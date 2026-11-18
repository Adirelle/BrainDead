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
	self:Debug("Initialized", self.db)
end

function mod:OnEnable()
	self:RegisterEvent('SPELLS_CHANGED', "ScanSpellBook")
	self:RegisterEvent('UNIT_AURA', "CheckPresence")

	self:ScanSpellBook("OnEnable")

	self:Debug("Enabled")
end

local function findHighestKnown(spells)
	for i = #spells, 1, -1 do
		if C_SpellBook.IsSpellKnown(spells[i]:GetSpellID()) then
			return spells[i]
		end
	end
end

mod.aspects = {}

function mod:ScanSpellBook(event)
	for aspect, spells in pairs(aspects) do
		self.aspects[aspect] = findHighestKnown(spells)
	end
	self:Debug("ScanSpellbook", event, self.aspects)
	self:CheckPresence("OnEnable")
end

function mod:CheckPresence(event, unit)
	if event ~= "OnEnable" and unit ~= "player" or not next(self.aspects) then return end
	local anyAspect = WheelCast.FindAnyAuraOf("player", allAspects, "HELPFUL|PLAYER")
	if anyAspect then
		self.state.line, self.state.id = nil, nil
	else
		local wants = self.aspects[self.db.profile.aspect]
		if wants then
			self.state.line, self.state.id = wants:IconLine(), wants:GetSpellID()
		end
	end
	self:Debug("CheckPresence", event, anyAspect)
end

function mod:SetupButton(button)
	self:Debug("setup", self.state.id, self.state.line)
	return button:SetManyAttributes("type", "spell", "spell", self.state.id)
end

function mod:GetOptions()
	local choices = {}

	return {
		name = "Hunter aspect",
		type = "select",
		get = function() return self.db.profile.aspect end,
		set = function(_, key, value)
			self.db.profile.aspect = key
			self:Debug("aspect selected", key, value)
			if self:IsEnabled() then
				self:CheckPresence("OnConfigchange", "player")
			end
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
