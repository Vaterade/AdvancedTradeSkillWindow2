-- Throwaway harness: luajit atsw_test.lua <dir with addon lua files>
local Dir = arg[1]
local function ReadFile(P) local F = assert(io.open(P)); local S = F:read('*a'); F:close(); return S end

local Files = {'Localization', 'AdvancedTradeSkillWindow2', 'CustomSorting'}
local UsePfUI = arg[2] == 'pfui'
local SkinDisabled = arg[3] == 'disabled'
if io.open(Dir .. '/QueueSidebar.lua') then table.insert(Files, 'QueueSidebar') end
if io.open(Dir .. '/pfUISkin.lua') then table.insert(Files, 'pfUISkin') end
local Sources, Methods = {}, {}
for _, N in ipairs(Files) do
	local S = ReadFile(Dir .. '/' .. N .. '.lua')
	-- Lua 5.0 implicit `arg` table
	S = string.gsub(S, '(function%s*[%w_.:]*%s*%([^)]*%.%.%.%s*%))', '%1 local arg = {n = select("#", ...), ...};')
	Sources[N] = S
	for M in string.gmatch(S, ':%s*(%u%a+)%s*%(') do Methods[M] = true end
end

local function Noop() end
local Created = 0
local Frame
local Meta = {__index = function(T, K)
	if Methods[K] then return Noop end
end}
function Frame(Name)
	local F = setmetatable({_name = Name, XOffset = 0, _visible = false, _lines = {}}, Meta)
	F.GetName = function() return Name or 'stub' end
	F.IsVisible = function(S) return S._visible end
	F.Show = function(S) S._visible = true end
	F.Hide = function(S) S._visible = false end
	F.GetParent = function(S) return S._parent or UIParent end
	F.GetNumber = function() return 0 end
	F.GetWidth = function() return 100 end
	F.GetHeight = function() return 18 end
	F.GetTextWidth = function() return 50 end
	F.GetFrameLevel = function() return 1 end
	F.GetAlpha = function() return 0 end
	F.GetMinMaxValues = function() return 0, 1 end
	F.GetBackdropColor = function() return 0, 0, 0, 1 end
	F.GetTextColor = function() return 0, 0, 0 end
	F.GetValue = function() return 0 end
	F.NumLines = 0
	F.MaxLineWidth = 0
	F.GetPoint = function() return 'LEFT', F, 'LEFT', 0, 0 end
	F.AddTextLine = function(S, T) table.insert(S._lines, T) end
	F.ClearLines = function(S) S._lines = {} end
	F.SetVertexColor = function(S, R, G, B) S._color = {R, G, B} end
	F.GetNormalTexture = function() return Frame() end
	F.GetPushedTexture = function() return Frame() end
	F.CreateFontString = function(S, Name) local R = Frame(Name); if Name then rawset(_G, Name, R) end; return R end
	F.SetTextColor = function(S, R, G, B) S._text = {R, G, B} end
	F.SetTexture = function(S, T) S._tex = T end
	F.SetScript = function(S, N, V) S._s = S._s or {}; S._s[N] = V end
	F.GetScript = function(S, N) return S._s and S._s[N] end
	F.SetBackdrop = function(S, B) S._backdrop = B; S._setbackdrop = (S._setbackdrop or 0) + 1 end
	F.GetRegions = function(S) return unpack(S._regions or {}) end
	F.GetChildren = function(S) return unpack(S._children or {}) end
	F.GetCheckedTexture = function() return Frame() end
	F.Enable = function(S) S._enabled = true end
	F.Disable = function(S) S._enabled = false end
	F.SetParent = function(S, P) S._parent = P; P._regions = P._regions or {}; table.insert(P._regions, S) end
	F.SetVertexColor = function(S, R, G, B, A) S._color = {R, G, B, A} end
	F.GetHighlightTexture = function() return Frame() end
	F.CreateTexture = function(S, Name) local R = Frame(Name); if Name then rawset(_G, Name, R) end; return R end
	return F
end

local Deny = {GromissingcraftsWindow=1, AegisExchangeFrame=1, Time=1, TimePassed=1, ERT=1, RecipesRemaining=1, ParameterString=1, CatIndex=1, aux_frame=1, AuxBuySearchBox=1, AuxBuyNameInputBox=1, AC_Craft=1, WIM_EditBoxInFocus=1, BlizzMo=1,
	GetSpellInfoVanillaDB=1, GetSpellInfoAtlasLootDB=1, AtlasLoot_Data=1, OldCraftCount=1, AuctionFrame=1,
	ATSW_Unified=1, Bar=1, T=1, Pos=1, Rt=1, Name=1, Tooltip=1, HeaderAdded=1, ATSW_ConsigerBank=1}
if os.getenv('NOCAPI') then Deny.IsTradeSkillLinked = 1; Deny.IsCraftLinked = 1; Deny.GetTradeSkillListLink = 1; Deny.GetCraftListLink = 1; Deny.GetSpellInfo = 1 end
setmetatable(_G, {__index = function(T, K)
	if Deny[K] then return nil end
	if string.find(K, '^ATSWRFReagent%d') then return nil end
	if string.find(K, '^ATSW[A-Z]') and not string.find(K, '^ATSWCS_') then
		local F = Frame(K); rawset(T, K, F); return F
	end
	if string.find(K, '^[A-Z][A-Z_0-9]+$') then return K end       -- Blizzard string constants
	if string.find(K, '^[A-Z][%w_]*$') then return Noop end
	return nil
end})

UIParent = Frame('UIParent'); UIParent._visible = true
TradeSkillFrame, CraftFrame, GameTooltip = Frame('TSF'), Frame('CF'), Frame('GT')
MerchantFrame, ChatFrameEditBox, TradeSkillListScrollFrame = Frame('MF'), Frame('CEB'), Frame('TLSF')
ChatFrame1, DEFAULT_CHAT_FRAME = Frame('CF1'), Frame('DCF')
UIPanelWindows, StaticPopupDialogs, SlashCmdList = {}, {}, {}
MAX_TRADE_SKILL_REAGENTS = 8
BANK_CONTAINER, BOOKTYPE_SPELL = -1, 'spell'
ERR_LEARN_RECIPE_S, ERR_LEARN_SPELL_S, ERR_LEARN_ABILITY_S = 'You have learned %s.', 'You have learned a new spell: %s.', 'New ability: %s.'
ERR_SPELL_UNLEARNED_S = 'You have unlearned %s.'
ERR_SKILL_UP_SI, ERR_SKILL_GAINED_S = 'Your skill in %s has increased to %d.', 'You have gained the %s skill.'
LOOT_ITEM_CREATED_SELF = 'You create: %s.'
ERR_USE_LOCKED_WITH_ITEM_S, ITEM_MIN_LEVEL = 'Requires %s', 'Requires Level %d'
TEXT = function(S) return S end
format, gsub, strfind, strlen = string.format, string.gsub, string.find, string.len
table.getn = table.getn or function(T) return #T end
getglobal = function(N) return _G[N] end
ChatFrame_TimeBreakDown = function(S) return 0, 0, math.floor(S / 60), math.floor(S % 60) end
FauxScrollFrame_GetOffset = function() return 0 end
string.gfind = string.gfind or string.gmatch
math.mod = math.mod or math.fmod

GetRealmName = function() return "N'Zoth" end
UnitName = function() return 'Hero' end
UnitClass = function() return 'Warrior', 'WARRIOR' end
local Now = 100
GetTime = function() Now = Now + 1; return Now end
GetNetStats = function() return 0, 0, 50 end
IsShiftKeyDown, IsControlKeyDown, IsAltKeyDown = Noop, Noop, Noop
GetCVar = function() return '1' end
GetCraftButtonToken = function() return 'CREATE' end

local Book = {
	{'Smelting', 'Interface\\Icons\\Spell_Fire_FlameBlades'},
	{'Cooking', 'Interface\\Icons\\INV_Misc_Food_15'},
}
GetSpellTabInfo = function() return 'General', '', 0, table.getn(Book) end
GetSpellName = function(I) return Book[I] and Book[I][1] end
GetSpellTexture = function(I) return Book[I] and Book[I][2] end

