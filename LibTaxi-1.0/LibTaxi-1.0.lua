--[[
Name: LibTaxi-1.0
Revision: $Rev: 1 $
Author(s): sinus (sinus@sinpi.net); WoW 1.12.1 port
Description: A library recording all the flight paths currently known to the character.
Dependencies: LibStub, CallbackHandler-1.0, AceEvent-3.0, LibHereBeDragons-1.0
License: Free for non-commercial use, except for Zygor Guides.
]]

local MAJOR_VERSION, MINOR_VERSION = "LibTaxi-1.0", 2

assert(LibStub, MAJOR_VERSION .. " requires LibStub")

local Lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not Lib then return end

local AceEvent = LibStub("AceEvent-3.0")
local HBD = LibStub("LibHereBeDragons-1.0")
AceEvent:Embed(Lib)

local _G = _G or getfenv(0)

local tinsert, tremove, tgetn = table.insert, table.remove, table.getn
local format, gsub, strfind = string.format, string.gsub, string.find
local ceil = math.ceil
local pairs, ipairs, type, tonumber, tostring = pairs, ipairs, type, tonumber, tostring
local setmetatable, rawget, pcall, unpack = setmetatable, rawget, pcall, unpack
local GetTime, GetLocale = GetTime, GetLocale

-- Continents are LibHereBeDragons-1.0 map ids, keyed by its continent index.
local KALIMDOR, EASTERN_KINGDOMS = 13, 14
local CONTINENT_BY_C = { KALIMDOR, EASTERN_KINGDOMS }
local IS_CONTINENT = { [KALIMDOR] = true, [EASTERN_KINGDOMS] = true }

-- Node states, as TaxiNodeGetType() reports them.
Lib.FlightPathState = { Current = 0, Reachable = 1, Unreachable = 2 }
local STATE_CURRENT = Lib.FlightPathState.Current
local STATE_UNREACHABLE = Lib.FlightPathState.Unreachable

-- LibStub copies no state between versions.
Lib.master = Lib.master or {}
Lib.saved_tables = Lib.saved_tables or {}
Lib.errors = Lib.errors or {}
Lib.path2cont = Lib.path2cont or {}
Lib.fc_by_tag = Lib.fc_by_tag or {}
Lib.fcnames_by_tag = Lib.fcnames_by_tag or {}
Lib.fnode_by_tag = Lib.fnode_by_tag or {}
Lib.npc2node = Lib.npc2node or {}

local function wipe(t)
	for k in pairs(t) do t[k] = nil end
	table.setn(t, 0)
	return t
end

function Lib:SetDebug(on, func)
	Lib.debug = not not on
	Lib.debugfunc = func
end

function Lib:Debug(s, ...)
	if not Lib.debug then return end
	local msg = s
	if arg.n > 0 then
		local ok, formatted = pcall(format, s, unpack(arg, 1, arg.n))
		msg = ok and formatted or s
	end
	if Lib.debugfunc then
		Lib.debugfunc(msg)
	else
		DEFAULT_CHAT_FRAME:AddMessage("LibTaxi: " .. msg)
	end
end

--[[================ DATA ===============]]--

-- data.lua and the locale files are plain data in globals, because the client may run them
-- before this file. Adopted at load and again at Startup, so either order works.
local function AdoptData()
	if _G.LibTaxi_Data then
		Lib.data = _G.LibTaxi_Data
		Lib.taxipoints = Lib.data.taxipoints
		Lib.flightcost = Lib.data.flightcost
		_G.LibTaxi_Data = nil
	end
	if _G.LibTaxi_Locales then
		local T = _G.LibTaxi_Locales[GetLocale()]
		if T then
			Lib.TaxiNames_Local = T.TAXINAMES
			Lib.NpcNames_Local = T.NPCNAMES
		end
		_G.LibTaxi_Locales = nil
	end
end
AdoptData()

-- All taxis are stored as ENGLISH; lookups of a client-supplied name need pre-translation.
local function SetupNames()
	if Lib.TaxiNames_English then return end
	local warned = {}
	local locale = GetLocale()
	local mt = { __index = function(t, k)
		if type(k) == "string" and not warned[k] then
			warned[k] = true
			tinsert(Lib.errors, "taxi name not translated to " .. locale .. ": " .. k)
		end
		return k
	end }

	local loc = Lib.TaxiNames_Local
	if loc then
		for en, lo in pairs(loc) do if lo == true then loc[en] = en end end
		Lib.TaxiNames_English = {}
		for en, lo in pairs(loc) do Lib.TaxiNames_English[lo] = en end
		setmetatable(loc, mt)
		setmetatable(Lib.TaxiNames_English, mt)
	else
		local stub = setmetatable({}, { __index = function(t, k) return k end })
		Lib.TaxiNames_Local, Lib.TaxiNames_English = stub, stub
	end
