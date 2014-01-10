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

local function DoIKnowYou(name)
	for i = 1, GetNumFriends() do
		if requestor == GetFriendInfo(i) then
			return 'friend'
		end
	end
	if IsInGuild() then
		local shortname, realm = strsplit('-', name, 2)
		local fqdn = shortname..'-'..(realm or GetRealmName())
		for i = 1, GetNumGuildMembers() do
			if fqdn == GetGuildRosterInfo(i) then
				return 'guildmate'
			end
		end
	end
end

function mod:PARTY_INVITE_REQUEST(event, requestor)
	local accept = DoIKnowYou(requestor)
	self:Debug('Invitation from', requestor, '=>', accept)
	if accept then
		self:Debug('Accepting invitation from', accept, requestor)
		if not self:AssertNotDND('Not accepting invitation while DND') then
			self:Debug('DND denial')
			return
		end
		local lfgMode = GetLFGMode(LE_LFG_CATEGORY_LFD)
			or GetLFGMode(LE_LFG_CATEGORY_RF)
			or GetLFGMode(LE_LFG_CATEGORY_SCENARIO)
			or GetLFGMode(LE_LFG_CATEGORY_LFR)
		self:Debug('lfgMode', lfgMode)
		if lfgMode and lfgMode ~= "abandonedInDungeon" then
			self:Feedback("Not accepting while invitation while in LFG queue")
			return
		end
		self:Feedback('Accepting invitation from', accept, requestor)
		self.requestor = requestor
		self:RegisterEvent('GROUP_ROSTER_UPDATE')
		AcceptGroup()
	else
		self:Debug('Invitation not automatically accepted')
	end
end

function mod:GROUP_ROSTER_UPDATE()
	self:UnregisterEvent('GROUP_ROSTER_UPDATE')
	StaticPopup_Hide('PARTY_INVITE')
	if self.requestor then
		self:AFKWarning(self.requestor, "Automatically accepted invitation.")
		self.requestor = nil
	end
end
