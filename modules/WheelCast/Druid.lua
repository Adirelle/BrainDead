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

--WheelCast:NewSelfBuffModule('DruidMark', 60,)
WheelCast:NewSelfBuffModule('DruidThorns', 60, 467, 782, 1075, 8914, 9756, 9910)

local findMark    = WheelCast.NewRankScanner(1126, 5232, 6756, 5234, 8907, 9884, 9885)
local findGift    = WheelCast.NewRankScanner(21849, 21850)

local mod         = WheelCast:NewModule("DruidMark", "AceBucket-3.0")
mod.priority      = 50
mod.units         = {}
mod.expectedAuras = {}

function mod:OnEnable()
	self:RegisterEvent('SPELLS_CHANGED', "Update")
	self:RegisterEvent("GROUP_ROSTER_UPDATE", "ScanRaidRoster")
	self:RegisterBucketEvent({ "UNIT_AURA", "UNIT_CONNECTION", "UNIT_HEALTH", "UNIT_IN_RANGE_UPDATE" }, 0.1, "ScanUnits")

	self:Debug("Enabled")
end

function mod:Update(event)
	self:Debug("Update", event)
	wipe(self.expectedAuras)
	local mark = findMark(mod.expectedAuras)
	if mark == self.mark then return end
	self.mark = mark
	if not mark then return end
	self.gift = findGift(mod.expectedAuras)
	self.findBuff = WheelCast.NewAuraFinder("HELPFUL", self.expectedAuras, 60)
	self:ScanRaidRoster(event)
end

local allUnitIDs = { player = true }
for i = 1, MAX_RAID_MEMBERS do
	allUnitIDs[string.format("raid%d", allUnitIDs)] = true
end

local function isActiveUnit(unitID)
	return unitID == "player" or
		allUnitIDs[unitID] and UnitInRaid(unitID) and UnitIsConnected(unitID) and not UnitIsDeadOrGhost(unitID)
end

function mod:ScanRaidRoster(event)
	if not self.mark then return end
	self:Debug("ScanRaidRoster", event)
	self:ScanUnits(allUnitIDs)
end

function mod:ScanUnits(unitIDs)
	if not self.mark then return end
	local changed = false
	for unitID in pairs(unitIDs) do
		local missing = isActiveUnit(unitID) and not self.findBuff(unitID) or nil
		self:Debug("ScanUnit", unitID, result)
		if missing ~= self.units[unitID] then
			self.units[unitID] = missing
			changed = true
		end
	end
	if changed then
		WheelCast:Update(self.moduleName)
	end
end

function mod:SetupTooltip(tooltip)
	for unitID in pairs(self.units) do
		tooltip:AddLine(WheelCast.IconLine(self.mark:GetSpellTexture(), UnitName(unitID)))
	end
end

function mod:SetupAction(button)
	self:Debug("SetupAction")
	for unitID in pairs(self.units) do
		if button:SetSpell(self.mark:GetSpellID(), unitID) then
			return true
		end
	end
	return false
end
