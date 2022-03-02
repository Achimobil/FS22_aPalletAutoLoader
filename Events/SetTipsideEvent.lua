SetTipsideEvent = {}
local SetTipsideEvent_mt = Class(SetTipsideEvent, Event)
InitEventClass(SetTipsideEvent, "SetTipsideEvent")

---
function SetTipsideEvent.emptyNew()
    local self = Event.new(SetTipsideEvent_mt)
    return self
end

---
function SetTipsideEvent.new(aPalletAutoLoader, tipsideIndex)
    local self = SetTipsideEvent.emptyNew()
    
    self.aPalletAutoLoader = aPalletAutoLoader
    self.tipsideIndex = tipsideIndex

    return self
end

---
function SetTipsideEvent:readStream(streamId, connection)
    self.aPalletAutoLoader = NetworkUtil.readNodeObject(streamId)
    self.tipsideIndex = streamReadInt32(streamId)
    
    self:run(connection)
end

---
function SetTipsideEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.aPalletAutoLoader) 
    streamWriteInt32(streamId, self.tipsideIndex)
end

---
function SetTipsideEvent:run(connection)
    assert(not connection:getIsServer(), "SetTipsideEvent is client to server only")

    -- eintragen was vom client gebraucht wird in die spec
    local spec = self.aPalletAutoLoader;
    spec:SetTipside(self.tipsideIndex)
end

function SetTipsideEvent.sendEvent(aPalletAutoLoader, tipsideIndex)
    g_client:getServerConnection():sendEvent(SetTipsideEvent.new(aPalletAutoLoader, tipsideIndex))
end