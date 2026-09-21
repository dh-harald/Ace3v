--[[
Name: LibRover-1.0
Revision: $Rev: 1 $
Author(s): sinus (sinus@sinpi.net); WoW 1.12.1 port
Description: A library calculating travel paths from point A to point B.
Dependencies: LibStub, CallbackHandler-1.0, AceEvent-3.0, AceTimer-3.0, LibTaxi-1.0,
              LibHereBeDragons-1.0
License: MIT
]]

local MAJOR_VERSION, MINOR_VERSION = "LibRover-1.0", 1

assert(LibStub, MAJOR_VERSION .. " requires LibStub")

local Lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not Lib then return end

local AceEvent = LibStub("AceEvent-3.0")
local AceTimer = LibStub("AceTimer-3.0")
local HBD = LibStub("LibHereBeDragons-1.0")
local LibTaxi = LibStub("LibTaxi-1.0")
AceEvent:Embed(Lib)
AceTimer:Embed(Lib)

local LibRover = Lib
local _G = _G or getfenv(0)
_G.LibRover = Lib

local tinsert, tremove, tgetn, tsort = table.insert, table.remove, table.getn, table.sort
local strfind, strgsub, strsub, strlower, strformat =
      string.find, string.gsub, string.sub, string.lower, string.format
local mmax, mmin, mabs, mfloor, mmod, msqrt = math.max, math.min, math.abs, math.floor, math.mod, math.sqrt
local ipairs, pairs, next, type, tonumber, tostring, unpack, assert, error, pcall =
      ipairs, pairs, next, type, tonumber, tostring, unpack, assert, error, pcall
local setmetatable, rawget, loadstring, setfenv = setmetatable, rawget, loadstring, setfenv
local GetTime = GetTime

-- 1.12 has no debugprofilestop.
local function ms()
	return GetTime() * 1000
end

local function wipe(t)
	for k in pairs(t) do t[k] = nil end
	table.setn(t, 0)
	return t
end

local function apibool(f, a)
	if type(f) ~= "function" then return nil end
	local ok, ret = pcall(f, a)
	return ok and not not ret or false
end

--[[================ CONSTANTS ===============]]--

local KALIMDOR, EASTERN_KINGDOMS = 13, 14
local CONTINENT_BY_C = { KALIMDOR, EASTERN_KINGDOMS }

local BASE_SPEED = 7                 -- yards per second on foot; BASE_MOVEMENT_SPEED in FrameXML
local COST_MAGE_TELEPORT = 20
local COST_PORTAL = 10
local COST_TRAM = 300
local COST_CROSSCONTINENT_DEFAULT = 20
local COST_SHIP_DEFAULT = 240
local COST_FAILURE = 100000          -- anything above means failed path
local COST_FORCED = -1000000         -- guaranteed best
local COST_MOUNTUP = 2.0
local COSTMOD_COMFORT_TAXI = 0.5
local COSTMOD_WALK = 1.2
local COSTMOD_HOSTILE = 1

local TAXI_NODE_RADIUS = 1
local STANDING_ON_NODE_RADIUS = 10
local STANDING_ON_NODE_RADIUS_END = 20

local STARTUP_INTENSITY = 50         -- ms of startup work per frame
local UPDATE_FREQ = 1

Lib.COST_FORCED = COST_FORCED
Lib.COST_FAILURE = COST_FAILURE
Lib.FINDPATH_MAX_RETRIES = 10
Lib.calculation_step_limit = 9999
Lib.update_interval = 30

--[[================ STATE ===============]]--

Lib.nodes = Lib.nodes or {all = {}, taxi = {}, id = {}, mageteleport = {}, useitem = {},
	inn = {}, ['start'] = {}, ['end'] = {}, ['temp'] = {}, by_map = {}, by_cont = {}}
local allnodes = Lib.nodes.all
local nodes_by_map = Lib.nodes.by_map
local nodes_by_cont = Lib.nodes.by_cont

Lib.opennodes = Lib.opennodes or LibRover_NodeSetHeap:New()
Lib.banned_nodes = Lib.banned_nodes or {}
Lib.delayeddata = Lib.delayeddata or {}
Lib.taxislinked = Lib.taxislinked or {}
Lib.greenborders = Lib.greenborders or {}
Lib.walls = Lib.walls or {}
Lib.ERRORS = Lib.ERRORS or {}
Lib.maxspeedinzone = Lib.maxspeedinzone or {}
Lib.GetMapByNameFloorErrors = Lib.GetMapByNameFloorErrors or {}
Lib.startup_modules_funcs = Lib.startup_modules_funcs or {}
Lib.init_progress = 0
Lib.RESULTS_SKIPPED_START = {}
Lib.RESULTS_SKIPPED_END = {}

local default_speeds = {1, 1, 0}
setmetatable(Lib.maxspeedinzone, {__index = function() return default_speeds end})

-- Localization stub: a consumer may replace the table's contents.
Lib.L = Lib.L or setmetatable({}, {__index = function(self, k) return rawget(self, k) or k end})

Lib.cfg = {
	use_mage_teleport = true,
	use_item_teleports = true,
	use_astral_recall = true,
	use_hearth = true,
	use_taxi = true,
	avoid_highlevel_zones = true,
	frown_on_portals = false,
	pathfinding_comfort = 0,
	pathfinding_speed = 15,
	remove_hairpins = true,
	remove_standing = true,
	strip_arrivals = true,
}
Lib.cfgNodeOverride = {}

function Lib:GetCFG(field)
	if self.cfgNodeOverride[field] == nil then return self.cfg[field] end
	return self.cfgNodeOverride[field]
end

-- Maps a consumer's profile onto the config, as the original did for ZGV's options.
function Lib:UpdateConfig(profile)
	if not profile then return end
	if profile.travelusehs ~= nil then Lib.cfg.use_hearth = profile.travelusehs end
	if profile.traveluseitems ~= nil then Lib.cfg.use_item_teleports = profile.traveluseitems end
	if profile.travelusespells ~= nil then
		Lib.cfg.use_astral_recall = profile.travelusespells
		Lib.cfg.use_mage_teleport = profile.travelusespells
	end
	if profile.pathfinding_comfort ~= nil then Lib.cfg.pathfinding_comfort = profile.pathfinding_comfort end
	if profile.pathfinding_speed ~= nil then Lib.cfg.pathfinding_speed = profile.pathfinding_speed end
	if profile.pathfinding ~= nil then Lib.cfg.pathfinding = profile.pathfinding end
end

--[[================ HOST INTERFACE ===============]]--

-- Everything the original read off the ZGV global comes from here instead.  All fields optional.
Lib.host = Lib.host or {}
function Lib:SetHost(host)
	for k, v in pairs(host or {}) do Lib.host[k] = v end
	if Lib.host.profile then Lib:UpdateConfig(Lib.host.profile) end
end

function Lib:HostPlayerLevel()
	if Lib.host.GetPlayerLevel then return Lib.host.GetPlayerLevel() end
	return UnitLevel("player") or 1
end

function Lib:HostReputation(factionid)
	if Lib.host.GetReputation then return Lib.host.GetReputation(factionid) or 0 end
	return 99  -- unknown: don't block on it
end

function Lib:HostQuestComplete(questid)
	if Lib.host.QuestComplete then return not not Lib.host.QuestComplete(questid) end
	return true  -- unknown: don't block on it
end

function Lib:SetDebug(on, func)
	Lib.debug = not not on
	Lib.debugfunc = func
end

function Lib:Debug(s, ...)
	if not Lib.debug then return end
	local msg = s
	if tgetn(arg) > 0 then
		local ok, formatted = pcall(strformat, s, unpack(arg))
		msg = ok and formatted or s
	end
	if Lib.debugfunc then Lib.debugfunc(msg)
	else DEFAULT_CHAT_FRAME:AddMessage("LibRover: " .. msg) end
end

local function AddError(fmt, a1, a2, a3, a4, a5)
	local ok, s = pcall(strformat, fmt, a1, a2, a3, a4, a5)
	tinsert(Lib.ERRORS, ok and s or fmt)
end

--[[================ DATA ===============]]--

local function AdoptData()
	if _G.LibRover_Data then
		Lib.data = Lib.data or {}
		for k, v in pairs(_G.LibRover_Data) do
			if k == "basenodes" and Lib.data.basenodes then
				for k2, v2 in pairs(v) do Lib.data.basenodes[k2] = v2 end
			else
				Lib.data[k] = v
			end
		end
		_G.LibRover_Data = nil
	end
end
AdoptData()

--[[================ GEOMETRY ===============]]--

local function getdist(node1, node2)
	if not node1 or not node2 or not node1.x or not node2.x then return 99999999 end
	local dist, xd, yd = HBD:GetZoneDistance(node1.m, nil, node1.x, node1.y,
	                                         node2.m, nil, node2.x, node2.y)
	return dist or 99999999, xd, yd
end
Lib.GetDist = getdist

local function MapName(id, floor)
	if type(id) == "table" then id = id.m end
	return HBD:GetLocalizedMap(tonumber(id) or 0) or ("(map " .. tostring(id) .. "?)")
end
Lib.MapName = MapName

-- Eastern Kingdoms is cut up by seas.  The original built a bitmask of which parts see each
-- other; with no flying that only matters for sanity checks, and set tables replace `bit`, whose
-- presence on 1.12 is unverified.
local EASTERN_PARTS = {
	{"Tirisfal Glades", "Undercity", "Western Plaguelands", "Eastern Plaguelands",
	 "Silverpine Forest", "Hillsbrad Foothills", "Arathi Highlands", "The Hinterlands",
	 "Alterac Mountains"},
	{"Arathi Highlands", "Wetlands"},
	{"Wetlands", "Dun Morogh", "Loch Modan", "Searing Gorge", "Badlands", "Burning Steppes",
	 "Elwynn Forest", "Redridge Mountains", "Westfall", "Duskwood", "Deadwind Pass",
	 "Swamp of Sorrows", "Stranglethorn Vale", "Blasted Lands", "Ironforge", "Stormwind City"},
}
local easterns = {}
setmetatable(easterns, {__index = function() return nil end})

function Lib.zone_same_eastern_part(map1, map2)
	local p1, p2 = easterns[map1], easterns[map2]
	if not p1 or not p2 then return true end  -- someone put a node out in continent space
	for part in pairs(p1) do if p2[part] then return true end end
	return false
end

