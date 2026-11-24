--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon   = ...

local ae         = LibStub("AceEvent-3.0")

local mod        = addon:NewModule('WheelCast', "AceBucket-3.0")
addon.WheelCast  = mod

mod.uiName       = "Cast thing with mouse wheel"

mod.playerRace   = select(2, UnitRace("player"))
mod.playerClass  = select(2, UnitClass("player"))

mod.moduleOrder  = {}
mod.actions      = {}
mod.labels       = {}
mod.units        = {}

mod.units.player = { guid = UnitGUID("player"), active = true }
for i = 1, MAX_RAID_MEMBERS do
	mod.units[string.format("raid%d", i)] = { active = false }
end

function mod:OnInitialize()
	self:RegisterDatabase({
		profile = {
			modules = { ["*"] = true },
			anchor = { point = "CENTER", x = 0, y = 0, locked = false },
		}
	})

	for name in self:IterateModules() do
		tinsert(self.moduleOrder, name)
	end
	table.sort(self.moduleOrder, function(a, b)
		return (self:GetModule(a).priority or 0) > (self:GetModule(b).priority or 0)
	end)

	self:Debug("Initialized", self.moduleOrder)
end

function mod:OnEnable()
	if InCombatLockdown()
		or not IsPlayerInWorld()
		or not HasFullControl()
		or UnitHasVehicleUI("player")
		or UnitOnTaxi("player")
		or UnitIsDeadOrGhost("player")
		or C_PetBattles.IsInBattle()
	then
		return self:Disable()
	end

	ae.UnregisterAllEvents(self.name)

	self:RegisterEvent("PLAYER_REGEN_DISABLED", "Disable")
	self:RegisterEvent("PLAYER_LEAVING_WORLD", "Disable")
	self:RegisterEvent("UNIT_ENTERED_VEHICLE")
	self:RegisterEvent("PET_BATTLE_OPENING_START", "Disable")
	self:RegisterEvent("PLAYER_CONTROL_LOST", "Disable")
	self:RegisterEvent("PLAYER_DEAD", "Disable")

	self:RegisterEvent("GROUP_ROSTER_UPDATE", "RefreshRoster")
	self:RegisterBucketEvent({ "UNIT_CONNECTION", "UNIT_DIED", "UNIT_IN_RANGE_UPDATE" }, 0.1, "RefreshUnitBatch")

	local anchorDb = mod.db.profile.anchor
	self.anchor:SetPoint(anchorDb.point, anchorDb.x, anchorDb.y)
	self.anchor:SetShown(not anchorDb.locked)

	wipe(self.labels)
	wipe(self.actions)
	self.hold = true

	for name, mod in self:IterateModules() do
		if self.db.profile.modules[name] then
			mod:Enable()
			mod:Update("OnEnable")
		end
	end

	self:RefreshRoster("OnEnable")

	self.hold = false
	self:Update("OnEnable")

	self:Debug("Enabled")
end

function mod:OnDisable()
	if self:IsModuleActive() then
		ae.RegisterEvent(self.name, "PLAYER_REGEN_ENABLED", self.Enable, self)
		ae.RegisterEvent(self.name, "PLAYER_ENTERING_WORLD", self.Enable, self)
		ae.RegisterEvent(self.name, "UNIT_EXITED_VEHICLE", self.Enable, self)
		ae.RegisterEvent(self.name, "PET_BATTLE_OVER", self.Enable, self)
		ae.RegisterEvent(self.name, "PLAYER_CONTROL_GAINED", self.Enable, self)
		ae.RegisterEvent(self.name, "PLAYER_ALIVE", self.Enable, self)
		ae.RegisterEvent(self.name, "PLAYER_UNGHOST", self.Enable, self)
	end

	self.tooltip:Hide()
	self.anchor:Hide()

	self:Debug("Disabled")
end

function mod:UNIT_ENTERED_VEHICLE(_, unit)
	if UnitIsUnit(unit, "player") then
		self:Disable()
	end
end

local function activeModuleIter(names, index)
	index = index + 1
	local name = names[index]
	if not name then return end
	if not mod.db.profile.modules[name] then
		return activeModuleIter(names, index)
	end
	return index, name
end

function mod:IterateActiveModules()
	return activeModuleIter, self.moduleOrder, 0
end

