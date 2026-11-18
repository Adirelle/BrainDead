--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon               = ...

local WheelCast              = addon.WheelCast

local FIND_TREASURE_SPELL_ID = 2481 -- https://www.wowhead.com/forever/spell=2481

local mod                    = WheelCast:NewModule('Tracking')
mod.priority                 = 50

function mod:OnInitialize()
	self:RegisterDatabase()
	self.trackings = {}
	self:Debug("Initialized")
end

function mod:OnEnable()
	self:RegisterEvent('MINIMAP_UPDATE_TRACKING', "Update")

	self:Update("OnEnable")

	self:Debug("Enabled")
end

local function trackingSpellIter(count, index)
	index = index + 1
	if index > count then
		return
	end
	local tracking = C_Minimap.GetTrackingInfo(index)
	if not tracking.spellID or tracking.spellID == FIND_TREASURE_SPELL_ID then
		return trackingSpellIter(count, index)
	end
	return index, tracking
end

local function iterateTrackingSpells()
	return trackingSpellIter, C_Minimap.GetNumTrackingTypes(), 0
end

function mod:Update(event)
	self:Debug("Update", event)

	for _, tracking in iterateTrackingSpells() do
		if tracking.active then
			self.state.id, self.state.line = nil, nil
			return
		elseif tracking.spellID == self.db.profile.tracking then
			self.state.id, self.state.line = tracking.spellID, WheelCast.IconLine(tracking.texture, tracking.name)
		end
	end
end

function mod:SetupButton(button)
	return button:SetManyAttributes("type", "spell", "spell", self.state.id)
end

function mod:GetOptions()
	local choices = {}
	return {
		name = "Default tracking",
		type = "select",
		width = "double",
		get = function() return self.db.profile.tracking end,
		set = function(_, key, value)
			self.db.profile.tracking = key
			self:Debug("aspect selected", key, value)
			if self:IsEnabled() then
				self:Update("OnConfigchange")
			end
		end,
		values = function()
			wipe(choices)
			for _, tracking in iterateTrackingSpells() do
				choices[tracking.spellID] = WheelCast.IconLine(tracking.texture, tracking.name)
			end
			return choices
		end,
	}
end
