--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
]]

local _, addon = ...

local mod = addon:NewModule('SellJunk', 'AceConsole-3.0', 'AceBucket-3.0')

local GetContainerItemInfo = C_Container.GetContainerItemInfo
local GetContainerNumFreeSlots = C_Container.GetContainerNumFreeSlots
local GetContainerNumSlots = C_Container.GetContainerNumSlots
local GetItemInfo = C_Item.GetItemInfo
local PickupContainerItem = C_Container.PickupContainerItem

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
	if self.db.profile.atMerchants and C_MerchantFrame.IsSellAllJunkEnabled() and C_MerchantFrame.GetNumJunkItems() > 0 then
		C_MerchantFrame.SellAllJunkItems()
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

function mod:DestroyOne()
	local bestPrice, bestBag, bestSlot, bestLink

	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local count, itemPrice, link = self:CanDestroy(bag, slot)
			if count > 0 then
				self:Debug("considering", bag, slot, link, count, itemPrice)
				local price = count * itemPrice
				if not bestPrice or price < bestPrice then
					bestPrice, bestBag, bestSlot, bestLink = price, bag, slot, link
					self:Debug("destroy candidate", bestPrice, bestBag, bestSlot, bestLink)
				end
			end
		end
	end
	if not bestPrice then
		self:Debug("nothing to destroy")
		return
	end
	self:Debug("destroying", bestPrice, bestBag, bestSlot, bestLink)
	self:DestroyItem(bestBag, bestSlot)
end

function mod:CanDestroy(bag, slot)
	local info = GetContainerItemInfo(bag, slot)
	if info then
		if info.stackCount > 0 and info.quality == Enum.ItemQuality.Poor then
			return info.stackCount, select(11, C_Item.GetItemInfo(info.itemID)), info.hyperlink
		end
	end
	return 0, 0, nil
end

function mod:DestroyItem(bag, slot)
	PickupContainerItem(bag, slot)
	if not CursorHasItem() then
		self:Debug('Could not pickup item', bag, slot, 'GetCursorInfo:', GetCursorInfo())
		return
	end
	DeleteCursorItem()
	if GetCursorInfo() then
		self:Debug('Could not destroy item', bag, slot, 'GetCursorInfo:', GetCursorInfo())
		PickupContainerItem(bag, slot)
		return
	end
	return true
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
							lastRemovedItem                         = nil
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
