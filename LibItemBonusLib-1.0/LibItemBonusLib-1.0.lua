--[[
	Name: LibItemBonusLib-1.0
	Revision: $Rev: 1 $
	Ported from: ItemBonusLib-1.0 r17465
	Description: Collects stat bonuses from equipped items, including set bonuses.
	Dependencies: LibStub, CallbackHandler-1.0, AceCore-3.0, AceEvent-3.0,
	              AceTimer-3.0, AceBucket-3.0, AceConsole-3.0, AceLocale-3.0,
	              LibGratuity-2.0, LibDeformat-2.0
	Note: Ace3v port of ItemBonusLib-1.0, API-compatible. The Ace2 original was an
	      AceAddon-2.0 object; this is a plain LibStub library.
]]

local MAJOR, MINOR = "LibItemBonusLib-1.0", 1

local ItemBonusLib = LibStub:NewLibrary(MAJOR, MINOR)

if not ItemBonusLib then return end -- No upgrade needed

-- AceConsole-3.0 prefixes every Print/Printf line with tostring(self).
setmetatable(ItemBonusLib, { __tostring = function() return "ItemBonusLib" end })

LibStub("AceEvent-3.0"):Embed(ItemBonusLib)
LibStub("AceTimer-3.0"):Embed(ItemBonusLib)
LibStub("AceBucket-3.0"):Embed(ItemBonusLib)
LibStub("AceConsole-3.0"):Embed(ItemBonusLib)
ItemBonusLib.callbacks = ItemBonusLib.callbacks or LibStub("CallbackHandler-1.0"):New(ItemBonusLib)

local Gratuity = LibStub("LibGratuity-2.0")
local Deformat = LibStub("LibDeformat-2.0")

-- The Locales-*.lua files only store their tables in LibItemBonusLib_Locales;
-- they are registered here, so they carry no dependency of their own. Unreal
-- Azeroth has been seen running those files ahead of every other script of the
-- same Load XML, before AceLocale-3.0 was loaded.
do
	local AceLocale = LibStub("AceLocale-3.0")
	local tables = LibItemBonusLib_Locales or {}
	local locales = { "enUS", "deDE", "esES", "frFR", "ruRU", "zhCN" }
	for i = 1, table.getn(locales) do
		local locale = locales[i]
		local T = tables[locale]
		local loc = T and AceLocale:NewLocale("ItemBonusLib", locale, locale == "enUS")
		if loc then
			for k, v in pairs(T) do loc[k] = v end
		end
	end
	LibItemBonusLib_Locales = nil
end

local L = LibStub("AceLocale-3.0"):GetLocale("ItemBonusLib")

-- Lua APIs
local tinsert, tconcat, tgetn = table.insert, table.concat, table.getn
local strfmt, strfind, strsub, strlen, strgsub = string.format, string.find, string.sub, string.len, string.gsub
local type, pairs, ipairs, error = type, pairs, ipairs, error

local DEBUG = false

-- bonuses[BONUS] = VALUE
local bonuses = {}

-- details[BONUS][SLOT] = VALUE
local details = {}

-- items[LINK].bonuses[BONUS] = VALUE
-- items[LINK].set = SETNAME
-- items[LINK].set_line = number
local items = {}

-- sets[SETNAME].count = COUNT
-- sets[SETNAME].bonuses[NUM][BONUS] = VALUE
-- sets[SETNAME].scan_count = COUNT
-- sets[SETNAME].scan_bonuses = COUNT
local sets = {}

local slots = {
	["Head"] = true,
	["Neck"] = true,
	["Shoulder"] = true,
	["Shirt"] = true,
	["Chest"] = true,
	["Waist"] = true,
	["Legs"] = true,
	["Feet"] = true,
	["Wrist"] = true,
	["Hands"] = true,
	["Finger0"] = true,
	["Finger1"] = true,
	["Trinket0"] = true,
	["Trinket1"] = true,
	["Back"] = true,
	["MainHand"] = true,
	["SecondaryHand"] = true,
	["Ranged"] = true,
	["Tabard"] = true,
}

