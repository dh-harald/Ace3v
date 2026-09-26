--[[
	Name: LibRosterLib-2.0
	Revision: $Rev: 1 $
	Ported from: RosterLib-2.0 r17213
	Author: Maia (maia.proudmoore@gmail.com), Ace3v port
	Description: party/raid roster management
	Dependencies: LibStub, CallbackHandler-1.0, AceCore-3.0, AceEvent-3.0, AceTimer-3.0
	Note: Ace3v port of RosterLib-2.0, API-compatible.
]]

local MAJOR, MINOR = "LibRosterLib-2.0", 2

local RosterLib, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not RosterLib then return end -- No upgrade needed

local AceCore = LibStub("AceCore-3.0")
local new, del = AceCore.new, AceCore.del

LibStub("AceEvent-3.0"):Embed(RosterLib)
LibStub("AceTimer-3.0"):Embed(RosterLib)
-- Vanilla: MINOR 1 fired with an argument count, Fire(event, argc, ...), and its registry may have been
-- built by a CallbackHandler with that Fire. Rebuild it, keeping the registrations.
if oldminor and oldminor < 2 and RosterLib.callbacks then
	local old = RosterLib.callbacks
	RosterLib.callbacks = LibStub("CallbackHandler-1.0"):New(RosterLib)
	for event, handlers in pairs(old.events) do
		for owner, func in pairs(handlers) do RosterLib.callbacks.events[event][owner] = func end
	end
end
RosterLib.callbacks = RosterLib.callbacks or LibStub("CallbackHandler-1.0"):New(RosterLib)

-- Lua APIs
local strfind, strgsub, strfmt = string.find, string.gsub, string.format
local next, pairs = next, pairs

-- Global vars/functions that we don't upvalue since they might get hooked
-- GLOBALS: UnitExists, UnitName, UnitClass, UnitIsConnected, UnitIsCharmed
-- GLOBALS: GetNumRaidMembers, GetNumPartyMembers, GetRaidRosterInfo
-- GLOBALS: UNKNOWNOBJECT, UNKNOWNBEING

local updatedUnits = {}
local unknownUnits = {}

RosterLib.roster = RosterLib.roster or {}
local roster = RosterLib.roster

local Initialize

function RosterLib:GetLibraryVersion()
	return MAJOR, MINOR
end

function RosterLib:Enable()
	-- not used anymore, but as addons still might be calling this method, we're keeping it.
end


function RosterLib:Disable()
	-- not used anymore, but as addons still might be calling this method, we're keeping it.
end

------------------------------------------------
-- Internal functions
------------------------------------------------

-- Ace3v: AceEvent-2.0's AceEvent_FullyInitialized has no Ace3 equivalent; we
-- start on PLAYER_LOGIN / PLAYER_ENTERING_WORLD, with the same 10s fallback
-- timer AceEvent-2.0 itself used for libraries loaded after login.
function Initialize()
	if RosterLib.initialized then return end
	RosterLib.initialized = true

	if RosterLib.initTimer then
		RosterLib:CancelTimer(RosterLib.initTimer)
		RosterLib.initTimer = nil
	end
	-- Ace3v: do NOT unregister PLAYER_LOGIN / PLAYER_ENTERING_WORLD here.
	-- We are inside their own dispatch, and CallbackHandler's dispatcher walks
	-- the handler table with next(); removing the current key breaks it with
	-- "invalid key for `next'". The `initialized` guard above makes the extra
	-- callbacks a no-op instead.

	RosterLib.callbacks:Fire("RosterLib_Enabled")
	RosterLib:RegisterEvent("RAID_ROSTER_UPDATE", "ScanFullRoster")
	RosterLib:RegisterEvent("PARTY_MEMBERS_CHANGED", "ScanFullRoster")
	RosterLib:RegisterEvent("UNIT_PET", "UNIT_PET")
	RosterLib:ScanFullRoster()
end

function RosterLib:AceEvent_FullyInitialized()
	Initialize()
end

function RosterLib:PLAYER_LOGIN()
	Initialize()
end

function RosterLib:PLAYER_ENTERING_WORLD()
	Initialize()
end

-- Ace3v: vanilla event arguments are globals, so the handler reads arg1 and
-- forwards it; ScanPet(owner) keeps its original signature for callers.
function RosterLib:UNIT_PET()
	self:ScanPet(arg1)
end


------------------------------------------------
-- Unit iterator
------------------------------------------------

local playersent, petsent, unitcount, petcount, pmem, rmem, unit

