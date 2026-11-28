--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon   = ...

local ae         = LibStub("AceEvent-3.0")
local ab         = LibStub("AceBucket-3.0")

local mod        = addon:NewModule('WheelCast', "AceBucket-3.0")
addon.WheelCast  = mod

mod.uiName       = "Cast thing with mouse wheel"

mod.playerRace   = select(2, UnitRace("player"))
mod.playerClass  = select(2, UnitClass("player"))

mod.moduleOrder  = {}
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
		or UnitIsDeadOrGhost("player")
		or C_PetBattles.IsInBattle()
	then
		return self:Disable()
	end

	ae.UnregisterAllEvents(self.name)

	self:RegisterEvent("PLAYER_REGEN_DISABLED", "Disable")
	self:RegisterEvent("UNIT_ENTERED_VEHICLE")
	self:RegisterBucketEvent(
		{ "PET_BATTLE_OPENING_START", "PLAYER_CONTROL_LOST", "PLAYER_DEAD", "PLAYER_LEAVING_WORLD" },
		0, "Disable")

	self:RegisterEvent("GROUP_ROSTER_UPDATE", "ScanRoster")
	self:RegisterEvent("PLAYER_ROLES_ASSIGNED", "ScanRoster")
	self:RegisterBucketEvent({ "UNIT_CONNECTION", "UNIT_HEALTH" }, 0.1, "ScanUnits")

	local anchorDb = mod.db.profile.anchor
	self.anchor:SetPoint(anchorDb.point, anchorDb.x, anchorDb.y)
	self.anchor:SetShown(not anchorDb.locked)

	self.hold = true

	self:ScanRoster("OnEnable")

	for name, mod in self:IterateModules() do
		if self.db.profile.modules[name] then
			mod:Enable()
			mod:Update("OnEnable")
		end
	end

	self.hold = false
	self:Update("OnEnable")

	self:Debug("Enabled")
end

function mod:OnDisable()
	if self:IsModuleActive() then
		ab.RegisterBucketEvent(
			self.name,
			{ "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD", "UNIT_EXITED_VEHICLE", "PET_BATTLE_OVER",
				"PLAYER_CONTROL_GAINED", "PLAYER_ALIVE", "PLAYER_UNGHOST" },
			0.2,
			function() mod:Enable() end
		)
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
	return index, name, mod:GetModule(name)
end

function mod:IterateActiveModules()
	return activeModuleIter, self.moduleOrder, 0
end

function mod:Update(event)
	if self.hold then return end

	local tooltip, button = self.tooltip, self.button

	tooltip:ClearLines()
	tooltip:Reanchor()
	tooltip:AddLine("Chores")

	button:Clear()

	for _, _, subMod in self:IterateActiveModules() do
		subMod:SetupTooltip(tooltip)
	end

	tooltip:SetShown(tooltip:NumLines() > 1)

	self:Debug("Updated", event)
end

function mod:SetupAction(button)
	for _, _, subMod in self:IterateActiveModules() do
		if subMod:SetupAction(button) then
			return
		end
	end
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

------------------------------------------------------------------------------------------------------------------------

local function CreateAuraPredicate(spellID, minRemainingTime)
	local predicate
	if type(spellID) == "table" then
		if #spellID == 0 then return nil end
		predicate = function(...) return tContains(spellID, select(13, ...)) end
	elseif type(spellID) == "number" and spellID > 0 then
		predicate = function(...) return spellID == select(13, ...) end
	elseif spellID == nil then
		return nil
	else
		error(string.format("invalid spell id: %s", spellID))
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

local function noop() end

function mod.NewAuraFinder(filter, spellID, minRemainingTime)
	local predicate = CreateAuraPredicate(spellID, minRemainingTime)
	if not predicate then
		return noop
	end
	return function(unitID)
		assert(not InCombatLockdown(), "AuraFinder called in combat")
		return AuraUtil.FindAura(predicate, unitID, filter)
	end
end

------------------------------------------------------------------------------------------------------------------------

function mod.NewRankScanner(...)
	local spells = {}

	for rank = select('#', ...), 1, -1 do
		local spellID = select(rank, ...)
		local spell = mod.GetSpell(spellID)
		spell.rank = rank
		tinsert(spells, spell)
	end

	return function(equalOrGreater)
		for _, spell in ipairs(spells) do
			local spellID = spell:GetSpellID()
			if equalOrGreater then
				tinsert(equalOrGreater, spellID)
			end
			if C_SpellBook.IsSpellKnown(spellID) then
				return spell
			end
		end
	end
end

------------------------------------------------------------------------------------------------------------------------

