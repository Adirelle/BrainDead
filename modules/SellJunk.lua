--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
]]

local _, addon = ...

local mod = addon:NewModule('SellJunk', 'AceConsole-3.0')

function mod:OnInitialize()
	self:RegisterChatCommand('destroyjunk', 'Destroy', true)
	self:RegisterChatCommand('dj', 'Destroy', true)
	self:Debug('Initialized')
end

function mod:OnEnable()
	self:RegisterEvent('MERCHANT_SHOW', 'Sell')
	self:Debug('Enabled')
end

function mod:Process(callback, action, report, noItems)
	if GetCursorInfo() then 
		return self:Feedback('Cannot '..action..' items while another action is pending.')
	end
	self:Debug('Looking for junk to', action)
	local func = self[callback]
	local count, money = 0, 0
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local texture, _, locked, quality,  _, _, link  = GetContainerItemInfo(bag, slot)
			if texture and link and quality and not locked then
				local linkColor = link:match('(|cff[a-z0-9][a-z0-9][a-z0-9][a-z0-9][a-z0-9][a-z0-9])')
				if (quality == ITEM_QUALITY_POOR or linkColor == ITEM_QUALITY_COLORS[ITEM_QUALITY_POOR].hex) and link:match('item:%d+:0:0:0:0') then
					if GetCursorInfo() then
						self:Feedback('Some weird error has happened; aborting to prevent further failures.')
						break
					end
					self:Debug('bag,slot:', bag, slot, 'link:', link, 'quality:', quality, 'linkColor:', linkColor..'XXXX|r')
					if callback(self, bag, slot) then
						money = money + (tonumber(select(11, GetItemInfo(link))) or 0)
						count = count + 1
					end
				end
			end
		end
	end
	if count > 0 then
		self:Feedback(report:format(count, GetCoinTextureString(money)))
	elseif noItems then
		self:Feedback(noItems)
	end
end

function mod:SellItem(bag, slot, link)
	UseContainerItem(bag, slot)
	if GetCursorInfo() then
		self:Debug('Could not sell item', bag, slot, link, 'GetCursorInfo:', GetCursorInfo())
		PickupContainerItem(bag, slot)
		return
	end
	return true
end

function mod:DestroyItem(bag, slot, link)
	PickupContainerItem(bag, slot)
	if not CursorHasItem() or select(3, GetCursorInfo()) ~= link then
		self:Debug('Could not pickup item', bag, slot, link, 'GetCursorInfo:', GetCursorInfo())
		return
	end
	DeleteCursorItem()
	if GetCursorInfo() then
		self:Debug('Could not destroy item', bag, slot, link, 'GetCursorInfo:', GetCursorInfo())
		PickupContainerItem(bag, slot)
		return
	end
	return true
end

function mod:Sell()
	return self:Process('SellItem', 'sell', 'Sold %d items for %s.')
end

function mod:Destroy()
	return self:Process('DestroyItem', 'destroy', 'Destroyed %d items, loss: %s.', 'No junk to destroy.')
end
