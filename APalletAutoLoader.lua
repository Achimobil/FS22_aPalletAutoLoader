---Specialization for automatically load objects onto a vehicle by Achimobil
-- It is not allowed to copy my code complete or in Parts into other mods
-- If you have any issues please report them in my Discord on the channel for the mod.
-- https://discord.gg/Va7JNnEkcW

APalletAutoLoader = {}

APalletAutoLoaderTipsides = {
    LEFT = 1,
    RIGHT = 2,
    MIDDLE = 3,
    BACK = 4
}

APalletAutoLoaderLoadingState = {
    STOPPED = 1,
    RUNNING = 2
}

---
function APalletAutoLoader.prerequisitesPresent(specializations)
    return true
end

function APalletAutoLoader.initSpecialization()
    print("init aPalletAutoLoader");
    g_configurationManager:addConfigurationType("aPalletAutoLoader", g_i18n:getText("configuration_aPalletAutoLoader"), "aPalletAutoLoader", nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION)
    
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("APalletAutoLoader")
    
    local baseXmlPath = "vehicle.aPalletAutoLoader.APalletAutoLoaderConfigurations.APalletAutoLoaderConfiguration(?)"
    
    schema:register(XMLValueType.NODE_INDEX, baseXmlPath .. ".trigger#node", "Trigger node")
    schema:register(XMLValueType.NODE_INDEX, baseXmlPath .. ".pickupTriggers.pickupTrigger(?)#node", "Pickup trigger node")
    schema:register(XMLValueType.STRING, baseXmlPath .. "#supportedObject", "Path to xml of supported object")
    schema:register(XMLValueType.INT, baseXmlPath .. "#fillUnitIndex", "Fill unit index to check fill type")
    schema:register(XMLValueType.INT, baseXmlPath .. "#maxObjects", "Max. number of objects to load", "Number of load places")
    schema:register(XMLValueType.BOOL, baseXmlPath .. "#useBales", "Use for bales", false)
    schema:register(XMLValueType.BOOL, baseXmlPath .. "#useTensionBelts", "Automatically mount tension belts", "False for mobile, otherwise true")
    schema:register(XMLValueType.VECTOR_TRANS, baseXmlPath .. "#UnloadRightOffset", "Offset for Unload right")
    schema:register(XMLValueType.VECTOR_TRANS, baseXmlPath .. "#UnloadLeftOffset", "Offset for Unload left")
    schema:register(XMLValueType.VECTOR_TRANS, baseXmlPath .. "#UnloadMiddleOffset", "Offset for Unload middle")
    schema:register(XMLValueType.VECTOR_TRANS, baseXmlPath .. "#UnloadBackOffset", "Offset for Unload back")
    schema:register(XMLValueType.NODE_INDEX, baseXmlPath .. ".loadArea#baseNode", "Base node for loading")
    schema:register(XMLValueType.VECTOR_TRANS, baseXmlPath .. ".loadArea#leftRightCornerOffset", "Offset for the left corner, loading will be done starting this point")
    schema:register(XMLValueType.FLOAT, baseXmlPath .. ".loadArea#lenght", "length of the loadArea")
    schema:register(XMLValueType.FLOAT, baseXmlPath .. ".loadArea#height", "height of the loadArea")
    schema:register(XMLValueType.FLOAT, baseXmlPath .. ".loadArea#width", "width of the loadArea")

    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).FS22_aPalletAutoLoader.aPalletAutoLoader#lastUsedPalletTypeIndex", "Last used pallet type")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).FS22_aPalletAutoLoader.aPalletAutoLoader#lastUseTensionBelts", "Last used tension belts setting")
end

function APalletAutoLoader.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getIsValidObject", APalletAutoLoader.getIsValidObject)
    SpecializationUtil.registerFunction(vehicleType, "getIsAutoLoadingAllowed", APalletAutoLoader.getIsAutoLoadingAllowed)
    SpecializationUtil.registerFunction(vehicleType, "getFirstValidLoadPlace", APalletAutoLoader.getFirstValidLoadPlace)
    SpecializationUtil.registerFunction(vehicleType, "autoLoaderOverlapCallback", APalletAutoLoader.autoLoaderOverlapCallback)
    SpecializationUtil.registerFunction(vehicleType, "autoLoaderTriggerCallback", APalletAutoLoader.autoLoaderTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "autoLoaderPickupTriggerCallback", APalletAutoLoader.autoLoaderPickupTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "onDeleteAPalletAutoLoaderObject", APalletAutoLoader.onDeleteAPalletAutoLoaderObject)
    SpecializationUtil.registerFunction(vehicleType, "onDeleteObjectToLoad", APalletAutoLoader.onDeleteObjectToLoad)
    SpecializationUtil.registerFunction(vehicleType, "loadObject", APalletAutoLoader.loadObject)
    SpecializationUtil.registerFunction(vehicleType, "unloadAll", APalletAutoLoader.unloadAll)
    SpecializationUtil.registerFunction(vehicleType, "loadAllInRange", APalletAutoLoader.loadAllInRange)
    SpecializationUtil.registerFunction(vehicleType, "SetTipside", APalletAutoLoader.SetTipside)
    SpecializationUtil.registerFunction(vehicleType, "SetAutoloadType", APalletAutoLoader.SetAutoloadType)
    SpecializationUtil.registerFunction(vehicleType, "SetLoadingState", APalletAutoLoader.SetLoadingState)
    SpecializationUtil.registerFunction(vehicleType, "StartLoading", APalletAutoLoader.StartLoading)
    SpecializationUtil.registerFunction(vehicleType, "GetAutoloadTypes", APalletAutoLoader.GetAutoloadTypes)
    SpecializationUtil.registerFunction(vehicleType, "SetTensionBeltsValue", APalletAutoLoader.SetTensionBeltsValue)
    
    if vehicleType.functions["getFillUnitCapacity"] == nil then
        SpecializationUtil.registerFunction(vehicleType, "getFillUnitCapacity", APalletAutoLoader.getFillUnitCapacity)
    end
    if vehicleType.functions["getFillUnitFillLevel"] == nil then
        SpecializationUtil.registerFunction(vehicleType, "getFillUnitFillLevel", APalletAutoLoader.getFillUnitFillLevel)
    end
    if vehicleType.functions["getFillUnitFreeCapacity"] == nil then
        SpecializationUtil.registerFunction(vehicleType, "getFillUnitFreeCapacity", APalletAutoLoader.getFillUnitFreeCapacity)
    end
end

function APalletAutoLoader.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDynamicMountTimeToMount", APalletAutoLoader.getDynamicMountTimeToMount)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getUseTurnedOnSchema", APalletAutoLoader.getUseTurnedOnSchema)
    
    if vehicleType.functions["getFillUnitCapacity"] ~= nil then
        SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitCapacity", APalletAutoLoader.getFillUnitCapacity)
    end
    if vehicleType.functions["getFillUnitFillLevel"] ~= nil then
        SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitFillLevel", APalletAutoLoader.getFillUnitFillLevel)
    end
    if vehicleType.functions["getFillUnitFreeCapacity"] ~= nil then
        SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitFreeCapacity", APalletAutoLoader.getFillUnitFreeCapacity)
    end
end

function APalletAutoLoader.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", APalletAutoLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", APalletAutoLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", APalletAutoLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", APalletAutoLoader)
    
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", APalletAutoLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", APalletAutoLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", APalletAutoLoader)
end

