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
	local cost, canRepair = GetRepairAllCost()
	if type(cost) ~= "number" or not canRepair then
		self:Debug("Cannot or no need to repair", cost, canRepair)
		return
	end
	if CanGuildBankRepair() then
		local amount, total = GetGuildBankWithdrawMoney(), GetGuildBankMoney()
		if amount == -1 then
			amount = total
		else
			amount = min(amount, total)
		end
		if amount >= cost then
			self:Feedback('Repairing all items using guild money for', GetCoinTextureString(cost))
			RepairAllItems(true)
			return
		end
	end
	if CanMerchantRepair() then
		if 2 * cost <= GetMoney() then
			self:Feedback('Repairing all items for', GetCoinTextureString(cost))
			RepairAllItems()
		else
			self:Feedback('Not enough money to repair; cost:', GetCoinTextureString(cost))
		end
	else
		self:Debug("This merchant cannot repair")
	end
end
