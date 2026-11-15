--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon  = ...

local WheelCast = addon.WheelCast

if WheelCast.playerRaceId ~= 3 then
	return -- not a dwarf
end

local mod         = WheelCast:NewModule('TrackTreasure')
mod.priority      = 30

local SPELL_ID    = 2481 -- https://www.wowhead.com/forever/spell=2481
local AURA_FILTER = "HELPFUL|PLAYER"

local SPELL_NAME, ICON_LINE
do
	local spell = Spell:CreateFromSpellID(SPELL_ID)
	spell:ContinueOnSpellLoad(function()
		SPELL_NAME = spell:GetSpellName()
		ICON_LINE = WheelCast.IconLine(spell:GetSpellTexture(), SPELL_NAME)
	end)
end

function mod:OnEnable(event)
	self:RegisterEvent('UNIT_AURA', "Update")
	self:Update("OnEnable")
	self:Debug("Enabled")
end

local function findAuraPredicate(expected, ...)
	local auraId = select(12, ...)
	return auraId == expected
end

function mod:Update(event, unit)
	if event ~= "OnEnable" and unit ~= "player" then return end
	local found = not not AuraUtil.FindAura(findAuraPredicate, "player", AURA_FILTER, SPELL_ID)
	if found then
		self.state.line = nil
	else
		self.state.line = ICON_LINE
	end
	self:Debug("Updated", found)
end

function mod:SetupButton(button, ...)
	return button:SetManyAttributes("type", "spell", "spell", SPELL_NAME)
end
