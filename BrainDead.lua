--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local addonName, addon = ...

LibStub('AceAddon-3.0'):NewAddon(addon, addonName, 'AceEvent-3.0', 'AceHook-3.0')

-- Debugging code
if AdiDebug then
	AdiDebug:Embed(addon, addonName)
else
	function addon.Debug(...) end
end

local DB_DEFAULTS = {
	profile = {
		modules = { ['*'] = true },
		feedback = true,
		afkwarning = true,
	}
}

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local SendChatMessage = C_ChatInfo.SendChatMessage

local function AddOptionPanel(self, label, parent)
	if not self.GetOptions then return end
	local options
	AceConfig:RegisterOptionsTable(self.name, function()
		if not options then options = self:GetOptions() end
		return options
	end)
	return AceConfigDialog:AddToBlizOptions(self.name, label, parent)
end

-- To be replaced by an useful function in OnInitialize
function OpenBrainDeadConfig() end

function addon:OnInitialize()
	self.db = LibStub('AceDB-3.0'):New('BraindDeadDB', DB_DEFAULTS, true)

	-- Main options
	local _, optionId = AddOptionPanel(self, addonName)
	OpenBrainDeadConfig = function()
		Settings.OpenToCategory(optionId)
	end

	-- Module options
	for name, module in self:IterateModules() do
		AddOptionPanel(module, module.uiName or name, addonName)
	end

	_G['SLASH_BRAINDEAD1'] = '/braindead'
	_G.SlashCmdList.BRAINDEAD = OpenBrainDeadConfig
end

function addon:OnEnable()
	for name, module in self:IterateModules() do
		module:SetEnabledState(self.db.profile.modules[name])
	end
end

function addon:GetOptions()
	local tmp = {}

	return {
		name = addonName,
		type = 'group',
		args = {
			modules = {
				name = 'Modules',
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
				order = 10,
			},
			afkwarning = {
				name = 'AFK warning',
				desc = 'Warn people that summons/invites/ressurect you that you are AFK when ' ..
					addonName .. ' confirms the action for you.',
				type = 'toggle',
				get = function() return self.db.profile.afkwarning end,
				set = function(_, value) self.db.profile.afkwarning = value end,
				order = 20,
			},
			feedback = {
				name = 'Feedback',
				desc = 'Display message in chat window when ' .. addonName .. ' automatically does something.',
				type = 'toggle',
				get = function() return self.db.profile.feedback end,
				set = function(_, value) self.db.profile.feedback = value end,
				order = 30,
			},
		},
	}
end

function addon.Feedback(self, ...)
	if not addon.db.profile.feedback then return end
	print('|cffffcc00[' .. (self.uiName or self.name) .. ']|r:', ...)
end

function addon.AFKWarning(self, target, ...)
	if UnitIsAFK('player') and target and addon.db.profile.afkwarning then
		SendChatMessage("<" .. (self.uiName or self.name) .. "> " .. strjoin(" ", tostringall(...)), "WHISPER", nil,
			target)
	end
end

function addon.AssertNotDND(self, ...)
	if UnitIsDND('player') then
		self:Feedback(...)
		return false
	end
	return true
end

function UnCamelCase(input)
	return input:gsub("%l%u", function(match, ...)
		addon:Debug("UnCamelCase", input, match, ...)
		return match:sub(1, 1) .. " " .. match:sub(2):lower()
	end)
end

function addon:OnModuleCreated(module)
	if not module.uiName then
		module.uiName = UnCamelCase(module.moduleName)
	end
	self:Debug("New module", module)
end

addon:SetDefaultModuleLibraries('AceEvent-3.0')
addon:SetDefaultModulePrototype({
	OnInitialize = function(self) self:Debug('Initialized') end,
	OnEnable = function(self) self:Debug('Enabled') end,
	OnDisable = function(self) self:Debug('Disabled') end,
	OnModuleCreated = addon.OnModuleCreated,
	Debug = addon.Debug,
	Feedback = addon.Feedback,
	AFKWarning = addon.AFKWarning,
	AssertNotDND = addon.AssertNotDND,
	RegisterDatabase = function(self, ...)
		self.db = addon.db:RegisterNamespace(self.moduleName, ...)
		return self.db
	end,
})