end

--[[================ HELPERS ===============]]--

-- Every node of a taxipoints-shaped table as c, z, n, node. Collected up front rather than
-- walked in a coroutine: the 1.12.1 client has no coroutine library.
local function EachNode(T)
	local list, i = {}, 0
	for c, cont in pairs(T) do
		for z, zone in pairs(cont) do
			for n, node in ipairs(zone) do
				tinsert(list, { c, z, n, node })
			end
		end
	end
	return function()
		i = i + 1
		local e = list[i]
		if e then return e[1], e[2], e[3], e[4] end
	end
end

-- The client appends the zone to a flight point's name: "Astranaar, Ashenvale", and on a
-- zhCN client with the full-width comma, "十字路口，贫瘠之地".
local function trim_zone(name)
	if type(name) ~= "string" then return name end
	name = gsub(name, ", .*", "")
	name = gsub(name, "\239\188\140.*", "")
	return name
end
Lib.TrimZone = trim_zone

local function is_enemy(f1, f2)
	return (f1 == "A" and f2 == "H") or (f1 == "H" and f2 == "A")
end
Lib.is_enemy = is_enemy

-- Andorhal has separate Horde and Alliance flight points with the same name, so faction is
-- what tells two same-named nodes apart. Read late: UnitFactionGroup answers nil before login.
local playerF
local function PlayerFaction()
	if not playerF then
		local faction = UnitFactionGroup("player")
		if faction == "Alliance" then playerF = "A"
		elseif faction == "Horde" then playerF = "H"
		end
	end
	return playerF
end

-- The tag of a node on an open taxi map: its position in thousandths, truncated.
local function TaxiTag(x, y)
	if not x or not y then return nil end
	return format("%03d:%03d", x * 1000, y * 1000)
end
Lib.TaxiTag = TaxiTag

function Lib:GetMapContinent(m)
	if not m then return nil end
	if IS_CONTINENT[m] then return m end
	local C = HBD:GetCZFromMapID(m)
	return C and CONTINENT_BY_C[C] or nil
end

function Lib:GetCurrentMapContinent()
	return Lib:GetMapContinent(HBD:GetPlayerZone())
end

function Lib:GetTaxiTripTime(tag1, tag2)
	local cont = Lib:GetCurrentMapContinent()
	local costs = cont and Lib.fc_by_tag[cont]
	local node1c = costs and costs[tag1]
	local node2c = costs and costs[tag2]
	if not node1c or not node2c then return false, false, "nodes missing" end

	local time = node1c.neighbors and node1c.neighbors[tag2]
	if time and time > 0 then return time, true end

	local node1n = Lib:FindTaxiByTag(cont, tag1)
	local node2n = Lib:FindTaxiByTag(cont, tag2)
	if not node1n or not node2n then return false, false, "nodes missing" end
	local dist = HBD:GetZoneDistance(node1n.m, nil, node1n.x, node1n.y,
	                                 node2n.m, nil, node2n.x, node2n.y)
	if not dist then return false, false, "no distance" end
	return dist * 1.2 / (7 * 4.5), false
end

--[[================ STARTUP ===============]]--

-- Return three-way node known status.
-- true = known, obviously. false = there's a marker indicating the continent is known, but
-- the node is not. nil = entirely unknown if known :P
Lib.known_by_continent_mt = { __index = function(t, i)
		if rawget(t, i) then
			return true
		else
			local c = Lib.path2cont[i]
			if c and rawget(t, c) then
				return false
			else
				return nil
			end
		end
	end
}

local function InitializeTaxis()
	for c, cont in pairs(Lib.taxipoints) do
		for z, zone in pairs(cont) do
			local m = HBD:GetMapIDFromZoneName(z)
			if not m then
				tinsert(Lib.errors, "unknown zone in taxi data: " .. tostring(z))
			else
				for n, node in ipairs(zone) do
					Lib.path2cont[node.name] = c
					node.m = m
					node.c = Lib:GetMapContinent(m)
					-- data.lua carries percent; everything else here works in 0-1
					if node.x and node.x > 1 then node.x, node.y = node.x / 100, node.y / 100 end
				end
			end
		end
	end
