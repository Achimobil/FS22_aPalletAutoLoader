---Specialization for automatically load objects onto a vehicle by Achimobil
-- It is not allowed to copy my code complete or in Parts into other mods
-- If you have any issues please report them in my Discord on the channel for the mod.
-- https://discord.gg/Va7JNnEkcW

APalletAutoLoader = {}







---
function APalletAutoLoader.prerequisitesPresent(specializations)
    return true
end

---
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
    schema:register(XMLValueType.NODE_INDEX, baseXmlPath .. ".loadArea#baseNode", "Base node for loading")
    schema:register(XMLValueType.VECTOR_TRANS, baseXmlPath .. ".loadArea#leftRightCornerOffset", "Offset for the left corner, loading will be done starting this point")
    schema:register(XMLValueType.FLOAT, baseXmlPath .. ".loadArea#lenght", "length of the loadArea")
    schema:register(XMLValueType.FLOAT, baseXmlPath .. ".loadArea#height", "height of the loadArea")
    schema:register(XMLValueType.FLOAT, baseXmlPath .. ".loadArea#width", "width of the loadArea")

    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).FS22_aPalletAutoLoader.aPalletAutoLoader#lastUsedPalletTypeIndex", "Last used pallet type")
end

---
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
end

---
function APalletAutoLoader.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDynamicMountTimeToMount", APalletAutoLoader.getDynamicMountTimeToMount)
end

---
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
                DebugUtil.drawDebugCircleAtNode(loadPlace.node, radius, 20, color, vertical, offset)
            else
                local sizeX = autoLoadType.sizeX/2;
                local sizeZ = autoLoadType.sizeZ/2;
                DebugUtil.drawDebugRectangle(loadPlace.node, -sizeX, sizeX, -sizeZ, sizeZ, 0, r, g, b)
            end
        end
    end
end

---
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
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            spec.actionEventId = actionEventId;
            
            local state, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AL_TOGGLE_LOADINGTYPE, self, APalletAutoLoader.actionEventToggleAutoLoadTypes, false, true, false, true, nil, nil, true, true)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            spec.toggleAutoLoadTypesActionEventId = actionEventId;
            
            local state, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AL_TOGGLE_TIPSIDE, self, APalletAutoLoader.actionEventToggleTipside, false, true, false, true, nil, nil, true, true)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            spec.toggleTipsideActionEventId = actionEventId;
            
            local state, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AL_UNLOAD, self, APalletAutoLoader.actionEventUnloadAll, false, true, false, true, nil, nil, true, true)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            spec.unloadAllEventId = actionEventId;
            
            local state, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AL_TOGGLE_MARKERS, self, APalletAutoLoader.actionEventToggleMarkers, false, true, false, true, nil, nil, true, true)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            spec.toggleMarkerEventId = actionEventId;
            
            
            APalletAutoLoader.updateActionText(self);
        end
    end
end

