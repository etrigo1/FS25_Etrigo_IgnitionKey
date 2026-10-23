--------------------------------------------------------------------------------
-- IgnitionKey.lua
-- Especialização: canhão de ignição no teclado, na tecla de arranque do jogo
-- (TOGGLE_MOTOR_STATE).
--
--   toque curto     : OFF -> IGNITION, IGNITION -> OFF, motor a trabalhar -> OFF
--   manter premido  : a partir de OFF roda a chave toda (0 -> 1 -> 2);
--                     a partir de IGNITION arranca; largar em STARTING continua a tentar
--
-- Fica vanilla com o arranque automático, o canhão de hardware ou a IA.
-- A tecla e o temporizador correm só no cliente que conduz; as mudanças de
-- estado seguem pelos eventos do jogo (setMotorState / startMotor / stopMotor).
--
-- Tecla partilhada (ADS carregado): o ADS também tira a tecla ao Motorized e
-- ganha sempre. O mod não lhe mexe: regista um segundo evento na mesma ação,
-- com a tabela do mod como dono, e cala o Motorized.actionEventToggleMotorState
-- que o ADS chama ao carregar (ver RegisterIgnitionKey.lua).
--------------------------------------------------------------------------------

IgnitionKey = {}
IgnitionKey.MOD_NAME = g_currentModName
IgnitionKey.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".ignitionKey"
IgnitionKey.ADS_MOD_NAME = "FS25_AdvancedDamageSystem"

IgnitionKey.HOLD_TO_CRANK_MS = 350      -- acima disto conta como "manter premido"
-- false = como a chave do jogo: depois de entrar em STARTING, largar a tecla
-- não para a tentativa de arranque. true = largar volta a IGNITION.
IgnitionKey.ABORT_START_ON_RELEASE = false
IgnitionKey.DEBUG = true                -- escreve no log.txt a tecla e as mudanças do motor/painel (testes)


local function getText(key)
    return g_i18n:getText(key, IgnitionKey.MOD_NAME)
end


--------------------------------------------------------------------------------
-- Debug: linhas "[IgnitionKey][debug]" no log.txt. Também regista o que faz a
-- chave de hardware, para comparar os dois caminhos.
--------------------------------------------------------------------------------
local function getStateName(motorState)
    for name, value in pairs(MotorState) do
        if value == motorState then
            return name
        end
    end
    return tostring(motorState)
end


local function debugLog(vehicle, fmt, ...)
    if IgnitionKey.DEBUG then
        local name = vehicle.getName ~= nil and vehicle:getName() or "?"
        Logging.info("[IgnitionKey][debug] t=%d %s | " .. fmt, g_time or 0, tostring(name), ...)
    end
end


-- escreve uma linha sempre que o estado do motor, a hora da ignição, o canhão
-- ou o valor do painel mudam (só no veículo em que o jogador está)
local function debugWatch(vehicle, spec)
    if vehicle.getIsEntered == nil or not vehicle:getIsEntered() then
        return
    end

    local motorizedSpec = vehicle.spec_motorized
    local lockState = "sem canhão"
    if g_ignitionLockManager ~= nil and g_ignitionLockManager:getIsAvailable() then
        lockState = tostring(g_ignitionLockManager:getState())
    end

    local dashboardValue = "-"
    local valueType = vehicle.ignitionKeyDashboardValueType
    if valueType ~= nil and valueType.getSourceValue ~= nil then
        -- o valor do jogo pode vir vazio (canhão a mudar de posição)
        local value = valueType:getSourceValue(nil)
        dashboardValue = tostring(value)
    end

    local snapshot = string.format("motor=%s ignitionTime=%s canhão=%s painel.ignitionState=%s modAtivo=%s",
        getStateName(vehicle:getMotorState()), tostring(motorizedSpec.motorStateIgnitionTime),
        lockState, dashboardValue, tostring(IgnitionKey.getIsActive(vehicle)))

    if snapshot ~= spec.debugLastSnapshot then
        spec.debugLastSnapshot = snapshot
        debugLog(vehicle, "%s", snapshot)
    end
end


local function isEngineActive(motorState)
    return motorState == MotorState.STARTING or motorState == MotorState.ON
end


--------------------------------------------------------------------------------
-- Registo
--------------------------------------------------------------------------------
function IgnitionKey.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Motorized, specializations)
        and SpecializationUtil.hasSpecialization(Enterable, specializations)
