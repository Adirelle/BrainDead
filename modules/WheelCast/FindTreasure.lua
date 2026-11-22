--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon  = ...

local WheelCast = addon.WheelCast

if WheelCast.playerRace ~= "Dwarf" then
	return
end

local mod = WheelCast:NewSelfBuffModule('TrackTreasure', 2481)
mod.priority = 30