---
function APalletAutoLoader.updateActionText(self)
    if self.isClient then
        local spec = self.spec_aPalletAutoLoader
        
        if not spec.available then
            g_inputBinding:setActionEventActive(spec.actionEventId, false)
            g_inputBinding:setActionEventActive(spec.toggleAutoLoadTypesActionEventId, false)
            g_inputBinding:setActionEventActive(spec.toggleTipsideActionEventId, false)
            g_inputBinding:setActionEventActive(spec.unloadAllEventId, false)
            g_inputBinding:setActionEventActive(spec.toggleMarkerEventId, false)
            return;
        end
        
        local text;
        if spec.objectsToLoadCount == 0 then
            text = g_i18n:getText("aPalletAutoLoader_nothingToLoad")
            g_inputBinding:setActionEventActive(spec.actionEventId, false)
        else
            text = g_i18n:getText("aPalletAutoLoader_loadPallets") .. ": " .. spec.objectsToLoadCount
            g_inputBinding:setActionEventText(spec.actionEventId, text)
            g_inputBinding:setActionEventActive(spec.actionEventId, true)
        end
        
        local loadingText = ""
        if (spec.autoLoadTypes == nil or spec.autoLoadTypes[spec.currentautoLoadTypeIndex] == nil) then
            loadingText = g_i18n:getText("aPalletAutoLoader_LoadingType") .. ": " .. "unknown"
        else
            loadingText = g_i18n:getText("aPalletAutoLoader_LoadingType") .. ": " .. g_i18n:getText("aPalletAutoLoader_" .. spec.autoLoadTypes[spec.currentautoLoadTypeIndex].name)
        end
        g_inputBinding:setActionEventText(spec.toggleAutoLoadTypesActionEventId, loadingText)
        
        local tipsideText = g_i18n:getText("aPalletAutoLoader_tipside") .. ": " .. g_i18n:getText("aPalletAutoLoader_" .. spec.currentTipside)
        g_inputBinding:setActionEventText(spec.toggleTipsideActionEventId, tipsideText)
        
        -- deactivate when somthing is already loaded or not
        g_inputBinding:setActionEventActive(spec.toggleAutoLoadTypesActionEventId, spec.numTriggeredObjects == 0)
        g_inputBinding:setActionEventActive(spec.unloadAllEventId, spec.numTriggeredObjects ~= 0)
        g_inputBinding:setActionEventActive(spec.toggleMarkerEventId, true)
    end
end

