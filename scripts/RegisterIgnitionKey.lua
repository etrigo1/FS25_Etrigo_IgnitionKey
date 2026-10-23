--------------------------------------------------------------------------------
-- RegisterIgnitionKey.lua
-- Regista a especialização IgnitionKey e junta-a a todos os tipos de veículo
-- com Motorized + Enterable (exceto locomotivas), incluindo tipos de outros mods.
--
-- Proteção contra o ADS: o FS25_AdvancedDamageSystem substitui a ação
-- TOGGLE_MOTOR_STATE pela sua. Se estiver carregado, este mod não se junta a
-- nenhum veículo e deixa a tecla ao ADS. A verificação é feita no validateTypes,
-- quando todos os mods já estão carregados.
--
-- Atenção: dentro de um mod, addSpecialization("ignitionKey") fica registado
-- como "<modName>.ignitionKey" (o jogo junta o nome do mod).
--------------------------------------------------------------------------------

local modDir = g_currentModDirectory
local modName = g_currentModName
local SPEC_FULL_NAME = modName .. ".ignitionKey"
local ADS_MOD_NAME = "FS25_AdvancedDamageSystem"
-- false = a proteção está desligada para testar ao lado do ADS (2026-10-23).
-- Pôr a true para o mod se desligar quando o ADS estiver carregado.
local DISABLE_WITH_ADS = false

g_specializationManager:addSpecialization("ignitionKey", "IgnitionKey", Utils.getFilename("scripts/IgnitionKey.lua", modDir), nil)

local function addToVehicleTypes(typeManager)
    if typeManager.typeName ~= "vehicle" then
        return
    end

    if g_modIsLoaded ~= nil and g_modIsLoaded[ADS_MOD_NAME] then
        if DISABLE_WITH_ADS then
            Logging.info("[IgnitionKey] %s carregado, mod desligado (a tecla de arranque fica para o ADS)", ADS_MOD_NAME)
            return
        end
        Logging.info("[IgnitionKey] %s carregado, proteção desligada (teste ao lado do ADS)", ADS_MOD_NAME)
    end

    local specObject = g_specializationManager:getSpecializationObjectByName(SPEC_FULL_NAME)
    if specObject == nil then
        Logging.error("[IgnitionKey] Especialização '%s' não encontrada, o mod não vai funcionar", SPEC_FULL_NAME)
        return
    end

    local numInserted = 0
    for typeName, typeEntry in pairs(typeManager:getTypes()) do
        local specs = typeEntry.specializations
        if specs ~= nil
            and typeEntry.specializationsByName[SPEC_FULL_NAME] == nil
            and specObject.prerequisitesPresent(specs)
            and (Locomotive == nil or not SpecializationUtil.hasSpecialization(Locomotive, specs)) then
            typeManager:addSpecialization(typeName, SPEC_FULL_NAME)
            numInserted = numInserted + 1
        end
    end

    Logging.info("[IgnitionKey] Especialização adicionada a %d tipos de veículo", numInserted)
end

TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, addToVehicleTypes)


-- textos da tecla: o Motorized volta a escrevê-los em cada tick
Motorized.updateActionEvents = Utils.appendedFunction(Motorized.updateActionEvents, function(vehicle)
    if IgnitionKey ~= nil then
        IgnitionKey.updateActionEventText(vehicle)
    end
end)
