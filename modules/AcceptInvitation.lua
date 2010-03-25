--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
]]

local _, addon = ...

local mod = addon:NewModule('AcceptInvitation')

function mod:OnEnable()
	self:Debug('Enabled')
	self:RegisterEvent('PARTY_INVITE_REQUEST')
end

function mod:PARTY_INVITE_REQUEST(event, requestor)
	local accept = UnitIsInMyGuild(requestor) and 'guildmate'
	if not accept then
		for i = 1, GetNumFriends() do
			if requestor == GetFriendInfo(i) then
				accept = 'friend'
				break
			end
		end
	end
	if accept then
		self:Feedback('Accepting invitation from', accept, requestor)
		AcceptGroup()
		self.requestor = requestor
		self:RegisterEvent('PARTY_MEMBERS_CHANGED')
	end
end

function mod:PARTY_MEMBERS_CHANGED()
	self:UnregisterEvent('PARTY_MEMBERS_CHANGED')
	StaticPopup_Hide('PARTY_INVITE')
	self:AFKWarning(self.requestor, "Automatically accepted invitation.")
end