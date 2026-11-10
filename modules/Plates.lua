--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon = ...

local modProto = setmetatable({
	previous = 0,

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
}, { __index = addon.defaultModulePrototype })

for uiName, suffix in pairs({
	["enemies"] = "Enemies",
	["friendly players"] = "FriendlyPlayers",
	["friendly NPCs"] = "FriendlyNpcs"
}) do
	local plateMod = addon:NewModule("Plates_" .. suffix, modProto)
	plateMod.uiName = "Show " .. uiName .. " nameplates in combat"
	plateMod.cvarName = "nameplateShow" .. suffix
end
