--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon  = ...

local WheelCast = addon.WheelCast

local mod       = WheelCast:NewModule('MiniPet')
mod.priority    = 10
mod.SetupAction = mod.SetMacrotext

local ICON_LINE = WheelCast.IconLine("Interface\\Icons\\INV_Box_PetCarrier_01", 'Minipet')

function mod:OnEnable()
	self:RegisterEvent('COMPANION_UPDATE', "Update")
	self:Debug("Enabled")
end

function mod:Test()
	if not C_PetJournal.GetSummonedPetGUID() then
		return ICON_LINE, C_PetJournal.HasFavoritePets() and "/randomfavoritepet" or "/randompet"
	end
end
