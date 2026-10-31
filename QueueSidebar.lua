-- The task queue as a sidebar on the game's stock profession windows.
--
-- A step in moving off ATSW's own window. Open it with /atsw disable, which switches a profession to
-- the stock window. The Reagents button stays disabled until that window moves across too.

ATSWQueue = {}

local ROWS 			= 20
local ROW_HEIGHT 	= 16

local Sidebar, AddButton, ToggleButton, Count, Empty, ScrollFrame
local ReagentsButton, StartButton
local Rows = {}
local Deletes = {}
local CurrentProfession
local SinceSelectionCheck = 0

local function Tasks()
	local Characters = ATSW_Tasks[ATSW_realm]
	local Professions = Characters and Characters[ATSW_player]

	return Professions and CurrentProfession and Professions[CurrentProfession] or {}
end

-- pfUI gives the window a backdrop to line up with exactly. The stock window's frame is much larger
-- than its art, so there the Exit button is the reliable guide to where the art ends. The
-- Gromissingcrafts panel opens in the same spot, so the sidebar moves out to the right of it.
local function PlaceSidebar()
	local Panel = GromissingcraftsWindow
	local Beside = Panel and Panel:IsVisible() and Panel or nil

	if Sidebar.Placed and Beside == Sidebar.Beside then
		return
	end

	local Frame = Sidebar:GetParent()
	local Exit = Sidebar.Exit

	Sidebar.Placed = true
	Sidebar.Beside = Beside
	Sidebar:ClearAllPoints()

	if Frame.backdrop then
		Sidebar:SetPoint('TOP', Frame.backdrop, 'TOP', 0, 0)
		Sidebar:SetPoint('BOTTOM', Frame.backdrop, 'BOTTOM', 0, 0)
	else
		Sidebar:SetPoint('TOP', Frame, 'TOP', 0, -10)
		Sidebar:SetPoint('BOTTOM', Exit, 'BOTTOM', 0, 0)
	end

	if Beside then
		Sidebar:SetPoint('LEFT', Beside, 'RIGHT', 2, 0)
	elseif Frame.backdrop then
		Sidebar:SetPoint('LEFT', Frame.backdrop, 'RIGHT', 2, 0)
	else
		Sidebar:SetPoint('LEFT', Exit, 'RIGHT', 4, 0)
	end
end

local function BuildButton(Name, Text)
	local Button = CreateFrame('Button', Name, Sidebar, 'UIPanelButtonTemplate')

	Button:SetHeight(22)
	Button:SetText(Text)
	Button:Disable()

	return Button
end