-- Intersect segments A (x1,y1 : x2,y2) and B (x1,y1 : x2,y2).
local function getIntersection(ax1, ay1, ax2, ay2, bx1, by1, bx2, by2)
	local aA = ay2-ay1
	local aB = ax1-ax2
	local aC = aA*ax1 + aB*ay1
	local bA = by2-by1
	local bB = bx1-bx2
	local bC = bA*bx1 + bB*by1

	local det = aA*bB - bA*aB
	if mabs(det) < 0.0001 then
		return nil -- parallel
	else
		return (bB*aC - aB*bC)/det, (aA*bC - bA*aC)/det
	end
end
Lib.getIntersection = getIntersection

local function doesIntersect(ax1, ay1, ax2, ay2, bx1, by1, bx2, by2)
	if ax1 == ax2 then ax1 = ax1 + 0.0001 end  -- perfect verticals/horizontals are a bitch.
	if ay1 == ay2 then ay1 = ay1 + 0.0001 end
	if bx1 == bx2 then bx1 = bx1 + 0.0001 end
	if by1 == by2 then by1 = by1 + 0.0001 end
	if mmax(ax1, ax2) < mmin(bx1, bx2) then return false, "no overlap x1" end
	if mmax(bx1, bx2) < mmin(ax1, ax2) then return false, "no overlap x2" end
	if mmax(ay1, ay2) < mmin(by1, by2) then return false, "no overlap y1" end
	if mmax(by1, by2) < mmin(ay1, ay2) then return false, "no overlap y2" end
	local intx, inty = getIntersection(ax1, ay1, ax2, ay2, bx1, by1, bx2, by2)
	if not intx then return false, "parallel" end
	if ax1 > ax2 then ax1, ax2 = ax2, ax1 end
	if ay1 > ay2 then ay1, ay2 = ay2, ay1 end
	if bx1 > bx2 then bx1, bx2 = bx2, bx1 end
	if by1 > by2 then by1, by2 = by2, by1 end
	if intx >= ax1 and intx <= ax2 and inty >= ay1 and inty <= ay2
	and intx >= bx1 and intx <= bx2 and inty >= by1 and inty <= by2 then return true end
	return false, "out"
end
Lib.doesIntersect = doesIntersect

function Lib.IsSegmentWalled(node1, node2)
	if node1.m ~= node2.m then return false, "no wall as not same map" end
	local walls = Lib.walls[node1.m]
	if not walls then return false, "no wall on map" end
	for wi, wall in ipairs(walls) do
		for si, points in ipairs(wall.segments) do
			local cross = doesIntersect(node1.x, node1.y, node2.x, node2.y,
				points[1], points[2], points[3], points[4])
			if cross then return true, wi, si, wall.penalty end
		end
	end
	return false
end

--[[================ MAPS ===============]]--

-- Zone name -> LibHereBeDragons map id.  The original looked this up in a table of Classic
-- uiMapIDs; here the names resolve through HBD, which knows the vanilla WorldMapArea ids.
local mapbyname_cache = {}
function Lib:GetMapByNameFloor(m, f, text)
	if not m then return false end
	if type(m) == "number" then return m, tonumber(f) or 0 end

	if not f and strfind(m, "/", 1, true) then
		local _, _, mm, ff = strfind(m, "^(.-)%s*/%s*([0-9]+)")
		if ff then m, f = mm, tonumber(ff) end
	end

	local id = mapbyname_cache[m]
	if id == nil then
		id = HBD:GetMapIDFromZoneName(m) or false
		mapbyname_cache[m] = id
	end
	if not id then
		Lib.GetMapByNameFloorErrors[m] = "unknown map - " .. (text or m)
		return false
	end
	return id, tonumber(f) or 0
end

function Lib:GetFloorByMapID(m)
	return 0  -- vanilla maps have one floor
end

function Lib.ZoneIsOutdoor(mapid)
	local C = HBD:GetCZFromMapID(mapid)
	return C ~= nil and C > 0
end

function Lib:GetMapContinent(m)
	if not m then return nil end
	if m == KALIMDOR or m == EASTERN_KINGDOMS then return m end
	local C = HBD:GetCZFromMapID(m)
	return C and CONTINENT_BY_C[C] or nil
end

function Lib:GetPlayerPosition()
	local x, y, m = HBD:GetPlayerZonePosition()
	if not m then return 0, 0, 0 end
	if not x then return 0, 0, m end
	return x, y, m
end

--[[================ SPEEDS ===============]]--

-- 1.12 has no flying mounts, and no way to read the riding skill without a localized string, so
-- ground speed is taken from the player's level (mount at 40, epic at 60) unless the host says
-- otherwise with SetGroundSpeed.  Flight speed is always 0.
Lib.groundspeed_override = nil
function Lib:SetGroundSpeed(mult)
	Lib.groundspeed_override = mult
	Lib.last_speed_check = nil
	Lib:CheckMaxSpeeds()
end

-- nil means "not measured yet"; see the spellbook cache above for why this is not a number
Lib.last_speed_check = nil
function Lib:CheckMaxSpeeds()
	local time = GetTime()
	if Lib.last_speed_check and time - Lib.last_speed_check < 1 then return end
	Lib.last_speed_check = time

	local groundspeed = Lib.groundspeed_override
	if not groundspeed then
		local level = Lib:HostPlayerLevel()
		if level >= 60 then groundspeed = 2.0
		elseif level >= 40 then groundspeed = 1.6
		else groundspeed = 1.0 end
	end

	Lib.speeds = { Azeroth = {groundspeed, 0} }

	local zonemeta = Lib.data.ZoneMeta
	local ids = HBD:GetAllMapIDs()
	for i, zoneid in ipairs(ids) do
		local cont = Lib:GetMapContinent(zoneid)
		if cont then
			local run = groundspeed
			if zonemeta[zoneid].runspeed then run = zonemeta[zoneid].runspeed end
			Lib.maxspeedinzone[zoneid] = { run, run, 0 }
		end
	end
end

--[[================ NODES ===============]]--

Lib.NodeRegions = Lib.NodeRegions or {}

function Lib.NodeRegions:Assign(node)
	for ri, region in ipairs(self) do
		if region:Contains(node) then node:AssignRegion(region) return end
	end
end

function Lib.NodeRegions:AddNewRegion(data)
	local region = LibRover_Region:New(data)
	tinsert(self, region)
	return region
end

Lib.SpecialMapNodeData = Lib.SpecialMapNodeData or {}
function Lib.SpecialMapNodeData:AddMap(map, floor, data)
	local mapdata = self[map]
	if not mapdata then mapdata = {} self[map] = mapdata end
	mapdata[floor or 0] = data
end
function Lib.SpecialMapNodeData:Assign(node)
	local mapdata = self[node.m]
	local floordata = mapdata and mapdata[node.f or 0]
	if floordata then
		node.dark = node.dark or floordata.dark
		node.nofly = node.nofly or floordata.nofly
	end
end

function Lib.greenborders:CanCross(id1, id2, loud)
	local si1 = self[id1]
	if si1 and si1[id2] and si1[id2] > 0 then return true end
	local si2 = self[id2]
	-- other way only if not defined as oneway
	if si2 and si2[id1] and si2[id1] > 0 and not (si1 and si1[id2] and si1[id2] < 0) then
		return true
	end
end

local function AddNode(node, dontlink)
	if node.m and not node.x then return nil end

	-- sanitize continent, coordinates, floor
	node.c = node.c or Lib:GetMapContinent(node.m)
	if not node.x then error("Failed to add map node " .. (tgetn(allnodes)+1) .. " type " .. tostring(node.type)) end
	if node.x > 1 then node.x, node.y = node.x/100, node.y/100 end
	node.f = node.f or 0

	tinsert(allnodes, node)
	node.num = tgetn(allnodes)

	if node.type then
		if not Lib.nodes[node.type] then Lib.nodes[node.type] = {} end
		tinsert(Lib.nodes[node.type], node)

		if node.type ~= "end" and node.type ~= "start" and node.type ~= "temp" then
			if not nodes_by_map[node.m] then nodes_by_map[node.m] = {} end
			tinsert(nodes_by_map[node.m], node)
			if not nodes_by_cont[node.c] then nodes_by_cont[node.c] = {} end
			tinsert(nodes_by_cont[node.c], node)
		end
	end

	-- set node.region, if applicable. BEFORE neighbours, ffs.
	node:AssignRegion()
	node:AssignSpecialMap()

	local zm = rawget(Lib.data.ZoneMeta, node.m)
	if zm then
		for k, v in pairs(zm) do if node[k] == nil then node[k] = v end end
	end

	node.radius = tonumber(node.radius)

	-- connect to other nodes, by automatic linkage (walk)
	if not dontlink then
		local ntype = node.type
		local function DoLinkage_in_scope(scope)
			if scope then for i, v in ipairs(scope) do
				if v ~= node then
					-- endnode only gets linked TO.
					if ntype ~= "end" then node:DoLinkage(v) end
					-- startnode and inns don't get linked TO, only FROM.
					if ntype ~= "start" and ntype ~= "inn" then v:DoLinkage(node) end
				end
			end end
		end
		DoLinkage_in_scope(nodes_by_cont[node.c])
		if ntype == "start" and Lib.nodes["end"][1] then DoLinkage_in_scope(Lib.nodes["end"]) end
		if ntype == "start" and Lib.nodes["temp"][1] then DoLinkage_in_scope(Lib.nodes["temp"]) end
	end

	if node.id then Lib.nodes.id[node.id] = node end

	return node
end
Lib.AddNode = AddNode

--[[================ NODE DATA PARSING ===============]]--

local function HandleSpellsAndItems(node, link)
	if not node then return end
	if node.spell then
		node.spell = tonumber(node.spell)
		tinsert(Lib.nodes.mageteleport, node)
	end
	if node.item then
		node.item = tonumber(node.item)
		tinsert(Lib.nodes.useitem, node)
	end
end

-- The environment a {cond:...} expression in the data is evaluated in.  The original called into
-- ZGV; a host may add to or replace these with SetHost{condEnv=...}.
local cond_env
cond_env = setmetatable({
	RaceClassMatch = function(what)
		local _, class = UnitClass("player")
		local _, race = UnitRace("player")
		return what == class or what == race
	end,
	PlayerLevel = function() return Lib:HostPlayerLevel() end,
	UnitLevel = function() return Lib:HostPlayerLevel() end,
	PlayerCompletedQuest = function(id) return Lib:HostQuestComplete(id) end,
	PlayerIsOnQuest = function(id)
		if Lib.host.OnQuest then return not not Lib.host.OnQuest(id) end
		return false
	end,
}, {__index = function(t, k)
	local h = Lib.host.condEnv
	if h and h[k] ~= nil then return h[k] end
	return _G[k]
end})
Lib.cond_env = cond_env

