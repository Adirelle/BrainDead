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
	self:RegisterMessage("WheelCast_Unit_Changed", "ScanUnit")
	self:RegisterBucketEvent({ "UNIT_AURA" }, 0.1, "ScanUnits")

	self:Debug("Enabled")
end

function mod:Update(event)
	wipe(self.expectedAuras)
	local mark = findMark(mod.expectedAuras)
	local gift = mark and findGift(mod.expectedAuras)
	if mark ~= self.mark or gift ~= self.gift then
		self.findBuff = WheelCast.NewAuraFinder("HELPFUL", self.expectedAuras, 60)
		self.mark, self.gift = mark, gift
	end

	for _, unit in WheelCast:IterateUnits() do
		self:ScanUnit(event, unit)
	end
end

local key = mod.name

function mod:ScanUnits(unitIDs)
	if InCombatLockdown() then return end
	for unitID in pairs(unitIDs) do
		local unit = WheelCast.units[unitID]
		if unit then
			self:ScanUnit(_, unit)
		end
	end
end

function mod:ScanUnit(_, unit, ...)
	local missing = unit.active and not self.findBuff(unit.id) or false
	if missing ~= unit[key] then
		unit[key] = missing
		WheelCast:Update(self.moduleName)
	end
end

function mod:SetupTooltip(tooltip)
	for _, unit in WheelCast:IterateUnits() do
		if unit[key] then
			tooltip:AddLine(WheelCast.IconLine(self.mark:GetSpellTexture(), unit.name))
		end
	end
end

function mod:SetupAction(button)
	self:Debug("SetupAction")
	local count, last = 0, nil
	for _, unit in WheelCast:IterateUnits() do
		if unit.active and unit[key] and button:SetSpell(self.mark:GetSpellID(), unit.id) then
			last, count = unit, count + 1
		end
	end
	if count > 3 and self.gift then
		button:SetSpell(self.gift:GetSpellID(), last.id)
	end
	return count > 0
end
