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
end

function ReactivateAccountDialog_OnEvent(self, event, ...)
	if (event == "TOKEN_BUY_CONFIRM_REQUIRED") then
		local now = time();
		local newTime = now + (30 * 24 * 60 * 60); -- 30 days * 24 hours * 60 minutes * 60 seconds

		local newDate = date("*t", newTime);
		local dialog = GoldReactivateConfirmationDialog;
		dialog.Expires:SetText(ACCOUNT_REACTIVATE_EXPIRATION:format(newDate.month, newDate.day, newDate.year));
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
	end
end

function ReactivateAccountDialog_Open()
	if (AccountReactivationInProgressDialog:IsShown()) then
		return;
	end
	local self = ReactivateAccountDialog;
	if (C_WowTokenGlue.GetTokenCount() > 0) then
		self.redeem = true;
		self.Title:SetText(ACCOUNT_REACTIVATE_TOKEN_TITLE);
		self.Description:SetText(ACCOUNT_REACTIVATE_TOKEN_DESC);
		self.Accept:SetText(ACCOUNT_REACTIVATE_TOKEN_ACCEPT);
		self:Show();
	elseif (C_WowTokenGlue.CanVeteranBuy()) then
		self.redeem = false;
		self.Title:SetText(ACCOUNT_REACTIVATE_GOLD_TITLE);
		self.Description:SetText(ACCOUNT_REACTIVATE_GOLD_DESC);
		self.Accept:SetText(ACCOUNT_REACTIVATE_ACCEPT:format(GetMoneyString(C_WowTokenPublic.GetCurrentMarketPrice(), true)));
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