local function ParseDataCond(data)
	if type(data.cond) == "string" then
		local fun, err = loadstring("return " .. data.cond)
		if err then error(err .. " in parsing '" .. data.cond .. "'") end
		data.cond_fun = fun
	elseif type(data.cond) == "function" then
		data.cond_fun = data.cond
		data.cond = "(function)"
	end
	if data.cond_fun then setfenv(data.cond_fun, cond_env) end
end

local function CloneTable(tab)
	local t = {}
	for k, v in pairs(tab) do t[k] = v end
	return t
end

local LAST_NODE  -- to use with @+ pseudo-id in data

local playerF, enemyfac
local function PlayerFaction()
	if not playerF then
		local faction = UnitFactionGroup("player")
		if faction == "Alliance" then playerF, enemyfac = "A", "H"
		elseif faction == "Horde" then playerF, enemyfac = "H", "A"
		end
	end
	return playerF
end

local function a_to_b(self, fromnode, tonode)
	if tonode == self.border then
		return (self.bordermeta and (self.bordermeta.title_atob or self.bordermeta.title))
	end
	if fromnode == self.border then
		return (self.bordermeta and (self.bordermeta.title_btoa or self.bordermeta.title))
	end
end
local function b_to_a(self, fromnode, tonode)
	if tonode == self.border then
		return (self.bordermeta and (self.bordermeta.title_btoa or self.bordermeta.title))
	end
	if fromnode == self.border then
		return (self.bordermeta and (self.bordermeta.title_atob or self.bordermeta.title))
	end
end

local function __SmartAddTextNodes(text, deftype, dontlink)
	deftype = deftype or "misc"
	local ntype
	local origtext = text

	-- Powerhorse: extract all {data:blablabla} tags.
	local conndata = {mode = "walk"}
	while true do
		local _, _, text1, key, val, text2 = strfind(text, "^(.-){(.-):(.-)}(.-)$")
		if not key then break end
		if key == "fac" and val == enemyfac then return end  -- quick exit if faction is wrong
		if key == "mode" then val = strlower(val) ntype = val end  -- ZEPPELIN->zeppelin
		local num = tonumber(val)
		if num then val = num end
		conndata[key] = val
		text = text1 .. text2
	end

	text = strgsub(text, "\\>", "%%GT%%")

	-- Powerhorse #2: parse "zone 12,34 -to- zone 55,66"
	local _, _, mxy1, dir, mxy2 = strfind(text, "^(.-)%s+%-([xto]+)%-%s+(.-)$")
	if not mxy1 then mxy1 = text end -- OMG one node!?
	local m1, f1, x1, y1, id1, dat1 = LibRover_Node:Parse(mxy1)

	local m2, f2, x2, y2, id2, dat2
	if mxy2 then m2, f2, x2, y2, id2, dat2 = LibRover_Node:Parse(mxy2) end

	local twoway = dir == "x"

	if not m1 and not id1 then return AddError("Cannot parse first node: %s", origtext) end
	if dir and not m2 and not id2 then return AddError("Cannot parse second node: %s", origtext) end

	local n1 = x1 and LibRover_Node:New{m = m1, f = f1, x = x1, y = y1, id = id1, type = ntype or deftype}
		or (id1 == "+" and LAST_NODE) or Lib.nodes.id[id1]
	local n2 = x2 and LibRover_Node:New{m = m2, f = f2, x = x2, y = y2, id = id2, type = ntype or deftype}
		or Lib.nodes.id[id2]

	LAST_NODE = n2 or n1  -- for reference using @+

	if id1 and not m1 and not n1 then return AddError("Node id @%s not found: %s", id1, origtext) end
	if id2 and not m2 and not n2 then return AddError("Node id @%s not found: %s", id2, origtext) end
	if not n1 then return AddError("Cannot make a node from: %s", origtext) end

	local link12, link21, link1m

	ParseDataCond(conndata)

	if n1 and n2 and conndata.replace then  -- modify an existing connection, don't make one
		for i, nodemeta in ipairs(n1.n) do
			if nodemeta[1] == n2 then for k, v in pairs(conndata) do nodemeta[2][k] = v end end
		end
		if twoway then
			for i, nodemeta in ipairs(n2.n) do
				if nodemeta[1] == n1 then for k, v in pairs(conndata) do nodemeta[2][k] = v end end
			end
		end
		return
	end

	if dat1 then
		ParseDataCond(dat1)
		for k, v in pairs(dat1) do n1[k] = v end
	end
	if n2 then
		if dat2 then for k, v in pairs(dat2) do n2[k] = v end end
		link12 = CloneTable(conndata)
		link12.hardwired = true
		n1:AddNeigh(n2, link12)
	end

	if twoway then
		if n2 then
			link21 = CloneTable(conndata)
			link21.hardwired = true
			n2:AddNeigh(n1, link21)
		elseif m2 then
			-- "Zone 12,34 x Zone"? One node with a multiple personality.
			if not n1.ms then n1.ms = {} end
			link1m = {}
			n1.ms[m2] = link1m
			for k, v in pairs(conndata) do link1m[k] = v end
		end
	end

	if n1 and (n2 or n1.ms) then
		if link12 then link12.mode = link12.mode or ntype or "walk" end
		if link21 then link21.mode = link21.mode or ntype or "walk" end
		if link1m then link1m.mode = link1m.mode or ntype or "walk" end

		-- A node closely bound with another gets that one as its .border, so a node with five
		-- neighbours can still name its SPECIAL one.  Already has one? Then it's a multi.
		if not conndata.dontsetborder then
			if n1.border then
				n1.borders = n1.borders or {}
				n1.borders[n1.border] = n1.bordermeta
				n1.borders[n2] = link12
				n1.border = "multi"
			else
				n1.border = n2
				n1.bordermeta = link12
			end
			if n2 then
				if n2.border then
					n2.borders = n2.borders or {}
					n2.borders[n2.border] = n2.bordermeta
					n2.borders[n1] = link21
					n2.border = "multi"
				else
					n2.border = n1
					n2.bordermeta = link21
				end
			end
		end
	end

	-- delayed adding, to account for optimizations using .border data above
	if x1 and n1 then AddNode(n1, dontlink) end
	if x2 and n2 then AddNode(n2, dontlink) end

	HandleSpellsAndItems(n1, link12)

	return n1, n2
end

local def_deftype = "walk"
local function __SmartAddArrayNodes(data, deftype, dontlink)
	deftype = deftype or def_deftype

	if data.faction == enemyfac then return end

	local m1, f1, x1, y1, id1, dat1 = LibRover_Node:Parse(data[1])
	local m2, f2, x2, y2, id2, dat2 = LibRover_Node:Parse(data[2])
	data[1] = nil
	data[2] = nil

	if data.set_def_type then def_deftype = data.set_def_type end
	if not m1 and not m2 and not id1 and not id2 then return end

	local n1 = x1 and LibRover_Node:New{m = m1, f = f1, x = x1, y = y1, id = id1,
			type = (dat1 and dat1.type) or data.mode or deftype}
		or (id1 == "+" and LAST_NODE) or Lib.nodes.id[id1]
	local n2 = x2 and LibRover_Node:New{m = m2, f = f2, x = x2, y = y2, id = id2,
			type = (dat2 and dat2.type) or data.mode or deftype}
		or Lib.nodes.id[id2]

	LAST_NODE = n2 or n1

	if not n1 then return AddError("Cannot make a node from an array entry") end

	if dat1 then for k, v in pairs(dat1) do n1[k] = v end end
	if x1 then AddNode(n1, dontlink) end
	if n2 then
		if dat2 then for k, v in pairs(dat2) do n2[k] = v end end
		if x2 then AddNode(n2, dontlink) end

		if n1.c ~= n2.c and data.mode ~= "ship" and data.mode ~= "zeppelin" then
			data.cost = data.cost or COST_CROSSCONTINENT_DEFAULT
			data.time = data.cost
		end

		data.hardwired = 1
		n1:AddNeigh(n2, data)

		if n1.type == "portal" and n2.type == "portal" and not data.mode then data.mode = "portal" end
	end

	data.mode = data.mode or deftype
	ParseDataCond(data)

	if not data.oneway then
		if n2 then
			n2:AddNeigh(n1, data)
		elseif m2 then
			if not n1.ms then n1.ms = {} end
			n1.ms[m2] = data
		end
	end
	data.oneway = nil

	if n1 and (n2 or n1.ms) then
		data.mode = data.mode or "walk"
		if not data.dontsetborder then
			local link12 = CloneTable(data)
			link12.hardwired = true
			if n1.border then
				n1.borders = n1.borders or {}
				n1.borders[n1.border] = n1.bordermeta
				n1.borders[n2] = link12
				n1.border = "multi"
			else
				n1.border = n2
				n1.bordermeta = link12
			end
			if n2 then
				local link21 = CloneTable(data)
				link21.hardwired = true
				if n2.border then
					n2.borders = n2.borders or {}
					n2.borders[n2.border] = n2.bordermeta
					n2.borders[n1] = link21
					n2.border = "multi"
				else
					n2.border = n1
					n2.bordermeta = link21
				end
			end
		end
	end

	HandleSpellsAndItems(n1, data)

	return n1, n2
end

local function SmartAddNode(data, deftype, dontlink)
	local n1, n2

	if type(data) == "string" then
		if strfind(data, "-- ", 1, true) then return end  -- a commented-out entry
		local aok
		aok, n1, n2 = pcall(__SmartAddTextNodes, data, deftype, dontlink)
		if not aok then
			AddError("NODE ERROR: %s in SmartAddNode(%s)", tostring(n1), data)
			return
		end
	elseif type(data) == "table" then
		if data[1] == "REGION" then
			Lib.NodeRegions:AddNewRegion(data)
			return
		elseif data[1] == "MAP" then
			Lib.SpecialMapNodeData:AddMap(Lib:GetMapByNameFloor(data.map), data.floor or 0, data.extra)
			return
		else
			local aok
			aok, n1, n2 = pcall(__SmartAddArrayNodes, data, deftype, dontlink)
			if not aok then
				AddError("NODE ERROR: %s in SmartAddNode(table)", tostring(n1))
				return
			end
		end
	end

	if n1 and n2 and n1.bordermeta then
		-- get data from connection_templates if {template:xxxx} is valid
		local template = Lib.data.connection_templates[n1.bordermeta.template]
		if template then
			for k, v in pairs(template) do
				if n1.bordermeta[k] == nil then n1.bordermeta[k] = v end
				if n2.bordermeta and n2.bordermeta[k] == nil then n2.bordermeta[k] = v end
			end
		end
		if n1.bordermeta.title_atob or n1.bordermeta.title_btoa or n1.bordermeta.title then
			n1.actiontitle = a_to_b
			if n2 then n2.actiontitle = b_to_a end
		end
	end

	return n1, n2