end


function IgnitionKey.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", IgnitionKey)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", IgnitionKey)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", IgnitionKey)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", IgnitionKey)
    SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", IgnitionKey)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", IgnitionKey)
end


--------------------------------------------------------------------------------
-- Ciclo de vida
--------------------------------------------------------------------------------
function IgnitionKey:onLoad(savegame)
    -- a spec é registada como "<modName>.ignitionKey"; atalho com nome simples
    self.spec_ignitionKey = self[IgnitionKey.SPEC_TABLE_NAME] or {}
    local spec = self.spec_ignitionKey

    -- tecla a meio (só no cliente que conduz)
    spec.press = nil

    -- evento paralelo da tecla partilhada (só com o ADS); o dono é esta tabela
    spec.vehicle = self
    spec.sharedActionEventId = nil
end


function IgnitionKey:onDelete()
    IgnitionKey.removeSharedKeyEvent(self)
end


-- A tecla fica partilhada quando outro mod é dono do TOGGLE_MOTOR_STATE.
function IgnitionKey.getShareKey()
    return g_modIsLoaded ~= nil and g_modIsLoaded[IgnitionKey.ADS_MOD_NAME] == true
end


-- true quando o evento paralelo deste veículo está registado
function IgnitionKey.getIsSharingKey(vehicle)
    local spec = vehicle ~= nil and vehicle.spec_ignitionKey or nil
    return spec ~= nil and spec.sharedActionEventId ~= nil
end


function IgnitionKey.removeSharedKeyEvent(vehicle)
    local spec = vehicle.spec_ignitionKey
    if spec ~= nil and spec.sharedActionEventId ~= nil then
        g_inputBinding:removeActionEvent(spec.sharedActionEventId)
        spec.sharedActionEventId = nil
    end
end


-- O mod só atua sem arranque automático, sem canhão de hardware e sem IA.
function IgnitionKey.getIsActive(vehicle)
    local missionInfo = g_currentMission ~= nil and g_currentMission.missionInfo or nil
    if missionInfo == nil or missionInfo.automaticMotorStartEnabled then
        return false
    end

    if g_ignitionLockManager ~= nil and g_ignitionLockManager:getIsAvailable() then
        return false
    end

    return not vehicle:getIsAIActive()
end


--------------------------------------------------------------------------------
-- Painel: motorized.ignitionState
-- 0 = off, 2 = ignição, 1 = arranque (posições do canhão de hardware).
-- Sem o canhão o jogo só devolve 2 com o motor a trabalhar, por isso o painel
-- ficava apagado em IGNITION. Corre depois do Motorized (a spec do mod vem a
-- seguir nos tipos), por isso o valor já está registado.
--------------------------------------------------------------------------------
function IgnitionKey:onRegisterDashboardValueTypes()
    local dashboardSpec = self.spec_dashboard
    if dashboardSpec == nil or dashboardSpec.dashboardValueTypes == nil then
        return
    end

    for _, valueType in ipairs(dashboardSpec.dashboardValueTypes) do
        if valueType.fullName == "motorized.ignitionState" then
            local vanillaGetSourceValue = valueType.getSourceValue
            if vanillaGetSourceValue == nil then
                debugLog(self, "ignitionState sem getSourceValue, painel não substituído")
                return
            end
            self.ignitionKeyDashboardValueType = valueType

            valueType:setValue(self, function(vehicle, dashboard)
                if not IgnitionKey.getIsActive(vehicle) then
                    return vanillaGetSourceValue(valueType, dashboard)
                end

                local motorState = vehicle:getMotorState()
                if motorState == MotorState.STARTING then
                    return 1
                elseif motorState == MotorState.ON or motorState == MotorState.IGNITION then
                    return 2
                end
                return 0
            end)
            return
        end
    end
end