end

function Lib:Startup(newsave)
	AdoptData()
	assert(Lib.taxipoints and Lib.flightcost, MAJOR_VERSION .. " has no data; load data.lua")
	SetupNames()
	PlayerFaction()

	Lib.master = newsave or {}
	setmetatable(Lib.master, Lib.known_by_continent_mt)
	tinsert(Lib.saved_tables, Lib.master)

	InitializeTaxis()
	Lib:CacheTaxiTags()
	Lib:ImportTaxiTimes()
	Lib:MergeData()          -- assigns the tags, then caches and links on them
	Lib:CacheNpcNames()
	Lib:TranslateData()
	Lib:MarkKnownTaxis()

	Lib:HookTakeTaxiNode()

	Lib:RegisterEvent("TAXIMAP_OPENED")
	Lib:RegisterEvent("UI_INFO_MESSAGE")
	Lib:RegisterEvent("UI_ERROR_MESSAGE")
	Lib:RegisterEvent("PLAYER_CONTROL_LOST", "TaxiStateChanged")
	Lib:RegisterEvent("PLAYER_CONTROL_GAINED", "TaxiStateChanged")

	Lib.ready = true
	Lib:Debug("Startup complete.")
end

--[[================ CACHES ===============]]--

-- cache tag->flightcost and tag->name mappings
function Lib:CacheTaxiTags()
	local pf = PlayerFaction()
	for cont, conttaxis in pairs(Lib.flightcost) do
		Lib.fc_by_tag[cont] = Lib.fc_by_tag[cont] or {}
		Lib.fcnames_by_tag[cont] = Lib.fcnames_by_tag[cont] or {}
		for ti, taxi in pairs(conttaxis) do
			if taxi.tag then
				if not is_enemy(taxi.faction, pf) then
					Lib.fc_by_tag[cont][taxi.tag] = taxi
				end
				Lib.fcnames_by_tag[cont][taxi.tag] = taxi.name
			end
		end
	end
end

-- cache tag->node mappings
function Lib:CacheTaxiPoints()
	local pf = PlayerFaction()
	for c, z, n, node in EachNode(Lib.taxipoints) do
		Lib.fnode_by_tag[c] = Lib.fnode_by_tag[c] or {}
		if not is_enemy(pf, node.faction) then
			if node.taxitag then Lib.fnode_by_tag[c][node.taxitag] = node end
			node._zone = z
		end
	end
end

function Lib:FindTaxiByTag(cont, tag)
	if not cont or not tag then return nil end
	Lib.fnode_by_tag[cont] = Lib.fnode_by_tag[cont] or {}
	return Lib.fnode_by_tag[cont][tag]
end

local aliases = { ["Stormwind City"] = "Stormwind", ["Theramore Isle"] = "Theramore" }
local findtaxi_cache = {}
function Lib:FindTaxi(name, trim)
	if type(name) ~= "string" then return nil end
	if findtaxi_cache[name] then return findtaxi_cache[name] end
	local key = name

	if trim then name = trim_zone(name) end
	name = aliases[name] or name
	local trimmed = trim_zone(name)
	local pf = PlayerFaction()

	for c, z, n, node in EachNode(Lib.taxipoints) do
		if not is_enemy(pf, node.faction) and (
			node.name == name  -- raw name, pretty rare
			or (not node.namestrict and node.name == trimmed)  -- node name with zone appended
		)
		then
			findtaxi_cache[key] = node
			return node
		end
	end
end

