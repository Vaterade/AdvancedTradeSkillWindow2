-- pfUI theme for Advanced Trade Skill Window 2. Does nothing unless pfUI is loaded.
-- Must stay last in the .toc: it skins frames created by both XML files.
--
-- pfUI runs the skin in its own environment (StripTextures, CreateBackdrop, ...), which is
-- why every helper is defined inside the function. Globals have to be written through _G.
-- pfUI requires ClassicAPI on this client, so SetColorTexture is available here.

if not pfUI then
	return
end

pfUI:RegisterSkin('AdvancedTradeSkillWindow2', function()
	-- RegisterSkin only checks this during pfUI's own startup, which is over by the time we load
	if pfUI_config.disabled and pfUI_config.disabled['skin_AdvancedTradeSkillWindow2'] == '1' then
		return
	end

	local Pixel = GetPerfectPixel()
	local BorderR, BorderG, BorderB, BorderA = GetStringColor(pfUI_config.appearance.border.color)
	local TextColor = 0.9

	-- The window frames are larger than their visible art. These are their XML HitRectInsets.
	local function SkinWindow(Frame, Left, Right, Top, Bottom)
		StripTextures(Frame)
		CreateBackdrop(Frame)

		Frame.backdrop:ClearAllPoints()
		Frame.backdrop:SetPoint('TOPLEFT', Frame, 'TOPLEFT', Left, -Top)
		Frame.backdrop:SetPoint('BOTTOMRIGHT', Frame, 'BOTTOMRIGHT', -Right, Bottom)

		-- CreateBackdrop widens the hit rect, which would make the empty margins catch clicks
		Frame:SetHitRectInsets(Left, Right, Top, Bottom)

		CreateBackdropShadow(Frame)
	end

	local function SkinDialog(Frame)
		CreateBackdrop(Frame, nil, true)
		CreateBackdropShadow(Frame)
	end

	-- A dark panel with a thin border, in pixels from the frame's top left corner. Built from
	-- textures because a child frame would draw over the frame's own text.
	local function AddPane(Frame, Left, Top, Right, Bottom, NoFill)
		local Fill = Frame:CreateTexture(nil, 'BACKGROUND')

		Fill:SetPoint('TOPLEFT', Frame, 'TOPLEFT', Left, -Top)
		Fill:SetPoint('BOTTOMRIGHT', Frame, 'TOPLEFT', Right, -Bottom)

		if NoFill then
			Fill:SetColorTexture(0, 0, 0, 0)
		else
			Fill:SetColorTexture(0, 0, 0, 0.5)
		end

		local Edges = {
			{'TOPLEFT', 'TOPRIGHT', 'Height'},
			{'BOTTOMLEFT', 'BOTTOMRIGHT', 'Height'},
			{'TOPLEFT', 'BOTTOMLEFT', 'Width'},
			{'TOPRIGHT', 'BOTTOMRIGHT', 'Width'},
		}

		for _, Edge in ipairs(Edges) do
			local Line = Frame:CreateTexture(nil, 'BORDER')

			Line:SetColorTexture(BorderR, BorderG, BorderB, BorderA)
			Line:SetPoint(Edge[1], Fill, Edge[1])
			Line:SetPoint(Edge[2], Fill, Edge[2])

			if Edge[3] == 'Height' then
				Line:SetHeight(Pixel)
			else
				Line:SetWidth(Pixel)
			end
		end
	end

	-- The addon colors a separate glow texture by item quality. Use the icon's border instead.
	local function QualityAsBorder(Button, Quality)
		local function Reset()
			if Button.backdrop then
				Button.backdrop:SetBackdropBorderColor(BorderR, BorderG, BorderB, BorderA)
			end
		end

		Quality:SetTexture(nil)

		Quality.Hide = Reset
		Quality.SetVertexColor = function(Self, R, G, B)
			if not (R and G and B) or (R == 1 and G == 1 and B == 1) then
				Reset()
			elseif Button.backdrop then
				Button.backdrop:SetBackdropBorderColor(R, G, B, 1)
			end
		end
	end

	local function SkinIcon(Button, Texture, Quality)
		CreateBackdrop(Button)

		if Texture then
			Texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		end

		if Quality then
			QualityAsBorder(Button, Quality)
		end
	end

	local function SkinEditBox(Box)
		StripTextures(Box)
		CreateBackdrop(Box)
		Box:SetTextInsets(4, 4, 0, 0)
	end

	local function SkinScrollFrame(Frame)
		StripTextures(Frame)
		SkinScrollbar(_G[Frame:GetName() .. 'ScrollBar'])
	end

	local function SkinBar(Bar, Texture)
		Texture:SetTexture(pfUI.media['img:bar'])
		CreateBackdrop(Bar, nil, true)
	end

	-- Square, cropped profession icon in place of the round portrait
	local function MoveIcon(Frame, Icon)
		Icon:SetDrawLayer('ARTWORK')
		Icon:ClearAllPoints()
		Icon:SetPoint('TOPLEFT', Frame, 'TOPLEFT', 18, -16)
		Icon:SetWidth(48)
		Icon:SetHeight(48)

		AddPane(Frame, 17, 15, 67, 65, true)
	end

	local function SetProfessionIcon(Icon)
		local Name = ATSW_Profession[ATSW_realm][ATSW_player]

		Icon:SetTexture(Name and ATSW_GetProfessionTexture(Name))
		Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end

	-- The addon tints the selected row by difficulty, too strongly for white text on a dark window
	local function SoftenHighlight(Texture)
		local SetVertexColor = Texture.SetVertexColor

		Texture.SetVertexColor = function(Self, R, G, B, A)
			SetVertexColor(Self, R, G, B, (A or 1) * 0.45)
		end
	end

	local function ApplyFont(Frame)
		for _, Region in ipairs({Frame:GetRegions()}) do
			if Region.GetFont then
				local _, Size, Flags = Region:GetFont()

				if Size then
					Region:SetFont(pfUI.font_default, Size, Flags)
				end
			end
		end

		for _, Child in ipairs({Frame:GetChildren()}) do
			ApplyFont(Child)
		end
	end

	-- Main window

	SkinWindow(ATSWFrame, 12, 35, 12, 12)
	MoveIcon(ATSWFrame, ATSWFramePortrait)

	AddPane(ATSWFrame, 18, 73, 345, 494)	-- Recipe list
	AddPane(ATSWFrame, 350, 73, 728, 343)	-- Recipe details
	AddPane(ATSWFrame, 350, 346, 728, 466)	-- Tasks

	ATSWFrameTitleText:SetTextColor(1, 1, 1, 1)

	-- These were black, for the parchment
	ATSWRecipeName:SetTextColor(TextColor, TextColor, TextColor)
	ATSWCraftDescription:SetTextColor(TextColor, TextColor, TextColor)
	ATSWCostText:SetTextColor(TextColor, TextColor, TextColor)

	SkinCloseButton(ATSWFrameCloseButton, ATSWFrame, -40, -17)

	ATSWRankFrameBackground:Hide()
	SkinBar(ATSWRankFrame, ATSWRankFrameBar)
	ATSWRankFrame:SetStatusBarColor(0.25, 0.4, 0.7, 1)

	ATSWProgressBarBorder:SetBackdrop(nil)
	SkinBar(ATSWProgressBar, ATSWProgressBarTexture)

	SkinCheckbox(ATSWCategorySortCheckbox)
	SkinCheckbox(ATSWDifficultySortCheckbox)
	SkinCheckbox(ATSWNameSortCheckbox)
	SkinCheckbox(ATSWCustomSortCheckbox)
	SkinCheckbox(ATSWAttributesButton)

	SkinEditBox(ATSWSearchBox)
	SkinEditBox(ATSWAmountBox)

	-- The search box's backdrop would cover these, since they belong to the window. The icon
	-- was stripped with the window, and has to be restored after the box's own strip above.
	ATSWSearchLabel:SetParent(ATSWSearchBox)
	ATSWSearchIcon:SetParent(ATSWSearchBox)
	ATSWSearchIcon:SetTexture('Interface\\AddOns\\AdvancedTradeSkillWindow2\\Textures\\Search')

	ATSWAmountBox:SetJustifyH('CENTER')

	-- useSmall: otherwise pfUI opens each menu once to measure it, before any profession is known
	SkinDropDown(ATSWSubClassDropDown, nil, nil, nil, true)
	SkinDropDown(ATSWInvSlotDropDown, nil, nil, nil, true)

	SoftenHighlight(ATSWHighlightTexture)

	SkinScrollFrame(ATSWListScrollFrame)
	SkinScrollFrame(ATSWTaskScrollFrame)
	StripTextures(ATSWTaskScrollFrameBackground)

	SkinArrowButton(ATSWDecrementButton, 'left', 18)
	SkinArrowButton(ATSWIncrementButton, 'right', 18)
	SkinArrowButton(ATSWPreviousItemButton, 'left', 18)

	SkinIcon(ATSWRecipeIcon, ATSWRecipeIconNormalTexture, ATSWRecipeIconQualityTexture)

	SkinButton(ATSWCustomEditorButton)
	SkinButton(ATSWSearchHelpButton)
	SkinButton(ATSWSearchBoxClear)
	SkinButton(ATSWReagentsButton)
	SkinButton(ATSWCreateButton)
	SkinButton(ATSWTaskButton)
	SkinButton(ATSWProgressBarStop)

	-- ATSW_PushCreateButton restores the stock highlight after every craft
	ATSWCreateButton.SetHighlightTexture = function() end

	for T = 1, ATSW_MAX_TRADESKILL_TABS do
		local Tab = _G['ATSWFrameTab' .. T]

		StripTextures(Tab)
		CreateBackdrop(Tab)

		if Tab:GetHighlightTexture() then
			Tab:GetHighlightTexture():SetColorTexture(1, 1, 1, 0.2)
		end

		if Tab:GetCheckedTexture() then
			Tab:GetCheckedTexture():SetColorTexture(1, 0.82, 0, 0.3)
		end
	end

	-- Reagents window

	SkinWindow(ATSWReagentsFrame, 11, 35, 12, 76)
	SkinCloseButton(ATSWReagentsFrameCloseButton, ATSWReagentsFrame, -41, -18)

	-- Auction shopping list

	SkinWindow(ATSWShoppingListFrame, 12, 35, 0, 58)
	SkinScrollFrame(ATSWSLScrollFrame)

	-- Buy button on the merchant window

	SkinButton(ATSWBuyButton)

	-- Options window

	SkinDialog(ATSWConfigFrame)
	ATSWOptionsMenuHeader:Hide()
	SkinButton(ATSWConfigFrameOKButton)

	StripTextures(ATSWOptionsAddonsCompat)

	CreateBackdrop(ATSWOptionsTotalDisplayed, nil, true)
	CreateBackdrop(ATSWOptionsTotalInclude, nil, true)
	CreateBackdrop(ATSWOptionsAddonsCompat, nil, true)
	CreateBackdrop(ATSWOptionsAddonsCompatTable, nil, true)

	SkinCheckbox(ATSWOFUnifiedButton)
	SkinCheckbox(ATSWOFSeparateButton)
	SkinCheckbox(ATSWOFIncludeBankButton)
	SkinCheckbox(ATSWOFIncludeAltsButton)
	SkinCheckbox(ATSWOFIncludeMerchantsButton)
	SkinCheckbox(ATSWOFAutoBuyButton)
	SkinCheckbox(ATSWOFTooltipButton)
	SkinCheckbox(ATSWOFShoppingListButton)

	-- Search help window

	SkinDialog(ATSWSearchHelpFrame)
	ATSWHelpMenuHeader:Hide()
	SkinButton(ATSWSearchHelpFrameOKButton)

	ATSWHelpTitle:ClearAllPoints()
	ATSWHelpTitle:SetPoint('TOP', ATSWSearchHelpFrame, 'TOP', 0, -10)

	-- Custom sorting window

	SkinWindow(ATSWCSFrame, 12, 35, 12, 12)
	MoveIcon(ATSWCSFrame, ATSWCSFramePortrait)

	AddPane(ATSWCSFrame, 18, 73, 345, 494)		-- Recipes
	AddPane(ATSWCSFrame, 348, 73, 728, 466)	-- Categories

	ATSWCSFrameTitleText:SetTextColor(1, 1, 1, 1)

	SkinCloseButton(ATSWCSFrameCloseButton, ATSWCSFrame, -40, -17)

	StripTextures(ATSWCSRecipesListScrollFrameBackground)
	StripTextures(ATSWCSCategoriesListScrollFrameBackground)
	SkinScrollFrame(ATSWCSRecipesListScrollFrame)
	SkinScrollFrame(ATSWCSCategoriesListScrollFrame)

	SoftenHighlight(ATSWCSHighlightTexture)

	SkinEditBox(ATSWCSNewCategoryBox)

	SkinButton(ATSWCSRenameButton)
	SkinButton(ATSWCSAddButton)
	SkinButton(ATSWCSFrameRename)
	SkinCloseButton(ATSWCSFrameDelete)
	SkinArrowButton(ATSWCSFrameMoveDown, 'down')
	SkinArrowButton(ATSWCSFrameMoveUp, 'up')

	-- Recipe tooltip

	CreateBackdrop(ATSWRecipeTooltip, nil, true)

	-- Fonts. ATSW_UpdateRecipes and the recipe tooltip read this one each time they draw.

	_G.ATSW_FontFile = pfUI.font_default

	ApplyFont(ATSWFrame)
	ApplyFont(ATSWCSFrame)
	ApplyFont(ATSWConfigFrame)
	ApplyFont(ATSWBuyNecessaryFrame)

	-- Things the addon changes or creates later

	hooksecurefunc('ATSW_UpdateBackground', function()
		ATSWBackground:SetTexture(nil)
	end)

	hooksecurefunc('ATSW_UpdateCaption', function()
		SetProfessionIcon(ATSWFramePortrait)
	end)

	hooksecurefunc('ATSWCS_OnShow', function()
		SetProfessionIcon(ATSWCSFramePortrait)
	end)

	hooksecurefunc('ATSWReagentsButton_OnClick', function()
		ApplyFont(ATSWReagentsFrame)
	end)

	hooksecurefunc('ATSW_ShowAuctionShoppingList', function()
		ApplyFont(ATSWShoppingListFrame)
	end)

	-- ATSW_Show creates the list buttons on the first open, then sets up the side tabs. Don't
	-- hook ATSW_CreateListButtons: ATSW_Show still needs the delete buttons' stock textures
	-- right after it returns.
	local ListsSkinned = false

	hooksecurefunc('ATSW_ConfigureSkillButtons', function()
		for T = 1, ATSW_MAX_TRADESKILL_TABS do
			local Normal = _G['ATSWFrameTab' .. T]:GetNormalTexture()

			if Normal then
				Normal:SetTexCoord(0.08, 0.92, 0.08, 0.92)
			end
		end

		if ListsSkinned or not ATSWTask1 then
			return
		end

		ListsSkinned = true

		for R = 1, MAX_TRADE_SKILL_REAGENTS do
			local Name = 'ATSWReagent' .. R

			SkinIcon(_G[Name], _G[Name .. 'Texture'], _G[Name .. 'QualityTexture'])

			-- The addon sets this to black every time it draws a reagent
			local Title = _G[Name .. 'Title']
			local SetTextColor = Title.SetTextColor

			Title.SetTextColor = function(Self, R, G, B, A)
				if R == 0 and G == 0 and B == 0 then
					R, G, B = TextColor, TextColor, TextColor
				end

				SetTextColor(Self, R, G, B, A)
			end
		end

		for T = 1, ATSW_TOOLS_DISPLAYED do
			local Tool = _G['ATSWTool' .. T]
			local Text = _G['ATSWTool' .. T .. 'Text']
			local SetTextColor = Text.SetTextColor

			-- The addon draws a tool you have in black, and one you don't in red
			Text.SetTextColor = function(Self, R, G, B, A)
				if R == 0 and G == 0 and B == 0 then
					R, G, B = TextColor, TextColor, TextColor
				end

				SetTextColor(Self, R, G, B, A)
			end

			Tool:SetTextColor(TextColor, TextColor, TextColor)
			Tool:SetDisabledTextColor(TextColor, TextColor, TextColor)
		end

		for T = 1, ATSW_TASKS_DISPLAYED do
			SkinCloseButton(_G['ATSWTask' .. T .. 'DeleteButton'])
		end

		ApplyFont(ATSWFrame)
	end)
end)