mod:SetDefaultModuleState(false)
mod:SetDefaultModuleLibraries('AceEvent-3.0')
mod:SetDefaultModulePrototype(setmetatable(
	{
		OnDisable = function(self)
			self._label, self._action = nil, nil
			self:Debug("disabled")
		end,

		Test = function(self) error(self.name .. ":Test() is not implemented") end,
		SetupAction = function(self) error(self.name .. ":SetupAction() is not implemented") end,

		Update = function(self)
			local label, action = self:Test()
			if label ~= self._label or action ~= self._action then
				self._label, self._action = label, action
				mod:Update(self.moduleName)
			end
		end,

		SetupTooltip = function(self, tooltip)
			if self._label then
				tooltip:AddLine(self._label)
			end
		end,

		SetSpell = function(self, button)
			if self._action then
				self:Debug("SetSpell", button, self._action, self.unit)
				return button:SetSpell(self._action, self.unit)
			end
		end,

		SetMacrotext = function(self, button)
			if self._action then
				return button:SetMacroText(self._action)
			end
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
	local super = mod.defaultModulePrototype
	local proto = setmetatable({
		priority    = 50,
		unit        = "player",
		SetupAction = super.SetSpell
	}, { __index = super })

	function mod:NewSelfBuffModule(name, minTimeRemaining, ...)
		local subMod            = self:NewModule(name, proto)
		subMod.minTimeRemaining = minTimeRemaining
		subMod.spellIDs         = {}
		subMod.findSpell        = mod.NewRankScanner(...)
		return subMod
	end

	function proto:OnEnable()
		self:RegisterEvent('UNIT_AURA', "OnUnitEvent")
		self:RegisterEvent('SPELLS_CHANGED', "ScanSpellBook")
		self:ScanSpellBook()

		self:Debug("Enabled")
	end

	function proto:ScanSpellBook()
		wipe(self.spellIDs)
		local spell = self.findSpell(self.spellIDs)
		if spell == self.spell then return end
		self.spell = spell
		self.findBuff = mod.NewAuraFinder("HELPFUL", self.spellIDs, self.minTimeRemaining)
		if self.spell then
			self:Update()
		end
	end

	function proto:Test()
		if self.spell and not self.findBuff(self.unit) then
			return self.spell:IconLine(), self.spell:GetSpellID()
		end
	end
end

------------------------------------------------------------------------------------------------------------------------

mod.units = {}
local function iteratePlayerUnit(_, index)
	if index == 0 then
		return 1, "player"
	end
end

local function iteratePlayerAndPartyUnits(_, index)
	index = index + 1
	if index == 5 then
		return 5, "player"
	elseif index > 5 then
		return
	end
	return index, string.format("party%d", index)
end

local function iterateRaidUnits(_, index)
	index = index + 1
	if index > 40 then
		return
	end
	return index, string.format("raid%d", index)
end

local function getGroupType()
	if IsInRaid() then
		return "raid", iterateRaidUnits
	end
	if IsInGroup() then
		return "party", iteratePlayerAndPartyUnits
	end
	return "alone", iteratePlayerUnit
end

function mod:ScanRoster(event)
	local groupType, iterateGroupUnits = getGroupType()
	if groupType ~= self.groupType then
		self:Debug("changed group type", self.groupType, "=>", groupType)
		self.groupType = groupType
		wipe(self.units)
	end
	for _, unitID in iterateGroupUnits, nil, 0 do
		if UnitExists(unitID) then
			local unit, guid = self.units[unitID], UnitGUID(unitID)
			if not unit then
				self.units[unitID] = { guid = guid, id = unitID, name = UnitName(unitID) }
				self:Debug("unit added", self.units[unitID])
			elseif guid ~= unit.guid then
				unit.guid, unit.name = guid, UnitName(unitID)
				self:Debug("unit changed", unit)
			end
		elseif self.units[unitID] then
			self:Debug("unit removed", self.units)
			self.units[unitID] = nil
		end
	end
	self:ScanUnits(self.units)
	self:Debug("roster scanned", event, groupType)
end

local function isActive(unitID)
	return UnitIsConnected(unitID) and not UnitIsDeadOrGhost(unitID)
end

function mod:ScanUnits(unitIDs)
	if not next(unitIDs) or InCombatLockdown() then return end
	local hold = self.hold
	self.hold = true
	for unitID in pairs(unitIDs) do
		local unit = self.units[unitID]
		if unit then
			local active = UnitIsConnected(unitID) and not UnitIsDeadOrGhost(unitID)
			local role = UnitGroupRolesAssigned(unitID)
			if active ~= unit.active or role ~= unit.role then
				unit.active, unit.role = active, role
				self:Debug("unit", unit, active and "activated" or "deactivated", role)
				self:SendMessage("WheelCast_Unit_Changed", unit)
			end
		end
	end
	self.hold = hold
	self:Update("ScanUnits")
	self:Debug("units scanned")
end

function mod:ScanUnit(unitID)
	local unit = self.units[unitID]
	if not unit then return end
	local missing = isActive(unitID) and not self.findBuff(unitID)
	if missing ~= unit.missing then
		unit.missing = true
		return true
	end
end

function mod:IterateUnits()
	return pairs(self.units)
end
