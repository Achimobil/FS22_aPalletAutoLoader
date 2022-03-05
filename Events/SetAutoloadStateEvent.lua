SetAutoloadStateEvent = {}
local SetAutoloadStateEvent_mt = Class(SetAutoloadStateEvent, Event)
InitEventClass(SetAutoloadStateEvent, "SetAutoloadStateEvent")

---
function SetAutoloadStateEvent.emptyNew()
    local self = Event.new(SetAutoloadStateEvent_mt)
    return self
end

---
function SetAutoloadStateEvent.new(aPalletAutoLoader, loadingState)
    local self = SetAutoloadStateEvent.emptyNew()
    
    self.aPalletAutoLoader = aPalletAutoLoader
    self.loadingState = loadingState

    return self
end

---
function SetAutoloadStateEvent:readStream(streamId, connection)
    self.aPalletAutoLoader = NetworkUtil.readNodeObject(streamId)
    self.loadingState = streamReadInt32(streamId)
    
    self:run(connection)
end

---
function SetAutoloadStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.aPalletAutoLoader) 
    streamWriteInt32(streamId, self.loadingState)
end

---
function SetAutoloadStateEvent:run(connection)
    assert(not connection:getIsServer(), "SetAutoloadStateEvent is client to server only")

    -- eintragen was vom client gebraucht wird in die spec
    local spec = self.aPalletAutoLoader;
    spec:SetLoadingState(self.loadingState)
end

function SetAutoloadStateEvent.sendEvent(aPalletAutoLoader, loadingState)
    g_client:getServerConnection():sendEvent(SetAutoloadStateEvent.new(aPalletAutoLoader, loadingState))
end