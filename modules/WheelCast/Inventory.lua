--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon  = ...

local WheelCast = addon.WheelCast

local mod       = WheelCast:NewModule('Inventory')
mod.priority    = 40

function mod:OnEnable()
	self:RegisterEvent("BAG_UPDATE_DELAYED", "Update")
	self:Update()
	self:Debug("Enabled")
end

local STANDARD_BAG_FAMILY_ID = 0

local function GetJunkInfo(bag, slot)
	local info = C_Container.GetContainerItemInfo(bag, slot)
	if not info or info.stackCount < 1 or info.isLocked or info.hasLoot or info.IsBound or info.quality > Enum.ItemQuality.Common then
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
	info.bag, info.slot, info.toalPrice = bag, slot, info.stackCount * sellPrice
	return info
end

function mod:Update()
	local cheapestJunk
	local totalFreeSlots, requiredFreeSlots = 0, 1

	for bag = 0, NUM_BAG_SLOTS do
		local numFreeSlots, bagFamily = C_Container.GetContainerNumFreeSlots(bag)
		if bagFamily == STANDARD_BAG_FAMILY_ID then
			totalFreeSlots = totalFreeSlots + numFreeSlots
			for slot = 1, C_Container.GetContainerNumSlots(bag) do
				local junkInfo, stackPrice = GetJunkInfo(bag, slot)
				if junkInfo and (not cheapestJunk or junkInfo.totalPrice < cheapestJunk.totalPrice) then
					cheapestJunk = junkInfo
				end
			end
		end
	end

	self:Debug("Update", "required", requiredFreeSlots, "available", totalFreeSlots, "cheapestJunk",
		cheapestJunk and cheapestJunk.itemName)

	local state = self.state
	if totalFreeSlots >= requiredFreeSlots or not cheapestJunk then
		state.line, state.bag, state.slot = nil, nil, nil
		return
	end

	state.line, state.bag, state.slot = WheelCast.IconLine(cheapestJunk.iconFileID, cheapestJunk.itemName), cheapestJunk
		.bag, cheapestJunk.slot
end

function mod:Update()
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
		cheapestJunk and cheapestJunk.itemName or "<nil>")

	local state = self.state
	if totalFreeSlots >= requiredFreeSlots or not cheapestJunk then
		state.action, state.line, state.bag, state.slot, state.itemID = nil, nil, nil, nil, nil
		return
	end

	state.action = "destroy"
	state.bag, state.slot, state.itemID = cheapestJunk.bag, cheapestJunk.slot, cheapestJunk.itemID
	state.line = WheelCast.IconLine(cheapestJunk.iconFileID, cheapestJunk.itemName)
end

local funcName = mod.name .. "_Destroy"
_G[funcName] = function(bag, slot, itemId)
	C_Container.PickupContainerItem(bag, slot)
	if select(2, GetCursorInfo()) == itemId then
		DeleteCursorItem()
	else
		C_Container.PickupContainerItem(bag, slot)
	end
end


function mod:SetupButton(button)
	local state = self.state
	if state.action == "destroy" then
		button:SetManyAttributes(
			"type", "macro",
			"macrotext", string.format("/run %s(%d, %d, %d)", funcName, state.bag, state.slot, state.itemID)
		)
	end
end
