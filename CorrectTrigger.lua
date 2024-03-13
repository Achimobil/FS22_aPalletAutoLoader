ChangePlaceableInfoTrigger = {}
function ChangePlaceableInfoTrigger:onFinalizePlacement()
	local spec = self.spec_infoTrigger

	if spec.infoTrigger ~= nil then
		local collisionMask = getCollisionMask(spec.infoTrigger);
		local bitStr = MathUtil.numberToSetBitsStr(collisionMask);
		
		local undefinedMask = bitAND(collisionMask, bitNOT(CollisionFlag.TRIGGER_PLAYER));
		local undefinedBitStr = MathUtil.numberToSetBitsStr(collisionMask);
		
		if collisionMask ~= CollisionFlag.TRIGGER_PLAYER then
			-- Logging.xmlWarning(self.xmlFile, "Info trigger collison mask is: %d", collisionMask);
			-- Logging.xmlWarning(self.xmlFile, "Info trigger collison bis is: %s", bitStr);
			-- Logging.xmlWarning(self.xmlFile, "Info trigger collison to much is: %s", undefinedMask);
			-- Logging.xmlWarning(self.xmlFile, "CollisionFlag.TRIGGER_PLAYER: %s", CollisionFlag.TRIGGER_PLAYER);
			-- Logging.xmlWarning(self.xmlFile, "Info trigger collison to remove is: %s", undefinedBitStr);
			if g_showDevelopmentWarnings then
				Logging.xmlWarning(self.xmlFile, "aPalletAutoLoader - Info trigger collison mask has wrong bits. Removing bits, only 20 is allowed. Defined was: %s", undefinedBitStr);
			else
				Logging.xmlInfo(self.xmlFile, "aPalletAutoLoader - Info trigger collison mask has wrong bits. Removing bits, only 20 is allowed. Defined was: %s", undefinedBitStr);
			end
			setCollisionMask(spec.infoTrigger, CollisionFlag.TRIGGER_PLAYER)
		end
		-- if not CollisionFlag.getHasFlagSet(spec.infoTrigger, CollisionFlag.TRIGGER_PLAYER) then
			-- Logging.xmlWarning(self.xmlFile, "Info trigger collison mask is missing bit 'TRIGGER_PLAYER' (%d)", CollisionFlag.getBit(CollisionFlag.TRIGGER_PLAYER))
		-- end
	end
end

PlaceableInfoTrigger.onFinalizePlacement = Utils.prependedFunction(PlaceableInfoTrigger.onFinalizePlacement, ChangePlaceableInfoTrigger.onFinalizePlacement)

ChangePlaceableLights = {}
function ChangePlaceableLights:onFinalizePlacement()

	local spec = self.spec_lights

	if spec.groups ~= nil then
		for _, group in ipairs(spec.groups) do
			
			if group.triggerNode ~= nil then
				local objectType = getRigidBodyType(group.triggerNode)
				
				-- remove wrong coumpound not possible becaus This is only allowed for non-added rigid bodies.
				-- So use has to live with error in log of removing Compound
				-- local isCompound = getIsCompound(group.triggerNode)
				-- if isCompound then
					-- if g_showDevelopmentWarnings then
						-- Logging.xmlWarning(self.xmlFile, "Remove wrong Compound");
					-- else
						-- Logging.xmlInfo(self.xmlFile, "Remove wrong Compound");
					-- end
					-- setIsCompound(group.triggerNode, false)
				-- end
				if objectType ~= RigidBodyType.STATIC then
					if g_showDevelopmentWarnings then
						Logging.xmlWarning(self.xmlFile, "aPalletAutoLoader - Light trigger has wrong RigidBodyType. Change it to static.");
					else
						Logging.xmlInfo(self.xmlFile, "aPalletAutoLoader - Light trigger has wrong RigidBodyType. Change it to static.");
					end
					setRigidBodyType(group.triggerNode, RigidBodyType.STATIC)
				end
			end
		end
	end
end
PlaceableLights.onFinalizePlacement = Utils.prependedFunction(PlaceableLights.onFinalizePlacement, ChangePlaceableLights.onFinalizePlacement)