--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

if _G.Scrap then return end

local _, addon = ...

local mod = addon:NewModule('SellJunk')
mod.uiName = "Sell junk to merchant"

function mod:OnEnable()
	self:Debug('Enabled')
	self:RegisterEvent('MERCHANT_SHOW')
end

function mod:MERCHANT_SHOW()
	self:Debug("on:MERCHANT_SHOW")
	if not C_MerchantFrame.IsSellAllJunkEnabled() then
		return
	end
	local junkCount = C_MerchantFrame.GetNumJunkItems()

	if junkCount > 0 then
		self:Feedback("Selling", junkCount, "junk item(s) at merchant")
		C_MerchantFrame.SellAllJunkItems()
	end
end
