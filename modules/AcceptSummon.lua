--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
]]

local _, addon = ...

local mod = addon:NewModule('AcceptSummon', 'AceTimer-3.0', 'AceHook-3.0')

function mod:OnEnable()
	self:Debug('Enabled')
	self:RegisterEvent('CONFIRM_SUMMON')
	self:SecureHook('StaticPopup_OnHide')
	self.summoner = nil
	self.timer = nil
end

function mod:CONFIRM_SUMMON(event)
	self.summoner = GetSummonConfirmSummoner()
	self:Debug('CONFIRM_SUMMON', event, self.summoner)
	self:RegisterEvent('PLAYER_REGEN_ENABLED', 'UpdateTimer')
	self:RegisterEvent('PLAYER_REGEN_DISABLED', 'UpdateTimer')
	self:UpdateTimer(event)
end

function mod:UpdateTimer(event)
	if UnitAffectingCombat("player") or not PlayerCanTeleport() then
		self:Debug('UpdateTimer', event, ': cannot teleport now')
		return self:StopTimer()
	elseif self.timer then
		self:Debug('UpdateTimer', event, ': already scheduled')
		return
	end
	local timeLeft = GetSummonConfirmTimeLeft() - 10
	if timeLeft > 0 then
		self:Feedback('Automatically confirming summon in', math.ceil(timeLeft), 'seconds')
		self.timer = self:ScheduleTimer('Accept', timeLeft)
	else
		self:Accept()
	end
end

function mod:Accept()
	self:Feedback('Automatically confirm summon')
	self:AFKWarning(self.summoner, "Automatically accepted invitation.")
	ConfirmSummon()
	StaticPopup_Hide('CONFIRM_SUMMON')
end

function mod:StopTimer()
	if self.timer then
		self:CancelTimer(self.timer)
		self:Feedback('Cancelling automatic summon confirmation')
		self.timer = nil
	end
end

function mod:StaticPopup_OnHide(dialog)
	if dialog.which == "CONFIRM_SUMMON" then
		self:Debug('StaticPopup_OnHide')
		self:UnregisterEvent('PLAYER_REGEN_ENABLED')
		self:UnregisterEvent('PLAYER_REGEN_DISABLED')		
		self.summoner = nil
		self:StopTimer()
	end
end