local function Build()
	Sidebar = CreateFrame('Frame', 'ATSWQueueFrame', UIParent)
	Sidebar:SetWidth(230)
	Sidebar:EnableMouse(true)
	Sidebar:Hide()
	Sidebar:SetBackdrop({
		bgFile = 'Interface\\Tooltips\\UI-Tooltip-Background',
		edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
		tile = true, tileSize = 16, edgeSize = 16,
		insets = {left = 4, right = 4, top = 4, bottom = 4}
	})
	Sidebar:SetBackdropColor(0.09, 0.09, 0.18, 1)
	Sidebar:SetScript('OnUpdate', PlaceSidebar)

	local Title = Sidebar:CreateFontString('ATSWQueueTitle', 'ARTWORK', 'GameFontNormal')
	Title:SetPoint('TOP', Sidebar, 'TOP', 0, -10)
	Title:SetText(ATSW_QUEUE_TITLE)

	for R = 1, ROWS do
		local Row = Sidebar:CreateFontString('ATSWQueueRow' .. R, 'ARTWORK', 'GameFontHighlightSmall')

		Row:SetWidth(166)
		Row:SetHeight(ROW_HEIGHT)
		Row:SetJustifyH('LEFT')
		Row:SetPoint('TOPLEFT', Sidebar, 'TOPLEFT', 12, -32 - (R - 1) * ROW_HEIGHT)

		Rows[R] = Row

		local Delete = CreateFrame('Button', 'ATSWQueueDelete' .. R, Sidebar, 'UIPanelCloseButton')

		Delete:SetWidth(16)
		Delete:SetHeight(16)
		Delete:SetPoint('LEFT', Row, 'RIGHT', 2, 0)
		Delete:SetScript('OnClick', function()
			ATSW_QueueDelete(this.TaskName)
		end)
		Delete:Hide()

		Deletes[R] = Delete
	end

	ScrollFrame = CreateFrame('ScrollFrame', 'ATSWQueueScrollFrame', Sidebar, 'FauxScrollFrameTemplate')
	ScrollFrame:SetPoint('TOPLEFT', Rows[1], 'TOPLEFT', 0, 0)
	ScrollFrame:SetPoint('BOTTOMRIGHT', Sidebar, 'BOTTOMRIGHT', -30, 38)
	ScrollFrame:SetScript('OnVerticalScroll', function()
		FauxScrollFrame_OnVerticalScroll(ROW_HEIGHT, ATSWQueue.Update)
	end)

	Empty = Sidebar:CreateFontString('ATSWQueueEmpty', 'ARTWORK', 'GameFontDisableSmall')
	Empty:SetPoint('TOPLEFT', Rows[1], 'TOPLEFT')
	Empty:SetText(ATSW_QUEUE_EMPTY)

	ReagentsButton = BuildButton('ATSWQueueReagentsButton', ATSW_REAGENTBUTTON)
	ReagentsButton:SetWidth(100)
	ReagentsButton:SetPoint('BOTTOMLEFT', Sidebar, 'BOTTOMLEFT', 10, 8)

	StartButton = BuildButton('ATSWQueueStartButton', ATSW_QUEUE_START)
	StartButton:SetWidth(100)
	StartButton:SetPoint('BOTTOMRIGHT', Sidebar, 'BOTTOMRIGHT', -10, 8)
	StartButton:SetScript('OnClick', function()
		if ATSW_QueueIsCrafting() then
			ATSW_QueueStop()
		elseif not ATSW_QueueStart() then
			DEFAULT_CHAT_FRAME:AddMessage(ATSW_QUEUE_NOTHING)
		end
	end)

	-- A text button for the action, and an icon with a count for the window it toggles
	AddButton = CreateFrame('Button', 'ATSWQueueAddButton', UIParent, 'UIPanelButtonTemplate')
	AddButton:SetWidth(110)
	AddButton:SetHeight(24)
	AddButton:SetText(ATSW_QUEUE_ADD)
	AddButton:Hide()
	AddButton:SetScript('OnClick', function()
		ATSWQueue.AddSelected()
	end)

	ToggleButton = CreateFrame('Button', 'ATSWQueueToggleButton', UIParent)
	ToggleButton:SetWidth(26)
	ToggleButton:SetHeight(26)
	ToggleButton:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square', 'ADD')
	ToggleButton:Hide()

	local Icon = ToggleButton:CreateTexture('ATSWQueueToggleIcon', 'ARTWORK')
	Icon:SetAllPoints(ToggleButton)
	Icon:SetTexture('Interface\\Icons\\INV_Misc_Note_01')
	Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	Count = ToggleButton:CreateFontString('ATSWQueueToggleCount', 'OVERLAY', 'NumberFontNormal')
	Count:SetPoint('BOTTOMRIGHT', ToggleButton, 'BOTTOMRIGHT', -2, 2)

	ToggleButton:SetScript('OnClick', function()
		ATSW_Options.QueueOpen = not ATSW_Options.QueueOpen
		ATSWQueue.Update()
	end)

	ToggleButton:SetScript('OnUpdate', function()
		-- A batch can end without an event, and ATSW's own timer isn't running with its window closed
		ATSW_CheckBatchTimeout()

		-- The stock window has no event for its selection changing, so check a few times a second
		SinceSelectionCheck = SinceSelectionCheck + arg1

		if SinceSelectionCheck >= 0.2 then
			SinceSelectionCheck = 0
			ATSWQueue.UpdateAddButton()
		end
	end)

	ToggleButton:SetScript('OnEnter', function()
		GameTooltip:SetOwner(this, 'ANCHOR_RIGHT')
		GameTooltip:SetText(ATSW_QUEUE_TITLE, 1, 1, 1)
		GameTooltip:Show()
	end)

	ToggleButton:SetScript('OnLeave', function()
		GameTooltip:Hide()
	end)