end
Lib.SmartAddNode = SmartAddNode

--[[================ TAXIS ===============]]--

local function InitializeTaxis(dontlink)
	if not LibTaxi.taxipoints then return end
	local pf = PlayerFaction()
	local zonenames = {}
	for c, cont in pairs(LibTaxi.taxipoints) do
		for z in pairs(cont) do tinsert(zonenames, z) end
	end
	tsort(zonenames)

	for c, cont in pairs(LibTaxi.taxipoints) do
		for zi, z in ipairs(zonenames) do
			local zone = cont[z]
			if zone then
				for n, node in ipairs(zone) do
					if node.faction ~= enemyfac then
						local map = Lib:GetMapByNameFloor(z)
						if map then
							node.m = map
							node.type = "taxi"
							node.radius = TAXI_NODE_RADIUS
							-- other fields are already there, how convenient!
							AddNode(LibRover_Node:New(node), dontlink)
						else
							AddError("initialise taxis, bad zone: %s", tostring(z))
						end
					end
				end
			end
		end
	end

	-- link taxis together
	local taxis = Lib.nodes.taxi
	for i, n1 in ipairs(taxis) do
		for j, n2 in ipairs(taxis) do
			local cost = n1.taxicosts and (n1.taxicosts[n2] or n1.taxicosts[n2.taxitag])
			if cost then
				-- if cost is 0 the time is unknown; leave it out and let the cost model estimate
				n1:AddNeigh(n2, {mode = "taxi", cost = (cost > 0) and cost or nil})
				Lib.taxislinked[n1.num .. "-" .. n2.num] = true
				for k, np in ipairs(n1.n) do
					if np[1] == n2 and np[2].mode == "walk" then
						tremove(n1.n, k)
						break
					end
				end
			end
		end
	end
end

function Lib:GetNearestTaxiInZone()
	local x, y, m = Lib:GetPlayerPosition()
	if not x or not m then return end
	local mindist, minnode = 999999, nil
	for n, node in ipairs(Lib.nodes.taxi) do
		if node.m == m and node.x then
			local dist = getdist({m = m, x = x, y = y}, node)
			if dist < mindist then mindist, minnode = dist, node end
		end
	end
	return minnode, mindist
end

--[[================ STARTUP ===============]]--

local TOTALPROGRESS_DATA = {
	{"start", 0},
	{"maxspeeds", 5},
	{"taxis", 96},
	{"inns", 13},
	{"greenborders", 0},
	{"walls", 0},
	{"borders", 24},
	{"transit", 46},
	{"dolinkage", 126},
	{"portkeys", 24},
}
local TOTALPROGRESSES = {}
do
	local total = 0
	for i, TP in ipairs(TOTALPROGRESS_DATA) do total = total + TP[2] end
	local base = 0
	for i, TP in ipairs(TOTALPROGRESS_DATA) do
		local size = TP[2]/total
		TOTALPROGRESSES[TP[1]] = {base = base, size = size}
		base = base + size
	end
end
Lib.TOTALPROGRESSES = TOTALPROGRESSES

-- The startup runs as named steps, in order, as many per frame as STARTUP_INTENSITY allows; a
-- step named in TOTALPROGRESSES advances init_progress when it finishes, and a step with a
-- `wait` function is not run while that answers true. A step list rather than a thread: the
-- 1.12.1 client has no coroutine library.
local STARTUP_STEPS = {}
local function AddStartupStep(name, func, wait)
	tinsert(STARTUP_STEPS, {name = name, func = func, wait = wait})
end

AddStartupStep("maxspeeds", function()
	PlayerFaction()

	-- ZoneMeta answers with defaults to every query
	local dummy = {}
	setmetatable(Lib.data.ZoneMeta, {__index = function() return dummy end})

	-- the eastern-parts sets, by map id
	for pi, part in ipairs(EASTERN_PARTS) do
		for zi, zname in ipairs(part) do
			local id = Lib:GetMapByNameFloor(zname)
			if id then
				easterns[id] = rawget(easterns, id) or {}
				easterns[id][pi] = true
			end
		end
	end

	Lib:CheckMaxSpeeds()
end)

AddStartupStep("setup", function()
	do -- INITIALIZE SETUP
		for i, text in ipairs(Lib.data.basenodes.setup or {}) do SmartAddNode(text) end
		Lib.data.basenodes.setup = nil
	end
end)

-- waits until the host turns pathfinding on
AddStartupStep("start", function()
	Lib.initializing = true
end, function() return Lib.cfg.pathfinding == false end)

AddStartupStep("advanced", function()
	do -- INITIALIZE ADVANCED (regions)
		for i, pair in ipairs(Lib.data.basenodes.advanced or {}) do SmartAddNode(pair) end
		Lib.data.basenodes.advanced = nil
	end
end)

AddStartupStep("greenborders", function()
	do -- INITIALIZE GREEN BORDERS
		for zi, zones in ipairs(Lib.data.greenborders or {}) do
			local oneway
			local n = tgetn(zones)
			if zones[n] == "oneway" then oneway = true tremove(zones, n) n = n - 1 end
			for zi1 = 1, n-1 do
				local z1 = Lib:GetMapByNameFloor(zones[zi1])
				for zi2 = zi1+1, n do
					local z2 = Lib:GetMapByNameFloor(zones[zi2])
					if z1 and z2 then
						local iz1 = Lib.greenborders[z1] or {}  iz1[z2] = 1  Lib.greenborders[z1] = iz1
						local iz2 = Lib.greenborders[z2] or {}  iz2[z1] = oneway and -1 or 1
						Lib.greenborders[z2] = iz2
					else
						AddError("initialising green borders, bad zone pair %s / %s",
							tostring(zones[zi1]), tostring(zones[zi2]))
					end
				end
			end
		end
		Lib.data.greenborders = nil
	end
end)

AddStartupStep("walls", function()
	do -- INITIALIZE WALLS
		for zone, zdata in pairs(Lib.data.walls or {}) do
			local mapid = Lib:GetMapByNameFloor(zone)
			for i, points in ipairs(zdata) do
				local loop = false
				local n = tgetn(points)
				if points[n] == "loop" then loop = true tremove(points) n = n - 1 end
				local wall = {segments = {}, nodes = {}}
				for pn = 1, n, 2 do
					local nextpn = pn + 2
					if nextpn > n then if loop then nextpn = 1 else nextpn = nil end end
					if nextpn then
						tinsert(wall.segments, {points[pn]/100, points[pn+1]/100,
							points[nextpn]/100, points[nextpn+1]/100})
					end
				end
				Lib.walls[mapid] = Lib.walls[mapid] or {}
				tinsert(Lib.walls[mapid], wall)
			end
		end
	end
end)

AddStartupStep("taxis", function()
	do -- INITIALIZE TAXIS
		InitializeTaxis()
	end
end)

AddStartupStep("inns", function()
	do -- INITIALIZE INNS
		local inns = Lib.data.basenodes.inns or {}
		local zonenames = {}
		for z in pairs(inns) do tinsert(zonenames, z) end
		tsort(zonenames)
		local count = tgetn(zonenames)
		for zi, z in ipairs(zonenames) do
			for n, node in ipairs(inns[z]) do
				if node.faction ~= enemyfac then
					local map = Lib:GetMapByNameFloor(z)
					if map then
						node.m = map
						node.type = "inn"
						AddNode(LibRover_Node:New(node))
					else
						AddError("initialise inns, bad zone: %s", tostring(z))
					end
				end
			end
		end
		Lib.data.basenodes.inns = nil
	end
end)

AddStartupStep("borders", function()
	do -- INITIALIZE BORDERS
		local borders = Lib.data.basenodes.borders or {}
		local count = tgetn(borders)
		for d, data in ipairs(borders) do
			SmartAddNode(data, "border")
		end
		Lib.data.basenodes.borders = nil
	end
end)

AddStartupStep("transit", function()
	do -- INITIALIZE TRANSIT
		local transit = Lib.data.basenodes.transit or {}
		local count = tgetn(transit)
		for d, data in ipairs(transit) do
			SmartAddNode(data)
		end
		Lib.data.basenodes.transit = nil
	end
end)

AddStartupStep("dolinkage", function()
	do -- self-regions for nodes that asked for one
		for nid, node in ipairs(allnodes) do
			if node.selfregion then
				local regionobj = Lib.NodeRegions:AddNewRegion{name = "selfregion_" .. nid,
					mapzone = node.m, centernode = node, radius = node.regionradius, nofly = 1}
				if regionobj then node:AssignRegion(regionobj) end
			end
		end
	end
end)

AddStartupStep("portkeys", function()
	do -- INITIALIZE PORTKEYS
		local portkeys = Lib.data.portkeys or {}
		local count = tgetn(portkeys)
		for i, item in ipairs(portkeys) do
			if item.destA and item.destH then
				item.destination = (playerF == "A") and item.destA or item.destH
			end
			-- make sure it's pointing to a node.
			if type(item.destination) == "string" and strsub(item.destination, 1, 1) ~= "_" then
				item.destination = SmartAddNode(item.destination)
				if not item.destination then item.ERROR = "bad destination" end
			end
			if type(item.destination) == "table" then
				item.destination.onlyhardwire_to = true
			end
			item.link = item.link or {}
			item.link.item = item.item
			item.link.spell = item.spell
		end
	end
end)

-- modules registered by now run as steps of their own, after everything above
AddStartupStep("modules", function()
	for i, namefunc in ipairs(Lib.startup_modules_funcs) do
		local func = namefunc[2]
		tinsert(Lib.startup_steps, {name = namefunc[1], func = function() func(Lib) end})
	end
end)

function Lib:StopStartup()
	Lib:Debug("Stopping startup cycle.")
	Lib.startup_steps = nil
end

function Lib:StartupStep(timeleft)
	local steps = Lib.startup_steps
	if not steps then return end

	local thisframe = 0
	while thisframe < (timeleft or STARTUP_INTENSITY) do
		local step = steps[Lib.startup_next]
		if not step then
			Lib:StopStartup()
			Lib.initializing = false
			Lib.init_progress = 1
			Lib.ready = true
			Lib:Debug("Startup complete: %d nodes.", tgetn(allnodes))
			Lib:SendMessage("LIBROVER_READY", 0)
			if Lib.find_after_load then
				local a = Lib.find_after_load
				Lib.find_after_load = nil
				Lib:FindPath(a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9])
			end
			return
		end
		if step.wait and step.wait() then return end

		local t = ms()
		local good, err = pcall(step.func)
		thisframe = thisframe + (ms() - t)
		if not good then
			Lib.ready = nil
			Lib:StopStartup()
			AddError("error initializing LibRover: %s", tostring(err))
			Lib:Debug("ERROR initializing LibRover: %s", tostring(err))
			return
		end

		local progress = TOTALPROGRESSES[step.name]
		if progress then Lib.init_progress = progress.base + progress.size end
		Lib.startup_next = Lib.startup_next + 1
	end