-- Pull "flightcost" data into taxipoints.
function Lib:MergeData()
	local FC = Lib.flightcost
	if not FC then tinsert(Lib.errors, "need flightcosts data") return end
	local pf = PlayerFaction()

	-- for each taxi NPC find its tag.
	for c, z, ni, node in EachNode(Lib.taxipoints) do
		local found
		for fi, fcdata in pairs(FC[c] or {}) do
			if strfind(fcdata.name, node.name, 1, true)
			and fcdata.taxioperator == node.taxioperator
			and not is_enemy(fcdata.faction, node.faction)
			then
				found = 1
				node.taxitag = fcdata.tag
				break
			end
		end
		if not found then
			tinsert(Lib.errors, node.name .. " (" .. z .. ") (faction:" .. (node.faction or "-")
				.. ") [" .. (node.taxioperator or "") .. "] didn't get a taxitag, no match found by name in LibTaxi.flightcost")
		end
	end

	Lib:CacheTaxiTags()
	-- the nodes only have their tags now, so this is where they become findable by tag
	Lib:CacheTaxiPoints()

	-- for each taxi NPC assign neighbors by tag. LibRover Node uses this for cost calc.
	for c, z, ni, node in EachNode(Lib.taxipoints) do
		if not is_enemy(node.faction, pf) then
			local fcdata = node.taxitag and Lib.fc_by_tag[c] and Lib.fc_by_tag[c][node.taxitag]
			if not node.taxitag then
				tinsert(Lib.errors, "Why did " .. node.name .. " not get a tag?")
			elseif not fcdata then
				tinsert(Lib.errors, "taxi " .. node.name .. " " .. node.taxitag .. " has no fcdata?")
			elseif fcdata.neighbors then
				node.taxicosts = {}
				for neighbortag, cost in pairs(fcdata.neighbors) do
					local neighbor = Lib.fnode_by_tag[c] and Lib.fnode_by_tag[c][neighbortag]
					if neighbor then
						node.taxicosts[neighbor] = cost
					else
						node.taxicosts[neighbortag] = cost  -- resolved by tag instead
					end
				end
			end
		end
	end
end

function Lib:TranslateData()
	local LOCALE = GetLocale()
	Lib.master.translation = Lib.master.translation or {}
	Lib.master.translation[LOCALE] = Lib.master.translation[LOCALE] or {}
	Lib.translation = Lib.master.translation[LOCALE]

	for c, z, n, node in EachNode(Lib.taxipoints) do
		local localname = node.taxitag and rawget(Lib.translation, node.taxitag)
		if not localname and Lib.TaxiNames_Local then
			localname = rawget(Lib.TaxiNames_Local, node.name)
			if localname == true then localname = node.name end
		end
		node.localname = localname or node.localname
	end
end

--[[================ KNOWLEDGE ===============]]--

function Lib:LearnTaxi(node, learn)
	node.known = learn
	Lib.master[node.name] = learn
	if node.taxitag then Lib.master[node.taxitag] = learn end
end

function Lib:MarkKnownTaxis()  -- Fill .known fields using saved data.
	for c, cont in pairs(Lib.taxipoints) do
		for z, zone in pairs(cont) do
			for n, node in ipairs(zone) do
				if node.taxioperator and node.taxioperator == "blackcat" then  -- usable by anyone
					Lib:LearnTaxi(node, true)
				else
					-- the tag first, then the name: a saved table written on a client whose
					-- TaxiNodePosition disagrees with our tags is still readable by name
					local known = Lib.master[node.taxitag]
					if known == nil then known = Lib.master[node.name] end
					if known ~= nil then  -- we know it, or we know we don't: simplest case
						node.known = known
						if type(node.known) == "string" then node.known = true end
					end
					-- DON'T GUESS! LibRover will "guess" if it wants to.
				end
			end
		end
	end
end

function Lib:ClearContinentKnowledge(cont, operator, status)
	if not cont then cont = Lib:GetCurrentMapContinent() end
	if not cont or not Lib.taxipoints[cont] then return end

	for z, zone in pairs(Lib.taxipoints[cont]) do
		for n, node in ipairs(zone) do
			if node.taxioperator == operator or operator == "all" then
				node.known = status
				Lib.master[node.name] = status
				if node.taxitag then Lib.master[node.taxitag] = status end
			end
		end
	end
	Lib.master["c_" .. cont] = status
end

function Lib:ClearAllKnowledge(status)
	for c, cont in pairs(Lib.taxipoints) do
		Lib:ClearContinentKnowledge(c, "all", status)
	end
	if status ~= true then
		-- keep the measured data: trip times and localized names are not knowledge
		local translation, taxitimes = Lib.master.translation, Lib.master.taxitimes
		wipe(Lib.master)
		Lib.master.translation, Lib.master.taxitimes = translation, taxitimes
	end
end

function Lib:ResetKnowledge()
	Lib:ClearAllKnowledge()
	Lib:MarkKnownTaxis()
end