-- Ace3v: replaces AceDebug-2.0
function ItemBonusLib:SetDebugging(debugging)
	DEBUG = debugging and true or false
end

function ItemBonusLib:IsDebugging()
	return DEBUG
end

function ItemBonusLib:Debug(a1, a2, a3, a4, a5)
	if not DEBUG then return end
	if a2 ~= nil and strfind(a1, "%%") then
		a1 = strfmt(a1, a2, a3, a4, a5)
	end
	self:Print("|cffff7f3f[debug]|r " .. a1)
end

ItemBonusLib:SetDebugging(DEBUG)

------------------------------------------------
-- Chat command
------------------------------------------------

-- Ace3v: AceConsole-2.0 took an option table and derived the subcommands from
-- the localized `name` fields. AceConsole-3.0 only registers a plain handler, so
-- the same subcommands are dispatched here, keeping the localized words.
local function ShowBonuses(self)
	self:Print(L["Current equipment bonuses:"])
	for bonus, value in pairs(bonuses) do
		self:Printf("%s : %d", self:GetBonusFriendlyName(bonus), value)
	end
end

local function ShowDetails(self)
	self:Print(L["Current equipment bonus details:"])
	for bonus, detail in pairs(details) do
		-- ScanEquipment empties a detail table but keeps its key, so a bonus that
		-- is no longer on the equipment has a detail entry and no total.
		if bonuses[bonus] then
			local s = {}
			for slot, value in pairs(detail) do
				tinsert(s, strfmt("%s : %d", slot, value))
			end
			self:Printf("%s : %d (%s)", self:GetBonusFriendlyName(bonus), bonuses[bonus], tconcat(s, ", "))
		end
	end
end

local function ShowItem(self, link)
	local info = self:ScanItemLink(link)
	self:Printf(L["Bonuses for %s:"], link)
	for bonus, value in pairs(info.bonuses) do
		self:Printf("%s : %d", self:GetBonusFriendlyName(bonus), value)
	end
	if info.set then
		self:Printf(L["Item is part of set [%s]"], info.set)
		local set = sets[info.set]
		for number, setbonuses in pairs(set.bonuses) do
			local has_bonus = number <= set.count and "*" or " "
			self:Printf(L[" %sBonus for %d pieces :"], has_bonus, number)
			for bonus, value in pairs(setbonuses) do
				self:Printf("    %s : %d", self:GetBonusFriendlyName(bonus), value)
			end
		end
	end
end

local function ShowSlot(self, slot)
	self:Printf(L["Bonuses of slot %s:"], slot)
	for bonus, detail in pairs(details) do
		if detail[slot] then
			self:Printf("%s : %d", self:GetBonusFriendlyName(bonus), detail[slot])
		end
	end
end

function ItemBonusLib:ChatCommand(input)
	-- GetArgs keeps item links in one piece, which matters for the "item" command
	local cmd, rest = self:GetArgs(input, 2, 1)
	if cmd == L["show"] then
		ShowBonuses(self)
	elseif cmd == L["details"] then
		ShowDetails(self)
	elseif cmd == L["item"] and rest then
		ShowItem(self, rest)
	elseif cmd == L["slot"] and rest then
		ShowSlot(self, rest)
	else
		self:Print(L["An addon to get information about bonus from equipped items"])
		self:Printf("  %s - %s", L["show"], L["Show all bonuses from the current equipment"])
		self:Printf("  %s - %s", L["details"], L["Shows bonuses with slot distribution"])
		self:Printf("  %s %s - %s", L["item"], L["<itemlink>"], L["show bonuses of given itemlink"])
		self:Printf("  %s %s - %s", L["slot"], L["<slotname>"], L["show bonuses of given slot"])
	end
