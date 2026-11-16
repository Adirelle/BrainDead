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

local mod             = WheelCast:NewModule('HunterPet')
mod.priority          = 50

local CALL_SPELL_ID   = 883 -- https://www.wowhead.com/forever/spell=883
local REVIVE_SPELL_ID = 982 -- https://www.wowhead.com/forever/spell=982
--
-- local CallSpell = Spell:CreateFromSpellID(883)
-- CallSpell:ContinueOnSpellLoad(function()
-- 	CallSpell.line = WheelCast.IconLine(CallSpell:GetSpellTexture(), CallSpell:GetSpellName())
-- end)
--
-- local RezSpell = Spell:CreateFromSpellID(982) -- https://www.wowhead.com/forever/spell=883
-- RezSpell:ContinueOnSpellLoad(function()
-- 	RezSpell.line = WheelCast.IconLine(RezSpell:GetSpellTexture(), RezSpell:GetSpellName())
-- end)

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

	local id
	if UnitIsUnit('pet', 'vehicle') then
		id = false
	elseif not UnitExists("pet") then
		id = CALL_SPELL_ID
	elseif UnitIsDeadOrGhost("pet") then
		id = REVIVE_SPELL_ID
	end

	if id then
		local spell = C_Spell.GetSpellInfo(id)
		if spell then
			self.state.line, self.state.id = WheelCast.IconLine(spell.iconID, spell.name), id
			return
		end
	end

	self.state.line, self.state.id = nil, nil
end

function mod:SetupButton(button)
	self:Debug("setup", self.state.id, self.state.line)
	return button:SetManyAttributes("type", "spell", "spell", self.state.id)
end
