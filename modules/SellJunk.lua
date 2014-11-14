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
			onlyDestroyJunk = true,
			items = {},
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
	self:RegisterBucketEvent('UI_ERROR_MESSAGE', 1)
	self:RegisterBucketEvent('BAG_UPDATE', 1)
	self:Debug('Enabled')
end

function mod:MERCHANT_SHOW()
	if self.db.profile.atMerchants then
		return self:Sell()
	end
end

function mod:UI_ERROR_MESSAGE(messages)
	if self.db.profile.onInventoryFull and messages[ERR_INV_FULL] and not InCombatLockdown() then
		return self:DestroyOne()
	end
end

function mod:BAG_UPDATE()
	if self.db.profile.keepOneFree and not InCombatLockdown() then
		for bag = 0, NUM_BAG_SLOTS do
			local freeSlots, bagType = GetContainerNumFreeSlots(bag)
			if freeSlots > 0 and bagType == 0 then
				self:Debug(freeSlots, 'free slots in bag', bag)
				return
			end
		end
		return self:DestroyOne()
	end
end

function mod:Process(callback, action, done, noItem, onlyJunk)
	if GetCursorInfo() then 
		return self:Feedback('Cannot '..action..' items while another action is pending.')
	end
	self:Debug('Looking for junk to '..action)
	local func = type(callback) == "function" and callback or self[callback] or callback
	local moreItems = self.db.profile.items
	local count, money, slots = 0, 0, 0
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local texture, stackSize, locked, quality,  _, _, link  = GetContainerItemInfo(bag, slot)
			if texture and link and quality and not locked then
				local itemId = tonumber(link:match('item:(%d+)'))
				local linkColor = link:match('(|cff[a-z0-9][a-z0-9][a-z0-9][a-z0-9][a-z0-9][a-z0-9])')
				if (quality == LE_ITEM_QUALITY_POOR or linkColor == ITEM_QUALITY_COLORS[LE_ITEM_QUALITY_POOR].hex or (moreItems[itemId] and not onlyJunk)) and link:match('item:%d+:0:0:0:0') then
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
	if done then
		if count > 0 then
			self:Feedback(("%s %d items (%d stacks), value: %s"):format(done, count, slots, GetCoinTextureString(money)))
		end
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
	return self:Process('DestroyItem', 'destroy', 'Destroyed', true, self.db.profile.onlyDestroyJunk)
end

function mod:DestroyOne()
	local bestPrice, bestBag, bestSlot, bestCount, bestLink
	self:Process(function(_, bag, slot, link, count, price)
		if not bestPrice or price < bestPrice then
			self:Debug('New best item to destroy:', price, bag, slot, count, link)
			bestPrice, bestBag, bestSlot, bestCount, bestLink = price, bag, slot, count, link
		end
	end, "destroy lowest price", nil, false, self.db.profile.onlyDestroyJunk)
	if bestPrice and self:DestroyItem(bestBag, bestSlot, bestLink) then
		self:Feedback(("Destroyed cheapest stack, %d x %s, value: %s"):format(bestCount, bestLink, GetCoinTextureString(bestPrice)))
	end
end

function mod:GetOptions()

	local function GetItemId(input)
		if not input or input:trim() == "" then return end
		local id = tonumber(input) or tonumber(input:match('item:(%d+)'))
		if id then return id end
		local _, link = GetItemInfo(input:trim())
		return link and tonumber(link:match('item:(%d+)'))
	end

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
			moreItems = {
				name = 'Additional items to sell or to destroy',
				type = 'group',
				inline = true,
				order = 100,
				args = {
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
					onlyDestroyJunk = {
						name = "Do not destroy items",
						desc = "Check this to prevent destroying items of the list. These items will only be sold.",
						type = 'toggle',
						order = 130,
						get = function() return self.db.profile.onlyDestroyJunk end,
						set = function(_, value) self.db.profile.onlyDestroyJunk = value end,
						disabled = function() return not next(self.db.profile.items) end,
					},
				},
			},
		}
	}
end

