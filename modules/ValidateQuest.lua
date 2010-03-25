--[[
BrainDead - when you don't want to think anymore (automated tasks).
Copyright 2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
]]

local _, addon = ...

local mod = addon:NewModule('ValidateQuest', 'AceHook-3.0')

function mod:OnEnable()
	self:Debug('Enabled')
	self:SecureHook('QuestFrameRewardPanel_OnShow')
end

function mod:QuestFrameRewardPanel_OnShow()
	if GetNumQuestChoices() == 0 and GetQuestMoneyToGet() == 0 then
		QuestRewardCompleteButton_OnClick()
	end
end
