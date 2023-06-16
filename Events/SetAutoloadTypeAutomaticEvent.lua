SetAutoloadTypeAutomaticEvent = {}
local SetAutoloadTypeAutomaticEvent_mt = Class(SetAutoloadTypeAutomaticEvent, Event)
InitEventClass(SetAutoloadTypeAutomaticEvent, "SetAutoloadTypeAutomaticEvent")

---
function SetAutoloadTypeAutomaticEvent.emptyNew()
    local self = Event.new(SetAutoloadTypeAutomaticEvent_mt)
    return self
end

---
function SetAutoloadTypeAutomaticEvent.new(aPalletAutoLoader)
    local self = SetAutoloadTypeAutomaticEvent.emptyNew()
    
    self.aPalletAutoLoader = aPalletAutoLoader

    return self
end

---
function SetAutoloadTypeAutomaticEvent:readStream(streamId, connection)
    self.aPalletAutoLoader = NetworkUtil.readNodeObject(streamId)
    
    self:run(connection)
end

---
function SetAutoloadTypeAutomaticEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.aPalletAutoLoader)
end

---
function SetAutoloadTypeAutomaticEvent:run(connection)
    assert(not connection:getIsServer(), "SetAutoloadTypeAutomaticEvent is client to server only")

    -- eintragen was vom client gebraucht wird in die spec
    local spec = self.aPalletAutoLoader;
    spec:SetAutoloadTypeAutomatic()
end

function SetAutoloadTypeAutomaticEvent.sendEvent(aPalletAutoLoader)
    g_client:getServerConnection():sendEvent(SetAutoloadTypeAutomaticEvent.new(aPalletAutoLoader))
end