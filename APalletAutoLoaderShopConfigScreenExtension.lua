
-- test im Shop daten an zu zeigen
APalletAutoLoaderShopConfigScreenExtension = {}
function APalletAutoLoaderShopConfigScreenExtension:registerCustomSpecValues(superFunc, values, storeItems, vehicle, saleItem)
	-- print("APalletAutoLoaderShopConfigScreenExtension:registerCustomSpecValues")
	
	superFunc(self, values, storeItems, vehicle, saleItem)
	
	local spec = vehicle.spec_aPalletAutoLoader
	
	if spec == nil or spec.loadArea["baseNode"] == nil then
		return false;
	end
	
	-- Ballen einfach nur die erste Zeile
	local text = "AL: ";
	local usedItems = 0;
	for index, shopText in ipairs(spec.squareBaleShopText) do
		if text ~= "AL: " then
			text = text .. " - ";
		end
		text = text .. shopText;
		usedItems = usedItems + 1;
		
		-- zwischenschritte ausgeben
		if string.len(text) >= 60 then
			break;
		end
	end
	
	if usedItems ~= #spec.squareBaleShopText then
		text = text .. " - ...";
	end
	-- ausgeben
	if text ~= "AL: " then
		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.BALE_SIZE_SQUARE,
			value = text
		})
		text = "AL: ";
		usedItems = 0
	end
	
	for index, shopText in ipairs(spec.roundBaleShopText) do
		if text ~= "AL: " then
			text = text .. " - ";
		end
		text = text .. shopText;
		usedItems = usedItems + 1;
		
		-- zwischenschritte ausgeben
		if string.len(text) >= 60 then
			break;
		end
	end
	
	if usedItems ~= #spec.roundBaleShopText then
		text = text .. " - ...";
	end
	-- rest ausgeben
	if text ~= "AL: " then
		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.BALE_SIZE_ROUND,
			value = text
		})
		text = "AL: ";
		usedItems = 0
	end
	
	
	-- Paletten so viele Zeilen bis es dann 9 sind
	local text = "AL: ";
	local usedItems = 0;
	local currentLineLength = 4;
	local currentLines = 1;
	local profileToUse = ShopConfigScreen.GUI_PROFILE.CAPACITY;
	local maxInnerLines = 2;
	for index, shopText in ipairs(spec.palletShopText) do
		if currentLineLength >= 60 then
			if currentLines == maxInnerLines then
				if #values == 8 then
					break;
				end
				-- neues Element einfügen
				table.insert(values, {
					profile = profileToUse,
					value = text
				})
				text = "";
				currentLineLength = 4;
				currentLines = 1;
				profileToUse = "";
				if maxInnerLines == 2 then 
					maxInnerLines = 3;
				else
					maxInnerLines = 2;
				end
			else
				text = text .. "\n";
				currentLineLength = 0
				currentLines = currentLines + 1
			end
		end
		if text ~= "AL: " and text ~= "" and currentLineLength ~= 0 then
			text = text .. " - "
		end
		
		text = text .. shopText;
		usedItems = usedItems + 1;
		currentLineLength = currentLineLength + string.len(shopText) + 3
		
		
	end
	
	if usedItems ~= #spec.palletShopText then
		text = text .. " - ...";
	end
	-- ausgeben
	if text ~= "AL: " and text ~= "" then
		table.insert(values, {
			profile = profileToUse,
			value = text
		})
		text = "AL: ";
		usedItems = 0
	end
	
	
	
end

ShopConfigScreen.registerCustomSpecValues = Utils.overwrittenFunction(ShopConfigScreen.registerCustomSpecValues, APalletAutoLoaderShopConfigScreenExtension.registerCustomSpecValues)