--------------------------------------------------------------------------------
-- Tecla
-- O Motorized regista TOGGLE_MOTOR_STATE só ao carregar. Aqui tira-se essa ação
-- e volta a registar-se na mesma tabela do Motorized, ao carregar e ao largar.
-- Fica na tabela dele para o Motorized.updateActionEvents continuar a ligar e
-- desligar a tecla quando se muda o arranque automático a meio do jogo.
--------------------------------------------------------------------------------
function IgnitionKey:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if not self.isClient then
        return
    end

    self.spec_ignitionKey.press = nil
    IgnitionKey.removeSharedKeyEvent(self)

    if IgnitionKey.getShareKey() then
        if isActiveForInputIgnoreSelection then
            IgnitionKey.registerSharedKeyEvent(self)
        end
        return
    end

    local motorizedEvents = self.spec_motorized.actionEvents
    if motorizedEvents == nil or motorizedEvents[InputAction.TOGGLE_MOTOR_STATE] == nil then
        return
    end

    local oldActionEventId = motorizedEvents[InputAction.TOGGLE_MOTOR_STATE].actionEventId
    self:removeActionEvent(motorizedEvents, InputAction.TOGGLE_MOTOR_STATE)

    local _, actionEventId = self:addActionEvent(motorizedEvents, InputAction.TOGGLE_MOTOR_STATE, self, IgnitionKey.actionEventStartKey, true, true, false, true, nil)
    debugLog(self, "tecla registada: antiga=%s (ainda existe=%s) nova=%s", tostring(oldActionEventId),
        tostring(g_inputBinding.events ~= nil and g_inputBinding.events[oldActionEventId] ~= nil), tostring(actionEventId))
    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
    g_inputBinding:setActionEventText(actionEventId, self.spec_motorized.turnOnText)

    Motorized.updateActionEvents(self)
end


-- Segundo evento na mesma ação, ao lado do evento do ADS. O dono é a tabela do
-- mod, por isso nem o ADS nem o jogo (que apaga por veículo) lhe tocam: é o mod
-- que o apaga (aqui ao registar, ao sair do veículo e no onDelete).
function IgnitionKey.registerSharedKeyEvent(vehicle)
    local spec = vehicle.spec_ignitionKey
    local _, actionEventId = g_inputBinding:registerActionEvent(InputAction.TOGGLE_MOTOR_STATE, spec, IgnitionKey.actionEventSharedKey, true, true, false, true, nil)

    if actionEventId ~= nil and actionEventId ~= "" then
        spec.sharedActionEventId = actionEventId
        -- a ajuda que se vê é a do ADS; não mostrar duas linhas da mesma tecla
        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
    end

    debugLog(vehicle, "tecla partilhada com o ADS: evento paralelo registado: id=%s", tostring(spec.sharedActionEventId))
end


-- callback do evento paralelo: o primeiro argumento é a tabela do mod
function IgnitionKey.actionEventSharedKey(spec, actionName, inputValue, callbackState, isAnalog)
    if spec ~= nil and spec.vehicle ~= nil then
        -- inativo: o evento do ADS já chama a função do jogo
        IgnitionKey.handleKey(spec.vehicle, inputValue, false, actionName, callbackState, isAnalog)
    end
end


-- callback da tecla que substitui a do Motorized (sem o ADS)
function IgnitionKey.actionEventStartKey(self, actionName, inputValue, callbackState, isAnalog)
    IgnitionKey.handleKey(self, inputValue, true, actionName, callbackState, isAnalog)
end


-- inputValue: 1 ao carregar, 0 ao largar
function IgnitionKey.handleKey(vehicle, inputValue, callVanilla, actionName, callbackState, isAnalog)
    local isDown = inputValue ~= nil and inputValue > 0
    debugLog(vehicle, "tecla %s (inputValue=%s) motor=%s modAtivo=%s partilhada=%s", isDown and "CARREGADA" or "LARGADA",
        tostring(inputValue), getStateName(vehicle:getMotorState()), tostring(IgnitionKey.getIsActive(vehicle)),
        tostring(not callVanilla))

    if not IgnitionKey.getIsActive(vehicle) then
        vehicle.spec_ignitionKey.press = nil
        if isDown and callVanilla then
            Motorized.actionEventToggleMotorState(vehicle, actionName, inputValue, callbackState, isAnalog)
        end
        return
    end

    if isDown then
        IgnitionKey.onKeyDown(vehicle)
    else
        IgnitionKey.onKeyUp(vehicle)
    end
end


function IgnitionKey.onKeyDown(vehicle)
    local motorState = vehicle:getMotorState()
    vehicle.spec_ignitionKey.press = {
        startTimeMs = g_time,
        fromState = motorState,
        cranked = false,
        vanillaStart = false
    }

    if motorState == MotorState.OFF then
        vehicle:setMotorState(MotorState.IGNITION)
    end
end


