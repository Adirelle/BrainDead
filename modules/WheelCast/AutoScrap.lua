--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local Scrap = _G.Scrap
if not Scrap then return end

local _, addon               = ...

local WheelCast              = addon.WheelCast

local mod                    = WheelCast:NewModule('Scrap')
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

local function getStackPrice(bag, slot)
	local info = C_Container.GetContainerItemInfo(bag, slot)
	if not info or not info.stackCount then return end
	local sellPrice = select(11, C_Item.GetItemInfo(info.itemID))
	return info.stackCount * sellPrice
end

function mod:Test()
	if C_Container.CalculateTotalNumberOfFreeBagSlots() > 0 then
		return
	end

	local bestBag, bestSlot, bestItemID, bestPrice
	for bag, slot, itemID in Scrap:IterateJunk() do
		local stackPrice = getStackPrice(bag, slot)
		if stackPrice and (not bestPrice or stackPrice < bestPrice) then
			bestBag, bestSlot, bestItemID, bestPrice = bag, slot, itemID, stackPrice
		end
	end

	if not bestBag then
		return
	end

	local label = WheelCast.IconLine(C_Item.GetItemIconByID(bestItemID), "Destroy " .. C_Item.GetItemNameByID(bestItemID))
	local macrotext = string.format("/run %s(%d, %d, %d)", globalDestroyFuncName, bestBag, bestSlot, bestItemID)
	return label, macrotext
end