end

function Lib:DoStartup()
	if Lib.startup_steps or Lib.ready then return end

	LibRover_Node:InterfaceWithLib(Lib)
	LibRover_NodeSet:InterfaceWithLib(Lib)
	LibRover_NodeSetHeap:InterfaceWithLib(Lib)
	LibRover_Region:InterfaceWithLib(Lib)

	AdoptData()
	assert(Lib.data and Lib.data.basenodes, MAJOR_VERSION .. " has no data; load its data files")

	if not Lib.frame then
		Lib.frame = CreateFrame("Frame")
		Lib.frame:SetScript("OnUpdate", function()
			Lib:OnUpdate(arg1 or 0)
		end)
	end
	Lib.frame:Show()

	Lib:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnZoneChanged")
	Lib:RegisterEvent("ZONE_CHANGED", "OnZoneChanged")
	Lib:RegisterEvent("ZONE_CHANGED_INDOORS", "OnZoneChanged")
	Lib:RegisterEvent("PLAYER_ENTERING_WORLD", "OnZoneChanged")
	Lib:RegisterEvent("LEARNED_SPELL_IN_TAB", "OnSpellsChanged")
	Lib:RegisterEvent("PLAYER_CONTROL_LOST", "OnTaxiStateChanged")
	Lib:RegisterEvent("PLAYER_CONTROL_GAINED", "OnTaxiStateChanged")
	Lib.RegisterMessage(Lib, "LibTaxi_KnowledgeChanged", "OnTaxiKnowledgeChanged")

	Lib.startup_steps = {}
	for i, step in ipairs(STARTUP_STEPS) do tinsert(Lib.startup_steps, step) end
	Lib.startup_next = 1
end

--[[================ QUICK TRAVEL (hearth, items, teleports) ===============]]--

local not_misc_item_modes = { hearth = true }

local function FindBindLocation(bind)
	if not bind then return nil end
	for i, node in ipairs(Lib.nodes.inn) do
		if bind == node.name then return node end
	end
	Lib:Debug("No idea where the hearthstone is bound to: %s", tostring(bind))
	Lib.FAILEDHEARTH = bind
	return nil
end
Lib.FindBindLocation = FindBindLocation

-- Adds instant travel modes to the starting node
function Lib:SetupInitialQuickTravel(startnode)
	local userlevel = Lib:HostPlayerLevel()

	if (Lib.endnode.m ~= Lib.cfgNodeOverride.m) or (Lib.endnode.x ~= Lib.cfgNodeOverride.x)
	or (Lib.endnode.y ~= Lib.cfgNodeOverride.y) then
		wipe(Lib.cfgNodeOverride)
		Lib.cfgNodeOverride.m = Lib.endnode.m
		Lib.cfgNodeOverride.x = Lib.endnode.x
		Lib.cfgNodeOverride.y = Lib.endnode.y
	end

	local bindlocation = FindBindLocation(GetBindLocation and GetBindLocation())

	for i, port in ipairs(Lib.data.portkeys or {}) do
		local dest, link = port.destination, port.link
		if dest == "_HEARTH" then dest = bindlocation end

		local coolstart, cooldur, coolavail, coolrem
		local reject

		if not dest then reject = "no destination"
		elseif port.spell and not Lib:IsSpellKnown(port.spell) then reject = "spell unknown"
		elseif port.item and Lib:GetItemCount(port.item) == 0 then reject = "no item"
		elseif port.mode == "hearth" and not Lib:GetCFG("use_hearth") then reject = "use_hearth off"
		elseif port.item and not (port.mode and not_misc_item_modes[port.mode])
		   and not Lib:GetCFG("use_item_teleports") then reject = "use_item_teleports off"
		elseif port.is_astral and not Lib:GetCFG("use_astral_recall") then reject = "use_astral_recall off"
		elseif port.maxlevel and userlevel > port.maxlevel then reject = "overleveled"
		elseif port.cond_fun and not port.cond_fun() then reject = "cond unmet"
		end

		if not reject then
			coolstart, cooldur, coolavail = Lib:GetCooldownWithoutGCD(
				(port.spell and "spell") or (port.item and "item"), port.spell or port.item)
			if port.item and coolavail == 0 then reject = "on cd" end
		end

		if not reject then
			coolrem = mmax(0, (coolstart or 0) + (cooldur or 0) - GetTime())

			if port.item then
				link.mode = port.mode or "useitem"
				link.cost = coolrem + (port.cost or 99)
			elseif port.spell then
				link.mode = port.mode or (port.is_astral and "astralrecall") or "spell"
				link.cost = coolrem + (port.cost or 0)
			end
			link.time = 0
			if port.title then
				link.title = port.title
				dest.title = port.title
			end
			link.spell = port.spell
			startnode:AddNeigh(dest, link)
		else
			Lib:Debug("portkey %s rejected: %s", tostring(port.item or port.spell), reject)
		end
	end

	if Lib:GetCFG("use_mage_teleport") then
		for i, node in ipairs(Lib.nodes.mageteleport) do
			if Lib:IsSpellKnown(node.spell) and (not node.cond_fun or node.cond_fun()) then
				local coolstart, cooldur = Lib:GetCooldownWithoutGCD("spell", node.spell)
				local coolrem = mmax(0, (coolstart or 0) + (cooldur or 0) - GetTime())
				local cost = (tonumber(node.casttime) or COST_MAGE_TELEPORT) + coolrem
				startnode:AddNeigh(node, {mode = "teleport", cost = cost})
			end
		end
	end
end

-- 1.12 has no IsSpellKnown: the spellbook is scanned, and a host may answer instead.
-- A nil stamp means "needs a scan".  Not a number in the past: GetTime() is the client's uptime,
-- so it is under a second right after a UI reload and any arithmetic guard would skip the scan.
local spellbook_cache, spellbook_stamp = {}, nil
function Lib:IsSpellKnown(spellid)
	if not spellid then return false end
	if Lib.host.IsSpellKnown then return not not Lib.host.IsSpellKnown(spellid) end
	if not spellbook_stamp or GetTime() - spellbook_stamp > 5 then
		wipe(spellbook_cache)
		spellbook_stamp = GetTime()
		local i = 1
		while true do
			local name = GetSpellName and GetSpellName(i, BOOKTYPE_SPELL or "spell")
			if not name then break end
			spellbook_cache[name] = i
			i = i + 1
		end
	end
	local name = Lib.spellnames and Lib.spellnames[spellid]
	if not name then return false end
	return spellbook_cache[name] ~= nil
end

-- Spell ids the data refers to, with the English names a 1.12 spellbook shows.  A host on a
-- localized realm should either replace this table or answer IsSpellKnown itself.
Lib.spellnames = {
	[3561] = "Teleport: Stormwind",
	[3562] = "Teleport: Ironforge",
	[3563] = "Teleport: Undercity",
	[3565] = "Teleport: Darnassus",
	[3566] = "Teleport: Thunder Bluff",
	[3567] = "Teleport: Orgrimmar",
	[18960] = "Teleport: Moonglade",
	[556] = "Astral Recall",
}

function Lib:GetItemCount(itemid)
	if Lib.host.GetItemCount then return Lib.host.GetItemCount(itemid) or 0 end
	if not GetContainerNumSlots then return 0 end
	for bag = 0, 4 do
		local slots = GetContainerNumSlots(bag) or 0
		for slot = 1, slots do
			local link = GetContainerItemLink and GetContainerItemLink(bag, slot)
			if link and strfind(link, "item:" .. itemid .. ":", 1, true) then return 1 end
		end
	end
	return 0
end

-- 1.12 has no GetItemCooldown and no global-cooldown spell to compare against.
function Lib:GetCooldownWithoutGCD(what, id)
	if what == "spell" then
		local index = Lib.spellnames and Lib.spellnames[id] and spellbook_cache[Lib.spellnames[id]]
		if index and GetSpellCooldown then
			local start, dur, active = GetSpellCooldown(index, BOOKTYPE_SPELL or "spell")
			return start or 0, dur or 0, active or 1
		end
	elseif what == "item" then
		if not GetContainerNumSlots then return 0, 0, 1 end
		for bag = 0, 4 do
			local slots = GetContainerNumSlots(bag) or 0
			for slot = 1, slots do
				local link = GetContainerItemLink and GetContainerItemLink(bag, slot)
				if link and strfind(link, "item:" .. id .. ":", 1, true) then
					local start, dur, active = GetContainerItemCooldown(bag, slot)
					return start or 0, dur or 0, active or 1
				end
			end
		end
	end
	return 0, 0, 1
end

--[[================ PATH FINDING ===============]]--

local lam, lax, lay, lbm, lbx, lby
local lastupdate = 0
local elapsed_for_update = 0

function Lib:ClearQueue()
	wipe(Lib.delayeddata)
	Lib.thread = nil
	Lib.calculating = nil
end

function Lib:QueueFindPath(am, ax, ay, bm, bx, by, handler, extradata, force_new, quiet)
	Lib:Debug("Adding new task for findpath")
	tinsert(Lib.delayeddata, {am = am, ax = ax, ay = ay, bm = bm, bx = bx, by = by,
		handler = handler, extradata = extradata, force_new = force_new, quiet = quiet})

	if not Lib.delayfindpath_timer then
		Lib.delayfindpath_timer = Lib:ScheduleRepeatingTimer("DelayFindPath", 0.1, 0)
	end
end

function Lib:DelayFindPath()
	if tgetn(Lib.delayeddata) == 0 then
		Lib:CancelTimer(Lib.delayfindpath_timer)
		Lib.delayfindpath_timer = nil
		return
	end
	if not Lib.calculating then
		local job = tremove(Lib.delayeddata, 1)
		Lib:FindPath(job.am, job.ax, job.ay, job.bm, job.bx, job.by, job.handler,
			job.extradata, job.force_new, job.quiet)
	end
end

function Lib:UpdateNow(quiet, speed)
	if not Lib.updating then return end
	Lib:Debug("Updating route NOW.")
	Lib.force_update_now = true
	Lib.calculating = false
	Lib.quiet = quiet
	Lib.pathfinding_speed_override = speed
end