end

------------------------------------------------
-- Startup
------------------------------------------------

function ItemBonusLib:OnInitialize()
	if self.initialized then return end
	self.initialized = true

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_LEAVING_WORLD")
	for s in pairs(slots) do
		slots[s] = GetInventorySlotInfo (s.."Slot")
	end

	for _, cmd in ipairs(L.CHAT_COMMANDS) do
		self:RegisterChatCommand(strgsub(cmd, "^/", ""), "ChatCommand")
	end
end

function ItemBonusLib:PLAYER_ENTERING_WORLD()
	if not self.bucket then
		self.bucket = self:RegisterBucketEvent("UNIT_INVENTORY_CHANGED", 0.5)
	end
	self:ScheduleTimer(function() ItemBonusLib:ScanEquipment() end, 1, 0)
end

function ItemBonusLib:PLAYER_LEAVING_WORLD()
	if self.bucket then
		self:UnregisterBucket(self.bucket)
		self.bucket = nil
	end
end

function ItemBonusLib:UNIT_INVENTORY_CHANGED(units)
	if units.player then
		self:ScanEquipment()
	end
end

local cleanItemLink
do
	local trim = function (str)
		str = strgsub (str, "^%s+", "" )
		str = strgsub (str, "%s+$", "" )
		str = strgsub (str, "%.$", "" )
		return str
	end

	local equip = ITEM_SPELL_TRIGGER_ONEQUIP
	local l_equip = strlen(equip)

	function cleanItemLink(itemLink)
		local _, _, link = strfind(itemLink, "|c%x+|H(item:%d+:%d+:%d+:%d+)|h%[.-%]|h|r")
		return link or itemLink
	end

	function ItemBonusLib:AddValue(bonuses, effect, value)
		if type(effect) == "string" then
			bonuses[effect] = (bonuses[effect] or 0) + value
		elseif type(value) == "table" then
			for i, e in ipairs(effect) do
				self:AddValue (bonuses, e, value[i])
			end
		else
			for _, e in ipairs(effect) do
				self:AddValue (bonuses, e, value)
			end
		end
	end

	function ItemBonusLib:CheckPassive(bonuses, line)
		for _, p in pairs(L.PATTERNS_PASSIVE) do
			local _, _, value = strfind (line, "^" .. p.pattern)
			if value then
				self:AddValue (bonuses, p.effect, value)
				return true
			end
		end
	end

	function ItemBonusLib:CheckToken(bonuses, token, value)
		local t = L.PATTERNS_GENERIC_LOOKUP[token]
		if t then
			self:AddValue (bonuses, t, value)
			return true
		else
			local s1, s2

			for _, p in ipairs(L.PATTERNS_GENERIC_STAGE1) do
				if strfind (token, p.pattern, 1, 1) then
					s1 = p.effect
					break
				end
			end
			for _, p in ipairs(L.PATTERNS_GENERIC_STAGE2) do
				if strfind(token, p.pattern, 1, 1) then
					s2 = p.effect
					break
				end
			end
			if s1 and s2 then
				self:AddValue (bonuses, s1..s2, value)
				return true
			end
		end
		self:Debug("CheckToken failed for \"%s\" (%d)", token, value)
	end

	function ItemBonusLib:CheckGeneric(bonuses, line)
		local found

		while strlen(line) > 0 do
			local tmpStr
			local pos = strfind (line, "/", 1, true)
			if pos then
				tmpStr = strsub (line, 1, pos-1)
				line = strsub (line, pos+1)
			else
				tmpStr = line
				line = ""
			end

			-- trim line
			tmpStr = trim (tmpStr)

			local _, _, value, token = strfind(tmpStr, "^%+(%d+)%%?(.*)$")
			if not value then
				_, _,  token, value = strfind(tmpStr, "^(.*)%+(%d+)%%?$")
			end
			if token and value then
				-- trim token
				token = trim (token)
				if self:CheckToken (bonuses, token, value) then
					found = true
				end
			end
		end
		return found
	end

	function ItemBonusLib:CheckOther(bonuses, line)
		for _, p in ipairs(L.PATTERNS_OTHER) do
			local start, _, value = strfind (line, "^" .. p.pattern)
			if start then
				if p.value then
					self:AddValue(bonuses, p.effect, p.value)
				elseif value then
					self:AddValue (bonuses, p.effect, value)
				end
				return true
			end
		end
	end

	function ItemBonusLib:AddBonusInfo(bonuses, line, no_prefix)
		local found
		if no_prefix then
			found = self:CheckPassive(bonuses, line)
		elseif strsub (line, 0, l_equip) == equip then
			-- Ace3v: ItemBonusLib-1.0 used l_equip + 2, assuming exactly one space
			-- after the colon. zhCN's prefix is "\232\163\133\229\164\135\239\188\154" with no
			-- trailing space, so that skipped one byte too many and produced a
			-- broken UTF-8 fragment which no pattern could match. Skip exactly the
			-- prefix, then drop any leading whitespace.
			found = self:CheckPassive (bonuses, strgsub(strsub(line, l_equip + 1), "^%s+", ""))
		end
		if not found then
			found = self:CheckGeneric(bonuses, line)
			if not found then
				found = self:CheckOther(bonuses, line)
				if not found then
					self:Debug("Unmatched bonus line \"%s\"", line)
				end
			end
		end
	end
