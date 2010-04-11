--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
]]

local _, addon = ...

local mod = addon:NewModule('SellJunk', 'AceConsole-3.0', 'AceBucket-3.0')

function mod:OnInitialize()
	self:RegisterDatabase({
		profile = {
			atMerchants = true,
			onInventoryFull = false,
			keepOneFree = false,
			items = { ['*'] = false },
		},
	})
	self:RegisterChatCommand('destroyjunk', 'Destroy', true)
	self:RegisterChatCommand('dj', 'Destroy', true)
	self:RegisterChatCommand('destroyonejunk', 'DestroyOne', true)
	self:RegisterChatCommand('doj', 'DestroyOne', true)
	self:Debug('Initialized')
end

function mod:OnEnable()
	self:RegisterEvent('MERCHANT_SHOW')
	self:RegisterEvent('UI_ERROR_MESSAGE')
	self:RegisterBucketEvent('BAG_UPDATE', 1)
	self:Debug('Enabled')
end

function mod:MERCHANT_SHOW()
	if self.db.profile.atMerchants then
		return self:Sell()
	end
end

function mod:UI_ERROR_MESSAGE(event, message)
	if self.db.profile.onInventoryFull and message == ERR_INV_FULL then
		self:Feedback('Should destroy item now.')
	end
end

function mod:BAG_UPDATE()
	if not self.db.profile.keepOneFree or not IsLoggedIn() or InCombatLockdown() then return end
	for bag = 0, NUM_BAG_SLOTS do
		local freeSlots, bagType = GetContainerNumFreeSlots(bag)
		if freeSlots > 0 and bagType == 0 then
			return
		end
	end
	self:Feedback(ERR_INV_FULL)
end

function mod:Process(callback, action, done, noItem)
	if GetCursorInfo() then 
		return self:Feedback('Cannot '..action..' items while another action is pending.')
	end
	self:Debug('Looking for junk to '..action)
	local func = type(callback) == "string" and self[callback] or callback
	local moreItems = self.db.profile.items
	local count, money, slots = 0, 0, 0
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local texture, stackSize, locked, quality,  _, _, link  = GetContainerItemInfo(bag, slot)
			if texture and link and quality and not locked then
				local itemId = tonumber(link:match('item:(%d+)'))
				local linkColor = link:match('(|cff[a-z0-9][a-z0-9][a-z0-9][a-z0-9][a-z0-9][a-z0-9])')
				if (quality == ITEM_QUALITY_POOR or linkColor == ITEM_QUALITY_COLORS[ITEM_QUALITY_POOR].hex or moreItems[itemId]) and link:match('item:%d+:0:0:0:0') then
					if GetCursorInfo() then
						self:Feedback('Some weird error has happened; aborting to prevent further failures.')
						break
					end
					self:Debug('bag,slot:', bag, slot, 'link:', link, 'quality:', quality, 'linkColor:', linkColor..'XXXX|r')
					local price = stackSize * (tonumber(select(11, GetItemInfo(link))) or 0) 
					if func(self, bag, slot, link, stackSize, price) then
						money = money + price
						count = count + stackSize
						slots = slots + 1
					end
				end
			end
		end
	end
	if count > 0 and done then
		self:Feedback(("%s %d items (%d stacks), value: %s"):format(done, count, slots, GetCoinTextureString(money)))
	elseif noItem then
		self:Feedback(noItem)
	end
	return count
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
	return self:Process('SellItem', 'sell', 'Sold')
end

function mod:Destroy()
	return self:Process('DestroyItem', 'destroy', 'Destroyed', true)
end

function mod:DestroyOne()
	local bestPrice, bestBag, bestSlot, bestLink
	self:Process(function(bag, slot, link, _, price)
		if not bestPrice or price < bestPrice then
			bestPrice, bestBag, bestSlot, bestLink = price, bag, slot, lnik
		end
	end, "destroy lowest price")
	if bestPrice and self:DestroyItem(bestBag, bestSlot, bestLink) then
		self:Feedback(("Destroyed cheapest stack, value: %s"):format(GetCoinTextureString(bestPrice)))
	end
end


local function GetItemId(input)
	if not input or input:trim() == "" then return end
	local id = tonumber(input) or tonumber(input:match('item:(%d+)'))
	if id then return id end
	local _, link = GetItemInfo(input:trim())
	return link and tonumber(link:match('item:(%d+)'))
end

function mod:GetOptions()
	local items = {}
	local lastRemovedItem

	return {
		name = 'SellJunk',
		type = 'group',
		order = 100,
		args = {
			atMerchants = {	
				name = 'Sell at merchant',
				desc = 'Automatically sell junk when talking to a merchant.',
				type = 'toggle',
				order = 10,
				get = function() return self.db.profile.atMerchants end,
				set = function(_, value) self.db.profile.atMerchants = value end,
			},
			onInventoryFull = {
				name = 'On full inventory',
				desc = 'Automatically destroy the stack with lowest price when receiving the "inventory full" error.',
				type = 'toggle',
				order = 20,
				get = function() return self.db.profile.onInventoryFull end,
				set = function(_, value) self.db.profile.onInventoryFull = value end,
			},
			keepOneFree = {
				name = 'Keep one free slot',
				desc = 'Automatically destroy the stack with lowest price when there is no free slot in regular bags.',
				type = 'toggle',
				order = 30,
				get = function() return self.db.profile.keepOneFree end,
				set = function(_, value) self.db.profile.keepOneFree = value end,
			},
			_itemHeader = {
				name = 'Additional items',
				type = 'header',
				order = 100,
			},
			addItem = {
				name = 'Add item',
				desc = "Enter the name, link of id of an item to add it to the list of non-junk items to sell.",
				type = 'input',
				order = 110,
				validate = function(_, value)
					return GetItemId(value) and true or 'Invalid item'
				end,
				get = function() return lastRemovedItem end,
				set = function(_, value)
					lastRemovedItem  = nil
					self.db.profile.items[GetItemId(value)] = true
				end
			},
			removeItem = {
				name = 'Remove item',
				desc = 'Select an item to remove it from the list of non-junk items to sell.',
				type = 'select',
				order = 120,
				confirm = true,
				confirmText = 'Do you really want to remove this item from the list ?',
				values = function()
					wipe(items)
					for id in pairs(self.db.profile.items) do
						items[id] = GetItemInfo(id)
					end
					return items
				end,
				get = function() end,
				set = function(_, value)
					lastRemovedItem = GetItemInfo(value)
					self.db.profile.items[value] = nil
				end,
			},
		}
	}
end

