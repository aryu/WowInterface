GARRISON_FOLLOWER_LIST_BUTTON_FULL_XP_WIDTH = 205;
GARRISON_FOLLOWER_MAX_LEVEL = 100;
GARRISON_FOLLOWER_MAX_UPGRADE_QUALITY = 4;

GARRISON_MISSION_NAME_FONT_COLOR	=	{r=0.78, g=0.75, b=0.73};
GARRISON_MISSION_TYPE_FONT_COLOR	=	{r=0.8, g=0.7, b=0.53};


---------------------------------------------------------------------------------
--- Main Frame                                                                ---
---------------------------------------------------------------------------------
function GarrisonLandingPage_OnLoad(self)
	GarrisonFollowerList_OnLoad(self)

	PanelTemplates_SetNumTabs(self, 2);
	self.selectedTab = 1;
	PanelTemplates_UpdateTabs(self);
	
	if ( PanelTemplates_GetSelectedTab(self) == 1 ) then
		GarrisonLandingPage.Report:Show();
		GarrisonLandingPage.FollowerList:Hide();
		GarrisonLandingPage.FollowerTab:Hide();
	else
		GarrisonLandingPage.Report:Hide();
		GarrisonLandingPage.FollowerList:Show();
		GarrisonLandingPage.FollowerTab:Show();
	end
end

function GarrisonLandingPage_OnShow(self)
	if (C_Garrison.IsInvasionAvailable()) then
		self.InvasionBadge:Show();
		self.InvasionBadge.InvasionBadgeAnim:Play();
	else
		self.InvasionBadge:Hide();
	end

	-- if there's no follower displayed on the right, select the first one
	if (not GarrisonLandingPage.FollowerTab.followerID) then
		local index = GarrisonLandingPage.FollowerList.followersList[1];
		if (index) then
			GarrisonFollowerPage_ShowFollower(GarrisonLandingPage.FollowerTab, GarrisonLandingPage.FollowerList.followers[index].followerID);
		else
			-- empty page
			GarrisonFollowerPage_ShowFollower(GarrisonLandingPage.FollowerTab,0);
		end
	end
	
	PlaySound("igSpellBookOpen");
end

function GarrisonLandingPage_OnHide(self)
	PlaySound("igSpellBookClose");
end

function GarrisonLandingPage_OnEvent(self, event, ...)
	GarrisonFollowerList_OnEvent(self, event, ...);
end

function GarrisonLandingPageTab_OnClick(self)
	PlaySound("igCharacterInfoTab");
	local id = self:GetID();
	PanelTemplates_SetTab(GarrisonLandingPage, id);
	if ( id == 1 ) then
		GarrisonLandingPage.Report:Show();
		GarrisonLandingPage.FollowerList:Hide();
		GarrisonLandingPage.FollowerTab:Hide();
	else
		GarrisonLandingPage.Report:Hide();
		GarrisonLandingPage.FollowerList:Show();
		GarrisonLandingPage.FollowerTab:Show();
	end
end

---------------------------------------------------------------------------------
--- Report Page                                                          ---
---------------------------------------------------------------------------------
function GarrisonLandingPageReport_OnLoad(self)
	HybridScrollFrame_CreateButtons(self.List.listScroll, "GarrisonLandingPageReportMissionTemplate", 0, 0);
	GarrisonLandingPageReportList_Update();
	self:RegisterEvent("GARRISON_LANDINGPAGE_SHIPMENTS");
	self:RegisterEvent("GARRISON_MISSION_LIST_UPDATE");
end

function GarrisonLandingPageReport_OnShow(self)
	-- Shipments
	C_Garrison.RequestLandingPageShipmentInfo();

	if ( not GarrisonLandingPageReport.selectedTab ) then
		-- SetTab flips the tabs, so set them up reversed & call SetTab
		GarrisonLandingPageReport.unselectedTab = GarrisonLandingPageReport.InProgress;
		GarrisonLandingPageReport.selectedTab = GarrisonLandingPageReport.Available;
		GarrisonLandingPageReport_SetTab(GarrisonLandingPageReport.unselectedTab);
	else
		GarrisonLandingPageReportList_UpdateItems()
	end
