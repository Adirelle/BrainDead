--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
]]

local _, addon = ...

local mod = addon:NewModule('AcceptResurrection')

function mod:OnEnable()
	self:Debug('Enabled')
	self:RegisterEvent('RESURRECT_REQUEST')
end

function mod:RESURRECT_REQUEST(event, requestor)
	if UnitAffectingCombat(requestor) then
		return self:Feedback('Ignoring resurrection from player in combat.')
	elseif ResurrectHasSickness() then
		return self:Feedback('Ignoring resurrection that would cause sickness.')
	elseif ResurrectHasTimer() then
		return
	end
	self:Feedback('Accepting resurrection from', requestor)
	self.requestor = requestor
	self:RegisterEvent('PLAYER_ALIVE')
	self:RegisterEvent('PLAYER_UNGHOST', 'PLAYER_ALIVE')
	AcceptResurrect()
end

function mod:PLAYER_ALIVE()
	self:UnregisterEvent('PLAYER_ALIVE')
	self:UnregisterEvent('PLAYER_UNGHOST', 'PLAYER_ALIVE')
	StaticPopup_Hide("RESURRECT")
	StaticPopup_Hide("RESURRECT_NO_SICKNESS")
	StaticPopup_Hide("RESURRECT_NO_TIMER")
	if self.requestor then
		self:AFKWarning(self.requestor, "Automatically accepted resurrection.")
		self.requestor = nil
	end
end
