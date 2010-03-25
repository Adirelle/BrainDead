--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
]]

local _, addon = ...

-- Static popup autoresponder prototype
do
	local proto = setmetatable({}, {__index = addon.defaultModulePrototype})
	
	function proto:OnEnable()
		self:Debug('Enabled')
		self:SecureHook('StaticPopup_OnShow')
		self:SecureHook('StaticPopup_OnHide')	
	end
	
	function proto:StaticPopup_OnShow(dialog)
		if not self.filter[dialog.which] then
			return
		end
		local shouldAccept, delay = self:ShouldAccept(dialog)
		self:Debug('StaticPopup', dialog.which, 'shown => shouldAccept=', shouldAccept, 'delay=', delay)
		if not shouldAccept then
			return 
		end
		self.dialog = dialog
		if delay == true then
			if type(dialog.timeleft) == "number" then
				delay = math.ceil(dialog.timeLeft * 0.9)
			else
				delay = 10
			end
		end
		if type(delay) == "number" then
			self:Debug('Accepting in', delay, 'seconds')
			self.timer = self:ScheduleTimer('Accept', delay)
		else
			self:Accept()
		end
	end
	
	function proto:Accept()
		if not self.dialog then return end
		self:Debug('Automatically accept', self.dialog.which)
		StaticPopup_OnClick(self.dialog, 1)
	end
	
	function proto:ShouldAccept()
		return true, self.delayed
	end

	function proto:StaticPopup_OnHide(dialog)
		if dialog == self.dialog then
			self:Debug('StaticPopup', dialog.which, 'hidden')
			self.dialog = nil
			if self.timer then
				self:Debug('Cancelling timer')
				self:CancelTimer(self.timer)
				self.timer = nil
			end
		end
	end

	function addon:NewStaticPopupModule(name, ...)
		local mod = self:NewModule(name, proto, 'AceTimer-3.0', 'AceHook-3.0')
		mod.filter = {}
		for i = 1, select('#', ...) do
			mod.filter[select(i, ...)] = true
		end
		return mod
	end
end

local resurrect = addon:NewStaticPopupModule('AcceptResurrect', 'RESURRECT', 'RESURRECT_NO_SICKNESS', 'RESURRECT_NO_TIMER')
function resurrect:ShouldAccept(dialog)
	self:Debug('ShouldAccept', dialog, dialog.text_arg1)
	return not UnitAffectingCombat(dialog.text_arg1)
end

--local invite = addon:NewStaticPopupModule('AcceptInvite', 'PARTY_INVITE')
--function resurrect:ShouldAccept(dialog)
--	self:Debug('ShouldAccept', dialog)
--	return not UnitAffectingCombat(dialog.text_arg1)
--end


