SetAutoloadTypeEvent = {}
local SetAutoloadTypeEvent_mt = Class(SetAutoloadTypeEvent, Event)
InitEventClass(SetAutoloadTypeEvent, "SetAutoloadTypeEvent")

---
function SetAutoloadTypeEvent.emptyNew()
    local self = Event.new(SetAutoloadTypeEvent_mt)
    return self
end

---
function SetAutoloadTypeEvent.new(aPalletAutoLoader, autoloadTypeIndex)
    local self = SetAutoloadTypeEvent.emptyNew()
    
    self.aPalletAutoLoader = aPalletAutoLoader
    self.autoloadTypeIndex = autoloadTypeIndex

    return self
end

---
function SetAutoloadTypeEvent:readStream(streamId, connection)
    self.aPalletAutoLoader = NetworkUtil.readNodeObject(streamId)
    self.autoloadTypeIndex = streamReadInt32(streamId)
    
    self:run(connection)
end

---
function SetAutoloadTypeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.aPalletAutoLoader) 
    streamWriteInt32(streamId, self.autoloadTypeIndex)
end

---
function SetAutoloadTypeEvent:run(connection)
    assert(not connection:getIsServer(), "SetAutoloadTypeEvent is client to server only")

    -- eintragen was vom client gebraucht wird in die spec
    local spec = self.aPalletAutoLoader;
    spec:SetAutoloadType(self.autoloadTypeIndex)
end

function SetAutoloadTypeEvent.sendEvent(aPalletAutoLoader, autoloadTypeIndex)
    g_client:getServerConnection():sendEvent(SetAutoloadTypeEvent.new(aPalletAutoLoader, autoloadTypeIndex))
end