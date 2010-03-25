--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
]]

local _, addon = ...

local mod = addon:NewModule('SellJunk')

function mod:OnEnable()
	self:Debug('Enabled')
	self:RegisterEvent('MERCHANT_SHOW', 'Sell')
end

function mod:Sell()
	if GetCursorInfo() then return end
	self:Debug('Sell')
	local count, money = 0, 0
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local texture, _, locked, quality,  _, _, link  = GetContainerItemInfo(bag, slot)
			if texture and link and quality and not locked then
				local linkColor = link:match('(|cff[a-z0-9][a-z0-9][a-z0-9][a-z0-9][a-z0-9][a-z0-9])')
				if (quality == ITEM_QUALITY_POOR or linkColor == ITEM_QUALITY_COLORS[ITEM_QUALITY_POOR].hex) and link:match('item:%d+:0:0:0:0') then
					self:Debug('bag,slot:', bag, slot, 'link:', link, 'quality:', quality, 'linkColor:', linkColor..'XXXX|r')
					UseContainerItem(bag, slot)
					if GetCursorInfo() then
						self:Debug('Could not sell', link)
						-- Something didn't worked, put it back
						PickupContainerItem(bag, slot)
					else
						money = money + (tonumber(select(11, GetItemInfo(link))) or 0)
						count = count + 1
					end
				end
			end
		end
	end
	if count > 0 then
		self:Feedback('Sold', count, 'items for', GetCoinTextureString(money))
	end
end