---
function APalletAutoLoader.actionEventToggleLoading(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_aPalletAutoLoader
    
    if not self.isServer then
        -- Ladebefehl in den stream schreiben
        spec.LoadNextObject = true;
        self:raiseDirtyFlags(spec.dirtyFlag)
    else
        if (spec.timerId == nil) then
            self:loadAllInRange();
            APalletAutoLoader.updateActionText(self);
        end
    end
end

---
function APalletAutoLoader.actionEventToggleAutoLoadTypes(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_aPalletAutoLoader
    
    if spec.currentautoLoadTypeIndex >= #spec.autoLoadTypes then
        spec.currentautoLoadTypeIndex = 1;
    else
        spec.currentautoLoadTypeIndex = spec.currentautoLoadTypeIndex + 1;
    end
    self:raiseDirtyFlags(spec.dirtyFlag)
    APalletAutoLoader.updateActionText(self);
end

---
function APalletAutoLoader.actionEventToggleTipside(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_aPalletAutoLoader
    
    if spec.currentTipside == "left" then
        spec.currentTipside = "right";
    else
        spec.currentTipside = "left";
    end
    self:raiseDirtyFlags(spec.dirtyFlag)
    APalletAutoLoader.updateActionText(self);
end

function APalletAutoLoader.actionEventToggleMarkers(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_aPalletAutoLoader
    
    spec.showMarkers = not spec.showMarkers;
end

---
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

---Called on loading
-- @param table savegame savegame
function APalletAutoLoader:onLoad(savegame)

    local aPalletAutoLoaderConfigurationId = Utils.getNoNil(self.configurations["aPalletAutoLoader"], 1)
    local baseXmlPath = string.format("vehicle.aPalletAutoLoader.APalletAutoLoaderConfigurations.APalletAutoLoaderConfiguration(%d)", aPalletAutoLoaderConfigurationId -1)
            
    -- hier für server und client
    self.spec_aPalletAutoLoader = {}
    local spec = self.spec_aPalletAutoLoader
    spec.LoadNextObject = false;
    spec.callUnloadAll = false;
    spec.objectsToLoadCount = 0;    
    spec.dirtyFlag = self:getNextDirtyFlag()
    spec.numTriggeredObjects = 0
    spec.currentTipside = "left";
    spec.currentautoLoadTypeIndex = 1;
    spec.available = false;
    spec.showMarkers = false;
    
    -- load the loading area
    spec.loadArea = {};
    spec.loadArea["baseNode"] = self.xmlFile:getValue(baseXmlPath..".loadArea#baseNode", nil, self.components, self.i3dMappings);
    spec.loadArea["leftRightCornerOffset"] = self.xmlFile:getValue(baseXmlPath .. ".loadArea#leftRightCornerOffset", "0 0 0", true);
    spec.loadArea["lenght"] = self.xmlFile:getValue(baseXmlPath .. ".loadArea#lenght") or 5
    spec.loadArea["height"] = self.xmlFile:getValue(baseXmlPath .. ".loadArea#height") or 2
    spec.loadArea["width"] = self.xmlFile:getValue(baseXmlPath .. ".loadArea#width") or 2
    spec.UnloadOffset = {}
    spec.UnloadOffset["right"] = self.xmlFile:getValue(baseXmlPath .. "#UnloadRightOffset", "-3 -0.5 0", true)
    spec.UnloadOffset["left"] = self.xmlFile:getValue(baseXmlPath .. "#UnloadLeftOffset", "3 -0.5 0", true)
    
    if spec.loadArea["baseNode"] == nil then
        return;
    end
    
    spec.available = true;
    
    -- ,"cottonSquarebale488" Bauwollquaderballen können aktuell nicht befestigt werden und machen nur fehler, deshalb zwar implementiert, aber nicht aktiviert.
    local types = {"euroPallet","liquidTank","bigBagPallet","cottonRoundbale238","euroPalletOversize", "roundbale125", "roundbale150"}  
    
    -- create loadplaces automatically from load Area size
    if spec.loadArea["baseNode"] ~= nil then
        spec.autoLoadTypes = {};
        for i,name in ipairs(types) do
            local autoLoadObject = {}
            autoLoadObject.index = spec.loadArea["baseNode"]
            autoLoadObject.name = name
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
                backDistance = 0.05;
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
                    
                    print("autoLoadObject.name:" .. autoLoadObject.name);
                    print("autoLoadObject.sizeX:" .. autoLoadObject.sizeX);
                    print("rowX1:" .. rowX1);
                    print("rowX2:" .. rowX2);
                    print("optimalDistanceZ:" ..optimalDistanceZ );
                    print("distanceZ:" .. distanceZ);                    
                    
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
                            loadingPatternItem.rotation = (3.1415927 / 2);
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
                
                setRotation(place.node, 0, loadingPatternItem.rotation, 0)
                setTranslation(place.node, loadingPatternItem.posX, cornerY, loadingPatternItem.posZ)
                table.insert(autoLoadObject.places, place)
            end
            
            if #autoLoadObject.places ~= 0 then
                table.insert(spec.autoLoadTypes, autoLoadObject)
            end
        end
    end
    
    if self.isServer then
        spec.objectsToLoad = {};
        spec.balesToLoad = {};

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
        spec.maxObjects = self.xmlFile:getValue(baseXmlPath .. "#maxObjects") or 50
        spec.useBales = self.xmlFile:getValue(baseXmlPath .. "#useBales", false)
        spec.useTensionBelts = self.xmlFile:getValue(baseXmlPath .. "#useTensionBelts", not GS_IS_MOBILE_VERSION)
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
end

---
function APalletAutoLoader:AddSupportedObjects(autoLoadObject, name)
    if (name == "euroPallet") then
        local function CheckType(object)
            if object.configFileName == "data/objects/pallets/pioneer/pioneerPallet.xml" then return false end
            if object.configFileName == "data/objects/pallets/grapePallet/grapePallet.xml" then return true end
            if object.configFileName == "data/objects/pallets/schaumann/schaumannPallet.xml" then return false end
        
            if object.i3dMappings == nil then 
                return false;
            end
            
            for mappingName, _ in pairs(object.i3dMappings) do
                if (mappingName == "euroPalletVis") or (mappingName == "pallet_vis") then
                return true;
                end
            end
            
            return false;
        end    
    
        autoLoadObject.CheckTypeMethod = CheckType
        autoLoadObject.sizeX = 1.2
        autoLoadObject.sizeY = 0.8
        autoLoadObject.sizeZ = 0.8
        autoLoadObject.type = "pallet"
    elseif (name == "euroPalletOversize") then
        local function CheckType(object)
            if object.configFileName == "data/objects/pallets/schaumann/schaumannPallet.xml" then return true end
            if object.configFileName == "data/objects/ksAG/patentkali/patentkali.xml" then return true end
            if object.configFileName == "data/objects/ksAG/epsoTop/epsoTop.xml" then return true end
            if object.configFileName == "data/objects/pallets/pioneer/pioneerPallet.xml" then return true end
                        
            return false;
        end    
    
        autoLoadObject.CheckTypeMethod = CheckType
        autoLoadObject.sizeX = 1.3
        autoLoadObject.sizeY = 0.8
        autoLoadObject.sizeZ = 1.0
        autoLoadObject.type = "pallet"
    elseif (name == "liquidTank") then
        local function CheckType(object)
            if string.find(object.i3dFilename, "data/objects/pallets/liquidTank") then
                return true;
            end
            return false;
        end    
    
        autoLoadObject.CheckTypeMethod = CheckType
        autoLoadObject.sizeX = 1.32
        autoLoadObject.sizeY = 2
        autoLoadObject.sizeZ = 1.32
        autoLoadObject.type = "pallet"
    elseif (name == "bigBagPallet") then
        local function CheckType(object)
        
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
        autoLoadObject.sizeY = 2
        autoLoadObject.sizeZ = 1.2
        autoLoadObject.type = "pallet"
    elseif (name == "cottonRoundbale238") then
        local function CheckType(object)
            if string.find(object.i3dFilename, "data/objects/cottonModules/cottonRoundbale238.i3d") then
                return true;
            end
            return false;
        end    
    
        autoLoadObject.CheckTypeMethod = CheckType
        autoLoadObject.sizeX = 2.38
        autoLoadObject.sizeY = 2.38
        autoLoadObject.sizeZ = 2.38
        autoLoadObject.type = "roundbale"
    elseif (name == "cottonSquarebale488") then
        local function CheckType(object)
            if string.find(object.i3dFilename, "data/objects/cottonModules/cottonSquarebale488.i3d") then
                return true;
            end
            return false;
        end    
    
        autoLoadObject.CheckTypeMethod = CheckType
        autoLoadObject.sizeX = 2.44
        autoLoadObject.sizeY = 2.44
        autoLoadObject.sizeZ = 4.88
        autoLoadObject.type = "cottonSquarebale"
    elseif (name == "roundbale125") then
        local function CheckType(object)
            if string.find(object.i3dFilename, "data/objects/roundbales/roundbale125/roundbale125.i3d") then
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
            if string.find(object.i3dFilename, "data/objects/roundbales/roundbale150/roundbale150.i3d") then
                return true;
            end
            return false;
        end    
    
        autoLoadObject.CheckTypeMethod = CheckType
        autoLoadObject.sizeX = 1.50
        autoLoadObject.sizeY = 1.20
        autoLoadObject.sizeZ = 1.50
        autoLoadObject.type = "roundbale"
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
    
    local objectFilename = object.configFileName or object.i3dFilename
    if objectFilename ~= nil then
        if object.typeName == "pallet" then
            return true
        end
        if object.typeName == "treeSaplingPallet" then
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

    -- Hier die loading position und das loading objekt nehmen und die erste ladeposition dafür dynamisch suchen
    -- https://gdn.giants-software.com/documentation_scripting_fs19.php?version=engine&category=15&function=138
    -- overlapBox scheint zu prüfen, ob der angegebene Bereich frei ist
    
    local currentLoadHeigt = 0;
    local autoLoadType = spec.autoLoadTypes[spec.currentautoLoadTypeIndex];
    local loadPlaces = spec.autoLoadTypes[spec.currentautoLoadTypeIndex].places;
    while (currentLoadHeigt + autoLoadType.sizeY)  <= spec.loadArea["height"] do
    
        for i=1, #loadPlaces do
            local loadPlace = loadPlaces[i]
            local x, y, z = localToWorld(loadPlace.node, 0, currentLoadHeigt, 0);
            local rx, ry, rz = getWorldRotation(loadPlace.node)
            
            -- collision mask : all bits except bit 13, 23, 30
            spec.foundObject = false 
                    
            -- TODO: Kollision rund berechnen für rundballen mit richtigem kreis, Kugel klappt nich bei den großen ballen
            if autoLoadType.type == "roundbale" then
                overlapSphere(x, y + (autoLoadType.sizeY / 2), z, autoLoadType.sizeX / 2, "autoLoaderOverlapCallback", self, 3212828671, true, false, true)
            else
                overlapBox(x, y + (autoLoadType.sizeY / 2), z, rx, ry, rz, autoLoadType.sizeX / 2, autoLoadType.sizeY / 2, autoLoadType.sizeZ / 2, "autoLoaderOverlapCallback", self, 3212828671, true, false, true)
            end

            if not spec.foundObject then
                return i, currentLoadHeigt
            end
        end
        
        currentLoadHeigt = currentLoadHeigt + 0.1
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
            loaded = self:loadObject(object);
            if loaded then 
                break;
            end
        end
    end
    for object,_  in pairs(spec.balesToLoad) do
        local isValidLoadType = spec.autoLoadTypes[spec.currentautoLoadTypeIndex].CheckTypeMethod(object);
        if isValidLoadType then
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
                        local loadPlaces = spec.autoLoadTypes[spec.currentautoLoadTypeIndex].places;
                        local loadPlace = loadPlaces[firstValidLoadPlace]
                        local x,y,z = localToWorld(loadPlace.node, 0, currentLoadHeigt, 0);
                        local objectNodeId = object.nodeId or object.components[1].node
                        local rx,ry,rz = getWorldRotation(loadPlace.node);

                        removeFromPhysics(objectNodeId)
                        
                        if spec.autoLoadTypes[spec.currentautoLoadTypeIndex].type == "roundbale" then
                            -- Baumwollrundballen müssen noch um die höhe hochgesetzt werden und gedreht
                            y = y + (spec.autoLoadTypes[spec.currentautoLoadTypeIndex].sizeY / 2)
                            rx = rx + (3.1415927 / 2);
                        end
                        if spec.autoLoadTypes[spec.currentautoLoadTypeIndex].type == "cottonSquarebale" then
                            -- Baumwollquaderballen müssen noch um die höhe hochgesetzt werden
                            y = y + (spec.autoLoadTypes[spec.currentautoLoadTypeIndex].sizeY / 2)
                        end

                        setWorldRotation(objectNodeId, rx,ry,rz)
                        setTranslation(objectNodeId, x, y, z)

                        addToPhysics(objectNodeId)

                        local vx, vy, vz = getLinearVelocity(self:getParentComponent(loadPlace.node))
                        if vx ~= nil then
                            setLinearVelocity(objectNodeId, vx, vy+1, vz)
                        end
                        
                        -- objekt als geladen markieren, damit nur hier auch entladen wird
                        object.currentlyLoadedOnAPalletAutoLoaderId = self.id;
                        
                        spec.triggeredObjects[object] = 0
                        spec.numTriggeredObjects = spec.numTriggeredObjects + 1

                        if spec.useTensionBelts and self.setAllTensionBeltsActive ~= nil then
                            self:setAllTensionBeltsActive(false, false)
                            --- PAUSE !!!
                            
                            self:setAllTensionBeltsActive(true, false)
                        end
                        
                        if spec.objectsToLoad[object.rootNode] ~= nil then
                            spec.objectsToLoad[object.rootNode] = nil;
                            spec.objectsToLoadCount = spec.objectsToLoadCount - 1;
                        end
                        
                        if spec.balesToLoad[object] ~= nil then
                            spec.balesToLoad[object] = nil;
                            spec.objectsToLoadCount = spec.objectsToLoadCount - 1;
                        end
                        self:raiseDirtyFlags(spec.dirtyFlag)
                        return true;
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

    for object,_ in pairs(spec.triggeredObjects) do
        if object ~= nil and (object.currentlyLoadedOnAPalletAutoLoaderId == nil or object.currentlyLoadedOnAPalletAutoLoaderId == self.id) then
            local objectNodeId = object.nodeId or object.components[1].node
            
            -- store current rotation to restore later
            local rx,ry,rz = getWorldRotation(objectNodeId); 
            
            -- set rotation to trailer rotation to move to a side
            setWorldRotation(objectNodeId, getWorldRotation(self.rootNode))
            
            --local x,y,z = localToWorld(objectNodeId, -3, -0.5, 0);
            local x,y,z = localToWorld(objectNodeId, unpack(spec.UnloadOffset[spec.currentTipside]));

            -- move object and restore rotation
            removeFromPhysics(objectNodeId)
            setWorldRotation(objectNodeId, rx,ry,rz)
            setTranslation(objectNodeId, x, y, z)
            addToPhysics(objectNodeId)
            
            if object.addDeleteListener ~= nil then
                object:addDeleteListener(self, "onDeleteAPalletAutoLoaderObject")
            end
        end
    end
    spec.triggeredObjects = {}
    spec.numTriggeredObjects = 0
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
        local LoadNextObject = streamReadBool(streamId);
        spec.currentautoLoadTypeIndex = streamReadInt32(streamId);
        spec.currentTipside = streamReadString(streamId);
        local callUnloadAll = streamReadBool(streamId);
        
        if LoadNextObject and spec.timerId == nil then
            -- Load like on non dedi serverside
            self:loadAllInRange();
        end
        
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
        streamWriteBool(streamId, spec.LoadNextObject)
        streamWriteInt32(streamId, spec.currentautoLoadTypeIndex)
        streamWriteString(streamId, spec.currentTipside)
        streamWriteBool(streamId, spec.callUnloadAll)
        
        -- zurücksetzen
        spec.LoadNextObject = false;
        spec.callUnloadAll = false;
    else
        -- print("Send to Client");
        streamWriteInt32(streamId, spec.numTriggeredObjects);
        streamWriteInt32(streamId, spec.objectsToLoadCount); 
        streamWriteInt32(streamId, spec.currentautoLoadTypeIndex);
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

---
function APalletAutoLoader:autoLoaderTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    local spec = self.spec_aPalletAutoLoader

    if onEnter then
        local object = g_currentMission:getNodeObject(otherActorId)
        if object ~= nil then
            if self:getIsValidObject(object) then
                if spec.triggeredObjects[object] == nil then
                    spec.triggeredObjects[object] = 0
                    spec.numTriggeredObjects = spec.numTriggeredObjects + 1
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
            if self:getIsValidObject(object) then
                if spec.triggeredObjects[object] ~= nil then
                    spec.triggeredObjects[object] = spec.triggeredObjects[object] - 1

                    if spec.triggeredObjects[object] == 0 then
                        spec.triggeredObjects[object] = nil
                        spec.numTriggeredObjects = spec.numTriggeredObjects - 1

                        if object.removeDeleteListener ~= nil then
                            object:removeDeleteListener(self, "onDeleteAPalletAutoLoaderObject")
                        end
                        self:raiseDirtyFlags(spec.dirtyFlag)
                    end

                    if next(spec.triggeredObjects) == nil then
                        spec.currentPlace = 1
                    end
                end
            end
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
