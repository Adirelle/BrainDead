--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon = ...

local mod = addon:NewModule('QuestWatch', "AceBucket-3.0", "AceHook-3.0")
mod.uiName = "(Un)watch quests based on current zone"

local update_events = {
	"PLAYER_ENTERING_WORLD",
	"QUEST_ACCEPTED",
	"QUEST_COMPLETE",
	"QUEST_REMOVED",
	"QUEST_POI_UPDATE",
	"RAID_ROSTER_UPDATE",
	"ZONE_CHANGED_NEW_AREA",
	"PLAYER_MAP_CHANGED",
	"SUPER_TRACKING_CHANGED",
}

function mod:OnEnable()
	self:Debug('Enabled')

	for _, event in pairs(update_events) do
		self:RegisterEvent(event, "Update")
	end
	-- self:RegisterBucketEvent(update_events, 0.5,"Update")

	self:SecureHook(WorldMapFrame, "OnMapChanged", function()
		self:Update("OnMapChanged")
	end)

	self:Update("OnEnable")
end

function mod:OnDisable()
	self:Debug('Disabled')
end

function mod:Update(event)
	if InCombatLockdown() or not QuestUtil.CanRemoveQuestWatch() then
		return
	end

	self.superTracked = C_SuperTrack.GetSuperTrackedQuestID()
	self.inRaid = IsInRaid()
	self.inParty = UnitInParty("player")
	self.inPlayerMap = WorldMapFrame:GetMapID() == C_Map.GetBestMapForUnit("player")
	self.inInstance = select(2, IsInInstance())

	local numEntries = C_QuestLog.GetNumQuestLogEntries()
	for i = 1, numEntries do
		local entry = C_QuestLog.GetInfo(i)
		if not entry.isHidden and not entry.isHeader then
			self:UpdateQuest(entry)
		end
	end
end

function mod:UpdateQuest(quest)
	local shouldWatch = self:ShouldWatch(quest)
	if shouldWatch == nil or shouldWatch == QuestUtils_IsQuestWatched(quest.questID) then
		return
	end

	if shouldWatch then
		self:Debug("Automatically watch quest", quest.title)
		C_QuestLog.AddQuestWatch(quest.questID)
	else
		self:Debug("Automatically unwatch quest", quest.title)
		C_QuestLog.RemoveQuestWatch(quest.questID)
	end
end

function mod:ShouldWatch(quest)
	if quest.questID == self.superTracked then
		return true
	end

	local questType = C_QuestLog.GetQuestType(quest.questID)

	if questType == Enum.QuestTag.Raid10 or questType == Enum.QuestTag.Raid25 or questType == Enum.QuestTag.Raid then
		if not self.inRaid then
			return false
		end
	elseif questType == Enum.QuestTag.Group then
		if not self.inParty then
			return false
		end
	elseif questType == Enum.QuestTag.Dungeon then
		if self.inInstance == "party" then
			return nil
		end
		return false
	elseif self.inInstance ~= "none" then
		return false
	end

	if not self.inPlayerMap then
		return nil
	end

	-- self:Debug("quest", quest.title, "type", questType, "isOnMap", quest.isOnMap, "hasLocalPOI", quest.hasLocalPOI)
	return quest.isOnMap or quest.hasLocalPOI
end