function mod:Update(event)
	if self.hold or not self.dirty then return end

	self:Debug("Updating", event, self.labels, self.actions)

	local tooltip, button = self.tooltip, self.button

	tooltip:ClearLines()
	tooltip:Reanchor()
	tooltip:AddLine("Chores")

	button:Clear()

	local hasAction
	for _, name in self:IterateActiveModules() do
		if self.labels[name] then
			tooltip:AddLine(self.labels[name])
		end
		hasAction = hasAction or self.actions[name] ~= nil
	end

	tooltip:SetShown(tooltip:NumLines() > 1)
	button:SetShown(hasAction)

	self.dirty = false
	self:Debug("Updated", event, "#labels:", tooltip:NumLines(), "action:", hasAction)
end

function mod:SetupAction(button)
	for _, name in self:IterateActiveModules() do
		if self.actions[name] and self:GetModule(name):SetupAction(button, self.actions[name]) then
			return
		end
	end
end

function mod:Set(name, label, action)
	if self.labels[name] == label and self.actions[name] == action then
		return false
	end
	self.labels[name], self.actions[name], self.dirty = label, action, true
	self:Update("Set_" .. name)
	return true
end

function mod:RefreshRoster(event)
	for i = 1, MAX_RAID_MEMBERS do
		local unitID = string.format("raid%d", i)
		local unit = self.units[unitID]
		local guid, oldGUID = UnitGUID(unitID), unit.guid
		unit.guid = guid
		if not guid and oldGUID then
			unit.active = false
			self:SendMessage("WheelCast_Unit_Updated", unitID, false)
		elseif guid ~= oldGUID then
			self:RefreshUnitState(event, unitID)
		end
	end
	self:Debug("roster refreshed", event)
end

function mod:RefreshUnitBatch(unitIDs)
	if InCombatLockdown() then return end
	for unitID in pairs(unitIDs) do
		self:RefreshUnit("Batch", unitID)
	end
end

function mod:RefreshUnit(event, unitID)
	local unit = self.units[unitID]
	if not unit then return end
	local dead = UnitIsDeadOrGhost(unitID)
	local connected = UnitIsConnected(unitID)
	local inRange = UnitInRange(unitID)
	local active = not dead and connected and inRange
	if active ~= unit.active then
		unit.active = active
		self:SendMessage("WheelCast_Unit_Updated", unitID, active)
	end
	self:Debug("Unit state refreshed", event, unitID)
end

function mod:IsActiveUnit(unitID)
	local unit = self.units[unitID]
	return unit and unit[unitID].active or false
end

function iterActiveUnit(units, key)
	local unit
	key, unit = next(units, key)
	if not key then
		return
	end
	if not unit.guid or not unit.active then
		return iterActiveUnit(units, key)
	end
	return key, unit.guid
end

function mod:IterateActiveUnits()
	return iterActiveUnit, self.units
end

------------------------------------------------------------------------------------------------------------------------

function mod.IconLine(icon, text)
	if icon then
		return "|T" .. icon .. ":0:0:0:0:64:64:4:60:4:60|t " .. text
	end
	return text
end

local function Spell_IconLine(self)
	return mod.IconLine(self:GetSpellTexture(), self:GetSpellName())
end

function mod.GetSpell(spellID)
	local spell = Spell:CreateFromSpellID(spellID)
	spell.IconLine = Spell_IconLine
	return spell
end

function mod.HighestKnownRank(spells)
	for rank = #spells, 1, -1 do
		if C_SpellBook.IsSpellKnown(spells[rank]:GetSpellID()) then
			mod:Debug("HighestKnownRank", spells[rank]:GetSpellName(), rank, spells[rank]:GetSpellID())
			return spells[rank]
		end
	end
end

function mod.CreateAuraPredicate(spellID, minRemainingTime)
	local predicate
	if type(spellID) == "table" then
		predicate = function(...) return tContains(spellID, select(13, ...)) end
	else
		predicate = function(...) return spellID == select(13, ...) end
	end
	if minRemainingTime and minRemainingTime > 0 then
		local prev = predicate
		predicate = function(...)
			if not prev(...) then
				return false
			end
			local expirationTime = select(9, ...)
			return expirationTime and expirationTime > 0 and (expirationTime - GetTime() >= minRemainingTime) or false
		end
	end
	return predicate
end

function mod.FindAura(unitID, filter, predicate)
	assert(not InCombatLockdown(), "FindAura called in combat")
	return AuraUtil.FindAura(predicate, unitID, filter)
end

------------------------------------------------------------------------------------------------------------------------