function Lib:IsDestinationImpossible(mymap, destmap)
	destmap = destmap or lbm
	if mymap == destmap then return false, "SAME_MAP", "same map" end
	if not Lib:GetMapContinent(destmap) then
		return true, "NO_CONTINENT", "That destination is not on Kalimdor or the Eastern Kingdoms."
	end
	return false
end

function Lib:FindPath(am, ax, ay, bm, bx, by, handler, extradata, force_new, quiet)
	if Lib.cfg.pathfinding == false then return false end

	Lib.quiet = quiet
	Lib.success_endnode = nil
	Lib.low_priority = false
	Lib.updating = true

	extradata = extradata or {}
	Lib.start_is_player = extradata.player
	if am == 0 then
		ax, ay, am = Lib:GetPlayerPosition()
		if not am or not ax or am <= 0 then ax, ay = 0, 0 end
		Lib.start_is_player = true
		extradata.player = true
	end

	if not am or not bm or am <= 0 or bm <= 0 or not ax or not ay or (ax == 0 and ay == 0) then
		Lib:Debug("FindPath failed: no start or end location.")
		Lib:ReportFail("Current location unknown.")
		extradata.retries = (extradata.retries or Lib.FINDPATH_MAX_RETRIES) - 1
		if extradata.retries > 0 then
			Lib:QueueFindPath(0, 0, 0, bm, bx, by, handler, extradata, force_new, quiet)
		end
		return
	end

	Lib.extradata = extradata
	Lib.PathFoundHandler = handler

	local is_impossible, code, reason = Lib:IsDestinationImpossible(am, bm)
	if is_impossible and not extradata.multiple_ends then
		Lib:Debug("FindPath failed, destination impossible: %s", tostring(code))
		Lib:ReportFail(reason)
		return
	end

	if not Lib.ready then
		Lib.find_after_load = {am, ax, ay, bm, bx, by, handler, extradata, force_new}
		Lib:Debug("FindPath: saving for after startup")
		return handler and handler("progress")
	end

	Lib:CheckMaxSpeeds()

	lam, lax, lay, lbm, lbx, lby = am, ax, ay, bm, bx, by
	Lib.force_update_counter = 0
	lastupdate = 0
	Lib.calculating = true
	Lib.calculation_step = 0

	Lib.thread = {phase = "init", steps = 0}
end

-- These fields get REMOVED from the nodes when clearing.
local temp_fields_i = {"cost", "time", "mycost", "mytime", "speed", "status", "parentlink",
	"parent", "prev", "next", "text", "maplabel", "toend", "taxiFinal", "taxiDestination", "link",
	"a_b", "a_b__c_d", "costdesc", "border_optimization", "changed_modes", "is_arrival"}

function Lib:InitializePath__RemoveStartEnd()
	local all = allnodes
	wipe(Lib.nodes['start'])
	for ni = tgetn(all), 1, -1 do
		if all[ni].type == "start" then tremove(all, ni) break end
	end
	wipe(Lib.nodes['end'])
	for ni = tgetn(all), 1, -1 do
		local n = all[ni]
		if n.type == "end" then tremove(all, ni) elseif n.type == "misc" then break end
	end
	if tgetn(Lib.nodes.temp) > 0 then
		wipe(Lib.nodes.temp)
		for ni = tgetn(all), 1, -1 do
			local n = all[ni]
			if n.type == "temp" then tremove(all, ni) elseif n.type == "misc" then break end
		end
	end
end

function Lib:InitializePath()
	Lib.initializing_path = true

	Lib:InitializePath__RemoveStartEnd()

	-- make neighbours forget our linkage
	for ni, node in ipairs(allnodes) do
		node:RemoveNeighType("temp", "start", "end")
	end

	Lib.endnode = LibRover_Node:New{m = lbm, f = 0, x = lbx, y = lby, type = "end",
		title = Lib.extradata and Lib.extradata.title,
		zone = Lib.extradata and Lib.extradata.waypoint_zone,
		realzone = Lib.extradata and Lib.extradata.waypoint_realzone,
		subzone = Lib.extradata and Lib.extradata.waypoint_subzone,
		minizone = Lib.extradata and Lib.extradata.waypoint_minizone,
		region = Lib.extradata and Lib.extradata.waypoint_region,
		waypoint = Lib.extradata and Lib.extradata.waypoint}
	AddNode(Lib.endnode)

	if Lib.extradata and Lib.extradata.multiple_ends then
		for i, data in ipairs(Lib.extradata.multiple_ends) do
			local node = LibRover_Node:New(data)
			node.type = "end"
			AddNode(node)
		end
	end

	Lib.startnode = LibRover_Node:New{m = lam, f = 0, x = lax, y = lay, type = "start",
		player = Lib.start_is_player}
	if Lib.startnode.player then
		Lib.startnode.zone = GetZoneText and GetZoneText() or ""
		Lib.startnode.realzone = GetRealZoneText and GetRealZoneText() or ""
		Lib.startnode.subzone = GetSubZoneText and GetSubZoneText() or ""
		Lib.startnode.minizone = GetMinimapZoneText and GetMinimapZoneText() or ""
		Lib.startnode.indoors = apibool(IsIndoors)
		Lib.startnode.swimming = apibool(IsSwimming)
	end

	Lib:SetupInitialQuickTravel(Lib.startnode)

	-- This allows for forcing the next node to be visited - like, flying on a taxi enforces the
	-- destination point.
	if Lib.force_next then
		local meta = Lib.force_next_manualmeta or {mode = "taxi", cost = COST_FORCED, time = 0}
		Lib.startnode:AddNeigh(Lib.force_next, meta)
	end

	AddNode(Lib.startnode)

	-- clear calculation garbage
	for ni, node in ipairs(allnodes) do
		for i, field in ipairs(temp_fields_i) do node[field] = nil end
	end

	Lib.startnode.cost = 0
	Lib.startnode.time = 0

	Lib.opennodes:Clear()
	Lib.startnode.status = "open"
	Lib.opennodes:Add(Lib.startnode)

	Lib.initializing_path = false
end

-- One step of the search in Lib.thread, returning what the driver acts on: the first call sets
-- the path up, every later one runs one A* step. A state table rather than a thread: the
-- 1.12.1 client has no coroutine library.
local function PathStep(state)
	if state.phase == "init" then
		Lib:InitializePath()
		state.phase = "search"
		return "PENDING"
	end

	local code, ret = Lib:StepPath()
	if not code then code = "ERROR" end
	if code == "SUCCESS" then
		if not Lib.success_endnode then
			Lib.success_endnode = ret
		else
			code = "PENDING"
		end
		Lib.low_priority = true
	end

	state.steps = state.steps + 1
	if state.steps > 10000 then code = "ERROR" end
	if code == "END" or code == "ERROR" then
		state.dead = true
		Lib.pathfinding_speed_override = nil
	end
	return code, ret
end

local opened_count, closed_count = 0, 0