end

do
	local ITEM_SET_NAME = ITEM_SET_NAME
	local ITEM_SET_BONUS = ITEM_SET_BONUS
	local ITEM_SET_BONUS_GRAY = ITEM_SET_BONUS_GRAY

	-- With `slot` (an inventory slot id of an equipped item) the tooltip is
	-- loaded with SetInventoryItem instead of SetHyperlink: Unreal Azeroth's
	-- SetHyperlink ignores the random-property field of "item:id:ench:rand:0",
	-- so a "... of the Owl" item shows as its base item, without the suffix stats.
	local function loadTooltip(link, slot)
		if slot then
			Gratuity:SetInventoryItem("player", slot)
		else
			Gratuity:SetHyperlink(link)
		end
	end

	function ItemBonusLib:ScanItemLink(link, slot)
		link = cleanItemLink(link)
		local info = items[link]
		local scan_set
		local set_name, set_count, set_total
		if not info then
			info = { bonuses = {} }
			loadTooltip(link, slot)
			for i = 2, Gratuity:NumLines() do
				local line = Gratuity:GetLine(i)
				set_name, set_count, set_total = Deformat(line, ITEM_SET_NAME)
				if set_name then
					info.set = set_name
					info.set_line = i
					local set = sets[set_name]
					if not set or set.scan_count > set_count and set.scan_bonuses > 1 then
						scan_set = true
					end
					break
				end
				self:AddBonusInfo(info.bonuses, line)
			end
			items[link] = info
		elseif info.set then
			loadTooltip(link, slot)
			set_name, set_count, set_total = Deformat(Gratuity:GetLine(info.set_line), ITEM_SET_NAME)
			local set = sets[set_name]
			if set.scan_count > set_count and set.scan_bonuses > 1 then
				scan_set = true
			end
		end
		if scan_set then
			self:Debug("Scanning set \"%s\"", set_name)
			local set = { count = 0, bonuses = {}, scan_count = set_count, scan_bonuses = 0 }
			for i = info.set_line + set_total + 2, Gratuity:NumLines() do
				local line = Gratuity:GetLine(i)
				local count, bonus
				local bonus = Deformat(line, ITEM_SET_BONUS)
				if bonus then
					set.scan_bonuses = set.scan_bonuses + 1
					count = set_count
				else
					count, bonus = Deformat(
					line, ITEM_SET_BONUS_GRAY)
				end
				if not bonus then
					self:Debug("Invalid set line \"%s\"", line)
					-- break
				else
					local bonuses = set.bonuses[count] or {}
					self:AddBonusInfo(bonuses, bonus, true)
					set.bonuses[count] = bonuses
				end
			end
			sets[set_name] = set
		end
		return info
	end
