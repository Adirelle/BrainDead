--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
]]

local _, addon = ...

local mod = addon:NewModule('ValidateQuest')

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
	self:Debug('QUEST_COMPLETE',  GetNumQuestChoices(), GetQuestMoneyToGet())
	if GetNumQuestChoices() < 2 and GetQuestMoneyToGet() == 0 then
		GetQuestReward(0)
	end
end