local Skills = {
	{Name = 'Smelting',        Type = 'header'},
	{Name = 'Smelt Copper',    Type = 'easy', ID = 2840},
	{Name = 'Smelt Dreamsteel',Type = 'easy', ID = 61216},
	{Name = 'Smelt Bronze',    Type = 'easy', ID = 2841},
}
Line = 'Mining'
GetTradeSkillLine = function() return Line, 100, 300 end
GetNumTradeSkills = function() return table.getn(Skills) end
GetFirstTradeSkill = function() return 2 end
GetTradeSkillInfo = function(I) local S = Skills[I]; if S then return S.Name, S.Type, 5, true end end
GetTradeSkillIcon = function() return 'Interface\\Icons\\Temp' end
GetTradeSkillItemLink = function(I)
	local S = Skills[I]
	return S and S.ID and ('|cffffffff|Hitem:' .. S.ID .. ':0:0:0|h[' .. S.Name .. ']|h|r')
end
GetTradeSkillNumMade = function() return 1, 1 end
GetTradeSkillCooldown = Noop
GetTradeSkillNumReagents = function(I) return Skills[I].ID and 1 or 0 end
GetTradeSkillReagentInfo = function() return 'Ore', 'tex', 1, 20 end
GetTradeSkillReagentItemLink = function() return '|cffffffff|Hitem:2770:0:0:0|h[Ore]|h|r' end
GetTradeSkillTools = Noop
GetTradeSkillSubClasses = Noop
GetTradeSkillInvSlots = Noop
GetContainerNumSlots = function() return 0 end
GetContainerItemLink, GetContainerItemInfo = Noop, Noop
GetItemInfo = Noop
DoTradeSkill = Noop
local Opening = false
CastSpellByName = function(N) end
CastSpell = Noop
UseAction = Noop

Created = 0
CreateFrame = function(Type, Name, Parent)
	if Name and string.find(Name, '^ATSWRFReagent%d') then Created = Created + 1 end
	local F = Frame(Name)
	F._parent = Parent
	if Name then rawset(_G, Name, F) end
	return F
end

if UsePfUI then
	local Log = {}
	PFLOG = Log
	local Env = {}
	local function API(Name, F)
		Env[Name] = function(A, B, C, D, E)
			if A == nil then error(Name .. ' called with nil frame', 2) end
			Log[Name] = (Log[Name] or 0) + 1
			if F then return F(A, B, C, D, E) end
		end
	end
	local function Back(F) F.backdrop = F.backdrop or Frame('backdrop') end
	API('StripTextures', function(F) for _, V in ipairs(F._regions or {}) do V._tex = nil end end); API('CreateBackdrop', function(F, I, Legacy) if not Legacy then Back(F) end end)
	API('CreateBackdropShadow'); API('SkinButton', function(B)
		-- like the real one: empties the stock textures
		B.SetHighlightTexture = B.SetHighlightTexture
		B.GetNormalTexture = function() return nil end
		B.GetPushedTexture = function() return nil end
	end)
	API('SkinCheckbox'); API('SkinDropDown'); API('SkinScrollbar'); API('SkinArrowButton')
	API('SkinCloseButton', function(B)
		B.GetNormalTexture = function() return nil end
		B.GetPushedTexture = function() return nil end
		B._closeSkinned = true
	end)
	Env.GetPerfectPixel = function() return 0.7 end
	Env.GetStringColor = function() return 0.2, 0.2, 0.2, 1 end
	Env._G = _G
	setmetatable(Env, {__index = _G})
	pfUI_config = {appearance = {border = {color = 'x'}}, disabled = SkinDisabled and {skin_AdvancedTradeSkillWindow2 = '1'} or nil}
	pfUI = {media = setmetatable({}, {__index = function(T, K) return K end}), font_default = 'PFFONT'}
	function pfUI:RegisterSkin(Name, F) setfenv(F, Env); F() end
	hooksecurefunc = function(Name, F)
		local Orig = _G[Name]
		assert(type(Orig) == 'function', 'hook target missing: ' .. Name)
		_G[Name] = function(A, B, C, D) local X, Y = Orig(A, B, C, D); F(A, B, C, D); return X, Y end
	end
end

for _, N in ipairs(Files) do
	local Chunk, Err = loadstring(Sources[N], N)
	if not Chunk then error(Err) end
	Chunk()
end

local function Fire(E, A1, A2)
	event, arg1, arg2 = E, A1, A2
	this = ATSWFrame
	ATSW_OnEvent()
end

local Realm, Me = "N'Zoth", 'Hero'
local Results = {}
local function Test(Name, F)
	local OK, Err = pcall(F)
	print((OK and 'PASS  ' or 'FAIL  ') .. Name .. (OK and '' or ('\n        ' .. tostring(Err))))
end
local function Eq(A, B, What) if A ~= B then error((What or '') .. ': expected ' .. tostring(B) .. ', got ' .. tostring(A), 2) end end

-- Open the Smelting window through the real event path
CastSpellByName('Smelting')
Fire('PLAYER_ENTERING_WORLD')
local Hooked = CastSpellByName
Hooked('Smelting')
Fire('TRADE_SKILL_SHOW')
Eq(ATSW_Profession[Realm][Me], 'Smelting', 'setup profession')
ATSW_GetRecipes(true)

local function Clear() ATSW_Tasks[Realm][Me]['Smelting'] = {} end

Test('1a Smelt Copper keeps its table color and starts processing', function()
	Clear(); ATSWProgressBarTexture._color = nil
	ATSW_Craft('Smelt Copper', 1)
	Fire('SPELLCAST_START', 'Smelt Copper', 3000)
	Eq(ATSWProgressBarTexture._color[1], 0.72, 'R')
	ATSW_StopProcessing()
end)
Test('1b Smelt Dreamsteel uses default color, queue counts down', function()
	Clear(); ATSWProgressBarTexture._color = nil
	ATSW_AddTask('Smelt Dreamsteel', 2)
	Eq(table.getn(ATSW_Tasks[Realm][Me]['Smelting']), 1, 'task added')
	ATSW_Craft('Smelt Dreamsteel', 2)
	Fire('SPELLCAST_START', 'Smelt Dreamsteel', 3000)
	Eq(ATSWProgressBarTexture._color[1], 1, 'R')
	Fire('CHAT_MSG_LOOT', 'You create: Dreamsteel Bar.')
	Eq(ATSW_Tasks[Realm][Me]['Smelting'][1].Amount, 1, 'remaining after one craft')
	ATSW_StopProcessing(); Clear()
end)

-- Merchant: need 10 Ore, have 10 in the bank, none in bags
local Buys
BuyMerchantItem = function(I, Q) table.insert(Buys, Q) end
GetMerchantNumItems = function() return 1 end
GetMerchantItemInfo = function() return 'Ore', 'tex', 100, 1, -1 end
local function MerchantSetup(ConsiderBank)
	Buys = {}
	MerchantFrame._visible = true
	ATSW_Options.ConsiderBank = ConsiderBank
	ATSW_NecessaryReagents[Realm][Me] = {{Name = 'Ore', Amount = 10}}
	ATSW_Bank[Realm] = {[Me] = {Ore = 10}}
end
Test('2a ConsiderBank on: reagents in the bank are not bought', function()
	MerchantSetup(true); ATSW_BuyFromMerchant(); Eq(table.getn(Buys), 0, 'buy calls')
end)
Test('2b ConsiderBank off: still buys the full amount', function()
	MerchantSetup(false); ATSW_BuyFromMerchant(); Eq(Buys[1], 10, 'bought')
end)
ATSW_NecessaryReagents[Realm][Me] = {}; ATSW_Options.ConsiderBank = false; MerchantFrame._visible = false

-- Alts
local function AltSetup()
	ATSW_Characters[Realm] = {
		{Name = Me, Class = 'Warrior'},
		{Name = 'Alta', Class = 'Mage'},
		{Name = 'Bolt', Class = 'WARRIOR'},   -- entry saved by an older version
	}
	ATSW_Bags[Realm] = {
		Alta = {[0] = {[1] = {Ore = 3}}},
		Bolt = {[0] = {[1] = {Ore = 4}}},
	}
	ATSW_Bank[Realm] = {Alta = {Ore = 5}, Bolt = {Ore = 7}, [Me] = {Ore = 100}}
	this = Frame('Hover'); this._parent = Frame('Row'); this._parent.Link = '[Ore]'
	ATSWRecipeTooltip:ClearLines()
	ATSWRecipeTooltip._visible = false
