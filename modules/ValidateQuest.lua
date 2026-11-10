--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010-2026 Adirelle (adirelle@gmail.com)

All rights reserved.
]]

local _, addon = ...

local mod = addon:NewModule('ValidateQuest')
mod.uiName = "Turn in quests with no reward choice"

function mod:OnEnable()
	self:Debug('Enabled')
	self:RegisterEvent('QUEST_PROGRESS')
	self:RegisterEvent('QUEST_COMPLETE')
end

function mod:QUEST_PROGRESS()
	self:Debug('QUEST_PROGRESS', IsQuestCompletable())
	if IsQuestCompletable() then
		CompleteQuest()
	end
end

function mod:QUEST_COMPLETE()
	self:Debug('QUEST_COMPLETE', GetNumQuestChoices(), GetQuestMoneyToGet())
	if GetNumQuestChoices() <= 1 and GetQuestMoneyToGet() == 0 then
		GetQuestReward(1)
	end
end
