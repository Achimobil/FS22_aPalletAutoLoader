---@type string directory of the mod.
local modDirectory = g_currentModDirectory or ""
---@type string name of the mod.
local modName = g_currentModName or "unknown"

---Init the mod.
local function init()
    g_specializationManager:addSpecialization("aPalletAutoLoader", "APalletAutoLoader", modDirectory .. "APalletAutoLoader.lua", nil)
    
    -- load events
    local path = modDirectory .. "Events/SetTipsideEvent.lua";
    source(path)
    local path = modDirectory .. "Events/SetAutoloadTypeEvent.lua";
    source(path)
    local path = modDirectory .. "Events/SetAutoloadStateEvent.lua";
    source(path)
    local path = modDirectory .. "Events/SetAutomaticTensionBeltsEvent.lua";
    source(path)
end

init()