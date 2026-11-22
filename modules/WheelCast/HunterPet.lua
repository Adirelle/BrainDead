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
mod.unit          = "player"
mod.SetupAction   = mod.SetSpell

local CallSpell   = WheelCast.GetSpell(883) -- https://www.wowhead.com/forever/spell=883
local ReviveSpell = WheelCast.GetSpell(982) -- https://www.wowhead.com/forever/spell=982

function mod:OnEnable()
	self:RegisterEvent('COMPANION_UPDATE', "Update")
	self:RegisterEvent('UNIT_PET', "OnUnitEvent")
	self:RegisterEvent('UNIT_SPELLCAST_START', "OnUnitEvent")
	self:RegisterEvent('UNIT_SPELLCAST_STOP', "OnUnitEvent")
	self:RegisterEvent('PET_ATTACK_STOP', "Update")
	self:Debug("Enabled")
end

function mod:Test()
	if UnitIsUnit('pet', 'vehicle') or select(9, UnitCastingInfo("player")) == ReviveSpell:GetSpellID() then
		return
	end

	-- NOP
	if not UnitExists("pet") then
		return CallSpell:IconLine(), CallSpell:GetSpellID()
	elseif UnitIsDeadOrGhost("pet") then
		return ReviveSpell:IconLine(), ReviveSpell:GetSpellID()
	end
end
