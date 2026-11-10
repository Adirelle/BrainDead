--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon = ...

local mod = addon:NewModule('PVPRelease')
mod.uiName = "Release in battleground and PvP zones"

function mod:OnEnable()
	self:Debug('Enabled')
	self:RegisterEvent('PLAYER_DEAD')
end

function mod:PLAYER_DEAD()
	if HasSoulstone() then return end
	local _, instanceType = IsInInstance()
	local map = GetMapInfo()
	if instanceType == "pvp" or instanceType == "arena" or map == "LakeWintergrasp" or map == "TolBarad" then
		RepopMe()
	end
end
