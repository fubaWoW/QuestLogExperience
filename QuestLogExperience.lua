local AddOnName, AddOn = ...

local LibQuestXP = LibStub:GetLibrary("LibQuestXP-1.0", true)
if not LibQuestXP then return end

local isClassicWow = select(4,GetBuildInfo()) < 20000
local gLevel = _G.LEVEL
local gLoss = _G.LOSS
local gExperience = _G.COMBAT_XP_GAIN

if not QuestLogExperienceDB then
	QuestLogExperienceDB = {
		ColorLevelByDifficulty = true,
	}
end

local textColor = {1, 1, 1}
local titleTextColor = {1, 0.80, 0.10}

local maxPlayerLevel = 60;

local QLRTT_point, QLRTT_relativeTo, QLRTT_relativePoint, QLRTT_xOfs, QLRTT_yOfs = QuestLogRewardTitleText:GetPoint()

local function round(num, numDecimalPlaces)
  return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

local function AddOnPrint(msg)
	(SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME):AddMessage("|cffffff78QLE: |r"..msg)
end

local function CreateSlider(g_name, parent, title, min_val, max_val, val_step, func)
	local SliderEditBoxBackdrop = {
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
		tile = true, edgeSize = 1, tileSize = 5,
	}
	
	local slider = CreateFrame("Slider", g_name, parent, "OptionsSliderTemplate")
	local editbox = CreateFrame("EditBox", g_name.."EditBox", slider)
	
	local text = _G[slider:GetName() .. "Text"]
	text:SetFontObject(GameFontNormal)
	text:SetJustifyH("CENTER")
	text:SetHeight(15)
	text:SetText(title)
	slider.text = text
	
	slider:SetOrientation("HORIZONTAL")
	slider:SetHeight(15)
	slider:SetHitRectInsets(0, 0, -10, 0)
	slider:SetPoint("TOP", parent, "BOTTOM")
	slider:SetPoint("LEFT", 3, 0)
	slider:SetPoint("RIGHT", -3, 0)
	slider:SetValue(0)
	_G[slider:GetName() .. "Low"]:SetText(nil)
	_G[slider:GetName() .. "High"]:SetText(nil)
	slider:SetMinMaxValues(min_val, max_val)
	slider:SetValueStep(val_step)
	
	local lowtext = slider:CreateFontString(g_name.."LowText", "ARTWORK", "GameFontHighlightSmall")
	lowtext:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 2, 3)

	local hightext = slider:CreateFontString(g_name.."HighText", "ARTWORK", "GameFontHighlightSmall")
	hightext:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", -2, 3)
	
	lowtext:SetText(floor(min_val))
	hightext:SetText(floor(max_val))
	slider:SetObeyStepOnDrag(true)
	
	editbox:SetAutoFocus(false)
	editbox:SetFontObject(GameFontHighlightSmall)
	editbox:SetPoint("TOP", slider, "BOTTOM")
	editbox:SetHeight(14)
	editbox:SetWidth(70)
	editbox:SetJustifyH("CENTER")
	editbox:EnableMouse(true)
	editbox:SetBackdrop(SliderEditBoxBackdrop)
	editbox:SetBackdropColor(0, 0, 0, 0.5)
	editbox:SetBackdropBorderColor(0.3, 0.3, 0.30, 0.80)	
	editbox:SetText(slider:GetValue())
	
	editbox:SetScript("OnEnterPressed", function(self)
			local val = self:GetText()
			if tonumber(val) then
				slider:SetValue(val)
				self:ClearFocus()
			end
	end)
	
	editbox:SetScript("OnEnter", function(self)
		self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
	end)
	
	editbox:SetScript("OnLeave", function(self)
		self:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
	end)
	
	slider:HookScript("OnMouseDown", function(self, btn)
		editbox:ClearFocus()
	end)
	
	slider:SetScript("OnValueChanged", function(self)
			editbox:SetText(tostring((floor(self:GetValue() / val_step) * val_step)))
			if func then func(self) end
	end)
	
	if ElvUI then
		local E, L, V, P, G = unpack(ElvUI)
		local S = E:GetModule('Skins')
		S:HandleSliderFrame(slider)
		S:HandleEditBox(editbox)
	end
	
	slider.textLow = lowtext
	slider.textHigh = hightext	
	slider.editbox = editbox
	
	return slider
end

