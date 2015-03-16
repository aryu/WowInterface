function AccountReactivate_DisplaySubscriptionRequest()
	ReactivateAccountDialog:Hide();
	AccountReactivatedDialog:Hide();
	GoldReactivateConfirmationDialog:Hide();
	TokenReactivateConfirmationDialog:Hide();
	
	SubscriptionRequestDialog:Show();
end

function AccountReactivate_ReactivateNow()
	PlaySound("gsTitleOptionOK");
	
	-- open web page
	LoadURLIndex(2);
end

function AccountReactivate_Cancel()
	SubscriptionRequestDialog:Hide();
	PlaySound("gsTitleOptionExit");
end

function AccountReactivate_CloseDialogs()
	ReactivateAccountDialog:Hide();
	AccountReactivationInProgressDialog:Hide();
	GoldReactivateConfirmationDialog:Hide();
	TokenReactivateConfirmationDialog:Hide();
	SubscriptionRequestDialog:Hide();
end

function ReactivateAccountDialog_OnLoad(self)
	self:SetHeight( 60 + self.Description:GetHeight() + 64 );
	self:RegisterEvent("TOKEN_BUY_CONFIRM_REQUIRED");
	self:RegisterEvent("TOKEN_REDEEM_CONFIRM_REQUIRED");
	self:RegisterEvent("TOKEN_STATUS_CHANGED");
	self:RegisterEvent("TOKEN_REDEEM_RESULT");
end

function GetTimeLeftMinuteString(minutes)
	local weeks = 7 * 24 * 60; -- 7 days, 24 hours, 60 minutes
	local days = 24 * 60; -- 24 hours, 60 minutes
	local hours = 60; -- 60 minutes

	local str = "";
	if (math.floor(minutes / weeks) > 0) then
		local wks = math.floor(minutes / weeks);

		minutes = minutes - (wks * weeks);
		str = str .. wks .. " " .. WEEKS_ABBR;
	end

	if (math.floor(minutes / days) > 0) then
		local dys = math.floor(minutes / days);

		minutes = minutes - (dys * days);
		str = str .. " " .. dys .. " " .. DAYS_ABBR;
	end

	if (math.floor(minutes / hours) > 0) then
		local hrs = math.floor(minutes / hours);

		minutes = minutes - (hrs * hours);
		str = str .. " " .. hrs .. " " .. HOURS_ABBR;
	end

	if (minutes > 0) then
		str = str .. " " .. minutes .. " " .. MINUTES_ABBR;
	end

	return str;
end

function ReactivateAccountDialog_OnEvent(self, event, ...)
	if (event == "TOKEN_BUY_CONFIRM_REQUIRED") then
		local dialog = GoldReactivateConfirmationDialog;
		local redeemIndex = select(3, C_WowTokenPublic.GetCommerceSystemStatus());
		
		if (redeemIndex == LE_CONSUMABLE_TOKEN_REDEEM_FOR_SUB_AMOUNT_30_DAYS) then
			local now = time();
			local newTime = now + (30 * 24 * 60 * 60); -- 30 days * 24 hours * 60 minutes * 60 seconds

			local newDate = date("*t", newTime);
			dialog.Expires:SetText(ACCOUNT_REACTIVATE_EXPIRATION:format(newDate.month, newDate.day, newDate.year));
		else
			dialog.Expires:SetText(ACCOUNT_REACTIVATE_EXPIRATION_MINUTES:format(GetTimeLeftMinuteString(2700)));
		end
		dialog.Price:SetText(ACCOUNT_REACTIVATE_GOLD_PRICE:format(GetMoneyString(C_WowTokenSecure.GetGuaranteedPrice(), true)));
		dialog.Remaining:SetText(ACCOUNT_REACTIVATE_GOLD_REMAINING:format(GetMoneyString(C_WowTokenGlue.GetAccountRemainingGoldAmount(), true)));
		dialog.remainingDialogTime = C_WowTokenSecure.GetPriceLockDuration();
		dialog.CautionText:Hide();
		dialog.heightSet = false;
		if (not dialog.ticker) then
			dialog.ticker = C_Timer.NewTicker(1, function()
				if (dialog.remainingDialogTime == 0) then
					dialog.ticker:Cancel();
					dialog.ticker = nil;
					dialog:Hide();
					self:Show();
				elseif (dialog.remainingDialogTime <= 20) then
					dialog.CautionText:SetText(TOKEN_PRICE_LOCK_EXPIRE:format(dialog.remainingDialogTime));
					dialog.CautionText:Show();
					if (not dialog.heightSet) then
						dialog:SetHeight(dialog:GetHeight() + dialog.CautionText:GetHeight() + 20);
						dialog.heightSet = true;
					end
				else
					dialog.CautionText:Hide();
				end
				dialog.remainingDialogTime = dialog.remainingDialogTime - 1;
			end);
		end
		dialog:Show();
	elseif (event == "TOKEN_REDEEM_CONFIRM_REQUIRED") then
		local now = time();
		local newTime = now + (30 * 24 * 60 * 60); -- 30 days * 24 hours * 60 minutes * 60 seconds

		local newDate = date("*t", newTime);
		local dialog = TokenReactivateConfirmationDialog;
		dialog.Expires:SetText(ACCOUNT_REACTIVATE_EXPIRATION:format(newDate.month, newDate.day, newDate.year));
		dialog:Show();
	elseif (event == "TOKEN_STATUS_CHANGED") then
		if (self:IsShown()) then
			ReactivateAccountDialog_Open();
		end
	elseif (event == "TOKEN_REDEEM_RESULT") then
		AccountReactivationInProgressDialog:Hide();
	end