function APalletAutoLoader:onDraw(isActiveForInput, isActiveForInputIgnoreSelection)
    local spec = self.spec_aPalletAutoLoader
    
    if spec.autoLoadTypes ~= nil then
        local maxItems = spec.autoLoadTypes[spec.currentautoLoadTypeIndex].maxItems;
        if spec.isFullLoaded then maxItems = spec.numTriggeredObjects; end
        local loadingText = g_i18n:getText("aPalletAutoLoader_" .. spec.autoLoadTypes[spec.currentautoLoadTypeIndex].name) .. " (" .. spec.numTriggeredObjects .. " / " .. maxItems .. ")"
        g_currentMission:addExtraPrintText(loadingText);
    end
    
    if not spec.showMarkers then return end
    
    if spec.loadArea["baseNode"] ~= nil then
        -- DebugUtil.drawDebugReferenceAxisFromNode(spec.loadArea["baseNode"]);
        
        -- draw line around loading area
        local cornerX,cornerY,cornerZ = unpack(spec.loadArea["leftRightCornerOffset"]);
        local node = spec.loadArea["baseNode"]
        local minX = (-spec.loadArea["width"]*0.5)+(cornerX-(spec.loadArea["width"]*0.5));
        local maxX = (spec.loadArea["width"]*0.5)+(cornerX-(spec.loadArea["width"]*0.5));
        local maxZ = (spec.loadArea["lenght"]*0.5)+(cornerZ-(spec.loadArea["lenght"]*0.5));
        local minZ = (-spec.loadArea["lenght"]*0.5)+(cornerZ-(spec.loadArea["lenght"]*0.5));
        local yOffset = cornerY;
        local r = 0;
        local g = 0.8;
        local b = 0.8;

        -- loading area
        local leftFrontX, leftFrontY, leftFrontZ = localToWorld(node, minX, yOffset, maxZ)
        local rightFrontX, rightFrontY, rightFrontZ = localToWorld(node, maxX, yOffset, maxZ)
        local leftBackX, leftBackY, leftBackZ = localToWorld(node, minX, yOffset, minZ)
        local rightBackX, rightBackY, rightBackZ = localToWorld(node, maxX, yOffset, minZ)
        
        drawDebugLine(leftFrontX, leftFrontY, leftFrontZ, r, g, b, rightFrontX, rightFrontY, rightFrontZ, r, g, b)
        drawDebugLine(rightFrontX, rightFrontY, rightFrontZ, r, g, b, rightBackX, rightBackY, rightBackZ, r, g, b)
        drawDebugLine(rightBackX, rightBackY, rightBackZ, r, g, b, leftBackX, leftBackY, leftBackZ, r, g, b)
        drawDebugLine(leftBackX, leftBackY, leftBackZ, r, g, b, leftFrontX, leftFrontY, leftFrontZ, r, g, b)

        -- unloading area
        local offx, offY, offZ = unpack(spec.UnloadOffset[spec.currentTipside])
        
        minX = minX + offx;
        maxX = maxX + offx;
        maxZ = maxZ + offZ;
        minZ = minZ + offZ;
        yOffset = yOffset + offY;
        
        leftFrontX, leftFrontY, leftFrontZ = localToWorld(node, minX, yOffset, maxZ)
        rightFrontX, rightFrontY, rightFrontZ = localToWorld(node, maxX, yOffset, maxZ)
        leftBackX, leftBackY, leftBackZ = localToWorld(node, minX, yOffset, minZ)
        rightBackX, rightBackY, rightBackZ = localToWorld(node, maxX, yOffset, minZ)
        
        drawDebugLine(leftFrontX, leftFrontY, leftFrontZ, r, g, b, rightFrontX, rightFrontY, rightFrontZ, r, g, b)
        drawDebugLine(rightFrontX, rightFrontY, rightFrontZ, r, g, b, rightBackX, rightBackY, rightBackZ, r, g, b)
        drawDebugLine(rightBackX, rightBackY, rightBackZ, r, g, b, leftBackX, leftBackY, leftBackZ, r, g, b)
        drawDebugLine(leftBackX, leftBackY, leftBackZ, r, g, b, leftFrontX, leftFrontY, leftFrontZ, r, g, b)   

        -- loadplaces
        local autoLoadType = spec.autoLoadTypes[spec.currentautoLoadTypeIndex];
        local loadPlaces = spec.autoLoadTypes[spec.currentautoLoadTypeIndex].places;
        for i=1, #loadPlaces do
            local loadPlace = loadPlaces[i]
            
            -- center node
            -- DebugUtil.drawDebugReferenceAxisFromNode(loadPlace.node);
            
            -- square
            if autoLoadType.type == "roundbale" then
                local radius = autoLoadType.sizeX/2;
                local vertical = false;
                local offset = nil;
                local color = {r,g,b};
                DebugUtil.drawDebugCircleAtNode(loadPlace.node, radius, 12, color, vertical, offset)
            elseif autoLoadType.type == "squarebale" then
                -- switch sizeZ and sizeX here because it is used 90° turned
                local sizeX = autoLoadType.sizeZ/2;
                local sizeZ = autoLoadType.sizeX/2;
                DebugUtil.drawDebugRectangle(loadPlace.node, -sizeX, sizeX, -sizeZ, sizeZ, 0, r, g, b)
            else
                local sizeX = autoLoadType.sizeX/2;
                local sizeZ = autoLoadType.sizeZ/2;
                DebugUtil.drawDebugRectangle(loadPlace.node, -sizeX, sizeX, -sizeZ, sizeZ, 0, r, g, b)
            end
        end
    end
end

function APalletAutoLoader:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_aPalletAutoLoader 
        if spec == nil then
            return;
        end
        
        if spec.actionEvents == nil then
            spec.actionEvents = {}
        else
            self:clearActionEventsTable(spec.actionEvents)
        end

        if isActiveForInput then
            local state, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AL_LOAD_PALLET, self, APalletAutoLoader.actionEventToggleLoading, false, true, false, true, nil, nil, true, true)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
            spec.toggleLoadingActionEventId = actionEventId;
            
            local state, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AL_TOGGLE_LOADINGTYPE, self, APalletAutoLoader.actionEventToggleAutoLoadTypes, false, true, false, true, nil, nil, true, true)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
            spec.toggleAutoLoadTypesActionEventId = actionEventId;
            
            local state, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AL_TOGGLE_TIPSIDE, self, APalletAutoLoader.actionEventToggleTipside, false, true, false, true, nil, nil, true, true)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            spec.toggleTipsideActionEventId = actionEventId;
            
            local state, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AL_UNLOAD, self, APalletAutoLoader.actionEventUnloadAll, false, true, false, true, nil, nil, true, true)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
            spec.unloadAllEventId = actionEventId;
            
            local state, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AL_TOGGLE_MARKERS, self, APalletAutoLoader.actionEventToggleMarkers, false, true, false, true, nil, nil, true, true)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            spec.toggleMarkerEventId = actionEventId;
            
            local state, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AL_TOGGLE_AUTOMATIC_TENSIONBELTS, self, APalletAutoLoader.actionEventToggleAutomaticTensionBelts, false, true, false, true, nil, nil, true, true)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            spec.toggleAutomaticTensionBeltsEventId = actionEventId;
            
            APalletAutoLoader.updateActionText(self);
        end
    end
end

function APalletAutoLoader.updateActionText(self)
    if self.isClient then
        local spec = self.spec_aPalletAutoLoader
        
        if not spec.available then
            g_inputBinding:setActionEventActive(spec.toggleLoadingActionEventId, false)
            g_inputBinding:setActionEventActive(spec.toggleAutoLoadTypesActionEventId, false)
            g_inputBinding:setActionEventActive(spec.toggleTipsideActionEventId, false)
            g_inputBinding:setActionEventActive(spec.unloadAllEventId, false)
            g_inputBinding:setActionEventActive(spec.toggleMarkerEventId, false)
            g_inputBinding:setActionEventActive(spec.toggleAutomaticTensionBeltsEventId, false)
            return;
        end
        
        -- different texts for the toggle loading key
        local text;
        if spec.loadingState == APalletAutoLoaderLoadingState.STOPPED then
            text = g_i18n:getText("aPalletAutoLoader_startLoading")
        else
            text = g_i18n:getText("aPalletAutoLoader_stopLoading")
        end 
        if spec.objectsToLoadCount ~= 0 then text = text  .. ": " .. spec.objectsToLoadCount end
        g_inputBinding:setActionEventText(spec.toggleLoadingActionEventId, text)
        g_inputBinding:setActionEventActive(spec.toggleLoadingActionEventId, true)   
                
        local loadingText = ""
        if (spec.autoLoadTypes == nil or spec.autoLoadTypes[spec.currentautoLoadTypeIndex] == nil) then
            loadingText = g_i18n:getText("aPalletAutoLoader_LoadingType") .. ": " .. "unknown"
        else
            loadingText = g_i18n:getText("aPalletAutoLoader_LoadingType") .. ": " .. g_i18n:getText("aPalletAutoLoader_" .. spec.autoLoadTypes[spec.currentautoLoadTypeIndex].name)
        end
        g_inputBinding:setActionEventText(spec.toggleAutoLoadTypesActionEventId, loadingText)
        
        g_inputBinding:setActionEventText(spec.toggleTipsideActionEventId, spec.tipsideText)
        
        local tensionBeltText = g_i18n:getText("aPalletAutoLoader_TensionBeltsNotActive");
        if spec.useTensionBelts then
            tensionBeltText = g_i18n:getText("aPalletAutoLoader_TensionBeltsActive");
        end
        g_inputBinding:setActionEventText(spec.toggleAutomaticTensionBeltsEventId, tensionBeltText)
        
        -- deactivate when somthing is already loaded or not
        g_inputBinding:setActionEventActive(spec.toggleAutoLoadTypesActionEventId, spec.numTriggeredObjects == 0 and spec.loadingState == APalletAutoLoaderLoadingState.STOPPED)
        g_inputBinding:setActionEventActive(spec.unloadAllEventId, spec.numTriggeredObjects ~= 0)
        g_inputBinding:setActionEventActive(spec.toggleMarkerEventId, true)
        g_inputBinding:setActionEventActive(spec.toggleAutomaticTensionBeltsEventId, true)
    end