-- return: is_known, is_suspicious
function Lib:IsContinentKnown(cont)
	if not cont then cont = Lib:GetCurrentMapContinent() end
	if rawget(Lib.master, "c_" .. (cont or 0)) ~= nil then
		return true, false  -- return whatever we know
	else
		return false, true
	end
end

function Lib:MarkContinentSeen(cont, operator)
	if not cont or not Lib.taxipoints[cont] then return end
	Lib:Debug("Marking all unseen nodes on continent %s as unknown.", tostring(cont))
	for z, zone in pairs(Lib.taxipoints[cont]) do
		for ni, node in ipairs(zone) do
			-- node.operator, not node.taxioperator: the data sets neither, so with the default
			-- operator (nil) every unseen node on the continent is falsified.
			if node.operator == operator and node.known == nil then Lib:LearnTaxi(node, false) end
		end
	end
	if not operator then
		Lib.master["c_" .. cont] = true
	end
end

function Lib:MarkNeightboursUnknown(node)
	if not node then
		Lib:Debug("MarkNeightboursUnknown got no node")
		return
	end

	if not node.n then
		Lib:Debug("MarkNeightboursUnknown node has no neighbours")
		return
	end

	for _, neigh in pairs(node.n) do
		if neigh[1] and neigh[1].taxitag then
			Lib:LearnTaxi(neigh[1], false)
		end
	end
	Lib:MarkContinentSeen(node.c, node.operator)
end

-- cache flight master name -> node, in English and, where the locale file has one, localized.
-- NPC names come from the server, so a localized realm answers UnitName with the local name.
function Lib:CacheNpcNames()
	local localnames = Lib.NpcNames_Local
	local pf = PlayerFaction()
	for c, z, n, node in EachNode(Lib.taxipoints) do
		if not is_enemy(pf, node.faction) then
			if node.npc then Lib.npc2node[node.npc] = node end
			local localized = localnames and node.npcid and localnames[node.npcid]
			if localized then
				node.localnpc = localized
				Lib.npc2node[localized] = node
			end
		end
	end
end

-- 1.12 has no UnitGUID, so the flight master is recognised by its name.
function Lib:GetTaxiByTarget()
	local name = UnitName("target")
	if not name then return end
	return Lib.npc2node[name]
end

local minimap_exceptions = {
	["Trade District"] = "Stormwind",
	["The Great Forge"] = "Ironforge",
	["Valley of Strength"] = "Orgrimmar",
}

function Lib:LearnCurrentTaxi(if_unlearn)
	local learn = true  if if_unlearn == false then learn = false end

	local node = Lib:GetTaxiByTarget()
	if node then
		Lib:LearnTaxi(node, learn)
		Lib:Debug("%slearned by npc, %s", (learn and "" or "un"), node.name)
		return node
	end

	-- NPC not found? try by the zone we're standing in.
	local zonetexts = { GetMinimapZoneText(), GetRealZoneText() }
	for i, zonetext in ipairs(zonetexts) do
		if zonetext and zonetext ~= "" then
			local name = Lib.TaxiNames_English[zonetext] or zonetext
			name = minimap_exceptions[name] or name
			node = Lib:FindTaxi(name, "trim")
			if node then
				Lib:LearnTaxi(node, learn)
				Lib:Debug("%slearned by map, node %s, map %s", (learn and "" or "un"), node.name, zonetext)
				return node
			end
		end
	end

	Lib:Debug("Something failed, map is %s, target is %s, but can't find a taxi here",
		tostring(GetMinimapZoneText()), tostring(UnitName("target")))
end

--[[================ TAXI MAP ===============]]--

-- The tag of a slot on the open taxi map, in the form the data records it. 1.12.1 measures
-- TaxiNodePosition's y from the bottom of the map (Orgrimmar reads 628:556 against the recorded
-- 628:443), the Classic client the tags were taken on from the top; whichever reading the
-- continent's recorded tags know is used, so a client measuring from the top still matches.
local function SlotTag(cont, x, y)
	local tag = TaxiTag(x, y)
	local recorded = cont and Lib.fcnames_by_tag[cont]
	if tag and recorded and not recorded[tag] then
		local flipped = TaxiTag(x, 1 - y)
		if recorded[flipped] then return flipped end
	end
	return tag
end

