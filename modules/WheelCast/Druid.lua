--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon  = ...

local WheelCast = addon.WheelCast

if WheelCast.playerClass ~= "DRUID" then
	return
end

WheelCast:NewSelfBuffModule('DruidMark', 60, 1126, 5232, 6756, 5234, 8907, 9884, 9885)
WheelCast:NewSelfBuffModule('DruidThorns', 60, 467, 782, 1075, 8914, 9756, 9910)
