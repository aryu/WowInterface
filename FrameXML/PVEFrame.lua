---------------------------------------------------------------
-- PVE FRAME
---------------------------------------------------------------
local panels = {
	{ name = "GroupFinderFrame", addon = nil },
	{ name = "PVPUIFrame", addon = "Blizzard_PVPUI" },
	{ name = "ChallengesFrame", addon = "Blizzard_ChallengesUI" },
}

function PVEFrame_OnLoad(self)
	RaiseFrameLevel(self.shadows);
	PanelTemplates_SetNumTabs(self, #panels);
	
	self.maxTabWidth = (self:GetWidth() - 19) / #panels;
end

function PVEFrame_ToggleFrame(sidePanelName, selection)
	if ( UnitLevel("player") < SHOW_LFD_LEVEL ) then
		return;
	end
	local self = PVEFrame;
	if ( self:IsShown() ) then
		if ( sidePanelName ) then
			local sidePanel = _G[sidePanelName];
			if ( sidePanel ) then
				--We know the panel is loaded, so try to dereference the selection
				if ( type(selection) == "string" ) then
					selection = _G[selection];
				end
				if ( sidePanel:IsShown() and (not selection or not sidePanel.getSelection or sidePanel:getSelection() == selection) ) then
					HideUIPanel(self);
					return;
				end
			end
		else
			HideUIPanel(self);
			return;
		end
	end
	PVEFrame_ShowFrame(sidePanelName, selection);
end

function PVEFrame_ShowFrame(sidePanelName, selection)
	local self = PVEFrame;
	-- find side panel
	local tabIndex;
	if ( sidePanelName ) then
		for index, data in pairs(panels) do
			if ( data.name == sidePanelName ) then
				tabIndex = index;
				break;
			end
		end
	else
		-- no side panel specified, check current panel
		if ( self.activeTabIndex ) then
			tabIndex = self.activeTabIndex;
		else
			-- no current panel, go to the first panel
			tabIndex = 1;
		end
	end	
	if ( not tabIndex ) then
		return;
	end
	-- load addon if needed
	if ( panels[tabIndex].addon ) then
		UIParentLoadAddOn(panels[tabIndex].addon);
		panels[tabIndex].addon = nil;
	end

	-- we've loaded the AddOn, so try to dereference the selection if needed
	if ( type(selection) == "string" ) then
		selection = _G[selection];
	end

	-- show it
	ShowUIPanel(self);
	self.activeTabIndex = tabIndex;	
	PanelTemplates_SetTab(self, tabIndex);
	for index, data in pairs(panels) do
		local panel = _G[data.name];
		if ( index == tabIndex ) then
			panel:Show();
			if( panel.update ) then
				panel:update(selection);
			end
		elseif ( panel ) then
			panel:Hide();
		end
	end
	--PVEFrame_UpdateTabs(self);
end

function PVEFrame_UpdateTabs(self)
	self = self or PVEFrame;
	for i = 1, self.numTabs do
		local state = "normal";	
		local tab = self["tab"..i];
		if ( tab.panel.GetState ) then
			state = tab.panel:GetState();
		end
		-- do something with state
	end	
end

function PVEFrame_TabOnClick(self)
	PlaySound("igCharacterInfoTab");
	PVEFrame_ShowFrame(panels[self:GetID()].name);
end

---------------------------------------------------------------
-- GROUP FINDER
---------------------------------------------------------------

SCENARIOS_SHOW_LEVEL = 85;
SCENARIOS_HIDE_ABOVE_LEVEL = 90;
RAID_FINDER_SHOW_LEVEL = 85;

local groupFrames = { "LFDParentFrame", "ScenarioFinderFrame", "RaidFinderFrame", "LFGListPVEStub" }

function GroupFinderFrame_OnLoad(self)
	SetPortraitToTexture(self.groupButton1.icon, "Interface\\Icons\\INV_Helmet_08");
	self.groupButton1.name:SetText(LOOKING_FOR_DUNGEON_PVEFRAME);
	SetPortraitToTexture(self.groupButton2.icon, "Interface\\Icons\\Icon_Scenarios");
	self.groupButton2.name:SetText(SCENARIOS_PVEFRAME);
	SetPortraitToTexture(self.groupButton3.icon, "Interface\\LFGFrame\\UI-LFR-PORTRAIT");
	self.groupButton3.name:SetText(RAID_FINDER_PVEFRAME);
	SetPortraitToTexture(self.groupButton4.icon, "Interface\\Icons\\Achievement_General_StayClassy");
	self.groupButton4.name:SetText(LFGLIST_NAME);
	
	GroupFinderFrame_EvaluateButtonVisibility(self, UnitLevel("player"));
	
	self:RegisterEvent("PLAYER_LEVEL_UP");

	GroupFinderFrameButton_SetEnabled(self.groupButton4, true);

	-- set up accessors
	self.getSelection = GroupFinderFrame_GetSelection;
	self.update = GroupFinderFrame_Update;
end

function GroupFinderFrame_EvaluateButtonVisibility(self, level)
	if ( level > SCENARIOS_HIDE_ABOVE_LEVEL ) then
		self.groupButton2:Hide()
		
		if ( GroupFinderFrame_GetSelectedIndex(self) == self.groupButton2:GetID() ) then
			-- Deselect this now hidden tab if it happened to be selected
			self.selection = nil
			GroupFinderFrame_ShowGroupFrame(nil)
		end
	else
		if ( level < SCENARIOS_SHOW_LEVEL ) then
			GroupFinderFrameButton_SetEnabled(self.groupButton2, false);
			self.groupButton2.tooltip = self.groupButton2.tooltip or format(FEATURE_BECOMES_AVAILABLE_AT_LEVEL, SCENARIOS_SHOW_LEVEL);
		else
			GroupFinderFrameButton_SetEnabled(self.groupButton2, true);
			self.groupButton2.tooltip = nil
		end
		
		self.groupButton2:Show()
	end
	
	if ( level < RAID_FINDER_SHOW_LEVEL ) then
		GroupFinderFrameButton_SetEnabled(self.groupButton3, false);
		self.groupButton3.tooltip = self.groupButton3.tooltip or format(FEATURE_BECOMES_AVAILABLE_AT_LEVEL, RAID_FINDER_SHOW_LEVEL);
	else
		self.groupButton3.tooltip = nil;
		GroupFinderFrameButton_SetEnabled(self.groupButton3, true);
	end
	
	GroupFinderFrame_UpdateButtonAnchors(self);
end

function GroupFinderFrame_UpdateButtonAnchors(self)
	local button3RelativeTo = self.groupButton2:IsShown() and self.groupButton2 or self.groupButton1
	self.groupButton3:SetPoint("TOP", button3RelativeTo, "BOTTOM", 0, -23);
end

function GroupFinderFrameButton_SetEnabled(button, enabled)
	if ( button:IsEnabled() == enabled ) then
		return
	end
	
	if ( enabled ) then
		button.bg:SetTexCoord(0.00390625, 0.87890625, 0.75195313, 0.83007813);
		button.name:SetFontObject("GameFontNormalLarge");
	else
		button.bg:SetTexCoord(0.00390625, 0.87890625, 0.67187500, 0.75000000);
		button.name:SetFontObject("GameFontDisableLarge");
	end
	SetDesaturation(button.icon, not enabled);
	SetDesaturation(button.ring, not enabled);
	button:SetEnabled(enabled);
end

function GroupFinderFrame_OnEvent(self, event, ...)
	local level = ...;
	GroupFinderFrame_EvaluateButtonVisibility(self, level);
end

function GroupFinderFrame_GetSelection(self)
	return self.selection;
end

function GroupFinderFrame_GetSelectedIndex(self)
	return self.selectionIndex;
end

function GroupFinderFrame_Update(self, frame)
	GroupFinderFrame_ShowGroupFrame(frame);
end

function GroupFinderFrame_OnShow(self)
	SetPortraitToTexture(PVEFrame.portrait, "Interface\\LFGFrame\\UI-LFG-PORTRAIT");
	PVEFrame.TitleText:SetText(GROUP_FINDER);
end

function GroupFinderFrame_ShowGroupFrame(frame)
	frame = frame or GroupFinderFrame.selection or LFDParentFrame;
	-- hide the other frames and select the right button
	for index, frameName in pairs(groupFrames) do
		local groupFrame = _G[frameName];
		if ( groupFrame == frame ) then
			GroupFinderFrame_SelectGroupButton(index);
		else
			groupFrame:Hide();
		end
	end
	frame:Show();
	GroupFinderFrame.selection = frame;	
end

function GroupFinderFrame_SelectGroupButton(index)
	local self = GroupFinderFrame;
	for i = 1, #groupFrames do
		local button = self["groupButton"..i];
		if ( i == index ) then
			button.bg:SetTexCoord(0.00390625, 0.87890625, 0.59179688, 0.66992188);
		else
			button.bg:SetTexCoord(0.00390625, 0.87890625, 0.75195313, 0.83007813);
		end
	end
	
	GroupFinderFrame.selectionIndex = index
end

function GroupFinderFrameGroupButton_OnClick(self)
	local frameName = groupFrames[self:GetID()];
	GroupFinderFrame_ShowGroupFrame(_G[frameName]);
end
