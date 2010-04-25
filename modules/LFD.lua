--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
]]

local _, addon = ...

local mod = addon:NewModule('LFD', 'AceTimer-3.0')


function mod:OnEnable()
	self:Debug('Enabled')
	self:RegisterEvent('LFG_ROLE_CHECK_SHOW', 'Update')
	self:RegisterEvent('LFG_ROLE_CHECK_HIDE', 'Update')
	self:RegisterEvent('LFG_PROPOSAL_SHOW', 'Update')
	self:RegisterEvent('LFG_PROPOSAL_UPDATE', 'Update')
	self:RegisterEvent('LFG_PROPOSAL_FAILED', 'Update')
	self:RegisterEvent('PLAYER_REGEN_ENABLED', 'Update')
	self:RegisterEvent('PLAYER_REGEN_DISABLED', 'Update')
	self:RegisterEvent('PLAYER_FLAGS_UPDATED', 'Update')
end

function mod:OnDisable()
	self:Debug('Disabled')
end

local currentMode

local function GetMode()
	local mode, subMode = GetLFGMode()
	if not mode then
		return "none"
	elseif InCombatLockdown() or UnitIsDND('player') then
		return "standby"
	elseif subMode then
		return strjoin('-', mode, subMode)
	else
		return mode
	end
end

local function Automate(mode)
	if mode == "rolecheck" then
		local canBeTank, canBeHealer, canBeDPS = GetAvailableRoles()
		local numRoles = (canBeTank and 1 or 0) + (canBeHealer and 1 or 0) + (canBeDPS and 1 or 0)
		return numRoles == 1
	elseif mode == "proposal-unaccepted" then
		local proposalExists, _, _, _, _, _, hasResponded, _, completedEncounters = GetLFGProposal()
		return proposalExists and not hasResponded and completedEncounters == 0 or false		
	end
	return false
end

function mod:TimeUp()
	local mode = GetMode()
	self:Debug('TimeUp, mode:', mode)
	
	if not Automate(mode) then
		self:Debug('No automation')
		return self:SetMode(mode, 'TimeUp')
	end
	
	if mode == 'rolecheck' then
		-- Checking roles

		local canBeTank, canBeHealer, canBeDPS = GetAvailableRoles()
		self:Debug('RoleCheck: tank, healer, dps =', canBeTank, canBeHealer, canBeDPS)		
		SetLFGRoles(GetLFGRoles(), canBeTank, canBeHealer, canBeDPS)
		LFG_UpdateRoleCheckboxes()
		self:Feedback('Automatically selected role:', canBeTank and "tank" or canBeHealer and "healer" or canBeDPS and "dps")
		-- CompleteLFGRoleCheck(true)

	elseif mode == 'proposal-unaccepted' then
		-- Dungeon proposal awaiting for confirmation

		self:Debug('Accepting proposal')
		self:Feedback('Accepting proposal')
		-- AcceptProposal()
	end
end

function mod:SetMode(newMode, event)
	if newMode == currentMode then return end
	self:Debug('SetMode on', event, currentMode, '=>', newMode)
	if self:CancelTimer(self.timer, true) then
		self:Feedback('Cancelled automatic accept')
	end
	currentMode = newMode
	if Automate(currentMode) then
		self:Feedback('Automatically accepting in 5 seconds')
		self.timer = self:ScheduleTimer('TimeUp', 5)
	end
end

function mod:Update(event)
	return self:SetMode(GetMode(), event)
end

