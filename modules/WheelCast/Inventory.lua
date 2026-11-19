--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon               = ...

local WheelCast              = addon.WheelCast

local mod                    = WheelCast:NewModule('Inventory')
mod.priority                 = 40
mod.SetupAction              = mod.SetMacrotext

local STANDARD_BAG_FAMILY_ID = 0

function mod:OnEnable()
	self:RegisterEvent("BAG_UPDATE_DELAYED", "Update")
	self:Debug("Enabled")
end

local globalDestroyFuncName = mod.name .. "_DestroyContainerItem"
_G[globalDestroyFuncName] = function(bag, slot, itemId)
	C_Container.PickupContainerItem(bag, slot)
	if select(2, GetCursorInfo()) == itemId then
		DeleteCursorItem()
	else
		C_Container.PickupContainerItem(bag, slot)
	end
end

local function GetJunkInfo(bag, slot)
	local info = C_Container.GetContainerItemInfo(bag, slot)
	if not info or (info.stackCount or 0) < 1 or info.isLocked or info.hasLoot or info.IsBound or (info.quality or 100) > Enum.ItemQuality.Common then
		return
	end
	local itemEquipLoc, _, sellPrice, _, _, _, _, _, isCraftingReagent = select(9, C_Item.GetItemInfo(info.itemID))
	if itemEquipLoc ~= "" or isCraftingReagent or not sellPrice or sellPrice == 0 then
		return
	end
	local questInfo = C_Container.GetContainerItemQuestInfo(bag, slot)
	if questInfo and questInfo.isQuestItem then
		return
	end
	info.bag, info.slot, info.totalPrice = bag, slot, info.stackCount * sellPrice
	return info
end

function mod:Test()
	local cheapestJunk
	local totalFreeSlots, requiredFreeSlots = 0, 1

	for bag = 0, NUM_BAG_SLOTS do
		local numFreeSlots, bagFamily = C_Container.GetContainerNumFreeSlots(bag)
		if bagFamily == STANDARD_BAG_FAMILY_ID then
			totalFreeSlots = totalFreeSlots + numFreeSlots
			for slot = 1, C_Container.GetContainerNumSlots(bag) do
				local junkInfo = GetJunkInfo(bag, slot)
				if junkInfo and (not cheapestJunk or junkInfo.totalPrice < cheapestJunk.totalPrice) then
					cheapestJunk = junkInfo
				end
			end
		end
	end

	self:Debug("Update", "required", requiredFreeSlots, "available", totalFreeSlots, "cheapestJunk",
		cheapestJunk and cheapestJunk.itemName)

	if totalFreeSlots >= requiredFreeSlots or not cheapestJunk then
		return
	end

	local label = WheelCast.IconLine(cheapestJunk.iconFileID, "Destroy " .. cheapestJunk.itemName)
	local macrotext = string.format("/run %s(%d, %d, %d)", globalDestroyFuncName, cheapestJunk.bag, cheapestJunk.slot,
		cheapestJunk.itemID)
	return label, macrotext
end
