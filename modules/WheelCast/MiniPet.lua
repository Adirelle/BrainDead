--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon  = ...

local WheelCast = addon.WheelCast

local mod       = WheelCast:NewModule('MiniPet')
mod.priority    = 10

local ICON_LINE = WheelCast.IconLine("Interface\\Icons\\INV_Box_PetCarrier_01", 'Minipet')

function mod:OnEnable(event)
	self:RegisterEvent('COMPANION_UPDATE', "Update")
	self:Update()
	self:Debug("Enabled")
end

function mod:Update()
	local hasMiniPet = C_PetJournal.GetSummonedPetGUID()
	if hasMiniPet then
		self.state.line = nil
	else
		self.state.line = ICON_LINE
	end
	self:Debug("Update", hasMiniPet)
end

function mod:SetupButton(button, ...)
	return button:SetManyAttributes("type", "macro", "macrotext",
		C_PetJournal.HasFavoritePets() and "/randomfavoritepet" or "/randompet")
end