function GetAdjustedXPByLevel(charLevel, xp, qLevel)
		if (charLevel >= 60) then return 0 end
    local diffFactor = 2 * (qLevel - charLevel) + 20;
    if (diffFactor < 1) then
        diffFactor = 1;
    elseif (diffFactor > 10) then
        diffFactor = 10;
    end

    xp = xp * diffFactor / 10;
    if (xp <= 100) then
        xp = 5 * floor((xp + 2) / 5);
    elseif (xp <= 500) then
        xp = 10 * floor((xp + 5) / 10);
    elseif (xp <= 1000) then
        xp = 25 * floor((xp + 12) / 25);
    else
        xp = 50 * floor((xp + 25) / 50);
    end

    return xp;
end

local QuestLogExperienceTitleText = QuestLogDetailScrollChildFrame:CreateFontString("QuestLogExperienceTitleText", "ARTWORK", "QuestTitleFont")
QuestLogExperienceTitleText:SetJustifyH ("LEFT")

local QuestLogExperienceText = QuestLogDetailScrollChildFrame:CreateFontString("QuestLogExperienceText", "ARTWORK", "QuestFont")
QuestLogExperienceText:SetShadowOffset(1,-1)
QuestLogExperienceText:SetJustifyH ("LEFT")
--QuestLogExperienceText:SetTextColor(0.30, 0.18, 0.00, 1.00)

local Slider_minVal = ((UnitLevel("player")-10 > 0 and UnitLevel("player")-10) or 1)
local Slider_maxVal = ((UnitLevel("player")+10 < 60 and UnitLevel("player")+10) or (maxPlayerLevel-1))
local QuestLogExperienceSlider = CreateSlider("QuestLogExperienceSlider", QuestLogDetailScrollChildFrame, "", Slider_minVal, Slider_maxVal, 1, nil)

local XpResetButton = CreateFrame("Button", nil, QuestLogDetailScrollChildFrame)
XpResetButton:SetAllPoints(QuestLogExperienceTitleText)
XpResetButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

if ElvUI then
	QuestLogExperienceTitleText:SetTextColor(unpack(titleTextColor))
	QuestLogExperienceText:SetTextColor(unpack(textColor))
end

local function usage()
    ChatFrame1:AddMessage(L["|cff0080ffQLE |r/qle |cff0080ffUsage:|r"])
    ChatFrame1:AddMessage(L["|cff0080ff/qle color|r - Toggle Colored Quest Level Text"])
end

_G['SLASH_' .. AddOnName .. 1] = '/qle'
_G['SLASH_' .. AddOnName .. 2] = '/questlogexperience'
SlashCmdList[AddOnName] = function(msg)
	local cmd = ""
	if msg and type(msg) == "string" then cmd = msg end
	if cmd ~= "" then
		if cmd == "colored" then
			if QuestLogExperienceDB.ColorLevelByDifficulty then
				QuestLogExperienceDB.ColorLevelByDifficulty = false
				AddOnPrint("Colored Quest Level Text is now disabled.")
			else
				QuestLogExperienceDB.ColorLevelByDifficulty = true
				AddOnPrint("Colored Quest Level Text is now enabled.")
			end
		end
	else
		ChatFrame1:AddMessage("|cffffff78QuestLogExperience |r/qle |cffffff78Usage:|r")
		ChatFrame1:AddMessage("|cffffff78/qle colored|r - Toggle Colored Quest Level Text")
	end
end

