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

local mod        = WheelCast:NewModule('HunterAspect')
mod.priority     = 50
mod.unit         = "player"
mod.aspects      = {}
mod.SetupAction  = mod.SetSpell

-- from https://www.wowhead.com/forever/spells/abilities/hunter/name:aspect#0+2+4+22
local aspects    = {
	beast = { 13616, 1299445, 1299446, 1299447 },
	cheetah = { 5118 },
	falcon = { 469145 },
	hawk = { 13165, 14318, 14319, 14320, 14321, 14322, 25296 },
	monkey = { 13163 },
	pack = { 13159 },
	viper = { 415423 },
	wild = { 20043, 20190 },
}

local allAspects = {}
for _, spells in pairs(aspects) do
	for i, spellID in pairs(spells) do
		spells[i] = WheelCast.GetSpell(spellID)
		tinsert(allAspects, spellID)
	end
end

function mod:OnInitialize()
	self:RegisterDatabase({
		profile = {
			aspect = "hawk",
		}
	})
	self:Debug("Initialized")
end

function mod:OnEnable()
	self:RegisterEvent('SPELLS_CHANGED', "ScanSpellBook")
	self:RegisterEvent('UNIT_AURA', "OnUnitEvent")
	self:ScanSpellBook("OnEnable")
	self:Debug("Enabled")
end

function mod:ScanSpellBook(event)
	for aspect, spells in pairs(aspects) do
		self.aspects[aspect] = WheelCast.HighestKnownRank(spells)
	end
	return self:Update(event)
end

function mod:Test()
	if not next(self.aspects) then return end

	local anyAspect = WheelCast.FindAnyAuraOf("player", allAspects, "HELPFUL|PLAYER")
	if anyAspect then return end

	local wants = self.aspects[self.db.profile.aspect]
	if wants then
		return wants:IconLine(), wants:GetSpellID()
	end
end

function mod:GetOptions()
	local choices = {}

	return {
		name = "Default hunter aspect",
		type = "select",
		get = function() return self.db.profile.aspect end,
		set = function(_, value)
			self.db.profile.aspect = value
			self:Update("OnConfigChanged")
		end,
		values = function()
			wipe(choices)
			for key, spell in pairs(self.aspects) do
				choices[key] = spell:IconLine()
			end
			return choices
		end,
	}
end
