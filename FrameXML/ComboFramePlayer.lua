ComboPointPowerBar = {};

function ComboPointPowerBar:OnLoad()
	if (GetCVar("comboPointLocation") ~= "2") then
		self:Hide();
		return;
	end
	
	self.class = "ROGUE";
	self.powerTokens = {"COMBO_POINTS"};
	
	for i = 1, #self.ComboPoints do
		self.ComboPoints[i].on = false;
	end
	self.maxUsablePoints = 5;
	
	self:SetFrameLevel(self:GetParent():GetFrameLevel() + 2);
	ClassPowerBar.OnLoad(self);
end

function ComboPointPowerBar:OnEvent(event, arg1, arg2)
	if (event == "UNIT_DISPLAYPOWER" or event == "PLAYER_ENTERING_WORLD" ) then
		self:SetupDruid();
	elseif (event == "UNIT_MAXPOWER") then
		self:UpdateMaxPower();
	else
		ClassPowerBar.OnEvent(self, event, arg1, arg2);
	end
end


function ComboPointPowerBar:Setup()
	local showBar = ClassPowerBar.Setup(self);
	if (showBar) then
		self:RegisterUnitEvent("UNIT_MAXPOWER", "player");
		self:SetPoint("TOP", self:GetParent(), "BOTTOM", 50, 38);
		self:UpdateMaxPower();
	else
		self:SetupDruid();
	end
end

function ComboPointPowerBar:SetupDruid()
	local _, myclass = UnitClass("player");
	if (myclass ~= "DRUID") then
		return;
	end
	self:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	local powerType, powerToken = UnitPowerType("player");
	local showBar = false;
	if (powerType == SPELL_POWER_ENERGY) then
		showBar = true;
		self:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player");
		self:RegisterUnitEvent("UNIT_MAXPOWER", "player");
	else
		self:UnregisterEvent("UNIT_POWER_FREQUENT");
		self:UnregisterEvent("UNIT_MAXPOWER");
	end
	if (showBar) then
		self:SetPoint("TOP", self:GetParent(), "BOTTOM", 50, 18);
		self:Show();
		self:UpdateMaxPower();
		self:UpdatePower();
	else
		self:Hide();
	end
end

function ComboPointPowerBar:UpdateMaxPower()
	local maxComboPoints = UnitPowerMax("player", SPELL_POWER_COMBO_POINTS);
	
	self.ComboPoints[6]:SetShown(maxComboPoints == 6);
	for i = 1, #self.ComboBonus do
		self.ComboBonus[i]:SetShown(maxComboPoints == 8);
	end
	
	if (maxComboPoints == 5 or maxComboPoints == 8) then
		self.maxUsablePoints = 5;
		for i = 1, 5 do
			self.ComboPoints[i]:SetSize(20, 21);
			self.ComboPoints[i].PointOff:SetSize(20, 21);
			self.ComboPoints[i].Point:SetSize(20, 21);
			if (i ~= 1) then
				self.ComboPoints[i]:SetPoint("LEFT", self.ComboPoints[i-1], "RIGHT", 1, 0);
			end
		end
	elseif (maxComboPoints == 6) then
		self.maxUsablePoints = 6;
		for i = 1, 6 do
			self.ComboPoints[i]:SetSize(18, 19);
			self.ComboPoints[i].PointOff:SetSize(18, 19);
			self.ComboPoints[i].Point:SetSize(18, 19);
			if (i ~= 1) then
				self.ComboPoints[i]:SetPoint("LEFT", self.ComboPoints[i-1], "RIGHT", -1, 0);
			end
		end
	end
end

function ComboPointPowerBar:AnimIn(frame)
	if (not frame.on) then
		frame.on = true;
		frame.AnimIn:Play();
	end
end

function ComboPointPowerBar:AnimOut(frame)
	if (frame.on) then
		frame.on = false;
		frame.AnimOut:Play();
	end
end


function ComboPointPowerBar:UpdatePower()
	if ( self.delayedUpdate ) then
		return;
	end
	
	local comboPoints = UnitPower("player", SPELL_POWER_COMBO_POINTS);
	local maxComboPoints = UnitPowerMax("player", SPELL_POWER_COMBO_POINTS);
	
	-- If we had more than self.maxUsablePoints and then used a finishing move, fade out
	-- the top row of points and then move the remaining points from the bottom up to the top
	if ( self.lastPower and self.lastPower > self.maxUsablePoints and comboPoints == self.lastPower - self.maxUsablePoints ) then
		for i = 1, self.maxUsablePoints do
			self:AnimOut(self.ComboPoints[i]);
		end
		self.delayedUpdate = true;
		self.lastPower = nil;
		C_Timer.After(0.45, function()
			self.delayedUpdate = false;
			self:UpdatePower();
		end);
	else
		for i = 1, min(comboPoints, self.maxUsablePoints) do
			if (not self.ComboPoints[i].on) then
				self:AnimIn(self.ComboPoints[i]);
			end
		end
		for i = comboPoints + 1, self.maxUsablePoints do
			if (self.ComboPoints[i].on) then
				self:AnimOut(self.ComboPoints[i]);
			end
		end
		
		if (maxComboPoints == 8) then
			for i = 6, comboPoints do
				self:AnimIn(self.ComboBonus[i-5]);
			end
			for i = max(comboPoints + 1, 6), 8 do
				self:AnimOut(self.ComboBonus[i-5]);
			end
		end
		
		self.lastPower = comboPoints;
	end
end
