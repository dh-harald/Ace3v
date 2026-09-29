--[[
Name: LibVanillaDurations-1.0
Author(s): dh-harald
Description: Aura names and durations for the 1.12.1 client and Unreal
             Azeroth, where UnitDebuff returns neither a name nor a
             duration (only texture, stacks and dispel type).
Dependencies: LibStub

How it works (after pfUI's libdebuff):
  * The name comes from a hidden tooltip, SetUnitDebuff(unit, index), with
    the UNFILTERED index -- the index UnitDebuff(unit, index) uses without
    its third argument. Unreal Azeroth ignores SetUnitDebuff's filter
    argument, so a filtered index would name the wrong debuff there.
  * The duration comes from the spell-name table in Durations.lua (pfUI's,
    English names). A spell without an entry has no timer.
  * The start is stamped when a scan of a unit finds the debuff, keyed by
    the unit's NAME (1.12 has no GUIDs). The stamp is EXACT (to the scan
    interval) when the previous scan of the same unit, no longer than
    KNOWN_WINDOW before, did not have it: the debuff was seen landing.
    Otherwise it is ESTIMATED -- the first scan of the unit (after a login
    or a reload, too), or a debuff that was already there -- and counts
    its full duration from that moment. Every timing call returns the
    flag; an addon that only wants real times ignores estimated ones.
    Keeping a unit scanned (CheckUnit) is what lets its next debuff be
    seen landing.
  * Another caster's multi-rank spell counts as its highest rank: the
    client tells no rank.
  * A stamp is dropped when a full scan of the unit no longer finds the
    debuff (dispelled, faded early, died), so a debuff applied again starts
    over. A stamp set with SetStamp(..., mine) survives scans without the
    debuff for STAMP_GRACE seconds: an addon may stamp its own cast before
    the aura lands.
  * A stamp that has run out while the debuff is still there is renewed as
    ESTIMATED: the debuff was refreshed at an unknown moment.

API:
  lib:GetDuration(name [, rank])        -> seconds, or nil
  lib:GetDebuff(unit, index)            -> name, timeLeft, duration, start,
                                           estimated
                                           (index as in UnitDebuff(unit, index);
                                           timeLeft etc. nil without a duration)
  lib:GetDebuffName(unit, index)        -> name, or nil
  lib:GetTimeLeft(unit, name)           -> timeLeft, duration, start,
                                           estimated, or nil
  lib:SetStamp(unitName, name, start, duration, mine, estimated)
                                           (mine, estimated: optional)
  lib:GetStamp(unitName, name)          -> start, duration, mine, estimated,
                                           or nil
  lib:CheckUnit(unit)                   -- rescans the unit if its scan is stale
  lib:UpdateUnit(unit)                  -- rescans the unit now

Unit scans are cached per unit id for CACHE_TTL seconds; UNIT_AURA for the
unit, a target change and a roster change end the cache early.
]]

local MAJOR, MINOR = "LibVanillaDurations-1.0", 1

local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

local _G = _G or getfenv()

local MAX_DEBUFFS = 16
local CACHE_TTL = 1
local STAMP_GRACE = 1
-- A debuff missing from a scan at most this old, and present in the next
-- one, was seen landing.
local KNOWN_WINDOW = 3
local TOOLTIP_NAME = "LibVanillaDurationsTooltip"

lib.durations = lib.durations or {}
-- stamps[unitName][spellName] = { start, duration, mine, estimated, time }
lib.stamps = lib.stamps or {}
-- units[unitId] = { time, dirty, unitName, names = {}, textures = {},
-- present = { [spellName] = true } }
lib.units = lib.units or {}

-- Durations

function lib:GetDuration(name, rank)
	local ranks = name and self.durations[name]
	if not ranks then return nil end

	local duration = rank and ranks[rank]
	if not duration then duration = ranks[0] end
	if not duration then
		local best, r, d = -1
		for r, d in pairs(ranks) do
			if r > best then
				best = r
				duration = d
			end
		end
	end
	if duration and duration > 0 then return duration end
	return nil
end

-- Tooltip

local tooltip

local function ScanDebuffName(unit, index)
	if not tooltip then
		local ok, tip = pcall(CreateFrame, "GameTooltip", TOOLTIP_NAME, nil, "GameTooltipTemplate")
		if not ok or not tip then return nil end
		tooltip = tip
	end

	-- The owner is set on every scan: hiding a tooltip clears its owner, and
	-- an ownerless tooltip is not filled.
	pcall(tooltip.SetOwner, tooltip, UIParent, "ANCHOR_NONE")
	pcall(tooltip.ClearLines, tooltip)
	local name
	if pcall(tooltip.SetUnitDebuff, tooltip, unit, index) then
		local line = _G[TOOLTIP_NAME .. "TextLeft1"]
		name = line and line:GetText()
	end
	-- A filled tooltip is shown; it would stay on screen.
	pcall(tooltip.Hide, tooltip)

	if name == "" then name = nil end
	return name
end

-- Stamps

function lib:SetStamp(unitName, name, start, duration, mine, estimated)
	if not unitName or not name then return end
	local stamps = self.stamps[unitName]
	if not stamps then
		stamps = {}
		self.stamps[unitName] = stamps
	end
	stamps[name] = {
		start = start,
		duration = duration,
		mine = mine and true or nil,
		estimated = estimated and true or nil,
		time = GetTime(),
	}
