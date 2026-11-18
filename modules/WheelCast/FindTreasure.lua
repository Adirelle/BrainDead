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

local mod               = WheelCast:NewModule('TrackTreasure')
mod.priority            = 30

local SPELL_ID          = 2481 -- https://www.wowhead.com/forever/spell=2481
local FindTreasureSpell = WheelCast.GetSpell(SPELL_ID)

function mod:OnEnable()
	self:RegisterEvent('UNIT_AURA', "Update")
	self:Update("OnEnable")
	self:Debug("Enabled")
end

function mod:Update(event, unit)
	if event ~= "OnEnable" and unit ~= "player" then return end
	self.state.line = not WheelCast.FindAura("player", SPELL_ID, "HELPFUL|PLAYER") and FindTreasureSpell:IconLine()
	self:Debug("Updated")
end

function mod:SetupButton(button)
	return button:SetManyAttributes("type", "spell", "spell", SPELL_ID)
end