function mod:GetOptions()
	local modList = {}
	local options = {}

	for name, mod in self:IterateModules() do
		local label = mod.uiName or addon.UnCamelCase(name)
		modList[name] = label

		local modOptions = mod.GetOptions and mod:GetOptions()
		if modOptions then
			if not modOptions.name then
				modOptions.name = label
			end
			modOptions.order = 100
			if modOptions.type == "group" then
				modOptions.inline = true
			end
			modOptions.hidden = function()
				return not self.db.profile.modules[name]
			end
			options[name] = modOptions
		end
	end

	options.modules = {
		name = 'Modules',
		type = 'multiselect',
		order = 1,
		get = function(_, name) return self.db.profile.modules[name] end,
		set = function(_, name, enabled)
			self.db.profile.modules[name] = enabled
			if self:IsEnabled() then
				local mod = self:GetModule(name)
				if enabled then
					mod:Enable()
					mod:Update("OnConfigChanged")
				else
					mod:Disable()
					self.labels[name], self.actions[name], self.dirty = nil, nil, true
					self:Update("OnConfigChanged")
				end
			end
		end,
		values = modList,
	}

	options.anchor = {
		name = "Show anchor",
		type = "toggle",
		order = -1,
		width = "full",
		get = function() return not self.db.profile.anchor.locked end,
		set = function(_, show)
			self.db.profile.anchor.locked = not show
			self.anchor:SetShown(not self:IsEnabled() and show)
		end,
	}

	return options
end

------------------------------------------------------------------------------------------------------------------------

mod:SetDefaultModuleState(false)
mod:SetDefaultModuleLibraries('AceEvent-3.0')
mod:SetDefaultModulePrototype(setmetatable(
	{
		Test = function(self) error(self.name .. ":Test() is not implemented") end,
		SetupAction = function(self) error(self.name .. ":SetupAction() is not implemented") end,

		Update = function(self)
			local label, action = self:Test()
			return mod:Set(self.moduleName, label or nil, action or nil)
		end,

		SetSpell = function(self, button, spellID, unitID)
			return button:SetSpell(spellID, unitID or self.unit)
		end,

		SetMacrotext = function(_, button, macrotext)
			return button:SetMacroText(macrotext)
		end,

		OnUnitEvent = function(self, event, unit)
			if unit == self.unit then
				self:Update(event)
			end
		end
	},
	{ __index = addon.defaultModulePrototype }
))

------------------------------------------------------------------------------------------------------------------------

do
	local proto = {}

	function proto:ScanSpellBook()
		wipe(self.accepted)
		self.highestRank = nil
		for rank = #self.spells, 1, -1 do
			local spellID = self.spellIDs[rank]
			tinsert(self.accepted, spellID)
			if C_SpellBook.IsSpellKnown(spellID) then
				self.highestRank = rank
				break
			end
		end
		self.predicate = (#self.accepted > 0 and self.highestRank and mod.CreateAuraPredicate(self.accepted, self.minRemainingTime) or nil)
	end

	function proto:Test(unitID)
		if not self.predicate or mod.FindAura(unitID, self.filter, self.predicate) then
			return
		end
		local spell = self.spells[self.highestRank]
		return spell:IconLine(), spell:GetSpellID()
	end

	function mod:NewSpellHandler(filter, minRemainingTime, ...)
		local handler = setmetatable({
			spells = {},
			spellIDs = { ... },
			accepted = {},
			filter = filter,
			minRemainingTime = minRemainingTime,
		}, { __index = proto })

		for rank = 1, select('#', ...) do
			local spell = mod.GetSpell(select(rank, ...))
			spell.rank = rank
			handler.spells[rank] = spell
		end

		return handler
	end
end

------------------------------------------------------------------------------------------------------------------------

do
	local super = mod.defaultModulePrototype
	local proto = setmetatable({
		priority    = 50,
		unit        = "player",
		SetupAction = super.SetSpell
	}, { __index = super })

	function proto:OnEnable()
		self:RegisterEvent('UNIT_AURA', "OnUnitEvent")
		self:RegisterEvent('SPELLS_CHANGED')
		self:SPELLS_CHANGED()

		self:Debug("Enabled")
	end

	function proto:SPELLS_CHANGED()
		self.handler:ScanSpellBook()
		self:Update()
	end

	function proto:Test()
		return self.handler:Test(self.unit)
	end

	function mod:NewSelfBuffModule(name, minRemainingTime, ...)
		local subMod   = self:NewModule(name, proto)
		subMod.handler = mod:NewSpellHandler("HELPFUL", minRemainingTime, ...)
		return subMod
	end
end