end

function APalletAutoLoader.actionEventToggleLoading(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_aPalletAutoLoader
    
    if spec.loadingState == APalletAutoLoaderLoadingState.STOPPED then
        SetAutoloadStateEvent.sendEvent(self, APalletAutoLoaderLoadingState.RUNNING)
    else
        SetAutoloadStateEvent.sendEvent(self, APalletAutoLoaderLoadingState.STOPPED)
    end
end

function APalletAutoLoader:SetLoadingState(newLoadingState)
    local spec = self.spec_aPalletAutoLoader
    
    spec.loadingState = newLoadingState;
    spec.usedPositions = {};
    
    if self.isClient then
        -- nur beim Client aufrufen, Wenn ein Server im Spiel ist kommt das über die Sync
        APalletAutoLoader.updateActionText(self);
    end
    
    if self.isServer then
        -- Starten des Ladetimers, wenn der neue Status aktiv ist
        if spec.loadingState == APalletAutoLoaderLoadingState.RUNNING then
            self:StartLoading();
        end
        
    end
end

function APalletAutoLoader:StartLoading()
    local spec = self.spec_aPalletAutoLoader
    
    if (spec.timerId ~= nil) then return end;
    
    spec.isFullLoaded = false;
    self:loadAllInRange();
end

function APalletAutoLoader:GetAutoloadTypes()
    local spec = self.spec_aPalletAutoLoader;
    
    return spec.autoLoadTypes;
end

function APalletAutoLoader.actionEventToggleAutoLoadTypes(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_aPalletAutoLoader
    
    local newAutoLoadTypeIndex;
    if spec.currentautoLoadTypeIndex >= #spec.autoLoadTypes then
        newAutoLoadTypeIndex = 1;
    else
        newAutoLoadTypeIndex = spec.currentautoLoadTypeIndex + 1;
    end
    
    SetAutoloadTypeEvent.sendEvent(self, newAutoLoadTypeIndex)
end

function APalletAutoLoader:SetAutoloadType(newAutoLoadTypeIndex)
    local spec = self.spec_aPalletAutoLoader
    
    spec.currentautoLoadTypeIndex = newAutoLoadTypeIndex;
    
    if self.isClient then
        -- nur beim Client aufrufen, Wenn ein Server im Spiel ist kommt das über die Sync
        APalletAutoLoader.updateActionText(self);
    end
end

function APalletAutoLoader.actionEventToggleTipside(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_aPalletAutoLoader
    
    local newTipside = APalletAutoLoaderTipsides.LEFT;
    
    if spec.currentTipside == APalletAutoLoaderTipsides.LEFT then
        newTipside = APalletAutoLoaderTipsides.RIGHT;
    elseif spec.currentTipside == APalletAutoLoaderTipsides.RIGHT then
        newTipside = APalletAutoLoaderTipsides.BACK;
    end
    
    SetTipsideEvent.sendEvent(self, newTipside)
end

function APalletAutoLoader:SetTipside(tipsideIndex)
    local spec = self.spec_aPalletAutoLoader
    
    spec.currentTipside = tipsideIndex;
    spec.tipsideText = g_i18n:getText("aPalletAutoLoader_tipside") .. ": " .. g_i18n:getText("aPalletAutoLoader_" .. spec.currentTipside)
    
    if self.isClient then
        -- nur beim Client aufrufen, Wenn ein Server im Spiel ist kommt das über die Sync
        APalletAutoLoader.updateActionText(self);
    end
end

function APalletAutoLoader.actionEventToggleMarkers(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_aPalletAutoLoader
    
    spec.showMarkers = not spec.showMarkers;
end

function APalletAutoLoader.actionEventUnloadAll(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_aPalletAutoLoader
    
    if not self.isServer then
        -- Entladebefehl in den stream schreiben mit entladeseite
        spec.callUnloadAll = true;
        self:raiseDirtyFlags(spec.dirtyFlag)
    else
        self:unloadAll()
        APalletAutoLoader.updateActionText(self);
    end
end

function APalletAutoLoader.actionEventToggleAutomaticTensionBelts(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_aPalletAutoLoader
        
    SetAutomaticTensionBeltsEvent.sendEvent(self, not spec.useTensionBelts)
end

function APalletAutoLoader:SetTensionBeltsValue(newTensionBeltsValue)
    local spec = self.spec_aPalletAutoLoader
    
    spec.useTensionBelts = newTensionBeltsValue;
    
    if self.isClient then
        -- nur beim Client aufrufen, Wenn ein Server im Spiel ist kommt das über die Sync
        APalletAutoLoader.updateActionText(self);
    end
end

---Called on loading
-- @param table savegame savegame
function APalletAutoLoader:onLoad(savegame)
    local aPalletAutoLoaderConfigurationId = Utils.getNoNil(self.configurations["aPalletAutoLoader"], 1)
    local baseXmlPath = string.format("vehicle.aPalletAutoLoader.APalletAutoLoaderConfigurations.APalletAutoLoaderConfiguration(%d)", aPalletAutoLoaderConfigurationId -1)
            
    -- hier für server und client
    self.spec_aPalletAutoLoader = {}
    local spec = self.spec_aPalletAutoLoader
    spec.callUnloadAll = false;
    spec.objectsToLoadCount = 0;    
    spec.dirtyFlag = self:getNextDirtyFlag()
    spec.numTriggeredObjects = 0
    spec.isFullLoaded = false;
    spec.currentTipside = APalletAutoLoaderTipsides.LEFT;
    spec.tipsideText = g_i18n:getText("aPalletAutoLoader_tipside") .. ": " .. g_i18n:getText("aPalletAutoLoader_" .. spec.currentTipside)
    spec.currentautoLoadTypeIndex = 1;
    spec.available = false;
    spec.showMarkers = false;
    spec.loadingState = APalletAutoLoaderLoadingState.STOPPED;
    spec.useTensionBelts = false;
    
    -- load the loading area
    spec.loadArea = {};
    spec.loadArea["baseNode"] = self.xmlFile:getValue(baseXmlPath..".loadArea#baseNode", nil, self.components, self.i3dMappings);
    spec.loadArea["leftRightCornerOffset"] = self.xmlFile:getValue(baseXmlPath .. ".loadArea#leftRightCornerOffset", "0 0 0", true);
    spec.loadArea["lenght"] = self.xmlFile:getValue(baseXmlPath .. ".loadArea#lenght") or 5
    spec.loadArea["height"] = self.xmlFile:getValue(baseXmlPath .. ".loadArea#height") or 2
    spec.loadArea["width"] = self.xmlFile:getValue(baseXmlPath .. ".loadArea#width") or 2
    spec.maxObjects = self.xmlFile:getValue(baseXmlPath .. "#maxObjects") or 50
    spec.UnloadOffset = {}
    spec.UnloadOffset[APalletAutoLoaderTipsides.RIGHT] = self.xmlFile:getValue(baseXmlPath .. "#UnloadRightOffset", "-" .. (spec.loadArea["width"]+1) .. " -0.5 0", true)
    spec.UnloadOffset[APalletAutoLoaderTipsides.LEFT] = self.xmlFile:getValue(baseXmlPath .. "#UnloadLeftOffset", (spec.loadArea["width"]+1) .. " -0.5 0", true)
    spec.UnloadOffset[APalletAutoLoaderTipsides.MIDDLE] = self.xmlFile:getValue(baseXmlPath .. "#UnloadMiddleOffset", "0 0 0", true)
    spec.UnloadOffset[APalletAutoLoaderTipsides.BACK] = self.xmlFile:getValue(baseXmlPath .. "#UnloadBackOffset", "0 -0.5 -" .. (spec.loadArea["lenght"]+1), true)
    
    if spec.loadArea["baseNode"] == nil then
        return;
    end
    
    spec.available = true;
    
    spec.useBales = self.xmlFile:getValue(baseXmlPath .. "#useBales", false)
    
    -- ,"cottonSquarebale488" Bauwollquaderballen können aktuell nicht befestigt werden und machen nur fehler, deshalb zwar implementiert, aber nicht aktiviert.
    local types = {"euroPallet","liquidTank","bigBagPallet","bigBag","euroPalletOversize"}
    
    if spec.useBales then
        table.insert(types, "cottonRoundbale238");
        table.insert(types, "roundbale125");
        table.insert(types, "roundbale150");
        table.insert(types, "roundbale180");
        table.insert(types, "squarebale180");
        table.insert(types, "squarebale220");
        table.insert(types, "squarebale240");
    end
    
    -- create loadplaces automatically from load Area size
    if spec.loadArea["baseNode"] ~= nil then
        spec.autoLoadTypes = {};
        for i,name in ipairs(types) do
            local autoLoadObject = {}
            autoLoadObject.index = spec.loadArea["baseNode"]
            autoLoadObject.name = name
            autoLoadObject.nameTranslated = g_i18n:getText("aPalletAutoLoader_" .. name)
            APalletAutoLoader:AddSupportedObjects(autoLoadObject, name)
            autoLoadObject.places = {}
            local cornerX,cornerY,cornerZ = unpack(spec.loadArea["leftRightCornerOffset"]);
            
            -- paletten nebeneinander bestimmen
            -- vieviele passen ohne drehung?
            -- erst mal alle rotiert oder nicht rotiert als loading anfang
            local restFirstNoRotation = (spec.loadArea["width"] - autoLoadObject.sizeX) % (autoLoadObject.sizeX + 0.05);
            local countNoRotation = (spec.loadArea["width"] - autoLoadObject.sizeX - restFirstNoRotation) / (autoLoadObject.sizeX + 0.05) + 1
            
            local restFirstRotation = (spec.loadArea["width"] - autoLoadObject.sizeZ) % (autoLoadObject.sizeZ + 0.05);
            local countRotation = (spec.loadArea["width"] - autoLoadObject.sizeZ - restFirstRotation) / (autoLoadObject.sizeZ + 0.05) + 1
            local backDistance = 0.05;
            if autoLoadObject.type == "roundbale" then
                -- rundballen ein bischen mehr platz geben wegen der runden kollision
                backDistance = 0.07;
            end
            
            local loadingPattern = {}
            if restFirstNoRotation <= restFirstRotation or autoLoadObject.type == "roundbale" then
                -- auladen ohne rotation
                -- rundballen generell hier, weil sind ja rund
                if autoLoadObject.type == "roundbale" and countNoRotation == 1 then
                    -- wenn rundballen und noch genug platz, versetzt laden um mehr auf die fläche zu bekommen
                    -- hierbei aber nur, wenn die restfläche mindestens so viel ist, wie der halbe durchmesser zur einfachen Verteilung, komplexer kann später
                    
                    -- position der zwei reihen
                    local rowX1 = (cornerX - (autoLoadObject.sizeX / 2))
                    local rowX2 = (cornerX - spec.loadArea["width"] + (autoLoadObject.sizeX / 2))
                    
                    -- abweichende distanz berechnen aus dem abstand der beiden Reihen und dem durchmesser
                    -- a² + b² = c²
                    -- a = wurzel aus c² - b²
                    local optimalDistanceZ = math.sqrt(math.pow(autoLoadObject.sizeX + backDistance, 2) - math.pow((rowX1 - rowX2), 2)) * 2;
                    
                    -- minimale distanz nur aus der größe und en abstand
                    local minimalDistanceZ = (autoLoadObject.sizeZ + backDistance);
                    
                    -- die höhere der beiden distanzen muss benutzt werden
                    local distanceZ = math.max(optimalDistanceZ, minimalDistanceZ);                
                    
                    -- schleifen bis zur länge links und rechts ausgericht
                    -- linke seite
                    for colPos = (autoLoadObject.sizeZ / 2), (spec.loadArea["lenght"]), distanceZ do
                        if (colPos + (autoLoadObject.sizeZ / 2)) <= spec.loadArea["lenght"] then
                            local loadingPatternItem = {}
                            loadingPatternItem.rotation = 0;
                            loadingPatternItem.posX = rowX1
                            loadingPatternItem.posZ = cornerZ - colPos
                            table.insert(loadingPattern, loadingPatternItem)
                        end
                    end
                    -- rechte seite
                    -- 2. reihe um die hälfte des abstandes nach hinten schieben
                    for colPos = (autoLoadObject.sizeZ / 2) + (distanceZ / 2), (spec.loadArea["lenght"]), distanceZ do
                        if (colPos + (autoLoadObject.sizeZ / 2)) <= spec.loadArea["lenght"] then
                            local loadingPatternItem = {}
                            loadingPatternItem.rotation = 0;
                            loadingPatternItem.posX = rowX2
                            loadingPatternItem.posZ = cornerZ - colPos
                            table.insert(loadingPattern, loadingPatternItem)
                        end
                    end
                else
                    for rowNumber = 0, (countNoRotation-1) do
                        -- schleife bis zur länge
                        for colPos = (autoLoadObject.sizeZ / 2), spec.loadArea["lenght"], (autoLoadObject.sizeZ + backDistance) do
                            if (colPos + (autoLoadObject.sizeZ / 2)) <= spec.loadArea["lenght"] then
                                local loadingPatternItem = {}
                                loadingPatternItem.rotation = 0;
                                loadingPatternItem.posX = cornerX - (autoLoadObject.sizeX / 2) - (rowNumber * (autoLoadObject.sizeX + backDistance)) - (restFirstNoRotation / 2)
                                loadingPatternItem.posZ = cornerZ - colPos
                                table.insert(loadingPattern, loadingPatternItem)
                            end
                        end
                    end
                end
            else
                -- aufladen mit rotation
                for rowNumber = 0, (countRotation-1) do
                    -- schleife bis zur länge
                    for colPos = (autoLoadObject.sizeX / 2), spec.loadArea["lenght"], (autoLoadObject.sizeX + backDistance) do
                        if (colPos + (autoLoadObject.sizeX / 2)) <= spec.loadArea["lenght"] then
                            local loadingPatternItem = {}
                            loadingPatternItem.rotation = math.rad(90);
                            loadingPatternItem.posX = cornerX - (autoLoadObject.sizeZ / 2) - (rowNumber * (autoLoadObject.sizeZ + backDistance)) - (restFirstRotation / 2)
                            loadingPatternItem.posZ = cornerZ - colPos
                            table.insert(loadingPattern, loadingPatternItem)
                        end
                    end
                end
            end
            
            table.sort(loadingPattern,compLoadingPattern)
            
            for _,loadingPatternItem in ipairs(loadingPattern) do
                local place = {}
                place.node = createTransformGroup("Loadplace")
                link(autoLoadObject.index, place.node);
                
                -- Round bales must be rotated with 15° so the collision edge is not pointing to the left and right border.
                -- Had to be done here, because at moving object it is not stabel basen on the direction the trailer looks to.
                local currentRotation = loadingPatternItem.rotation;
                if autoLoadObject.type == "roundbale" then
                    currentRotation = currentRotation + 15;
                end
                if autoLoadObject.type == "squarebale" then
                    -- turn tthe place by 90° to need no rotation on loading
                    currentRotation = currentRotation + math.rad(90);
                end
                
                setRotation(place.node, 0, currentRotation, 0)
                setTranslation(place.node, loadingPatternItem.posX, cornerY, loadingPatternItem.posZ)
                table.insert(autoLoadObject.places, place)
            end
            
            local amountPerLayer = #autoLoadObject.places;
            local maxLayers = math.floor(spec.loadArea["height"] / autoLoadObject.sizeY);
            if autoLoadObject.type == "bigBag" then maxLayers = 1 end
            local maxAmountForLayers = amountPerLayer * maxLayers;
            autoLoadObject.maxItems = math.min(maxAmountForLayers, spec.maxObjects); 
            
            if #autoLoadObject.places ~= 0 and autoLoadObject.maxItems ~= 0 then
                table.insert(spec.autoLoadTypes, autoLoadObject)
            end
        end
    end
    
    if self.isServer then
        spec.objectsToLoad = {};
        spec.balesToLoad = {};
        spec.objectsToJoint = {}

        spec.triggerId = self.xmlFile:getValue(baseXmlPath .. ".trigger#node", nil, self.components, self.i3dMappings)
        if spec.triggerId ~= nil then
            addTrigger(spec.triggerId, "autoLoaderTriggerCallback", self);
        end
        
        spec.pickupTriggers = {}
        
        local i = 0
        while true do
            local pickupTriggerKey = string.format(baseXmlPath .. ".pickupTriggers.pickupTrigger(%d)", i)
            if not self.xmlFile:hasProperty(pickupTriggerKey) then
                break
            end

            local entry = {}
            entry.node = self.xmlFile:getValue(pickupTriggerKey .. "#node", nil, self.components, self.i3dMappings)

            if entry.node ~= nil then
                table.insert(spec.pickupTriggers, entry)
                addTrigger(entry.node, "autoLoaderPickupTriggerCallback", self)
            end

            i = i + 1
        end
        
        spec.triggeredObjects = {}
        
        spec.supportedObject = self.xmlFile:getValue(baseXmlPath .. "#supportedObject")

        spec.fillUnitIndex = self.xmlFile:getValue(baseXmlPath .. "#fillUnitIndex")
        spec.useTensionBelts = self.xmlFile:getValue(baseXmlPath .. "#useTensionBelts", not GS_IS_MOBILE_VERSION)
        
        -- fix for dedi problem with sync by deactivate tension belts on server
        -- if g_dedicatedServer ~= nil then
            -- spec.useTensionBelts = false;
        -- end
    end
    
    spec.initialized = true;
end

function compLoadingPattern(w1,w2)
    -- Zum Sortieren
    if w1.posZ == w2.posZ and w1.posX > w2.posX then
        return true
    end
    if w1.posZ > w2.posZ then
        return true
    end
end

---Called after loading
-- @param table savegame savegame
function APalletAutoLoader:onPostLoad(savegame)
    if savegame ~= nil and self.spec_aPalletAutoLoader ~= nil then
        local spec = self.spec_aPalletAutoLoader

        if not savegame.resetVehicles then
            spec.currentautoLoadTypeIndex = savegame.xmlFile:getValue(savegame.key..".FS22_aPalletAutoLoader.aPalletAutoLoader#lastUsedPalletTypeIndex", 1)
            if(spec.autoLoadTypes == nil or spec.autoLoadTypes[spec.currentautoLoadTypeIndex] == nil) then
                spec.currentautoLoadTypeIndex = 1;
            end
            local useTensionBelts = savegame.xmlFile:getBool(savegame.key..".FS22_aPalletAutoLoader.aPalletAutoLoader#lastUseTensionBelts", nil)
            if(useTensionBelts ~= nil) then
                spec.useTensionBelts = useTensionBelts;
            end
        end
    end
end

---
function APalletAutoLoader:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_aPalletAutoLoader 
    if spec == nil then
        return;
    end

    xmlFile:setValue(key.."#lastUsedPalletTypeIndex", spec.currentautoLoadTypeIndex)
    if spec.useTensionBelts ~= nil then
        xmlFile:setBool(key.."#lastUseTensionBelts", spec.useTensionBelts)
    end
end

---
function APalletAutoLoader:AddSupportedObjects(autoLoadObject, name)
    if (name == "euroPallet") then
        local function CheckType(object)
            if object.configFileName == "data/objects/pallets/pioneer/pioneerPallet.xml" then return false end
            if object.configFileName == "data/objects/pallets/grapePallet/grapePallet.xml" then return true end
            if object.configFileName == "data/objects/pallets/schaumann/schaumannPallet.xml" then return false end
            if string.find(object.i3dFilename, "FS22_HoT_pommesFactory/placeable/pallets") then return true end
            if object.configFileName ~= nil and string.find(object.configFileName, "/euroPallets/") then return true end
        
            if object.i3dMappings == nil then 
                return false;
            end
            
            for mappingName, _ in pairs(object.i3dMappings) do
                if (mappingName == "euroPalletVis") or (mappingName == "pallet_vis") or (mappingName == "grapePallet_vis") then
                return true;
                end
            end
            
            return false;
        end    
    
        autoLoadObject.CheckTypeMethod = CheckType
        autoLoadObject.sizeX = 1.2
        autoLoadObject.sizeY = 1.0
        autoLoadObject.sizeZ = 0.8
        autoLoadObject.type = "pallet"
    elseif (name == "euroPalletOversize") then
        local function CheckType(object)
            if object.configFileName == "data/objects/pallets/schaumann/schaumannPallet.xml" then return true end
            if object.configFileName == "data/objects/ksAG/patentkali/patentkali.xml" then return true end
            if object.configFileName == "data/objects/ksAG/epsoTop/epsoTop.xml" then return true end
            if object.configFileName == "data/objects/pallets/pioneer/pioneerPallet.xml" then return true end
            if string.find(object.i3dFilename, "FS22_Pallets_And_Bags_Pack/Pallets") then return true end
            if object.configFileName ~= nil and string.find(object.configFileName, "/euroPalletsOversized/") then return true end
                        
            return false;
        end    
    
        autoLoadObject.CheckTypeMethod = CheckType
        autoLoadObject.sizeX = 1.3
        autoLoadObject.sizeY = 1.0
        autoLoadObject.sizeZ = 1.0
        autoLoadObject.type = "pallet"
    elseif (name == "liquidTank") then
        local function CheckType(object)
            if string.find(object.i3dFilename, "data/objects/pallets/liquidTank") then return true end
            if object.configFileName ~= nil and string.find(object.configFileName, "/liquidTank/") then return true end
            return false;
        end    
    
        autoLoadObject.CheckTypeMethod = CheckType
        autoLoadObject.sizeX = 1.34
        autoLoadObject.sizeY = 1.5
        autoLoadObject.sizeZ = 1.34
        autoLoadObject.type = "pallet"
    elseif (name == "bigBagPallet") then
        local function CheckType(object)
            if object.configFileName ~= nil and string.find(object.configFileName, "/bigBagPallet/") then return true end
        
            if object.i3dMappings == nil then 
                return false;
            end
            
            for mappingName, _ in pairs(object.i3dMappings) do
                if (mappingName == "bigBagPallet_vis") then
                return true;
                end
            end
            return false;
        end    
    
        autoLoadObject.CheckTypeMethod = CheckType
        autoLoadObject.sizeX = 1.4
        autoLoadObject.sizeY = 1.5
        autoLoadObject.sizeZ = 1.2
        autoLoadObject.type = "pallet"
    elseif (name == "bigBag") then
        local function CheckType(object)
            if object.configFileName ~= nil and string.find(object.configFileName, "/bigBag/") then return true end
        
            if object.i3dMappings == nil then 
                return false;
            end
            
            for mappingName, _ in pairs(object.i3dMappings) do
                if (mappingName == "bigBag_vis") then
                return true;
                end
            end
            return false;
        end    
    
        autoLoadObject.CheckTypeMethod = CheckType
        autoLoadObject.sizeX = 1
        autoLoadObject.sizeY = 1.55
        autoLoadObject.sizeZ = 0.85
        autoLoadObject.type = "bigBag"
    elseif (name == "cottonRoundbale238") then
        local function CheckType(object)
            if string.find(object.i3dFilename, "cottonModules/cottonRoundbale238.i3d") then return true end
            if string.find(object.i3dFilename, "lavenderModules/lavenderRoundbale238.i3d") then return true end
            
            return false;
        end    
    
        autoLoadObject.CheckTypeMethod = CheckType
        autoLoadObject.sizeX = 2.38
        autoLoadObject.sizeY = 2.38
        autoLoadObject.sizeZ = 2.38
        autoLoadObject.type = "roundbale"
    elseif (name == "cottonSquarebale488") then
        local function CheckType(object)
            if string.find(object.i3dFilename, "cottonModules/cottonSquarebale488.i3d") then return true end
            if string.find(object.i3dFilename, "lavenderModules/lavenderSquarebale488.i3d") then return true end
            
            return false;
        end    
    
        autoLoadObject.CheckTypeMethod = CheckType
        autoLoadObject.sizeX = 2.44
        autoLoadObject.sizeY = 2.44
        autoLoadObject.sizeZ = 4.88
        autoLoadObject.type = "cottonSquarebale"
    elseif (name == "roundbale125") then
        local function CheckType(object)
            if string.find(object.i3dFilename, "roundbales/roundbale125/roundbale125.i3d") then
                return true;
            end
            if string.find(object.i3dFilename, "roundbales/biomass/biomassBale125.i3d") then
                return true;
            end
            return false;
        end    
    
        autoLoadObject.CheckTypeMethod = CheckType
        autoLoadObject.sizeX = 1.25
        autoLoadObject.sizeY = 1.20
        autoLoadObject.sizeZ = 1.25
        autoLoadObject.type = "roundbale"
    elseif (name == "roundbale150") then
        local function CheckType(object)
            if string.find(object.i3dFilename, "roundbales/roundbale150/roundbale150.i3d") then
                return true;
            end
            return false;
        end    
    
        autoLoadObject.CheckTypeMethod = CheckType
        autoLoadObject.sizeX = 1.50
        autoLoadObject.sizeY = 1.20
        autoLoadObject.sizeZ = 1.50
        autoLoadObject.type = "roundbale"
    elseif (name == "roundbale180") then
        local function CheckType(object)
            if string.find(object.i3dFilename, "roundbales/roundbale180/roundbale180.i3d") then
                return true;
            end
            return false;
        end    
    
        autoLoadObject.CheckTypeMethod = CheckType
        autoLoadObject.sizeX = 1.80
        autoLoadObject.sizeY = 1.20
        autoLoadObject.sizeZ = 1.80
        autoLoadObject.type = "roundbale"
    elseif (name == "squarebale240") then
        local function CheckType(object)
            if string.find(object.i3dFilename, "squarebales/squarebale240/squarebale240.i3d") then
                return true;
            end
            return false;
        end    
    
        autoLoadObject.CheckTypeMethod = CheckType
        autoLoadObject.sizeX = 2.40
        autoLoadObject.sizeY = 0.86
        autoLoadObject.sizeZ = 1.20
        autoLoadObject.type = "squarebale"
    elseif (name == "squarebale220") then
        local function CheckType(object)
            if string.find(object.i3dFilename, "squarebales/squarebale220/squarebale220.i3d") then
                return true;
            end
            return false;
        end    
    
        autoLoadObject.CheckTypeMethod = CheckType
        autoLoadObject.sizeX = 2.20
        autoLoadObject.sizeY = 0.85
        autoLoadObject.sizeZ = 1.20
        autoLoadObject.type = "squarebale"
    elseif (name == "squarebale180") then
        local function CheckType(object)
            if string.find(object.i3dFilename, "squarebales/squarebale180/squarebale180.i3d") then
                return true;
            end
            return false;
        end    
    
        autoLoadObject.CheckTypeMethod = CheckType
        autoLoadObject.sizeX = 1.80
        autoLoadObject.sizeY = 0.87
        autoLoadObject.sizeZ = 1.20
        autoLoadObject.type = "squarebale"
    end
end

---
function APalletAutoLoader:onDelete()
    local spec = self.spec_aPalletAutoLoader
    if spec == nil then
        return;
    end

    if self.isServer then
        if spec.triggerId ~= nil then
            removeTrigger(spec.triggerId)
        end

        if spec.pickupTriggers ~= nil then
            for _, pickupTrigger in pairs(spec.pickupTriggers) do
                removeTrigger(pickupTrigger.node)
            end            
        end
    end
end

---
function APalletAutoLoader:getIsValidObject(object)
    local spec = self.spec_aPalletAutoLoader
    
    if object.currentlyLoadedOnAPalletAutoLoaderId ~= nil then
        return false;
    end
    
    local objectFilename = object.configFileName or object.i3dFilename
    if objectFilename ~= nil then
        if object.typeName == "pallet" then
            return true
        end
        if object.typeName == "treeSaplingPallet" then
            return true
        end
        if object.typeName == "bigBag" then
            return true
        end
    else
        return false
    end

    if object == self then
        return false
    end
    
    if not object:isa(Bale) or not object:getAllowPickup() then
        return false
    end

    if not g_currentMission.accessHandler:canFarmAccess(self:getActiveFarm(), object) then
        return false
    end

    if spec.fillUnitIndex ~= nil and object.getFillType ~= nil and not self:getFillUnitSupportsFillType(spec.fillUnitIndex, object:getFillType()) then
        return false
    end

    return true
end

---
function APalletAutoLoader:getIsAutoLoadingAllowed()
    -- check if the vehicle has not fallen to side
    local _, y1, _ = getWorldTranslation(self.components[1].node)
    local _, y2, _ = localToWorld(self.components[1].node, 0, 1, 0)
    if y2 - y1 < 0.5 then
        return false
    end

    return true
end

---
function APalletAutoLoader:getDynamicMountTimeToMount(superFunc)
    return self:getIsAutoLoadingAllowed() and -1 or math.huge
end

---
function APalletAutoLoader:getFirstValidLoadPlace()
    local spec = self.spec_aPalletAutoLoader

    if spec.usedPositions == nil then spec.usedPositions = {} end
    -- Hier die loading position und das loading objekt nehmen und die erste ladeposition dafür dynamisch suchen
    -- https://gdn.giants-software.com/documentation_scripting_fs19.php?version=engine&category=15&function=138
    -- overlapBox scheint zu prüfen, ob der angegebene Bereich frei ist
    
    local currentLoadHeigt = 0;
    local autoLoadType = spec.autoLoadTypes[spec.currentautoLoadTypeIndex];
    local loadPlaces = spec.autoLoadTypes[spec.currentautoLoadTypeIndex].places;
    while (currentLoadHeigt + autoLoadType.sizeY)  <= spec.loadArea["height"] do
    
        for i=1, #loadPlaces do
            local positionIndex = i .. "-" .. currentLoadHeigt;
            
            if spec.usedPositions[positionIndex] == nil
            then
                local loadPlace = loadPlaces[i]
                local x, y, z = localToWorld(loadPlace.node, 0, currentLoadHeigt, 0);
                local rx, ry, rz = getWorldRotation(loadPlace.node)
                -- collision mask : all bits except bit 13, 23, 30
                spec.foundObject = false 
                        
                if autoLoadType.type == "roundbale" then
                    -- Kollision rund berechnen für Rundballen mit simuliertem Kreis, Kugel klappt nicht bei den großen ballen wegen der höhe
                    -- eine virtel umdrehung als konstante
                    local rotationQuarter = math.rad(90);
                    local testRuns = 3;
                    
                    -- länge des quadrates im kreis berechnen für x und z
                    -- radius = seitenlänge / Wurzel 2
                    -- seitenlänge = radius * Wurzel 2
                    local squareLength = (autoLoadType.sizeX / 2) * math.sqrt(2);
                    
                    -- für jeden teil einen test machen
                    for i = 1, testRuns do 
                        overlapBox(x, y + (autoLoadType.sizeY / 2), z, rx, (ry + (rotationQuarter / testRuns * i)), rz, squareLength / 2, autoLoadType.sizeY / 2, squareLength / 2, "autoLoaderOverlapCallback", self, 3212828671, true, false, true)
                    end
                elseif autoLoadType.type == "squarebale" then
                    -- switch sizeZ and sizeX here because it is used 90° turned
                    
                    overlapBox(x, y + (autoLoadType.sizeY / 2), z, rx, ry, rz, autoLoadType.sizeZ / 2, autoLoadType.sizeY / 2, autoLoadType.sizeX / 2, "autoLoaderOverlapCallback", self, 3212828671, true, false, true)
                else
                    overlapBox(x, y + (autoLoadType.sizeY / 2), z, rx, ry, rz, autoLoadType.sizeX / 2, autoLoadType.sizeY / 2, autoLoadType.sizeZ / 2, "autoLoaderOverlapCallback", self, 3212828671, true, false, true)
                end
                
                -- save checked position to skip on next run
                if spec.usedPositions[positionIndex] == nil then spec.usedPositions[positionIndex] = true end;
                
                -- sollte auf true sein, wenn eine rotation was gefunden hat
                if not spec.foundObject then
                    -- print("height: " .. currentLoadHeigt)
                    return i, currentLoadHeigt
                end
            end
        end
        
        if autoLoadType.type == "bigBag" then
            break
        elseif autoLoadType.type == "squarebale" then
            if currentLoadHeigt == 0 then
                -- when balse we can directly jump the size up for the second line for performance reason
                currentLoadHeigt = autoLoadType.sizeY + 0.01
            else
                currentLoadHeigt = currentLoadHeigt + 0.01
            end
        else
            currentLoadHeigt = currentLoadHeigt + 0.05
        end
    end

    return -1, 0
end

---
function APalletAutoLoader:autoLoaderOverlapCallback(transformId)
    if transformId ~= 0 and getHasClassId(transformId, ClassIds.SHAPE) then
        local spec = self.spec_aPalletAutoLoader

        local object = g_currentMission:getNodeObject(transformId)
        if object ~= nil and object ~= self then
            spec.foundObject = true
        end
    end

    return true
end

---
function APalletAutoLoader:loadAllInRange()
    local spec = self.spec_aPalletAutoLoader
    
    local loaded = false;
    
    for _, object in pairs(spec.objectsToLoad) do
        local isValidLoadType = spec.autoLoadTypes[spec.currentautoLoadTypeIndex].CheckTypeMethod(object);
        if isValidLoadType then
            if spec.loadingState == APalletAutoLoaderLoadingState.STOPPED then 
                break;
            end
            loaded = self:loadObject(object);
            if loaded then 
                break;
            end
        end
    end
    for object,_  in pairs(spec.balesToLoad) do
        local isValidLoadType = spec.autoLoadTypes[spec.currentautoLoadTypeIndex].CheckTypeMethod(object);
        if isValidLoadType then
            if spec.loadingState == APalletAutoLoaderLoadingState.STOPPED then 
                break;
            end
            loaded = self:loadObject(object);
            if loaded then 
                break;
            end
        end
    end
        
    if spec.timerId ~= nil then
        if loaded then
            return true;
        else
            spec.timerId = nil;
            if self.isClient then
                APalletAutoLoader.updateActionText(self);
            end
           
            -- release all joints
            for _,jointData  in pairs(spec.objectsToJoint) do
				removeJoint(jointData.jointIndex)
				delete(jointData.jointTransform)
            end
            
            spec.objectsToJoint = {};
            
            if spec.useTensionBelts and self.setAllTensionBeltsActive ~= nil then
                self:setAllTensionBeltsActive(false, false)
                self:setAllTensionBeltsActive(true, false)
            end
        end
    else
        if loaded then
            spec.timerId = addTimer(100, "loadAllInRange", self);
        end
    end
end

---
function APalletAutoLoader:loadObject(object)
    if object ~= nil then
        if self:getIsAutoLoadingAllowed() and self:getIsValidObject(object) then
            local spec = self.spec_aPalletAutoLoader
            if spec.triggeredObjects[object] == nil then
                if spec.numTriggeredObjects < spec.maxObjects then
                    local firstValidLoadPlace, currentLoadHeigt = self:getFirstValidLoadPlace()
                    if firstValidLoadPlace ~= -1 then
                        local currentAutoLoadType = spec.autoLoadTypes[spec.currentautoLoadTypeIndex];
                        local loadPlaces = currentAutoLoadType.places;
                        local loadPlace = loadPlaces[firstValidLoadPlace]
                        local x,y,z = localToWorld(loadPlace.node, 0, currentLoadHeigt, 0);
                        local objectNodeId = object.nodeId or object.components[1].node
                        local rx,ry,rz = getWorldRotation(loadPlace.node);

                        -- bigBags and pallets have two components and appear as vehicle, so we treat them differently
                        if currentAutoLoadType.type == "bigBag" or currentAutoLoadType.type == "pallet" then
                            object:removeFromPhysics()
                            object:setAbsolutePosition(x, y, z, rx, ry, rz)
                            object:addToPhysics()
                        else
                            removeFromPhysics(objectNodeId)
                            
                            if currentAutoLoadType.type == "roundbale" then
                                -- round bales must be raised up half size, because the zero point is in the middle of the bale and not on the bottom
                                y = y + (currentAutoLoadType.sizeY / 2)
                                -- round bales also must be rotated by 90° in x to have the flat side on the bottom
                                rx = rx + math.rad(90);
                            end
                            if currentAutoLoadType.type == "squarebale" then
                                -- square bales must be raised up half size, because the zero point is in the middle of the bale and not on the bottom
                                y = y + (currentAutoLoadType.sizeY / 2)
                            end
                            if currentAutoLoadType.type == "cottonSquarebale" then
                                -- cotton square bales must be raised up half size, because the zero point is in the middle of the bale and not on the bottom
                                y = y + (currentAutoLoadType.sizeY / 2)
                            end

                            setWorldRotation(objectNodeId, rx,ry,rz)
                            setTranslation(objectNodeId, x, y, z)

                            addToPhysics(objectNodeId)
                        end

                        local vx, vy, vz = getLinearVelocity(self:getParentComponent(loadPlace.node))
                        if vx ~= nil then
                            setLinearVelocity(objectNodeId, vx, vy, vz)
                        end
                        
                        -- objekt als geladen markieren, damit nur hier auch entladen wird
                        object.currentlyLoadedOnAPalletAutoLoaderId = self.id;
                        
                        spec.triggeredObjects[object] = 0
                        spec.numTriggeredObjects = spec.numTriggeredObjects + 1

                        -- Create Joint to keep the object on the place even if moving
                        if spec.objectsToJoint[objectNodeId] == nil and self.spec_tensionBelts ~= nil and self.spec_tensionBelts.jointNode ~= nil then
                            local constr = JointConstructor.new()

                            constr:setActors(self.spec_tensionBelts.jointNode, objectNodeId)

                            local jointTransform = createTransformGroup("tensionBeltJoint")

                            link(self.spec_tensionBelts.linkNode, jointTransform)

                            local x, y, z = localToWorld(objectNodeId, getCenterOfMass(objectNodeId))

                            setWorldTranslation(jointTransform, x, y, z)
                            constr:setJointTransforms(jointTransform, jointTransform)
                            constr:setRotationLimit(0, 0, 0)
                            constr:setRotationLimit(1, 0, 0)
                            constr:setRotationLimit(2, 0, 0)

                            local springForce = 1000
                            local springDamping = 10

                            constr:setRotationLimitSpring(springForce, springDamping, springForce, springDamping, springForce, springDamping)
                            constr:setTranslationLimitSpring(springForce, springDamping, springForce, springDamping, springForce, springDamping)

                            local jointIndex = constr:finalize()

                            -- save info for release items
                            spec.objectsToJoint[objectNodeId] = {
                                jointIndex = jointIndex,
                                jointTransform = jointTransform,
                                object = object
                            }
                        end
                                                
                        if spec.objectsToLoad[object.rootNode] ~= nil then
                            spec.objectsToLoad[object.rootNode] = nil;
                            spec.objectsToLoadCount = spec.objectsToLoadCount - 1;
                        end
                        
                        if spec.balesToLoad[object] ~= nil then
                            spec.balesToLoad[object] = nil;
                            spec.objectsToLoadCount = spec.objectsToLoadCount - 1;
                        end
                        
                        if spec.numTriggeredObjects >= currentAutoLoadType.maxItems then
                            spec.loadingState = APalletAutoLoaderLoadingState.STOPPED;
                            spec.usedPositions = {};
                        end
                        
                        self:raiseDirtyFlags(spec.dirtyFlag)
                        
                        return true;
                    else
                        spec.loadingState = APalletAutoLoaderLoadingState.STOPPED;
                        spec.usedPositions = {};
                        spec.isFullLoaded = true;
                    end
                end
            end
        end
    end
    
    return false;
end

---
function APalletAutoLoader:unloadAll()
    local spec = self.spec_aPalletAutoLoader
    
    spec.loadingState = APalletAutoLoaderLoadingState.STOPPED;
    spec.usedPositions = {};
    spec.isFullLoaded = false;

    for object,_ in pairs(spec.triggeredObjects) do
        if object ~= nil and (object.currentlyLoadedOnAPalletAutoLoaderId == nil or object.currentlyLoadedOnAPalletAutoLoaderId == self.id) then
            local objectNodeId = object.nodeId or object.components[1].node
            
            -- store current rotation to restore later
            local rx,ry,rz = getWorldRotation(objectNodeId); 
            
            -- set rotation to trailer rotation to move to a side
            setWorldRotation(objectNodeId, getWorldRotation(self.rootNode))
            
            --local x,y,z = localToWorld(objectNodeId, -3, -0.5, 0);
            local x,y,z = localToWorld(objectNodeId, unpack(spec.UnloadOffset[spec.currentTipside]));

            --bigBags have two components and appear as vehicle, so we treat them differently
            if spec.autoLoadTypes[spec.currentautoLoadTypeIndex].type == "bigBag" then
                object:removeFromPhysics()
                object:setAbsolutePosition(x, y, z, rx, ry, rz)
                object:addToPhysics()
            else
                -- move object and restore rotation
                removeFromPhysics(objectNodeId)
                setWorldRotation(objectNodeId, rx,ry,rz)
                setTranslation(objectNodeId, x, y, z)
                addToPhysics(objectNodeId)
            end
            
            object.currentlyLoadedOnAPalletAutoLoaderId = nil;
            
            if object.addDeleteListener ~= nil then
                object:addDeleteListener(self, "onDeleteAPalletAutoLoaderObject")
            end
        end
    end
    spec.triggeredObjects = {}
    spec.numTriggeredObjects = 0
    self:setAllTensionBeltsActive(false, false)
    self:raiseDirtyFlags(spec.dirtyFlag)
end


---Called on on update
-- @param integer streamId stream ID
-- @param integer timestamp timestamp
-- @param table connection connection
function APalletAutoLoader:onReadUpdateStream(streamId, timestamp, connection)
    local spec = self.spec_aPalletAutoLoader

    if not connection:getIsServer() then
        -- print("Received from Client");
        local callUnloadAll = streamReadBool(streamId);
        
        if callUnloadAll then
            self:unloadAll()
        end
    else
        -- print("Received from Server");
        local hasChanges = false;
        local numTriggeredObjects = streamReadInt32(streamId);
        if spec.numTriggeredObjects ~= numTriggeredObjects then
            spec.numTriggeredObjects = numTriggeredObjects;
            hasChanges = true;
        end
        local objectsToLoadCount = streamReadInt32(streamId);
        if spec.objectsToLoadCount ~= objectsToLoadCount then
            spec.objectsToLoadCount = objectsToLoadCount;
            hasChanges = true;
        end 
        local currentautoLoadTypeIndex = streamReadInt32(streamId);
        if spec.currentautoLoadTypeIndex ~= currentautoLoadTypeIndex then
            spec.currentautoLoadTypeIndex = currentautoLoadTypeIndex;
            hasChanges = true;
        end   
        local currentTipside = streamReadInt32(streamId);
        if spec.currentTipside ~= currentTipside then
            spec.currentTipside = currentTipside;
            spec.tipsideText = g_i18n:getText("aPalletAutoLoader_tipside") .. ": " .. g_i18n:getText("aPalletAutoLoader_" .. spec.currentTipside)
            hasChanges = true;
        end   
        local loadingState = streamReadInt32(streamId);
        if spec.loadingState ~= loadingState then
            spec.loadingState = loadingState;
            hasChanges = true;
        end   
        local isFullLoaded = streamReadBool(streamId);
        if spec.isFullLoaded ~= isFullLoaded then
            spec.isFullLoaded = isFullLoaded;
            hasChanges = true;
        end   
        local useTensionBelts = streamReadBool(streamId);
        if spec.useTensionBelts ~= useTensionBelts then
            spec.useTensionBelts = useTensionBelts;
            hasChanges = true;
        end   
        
        if hasChanges then
            APalletAutoLoader.updateActionText(self);
        end
    end
end


---Called on on update
-- @param integer streamId stream ID
-- @param table connection connection
-- @param integer dirtyMask dirty mask
function APalletAutoLoader:onWriteUpdateStream(streamId, connection, dirtyMask)
    local spec = self.spec_aPalletAutoLoader

    if connection:getIsServer() then
        -- print("Send to Server");
        streamWriteBool(streamId, spec.callUnloadAll)
        
        -- zurücksetzen
        spec.callUnloadAll = false;
    else
        -- print("Send to Client");
        streamWriteInt32(streamId, spec.numTriggeredObjects);
        streamWriteInt32(streamId, spec.objectsToLoadCount); 
        streamWriteInt32(streamId, spec.currentautoLoadTypeIndex);
        streamWriteInt32(streamId, spec.currentTipside)
        streamWriteInt32(streamId, spec.loadingState)
        streamWriteBool(streamId, spec.isFullLoaded)
        streamWriteBool(streamId, spec.useTensionBelts)
    end
end

---
function APalletAutoLoader:autoLoaderPickupTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    if otherActorId ~= 0 then
        local object = g_currentMission:getNodeObject(otherActorId)
        if object ~= nil then
            if self:getIsAutoLoadingAllowed() and self:getIsValidObject(object) then
                local spec = self.spec_aPalletAutoLoader
                if onEnter then
                    if not object:isa(Bale) then
                        if spec.objectsToLoad[object.rootNode] == nil and spec.triggeredObjects[object] == nil then
                            spec.objectsToLoad[object.rootNode] = object;
                            spec.objectsToLoadCount = spec.objectsToLoadCount + 1;
                            self:raiseDirtyFlags(spec.dirtyFlag)
                            APalletAutoLoader.updateActionText(self);
                            if object.addDeleteListener ~= nil then
                                object:addDeleteListener(self, "onDeleteObjectToLoad")
                            end
                        end
                    else
                        -- ballen sind keine objekte mit rootNode, also in andere liste packen?
                        if spec.balesToLoad[object] == nil and spec.triggeredObjects[object] == nil then
                            spec.balesToLoad[object] = true;
                            spec.objectsToLoadCount = spec.objectsToLoadCount + 1;
                            self:raiseDirtyFlags(spec.dirtyFlag)
                            APalletAutoLoader.updateActionText(self);
                            if object.addDeleteListener ~= nil then
                                object:addDeleteListener(self, "onDeleteObjectToLoad")
                            end
                        end
                    end
                    -- Ladevorgang starten, wenn Laden aktiv
                    if spec.loadingState == APalletAutoLoaderLoadingState.RUNNING then
                        self:StartLoading();
                    end
                elseif onLeave then
                    if not object:isa(Bale) then
                        if spec.objectsToLoad[object.rootNode] ~= nil then
                            spec.objectsToLoad[object.rootNode] = nil;
                            spec.objectsToLoadCount = spec.objectsToLoadCount - 1;
                            self:raiseDirtyFlags(spec.dirtyFlag)
                            APalletAutoLoader.updateActionText(self);
                            if object.removeDeleteListener ~= nil then
                                object:removeDeleteListener(self, "onDeleteObjectToLoad")
                            end
                        end
                    else
                        if spec.balesToLoad[object] ~= nil then
                            spec.balesToLoad[object] = nil;
                            spec.objectsToLoadCount = spec.objectsToLoadCount - 1;
                            self:raiseDirtyFlags(spec.dirtyFlag)
                            APalletAutoLoader.updateActionText(self);
                            if object.removeDeleteListener ~= nil then
                                object:removeDeleteListener(self, "onDeleteObjectToLoad")
                            end
                        end
                    end
                end
            end
        end
    end
end

-- local rX, rY, rZ = getRotation(place.node);
-- print("place.node rX:"..rX.." rY:"..rY.." rZ:"..rZ);

-- print("loadingPattern")
-- DebugUtil.printTableRecursively(loadingPattern,"_",0,2)

function APalletAutoLoader:autoLoaderTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    local spec = self.spec_aPalletAutoLoader

    if onEnter then
        local object = g_currentMission:getNodeObject(otherActorId)
        if object ~= nil then
            if self:getIsValidObject(object) then
                if spec.triggeredObjects[object] == nil then
                    spec.triggeredObjects[object] = 0
                    spec.numTriggeredObjects = spec.numTriggeredObjects + 1
                    object.currentlyLoadedOnAPalletAutoLoaderId = self.id;
                end

                if spec.triggeredObjects[object] == 0 then
                    if object.addDeleteListener ~= nil then
                        object:addDeleteListener(self, "onDeleteAPalletAutoLoaderObject")
                    end
                end

                spec.triggeredObjects[object] = spec.triggeredObjects[object] + 1
                self:raiseDirtyFlags(spec.dirtyFlag)
            end
        end
    elseif onLeave then
        local object = g_currentMission:getNodeObject(otherActorId)
        if object ~= nil then
-- print("test");
            -- if self:getIsValidObject(object) then
                if spec.triggeredObjects[object] ~= nil then
                    spec.triggeredObjects[object] = spec.triggeredObjects[object] - 1

                    if spec.triggeredObjects[object] == 0 then
                        spec.triggeredObjects[object] = nil
                        spec.numTriggeredObjects = spec.numTriggeredObjects - 1
                        object.currentlyLoadedOnAPalletAutoLoaderId = nil;
                        
                        if object.removeDeleteListener ~= nil then
                            object:removeDeleteListener(self, "onDeleteAPalletAutoLoaderObject")
                        end
                        self:raiseDirtyFlags(spec.dirtyFlag)
                    end

                    if next(spec.triggeredObjects) == nil then
                        spec.currentPlace = 1
                    end
                end
            -- end
        end
    end
end

---
function APalletAutoLoader:onDeleteAPalletAutoLoaderObject(object)
    local spec = self.spec_aPalletAutoLoader

    if spec.triggeredObjects[object] ~= nil then
        spec.triggeredObjects[object] = nil
        spec.numTriggeredObjects = spec.numTriggeredObjects - 1

        if next(spec.triggeredObjects) == nil then
            spec.currentPlace = 1
        end
    end
end

---
function APalletAutoLoader:onDeleteObjectToLoad(object)
    local spec = self.spec_aPalletAutoLoader
    
    if spec.objectsToLoad[object.rootNode] ~= nil then
        spec.objectsToLoad[object.rootNode] = nil;
        spec.objectsToLoadCount = spec.objectsToLoadCount - 1;
    end
                        
    if spec.balesToLoad[object] ~= nil then
        spec.balesToLoad[object] = nil;
        spec.objectsToLoadCount = spec.objectsToLoadCount - 1;
    end
    
    if not self.isServer then
        self:raiseDirtyFlags(spec.dirtyFlag)
    else
        APalletAutoLoader.updateActionText(self);
    end
end

function APalletAutoLoader:getUseTurnedOnSchema()
    local spec = self.spec_aPalletAutoLoader
	return spec.loadingState == APalletAutoLoaderLoadingState.RUNNING
end

function APalletAutoLoader:getFillUnitCapacity(superFunc, fillUnitIndex)
    local spec = self.spec_aPalletAutoLoader

    if spec == nil or spec.loadArea["baseNode"] == nil or fillUnitIndex ~= nil then
        return superFunc(self, fillUnitIndex);
    end

    return spec.autoLoadTypes[spec.currentautoLoadTypeIndex].maxItems;
    
end

function APalletAutoLoader:getFillUnitFillLevel(superFunc, fillUnitIndex)
    local spec = self.spec_aPalletAutoLoader

    if spec == nil or spec.loadArea["baseNode"] == nil or fillUnitIndex ~= nil then
        return superFunc(self, fillUnitIndex);
    end

    return spec.numTriggeredObjects;
    
end

function APalletAutoLoader:getFillUnitFreeCapacity(superFunc, fillUnitIndex)
    local spec = self.spec_aPalletAutoLoader

    if spec == nil or spec.loadArea["baseNode"] == nil or fillUnitIndex ~= nil then
        return superFunc(self, fillUnitIndex);
    end

    if spec.isFullLoaded then 
        return 0;
    end
    
    return spec.autoLoadTypes[spec.currentautoLoadTypeIndex].maxItems - spec.numTriggeredObjects;
    
end