function Lib:StepPath()  -- THE WORKHORSE.
	Lib.calculation_step = Lib.calculation_step + 1

	local current = Lib.opennodes:RemoveCheapest()
	if not current then return "END" end

	local _ZoneMeta = Lib.data.ZoneMeta
	local cost_debugging = Lib.debug

	current.status = "closed"
	closed_count = closed_count + 1

	if current.type == "end" then return "SUCCESS", current end

	local speeds = Lib.maxspeedinzone[current.m]
	local maxspeed, runspeed = speeds[1], speeds[2]

	local comfort = Lib:GetCFG("pathfinding_comfort") or 0
	local banned_any = next(Lib.banned_nodes)

	for neigh, neighlink in current:IterNeighs() do
		local mode = neighlink.mode
		local failed_cond = neighlink.cond_fun and not neighlink.cond_fun()

		if neigh.status ~= "closed" and not failed_cond then
			local costdesc
			if cost_debugging then costdesc = "" end

			local mycost, mytime, myspeed

			--[[  DETERMINE THE MOVEMENT COST, BASING ON LINK MODE ]]--

			if neighlink.cost and mode ~= "taxi" then
				mytime = neighlink.cost  -- timetabled!

			elseif mode == "taxi" then
				-- taxi flights are not penalized on knowledge here; departure and arrival are.
				mytime = neighlink.cost
					or getdist(current, neigh) * 1.2  -- taxis fly in wide curves...
						/ (BASE_SPEED * 4.3)

			elseif mode == "tram" then
				mytime = COST_TRAM

			elseif mode == "portal" then
				mytime = neighlink.cost or COST_PORTAL
				if Lib:GetCFG("frown_on_portals") then mytime = mytime * 5 end

			elseif mode == "ship" or mode == "zeppelin" then
				mytime = COST_SHIP_DEFAULT

			-- walking away from a taxi we had to land on means we flew to an unknown point
			elseif mode == "walk" and current.parentlink and current.parentlink.mode == "taxi"
			   and current:IsTaxiKnown() == false then
				mytime = COST_FAILURE + 1
				if cost_debugging then costdesc = costdesc .. "no arrival at unknown taxi; " end

			else -- walk
				local dist = neighlink.dist
				if not dist then
					dist = getdist(current, neigh)
					neighlink.dist = dist
				end
				local speed = runspeed * BASE_SPEED
				if speed == 0 then speed = 0.001 end
				mytime = dist / speed
				if cost_debugging then
					costdesc = costdesc .. strformat("dist %.1f, speed %.1f; ", dist, speed)
				end
				if current.parentlink and current.parentlink.mode ~= "walk" and speed > BASE_SPEED then
					mytime = mytime + COST_MOUNTUP
					if cost_debugging then costdesc = costdesc .. "mountup; " end
				end
				myspeed = speed
			end

			local prevmode = current.parentlink and current.parentlink.mode
			local costprev = neighlink['cost_prev_' .. (prevmode or "")]
			if costprev then
				if type(costprev) == "string" and strsub(costprev, 1, 1) == "*" then
					mytime = mytime * tonumber(strsub(costprev, 2))
				else
					mytime = costprev
				end
			end

			mytime = mytime or neighlink.cost or 0
			mytime = mytime + (neighlink.penalty or 0)

			mycost = mytime

			if neigh.costmod or current.costmod or neighlink.costmod then
				mycost = mycost * tonumber(neigh.costmod or current.costmod or neighlink.costmod)
			end
			if neighlink.mud then mycost = mycost * neighlink.mud end

			if mode == "walk" then mycost = mycost * COSTMOD_WALK end  -- walking sucks, never a beeline

			-- If high level zones are avoided... avoid.
			if mode == "walk" and Lib:GetCFG("avoid_highlevel_zones") then
				local c_hostile = (current.regionobj and current.regionobj.hostile)
					or _ZoneMeta[current.m].hostile
				if c_hostile == true then c_hostile = COSTMOD_HOSTILE end
				local n_hostile = (neigh.regionobj and neigh.regionobj.hostile)
					or _ZoneMeta[neigh.m].hostile
				if n_hostile == true then n_hostile = COSTMOD_HOSTILE end

				local hostile
				if c_hostile and n_hostile then hostile = (c_hostile + n_hostile)/2
				else hostile = c_hostile or n_hostile end
				if hostile then mycost = mycost * hostile end
			end

			-- Penalize uncomfortable modes of travel.
			local changed_modes = current.changed_modes or 0
			if comfort > 0 and mode ~= "portal" and mode ~= "teleport" and mode ~= "ship"
			   and mode ~= "zeppelin" then
				if mode ~= prevmode and mode ~= "taxi" and prevmode ~= "taxi" then
					changed_modes = changed_modes + 1
				end
				if mode == "walk" then
					mycost = mycost * (1 + comfort)
				elseif mode == "taxi" then
					mycost = mycost * (1 - (comfort * COSTMOD_COMFORT_TAXI))
				end
				mycost = mycost * (1 + (comfort * changed_modes * 0.2))
			end

			-- departing from a taxi point we cannot use is bad
			if neigh.type == "taxi" and mode == "walk" then
				local known, desc, couldbe = neigh:IsTaxiKnown()
				if known == false and couldbe == false then
					mycost = mycost + COST_FAILURE + 20
				end
				if not known and cost_debugging then costdesc = costdesc .. "taxi " .. desc .. "; " end
			end

			-- no flyovers: a flight to a point we have not discovered cannot be taken
			if mode == "taxi" and neigh.known == false then
				mycost = mycost + COST_FAILURE + 23
				if cost_debugging then costdesc = costdesc .. "no flyovers; " end
			end

			if banned_any and Lib.banned_nodes[neigh] then
				mycost = mycost + COST_FAILURE + 99
			end

			if neigh.cond_fun and not neigh.cond_fun() then
				mycost = mycost + COST_FAILURE + 21
				if cost_debugging then costdesc = costdesc .. "failed cond_fun; " end
			end

			-- Ban nodes by quest/faction/class.
			if neigh.factionid and Lib:HostReputation(neigh.factionid) < (neigh.factionstanding or 3) then
				mycost = mycost + COST_FAILURE + 100
			elseif neigh.quest and not Lib:HostQuestComplete(neigh.quest) then
				mycost = mycost + COST_FAILURE + 100
			elseif neigh.class then
				local _, class = UnitClass("player")
				if class ~= neigh.class then mycost = mycost + COST_FAILURE + 100 end
			end

			if Lib.RestrictMap and current.m ~= Lib.startnode.m then
				mycost = mycost + COST_FAILURE + 100
			end

			-- cost calculation is over.
			local cost = current.cost + mycost
			local time = current.time + mytime

			local updated
			if not neigh.cost or cost < neigh.cost then
				neigh.cost = cost
				neigh.time = time
				neigh.parentlink = neighlink
				neigh.mytime = mytime
				neigh.mycost = mycost
				neigh.parent = current
				neigh.costdesc = costdesc
				neigh.changed_modes = changed_modes
				neigh.speed = myspeed
				updated = true

				-- border opening optimization: open the OTHER end of the door instead.
				if neigh.border and neigh.border ~= "multi" then
					if neigh ~= current.border and not neigh.border_optimization then
						neigh.border_optimization = "border"
					elseif neigh.border_optimization == "border" then
						neigh.border_optimization = "ignore"
					end
				end
			end

			-- With the heap, NEVER ALLOW THE NODE SCORE TO INCREASE. This screws things royally.
			if updated then
				if neigh.status == "open" then
					Lib.opennodes:BubbleUp(neigh)
				else
					Lib.opennodes:Add(neigh)
					neigh.status = "open"
					opened_count = opened_count + 1
				end
			end
		end
	end

	if Lib.calculation_step >= Lib.calculation_step_limit then return "TIMEOUT", current end

	return "PENDING"
end

--[[================ RESULTS ===============]]--

function Lib:Cleanup()
end

local function AngleBetween(n1, n2, n3)
	if not (n1 and n2 and n3) then return 99 end
	local a1 = n2:GetAngleTo(n1)
	local a2 = n2:GetAngleTo(n3)
	if not (a1 and a2) then return 99 end
	local d = mabs(a2 - a1)
	if d > 180 then d = 360 - d end
	return d
end

function Lib:BuildResults(endnode)
	local results = {}
	-- do the backwards walk
	while endnode do
		endnode.link = endnode.parentlink
		tinsert(results, 1, endnode)
		endnode = endnode.parent
	end
	return results
end

function Lib:ReportPath(endnode)
	local results = Lib:BuildResults(endnode)
	Lib.RESULTS = results
	local n_results = tgetn(results)

	wipe(Lib.RESULTS_SKIPPED_START)
	wipe(Lib.RESULTS_SKIPPED_END)

	if Lib.extradata and Lib.extradata.reportEnd then Lib.extradata.endnode = endnode end

	-- TAXI DISPLAY PREPARATION: find the final flight and stamp it onto all flights in a sequence.
	Lib.RESULTS_ASSUMED_TAXI = false
	for i = 2, n_results-1 do
		if results[i].type == "taxi" and results[i].known == nil then Lib.RESULTS_ASSUMED_TAXI = true end
	end

	local first_taxi, prevnode
	for i = 2, n_results do
		local node = results[i]
		if first_taxi and node.link.mode ~= "taxi" then
			-- prevnode is our final taxi, we're on a node after that.
			prevnode.taxiFinal = true
			for j = i-2, first_taxi, -1 do
				if results[j].type == "taxi" then results[j].taxiDestination = prevnode end
			end
			first_taxi = nil
		end
		if not first_taxi and node.type == "taxi" and node.link.mode == "walk" then
			first_taxi = i
		end
		prevnode = node
	end

	local point_templates = Lib.data.point_context_templates
	local point_templates_keys = Lib.point_templates_keys
	if not point_templates_keys then
		point_templates_keys = {}
		for i, pair in ipairs(point_templates) do point_templates_keys[pair[1]] = pair[2] end
		Lib.point_templates_keys = point_templates_keys
	end

	-- PREPARE NODES FOR DISPLAY. Assign titles based on situation.
	for n = 1, n_results do
		local node = results[n]
		node.prev = results[n-1]
		node.next = results[n+1]
		local nextnode = node.next
		local text

		if node.waypoint and node.waypoint.goal then text = node.waypoint:GetTitle() end

		local function _GetNodeMode(nd)
			return nd.link and (nd.link.template or nd.link.mode) or "walk"
		end
		local function _GetNodeType(nd)
			return nd.taxioperator or nd.subtype or nd.type or "*"
		end

		local travelmode = _GetNodeMode(node)
		local nodetype = _GetNodeType(node)
		if nodetype == "start" then travelmode = "start" end

		local a_b = travelmode .. "_" .. nodetype
		local a_b__c_d = ""
		if nextnode then
			a_b__c_d = travelmode .. "_" .. nodetype .. "__"
				.. _GetNodeMode(nextnode) .. "_" .. _GetNodeType(nextnode)
		end
		node.a_b = a_b
		node.a_b__c_d = a_b__c_d

		text = text or node:GetActionTitle(node.prev, node.next) or node.title
			or (node.link and node.link.title)

		if not text then
			for i, patpair in ipairs(point_templates) do
				local pat = strgsub(patpair[1], "%*", "%%w*")
				if strfind(a_b__c_d, "^" .. pat .. "$") then text = patpair[2] break end
				if strfind(a_b, "^" .. pat .. "$") then text = patpair[2] break end
				if travelmode == pat then text = patpair[2] break end
				if nodetype == pat then text = patpair[2] break end
			end
		end
		text = text or "walk"

		node.is_arrival = (a_b == "taxi_taxi" or a_b == "ship_ship" or a_b == "zeppelin_zeppelin"
			or a_b == "portal_portal" or text == "arrive" or node.taxioperator)
			and node ~= Lib.force_next

		if node == Lib.force_next and strfind(a_b__c_d, "taxi_.-__taxi_.-") then
			text = 'forced_taxi__taxi_taxi'
		end
		if strfind(a_b__c_d, ".*_taxi__taxi_taxi") then
			local known, desc, couldbe = node:IsTaxiKnown()
			if not known and couldbe then text = 'taximaybe' end
		end

		while point_templates_keys[text] do text = point_templates_keys[text] end  -- do redirects

		local nextmap = MapName(nextnode
			and ((nextnode.taxiDestination and nextnode.taxiDestination.m) or nextnode.m) or 0)

		text = strgsub(text, "{node}", node:GetText(node.prev, node.next) or "?")
		text = strgsub(text, "{name}", node.localname or node.name or "?")
		text = strgsub(text, "{next_name}", nextnode
			and ((nextnode.taxiDestination
				and (nextnode.taxiDestination.localname or nextnode.taxiDestination.name))
				or nextnode.localname or nextnode.name or nextmap) or "?")
		text = strgsub(text, "{map}", MapName(node))
		text = strgsub(text, "{next_map}", (nextnode and nextnode.title) or nextmap or "?")
		text = strgsub(text, "{next_title}", (nextnode and nextnode.title) or "?")
		text = strgsub(text, "{next_port}", nextnode
			and ((nextnode.port and (nextnode.port .. ", " .. nextmap)) or nextmap) or "?port?")
		text = strgsub(text, "{bordermap}",
			(nextnode and nextnode.border == node) and MapName(nextnode) or MapName(node))
		text = strgsub(text, "{item}", Lib.L["item"] or "item")
		text = strgsub(text, "{npc}", node.localnpc or node.npc or "?")
		text = strgsub(text, "{spell}", Lib.spellnames and node.spell
			and Lib.spellnames[node.spell] or "Teleport")

		node.text = text
		node.maplabel = node:GetText(node.prev, node.next)
	end

	--== LOOSE START OPTIMIZATION: drop the nodes we are standing on top of
	if Lib:GetCFG("remove_standing") then
		local sn = results[1]
		local standing_nr
		for i = 2, tgetn(results)-1 do
			if getdist(sn, results[i]) < (results[i].radius or STANDING_ON_NODE_RADIUS) then
				standing_nr = i
				break
			end
		end

		if standing_nr then
			local dobreak
			for i = 2, standing_nr do
				local nd = results[i]
				if nd.noskip or nd.type == "portal" or nd.type == "taxi" or nd.type == "ship"
				or nd.type == "zeppelin" then dobreak = true break end
			end
			if not dobreak then
				local standing_node = results[standing_nr]
				local nr
				repeat
					nr = results[2]
					sn.link = nr.link
					tremove(results, 2)
					tinsert(Lib.RESULTS_SKIPPED_START,
						{nr, "standing on [" .. standing_node.num .. "]"})
				until nr == standing_node
			end
		end
	end

	--=========== HAIRPIN OPTIMIZATION
	if Lib:GetCFG("remove_hairpins") then
		local sn, n1, n2 = results[1], results[2], results[3]

		while sn and n1 and n2
		and (n1.link.mode == "walk" or n1.link.mode == "road")
		and n2.link and (n2.link.mode == "walk" or n2.link.mode == "road" or n2.link.mode == "border")
		and (
			-- standing on the point
			(getdist(sn, n1) < (tonumber(n1.radius) or STANDING_ON_NODE_RADIUS)
				and sn.region == n1.region)
			or
			-- standing next to the point, acute angle
			(getdist(sn, n1) < getdist(n1, n2)
				and AngleBetween(sn, n1, n2) < (90 - (getdist(sn, n1)/getdist(n1, n2))*70)
				and sn.region == n1.region)
		)
		do
			sn.link = n1.link
			tremove(results, 2)
			tinsert(Lib.RESULTS_SKIPPED_START, {n1, "hairpin"})
			sn, n1, n2 = results[1], results[2], results[3]
		end

		-- repeat for the pre-end point
		local n = tgetn(results)
		if n > 2 then
			local e1, e2, en = results[n-2], results[n-1], results[n]
			if e2.link and (e2.link.mode == "walk" or e2.link.mode == "border")
			and e1.link and e1.link.mode == "walk"
			and (getdist(e2, en) < (e2.radius or STANDING_ON_NODE_RADIUS_END)
				or (getdist(e2, en) < (e2.radius or STANDING_ON_NODE_RADIUS_END)*3
					and AngleBetween(e1, e2, en) < 45))
			and e1.type ~= "taxi"
			then
				e1.link = e2.link
				tremove(results, n-1)
				tinsert(Lib.RESULTS_SKIPPED_END, {e1, "pre-end"})
			end
		end
	end
	--============ HAIRPIN OPTIMIZATION ENDS.

	for i = 1, tgetn(results) do
		local node = results[i]
		Lib:Debug("%d. %s -- %s", i-1,
			node.type == "start" and "START" or tostring(node.text), node:tostring())
	end

	lastupdate = 0

	if tgetn(results) == 2 and not results[2].noskip then
		if getdist(results[1], results[2]) < (Lib.arrival_distance or 10) then
			return Lib:ReportArrival()
		end
	end

	if Lib.PathFoundHandler then
		local returnData = Lib.extradata or {}
		returnData.fromme = Lib.startnode.player
		Lib.PathFoundHandler("success", results, returnData)
	end

	Lib:SendMessage("LIBROVER_TRAVEL_REPORTED", 0)
	Lib.pathfinding_speed_override = nil
