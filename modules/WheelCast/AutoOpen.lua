local _, addon  = ...

local WheelCast = addon.WheelCast

local mod       = WheelCast:NewModule('AutoOpen')
mod.priority    = 20

function mod:OnEnable()
	self:RegisterEvent("BAG_UPDATE_DELAYED", "Update")
	self:Debug("Enabled")
end

local FIRST_BAG, LAST_BAG = 0, 4

local function iterateBagItems()
	local bag, slot = FIRST_BAG, 0
	local count = C_Container.GetContainerNumSlots(bag)

	local nextSlot

	local function nextBag()
		slot = 0
		while bag < LAST_BAG do
			bag = bag + 1
			local count = C_Container.GetContainerNumSlots(bag)
			if count > 0 then
				return nextSlot()
			end
		end
	end

	function nextSlot()
		slot = slot + 1
		if slot > count then
			return nextBag()
		end
		local info = C_Container.GetContainerItemInfo(bag, slot)
		if not info then
			return nextSlot()
		end
		return bag, slot, info
	end

	return nextSlot
end

local ITEMS = {
	[5523] = 1,
}


function mod:Test()
	local freeSpace = C_Container.CalculateTotalNumberOfFreeBagSlots()
	self:Debug("Test", freeSpace)
	if freeSpace == 0 then
		return
	end

	for _, _, info in iterateBagItems() do
		if ITEMS[info.itemID] and freeSpace >= ITEMS[info.itemID] then
			return WheelCast.IconLine(info.iconFileID, "Open " .. info.itemName), info.itemName
		end
	end
end

function mod:SetupAction(button)
	if not self._action then return end

	button:SetManyAttributes("type", "item", "item", self._action)
	return true
end
