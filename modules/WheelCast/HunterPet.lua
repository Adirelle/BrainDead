--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon  = ...

local WheelCast = addon.WheelCast

if WheelCast.playerClass ~= "HUNTER" then
	return
end

local mod         = WheelCast:NewModule('HunterPet')
mod.priority      = 50

local CallSpell   = WheelCast.GetSpell(883) -- https://www.wowhead.com/forever/spell=883
local ReviveSpell = WheelCast.GetSpell(982) -- https://www.wowhead.com/forever/spell=982

function mod:OnEnable()
	self:RegisterEvent('COMPANION_UPDATE', "Update")
	self:RegisterEvent('UNIT_PET', "Update")
	self:RegisterEvent('UNIT_AURA', "Update")
	self:RegisterEvent('PLAYER_UPDATE_RESTING', "Update")
	self:RegisterEvent('PET_ATTACK_STOP', "Update")
	self:Update()
	self:Debug("Enabled")
end

function mod:Update(_, unit)
	if unit and unit ~= "pet" and unit ~= "player" then
		return
	end

	local spell
	if UnitIsUnit('pet', 'vehicle') then
		-- NOP
	elseif not UnitExists("pet") then
		spell = CallSpell
	elseif UnitIsDeadOrGhost("pet") then
		spell = ReviveSpell
	end

	if spell then
		self.state.line, self.state.id = spell:IconLine(), spell:GetSpellID()
	else
		self.state.line, self.state.id = nil, nil
	end
end

function mod:SetupButton(button)
	self:Debug("setup", self.state.id, self.state.line)
	return button:SetManyAttributes("type", "spell", "spell", self.state.id)
end