end
-- Record lines, then run the addon's real AddTextLine
local RealAdd, RealClear = ATSWRecipeTooltip.AddTextLine, ATSWRecipeTooltip.ClearLines
ATSWRecipeTooltip.AddTextLine = function(S, T, A, B, C) table.insert(S._lines, T); return RealAdd(S, T, A, B, C) end
ATSWRecipeTooltip.ClearLines = function(S) S._lines = {}; return RealClear(S) end
local function Lines() return table.concat(ATSWRecipeTooltip._lines, '\n') end
Test('3a alt tooltip lists each alt with its own counts', function()
	AltSetup()
	ATSW_GetAltsLocationIntoTooltip('Ore')
	local L = Lines()
	assert(string.find(L, '[Ore]', 1, true), 'no header: "' .. L .. '"')
	assert(string.find(L, 'Alta|r: |cffffffff3|r', 1, true), 'Alta bags: ' .. L)
	assert(string.find(L, 'Alta|r: |cffffffff5|r', 1, true), 'Alta bank: ' .. L)
	assert(string.find(L, 'Bolt: |cffffffff4|r', 1, true), 'Bolt bags: ' .. L)
	assert(string.find(L, 'Bolt: |cffffffff7|r', 1, true), 'Bolt bank: ' .. L)
	assert(not string.find(L, '12|r', 1, true), 'combined bank total: ' .. L)
	Eq(string.find(L, 'Hero', 1, true), nil, 'own character listed')
	Eq(ATSWRecipeTooltip._visible, true, 'tooltip shown')
end)
Test('3b item no alt has: no empty tooltip', function()
	AltSetup()
	ATSW_GetAltsLocationIntoTooltip('Linen')
	Eq(Lines(), '', 'lines')
	Eq(ATSWRecipeTooltip._visible, false, 'tooltip shown')
end)
Test('3c class name is Warrior, not WARRIOR, for a new character', function()
	ATSW_Characters[Realm] = {}
	Fire('PLAYER_ENTERING_WORLD')
	Eq(ATSW_Characters[Realm][1].Class, 'Warrior', 'class')
end)

-- Bank bags
Test('4 bank bags are not saved into the bag list; alt total not doubled', function()
	GetContainerNumSlots = function(B) return (B == 5 or B == 0) and 1 or 0 end
	GetContainerItemLink = function() return '|cffffffff|Hitem:2770:0:0:0|h[Ore]|h|r' end
	GetContainerItemInfo = function() return 'tex', 2 end
	ATSW_Bags[Realm] = {}
	ATSW_SaveBag(5); ATSW_SaveBag(-2); ATSW_SaveBag(-1)
	Eq(ATSW_Bags[Realm][Me], nil, 'bank bag saved')
	ATSW_SaveBag(0)
	Eq(ATSW_Bags[Realm][Me][0][1].Ore, 2, 'backpack saved')
	GetContainerNumSlots = function() return 0 end
	GetContainerItemLink, GetContainerItemInfo = Noop, Noop
end)

-- Unlearn
Test('5 unlearning with three tasks clears tasks and history', function()
	Clear()
	ATSW_AddTask('Smelt Copper', 1); ATSW_AddTask('Smelt Bronze', 1); ATSW_AddTask('Smelt Dreamsteel', 1)
	Eq(table.getn(ATSW_Tasks[Realm][Me]['Smelting']), 3, 'tasks')
	ATSW_PreviousRecipes[Realm][Me]['Smelting'] = {'a', 'b', 'c', 'd'}
	Fire('CHAT_MSG_SYSTEM', 'You have unlearned Smelting.')
	Eq(table.getn(ATSW_Tasks[Realm][Me]['Smelting']), 0, 'tasks left')
	Eq(table.getn(ATSW_PreviousRecipes[Realm][Me]['Smelting']), 0, 'history left')
end)

-- Reagents window
ATSW_Profession[Realm][Me] = 'Smelting'
Test('6 opening the Reagents window repeatedly creates 20 frames once', function()
	Created = 0
	ATSW_Tasks[Realm][Me]['Smelting'] = {}
	for I = 1, 3 do
		ATSWReagentsFrame._visible = false
		ATSWReagentsButton_OnClick()
	end
	Eq(Created, ATSW_NECESSARIES_DISPLAYED, 'frames created')
end)

if UsePfUI and not SkinDisabled then
	Test('P1 tooltip backdrop is left to pfUI on load', function()
		GameTooltip._setbackdrop = nil
		ATSW_OnLoad()
		Eq(GameTooltip._setbackdrop, nil, 'GameTooltip SetBackdrop calls')
	end)
	Test('P2 list buttons skinned after first open, in a safe order', function()
		assert(ATSWTask1, 'no task rows')
		Eq(ATSWTask1DeleteButton._closeSkinned, true, 'delete button')
		assert(ATSWReagent1.backdrop, 'reagent icon backdrop')
	end)
	Test('P3 font constant and text colours', function()
		Eq(ATSW_FontFile, 'PFFONT', 'font')
		Eq(ATSWRecipeName._text[1], 0.9, 'recipe name')
	end)
	Test('P4 black reagent and tool text stays readable; missing tool stays red', function()
		ATSWReagent1Title:SetTextColor(0, 0, 0, 1)
		Eq(ATSWReagent1Title._text[1], 0.9, 'reagent title')
		ATSWTool1Text:SetTextColor(0, 0, 0)
		Eq(ATSWTool1Text._text[1], 0.9, 'tool have')
		ATSWTool1Text:SetTextColor(1, 0, 0)
		Eq(ATSWTool1Text._text[1], 1, 'tool missing')
		Eq(ATSWTool1Text._text[2], 0, 'tool missing')
	end)
	Test('P5 quality goes to the icon border, white and hidden reset it', function()
		local Set
		ATSWRecipeIcon.backdrop.SetBackdropBorderColor = function(S, R, G, B) Set = {R, G, B} end
		ATSWRecipeIconQualityTexture:SetVertexColor(0.12, 1, 0)
		Eq(Set[1], 0.12, 'green')
		ATSWRecipeIconQualityTexture:SetVertexColor(1, 1, 1)
		Eq(Set[1], 0.2, 'white reset')
		ATSWRecipeIconQualityTexture:SetVertexColor(0, 0.44, 0.87)
		ATSWRecipeIconQualityTexture:Hide()
		Eq(Set[1], 0.2, 'hide reset')
		ATSWRecipeIconQualityTexture:SetVertexColor(nil, nil, nil)
	end)
	Test('P6 background art and portrait stay themed after a redraw', function()
		ATSW_UpdateBackground()
		Eq(ATSWBackground._tex, nil, 'background')
		ATSW_Profession[Realm][Me] = 'Cooking'
		ATSW_UpdateCaption()
		Eq(ATSWFramePortrait._tex, 'Interface\\Icons\\INV_Misc_Food_15', 'portrait')
		ATSW_Profession[Realm][Me] = 'Smelting'
	end)
	Test('P9 search icon survives the search box being stripped', function()
		assert(ATSWSearchIcon._tex and string.find(ATSWSearchIcon._tex, 'Search'), 'icon texture: ' .. tostring(ATSWSearchIcon._tex))
		Eq(ATSWSearchIcon._parent, ATSWSearchBox, 'icon parent')
	end)
	Test('P10 selected row tint is softened', function()
		ATSWHighlightTexture:SetVertexColor(1, 1, 0, 0.8)
		assert(math.abs(ATSWHighlightTexture._color[4] - 0.36) < 1e-9, 'alpha ' .. tostring(ATSWHighlightTexture._color[4]))
	end)
	Test('P7 create button cannot get the stock highlight back', function()
		local Real = ATSWCreateButton.SetHighlightTexture
		ATSW_PushCreateButton(false)
		assert(Real ~= Noop, 'override missing')
	end)
	Test('P8 lazily created rows and hooks run', function()
		ATSWReagentsFrame._visible = false
		ATSWReagentsButton_OnClick()
		ATSW_ShowAuctionShoppingList()
		ATSWCS_OnShow()
	end)
	local Names = {}
	for K, V in pairs(PFLOG) do table.insert(Names, K .. '=' .. V) end
	table.sort(Names)
	print('      calls: ' .. table.concat(Names, ' '))
