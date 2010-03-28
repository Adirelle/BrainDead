--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
]]

local addonName, addon = ...

LibStub('AceAddon-3.0'):NewAddon(addon, addonName, 'AceEvent-3.0', 'AceHook-3.0')

-- Debugging code
if tekDebug then
	local frame = tekDebug:GetFrame(addonName)
	function addon:Debug(...)
		frame:AddMessage('|cffff7700['..self.name..']|r '..string.join(", ",tostringall(...)):gsub("([%[%(=]), ", "%1"):gsub(', ([%]%)])','%1'):gsub(':, ', ': '))
	end
else
	function addon.Debug() end
end

local DB_DEFAULTS = {
	profile = {
		modules = { ['*'] = true },
		feedback = true,
		afkwarning = true,
	}
}

function addon:OnInitialize()
	self.db = LibStub('AceDB-3.0'):New('BrainDeadDB', DB_DEFAULTS, true)

	-- Main options
	LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, function() return self:GetOptions() end)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName)

	-- Slash command
	_G['SLASH_BRAINDEAD1'] = '/braindead'
	SlashCmdList.BRAINDEAD = function() InterfaceOptionsFrame_OpenToCategory(addonName) end
end

function addon:OnEnable()

	for name, module in self:IterateModules() do
		module:SetEnabledState(self.db.profile.modules[name])
	end
end

function addon:GetOptions()
	if not self.options then
		local tmp = {}

		self.options = {
			name = addonName,
			type = 'group',
			args = {
				modules = {
					name = 'Modules',
					type = 'multiselect',
					get = function(info, name) return self.db.profile.modules[name] end,
					set = function(info, name, enabled)
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
					desc = 'Warn people that summons/invites/ressurect you that you are AFK when '..addonName..' confirms the action for you.',
					type = 'toggle',
					get = function() return self.db.profile.afkwarning end,
					set = function(_, value) self.db.profile.afkwarning = value end,
					order = 20,
				},
				feedback = {
					name = 'Feedback',
					desc = 'Display message in chat window when '..addonName..' automatically does something.',
					type = 'toggle',
					get = function() return self.db.profile.feedback end,
					set = function(_, value) self.db.profile.feedback = value end,
					order = 30,
				},
			},
		}
	end
	return self.options
end

function addon.Feedback(self, ...)
	if not self.db.profile.feedback then return end
	print('|cffffcc00['..(self.uiName or self.name)..']|r:', ...)
end

function addon.AFKWarning(self, target, ...)
	if UnitIsAFK('player') and target and self.db.profile.afkwarning then
		SendChatMessage("<"..(self.uiName or self.name).."> "..strjoin(" ", tostringall(...)), "WHISPER", nil, target)
	end
end

addon:SetDefaultModuleLibraries('AceEvent-3.0')
addon:SetDefaultModulePrototype({
	OnEnable = function(self) self:Debug('Enabled') end,
	OnDisable = function(self) self:Debug('Disabled') end,
	Debug = addon.Debug,
	Feedback = addon.Feedback,
	AFKWarning = addon.AFKWarning
})
