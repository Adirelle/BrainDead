--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon = ...

local plates = addon:NewModule('Plates')
plates.uiName = "Name plates"

function plates:OnInitialize()
	self:RegisterDatabase({
		profile = {
			modules = { ['*'] = true },
		}
	})
	self:Debug('Initialized', self.db)
end

function plates:OnEnable()
	for name, module in self:IterateModules() do
		module:SetEnabledState(self.db.profile.modules[name])
	end
	self:Debug("Enabled")
end

function plates:GetOptions()
	local tmp = {}
	self:Debug("GetOptions")

	return {
		name = "Name plates",
		type = 'group',
		args = {
			plates = {
				name = 'Show name plates only in combat',
				type = 'multiselect',
				get = function(_, name) return self.db.profile.modules[name] end,
				set = function(_, name, enabled)
					self.db.profile.modules[name] = enabled
					local module = self:GetModule(name)
					if self:IsEnabled() then
						if enabled then
							module:Enable()
						else
							module:Disable()
						end
					else
						module:SetEnabledState(enabled)
					end
				end,
				values = function()
					wipe(tmp)
					for name, module in self:IterateModules() do
						tmp[name] = module.uiName or name
					end
					return tmp
				end,
			}
		}
	}
end

plates:SetDefaultModuleLibraries('AceEvent-3.0')
plates:SetDefaultModuleState(true)
plates:SetDefaultModulePrototype({
	previous = 0,

	Debug = plates.Debug,

	OnInitialize = function(self) self:Debug('Initialized') end,

	OnEnable = function(self)
		self.previous = SetCVar(self.cvarName)

		self:RegisterEvent('PLAYER_REGEN_ENABLED', 'Set', 0)
		self:RegisterEvent('PLAYER_REGEN_DISABLED', 'Set', 1)
		self:RegisterEvent('PLAYER_LOGOUT', 'Disable')

		self:Set("OnEnable", InCombatLockdown() and 1 or 0)
		self:Debug('Enabled')
	end,

	OnDisable = function(self)
		self:Set(self.previous, "OnDisable")
		self:Debug('Disabled')
	end,

	Set = function(self, value, event)
		self:Debug("Set", event, self.cvarName, value)
		SetCVar(self.cvarName, value)
	end,
})


for uiName, suffix in pairs({
	["Enemies"] = "Enemies",
	["Friendly players"] = "FriendlyPlayers",
	["Friendly NPCs"] = "FriendlyNpcs"
}) do
	local subplates = plates:NewModule("Plates_" .. suffix)
	subplates.uiName = uiName
	subplates.cvarName = "nameplateShow" .. suffix
end
