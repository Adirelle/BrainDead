--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon = ...

local mod = addon:NewModule('QuietFishing', "AceEvent-3.0")

local fishingPoleLocation = ItemLocation:CreateFromEquipmentSlot(_G.INVSLOT_MAINHAND)

local cvars = {
	"Sound_EnableAmbience",
	"Sound_EnableEmoteSounds",
	"Sound_EnablePetSounds",
	"Sound_EnablePingSounds",
}

function mod:OnInitialize()
	self.muted = false
	self.previous = {}
	self:Debug("Initalized", fishingPoleLocation)
end

function mod:OnEnable()
	self:RegisterEvent('PLAYER_EQUIPMENT_CHANGED')
	self:RegisterEvent('PLAYER_LOGOUT', "Disable")
	self:Update("OnEnable")
	self:Debug('Enabled')
end

function mod:OnDisable()
	self:Unmute()
	self:Debug('Disabled')
end

function mod:PLAYER_EQUIPMENT_CHANGED(event, slot)
	self:Debug(event, slot)
	if slot == fishingPoleLocation:GetEquipmentSlot() then
		self:Update(event)
	end
end

function mod:Update(event)
	local itemID = C_Item.GetItemID(fishingPoleLocation)
	if not itemID then
		return
	end
	local subclassID = select(13, C_Item.GetItemInfo(itemID))
	if subclassID == nil then
		return
	end
	local fishingPoleEquipped = subclassID == 20
	self:Debug("Update", event, subclassID, fishingPoleEquipped)
	if fishingPoleEquipped then
		self:Mute(event)
	else
		self:Unmute(event)
	end
end

function mod:Mute(event)
	if self.muted then
		return
	end
	self:Debug("Mute", event)
	for _, cvar in ipairs(cvars) do
		self.previous[cvar] = GetCVar(cvar)
		if self.previous[cvar] then
			SetCVar(cvar, 0)
			self:Debug("Disabled", cvar)
		end
	end
	self.muted = true
end

function mod:Unmute(event)
	if not self.muted then
		return
	end
	self:Debug("Unmute", event)
	for cvar, value in pairs(self.previous) do
		if value then
			SetCVar(cvar, value)
			self:Debug("Enabled", cvar)
		end
	end
	self.muted = false
end