function IgnitionKey.onKeyUp(vehicle)
    local spec = vehicle.spec_ignitionKey
    local press = spec.press
    spec.press = nil
    if press == nil then
        return
    end

    local motorState = vehicle:getMotorState()

    if press.cranked then
        -- largou antes de o motor pegar: a chave volta à ignição (só com ABORT_START_ON_RELEASE)
        if IgnitionKey.ABORT_START_ON_RELEASE and press.vanillaStart and motorState == MotorState.STARTING then
            vehicle:stopMotor()
            vehicle:setMotorState(MotorState.IGNITION)
        end
        return
    end

    -- o toque que ligou a ignição a partir de OFF, ou segurar com o motor a trabalhar
    if press.fromState == MotorState.OFF or g_time - press.startTimeMs >= IgnitionKey.HOLD_TO_CRANK_MS then
        return
    end

    if motorState == MotorState.IGNITION then
        vehicle:setMotorState(MotorState.OFF)
    elseif isEngineActive(motorState) then
        vehicle:stopMotor()
    end
end


-- enquanto a tecla está premida: ao fim de HOLD_TO_CRANK_MS arranca
function IgnitionKey:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_ignitionKey
    if spec == nil then
        return
    end

    -- Painel: os grupos "electronicsStarting/Running" acendem a partir de
    -- motorStateIgnitionTime. Com o canhão, o setMotorState(IGNITION) marca-o;
    -- vindo do teclado fica a 0 até STARTING (visto no log de 2026-10-23).
    -- Marca-se aqui com o mesmo relógio que o Motorized usa.
    local motorizedSpec = self.spec_motorized
    if motorizedSpec.motorStateIgnitionTime == 0 and self:getMotorState() == MotorState.IGNITION
        and IgnitionKey.getIsActive(self) then
        motorizedSpec.motorStateIgnitionTime = g_currentMission.time
    end

    if IgnitionKey.DEBUG and self.isClient then
        debugWatch(self, spec)
    end

    local press = spec.press
    if press == nil or press.cranked then
        return
    end

    if not IgnitionKey.getIsActive(self) then
        spec.press = nil
        return
    end

    -- segurar com o motor a trabalhar não faz nada
    if isEngineActive(press.fromState) or g_time - press.startTimeMs < IgnitionKey.HOLD_TO_CRANK_MS then
        return
    end

    press.cranked = true
    if self:getMotorState() ~= MotorState.IGNITION then
        return
    end

    -- mostra os avisos do jogo se o motor não puder trabalhar (ex.: sem combustível)
    Motorized.actionEventSetMotorStateOn(self, InputAction.MOTOR_STATE_ON, 1, nil, false)
    press.vanillaStart = self:getMotorState() == MotorState.STARTING
    debugLog(self, "manter premido %d ms -> arranque, motor=%s", g_time - press.startTimeMs, getStateName(self:getMotorState()))
end


-- onLeaveVehicle corre no servidor e nos clientes; só quem conduzia desliga a ignição
function IgnitionKey:onLeaveVehicle(wasEntered)
    local spec = self.spec_ignitionKey
    if spec == nil then
        return
    end

    spec.press = nil

    -- o jogo só apaga os eventos cujo dono é o veículo
    if wasEntered then
        IgnitionKey.removeSharedKeyEvent(self)
    end

    if wasEntered and self:getMotorState() == MotorState.IGNITION
        and not (g_ignitionLockManager ~= nil and g_ignitionLockManager:getIsAvailable()) then
        self:setMotorState(MotorState.OFF)
    end
end


-- Junta-se ao Motorized.updateActionEvents, que volta a escrever o texto da
-- tecla em cada tick. Com o motor a trabalhar fica o texto do jogo.
function IgnitionKey.updateActionEventText(vehicle)
    if vehicle.spec_ignitionKey == nil or vehicle.spec_motorized == nil or vehicle.spec_motorized.actionEvents == nil then
        return
    end

    local actionEvent = vehicle.spec_motorized.actionEvents[InputAction.TOGGLE_MOTOR_STATE]
    if actionEvent == nil or not IgnitionKey.getIsActive(vehicle) then
        return
    end

    local motorState = vehicle:getMotorState()
    if motorState == MotorState.OFF then
        g_inputBinding:setActionEventText(actionEvent.actionEventId, getText("ik_ignitionOn"))
    elseif motorState == MotorState.IGNITION then
        g_inputBinding:setActionEventText(actionEvent.actionEventId, getText("ik_start"))
    end
end
