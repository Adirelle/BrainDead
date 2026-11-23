--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon  = ...

local ae        = LibStub("AceEvent-3.0")

local mod       = addon:NewModule('WheelCast')
mod.uiName      = "Cast thing with mouse wheel"

mod.playerRace  = select(2, UnitRace("player"))
mod.playerClass = select(2, UnitClass("player"))

addon.WheelCast = mod

mod.moduleOrder = {}
mod.actions     = {}
mod.labels      = {}

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
	self:RegisterEvent("UNIT_ENTERED_VEHICLE", "Disable")
	self:RegisterEvent("PET_BATTLE_OPENING_START", "Disable")
	self:RegisterEvent("PLAYER_CONTROL_LOST", "Disable")
	self:RegisterEvent("PLAYER_DEAD", "Disable")

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
	if minRemainingTime then
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

function mod:NewSelfBuffModule(name, ...)
	local subMod       = self:NewModule(name)
	subMod.priority    = 50
	subMod.unit        = "player"
	subMod.SetupAction = subMod.SetSpell

	subMod.handler     = mod:NewSpellHandler("HELPFUL", 60, ...)

	function subMod:OnEnable()
		self:RegisterEvent('UNIT_AURA', "OnUnitEvent")
		self:RegisterEvent('SPELLS_CHANGED')
		self:SPELLS_CHANGED()

		self:Debug("Enabled")
	end

	function subMod:SPELLS_CHANGED()
		self.handler:ScanSpellBook()
		self:Update()
	end

	function subMod:Test()
		return self.handler:Test(self.unit)
	end

	return subMod
end