local function NextUnit()
	-- STEP 1: pet
	if not petsent then
		petsent = true
		if rmem == 0 then
			unit = "pet"
			if UnitExists(unit) then return unit end
		end
	end
	-- STEP 2: player
	if not playersent then
		playersent = true
		if rmem == 0 then
			unit = "player"
			if UnitExists(unit) then return unit end
		end
	end
	-- STEP 3: raid units
	if rmem > 0 then
		-- STEP 3a: pet units
		for i = petcount, rmem do
			unit = strfmt("raidpet%d", i)
			petcount = petcount + 1
			if UnitExists(unit) then return unit end
		end
		-- STEP 3b: player units
		for i = unitcount, rmem do
			unit = strfmt("raid%d", i)
			unitcount = unitcount + 1
			if UnitExists(unit) then return unit end
		end
		-- STEP 4: party units
	elseif pmem > 0 then
		-- STEP 3a: pet units
		for i = petcount, pmem do
			unit = strfmt("partypet%d", i)
			petcount = petcount + 1
			if UnitExists(unit) then return unit end
		end
		-- STEP 3b: player units
		for i = unitcount, pmem do
			unit = strfmt("party%d", i)
			unitcount = unitcount + 1
			if UnitExists(unit) then return unit end
		end
	end
end

local function UnitIterator()
	playersent, petsent, unitcount, petcount, pmem, rmem = false, false, 1, 1, GetNumPartyMembers(), GetNumRaidMembers()
	return NextUnit
end

------------------------------------------------
-- Roster code
------------------------------------------------


function RosterLib:ScanFullRoster()
	-- save all units we currently have, this way we can check who to remove from roster later.
	local temp = new()
	for name in pairs(roster) do
		temp[name] = true
	end
	-- update data
	for unitid in UnitIterator() do
		local name = self:CreateOrUpdateUnit(unitid)
		-- we successfully added a unit, so we don't need to remove it next step
		if name then temp[name] = nil end
	end
	-- clear units we had in roster that either left the raid or are unknown for some reason.
	for name in pairs(temp) do
		self:RemoveUnit(name)
	end
	del(temp)
	self:ProcessRoster()
end


function RosterLib:ScanPet(owner)
	local unitid = self:GetPetFromOwner(owner)
	if not unitid then
		return
	elseif not UnitExists(unitid) then
		unknownUnits[unitid] = nil
		-- find the pet in the roster we need to delete
		for _,u in pairs(roster) do
			if u.unitid == unitid then
				self:RemoveUnit(u.name)
			end
		end
	else
		self:CreateOrUpdateUnit(unitid)
	end
	self:ProcessRoster()
end


function RosterLib:GetPetFromOwner(id)
	-- convert party3 crap to raid IDs when in raid.
	local owner = self:GetUnitIDFromUnit(id)
	if not owner then
		return
	end
	-- get ID
	if strfind(owner,"raid") then
		return strgsub(owner, "raid", "raidpet")
	elseif strfind(owner,"party") then
		return strgsub(owner, "party", "partypet")
	elseif owner == "player" then
		return "pet"
	else
		return nil
	end
end


function RosterLib:ScanUnknownUnits()
	local name
	for unitid in pairs(unknownUnits) do
		if UnitExists(unitid) then
			name = self:CreateOrUpdateUnit(unitid)
		else
			unknownUnits[unitid] = nil
		end
		-- some pets never have a name. too bad for them, farewell!
		if not name and strfind(unitid,"pet") then
			unknownUnits[unitid] = nil
		end
	end
	self:ProcessRoster()
end


function RosterLib:ProcessRoster()
	if next(updatedUnits, nil) then
		self.callbacks:Fire("RosterLib_RosterChanged", updatedUnits)
		for name in pairs(updatedUnits) do
			local u = updatedUnits[name]
			self.callbacks:Fire("RosterLib_UnitChanged", u.unitid, u.name, u.class, u.subgroup, u.rank, u.oldname, u.oldunitid, u.oldclass, u.oldsubgroup, u.oldrank)
			del(updatedUnits[name])
			updatedUnits[name] = nil
		end
	end
	if next(unknownUnits, nil) then
		if self.unknownTimer then self:CancelTimer(self.unknownTimer) end
		self.unknownTimer = self:ScheduleTimer("ScanUnknownUnits", 1, 0)
	end
end