end

function lib:GetStamp(unitName, name)
	local stamps = unitName and self.stamps[unitName]
	local stamp = stamps and name and stamps[name]
	if not stamp then return nil end
	return stamp.start, stamp.duration, stamp.mine, stamp.estimated
end

-- The stamp of `name` on the unit named `unitName`, created now when there
-- is none, or renewed when it ran out while the debuff is still there
-- (then always estimated). `seenLanding`: the caller saw the debuff
-- appear, so a new stamp is exact.
local function CurrentStamp(self, unitName, name, seenLanding)
	local duration = self:GetDuration(name)
	if not duration then return nil end

	local stamps = self.stamps[unitName]
	local stamp = stamps and stamps[name]
	local now = GetTime()
	if not stamp then
		self:SetStamp(unitName, name, now, duration, nil, not seenLanding)
		stamp = self.stamps[unitName][name]
	elseif stamp.start + stamp.duration <= now then
		self:SetStamp(unitName, name, now, duration, nil, true)
		stamp = self.stamps[unitName][name]
	end
	return stamp
end

-- Unit scans

local function Cache(self, unit)
	local cache = self.units[unit]
	if not cache then
		cache = { time = 0, dirty = true, names = {}, textures = {} }
		self.units[unit] = cache
	end
	return cache
end

-- Reads every debuff slot of the unit (not only up to the first empty one:
-- on Unreal Azeroth a debuff can follow an empty slot), names them, stamps
-- the new ones and drops the stamps of the ones that are gone. A slot keeps
-- its name without a new tooltip scan while its texture and the unit are
-- unchanged and no UNIT_AURA arrived since. A debuff counts as seen landing
-- when the previous scan was of the same unit, at most KNOWN_WINDOW ago,
-- and did not have it.
function lib:UpdateUnit(unit)
	local cache = Cache(self, unit)
	local unitName = UnitName(unit)
	local now = GetTime()
	local sameUnit = cache.unitName == unitName
	local reuse = not cache.dirty and sameUnit
	local previous = sameUnit and now - cache.time <= KNOWN_WINDOW and cache.present
	local names, textures = cache.names, cache.textures
	local present = {}

	local i
	for i = 1, MAX_DEBUFFS do
		local texture = UnitDebuff(unit, i)
		local name
		if texture then
			if reuse and textures[i] == texture then
				name = names[i]
			else
				name = ScanDebuffName(unit, i)
			end
			if name then present[name] = true end
		end
		textures[i] = texture
		names[i] = name
	end

	cache.unitName = unitName
	cache.time = now
	cache.dirty = false
	cache.present = present

	if not unitName then return end
	local name
	for name in pairs(present) do
		CurrentStamp(self, unitName, name, previous and not previous[name])
	end
	local stamps = self.stamps[unitName]
	if stamps then
		local stamp
		for name, stamp in pairs(stamps) do
			if not present[name] and not (stamp.mine and now - (stamp.time or 0) <= STAMP_GRACE) then
				stamps[name] = nil
			end
		end
	end
end

local function FreshCache(self, unit)
	local cache = self.units[unit]
	if not cache or cache.dirty or GetTime() - cache.time > CACHE_TTL then
		self:UpdateUnit(unit)
		cache = self.units[unit]
	end
	return cache
end

function lib:CheckUnit(unit)
	if unit then FreshCache(self, unit) end
end

function lib:GetDebuffName(unit, index)
	if not unit or not index then return nil end
	return FreshCache(self, unit).names[index]
end

-- A name never scanned on the unit gets an estimated stamp here.
function lib:GetTimeLeft(unit, name)
	local unitName = unit and UnitName(unit)
	if not unitName or not name then return nil end
	local stamp = CurrentStamp(self, unitName, name, false)
	if not stamp then return nil end
	return stamp.start + stamp.duration - GetTime(), stamp.duration, stamp.start, stamp.estimated
end

function lib:GetDebuff(unit, index)
	local name = self:GetDebuffName(unit, index)
	if not name then return nil end
	local timeLeft, duration, start, estimated = self:GetTimeLeft(unit, name)
	return name, timeLeft, duration, start, estimated
end

-- Events

-- Every cached unit, or only those last seen with the name `unitName`.
local function MarkDirty(self, unitName)
	local unit, cache
	for unit, cache in pairs(self.units) do
		if not unitName or cache.unitName == unitName then
			cache.dirty = true
		end
	end
end

local function OnEvent()
	if event == "UNIT_AURA" then
		local cache = arg1 and lib.units[arg1]
		if cache then cache.dirty = true end
		-- The player's own aura events arrive as "player" only, not as the
		-- raid or party id that also points at the player.
		if arg1 == "player" then MarkDirty(lib, UnitName("player")) end
	elseif event == "PLAYER_TARGET_CHANGED" then
		local cache = lib.units.target
		if cache then cache.dirty = true end
	else
		MarkDirty(lib)
	end
end

-- Registering again on an upgrade is harmless; UnregisterAllEvents does not
-- work on Unreal Azeroth.
lib.frame = lib.frame or CreateFrame("Frame")
lib.frame:RegisterEvent("UNIT_AURA")
lib.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
lib.frame:RegisterEvent("RAID_ROSTER_UPDATE")
lib.frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
lib.frame:SetScript("OnEvent", OnEvent)
