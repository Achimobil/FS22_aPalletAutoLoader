SetTipsideEventEvent = {}
local SetTipsideEventEvent_mt = Class(SetTipsideEventEvent, Event)
InitEventClass(SetTipsideEventEvent, "SetTipsideEventEvent")

---
function SetTipsideEventEvent.emptyNew()
    local self = Event.new(SetTipsideEventEvent_mt)
    return self
end

---
function SetTipsideEventEvent.new(aPalletAutoLoader, tipsideIndex)
    local self = SetTipsideEventEvent.emptyNew()
    
    self.aPalletAutoLoader = aPalletAutoLoader
    self.tipsideIndex = tipsideIndex

    return self
end

---
function SetTipsideEventEvent:readStream(streamId, connection)
    self.aPalletAutoLoader = NetworkUtil.readNodeObject(streamId)
    self.tipsideIndex = streamReadInt32(streamId)
    
    self:run(connection)
end

---
function SetTipsideEventEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.aPalletAutoLoader) 
    streamWriteInt32(streamId, self.tipsideIndex)
end

---
function SetTipsideEventEvent:run(connection)
    assert(not connection:getIsServer(), "SetTipsideEventEvent is client to server only")

    -- eintragen was vom client gebraucht wird in die spec
    local spec = self.aPalletAutoLoader;
    spec:SetTipside(self.tipsideIndex)
end

function SetTipsideEventEvent.sendEvent(aPalletAutoLoader, tipsideIndex)
    g_client:getServerConnection():sendEvent(SetTipsideEventEvent.new(aPalletAutoLoader, tipsideIndex))
end