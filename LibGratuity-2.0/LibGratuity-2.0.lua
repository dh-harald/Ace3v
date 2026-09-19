--[[
	Name: LibGratuity-2.0
	Revision: $Rev: 1 $
	Ported from: Gratuity-2.0 r11054
	Author: Tekkub Stoutwrithe (tekkub@gmail.com), Ace3v port
	Description: Tooltip parsing library
	Dependencies: LibStub, (optional) LibDeformat-2.0
	Note: Ace3v port of Gratuity-2.0, API-compatible.
]]

local MAJOR, MINOR = "LibGratuity-2.0", 1

local lib = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then return end -- No upgrade needed

-- Lua APIs
local strfind, strgsub, strfmt = string.find, string.gsub, string.format
local tinsert = table.insert
local type, pairs, pcall, error = type, pairs, pcall, error
local setmetatable, rawset = setmetatable, rawset
local _G = _G or getfenv()

-- The scanning tooltip is built from GameTooltipTemplate and read through its
-- named line globals (<name>TextLeftN / <name>TextRightN). On Unreal Azeroth a
-- GameTooltip created without the template stays empty after any Set* call,
-- font strings added with AddFontStrings included, whoever owns it.
local TOOLTIP_NAME = "LibGratuity20Tooltip"

local methods = {
	"SetBagItem", "SetAction", "SetAuctionItem", "SetAuctionSellItem", "SetBuybackItem",
	"SetCraftItem", "SetCraftSpell", "SetHyperlink", "SetInboxItem", "SetInventoryItem",
	"SetLootItem", "SetLootRollItem", "SetMerchantItem", "SetPetAction", "SetPlayerBuff",
	"SetQuestItem", "SetQuestLogItem", "SetQuestRewardSpell", "SetSendMailItem", "SetShapeshift",
	"SetSpell", "SetTalent", "SetTrackingSpell", "SetTradePlayerItem", "SetTradeSkillItem", "SetTradeTargetItem",
	"SetTrainerService", "SetUnit", "SetUnitBuff", "SetUnitDebuff",
}

local function argCheck(value, num, kind, kind2)
	local t = type(value)
	if t ~= kind and t ~= kind2 then
		error(strfmt("%s: bad argument #%d (%s expected, got %s)", MAJOR, num, kind, t), 3)
	end
end

local function assert(cond, msg)
	if not cond then error(MAJOR .. ": " .. msg, 3) end
	return cond
end

-- AceLibrary injected a :pcall that re-raised failures with the file/line
-- prefix stripped; keep that behaviour for the generated Set* methods.
local function callTooltip(func, a1, a2, a3, a4, a5)
	local ok, r1, r2, r3, r4 = pcall(func, a1, a2, a3, a4, a5)
	if not ok then
		error(strgsub(r1, ".-%.lua:%d-: ", ""), 3)
	end
	return r1, r2, r3, r4
end

function lib:GetLibraryVersion()
	return MAJOR, MINOR
end

-- The template creates the first lines; the client adds <name>TextLeft9 and
-- up as the content needs them, so each line is looked up by name on first
-- use and remembered once it exists.
local function lineTable(side)
	return setmetatable({}, { __index = function(t, i)
		local fs = _G[TOOLTIP_NAME .. side .. i]
		if fs then rawset(t, i, fs) end
		return fs
	end })
end

function lib:CreateTooltip()
	local tt = _G[TOOLTIP_NAME] or CreateFrame("GameTooltip", TOOLTIP_NAME, nil, "GameTooltipTemplate")

	self.vars.tooltip = tt
	self.vars.tooltipName = TOOLTIP_NAME
	tt:SetOwner(UIParent, "ANCHOR_NONE")

	self.vars.Llines, self.vars.Rlines = lineTable("TextLeft"), lineTable("TextRight")
end


--	Clears the tooltip completely, none of this "erase left, hide right" crap blizzard does
function lib:Erase()
	self.vars.tooltip:ClearLines() -- Ensures tooltip's NumLines is reset
	for i=1,30 do -- Clear text from right side (ClearLines only hides them)
		local r = self.vars.Rlines[i]
		if r then r:SetText() end
	end
	if not self.vars.tooltip:IsOwned(UIParent) then self.vars.tooltip:SetOwner(UIParent, "ANCHOR_NONE") end
	assert(self.vars.tooltip:IsOwned(UIParent), "Gratuity's tooltip is not scanable")
end


-- Get the number of lines
-- Arg: endln - If passed and tooltip's NumLines is higher, endln is returned back
function lib:NumLines(endln)
	local num = self.vars.tooltip:NumLines()
	return endln and num > endln and endln or num or 0
end

local FindDefault = function(str, pattern)
	return strfind(str, pattern);
end;

local FindExact = function(str, pattern)
	if (str == pattern) then
		return strfind(str, pattern);
	end;
end;

