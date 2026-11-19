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
mod.unit                = "player"
mod.SetupAction         = mod.SetSpell

local SPELL_ID          = 2481 -- https://www.wowhead.com/forever/spell=2481
local FindTreasureSpell = WheelCast.GetSpell(SPELL_ID)

function mod:OnEnable()
	self:RegisterEvent("UNIT_AURA", "OnUnitEvent")
	self:Debug("Enabled")
end

function mod:UNIT_AURA(_, unit)
	if unit == "PLAYER" then
		self:MarkDirty()
	end
end

function mod:Test()
	if not WheelCast.FindAura("player", SPELL_ID, "HELPFUL|PLAYER") then
		return FindTreasureSpell:IconLine(), SPELL_ID
	end
end
