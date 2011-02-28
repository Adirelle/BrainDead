--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
]]

local _, addon = ...

local mod = addon:NewModule('PVPRelease')

function mod:OnEnable()
	self:Debug('Enabled')
	self:RegisterEvent('PLAYER_DEAD')
end

function mod:PLAYER_DEAD()
	local _, instanceType, map = IsInInstance(), GetMapInfo()
	if not HasSoulstone() and instanceType == "pvp" or instanceType == "arena" or map == "LakeWintergrasp" or map == "TolBarad" then
		RepopMe()
	end
end