end

function Lib:ReportFail(reason)
	Lib:Debug("Report: FAIL! %s", tostring(reason))
	if Lib.PathFoundHandler then
		Lib.PathFoundHandler("failure", nil, Lib.extradata, reason)
	end
	Lib:Stop()
end

function Lib:ReportArrival()
	Lib:Debug("Report: Arrived.")
	if Lib.PathFoundHandler then Lib.PathFoundHandler("arrival") end
	Lib:Stop()
end

--[[================ DRIVER ===============]]--

local tmp_progress = {}

function Lib:OnUpdate(elapsed)
	if Lib.startup_steps then
		Lib:StartupStep()
		return
	end

	if Lib.calculating and Lib.thread then
		local time_slot = Lib.pathfinding_speed_override or Lib:GetCFG("pathfinding_speed") or 1
		if Lib.low_priority then time_slot = 1 end
		local time_slot_remaining = time_slot
		local code, ret, resumed

		local hardlimit = 10000
		while time_slot_remaining >= 0 and Lib.calculating do
			local slot_time = ms()
			if Lib.thread.dead then Lib.calculating = false return end
			resumed, code, ret = pcall(PathStep, Lib.thread)
			if not resumed then
				AddError("Travel System crashed: %s", tostring(code))
				Lib:Debug("Travel System crashed: %s", tostring(code))
				Lib.calculating = false
				return
			end
			if code == "SUCCESS" then time_slot_remaining = 0 end
			time_slot_remaining = time_slot_remaining - (ms() - slot_time)

			if not code or code == "ERROR" or code == "END" then Lib.calculating = nil end
			if code == "SUCCESS" then Lib.calculating = nil end

			hardlimit = hardlimit - 1
			if hardlimit < 0 then break end
		end

		-- Detect soft failure - path was found, but unacceptably long.
		if code == "SUCCESS" and Lib.success_endnode and Lib.success_endnode.cost >= COST_FAILURE then
			Lib:Debug("Path found has cost %d, that's unacceptable. Failing.", Lib.success_endnode.cost)
			Lib.RESULTS_FAIL = Lib:BuildResults(Lib.success_endnode)
			code = "END"
		end

		if code == "PENDING" or code == "TIMEOUT" then
			if not Lib.quiet and not Lib.success_endnode and Lib.PathFoundHandler then
				tmp_progress.progress = Lib.calculation_step * 0.001
				Lib.PathFoundHandler("progress", nil, tmp_progress)
			end
		elseif code == "SUCCESS" then
			Lib:ReportPath(Lib.success_endnode)
			Lib:Cleanup()
		elseif code == "END" then
			Lib:Debug("Path FAILED after %d calculations.", Lib.calculation_step)
			Lib:ReportFail("Destination unreachable.")
			Lib:Cleanup()
		elseif code == "ERROR" then
			Lib:ReportFail("Error finding path.")
		end

		lastupdate = 0

	elseif Lib.updating and lbm then

		if apibool(UnitOnTaxi, "player") then
			-- Restart path searching with a different starting point: at the taxi destination.
			if not Lib.force_next and not Lib.force_next_failed then
				Lib.force_update_now = true
			end
			Lib.force_next = LibTaxi.LastTaxi and LibTaxi.LastTaxi.node
			Lib.force_next_failed = not Lib.force_next
		else
			Lib.force_next = Lib.force_next_manual
		end

		lastupdate = lastupdate + elapsed
		if lastupdate > Lib.update_interval then
			elapsed_for_update = elapsed_for_update + elapsed
			if elapsed_for_update > UPDATE_FREQ then
				elapsed_for_update = 0
				local x, y, m = Lib:GetPlayerPosition()
				if x and y and m and m > 0 then
					local dist = getdist({m = m, x = x, y = y}, {m = lam, x = lax, y = lay})
					if dist and dist > 50 and dist < 99999999 then
						Lib:Debug("Player moved %d yd, updating route quietly.", dist)
						Lib.quiet = true
						Lib.force_update_now = true
					end
				end
			end
		end

		if Lib.force_update_now then
			Lib.force_update_counter = (Lib.force_update_counter or 0) + 1
			if Lib.force_update_counter > 50 then
				Lib.force_update_now = false
				Lib.force_update_counter = 0
				return
			end
			local x, y, m
			if Lib.startnode then
				if Lib.startnode.player then
					x, y, m = Lib:GetPlayerPosition()
					if not x or not y or not m or m <= 0 then return end
				else
					x, y, m = Lib.startnode.x, Lib.startnode.y, Lib.startnode.m
				end
			else
				return
			end
			Lib.force_update_now = false
			Lib:FindPath(m, x, y, lbm, lbx, lby, Lib.PathFoundHandler, Lib.extradata, nil, Lib.quiet)
			lastupdate = 0
		end
	end
end

function Lib:Abort(whence, quiet)
	Lib:Debug("Aborting from: %s.", tostring(whence or "somewhere"))
	wipe(Lib.delayeddata)
	if Lib.delayfindpath_timer then
		Lib:CancelTimer(Lib.delayfindpath_timer)
		Lib.delayfindpath_timer = nil
	end
	Lib.updating = false
	Lib.calculating = false
	Lib.thread = nil
	if not quiet and Lib.PathFoundHandler then
		Lib.PathFoundHandler("failure", nil, Lib.extradata, "aborted")
	end
end

function Lib:Stop()
	Lib.calculating = false
	Lib.thread = nil
	Lib:Debug("stopping gracefully, will update")
end

--[[================ EVENTS ===============]]--

function Lib:OnZoneChanged()
	if Lib.updating then Lib:UpdateNow("quiet") end
end

function Lib:OnSpellsChanged()
	spellbook_stamp = nil
	Lib.last_speed_check = nil
	if Lib.updating then Lib:UpdateNow("quiet") end
end

function Lib:OnTaxiKnowledgeChanged()
	if Lib.updating then Lib:UpdateNow("quiet") end
end

function Lib:OnTaxiStateChanged()
	local ontaxi = apibool(UnitOnTaxi, "player")
	if ontaxi == Lib.unitOnTaxi then return end
	Lib.unitOnTaxi = ontaxi
	if not ontaxi then
		-- landed: forget the forced destination and re-plan from here
		Lib.force_next = nil
		Lib.force_next_failed = nil
	end
	if Lib.updating then Lib:UpdateNow("quiet") end
end

--[[================ DEBUG HELPERS ===============]]--

function Lib:Explain()
	local out = {}
	tinsert(out, strformat("LibRover: %d nodes, ready=%s, %d errors",
		tgetn(allnodes), tostring(Lib.ready), tgetn(Lib.ERRORS)))
	for t, list in pairs(Lib.nodes) do
		if type(list) == "table" and tgetn(list) > 0 and t ~= "all" then
			tinsert(out, strformat("  %s: %d", t, tgetn(list)))
		end
	end
	if Lib.RESULTS then
		tinsert(out, strformat("last path: %d legs", tgetn(Lib.RESULTS)))
		for i, node in ipairs(Lib.RESULTS) do
			tinsert(out, strformat("  %d. %s | %s", i-1, tostring(node.text), node:tostring()))
		end
	end
	return table.concat(out, "\n")
end

function Lib:PathToString(path)
	local out = {}
	for i, node in ipairs(path or Lib.RESULTS or {}) do
		tinsert(out, strformat("%d. %s", i-1, tostring(node.text)))
	end
	return table.concat(out, "\n")
end

function Lib:FindNode(map, f, x, y)
	for i, node in ipairs(allnodes) do
		if node.m == map and mabs(node.x - x) < 0.005 and mabs(node.y - y) < 0.005 then
			return node
		end
	end
end