--	If text is found on tooltip then results of string.find are returned
--  Args:
--    txt      - The text string to find
--    startln  - First tooltip line to check, default 1
--    endln    - Last line to test, default 30
--    ignoreleft / ignoreright - Causes text on one side of the tooltip to be ignored
--    exact	   - the compare will be an exact match vs the default behaviour of
function lib:Find(txt, startln, endln, ignoreleft, ignoreright, exact)
	local searchFunction = FindDefault;
	-- Ace3v: truthiness, not `exact == true`; clients differ on 1/nil vs true/false
	if exact then
		searchFunction = FindExact;
	end;
	argCheck(txt, 2, "string", "number")
	for i=(startln or 1),self:NumLines(endln) do
		if not ignoreleft then
			local txtl = self.vars.Llines[i]:GetText()
			if (txtl and searchFunction(txtl, txt)) then return strfind(txtl, txt) end
		end

		if not ignoreright then
			local txtr = self.vars.Rlines[i]:GetText()
			if (txtr and searchFunction(txtr, txt)) then return strfind(txtr, txt) end
		end
	end
end


--  Calls Find many times.
--  Args are passed directly to Find, t1-t10 replace the txt arg
--  Returns Find results for the first match found, if any
function lib:MultiFind(startln, endln, ignoreleft, ignoreright, t1,t2,t3,t4,t5,t6,t7,t8,t9,t10)
	argCheck(t1, 6, "string", "number")
	if t1 and self:Find(t1, startln, endln, ignoreleft, ignoreright) then return self:Find(t1, startln, endln, ignoreleft, ignoreright)
elseif t2 then return self:MultiFind(startln, endln, ignoreleft, ignoreright, t2,t3,t4,t5,t6,t7,t8,t9,t10) end
end


local deformat
--	If text is found on tooltip then results of deformat:Deformat are returned
--  Args:
--    txt      - The text string to deformat and serach for
--    startln  - First tooltip line to check, default 1
--    endln    - Last line to test, default 30
--    ignoreleft / ignoreright - Causes text on one side of the tooltip to be ignored
function lib:FindDeformat(txt, startln, endln, ignoreleft, ignoreright)
	argCheck(txt, 2, "string", "number")
	if not deformat then
		deformat = LibStub:GetLibrary("LibDeformat-2.0", true)
		assert(deformat, "FindDeformat requires LibDeformat-2.0 to be available")
	end

	for i=(startln or 1),self:NumLines(endln) do
		if not ignoreleft then
			local txtl = self.vars.Llines[i]:GetText()
			if (txtl and deformat(txtl, txt)) then return deformat(txtl, txt) end
		end

		if not ignoreright then
			local txtr = self.vars.Rlines[i]:GetText()
			if (txtr and deformat(txtr, txt)) then return deformat(txtr, txt) end
		end
	end
end


--	Returns a table of strings pulled from the tooltip, or nil if no strings in tooltip
--  Args:
--    startln  - First tooltip line to check, default 1
--    endln    - Last line to test, default 30
--    ignoreleft / ignoreright - Causes text on one side of the tooltip to be ignored
function lib:GetText(startln, endln, ignoreleft, ignoreright)
	local retval

	for i=(startln or 1),(endln or 30) do
		local txtl, txtr
		local l, r = self.vars.Llines[i], self.vars.Rlines[i]
		if not ignoreleft and l then txtl = l:GetText() end
		if not ignoreright and r then txtr = r:GetText() end
		if txtl or txtr then
			if not retval then retval = {} end
			tinsert(retval, {txtl, txtr})
		end
	end

	return retval
end


--	Returns the text from a specific line (both left and right unless second arg is true)
--  Args:
--    line     - the line number you wish to retrieve
--    getright - if passed the right line will be returned, if not the left will be returned
function lib:GetLine(line, getright)
	argCheck(line, 2, "number")
	if self.vars.tooltip:NumLines() < line then return end
	if getright then return self.vars.Rlines[line] and self.vars.Rlines[line]:GetText()
	elseif self.vars.Llines[line] then
		return self.vars.Llines[line]:GetText(), self.vars.Rlines[line]:GetText()
	end
end


-----------------------------------
--      Set tooltip methods      --
-----------------------------------

-- These methods are designed to immitate the GameTooltip API
local testmethods = {
	SetAction = function(id) return HasAction(id) end,
}
local gettrue = function() return true end
function lib:CreateSetMethods()
	for _,m in pairs(methods) do
		local meth = m
		local func = testmethods[meth] or gettrue
		self[meth] = function(self,a1,a2,a3,a4)
			self:Erase()
			if not func(a1,a2,a3,a4) then return end
		return callTooltip(self.vars.tooltip[meth], self.vars.tooltip,a1,a2,a3,a4) end
	end
end


--------------------------------
--      Load this bitch!      --
--------------------------------
lib.vars = lib.vars or {}
if not lib.vars.tooltip then lib:CreateTooltip() end
lib:CreateSetMethods()
