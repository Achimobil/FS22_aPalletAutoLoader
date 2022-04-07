SetAutomaticTensionBeltsEvent = {}
local SetAutomaticTensionBeltsEvent_mt = Class(SetAutomaticTensionBeltsEvent, Event)
InitEventClass(SetAutomaticTensionBeltsEvent, "SetAutomaticTensionBeltsEvent")

---
function SetAutomaticTensionBeltsEvent.emptyNew()
    local self = Event.new(SetAutomaticTensionBeltsEvent_mt)
    return self
end

---
function SetAutomaticTensionBeltsEvent.new(aPalletAutoLoader, newTensionBeltsValue)
    local self = SetAutomaticTensionBeltsEvent.emptyNew()
    
    self.aPalletAutoLoader = aPalletAutoLoader
    self.newTensionBeltsValue = newTensionBeltsValue

    return self
end

---
function SetAutomaticTensionBeltsEvent:readStream(streamId, connection)
    self.aPalletAutoLoader = NetworkUtil.readNodeObject(streamId)
    self.newTensionBeltsValue = streamReadBool(streamId)
    
    self:run(connection)
end

---
function SetAutomaticTensionBeltsEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.aPalletAutoLoader) 
    streamWriteBool(streamId, self.newTensionBeltsValue)
end

---
function SetAutomaticTensionBeltsEvent:run(connection)
    assert(not connection:getIsServer(), "SetAutomaticTensionBeltsEvent is client to server only")
    
    -- eintragen was vom client gebraucht wird in die spec
    local spec = self.aPalletAutoLoader;
    spec:SetTensionBeltsValue(self.newTensionBeltsValue)
end

function SetAutomaticTensionBeltsEvent.sendEvent(aPalletAutoLoader, newTensionBeltsValue)
    g_client:getServerConnection():sendEvent(SetAutomaticTensionBeltsEvent.new(aPalletAutoLoader, newTensionBeltsValue))
end