hooksecurefunc('QuestLog_UpdateQuestDetails', function()
	local questSelected = GetQuestLogSelection()
	local questTitle, level, questTag, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(questSelected)
	if not isHeader and (tonumber(level) > 0) and (questID > 0) then	
		local xp, qLevel = LibQuestXP:GetQuestInfo(questID)
		local maxXP = GetAdjustedXPByLevel(1, xp, qLevel)

		local LoseLevel = 0
		local LoseLevelXP = 0
		for i=1, 10 do
			local testlevel = qLevel+i
			local curXP = GetAdjustedXPByLevel(testlevel, xp, qLevel)
			if curXP < maxXP then
				LoseLevel = testlevel
				LoseLevelXP = curXP
				break
			end
		end

		local questXP = GetQuestLogRewardXP()
		if not questXP or questXP == 0 then questXP = GetQuestLogRewardXP(questID) end
		if not questXP or questXP == 0 then return end

		if questXP > 0 then			
			QuestLogExperienceTitleText:SetText(gExperience)
			QuestLogExperienceTitleText:Hide()
			QuestLogExperienceTitleText:ClearAllPoints()
			QuestLogExperienceTitleText:SetPoint("TOPLEFT", QuestLogQuestDescription, "BOTTOMLEFT", 0, -15)

			local PlayerCurXP = UnitXP("player")
			local PlayerMaxXP = UnitXPMax("player")
			local charLevel = UnitLevel("player");
			local QuestXPPerc = questXP / (PlayerMaxXP / 100)
			Slider_minVal = (UnitLevel("player")-10 > 0 and UnitLevel("player")-10) or 1
			Slider_maxVal = (LoseLevel+4 < 60 and LoseLevel+4) or (maxPlayerLevel-1)

			QuestLogExperienceText:ClearAllPoints()
			QuestLogExperienceText:SetPoint("TOPLEFT", QuestLogExperienceTitleText, "BOTTOMLEFT", 0, -5)
			
			-- Slider
			QuestLogExperienceSlider:ClearAllPoints()
			QuestLogExperienceSlider:SetPoint("TOPLEFT", QuestLogExperienceText, "BOTTOMLEFT", 0, -2);
			QuestLogExperienceSlider:SetMinMaxValues(Slider_minVal, Slider_maxVal)
			QuestLogExperienceSlider.textLow:SetText(floor(Slider_minVal))
			QuestLogExperienceSlider.textHigh:SetText(floor(Slider_maxVal))
			QuestLogExperienceSlider.editbox:SetText(charLevel)
			QuestLogExperienceSlider.editbox:ClearFocus()
			QuestLogExperienceSlider:SetValue(charLevel)
			
			XpResetButton:SetScript("OnClick", function(self, btn)
				if btn == "RightButton" then
					QuestLogExperienceSlider:SetValue(LoseLevel)
					QuestLogExperienceSlider.editbox:ClearFocus()
				else
					QuestLogExperienceSlider:SetValue(UnitLevel("player"))
					QuestLogExperienceSlider.editbox:ClearFocus()
				end
			end)
			
			local diffcolor = GetRelativeDifficultyColor(charLevel, level)
			local coloredlevel = charLevel
			local colortext = gLevel.." "..charLevel..": "..questXP.." ("..round(QuestXPPerc, 2).."%)"
			if QuestLogExperienceDB.ColorLevelByDifficulty then
				coloredlevel = format("\124cff%.2x%.2x%.2x%d\124r", diffcolor.r*255, diffcolor.g*255, diffcolor.b*255, charLevel)
				colortext = format("\124cff%.2x%.2x%.2x%s\124r", diffcolor.r*255, diffcolor.g*255, diffcolor.b*255, colortext)
			end
			QuestLogExperienceText:SetText(colortext);
			
			QuestLogExperienceSlider:HookScript("OnValueChanged", function(self, value)
				local slider_questXP = GetAdjustedXPByLevel(value, xp, qLevel)
				local slider_PlayerMaxXP = UnitXPMax("player")
				local slider_XPPerc = slider_questXP / (slider_PlayerMaxXP / 100)
				diffcolor = GetRelativeDifficultyColor(value, level)
				coloredlevel = value
				colortext = gLevel.." "..value..": "..slider_questXP.." ("..round(slider_XPPerc, 2).."%)"
				if QuestLogExperienceDB.ColorLevelByDifficulty then
					coloredlevel = format("\124cff%.2x%.2x%.2x%d\124r", diffcolor.r*255, diffcolor.g*255, diffcolor.b*255, value)
					colortext = format("\124cff%.2x%.2x%.2x%s\124r", diffcolor.r*255, diffcolor.g*255, diffcolor.b*255, colortext)
				end				
				QuestLogExperienceText:SetText(colortext);
				
			end)

			if questXP and (questXP > 0) then
				QuestLogExperienceTitleText:Show()
				QuestFrame_SetAsLastShown(QuestLogExperienceSlider)
			else
				QuestLogExperienceTitleText:Hide()
			end
			
			if QuestLogRewardTitleText:IsShown() then
				QuestLogRewardTitleText:SetPoint(QLRTT_point, QuestLogExperienceSlider, QLRTT_relativePoint, QLRTT_xOfs, QLRTT_yOfs-10)
				QuestFrame_SetAsLastShown(QuestLogRewardTitleText)
			end
		end
	end
end)