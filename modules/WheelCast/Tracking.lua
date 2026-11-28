--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon  = ...

local WheelCast = addon.WheelCast

local mod       = WheelCast:NewModule('Tracking')
mod.priority    = 50
mod.SetupAction = mod.SetSpell

function mod:OnInitialize()
	self:RegisterDatabase()
	self:Debug("Initialized")
end

function mod:OnEnable()
	self:RegisterEvent('MINIMAP_UPDATE_TRACKING', "Update")
	self:Debug("Enabled")
end

local FIND_TREASURE_SPELL_ID = 2481 -- https://www.wowhead.com/forever/spell=2481

local function trackingSpellIter(count, index)
	index = index + 1
	if index > count then
		return
	end
	local tracking = C_Minimap.GetTrackingInfo(index)
	if not tracking.spellID or tracking.spellID == FIND_TREASURE_SPELL_ID then
		return trackingSpellIter(count, index)
	end
	return index, tracking, tracking.spellID
end

local function iterateTrackingSpells()
	return trackingSpellIter, C_Minimap.GetNumTrackingTypes(), 0
end

function mod:Test()
	for _, tracking, spellID in iterateTrackingSpells() do
		if tracking.active then
			return
		elseif spellID == self.db.profile.tracking then
			return WheelCast.IconLine(tracking.texture, tracking.name), spellID
		end
	end
end

function mod:GetOptions()
	local choices = {}
	return {
		name = "Default tracking",
		type = "select",
		width = "double",
		get = function() return self.db.profile.tracking end,
		set = function(_, value)
			self.db.profile.tracking = value
			self:Update("OnConfigChanged")
		end,
		values = function()
			wipe(choices)
			for _, tracking in iterateTrackingSpells() do
				choices[tracking.spellID] = WheelCast.IconLine(tracking.texture, tracking.name)
			end
			return choices
		end,
		hidden = function()
			if self:IsEnabled() then
				for _ in iterateTrackingSpells() do
					return false
				end
			end
			return true
		end
	}
end