function Lib:GetTaxiDataBySlot()
	local taxidata = {}
	local cont = Lib:GetCurrentMapContinent()
	for i = 1, NumTaxiNodes() do
		local x, y = TaxiNodePosition(i)
		local taxitype = TaxiNodeGetType(i)
		taxidata[i] = {
			name = TaxiNodeName(i),
			slotIndex = i,
			state = (taxitype == "CURRENT" and 0) or (taxitype == "REACHABLE" and 1) or 2,
			taxitype = taxitype,
			position = { x = x, y = y },
			taxitag = SlotTag(cont, x, y),
		}
	end
	local taxidata_by_slot = {}
	for i, taxi in ipairs(taxidata) do taxidata_by_slot[taxi.slotIndex] = taxi end
	return taxidata, taxidata_by_slot
end

-- Find the node an open taxi map's slot refers to. The tag is the primary key; the node's
-- (translated) name is a second chance for a flight point whose position does not match.
function Lib:FindTaxiBySlotData(cont, taxi)
	local node = Lib:FindTaxiByTag(cont, taxi.taxitag)
	if node then return node, "tag" end
	local name = trim_zone(taxi.name)
	node = Lib:FindTaxi(Lib.TaxiNames_English[name] or name, "trim")
	if node then return node, "name" end
end

-- Scan an open taxi map for node names and "known" status.
function Lib:ScanTaxiMap()
	if not (TaxiFrame and TaxiFrame:IsShown()) then
		Lib:Debug("Map not shown, unable to scan.")
		return
	end

	local cont = Lib:GetCurrentMapContinent()
	if not cont then
		tinsert(Lib.errors, "taxi map scanned outside a known continent")
		return
	end
	Lib:Debug("Scanning map for continent %d...", cont)

	local taxidata = Lib:GetTaxiDataBySlot()

	-- switch to a specific operator
	local current_operator
	for i, taxi in ipairs(taxidata) do
		if taxi.state == STATE_CURRENT then
			local taxinode = Lib:FindTaxiBySlotData(cont, taxi)
			if taxinode then
				current_operator = taxinode.taxioperator
			else
				tinsert(Lib.errors, "current taxi " .. taxi.name .. " [" .. tostring(taxi.taxitag)
					.. "] not found in continent " .. cont .. " data")
			end
			break
		end
	end

	for i, taxi in ipairs(taxidata) do
		local name = trim_zone(taxi.name)
		local taxinode, matchedby = Lib:FindTaxiBySlotData(cont, taxi)

		if taxinode then
			if taxinode.taxioperator == current_operator then
				local known = taxi.state ~= STATE_UNREACHABLE
				Lib:LearnTaxi(taxinode, known)
				Lib:Debug("%s taxi: %s [%s, by %s]", known and "Known" or "Unknown",
					name, tostring(taxi.taxitag), matchedby)
			end
			taxinode.localname = taxinode.localname or name
			if taxinode.taxitag and Lib.translation then
				Lib.translation[taxinode.taxitag] = name
			end
		else
			tinsert(Lib.errors, "NPC missing in continent " .. cont .. " data: " .. name
				.. " [" .. tostring(taxi.taxitag) .. "]")
		end
	end

	Lib:MarkContinentSeen(cont, current_operator)
	Lib:CacheTaxiPoints()
	Lib:SendMessage("LibTaxi_KnowledgeChanged")
end

--[[================ TAKING A TAXI ===============]]--

-- And now, the EVIL. Let's peek into a taxi before it flies.
-- LibTaxi.LastTaxi becomes the node of the last taxi taken!
function Lib:HookTakeTaxiNode()
	if Lib.hooked or not _G.TakeTaxiNode then return end
	Lib.hooked = true
	local original = _G.TakeTaxiNode
	_G.TakeTaxiNode = function(destIndex)
		pcall(Lib.RecordTakenTaxi, Lib, destIndex)
		original(destIndex)
	end
end