end

function ReactivateAccountDialog_Open()
	if (AccountReactivationInProgressDialog:IsShown()) then
		return;
	end
	local self = ReactivateAccountDialog;
	local redeemIndex = select(3, C_WowTokenPublic.GetCommerceSystemStatus());
	if (C_WowTokenGlue.GetTokenCount() > 0) then
		self.redeem = true;
		self.Title:SetText(ACCOUNT_REACTIVATE_TOKEN_TITLE);
		if (redeemIndex == LE_CONSUMABLE_TOKEN_REDEEM_FOR_SUB_AMOUNT_30_DAYS) then
			self.Description:SetText(ACCOUNT_REACTIVATE_TOKEN_DESC);
		elseif (redeemIndex == LE_CONSUMABLE_TOKEN_REDEEM_FOR_SUB_AMOUNT_2700_MINUTES) then
			self.Description:SetText(ACCOUNT_REACTIVATE_TOKEN_DESC_MINUTES);
		end
		self.Accept:SetText(ACCOUNT_REACTIVATE_TOKEN_ACCEPT);
		self:Show();
	elseif (C_WowTokenGlue.CanVeteranBuy()) then
		self.redeem = false;
		self.Title:SetText(ACCOUNT_REACTIVATE_GOLD_TITLE);
		if (redeemIndex == LE_CONSUMABLE_TOKEN_REDEEM_FOR_SUB_AMOUNT_30_DAYS) then
			self.Description:SetText(ACCOUNT_REACTIVATE_GOLD_DESC);
			self.Accept:SetText(ACCOUNT_REACTIVATE_ACCEPT:format(GetMoneyString(C_WowTokenPublic.GetCurrentMarketPrice(), true)));
		elseif (redeemIndex == LE_CONSUMABLE_TOKEN_REDEEM_FOR_SUB_AMOUNT_2700_MINUTES) then
			self.Description:SetText(ACCOUNT_REACTIVATE_GOLD_DESC_MINUTES);
			self.Accept:SetText(ACCOUNT_REACTIVATE_ACCEPT_MINUTES:format(GetMoneyString(C_WowTokenPublic.GetCurrentMarketPrice(), true)));
		end
		self:Show();
	else
		self:Hide();
	end
end

function ReactivateAccountDialog_OnAccept(self)
	PlaySound("gsTitleOptionOK");
	if (self:GetParent().redeem) then
		C_WowTokenSecure.RedeemToken();
	else
		C_WowTokenPublic.BuyToken();
	end
	self:GetParent():Hide();
end

function SubscriptionRequestDialog_Open()
	AccountReactivate_CloseDialogs();
	SubscriptionRequestDialog:Show();
end