end

function ItemBonusLib:ScanEquipment()
	-- clean bonus information
	for bonus in pairs(bonuses) do
		bonuses[bonus] = nil
	end
	for bonus, detail in pairs(details) do
		for slot in pairs(detail) do
			detail[slot] = nil
		end
	end
	for _, set in pairs(sets) do
		set.count = 0
	end

	for slot, id in pairs(slots) do
		local link = GetInventoryItemLink("player", id)
		-- Unreal Azeroth returns "item:0:0:0:0" for an empty slot instead of nil.
		local _, _, itemId = strfind(link or "", "item:(%d+)")
		if itemId and itemId ~= "0" then
			self:Debug("Scanning item %s", link)
			local info = self:ScanItemLink(link, id)
			local set = info.set
			if set then
				sets[set].count = sets[set].count + 1
			end
			for bonus, value in pairs(info.bonuses) do
				bonuses[bonus] = (bonuses[bonus] or 0) + value
				if not details[bonus] then
					details[bonus] = {}
				end
				details[bonus][slot] = (details[bonus][slot] or 0) + value
			end
		end
	end
	for _, set in pairs(sets) do
		for i = 2, set.count do
			if set.bonuses[i] then
				for bonus, value in pairs(set.bonuses[i]) do
					bonuses[bonus] = (bonuses[bonus] or 0) + value
					if not details[bonus] then
						details[bonus] = {}
					end
					details[bonus].Set = (details[bonus].Set or 0) + value
				end
			end
		end
	end
	self.callbacks:Fire("ItemBonusLib_Update", 0)
end

-- DEBUG
if DEBUG then
	function ItemBonusLib:DumpCachedItems(clear)
		DevTools_Dump(items)
		if clear then
			items = {}
		end
	end

	function ItemBonusLib:DumpCachedSets(clear)
		DevTools_Dump(sets)
	end

	function ItemBonusLib:DumpBonuses()
		DevTools_Dump(bonuses)
	end

	function ItemBonusLib:DumpDetails()
		DevTools_Dump(details)
	end

	function ItemBonusLib:Reload()
		items = {}
		sets = {}
		self:ScanEquipment()
	end
end

-- BonusScanner compatible API
function ItemBonusLib:GetBonus(bonus)
	return bonuses[bonus] or 0
end

function ItemBonusLib:GetSlotBonuses (slotname)
	local bonuses = {}
	for bonus, detail in pairs(details) do
		if detail[slotname] then
			bonuses[bonus] = detail[slotname]
		end
	end
	return bonuses
end

function ItemBonusLib:GetBonusDetails (bonus)
	return details[bonus] or {}
end

function ItemBonusLib:GetSlotBonus (bonus, slotname)
	local detail = details[bonus]
	return detail and detail[slotname] or 0
end

function ItemBonusLib:GetBonusFriendlyName (bonus)
	return L.NAMES[bonus] or bonus
end

function ItemBonusLib:IsActive ()
	return true
end

function ItemBonusLib:ScanItem (itemlink, excludeSet)
	if not excludeSet then
		error(MAJOR .. ": excludeSet can't be false on BonusScanner compatible API", 2)
	end
	local name, link = GetItemInfo(itemlink)
	if not name then
		return
	end
	return self:ScanItemLink(link).bonuses
end

function ItemBonusLib:ScanTooltipFrame (frame, excludeSet)
	error(MAJOR .. ": BonusScanner:ScanTooltipFrame() is not available", 2)
end

function ItemBonusLib:GetLibraryVersion()
	return MAJOR, MINOR
end

ItemBonusLib:OnInitialize()