function Lib:RecordTakenTaxi(destIndex)
	local cont = Lib:GetCurrentMapContinent()
	local taxidata, taxidata_slots = Lib:GetTaxiDataBySlot()
	local data = taxidata_slots[destIndex]
	if not (data and data.taxitag) then return end

	local last = { fullname = data.name, cont = cont }
	Lib.LastTaxi = last
	last.node = Lib:FindTaxiBySlotData(cont, data)
	if last.node then
		last.name, last.zone = last.node.name, HBD:GetLocalizedMap(last.node.m)
	else
		local _, _, name, zone = strfind(last.fullname, "^(.*), (.*)$")
		last.name, last.zone = name, zone
	end

	local route = {}
	local time = 0
	for routeIndex = 1, GetNumRoutes(destIndex) do
		local src_data = taxidata_slots[TaxiGetNodeSlot(destIndex, routeIndex, true)]
		local dst_data = taxidata_slots[TaxiGetNodeSlot(destIndex, routeIndex, false)]
		if not (src_data and dst_data) then route = {} time = nil break end
		if tgetn(route) == 0 then tinsert(route, src_data) end
		tinsert(route, dst_data)
		local hoptime = Lib:GetTaxiTripTime(src_data.taxitag, dst_data.taxitag)
		if not hoptime then
			time = nil
		elseif time then
			time = time + hoptime
			if routeIndex > 1 then time = time - 3 end  -- deduct for taxis passed on a multi-hop path
		end
	end

	last.route = route
	last.eta = time
	last.departure = GetTime()
	Lib:Debug("TakeTaxiNode proxy, flying to %s (%s), eta %s",
		tostring(data.name), tostring(data.taxitag), tostring(time))
	Lib:SendMessage("LibTaxi_TaxiTaken", last)
end

--[[================ TRIP TIMES ===============]]--

-- A flightcost of 0 means "connected, time unknown". Time the flights we take, so those fill
-- in; a single-hop route is the only one whose time can be attributed to one connection.
function Lib:RecordTripTime(triptime)
	local last = Lib.LastTaxi
	if not last or not last.route or tgetn(last.route) ~= 2 then return end
	local cont = last.cont
	local costs = cont and Lib.fc_by_tag[cont]
	local dep, arr = last.route[1].taxitag, last.route[2].taxitag
	if not (costs and costs[dep] and costs[arr] and costs[dep].neighbors) then return end
	if not costs[dep].neighbors[arr] then return end  -- not a known direct route

	Lib.master.taxitimes = Lib.master.taxitimes or {}
	costs[dep].neighbors[arr] = triptime
	Lib.master.taxitimes[dep .. "_" .. arr] = triptime
	-- assume the reverse route takes the same
	if costs[arr].neighbors and costs[arr].neighbors[dep] == 0 then
		costs[arr].neighbors[dep] = triptime
		Lib.master.taxitimes[arr .. "_" .. dep] = triptime
	end
	Lib:Debug("Travel time from %s to %s = %d seconds.", tostring(last.route[1].name),
		tostring(last.route[2].name), triptime)
end

function Lib:ImportTaxiTimes()
	local times = Lib.master.taxitimes
	if not times then return end
	local loaded = 0
	for k, v in pairs(times) do
		if v > 0 then
			local _, _, tag1, tag2 = strfind(k, "^(.-)_(.*)$")
			for cont, costs in pairs(Lib.fc_by_tag) do
				if costs[tag1] and costs[tag2] and costs[tag1].neighbors
				and (costs[tag1].neighbors[tag2] or 0) == 0 then
					costs[tag1].neighbors[tag2] = v
					loaded = loaded + 1
				end
			end
		end
	end
	Lib:Debug("%d recorded taxi trip times loaded.", loaded)
end

--[[================ EVENTS ===============]]--

function Lib:TAXIMAP_OPENED()
	Lib:ScanTaxiMap()
end

function Lib:UI_INFO_MESSAGE()
	if arg1 == ERR_NEWTAXIPATH then
		local node = Lib:LearnCurrentTaxi()
		Lib:SendMessage("LibTaxi_KnowledgeChanged")
		return node
	end
end

function Lib:UI_ERROR_MESSAGE()
	if arg1 == ERR_TAXINOPATHS then
		local node = Lib:LearnCurrentTaxi()
		Lib:MarkNeightboursUnknown(node)
		Lib:SendMessage("LibTaxi_KnowledgeChanged")
		return node
	end
end

function Lib:TaxiStateChanged()
	local ontaxi = UnitOnTaxi and not not UnitOnTaxi("player")
	if ontaxi == Lib.ontaxi then return end
	Lib.ontaxi = ontaxi
	if ontaxi then
		Lib.departure_time = GetTime()
	elseif Lib.departure_time then
		local triptime = ceil(GetTime() - Lib.departure_time)
		Lib.departure_time = nil
		Lib:RecordTripTime(triptime)
	end
end

_G.LibTaxi = Lib