end

function GarrisonLandingPageReport_OnHide(self)
	GarrisonLandingPageReport:SetScript("OnUpdate", nil);
end

function GarrisonLandingPageReport_OnEvent(self, event)
	if ( event == "GARRISON_LANDINGPAGE_SHIPMENTS" ) then
		GarrisonLandingPageReport_GetShipments(self);
	elseif ( event == "GARRISON_MISSION_LIST_UPDATE" ) then
		GarrisonLandingPageReportList_UpdateItems();
	end
end

function GarrisonLandingPageReport_OnUpdate()
	if( GarrisonLandingPageReport.List.items and #GarrisonLandingPageReport.List.items > 0 )then
		GarrisonLandingPageReport.List.items = C_Garrison.GetLandingPageItems(true); -- don't sort entries again
	else
		GarrisonLandingPageReport.List.items = C_Garrison.GetLandingPageItems();
	end
	
	if( GarrisonLandingPageReportList_Update() ) then
		GarrisonLandingPageReport:SetScript("OnUpdate", nil);
	end
end

---------------------------------------------------------------------------------
--- Report - Shipments                                                        ---
---------------------------------------------------------------------------------
function GarrisonLandingPageReport_GetShipments(self)
	local shipmentIndex = 1;
	local buildings = C_Garrison.GetBuildings();
	for i = 1, #buildings do
		local buildingID = buildings[i].buildingID;
		if ( buildingID ) then
			local name, texture, shipmentsReady, shipmentsTotal, creationTime, duration, timeleftString, itemName, itemIcon, itemQuality, itemID = C_Garrison.GetLandingPageShipmentInfo(buildingID);
			local shipment = self.Shipments[shipmentIndex];
			if ( not shipment ) then
				return;
			end
			if ( name ) then
				SetPortraitToTexture(shipment.Icon, texture);
				shipment.Icon:SetDesaturated(true);
				shipment.Name:SetText(name);
				shipment.Done:Hide();
				shipment.BG:Show();
				shipment.Count:SetText(nil);
				shipment.buildingID = buildingID;
				if (shipmentsTotal) then
					shipment.Count:SetFormattedText(GARRISON_LANDING_SHIPMENT_COUNT, shipmentsReady, shipmentsTotal);
					if ( shipmentsReady == shipmentsTotal ) then
						shipment.Swipe:SetCooldownUNIX(0, 0);
						shipment.Done:Show();
						shipment.BG:Hide();
					else
						shipment.Swipe:SetCooldownUNIX(creationTime, duration);
					end
				end
				shipment:Show();
				shipmentIndex = shipmentIndex + 1;
			else
				shipment:Hide();
			end
		end
	end
	for i = shipmentIndex, #self.Shipments do
		self.Shipments[i]:Hide();
	end
end

function GarrisonLandingPageReportShipment_OnEnter(self)
	local name, texture, shipmentsReady, shipmentsTotal, creationTime, duration, timeleftString, itemName, itemIcon, itemQuality, itemID = C_Garrison.GetLandingPageShipmentInfo(self.buildingID);
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	if (itemName) then
		GameTooltip:SetText(itemName);
	end
	if (shipmentsReady and shipmentsTotal) then
		GameTooltip:AddLine(format(GARRISON_LANDING_COMPLETED, shipmentsReady, shipmentsTotal), 1, 1, 1);
	    
		if (shipmentsReady == shipmentsTotal) then
		    GameTooltip:AddLine(GARRISON_LANDING_RETURN, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
	    elseif (timeleftString) then
		    GameTooltip:AddLine(format(GARRISON_LANDING_NEXT,timeleftString), 1, 1, 1);
	    end
	end
	GameTooltip:Show();
end

---------------------------------------------------------------------------------
--- Report - Mission List                                                     ---
---------------------------------------------------------------------------------
function GarrisonLandingPageReportList_OnShow(self)
	GarrisonMinimap_ClearPulse();
	if ( GarrisonLandingPageReport.selectedTab ) then
		GarrisonLandingPageReportList_UpdateItems()
	end
end

function GarrisonLandingPageReportList_OnHide(self)
	self.missions = nil;
end

function GarrisonLandingPageReportTab_OnClick(self)
	if ( self == GarrisonLandingPageReport.unselectedTab ) then
		PlaySound("igMainMenuOptionCheckBoxOn");
		GarrisonLandingPageReport_SetTab(self);
	end
end

function GarrisonLandingPageReport_SetTab(self)
	local tab = GarrisonLandingPageReport.selectedTab;
	tab:GetNormalTexture():SetAtlas("GarrLanding-TopTabUnselected", true);
	tab:SetNormalFontObject(GameFontNormalMed2);
	tab:SetHighlightFontObject(GameFontNormalMed2);
	tab:GetHighlightTexture():SetAlpha(1);
	tab:SetSize(205,30);
	
	GarrisonLandingPageReport.unselectedTab = tab;
	GarrisonLandingPageReport.selectedTab = self;
	
	self:GetNormalTexture():SetAtlas("GarrLanding-TopTabSelected", true);
	self:SetNormalFontObject(GameFontHighlightMed2);
	self:SetHighlightFontObject(GameFontHighlightMed2);
	self:GetHighlightTexture():SetAlpha(0);
	self:SetSize(205,36);
	
	if (self == GarrisonLandingPageReport.InProgress) then
		GarrisonLandingPageReport.List.listScroll.update = GarrisonLandingPageReportList_Update;
	else
		GarrisonLandingPageReport.List.listScroll.update = GarrisonLandingPageReportList_UpdateAvailable;
	end
	
	GarrisonLandingPageReportList_UpdateItems();
end

function GarrisonLandingPageReportList_UpdateItems()
	GarrisonLandingPageReport.List.items = C_Garrison.GetLandingPageItems();
	GarrisonLandingPageReport.List.AvailableItems = C_Garrison.GetAvailableMissions();
	GarrisonLandingPageReport.InProgress.Text:SetFormattedText(GARRISON_LANDING_IN_PROGRESS, #GarrisonLandingPageReport.List.items);
	GarrisonLandingPageReport.Available.Text:SetFormattedText(GARRISON_LANDING_AVAILABLE, #GarrisonLandingPageReport.List.AvailableItems);
	if ( GarrisonLandingPageReport.selectedTab == GarrisonLandingPageReport.InProgress ) then
		GarrisonLandingPageReportList_Update();
		GarrisonLandingPageReport:SetScript("OnUpdate", GarrisonLandingPageReport_OnUpdate);
	else
		GarrisonLandingPageReportList_UpdateAvailable();
		GarrisonLandingPageReport:SetScript("OnUpdate", nil);
	end
end

function GarrisonLandingPageReportList_UpdateAvailable()
	local items = GarrisonLandingPageReport.List.AvailableItems or {};
	local numItems = #items;
	local scrollFrame = GarrisonLandingPageReport.List.listScroll;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local buttons = scrollFrame.buttons;
	local numButtons = #buttons;

	if (numItems == 0) then
		GarrisonLandingPageReport.List.EmptyMissionText:SetText(GARRISON_EMPTY_MISSION_LIST);
	else
		GarrisonLandingPageReport.List.EmptyMissionText:SetText(nil);
	end
	
	for i = 1, numButtons do
		local button = buttons[i];
		local index = offset + i; -- adjust index
		if ( index <= numItems ) then
			local item = items[index];
			button.id = index;

			button.BG:SetAtlas("GarrLanding-Mission-InProgress", true);
			button.Title:SetText(item.name);
			button.MissionType:SetTextColor(GARRISON_MISSION_TYPE_FONT_COLOR.r, GARRISON_MISSION_TYPE_FONT_COLOR.g, GARRISON_MISSION_TYPE_FONT_COLOR.b);
			button.MissionType:SetText(item.duration);
			button.MissionTypeIcon:Show();
			button.RewardBG:Show();
			
			if ( item.cost > 0 ) then
				button.CostBG:Show();
				button.Cost:SetText(BreakUpLargeNumbers(item.cost));
				button.Cost:Show();
				button.CostLabel:Show();
				button.MaterialIcon:Show();
			else
				button.CostBG:Hide();
				button.Cost:Hide();
				button.CostLabel:Hide();
				button.MaterialIcon:Hide();
			end
			
			local index = 1;
			for id, reward in pairs(item.rewards) do
				local Reward = button.Rewards[index];
				Reward.Quantity:Hide();
				if (reward.itemID) then
					Reward.itemID = reward.itemID;
					local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(reward.itemID);
					Reward.Icon:SetTexture(itemTexture);
				else
					Reward.Icon:SetTexture(reward.icon);
					Reward.title = reward.title
					if (reward.currencyID and reward.quantity) then
						if (reward.currencyID == 0) then
							Reward.tooltip = GetMoneyString(reward.quantity);
						else
							local _, _, currencyTexture = GetCurrencyInfo(reward.currencyID);
							Reward.tooltip = BreakUpLargeNumbers(reward.quantity).." |T"..currencyTexture..":0:0:0:-1|t ";
							Reward.Quantity:SetText(reward.quantity);
							Reward.Quantity:Show();
						end
					else
						Reward.tooltip = reward.tooltip;
					end
				end
				Reward:Show();
				index = index + 1;
			end
			for i = index, #button.Rewards do
				button.Rewards[i]:Hide();
			end
			
			button.Status:Hide();
			button.TimeLeft:Hide();
			button:Show();
		else
			button:Hide();
		end
	end
	
	local totalHeight = numItems * scrollFrame.buttonHeight;
	local displayedHeight = numButtons * scrollFrame.buttonHeight;
	HybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight);
end

function GarrisonLandingPageReportList_Update()
	local items = GarrisonLandingPageReport.List.items or {};
	local numItems = #items;
	local scrollFrame = GarrisonLandingPageReport.List.listScroll;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local buttons = scrollFrame.buttons;
	local numButtons = #buttons;

	local stopUpdate = true;
	
	if (numItems == 0) then
		GarrisonLandingPageReport.List.EmptyMissionText:SetText(GARRISON_EMPTY_IN_PROGRESS_LIST);
	else
		GarrisonLandingPageReport.List.EmptyMissionText:SetText(nil);
	end
	
	for i = 1, numButtons do
		local button = buttons[i];
		local index = offset + i; -- adjust index
		if ( index <= numItems ) then
			local item = items[index];
			button.id = index;
			local bgName;
			if (item.isBuilding) then
				bgName = "GarrLanding-Building-";
				button.Status:SetText(GARRISON_LANDING_STATUS_BUILDING);
			else
				bgName = "GarrLanding-Mission-";
			end
			if (item.isComplete) then
				bgName = bgName.."Complete";
				button.MissionType:SetText(GARRISON_LANDING_BUILDING_COMPLEATE);
				button.MissionType:SetTextColor(YELLOW_FONT_COLOR.r, YELLOW_FONT_COLOR.g, YELLOW_FONT_COLOR.b);
			else
				bgName = bgName.."InProgress";
				button.MissionType:SetTextColor(GARRISON_MISSION_TYPE_FONT_COLOR.r, GARRISON_MISSION_TYPE_FONT_COLOR.g, GARRISON_MISSION_TYPE_FONT_COLOR.b);
				if (item.isBuilding) then
					button.MissionType:SetText(GARRISON_BUILDING_IN_PROGRESS);
				else
					button.MissionType:SetText(item.type);
				end
				button.TimeLeft:SetText(item.timeLeft);
				stopUpdate = false;
			end

			button.MissionTypeIcon:SetShown(not item.isBuilding);
			button.Status:SetShown(not item.isComplete);
			button.TimeLeft:SetShown(not item.isComplete);

			button.BG:SetAtlas(bgName, true);
			button.Title:SetText(item.name);
			button.Cost:Hide();
			button.CostLabel:Hide();
			button.MaterialIcon:Hide();
			button.RewardBG:Hide();
			button.CostBG:Hide();
			for i = 1, #button.Rewards do
				button.Rewards[i]:Hide();
			end
			button:Show();
		else
			button:Hide();
		end
	end
	
	local totalHeight = numItems * scrollFrame.buttonHeight;
	local displayedHeight = numButtons * scrollFrame.buttonHeight;
	HybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight);
	
	return stopUpdate;
end

function GarrisonLandingPageReportMission_OnClick(self, button)
	if ( IsModifiedClick("CHATLINK") ) then
		local items = GarrisonLandingPageReport.List.items or {};
		if GarrisonLandingPageReport.selectedTab == GarrisonLandingPageReport.Available then
			items = GarrisonLandingPageReport.List.AvailableItems or {};
		end
	
		local item = items[self.id];

		-- non mission entries have no link capability
		if not item.missionID then
			return;
		end

		local missionLink = C_Garrison.GetMissionLink(item.missionID);
		if (missionLink) then
			ChatEdit_InsertLink(missionLink);
			return;
		end
	end
end

function GarrisonLandingPageReportMission_OnEnter(self, button)
	GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT");
	local items = GarrisonLandingPageReport.List.items or {};
	if GarrisonLandingPageReport.selectedTab == GarrisonLandingPageReport.Available then
	    items = GarrisonLandingPageReport.List.AvailableItems or {};
	end
	
	local item = items[self.id];

	-- building entries have no tooltip
	if item.isBuilding then
		return;
	end
	
	--mission tooltips
	GameTooltip:SetText(item.name);

	if(GarrisonLandingPageReport.selectedTab == GarrisonLandingPageReport.InProgress) then
		if(item.isComplete) then
			GameTooltip:AddLine(COMPLETE, 1, 1, 1);
		else
			GameTooltip:AddLine(tostring(item.timeLeft), 1, 1, 1);
		end

		GameTooltip:AddLine(" ");

		if item.followers ~= nil then
			GameTooltip:AddLine(GARRISON_FOLLOWERS);
			for i=1, #(item.followers) do
				GameTooltip:AddLine(C_Garrison.GetFollowerName(item.followers[i]), 1, 1, 1);
			end
			GameTooltip:AddLine(" ");
		end

		GameTooltip:AddLine(REWARDS);
		for id, reward in pairs(item.rewards) do
			if (reward.quality) then
				GameTooltip:AddLine(ITEM_QUALITY_COLORS[reward.quality + 1].hex..reward.title..FONT_COLOR_CODE_CLOSE);
			elseif (reward.itemID) then 
				local itemName, _, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(reward.itemID);
				if itemName then
					GameTooltip:AddLine(ITEM_QUALITY_COLORS[itemRarity].hex..itemName..FONT_COLOR_CODE_CLOSE);
				end
			elseif (reward.followerXP) then
				GameTooltip:AddLine(reward.title, 1, 1, 1);
			else
				GameTooltip:AddLine(reward.title, 1, 1, 1);
			end
		end
	else
		GameTooltip:AddLine(string.format(GARRISON_MISSION_TOOLTIP_NUM_REQUIRED_FOLLOWERS, item.numFollowers), 1, 1, 1);
		
		if not C_Garrison.IsOnGarrisonMap() then
			GameTooltip:AddLine(" ");
			GameTooltip:AddLine(GARRISON_MISSION_TOOLTIP_RETURN_TO_START);
		end
	end

	GameTooltip:Show();
end