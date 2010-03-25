--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
]]

local _, addon = ...

local mod = addon:NewModule('Plates')

function mod:OnEnable()
	self:Debug('Enabled')
	self:RegisterEvent('PLAYER_REGEN_ENABLED', 'Update')
	self:RegisterEvent('PLAYER_REGEN_DISABLED', 'Update')
	self:RegisterEvent('PLAYER_LOGOUT', 'Disable')
	self:Update('OnEnable')
end

function mod:OnDisable()
	self:Debug('Disabled')
	self:Update('OnDisable')
end

function mod:Update(event)
	local enable = ((event ~= 'OnDisable') and (InCombatLockdown() or event == 'PLAYER_REGEN_DISABLED'))
	self:Debug('Update', event, 'newState=', enable, 'currentState=', self.enabled)
	if enable == self.enabled then return end
	self.enabled = enable
	local cvar = GetCVarBool('nameplateShowEnemies')
	self:Debug('Updating', event, 'cvar=', cvar, 'enable=', enable, 'wasEnabled=', self.wasEnabled)
	if enable then
		self.wasEnabled = cvar 
	else
		enable = self.wasEnabled 
	end
	if (enable and not cvar) or (not enable and cvar) then
		self:Debug('Setting nameplateShowEnemies to:', enable)
		SetCVar('nameplateShowEnemies', enable and 1 or 0)
	end
end
