--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
]]

local _, addon = ...

local mod = addon:NewModule('Plates')

function mod:OnInitialize()
	self.modOptions = {}
end

function mod:OnModuleCreated(mod)
	self:Debug("OnModuleCreated", mod.name, mod)
end

function mod:GetOptions()
	return {
		name = 'Plates',
		type = 'group',
		order = 100,
		args = self.modOptions,
	}
end

mod:SetDefaultModuleLibraries('AceEvent-3.0')
mod:SetDefaultModuleState(true)
mod:SetDefaultModulePrototype({
	show = false,
	wasShown = false,

	Debug = mod.Debug,
	Feedback = mod.Feedback,
	AFKWarning = mod.AFKWarning,
	AssertNotDND = mod.AssertNotDND,

	RegisterDatabase = function(self, ...)
		self.db = mod.db:RegisterNamespace(self.moduleName, ...)
		return self.db
	end,

	OnEnable = function(self)
		self:Debug('Enabled')
		self:RegisterEvent('PLAYER_REGEN_ENABLED', 'Update')
		self:RegisterEvent('PLAYER_REGEN_DISABLED', 'Update')
		self:RegisterEvent('PLAYER_LOGOUT', 'Disable')
		self:Update('OnEnable')
	end,

	OnDisable = function(self)
		self:Debug('Disabled')
		self:Update('OnDisable')
	end,

	Update = function(self, event)
		local show = event ~= 'OnDisable' and (event == 'PLAYER_REGEN_DISABLED' or not not InCombatLockdown())
		if show == self.show then return end
		self.show = show
		local current = not not GetCVarBool(self.cvarName)
		self:Debug('Updating', self.cvarName, event, 'current=', current, 'show=', show, 'wasShown=', self.wasShown)
		if show then
			self.wasShown = current
		else
			show = self.wasShown
		end
		if show ~= current then
			self:Debug('Setting', self.cvarName, 'to:', show)
			SetCVar(self.cvarName, show and 1 or 0)
		end
	end
})

for _, cvarName in ipairs({ "nameplateShowEnemies", "nameplateShowFriendlyPlayers", "nameplateShowFriendlyNpcs" }) do
	mod:NewModule(cvarName).cvarName = cvarName
end