end

-- The name ATSW's tasks use: a recipe with a rank has it added after three spaces
local function SelectedRecipe()
	if ATSW_TradeSkill() then
		local Name, Type = GetTradeSkillInfo(GetTradeSkillSelectionIndex())

		if Name and Type ~= 'header' then
			return Name, math.max(TradeSkillInputBox:GetNumber(), 1)
		end
	else
		local Name, SubName, Type = GetCraftInfo(GetCraftSelectionIndex())

		if Name and Type ~= 'header' then
			if SubName and SubName ~= '' then
				Name = Name .. '   (' .. SubName .. ')'
			end

			return Name, 1
		end
	end
end

-- Collapsing a header or filtering can leave no recipe selected, and then there is nothing to add
function ATSWQueue.UpdateAddButton()
	if SelectedRecipe() then
		AddButton:Enable()
	else
		AddButton:Disable()
	end
end

function ATSWQueue.AddSelected()
	local Name, Amount = SelectedRecipe()

	if Name then
		ATSW_Options.QueueOpen = true
		ATSW_QueueAdd(Name, Amount)
		ATSWQueue.Update()
	end
end

function ATSWQueue.Update()
	-- ATSW's task code calls this whichever window is open, including before one has been attached
	if not CurrentProfession then
		return
	end

	local List = Tasks()
	local Size = table.getn(List)

	Count:SetText(Size > 0 and Size or '')

	if ATSW_Options.QueueOpen then
		Sidebar:Show()
	else
		Sidebar:Hide()
	end

	FauxScrollFrame_Update(ScrollFrame, Size, ROWS, ROW_HEIGHT)

	local Offset = FauxScrollFrame_GetOffset(ScrollFrame)

	for R = 1, ROWS do
		local Task = List[R + Offset]

		Rows[R]:SetText(Task and ('|cffb0b0b0' .. Task.Amount .. 'x|r ' .. Task.Name) or '')

		if Task then
			Deletes[R].TaskName = Task.Name
			Deletes[R]:Show()
		else
			Deletes[R]:Hide()
		end
	end

	if ATSW_QueueIsCrafting() then
		StartButton:SetText(ATSW_QUEUE_STOP)
		StartButton:Enable()
	else
		StartButton:SetText(ATSW_QUEUE_START)

		if Size > 0 then
			StartButton:Enable()
		else
			StartButton:Disable()
		end
	end

	if Size == 0 then
		Empty:Show()
	else
		Empty:Hide()
	end

end

-- Called whenever a stock window opens. A linked window shows another player's recipes, so it
-- gets no queue.
function ATSWQueue.Attach(Frame, Exit, Prof, Linked)
	if Linked then
		AddButton:Hide()
		ToggleButton:Hide()
		Sidebar:Hide()

		return
	end

	CurrentProfession = Prof

	Sidebar:SetParent(Frame)
	Sidebar:SetFrameStrata('HIGH') -- Bags can sit under it when a merchant pushes the window across
	Sidebar.Exit = Exit
	Sidebar.Placed = false

	ToggleButton:SetParent(Frame)
	ToggleButton:ClearAllPoints()
	ToggleButton:SetPoint('TOPRIGHT', Exit, 'BOTTOMRIGHT', 0, -8)
	ToggleButton:Show()

	AddButton:SetParent(Frame)
	AddButton:ClearAllPoints()
	AddButton:SetPoint('RIGHT', ToggleButton, 'LEFT', -4, 0)
	AddButton:Show()

	ATSWQueue.Update()
	ATSWQueue.UpdateAddButton()
	PlaceSidebar()
end

Build()