function RosterLib:CreateOrUpdateUnit(unitid)
	local old = nil
	-- check for name
	local name = UnitName(unitid)
	-- Ace3v: RosterLib-2.0 tested the misspelled global UKNOWNBEING, which is
	-- nil, so this guard never rejected "Unknown Being"; fixed to UNKNOWNBEING
	if name and name ~= UNKNOWNOBJECT and name ~= UNKNOWNBEING and not UnitIsCharmed(unitid) then
		-- clear stuff
		unknownUnits[unitid] = nil
		-- return if a pet attempts to replace a player name
		-- this doesnt fix the problem with 2 pets overwriting each other FIXME
		-- Ace3v: compared against "pet" while class is set to "PET", so this
		-- always bailed and pets were never updated after creation
		if strfind(unitid,"pet") then
			if roster[name] and roster[name].class ~= "PET" then
				return name
			end
			-- Ace3v: a pet's name can change while its unit id stays (seen on
			-- Unreal Azeroth: "Voidwalker" and "Zag'nuz" both ended up on "pet").
			-- Carry the entry over as a rename instead of adding a second member
			-- on the same unit id.
			if not roster[name] then
				for prevName, u in pairs(roster) do
					if u.unitid == unitid then
						roster[name] = u
						roster[prevName] = nil
						break
					end
				end
			end
		end
		-- save old data if existing
		if roster[name] then
			old          = new()
			old.name     = roster[name].name
			old.unitid   = roster[name].unitid
			old.class    = roster[name].class
			old.rank     = roster[name].rank
			old.subgroup = roster[name].subgroup
			old.online   = roster[name].online
		end
		-- object
		if not roster[name] then
			roster[name] = new()
		end
		-- name
		roster[name].name = name
		-- unitid
		roster[name].unitid = unitid
		-- class
		if strfind(unitid,"pet") then
			roster[name].class = "PET"
		else
			_,roster[name].class = UnitClass(unitid)
		end
		-- subgroup and rank
			local _,_,num = strfind(unitid, "(%d+)")
		if GetNumRaidMembers() > 0 and num then
			_,roster[name].rank,roster[name].subgroup = GetRaidRosterInfo(num)
		else
			roster[name].subgroup = 1
			roster[name].rank = 0
		end
		-- online/offline status
		-- Ace3v: normalised, clients disagree on 1/nil vs true/false
		roster[name].online = not not UnitIsConnected(unitid)

		-- compare data
		if not old
			or roster[name].name     ~= old.name
			or roster[name].unitid   ~= old.unitid
			or roster[name].class    ~= old.class
			or roster[name].subgroup ~= old.subgroup
			or roster[name].rank     ~= old.rank
			or roster[name].online   ~= old.online
			then
			updatedUnits[name]             = new()
			updatedUnits[name].oldname     = (old and old.name) or nil
			updatedUnits[name].oldunitid   = (old and old.unitid) or nil
			updatedUnits[name].oldclass    = (old and old.class) or nil
			updatedUnits[name].oldsubgroup = (old and old.subgroup) or nil
			updatedUnits[name].oldrank     = (old and old.rank) or nil
			updatedUnits[name].oldonline   = (old and old.online) or nil
			updatedUnits[name].name        = roster[name].name
			updatedUnits[name].unitid      = roster[name].unitid
			updatedUnits[name].class       = roster[name].class
			updatedUnits[name].subgroup    = roster[name].subgroup
			updatedUnits[name].rank        = roster[name].rank
			updatedUnits[name].online      = roster[name].online
		end
		-- recycle our table
		if old then
			del(old)
		end
		return name
	else
		unknownUnits[unitid] = true
		return false
	end
end


function RosterLib:RemoveUnit(name)
	updatedUnits[name]             = new()
	updatedUnits[name].oldname     = roster[name].name
	updatedUnits[name].oldunitid   = roster[name].unitid
	updatedUnits[name].oldclass    = roster[name].class
	updatedUnits[name].oldsubgroup = roster[name].subgroup
	updatedUnits[name].oldrank     = roster[name].rank
	del(roster[name])
	roster[name] = nil
end


------------------------------------------------
-- API
------------------------------------------------

function RosterLib:GetUnitIDFromName(name)
	if roster[name] then
		return roster[name].unitid
	else
		return nil
	end
end


function RosterLib:GetUnitIDFromUnit(unit)
	local name = UnitName(unit)
	if name and roster[name] then
		return roster[name].unitid
	else
		return nil
	end
end


function RosterLib:GetUnitObjectFromName(name)
	if roster[name] then
		return roster[name]
	else
		return nil
	end
end


function RosterLib:GetUnitObjectFromUnit(unit)
	local name = UnitName(unit)
	if roster[name] then
		return roster[name]
	else
		return nil
	end
end


function RosterLib:IterateRoster(pets)
	local key
	return function()
		repeat
			key = next(roster, key)
		until (roster[key] == nil or pets or roster[key].class ~= "PET")

		return roster[key]
	end
end


------------------------------------------------
-- Startup
------------------------------------------------

if RosterLib.initialized then
	-- library upgraded mid-session: re-arm the events and rescan
	RosterLib.initialized = nil
	Initialize()
else
	RosterLib:RegisterEvent("PLAYER_LOGIN", "PLAYER_LOGIN")
	RosterLib:RegisterEvent("PLAYER_ENTERING_WORLD", "PLAYER_ENTERING_WORLD")
	RosterLib.initTimer = RosterLib:ScheduleTimer(Initialize, 10, 0)
end
