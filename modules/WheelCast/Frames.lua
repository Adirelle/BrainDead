--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon = ...
local mod      = addon.WheelCast

local anchor, tooltip, button

anchor         = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
anchor:SetHeight(24)
anchor:Hide()

anchor.backdropInfo = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile =
	"Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 16,
	insets = { left = 5, right = 5, top = 5, bottom = 5 },
	tile = true,
	tileSize = 16
}
anchor:ApplyBackdrop()

anchor:SetBackdropColor(0.09, 0.09, 0.19, 0.5)
anchor:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

local text = anchor:CreateFontString(nil, nil, "GameFontNormalSmall")
text:SetPoint("CENTER")
text:SetText("Chores")
text:SetTextColor(1, 1, 1)
anchor:SetWidth(text:GetStringWidth() + 8)

anchor:SetMovable(true)
anchor:RegisterForClicks("RightButtonUp")
anchor:RegisterForDrag("LeftButton")

anchor:SetScript("OnClick", function(self, btn)
	mod.db.profile.anchor.locked = true
	self:Hide()
end)

anchor:SetScript("OnDragStart", anchor.StartMoving)

anchor:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	local anchorDb = mod.db.profile.anchor
	anchorDb.point, anchorDb.x, anchorDb.y = "BOTTOMLEFT", self:GetLeft(), self:GetBottom()
end)

anchor:SetScript("OnShow", function()
	tooltip:Reanchor()
end)

anchor:SetScript("OnHide", anchor.StopMovingOrSizing)

----

local tooltipName = mod.name .. "Tooltip"
tooltip = CreateFrame("GameTooltip", tooltipName, UIParent, "SharedTooltipTemplate")
_G[tooltipName .. "TextLeft1"]:SetFontObject(GameTooltipText)
_G[tooltipName .. "TextRight1"]:SetFontObject(GameTooltipText)
tooltip:Hide()

local function GetTipAnchor()
	local x, y = anchor:GetCenter()
	if not x or not y then return "TOPLEFT", anchor, "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth() * 2 / 3) and "RIGHT" or (x < UIParent:GetWidth() / 3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight() / 2) and "TOP" or "BOTTOM"
	return vhalf .. hhalf, anchor, (vhalf == "TOP" and "BOTTOM" or "TOP") .. hhalf
end

function tooltip:Reanchor()
	self:SetOwner(anchor, "ANCHOR_NONE")
	self:SetPoint(GetTipAnchor())
end

----

local buttonName = mod.name .. "Button"
button = CreateFrame("Button", buttonName, tooltip, "SecureActionButtonTemplate")
button:RegisterForClicks("AnyDown", "AnyUp")
button:SetAllPoints(tooltip)
button:Hide()

button:SetScript("OnDragStart", function()
	tooltip:StartMoving()
end)

button:SetScript("OnDragStop", function()
	tooltip:StopMovingOrSizing()
	local db = mod.db.profile.anchor
	db.x, db.y = tooltip:GetLeft(), tooltip:GetBottom()
	tooltip:Reanchor()
end)

function button:SetManyAttributes(...)
	for i = 1, select("#", ...), 2 do
		local att, val = select(i, ...)
		self:SetAttribute(att, val)
	end
	return true
end

function button:SetSpell(spellID, unit)
	self:SetManyAttributes("type", "spell", "spell", spellID, "unit", unit)
end

function button:SetMacroText(macrotext)
	self:SetManyAttributes("type", "macro", "macrotext", macrotext)
end

function button:Clear()
	self:SetManyAttributes("type", nil, "unit", nil, "bag", nil, "slot", nil, "item", nil, "spell", nil, "macrotext",
		nil)
end

button:SetScript("OnShow", function(self)
	if InCombatLockdown() then return end
	SetOverrideBindingClick(self, true, 'MOUSEWHEELUP', buttonName)
	SetOverrideBindingClick(self, true, 'MOUSEWHEELDOWN', buttonName)
end)

button:SetScript("OnHide", function(self)
	if InCombatLockdown() then return end
	ClearOverrideBindings(self)
end)

mod.anchor, mod.tooltip, mod.button = anchor, tooltip, button