end
if UsePfUI and SkinDisabled then
	Test('D1 disabled skin leaves the addon stock', function()
		Eq(ATSW_FontFile, 'Fonts\\FRIZQT__.ttf', 'font')
		Eq(next(PFLOG), nil, 'pfUI calls')
	end)
end

-- /atsw enable and disable, with stock windows that behave like the client's
do
	local Closes = {Trade = 0, Craft = 0}
	local Messages = {}
	DEFAULT_CHAT_FRAME.AddMessage = function(S, M) table.insert(Messages, M) end
	local function LastMessage() return Messages[table.getn(Messages)] end

	local function Stock(F, Kind, CloseEvent)
		F._events = {}
		F.RegisterEvent = function(S, E) S._events[E] = true end
		F.UnregisterEvent = function(S, E) S._events[E] = nil end
		F._scripts = {OnHide = function()
			Closes[Kind] = Closes[Kind] + 1
			if ATSWFrame._reg == nil or ATSWFrame._reg[CloseEvent] ~= false then
				event, arg1 = CloseEvent, nil
				ATSW_OnEvent()
			end
		end}
		F.GetScript = function(S, N) return S._scripts[N] end
		F.SetScript = function(S, N, V) S._scripts[N] = V end
		F.Hide = function(S)
			if S._visible then
				S._visible = false
				if S._scripts.OnHide then S._scripts.OnHide() end
			end
		end
	end
	Stock(TradeSkillFrame, 'Trade', 'TRADE_SKILL_CLOSE')
	Stock(CraftFrame, 'Craft', 'CRAFT_CLOSE')
	ATSWFrame._reg = {}
	ATSWFrame.RegisterEvent = function(S, E) S._reg[E] = true end
	ATSWFrame.UnregisterEvent = function(S, E) S._reg[E] = false end
	ShowUIPanel = function(F) F._visible = true end
	HideUIPanel = function(F) F:Hide() end
	TradeSkillFrame_Show = function() ShowUIPanel(TradeSkillFrame) end
	CraftFrame_Show = function() ShowUIPanel(CraftFrame) end
	-- The profession stays open until something closes it, like the client
	CloseTradeSkill, CloseCraft = Noop, Noop

	table.insert(Book, {'Enchanting', 'Interface\\Icons\\Trade_Engraving'})
	GetCraftName = function() return 'Enchanting' end
	GetCraftDisplaySkillLine = function() return 'Enchanting', 100, 300 end
	GetNumCrafts = function() return 0 end

	local function Open(Name)
		CastSpellByName(Name)
		Line = (Name == 'Smelting') and 'Mining' or Name
		Fire(Name == 'Enchanting' and 'CRAFT_SHOW' or 'TRADE_SKILL_SHOW')
	end
	local function Reset()
		-- Close through the game's normal path, so the addon's state follows
		TradeSkillFrame:Hide(); CraftFrame:Hide()
		for _, F in ipairs({TradeSkillFrame, CraftFrame, ATSWFrame}) do
			local Old = F._scripts; if Old then F._scripts = {} end
			F._visible = false
			if Old then F._scripts = Old end
		end
		ATSW_Disabled = {}
		SLASH = SlashCmdList
	end
	local function Saved(P) return ATSW_Disabled[Realm] and ATSW_Disabled[Realm][Me] and ATSW_Disabled[Realm][Me][P] end

	Test('E1 /atsw disable swaps to the stock window without closing the profession', function()
		Reset(); Open('Cooking'); Eq(ATSWFrame._visible, true, 'ATSW open')
		local Before = Closes.Trade
		ATSW_Command('disable')
		Eq(ATSWFrame._visible, false, 'ATSW')
		Eq(TradeSkillFrame._visible, true, 'stock')
		Eq(Saved('Cooking'), true, 'saved')
		Eq(TradeSkillFrame._events.TRADE_SKILL_UPDATE, true, 'stock gets updates')
		Eq(TradeSkillFrame._events.PLAYER_ENTERING_WORLD, true, 'stock gets loading screens')
		Eq(Closes.Trade, Before, 'closes')
		assert(string.find(LastMessage(), 'off for Cooking'), LastMessage())
	end)
	Test('E2 closing the stock window, then reopening, stays stock', function()
		TradeSkillFrame:Hide()
		Eq(TradeSkillFrame._events.TRADE_SKILL_UPDATE, nil, 'events returned')
		Eq(ATSWFrame._visible, false, 'ATSW')
		Open('Cooking')
		Eq(TradeSkillFrame._visible, true, 'stock')
		Eq(ATSWFrame._visible, false, 'ATSW after reopen')
	end)
	Test('E3 a different profession uses ATSW, and the new one is not closed', function()
		local Before = Closes.Trade
		Open('Smelting')
		Eq(TradeSkillFrame._visible, false, 'stock')
		Eq(ATSWFrame._visible, true, 'ATSW')
		Eq(Closes.Trade, Before, 'closes')
		Eq(ATSW_Profession[Realm][Me], 'Smelting', 'profession')
	end)
	Test('E4 switching from ATSW to a disabled profession', function()
		Open('Cooking')
		Eq(ATSWFrame._visible, false, 'ATSW')
		Eq(TradeSkillFrame._visible, true, 'stock')
	end)
	Test('E5 /atsw enable returns to ATSW and is remembered', function()
		local Before = Closes.Trade
		ATSW_Command('enable')
		Eq(TradeSkillFrame._visible, false, 'stock')
		Eq(ATSWFrame._visible, true, 'ATSW')
		Eq(Saved('Cooking'), nil, 'saved')
		Eq(Closes.Trade, Before, 'closes')
		Eq(TradeSkillFrame._events.TRADE_SKILL_UPDATE, nil, 'events returned')
		Open('Smelting'); Open('Cooking')
		Eq(ATSWFrame._visible, true, 'ATSW after reopen')
	end)
	Test('E6 stock Smelting can be enabled after casting something else', function()
		Reset(); Open('Smelting')
		ATSW_Command('disable')
		Eq(Saved('Smelting'), true, 'saved')
		CastSpellByName('Frostbolt')
		ATSW_Command('enable')
		Eq(Saved('Smelting'), nil, 'saved')
		Eq(ATSW_Profession[Realm][Me], 'Smelting', 'profession')
	end)
	Test('E7 stock craft and trade windows replace each other', function()
		Reset(); Open('Enchanting')
		Eq(ATSWFrame._visible, true, 'ATSW for Enchanting')
		ATSW_Command('disable')
		Eq(CraftFrame._visible, true, 'stock craft')
		Eq(CraftFrame._events.CRAFT_UPDATE, true, 'craft updates')
		Open('Cooking')
		Eq(CraftFrame._visible, false, 'stock craft closed')
		Eq(ATSWFrame._visible, true, 'ATSW for Cooking')
		ATSW_Command('disable')
		Eq(TradeSkillFrame._visible, true, 'stock trade')
		Open('Enchanting')
		Eq(TradeSkillFrame._visible, false, 'stock trade closed')
		Eq(CraftFrame._visible, true, 'stock craft again')
		Eq(ATSWFrame._visible, false, 'ATSW')
	end)
	Test('E8 commands with no window open change nothing', function()
		Reset()
		ATSW_Command('disable')
		Eq(next(ATSW_Disabled), nil, 'saved')
		assert(string.find(LastMessage(), 'Open a profession'), LastMessage())
		ATSW_Command('enable')
		assert(string.find(LastMessage(), 'Open a profession'), LastMessage())
	end)
	Test('E9 the setting is per character', function()
		ATSW_Disabled = {[Realm] = {Alta = {Cooking = true}}}
		Open('Cooking')
		Eq(ATSWFrame._visible, true, 'ATSW')
	end)

	-- Task queue sidebar
	TradeSkillCancelButton, CraftCancelButton = Frame('TradeExit'), Frame('CraftExit')
	local Points
	ATSWQueueFrame.SetPoint = function(S, P, To) Points[P] = To end
	ATSWQueueFrame.ClearAllPoints = function() Points = {} end
	ATSWQueueToggleCount.SetText = function(S, T) S._t = T end
	ATSWQueueRow1.SetText = function(S, T) S._t = T end
	ATSWQueueRow2.SetText = function(S, T) S._t = T end

	Test('S1 a stock window gets the buttons, parented so they close with it', function()
		Reset(); ATSW_Options.QueueOpen = nil
		ATSW_Tasks[Realm][Me]['Cooking'] = {{Name = 'Roast', Amount = 3}, {Name = 'Stew', Amount = 1}}
		Open('Cooking'); ATSW_Command('disable')
		Eq(ATSWQueueToggleButton._visible, true, 'toggle')
		Eq(ATSWQueueAddButton._visible, true, 'add')
		Eq(ATSWQueueToggleButton._parent, TradeSkillFrame, 'toggle parent')
		Eq(ATSWQueueAddButton._parent, TradeSkillFrame, 'add parent')
		Eq(ATSWQueueFrame._parent, TradeSkillFrame, 'sidebar parent')
		Eq(ATSWQueueToggleCount._t, 2, 'count')
		Eq(ATSWQueueFrame._visible, false, 'closed by default')
		Eq(Points.LEFT, TradeSkillCancelButton, 'anchored to Exit')
		Eq(Points.BOTTOM, TradeSkillCancelButton, 'bottom anchored to Exit')
	end)
	Test('S2 the toggle is remembered and the sidebar lists the tasks', function()
		ATSW_Options.QueueOpen = true
		ATSWQueue.Update()
		Eq(ATSWQueueFrame._visible, true, 'open')
		assert(string.find(ATSWQueueRow1._t, 'Roast', 1, true) and string.find(ATSWQueueRow1._t, '3x', 1, true), ATSWQueueRow1._t)
		assert(string.find(ATSWQueueRow2._t, 'Stew', 1, true), ATSWQueueRow2._t)
		TradeSkillFrame:Hide(); Open('Cooking')
		Eq(ATSWQueueFrame._visible, true, 'still open on reopening')
	end)
	Test('S3 the sidebar moves aside for the Gromissingcrafts panel, and back', function()
		rawset(_G, 'GromissingcraftsWindow', Frame('GMC')); GromissingcraftsWindow._visible = true
		ATSWQueueFrame:GetParent()
		ATSWQueue.Attach(TradeSkillFrame, TradeSkillCancelButton, 'Cooking')
		Eq(Points.LEFT, GromissingcraftsWindow, 'beside panel')
		GromissingcraftsWindow._visible = false
		ATSWQueue.Attach(TradeSkillFrame, TradeSkillCancelButton, 'Cooking')
		Eq(Points.LEFT, TradeSkillCancelButton, 'back')
		rawset(_G, 'GromissingcraftsWindow', nil)
	end)
	Test('S6 under pfUI the sidebar lines up with the window backdrop', function()
		TradeSkillFrame.backdrop = Frame('pfBackdrop')
		ATSWQueue.Attach(TradeSkillFrame, TradeSkillCancelButton, 'Cooking')
		Eq(Points.TOP, TradeSkillFrame.backdrop, 'top')
		Eq(Points.BOTTOM, TradeSkillFrame.backdrop, 'bottom')
		Eq(Points.LEFT, TradeSkillFrame.backdrop, 'left')
		rawset(_G, 'GromissingcraftsWindow', Frame('GMC')); GromissingcraftsWindow._visible = true
		ATSWQueue.Attach(TradeSkillFrame, TradeSkillCancelButton, 'Cooking')
		Eq(Points.LEFT, GromissingcraftsWindow, 'beside the panel')
		rawset(_G, 'GromissingcraftsWindow', nil)
		TradeSkillFrame.backdrop = nil
		ATSWQueue.Attach(TradeSkillFrame, TradeSkillCancelButton, 'Cooking')
		Eq(Points.TOP, TradeSkillFrame, 'stock top')
		Eq(Points.BOTTOM, TradeSkillCancelButton, 'stock bottom')
	end)
	Test('S4 long queues scroll; an empty one shows the empty text', function()
		local Big = {}
		for I = 1, 25 do Big[I] = {Name = 'T' .. I, Amount = 1} end
		ATSW_Tasks[Realm][Me]['Cooking'] = Big
		local Offset = FauxScrollFrame_GetOffset
		FauxScrollFrame_GetOffset = function() return 5 end
		ATSWQueue.Update()
		FauxScrollFrame_GetOffset = Offset
		assert(string.find(ATSWQueueRow1._t, 'T6', 1, true), ATSWQueueRow1._t)
		Eq(ATSWQueueDelete20.TaskName, 'T25', 'last row')
		Eq(ATSWQueueEmpty._visible, false, 'empty text')
		ATSW_Tasks[Realm][Me]['Cooking'] = {}
		ATSWQueue.Update()
		Eq(ATSWQueueEmpty._visible, true, 'empty text')
		Eq(ATSWQueueToggleCount._t, '', 'count')
	end)
	Test('S5 another player linked profession gets no queue', function()
		ATSWQueue.Attach(TradeSkillFrame, TradeSkillCancelButton, 'Tailoring', 1)
		Eq(ATSWQueueToggleButton._visible, false, 'toggle')
		Eq(ATSWQueueAddButton._visible, false, 'add')
		Eq(ATSWQueueFrame._visible, false, 'sidebar')
		ATSW_Options.QueueOpen = nil
		ATSW_Disabled = {}
		TradeSkillFrame:Hide()
	end)

	-- Working the queue from the stock window, with a list that really filters and collapses
	do
		local Full = {
			{Name = 'Metals', Type = 'header', Sub = 1},
			{Name = 'Smelt Copper', Type = 'easy', ID = 2840, Sub = 1, Slot = 0},
			{Name = 'Smelt Bronze', Type = 'easy', ID = 2841, Sub = 1, Slot = 0},
			{Name = 'Other', Type = 'header', Sub = 2},
			{Name = 'Smelt Dreamsteel', Type = 'easy', ID = 61216, Sub = 2, Slot = 1},
		}
		local FilterSub, FilterSlot, Folded, Selection, Changes = 0, 0, {}, 2, 0
		local function View()
			local V, Head = {}, nil
			for _, R in ipairs(Full) do
				if FilterSub == 0 or R.Sub == FilterSub then
					if R.Type == 'header' then
						Head = R; table.insert(V, R)
					elseif (FilterSlot == 0 or R.Slot == FilterSlot) and not Folded[Head.Name] then
						table.insert(V, R)
					end
				end
			end
			return V
		end
		local Crafted, Keep
		local function UseList()
			Keep = {GetNumTradeSkills, GetTradeSkillInfo, GetTradeSkillItemLink, GetTradeSkillNumReagents, DoTradeSkill}
			GetNumTradeSkills = function() return table.getn(View()) end
			GetTradeSkillInfo = function(I) local R = View()[I]; if R then return R.Name, R.Type, 5, not Folded[R.Name] end end
			GetTradeSkillItemLink = function(I) local R = View()[I]; return R and R.ID and ('|cffffffff|Hitem:' .. R.ID .. ':0:0:0|h[' .. R.Name .. ']|h|r') end
			GetTradeSkillNumReagents = function(I) local R = View()[I]; return R and R.ID and 1 or 0 end
			DoTradeSkill = function(I, N) Crafted = {View()[I].Name, N, table.getn(View())} end
		end
		local function EndList()
			GetNumTradeSkills, GetTradeSkillInfo, GetTradeSkillItemLink, GetTradeSkillNumReagents, DoTradeSkill = Keep[1], Keep[2], Keep[3], Keep[4], Keep[5]
		end
		GetTradeSkillSubClasses = function() return 'A', 'B' end
		GetTradeSkillInvSlots = function() return 'S' end
		GetTradeSkillSubClassFilter = function(I) return I == FilterSub end
		GetTradeSkillInvSlotFilter = function(I) return I == FilterSlot end
		SetTradeSkillSubClassFilter = function(I) FilterSub = I; Changes = Changes + 1; Selection = 0 end
		SetTradeSkillInvSlotFilter = function(I) FilterSlot = I; Changes = Changes + 1 end
		ExpandTradeSkillSubClass = function(I) Folded = {}; Changes = Changes + 1 end
		CollapseTradeSkillSubClass = function(I) Folded[View()[I].Name] = true; Changes = Changes + 1 end
		GetTradeSkillSelectionIndex = function() return Selection end
		SelectTradeSkill = function(I) Selection = I end
		TradeSkillInputBox = Frame('TradeSkillInputBox')
		TradeSkillInputBox.GetNumber = function() return 4 end
		local function Queue() return ATSW_Tasks[Realm][Me]['Cooking'] end

		local function Fresh()
			ATSWReagentsFrame._visible = false -- A child of ATSW's window, which is hidden here
			Reset(); ATSW_Options.QueueOpen = nil
			FilterSub, FilterSlot, Folded, Selection, Changes = 0, 0, {}, 2, 0
			Crafted = nil
			UseList()
			Open('Cooking')
			ATSW_Tasks[Realm][Me]['Cooking'] = {}
			ATSW_NecessaryReagents[Realm][Me] = {}
			ATSW_Command('disable')
			Changes = 0
		end

		Test('Q1 adding with no filters changes nothing about the list', function()
			Fresh()
			ATSWQueueAddButton:GetScript('OnClick')()
			EndList()
			Eq(Queue()[1].Name, 'Smelt Copper', 'name')
			Eq(Queue()[1].Amount, 4, 'amount from the stock box')
			Eq(Changes, 0, 'list changes')
			Eq(ATSW_Options.QueueOpen, true, 'sidebar opens')
			Eq(ATSWQueueFrame._visible, true, 'sidebar')
		end)
		Test('Q2 adding under a filter and a collapsed header restores both, and the selection', function()
			Fresh()
			FilterSub = 1; Selection = 3; Folded = {Other = true}
			ATSWQueueAddButton:GetScript('OnClick')()
			local Sub, Slot, Fold, Sel = FilterSub, FilterSlot, Folded.Other, Selection
			EndList()
			Eq(Queue()[1].Name, 'Smelt Bronze', 'name')
			Eq(Sub, 1, 'subclass filter')
			Eq(Slot, 0, 'slot filter')
			Eq(Fold, true, 'collapsed header')
			Eq(Sel, 3, 'selection')
		end)
		Test('Q3 Start crafts the right recipe even when its row is filtered out', function()
			Fresh()
			ATSW_Tasks[Realm][Me]['Cooking'] = {{Name = 'Smelt Dreamsteel', Amount = 2}}
			FilterSub = 1
			ATSWQueueStartButton:GetScript('OnClick')()
			local Sub = FilterSub
			EndList()
			Eq(Crafted[1], 'Smelt Dreamsteel', 'recipe crafted')
			Eq(Crafted[3], 5, 'with the whole list showing')
			Eq(Sub, 1, 'filter back')
			ATSW_StopProcessing()
		end)
		Test('Q4 a full batch counts down and finishes with ATSW\'s window closed', function()
			Fresh()
			ATSW_Tasks[Realm][Me]['Cooking'] = {{Name = 'Smelt Copper', Amount = 2}}
			ATSWQueueStartButton:GetScript('OnClick')()
			Fire('SPELLCAST_START', 'Smelt Copper', 3000)
			Eq(ATSW_QueueIsCrafting(), true, 'crafting')
			local function Done()
				if ATSWFrame.ClassicAPI then
					event, arg1, arg4 = 'UNIT_SPELLCAST_SUCCEEDED', 'player', 'Smelt Copper'
					ATSW_OnEvent()
				else
					Fire('CHAT_MSG_LOOT', 'You create: x.')
				end
			end
			Done()
			Eq(Queue()[1].Amount, 1, 'after one')
			Fire('SPELLCAST_START', 'Smelt Copper', 3000)
			Done()
			EndList()
			Eq(table.getn(Queue()), 0, 'done')
			Eq(ATSW_QueueIsCrafting(), false, 'stopped')
		end)
		Test('Q5 delete, stop, and a queue with nothing to craft', function()
			Fresh()
			ATSW_Tasks[Realm][Me]['Cooking'] = {{Name = 'Smelt Copper', Amount = 2}, {Name = 'Smelt Bronze', Amount = 1}}
			ATSWQueue.Update()
			this = ATSWQueueDelete1
			ATSWQueueDelete1:GetScript('OnClick')()
			Eq(Queue()[1].Name, 'Smelt Bronze', 'first deleted')
			ATSWQueueStartButton:GetScript('OnClick')()
			Fire('SPELLCAST_START', 'Smelt Bronze', 3000)
			Eq(ATSW_QueueIsCrafting(), true, 'crafting')
			ATSWQueueStartButton:GetScript('OnClick')()
			Eq(ATSW_QueueIsCrafting(), false, 'Stop stopped it')
			local Info = GetTradeSkillReagentInfo
			GetTradeSkillReagentInfo = function() return 'Ore', 'tex', 1, 0 end
			Crafted = nil
			ATSWQueueStartButton:GetScript('OnClick')()
			GetTradeSkillReagentInfo = Info
			EndList()
			Eq(Crafted, nil, 'nothing crafted')
			assert(string.find(LastMessage(), 'reagents', 1, true), LastMessage())
		end)
		Test('Q7 Add to Queue greys out when no recipe is selected, and comes back', function()
			Fresh()
			Eq(ATSWQueueAddButton._enabled, true, 'recipe selected on opening')
			local function Tick() arg1 = 1; ATSWQueueToggleButton:GetScript('OnUpdate')() end
			-- The state in the screenshot: filtered to one header, collapsed, nothing to select
			FilterSub = 2; Folded = {Other = true}
			Tick()
			Eq(ATSWQueueAddButton._enabled, false, 'selection past the end of the list')
			Selection = 1
			Tick()
			Eq(ATSWQueueAddButton._enabled, false, 'selection on the header')
			Folded = {}; Selection = 2
			Tick()
			EndList()
			Eq(ATSWQueueAddButton._enabled, true, 'recipe selected again')
		end)
		Test('Q6 a failure while reading still restores the list', function()
			Fresh()
			FilterSub = 1
			local Add = ATSW_AddTask
			ATSW_AddTask = function() error('boom', 0) end
			local Good, Err = pcall(ATSWQueueAddButton:GetScript('OnClick'))
			ATSW_AddTask = Add
			local Sub = FilterSub
			EndList()
			Eq(Good, false, 'error passes on')
			Eq(Err, 'boom', 'the original error')
			Eq(Sub, 1, 'filter back')
		end)
		TradeSkillFrame:Hide()
		ATSW_Disabled = {}; ATSW_Options.QueueOpen = nil
		ATSW_Tasks[Realm][Me]['Cooking'] = {}
		FilterSub, FilterSlot, Folded = 0, 0, {}
	end

	-- Remaining review items
	local Sounds = 0
	Original_PlaySound = function(N) Sounds = Sounds + 1 end
	PlaySound = function(N) Sounds = Sounds + 100 end
	Test('R2 closing plays one sound; a loading screen plays none', function()
		Reset(); Open('Cooking')
		Sounds = 0
		Fire('TRADE_SKILL_CLOSE')
		Eq(Sounds, 1, 'close')
		Sounds = 0
		Fire('PLAYER_ENTERING_WORLD')
		Eq(Sounds, 0, 'loading screen')
	end)
	Test('R3 redrawing does not rescan the spellbook for the profession icon', function()
		Reset(); Open('Cooking')
		ATSW_GetRecipes(true)
		assert(ATSWRecipe2.Position, 'no recipe rows to draw')
		local Scans = 0
		local Real = GetSpellName
		GetSpellName = function(I, B) Scans = Scans + 1; return Real(I, B) end
		ATSW_UpdateRecipes(); ATSW_UpdateRecipes(); ATSW_UpdateRecipes()
		GetSpellName = Real
		Eq(Scans, 0, 'spellbook lookups')
	end)
	Test('R4 Jewelcrafting tools get their icons', function()
		local Asked = {}
		GetItemInfo = function(ID) Asked[ID] = true; return 'n','l',1,1,'t','s',1,'',"tex" end
		GetTradeSkillTools = function() return 'Jewelry Lens', 1, 'Jewelry Scope', nil end
		Reset(); Open('Cooking'); ATSW_GetRecipes(true)
		ATSW_SelectRecipe('Smelt Copper')
		GetTradeSkillTools = Noop; GetItemInfo = Noop
		Eq(Asked[41326], true, 'lens')
		Eq(Asked[41327], true, 'scope')
	end)
	Test('R5 the shopping list follows whichever auction window is showing', function()
		local Points = {}
		ATSWShoppingListFrame.SetPoint = function(S, A, W, B, X, Y) Points = {A, W, B, X, Y} end
		ATSW_NecessaryReagents[Realm][Me] = {{Name = 'Ore', Amount = 1}}
		ATSW_Options.DisplayShoppingList = true
		rawset(_G, 'AuctionFrame', Frame('AuctionFrame')); AuctionFrame._visible = true
		rawset(_G, 'AegisExchangeFrame', Frame('Aegis'))
		ATSWShoppingListFrame.AttachedTo = nil
		ATSW_ShowAuctionShoppingList()
		Eq(Points[2], AuctionFrame, 'stock window first')
		AuctionFrame._visible = false; AegisExchangeFrame._visible = true
		ATSWShoppingListFrame._scripts = nil
		ATSW_AttachShoppingList()
		Eq(Points[2], AegisExchangeFrame, 'Aegis takes over')
		Eq(Points[1], 'TOPRIGHT', 'point')
		Points = {}
		ATSW_AttachShoppingList()
		Eq(Points[2], nil, 'no re-anchoring every frame')
		AegisExchangeFrame._visible = false; AuctionFrame._visible = true
		ATSW_AttachShoppingList()
		Eq(Points[2], AuctionFrame, 'back to stock')
		rawset(_G, 'AuctionFrame', nil); rawset(_G, 'AegisExchangeFrame', nil)
		ATSW_NecessaryReagents[Realm][Me] = {}
		ATSWShoppingListFrame.SetPoint = Noop
	end)
	Test('R6 the shopping list opens on the Aegis window alone', function()
		ATSW_NecessaryReagents[Realm][Me] = {{Name = 'Ore', Amount = 1}}
		rawset(_G, 'AegisExchangeFrame', Frame('Aegis')); AegisExchangeFrame._visible = true
		ATSWShoppingListFrame._visible = false
		ATSW_ShowAuctionShoppingList()
		Eq(ATSWShoppingListFrame._visible, true, 'list')
		rawset(_G, 'AegisExchangeFrame', nil)
		ATSW_NecessaryReagents[Realm][Me] = {}
		ATSWShoppingListFrame._visible = false
	end)

	-- Bag updates
	local Redraws, Saves = 0, 0
	local RealUpdate, RealSave = ATSW_UpdateRecipes, ATSW_SaveBag
	ATSW_UpdateRecipes = function() Redraws = Redraws + 1; return RealUpdate() end
	ATSW_SaveBag = function(B) Saves = Saves + 1; return RealSave(B) end
	local BankScans = 0
	GetContainerNumSlots = function(B) if B == 5 then BankScans = BankScans + 1 end return 0 end
	ATSWFrame._reg = {}
	ATSW_OnLoad()
	local function Burst()
		Redraws, Saves, BankScans = 0, 0, 0
		for I = 1, 12 do Fire('BAG_UPDATE', 1) end
	end

	if os.getenv('NOCAPI') then
		Test('B3 without ClassicAPI each BAG_UPDATE still redraws', function()
			Eq(ATSWFrame._reg.BAG_UPDATE_DELAYED, nil, 'registered')
			Burst()
			Eq(Saves, 12, 'bag saves')
			assert(Redraws >= 12, 'redraws ' .. Redraws)
		end)
		Test('L3 without ClassicAPI windows open as normal', function()
			Open('Cooking')
			Eq(ATSWFrame._visible, true, 'ATSW')
		end)
		Test('C7 without ClassicAPI the loot message still counts, and closing stops tracking', function()
			Reset(); Open('Smelting')
			ATSW_GetRecipes(true)
			ATSW_Tasks[Realm][Me]['Smelting'] = {}
			ATSW_AddTask('Smelt Copper', 3)
			ATSW_Craft('Smelt Copper', 3)
			Fire('SPELLCAST_START', 'Smelt Copper', 3000)
			Fire('CHAT_MSG_LOOT', 'You create: Copper Bar.')
			Eq(ATSW_Tasks[Realm][Me]['Smelting'][1].Amount, 2, 'after one')
			Eq(ATSWFrame._reg.UNIT_SPELLCAST_SUCCEEDED, nil, 'registered')
			ATSW_Hide()
			Fire('CHAT_MSG_LOOT', 'You create: Copper Bar.')
			Eq(ATSW_Tasks[Realm][Me]['Smelting'][1].Amount, 1, 'after two')
			Eq(ATSWFrame._reg.SPELLCAST_START, false, 'stopped')
		end)
		Test('N3 without ClassicAPI Smelting is named from the last cast', function()
			Reset(); Open('Smelting')
			Eq(ATSW_Profession[Realm][Me], 'Smelting', 'profession')
		end)
	else
		Test('B1 a burst of bag updates saves every bag and redraws once', function()
			Eq(ATSWFrame._reg.BAG_UPDATE_DELAYED, true, 'registered')
			Open('Cooking')
			Burst()
			Eq(Saves, 12, 'bag saves')
			Eq(Redraws, 0, 'redraws before the delayed event')
			Fire('BAG_UPDATE_DELAYED')
			assert(Redraws > 0, 'no redraw')
			local One = Redraws
			Burst(); Fire('BAG_UPDATE_DELAYED')
			Eq(Redraws, One, 'same work per burst')
		end)
		Test('B2 at the bank, the bank is rescanned once per burst', function()
			Fire('BANKFRAME_OPENED')
			Burst()
			Eq(BankScans, 0, 'scans before the delayed event')
			Fire('BAG_UPDATE_DELAYED')
			Eq(BankScans, 1, 'scans')
			Fire('BANKFRAME_CLOSED')
		end)

		-- Profession links
		local TradeLinked, CraftLinked
		IsTradeSkillLinked = function() return TradeLinked, TradeLinked and 'Other' end
		IsCraftLinked = function() return CraftLinked, CraftLinked and 'Other' end

		Test('L1 a linked profession opens in the stock window, leaving ATSW untouched', function()
			Reset(); Open('Smelting')
			local Sizes = ATSW.RecipesSize[Realm][Me]['Smelting']
			TradeLinked = true
			Line = 'Tailoring'
			Fire('TRADE_SKILL_SHOW')
			Eq(TradeSkillFrame._visible, true, 'stock')
			Eq(ATSWFrame._visible, false, 'ATSW')
			Eq(ATSW_Profession[Realm][Me], 'Smelting', 'profession')
			Eq(ATSW.RecipesSize[Realm][Me]['Tailoring'], nil, 'recipes read')
			Eq(ATSW.RecipesSize[Realm][Me]['Smelting'], Sizes, 'own recipes')
			Eq(next(ATSW_Disabled), nil, 'saved')
		end)
		Test('L2 the commands refuse a linked window, and your own profession returns to ATSW', function()
			ATSW_Command('disable')
			assert(string.find(LastMessage(), 'another player'), LastMessage())
			ATSW_Command('enable')
			assert(string.find(LastMessage(), 'another player'), LastMessage())
			Eq(next(ATSW_Disabled), nil, 'saved')
			Eq(TradeSkillFrame._visible, true, 'still stock')
			local Before = Closes.Trade
			TradeLinked = nil
			Open('Cooking')
			Eq(ATSWFrame._visible, true, 'ATSW')
			Eq(TradeSkillFrame._visible, false, 'stock')
			Eq(Closes.Trade, Before, 'closes')
		end)
		Test('L4 a linked craft profession opens in the stock window', function()
			CraftLinked = true
			Fire('CRAFT_SHOW')
			Eq(CraftFrame._visible, true, 'stock craft')
			Eq(ATSWFrame._visible, false, 'ATSW')
			CraftLinked = nil
			CraftFrame:Hide()
			Eq(CraftFrame._events.CRAFT_UPDATE, nil, 'events returned')
			ATSW_Command('disable')
			assert(string.find(LastMessage(), 'Open a profession'), LastMessage())
		end)

		-- Counting crafts
		local function Tasks() return ATSW_Tasks[Realm][Me]['Smelting'] end
		local function Spell(E, Name, Unit) Fire(E, Unit or 'player'); end
		local function Cast(E, Name, Unit)
			event, arg1, arg2, arg3, arg4 = E, Unit or 'player', 'guid', 1, Name
			this = ATSWFrame
			ATSW_OnEvent()
		end
		local function Begin(Amount)
			Reset(); TradeLinked = nil; Open('Smelting')
			ATSW_GetRecipes(true)
			ATSW_Tasks[Realm][Me]['Smelting'] = {}
			ATSW_AddTask('Smelt Copper', Amount)
			ATSW_Craft('Smelt Copper', Amount)
			Fire('SPELLCAST_START', 'Smelt Copper', 3000)
		end
		local function Running() return ATSWFrame._reg.UNIT_SPELLCAST_SUCCEEDED == true end

		Test('C1 each successful cast counts once; the loot message adds nothing', function()
			Begin(3)
			Eq(Running(), true, 'listening')
			Cast('UNIT_SPELLCAST_SUCCEEDED', 'Smelt Copper')
			Fire('CHAT_MSG_LOOT', 'You create: Copper Bar.')
			Eq(Tasks()[1].Amount, 2, 'after one')
			Fire('SPELLCAST_START', 'Smelt Copper', 3000)
			Cast('UNIT_SPELLCAST_SUCCEEDED', 'Smelt Copper')
			Eq(Tasks()[1].Amount, 1, 'after two')
			ATSW_StopProcessing()
			Eq(Running(), false, 'stops listening')
		end)
		Test('C2 other spells and other units are ignored', function()
			Begin(3)
			Cast('UNIT_SPELLCAST_SUCCEEDED', 'Frostbolt')
			Cast('UNIT_SPELLCAST_SUCCEEDED', 'Smelt Copper', 'party1')
			Cast('UNIT_SPELLCAST_FAILED', 'Frostbolt')
			Cast('UNIT_SPELLCAST_FAILED', 'Smelt Copper', 'party1')
			Eq(Tasks()[1].Amount, 3, 'amount')
			Eq(Running(), true, 'still running')
			ATSW_StopProcessing()
		end)
		Test('C3 a failed cast stops the batch and keeps the task', function()
			Begin(3)
			Cast('UNIT_SPELLCAST_FAILED', 'Smelt Copper')
			Eq(Running(), false, 'stopped')
			Eq(Tasks()[1].Amount, 3, 'amount')
		end)
		Test('C4 closing the window keeps the count right, with the profession closed', function()
			Begin(3)
			ATSW_Hide()
			Eq(ATSWFrame._visible, false, 'closed')
			local N, M, I, R = GetNumTradeSkills, GetTradeSkillNumMade, GetTradeSkillInfo, GetTradeSkillNumReagents
			GetNumTradeSkills = function() return 0 end
			GetTradeSkillNumMade, GetTradeSkillInfo, GetTradeSkillNumReagents = Noop, Noop, Noop
			Cast('UNIT_SPELLCAST_SUCCEEDED', 'Smelt Copper')
			Eq(Tasks()[1].Amount, 2, 'after one')
			Fire('SPELLCAST_START', 'Smelt Copper', 3000)
			Cast('UNIT_SPELLCAST_SUCCEEDED', 'Smelt Copper')
			Eq(Tasks()[1].Amount, 1, 'after two')
			Fire('SPELLCAST_START', 'Smelt Copper', 3000)
			Cast('UNIT_SPELLCAST_SUCCEEDED', 'Smelt Copper')
			Eq(table.getn(Tasks()), 0, 'done')
			Eq(Running(), false, 'stopped')
			GetNumTradeSkills, GetTradeSkillNumMade, GetTradeSkillInfo, GetTradeSkillNumReagents = N, M, I, R
		end)
		Test('C5 a batch that ends silently stops after the timeout, and a new cast cancels it', function()
			Begin(3)
			Cast('UNIT_SPELLCAST_SUCCEEDED', 'Smelt Copper')
			ATSW_OnUpdate(0.01)
			Eq(Running(), true, 'inside the timeout')
			Fire('SPELLCAST_START', 'Smelt Copper', 3000)
			for I = 1, 20 do ATSW_OnUpdate(0.01) end
			Eq(Running(), true, 'next cast started')
			Cast('UNIT_SPELLCAST_SUCCEEDED', 'Smelt Copper')
			for I = 1, 20 do ATSW_OnUpdate(0.01) end
			Eq(Running(), false, 'timed out')
			Eq(Tasks()[1].Amount, 1, 'amount kept')
		end)
		Test('C6 the last craft flashes, then completes', function()
			Begin(1)
			Cast('UNIT_SPELLCAST_SUCCEEDED', 'Smelt Copper')
			Eq(ATSWProgressBar.Mode, ATSW_FLASH, 'mode')
			Eq(Tasks()[1].Amount, 1, 'not yet')
			local Alpha = 0
			ATSWProgressBarGlow.GetAlpha = function() return Alpha end
			ATSWProgressBarGlow.SetAlpha = function(S, A) Alpha = A end
			for I = 1, 200 do if Running() then ATSW_OnUpdate(0.05) end end
			Eq(table.getn(Tasks()), 0, 'done')
			Eq(Running(), false, 'stopped')
		end)
		Test('C8 an enchant waits for its cast event, not the timer', function()
			local Icon = GetTradeSkillIcon
			GetTradeSkillIcon = function() return 'Interface\\Icons\\Spell_Holy_GreaterHeal' end
			Begin(1)
			GetTradeSkillIcon = Icon
			ATSWProgressBar.EndTime = 0
			ATSW_OnUpdate(0.01)
			Eq(ATSWProgressBar.Mode, ATSW_CAST, 'still casting after the timer')
			Cast('UNIT_SPELLCAST_SUCCEEDED', 'Smelt Copper')
			Eq(ATSWProgressBar.Mode, ATSW_FLASH, 'flashes on the event')
			ATSW_StopProcessing()
		end)

		Test('R1 the progress bar estimates the casts actually left', function()
			Begin(3)
			-- This harness's clock ticks on every read, so hold it still to measure
			local Clock = GetTime
			GetTime = function() return 500 end
			Cast('UNIT_SPELLCAST_SUCCEEDED', 'Smelt Copper')
			local Left = ATSWProgressBar.EndTime - 500
			GetTime = Clock
			assert(math.abs(Left - 2 * 3.05) < 0.001, 'two casts left, estimate ' .. Left)
			ATSW_StopProcessing()
		end)

		-- Naming Smelting
		local Scans = 0
		ATSWActionNameTooltip.SetAction = function() Scans = Scans + 1 end
		ATSWActionNameTooltipTextLeft1.GetText = function() return 'Smelting' end
		local LinkSpell
		GetTradeSkillListLink = function() return LinkSpell and ('|cffffd000|Htrade:' .. LinkSpell .. ':100:300:AB:xx|h[Mining]|h|r') end
		GetSpellInfo = function(ID) if ID == 2656 then return 'Smelting' elseif ID == 2575 then return 'Mining' end end

		Test('N1 the link names Smelting even after casting something else', function()
			Reset(); LinkSpell = 2656; Open('Smelting')
			CastSpellByName('Frostbolt')
			Fire('TRADE_SKILL_SHOW')
			Eq(ATSW_Profession[Realm][Me], 'Smelting', 'profession')
		end)
		Test('N2 a link that says Mining falls back to the last cast', function()
			Reset(); LinkSpell = 2575
			CastSpellByName('Smelting')
			Line = 'Mining'
			Fire('TRADE_SKILL_SHOW')
			Eq(ATSW_Profession[Realm][Me], 'Smelting', 'profession')
		end)
		Test('N4 action bar presses do no tooltip scan until the name is needed', function()
			Reset(); LinkSpell = nil
			Scans = 0
			for I = 1, 5 do UseAction(I) end
			Eq(Scans, 0, 'scans after presses')
			Line = 'Mining'
			Fire('TRADE_SKILL_SHOW')
			Eq(Scans, 1, 'scans once needed')
			Eq(ATSW_Profession[Realm][Me], 'Smelting', 'profession')
		end)
	end
end
