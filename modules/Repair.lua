--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
]]

local _, addon = ...

local mod = addon:NewModule('Repair')

function mod:OnEnable()
	self:Debug('Enabled')
	self:RegisterEvent('MERCHANT_SHOW', 'Repair')
end

function mod:Repair()
	if CanMerchantRepair() then
		local cost, canRepair = GetRepairAllCost()
		if canRepair and type(cost) == "number" then
			if cost / GetMoney() < 0.5 then
				self:Feedback('Repairing all items for', GetCoinTextureString(cost))
				RepairAllItems()
			else
				self:Feedback('Not enough money to repair ; repair cost:', GetCoinTextureString(cost))
			end
		else
			self:Debug("Can't or no need to repair", cost, canRepair)
		end
	else
		self:Debug("Merchant can't repair")
	end
end