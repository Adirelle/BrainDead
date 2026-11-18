--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon      = ...

local ldb           = LibStub("LibDataBroker-1.1")

local mod           = addon:NewModule('WheelCast', 'AceBucket-3.0')
mod.uiName          = "Cast thing with mouse wheel"
mod.states          = {}
mod.orderedStates   = {}

mod.playerRaceId    = select(3, UnitRace("player"))
mod.playerClass     = select(2, UnitClass("player"))

addon.WheelCast     = mod

local DATAOBJ_TYPE  = mod.addonName

local suspendEvents = { "PLAYER_LEAVING_WORLD", "UNIT_ENTERED_VEHICLE", "PET_BATTLE_OPENING_START",
	"PLAYER_CONTROL_LOST", "PLAYER_DEAD" }
local resumeEvents  = { "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD", "UNIT_EXITED_VEHICLE", "PET_BATTLE_OVER",
	"PLAYER_CONTROL_GAINED", "PLAYER_ALIVE", "PLAYER_UNGHOST" }

function mod:OnInitialize()
	self:RegisterDatabase({
		profile = {
			modules = { ["*"] = true },
			anchor = {
				point = "BOTTOMRIGHT",
				x = 0,
				y = 0,
				locked = false,
			}
		}
	})
	self:Debug("Initialized", self.db)
end

function mod:OnEnable()
	local anchorDb = self.db.profile.anchor
	self.anchor:SetPoint(anchorDb.point, anchorDb.x, anchorDb.y)
	if not anchorDb.locked then
		self.anchor:Show()
	else
		self.anchor:Hide()
	end

	self.suspended = true
	self:TryResume("OnEnable")
	self:Debug("Enabled")
end

function mod:OnDisable()
	self.anchor:Hide()
	self:Suspend("OnDisable")
	self:Debug("Disabled")
end

function mod:TryResume(event, ...)
	if InCombatLockdown() or
		not IsPlayerInWorld() or
		not HasFullControl() or
		UnitHasVehicleUI("player") or
		UnitOnTaxi("player") or
		UnitIsDeadOrGhost("player") or
		C_PetBattles.IsInBattle()
	then
		return self:Suspend(event)
	end

	return self:Resume(event)
end

function mod:Resume(event)
	if not self.suspended then return end
	self.suspended = false

	self:UnregisterAllEvents()
	self:UnregisterAllBuckets()

	for name, mod in self:IterateModules() do
		if self.db.profile.modules[name] then
			mod:Enable()
		end
	end

	self:RegisterEvent("PLAYER_REGEN_DISABLED", "Suspend")
	self:RegisterBucketEvent(suspendEvents, 0.1, "Suspend")

	if not self.db.profile.anchor.locked then
		self.anchor:Show()
	end

	self:MarkDirty()

	self:Debug("Resumed", event)
end

function mod:Suspend(event)
	if self.suspended and event ~= "OnEnable" then return end
	self.suspended = true

	self:UnregisterAllEvents()
	self:UnregisterAllBuckets()

	for _, subMod in self:IterateModules() do
		subMod:Disable()
	end

	self:RegisterBucketEvent(resumeEvents, 0.02, "TryResume")

	self.anchor:Hide()
	self.tooltip:Hide()
	self.button:Hide()

	self:Debug("suspended", event)
end

function mod:MarkDirty()
	if self.dirty then return end
	self.dirty = true
	self:Clean()
end

local doClean = function() mod:DoClean() end

function mod:Clean()
	if self.suspended or not self.dirty then return end
	C_Timer.After(0, doClean)
end

function mod:DoClean()
	if self.suspended or not self.dirty then return end
	self.dirty = false
	self:Debug("DoClean")

	table.sort(self.orderedStates, function(a, b)
		return (a.priority or 0) > (b.priority or 0)
	end)

	local tooltip, button = self.tooltip, self.button

	tooltip:ClearLines()
	tooltip:Reanchor()
	tooltip:AddLine(mod.name)

	local actionnable = false
	button:SetManyAttributes("type", nil, "bag", nil, "slot", nil, "item", nil, "spell", nil, "macrotext", nil)

	for _, state in pairs(self.orderedStates) do
		if state.line then
			tooltip:AddLine(state.line)
			if not actionnable and state.SetupButton then
				state:SetupButton(button)
				actionnable = true
				self:Debug("button set up for", state.line)
			end
		end
	end

	tooltip:SetShown(tooltip:NumLines() > 1)
	button:SetShown(actionnable)
end

------------------------------------------------------------------------------------------------------------------------

local function IconLine(icon, text)
	if icon then
		return "|T" .. icon .. ":0:0:0:0:64:64:4:60:4:60|t " .. text
	end
	return text
end

local function Spell_IconLine(self)
	return IconLine(self:GetSpellTexture(), self:GetSpellName())
end

local function GetSpell(spellID)
	local spell = Spell:CreateFromSpellID(spellID)
	spell.IconLine = Spell_IconLine
	return spell
end


local function FindAuraPredicate(expected, ...)
	local auraID = select(12, ...)
	return auraID == expected
end

local function FindAura(unitID, auraID, filter)
	assert(not InCombatLockdown(), "FindAura called in combat")
	return AuraUtil.FindAura(FindAuraPredicate, unitID, filter, auraID)
end

local function FindAnyAuraOfPredicate(expected, ...)
	local auraId = select(12, ...)
	return tContains(expected, auraId)
end

local function FindAnyAuraOf(unitID, auraIDs, filter)
	assert(not InCombatLockdown(), "FindAnyAuraOf called in combat")
	return AuraUtil.FindAura(FindAnyAuraOfPredicate, unitID, filter, auraIDs)
end


mod.IconLine, mod.GetSpell, mod.FindAura, mod.FindAnyAuraOf = IconLine, GetSpell, FindAura, FindAnyAuraOf

------------------------------------------------------------------------------------------------------------------------

function mod:GetOptions()
	local modList = {}
	local options = {}

	for name, mod in self:IterateModules() do
		local label = mod.uiName or addon.UnCamelCase(name)
		modList[name] = label

		local modOptions = mod.GetOptions and mod:GetOptions()
		if modOptions then
			options[name] = {
				name = label,
				type = "group",
				args = modOptions,
				order = 100,
				hidden = function()
					return not self.db.profile.modules[name]
				end,
			}
		end
	end

	options.modules = {
		name = 'Modules',
		type = 'multiselect',
		get = function(_, name) return self.db.profile.modules[name] end,
		set = function(_, name, enabled)
			self.db.profile.modules[name] = enabled
			local module = self:GetModule(name)
			if self:IsEnabled() then
				if enabled then
					module:Enable()
				else
					module:Disable()
				end
			else
				module:SetEnabledState(enabled)
			end
		end,
		values = modList,
		width = "double",
		order = 10,
	}

	return options
end

------------------------------------------------------------------------------------------------------------------------

mod:SetDefaultModuleState(true)
mod:SetDefaultModuleLibraries('AceEvent-3.0')
mod:SetDefaultModulePrototype(addon.defaultModulePrototype)

function mod:OnModuleCreated(subMod)
	local name = subMod.name
	local state = ldb:NewDataObject(name, {
		type = DATAOBJ_TYPE,
		SetupButton = function(_, ...) subMod:SetupButton(...) end
	})
	subMod.state = state
	mod:Debug("Registered module", name, subMod)
	ldb.RegisterCallback(self, "LibDataBroker_AttributeChanged_" .. name, "MarkDirty")
	self.states[name] = state
	tinsert(self.orderedStates, state)
end
