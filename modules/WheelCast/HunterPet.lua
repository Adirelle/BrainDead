--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon  = ...

local WheelCast = addon.WheelCast

if WheelCast.playerClass ~= "HUNTER" then
	return
end

local mod            = WheelCast:NewModule('HunterPet')
mod.priority         = 50
mod.unit             = "player"
mod.SetupAction      = mod.SetSpell

local CallSpell      = WheelCast.GetSpell(883) -- https://www.wowhead.com/forever/spell=883
local ReviveSpell    = WheelCast.GetSpell(982) -- https://www.wowhead.com/forever/spell=982

local PET_ERROR_CODE = 306

function mod:OnEnable()
	self:RegisterEvent('UNIT_SPELLCAST_START', "OnUnitEvent")
	self:RegisterEvent('UNIT_SPELLCAST_STOP', "OnUnitEvent")
	self:RegisterEvent('UNIT_PET', "OnUnitEvent")
	self:RegisterEvent('PET_ATTACK_STOP', "UpdateState")
	self:RegisterEvent('UI_ERROR_MESSAGE')

	self.state = nil
	self:UpdateState()

	self:Debug("Enabled")
end

function mod:OnUnitEvent(event, unit)
	self:Debug(event, unit)
	if unit == "player" then
		self:UpdateState()
	end
end

function mod:GuessState()
	if not UnitExists("pet") then
		self:Debug("pet does not exist")
		if self.state ~= "missing" then
			return "missing"
		end
		return self.state or "missing"
	end
	if UnitIsUnit('pet', 'vehicle') then
		self:Debug("pet is a vehcile")
		return "vechile"
	end
	if UnitIsDeadOrGhost("pet") then
		self:Debug("pet is dead")
		return "dead"
	end
	self:Debug("pet is alive")
	return "alive"
end

function mod:UpdateState()
	self:SetState(self:GuessState())
end

function mod:SetState(state)
	if state ~= self.state then
		self:Debug("OnStateChanged", self.state, "=>", state)
		self.state = state
		self:Update("OnStateChanged")
	end
end

function mod:UI_ERROR_MESSAGE(_, errorType, msg)
	self:Debug("UI_ERROR_MESSAGE", errorType, msg)
	if errorType ~= PET_ERROR_CODE then
		return
	end

	if msg == ERR_PET_SPELL_DEAD then
		return self:SetState("dead")
	end

	if msg == ERR_NO_PET then
		return self:SetState("nopet")
	end

	self:SetState("nopet")
end

function mod:Test()
	if UnitIsUnit('pet', 'vehicle') or select(9, UnitCastingInfo("player")) == ReviveSpell:GetSpellID() then
		return
	end

	-- NOP
	if self.state == "missing" then
		return CallSpell:IconLine(), CallSpell:GetSpellID()
	elseif self.state == "dead" then
		return ReviveSpell:IconLine(), ReviveSpell:GetSpellID()
	end
end
