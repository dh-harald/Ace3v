-- LibHereBeDragons-1.0 is a data API for the WoW 1.12.1 mapping system.
--
-- A vanilla implementation of the HereBeDragons-1.0 API, built on a static, generated zone
-- table instead of a load-time map sweep.  It replaces Astrolabe-0.2, whose sweep calls
-- GetMapZones(C) once per continent and SetMapZoom(C, Z) once per zone -- and on Unreal
-- Azeroth GetMapZones ignores its argument, so the sweep mismatches a whole continent and
-- Astrolabe's zone geometry is silently zeroed.
--
-- Dependencies: LibStub, CallbackHandler-1.0.

local MAJOR, MINOR = "LibHereBeDragons-1.0", 1
assert(LibStub, MAJOR .. " requires LibStub")

local HBD = LibStub:NewLibrary(MAJOR, MINOR)
if not HBD then return end

local CBH = LibStub("CallbackHandler-1.0")
assert(CBH, MAJOR .. " requires CallbackHandler-1.0")

-- Lua upvalues.  Only math.* -- WoW's global sin/cos/atan2 work in DEGREES.
local PI2 = math.pi * 2
local mabs, msqrt, matan2 = math.abs, math.sqrt, math.atan2
local pairs, type, tonumber, tostring = pairs, type, tonumber, tostring
local tinsert, tgetn = table.insert, table.getn
local strgsub, strlower = string.gsub, string.lower

-- Even math.atan2 is degree-based on some clients; probe rather than assume.
local ATAN2_DEG = mabs(matan2(1, 1) - 45) < 0.01

-- WoW API upvalues
local GetMapInfo, GetPlayerMapPosition = GetMapInfo, GetPlayerMapPosition
local GetCurrentMapContinent, GetCurrentMapZone = GetCurrentMapContinent, GetCurrentMapZone
local SetMapToCurrentZone, SetMapZoom, GetMapZones = SetMapToCurrentZone, SetMapZoom, GetMapZones

local COSMIC_ID = 0

-- Persistent state: LibStub copies nothing between versions.
HBD.mapData          = HBD.mapData or {}
HBD.cosmicData       = HBD.cosmicData or {}
HBD.mapToID          = HBD.mapToID or {}
HBD.nameToID         = HBD.nameToID or {}
HBD.continentZoneMap = HBD.continentZoneMap or {}
HBD.callbacks        = HBD.callbacks or CBH:New(HBD, nil, nil, false)
-- Unnamed: on Unreal Azeroth CreateFrame() rewrites every "-" in a frame name.
HBD.eventFrame       = HBD.eventFrame or CreateFrame("Frame")

local mapData          = HBD.mapData
local cosmicData       = HBD.cosmicData
local mapToID          = HBD.mapToID
local nameToID         = HBD.nameToID
local continentZoneMap = HBD.continentZoneMap

local function wipe(t)
	for k in pairs(t) do t[k] = nil end
	table.setn(t, 0)
	return t
end

--------------------------------------------------------------------------------------------
-- Zone data (generated -- see docs/zone-data.md; regenerate, never hand-edit)
--------------------------------------------------------------------------------------------

--@begin-zonedata@
-- Vanilla zone geometry.  GENERATED -- do not edit; regenerate instead.
--
-- Derived from the vanilla WorldMapArea.dbc: width = loc_left - loc_right,
-- height = loc_top - loc_bottom, and left/top are the zone's minimum x/y in continent
-- yards.  Cross-validated against Astrolabe's WorldMapSize (all 46 zones, all four
-- fields, to within 0.01 yards), the zone extents in pfQuest's DBC-derived minimap
-- table, the map ids in HereBeDragons-Migrate, and the English zone names in
-- LibBabble-Zone-2.2's enUS locale.
--
-- The cosmic world map's size and the two continent offsets onto it are NOT from the
-- DBC -- they are Astrolabe/Questie values, and the Eastern Kingdoms pair is a guess in
-- the original.  They affect cross-continent translation only.

wipe(mapData)
mapData[4] = { 5287.499634, 3524.999878, left = 19029.099487, top = 10991.567139, mapFile = "Durotar", name = "Durotar", C = 1, instance = 1, areaID = 14 }
mapData[9] = { 5137.499878, 3424.999847, left = 15018.682983, top = 13072.817047, mapFile = "Mulgore", name = "Mulgore", C = 1, instance = 1, areaID = 215 }
mapData[11] = { 10133.333008, 6756.249878, left = 14443.683105, top = 11187.400513, mapFile = "Barrens", name = "The Barrens", C = 1, instance = 1, areaID = 17 }
mapData[13] = { 36799.810547, 24533.200195, left = 0.0, top = 0.0, mapFile = "Kalimdor", name = "Kalimdor", C = 1, instance = 1, areaID = 0 }
mapData[14] = { 35199.900391, 23466.600098, left = 0.0, top = 0.0, mapFile = "Azeroth", name = "Eastern Kingdoms", C = 2, instance = 0, areaID = 0 }
mapData[15] = { 2799.999939, 1866.666656, left = 15216.666687, top = 5966.600098, mapFile = "Alterac", name = "Alterac Mountains", C = 2, instance = 0, areaID = 36 }
mapData[16] = { 3599.999878, 2399.999924, left = 16866.666626, top = 7599.933426, mapFile = "Arathi", name = "Arathi Highlands", C = 2, instance = 0, areaID = 45 }
mapData[17] = { 2487.5, 1658.333496, left = 18079.166504, top = 13356.183105, mapFile = "Badlands", name = "Badlands", C = 2, instance = 0, areaID = 3 }
mapData[19] = { 3349.999878, 2233.333984, left = 17241.666626, top = 18033.266113, mapFile = "BlastedLands", name = "Blasted Lands", C = 2, instance = 0, areaID = 4 }
mapData[20] = { 4518.749878, 3012.499817, left = 12966.666748, top = 3629.100342, mapFile = "Tirisfal", name = "Tirisfal Glades", C = 2, instance = 0, areaID = 85 }
mapData[21] = { 4199.999756, 2799.999878, left = 12550.000244, top = 5799.933472, mapFile = "Silverpine", name = "Silverpine Forest", C = 2, instance = 0, areaID = 130 }
mapData[22] = { 4299.999908, 2866.666534, left = 15583.333344, top = 4099.933594, mapFile = "WesternPlaguelands", name = "Western Plaguelands", C = 2, instance = 0, areaID = 28 }
mapData[23] = { 3870.833496, 2581.249756, left = 18185.416504, top = 3666.600342, mapFile = "EasternPlaguelands", name = "Eastern Plaguelands", C = 2, instance = 0, areaID = 139 }
mapData[24] = { 3199.999878, 2133.333252, left = 14933.333374, top = 7066.600098, mapFile = "Hilsbrad", name = "Hillsbrad Foothills", C = 2, instance = 0, areaID = 267 }
mapData[26] = { 3850.0, 2566.666626, left = 17575.0, top = 5999.933472, mapFile = "Hinterlands", name = "The Hinterlands", C = 2, instance = 0, areaID = 47 }
mapData[27] = { 4924.999756, 3283.333252, left = 14197.916748, top = 11343.68335, mapFile = "DunMorogh", name = "Dun Morogh", C = 2, instance = 0, areaID = 1 }
mapData[28] = { 2231.249847, 1487.499512, left = 16322.916656, top = 13566.600098, mapFile = "SearingGorge", name = "Searing Gorge", C = 2, instance = 0, areaID = 51 }
mapData[29] = { 2929.166595, 1952.083496, left = 16266.666656, top = 14497.849609, mapFile = "BurningSteppes", name = "Burning Steppes", C = 2, instance = 0, areaID = 46 }
mapData[30] = { 3470.833252, 2314.583008, left = 14464.583374, top = 15406.183105, mapFile = "Elwynn", name = "Elwynn Forest", C = 2, instance = 0, areaID = 12 }
mapData[32] = { 2499.999939, 1666.666992, left = 16833.333313, top = 17333.266113, mapFile = "DeadwindPass", name = "Deadwind Pass", C = 2, instance = 0, areaID = 41 }
mapData[34] = { 2699.999939, 1800.0, left = 15166.666687, top = 17183.266113, mapFile = "Duskwood", name = "Duskwood", C = 2, instance = 0, areaID = 10 }
mapData[35] = { 2758.33313, 1839.583008, left = 17993.749878, top = 11954.100098, mapFile = "LochModan", name = "Loch Modan", C = 2, instance = 0, areaID = 38 }
mapData[36] = { 2170.833252, 1447.916016, left = 17570.833252, top = 16041.600098, mapFile = "Redridge", name = "Redridge Mountains", C = 2, instance = 0, areaID = 44 }
mapData[37] = { 6381.249756, 4254.166016, left = 13779.166748, top = 18635.350098, mapFile = "Stranglethorn", name = "Stranglethorn Vale", C = 2, instance = 0, areaID = 33 }
mapData[38] = { 2293.75, 1529.166992, left = 18222.916504, top = 17087.433105, mapFile = "SwampOfSorrows", name = "Swamp of Sorrows", C = 2, instance = 0, areaID = 8 }
mapData[39] = { 3499.999817, 2333.333008, left = 12983.333496, top = 16866.600098, mapFile = "Westfall", name = "Westfall", C = 2, instance = 0, areaID = 40 }
mapData[40] = { 4135.416687, 2756.25, left = 16389.583313, top = 9614.516602, mapFile = "Wetlands", name = "Wetlands", C = 2, instance = 0, areaID = 11 }
mapData[41] = { 5091.666504, 3393.75, left = 13252.016357, top = 968.650391, mapFile = "Teldrassil", name = "Teldrassil", C = 1, instance = 1, areaID = 141 }
mapData[42] = { 6549.999756, 4366.666504, left = 14124.933105, top = 4466.567383, mapFile = "Darkshore", name = "Darkshore", C = 1, instance = 1, areaID = 148 }
mapData[43] = { 5766.666382, 3843.749878, left = 15366.599731, top = 8126.983887, mapFile = "Ashenvale", name = "Ashenvale", C = 1, instance = 1, areaID = 331 }
mapData[61] = { 4399.999695, 2933.333008, left = 17499.932922, top = 16766.566895, mapFile = "ThousandNeedles", name = "Thousand Needles", C = 1, instance = 1, areaID = 400 }
mapData[81] = { 4883.33313, 3256.249817, left = 13820.766357, top = 9883.233887, mapFile = "StonetalonMountains", name = "Stonetalon Mountains", C = 1, instance = 1, areaID = 406 }
mapData[101] = { 4495.833008, 2997.916565, left = 12833.266602, top = 12347.817078, mapFile = "Desolace", name = "Desolace", C = 1, instance = 1, areaID = 405 }
mapData[121] = { 6949.999756, 4633.333008, left = 11624.933105, top = 15166.566895, mapFile = "Feralas", name = "Feralas", C = 1, instance = 1, areaID = 357 }
mapData[141] = { 5250.000061, 3499.999756, left = 18041.599548, top = 14833.233643, mapFile = "Dustwallow", name = "Dustwallow Marsh", C = 1, instance = 1, areaID = 15 }
mapData[161] = { 6899.999527, 4600.0, left = 17285.349594, top = 18674.900391, mapFile = "Tanaris", name = "Tanaris", C = 1, instance = 1, areaID = 440 }
mapData[181] = { 5070.832764, 3381.249878, left = 20343.682861, top = 7458.233887, mapFile = "Aszhara", name = "Azshara", C = 1, instance = 1, areaID = 16 }
mapData[182] = { 5749.999634, 3833.333252, left = 15424.932983, top = 5666.567383, mapFile = "Felwood", name = "Felwood", C = 1, instance = 1, areaID = 361 }
mapData[201] = { 3699.999817, 2466.666504, left = 16533.266296, top = 18766.566895, mapFile = "UngoroCrater", name = "Un'Goro Crater", C = 1, instance = 1, areaID = 490 }
mapData[241] = { 2308.333252, 1539.583008, left = 18447.849609, top = 4308.234375, mapFile = "Moonglade", name = "Moonglade", C = 1, instance = 1, areaID = 493 }
mapData[261] = { 3483.333984, 2322.916016, left = 14529.099609, top = 18758.234375, mapFile = "Silithus", name = "Silithus", C = 1, instance = 1, areaID = 1377 }
mapData[281] = { 7099.999847, 4733.333252, left = 17383.266266, top = 4266.567383, mapFile = "Winterspring", name = "Winterspring", C = 1, instance = 1, areaID = 618 }
mapData[301] = { 1344.270805, 896.354492, left = 14619.028564, top = 15745.450684, mapFile = "Stormwind", name = "Stormwind City", C = 2, instance = 0, areaID = 1519 }
mapData[321] = { 1402.604492, 935.416626, left = 20747.200684, top = 10526.023193, mapFile = "Ogrimmar", name = "Orgrimmar", C = 1, instance = 1, areaID = 1637 }
mapData[341] = { 790.625061, 527.604492, left = 16713.59137, top = 12035.841309, mapFile = "Ironforge", name = "Ironforge", C = 2, instance = 0, areaID = 1537 }
mapData[362] = { 1043.749939, 695.833313, left = 16549.932983, top = 13649.90033, mapFile = "ThunderBluff", name = "Thunder Bluff", C = 1, instance = 1, areaID = 1638 }
mapData[381] = { 1058.333252, 705.729492, left = 14128.236816, top = 2561.583984, mapFile = "Darnassis", name = "Darnassus", C = 1, instance = 1, areaID = 1657 }
mapData[382] = { 959.375031, 640.104126, left = 15126.807373, top = 5588.654785, mapFile = "Undercity", name = "Undercity", C = 2, instance = 0, areaID = 1497 }
mapData[401] = { 4237.499878, 2824.999878, left = 0.0, top = 0.0, mapFile = "AlteracValley", name = "Alterac Valley", instance = 30, areaID = 2597 }
mapData[443] = { 1145.833313, 764.583313, left = 0.0, top = 0.0, mapFile = "WarsongGulch", name = "Warsong Gulch", instance = 489, areaID = 3277 }
mapData[461] = { 1756.249924, 1170.833252, left = 0.0, top = 0.0, mapFile = "ArathiBasin", name = "Arathi Basin", instance = 529, areaID = 3358 }

wipe(cosmicData)
-- The base entry IS floor 0 (Eastern Kingdoms), so a floor-less call still
-- resolves.  Named World, not Azeroth: mapData[14].mapFile is already Azeroth
-- (the Eastern Kingdoms continent map), so the name would be ambiguous.
cosmicData[0] = { 44531.829079, 29687.905754, left = -16625.0, top = -2470.0, mapFile = "World", name = "World", C = 0, instance = -1, floors = {
	[0] = { 44531.829079, 29687.905754, left = -16625.0, top = -2470.0, instance = 0 },
	[1] = { 44531.829079, 29687.905754, left = 8310.0, top = -1815.0, instance = 1 },
} }

wipe(mapToID)
wipe(nameToID)
for id, d in pairs(mapData) do
	mapToID[d.mapFile] = id
	nameToID[d.name] = id
end

-- Normalised names, so GetMapIDFromZoneName tolerates spacing and punctuation.
nameToID["durotar"] = 4
nameToID["mulgore"] = 9
nameToID["thebarrens"] = 11
nameToID["kalimdor"] = 13
nameToID["easternkingdoms"] = 14
nameToID["alteracmountains"] = 15
nameToID["arathihighlands"] = 16
nameToID["badlands"] = 17
nameToID["blastedlands"] = 19
nameToID["tirisfalglades"] = 20
nameToID["silverpineforest"] = 21
nameToID["westernplaguelands"] = 22
nameToID["easternplaguelands"] = 23
nameToID["hillsbradfoothills"] = 24
nameToID["thehinterlands"] = 26
nameToID["dunmorogh"] = 27
nameToID["searinggorge"] = 28
nameToID["burningsteppes"] = 29
nameToID["elwynnforest"] = 30
nameToID["deadwindpass"] = 32
nameToID["duskwood"] = 34
nameToID["lochmodan"] = 35
nameToID["redridgemountains"] = 36
nameToID["stranglethornvale"] = 37
nameToID["swampofsorrows"] = 38
nameToID["westfall"] = 39
nameToID["wetlands"] = 40
nameToID["teldrassil"] = 41
nameToID["darkshore"] = 42
nameToID["ashenvale"] = 43
nameToID["thousandneedles"] = 61
nameToID["stonetalonmountains"] = 81
nameToID["desolace"] = 101
nameToID["feralas"] = 121
nameToID["dustwallowmarsh"] = 141
nameToID["tanaris"] = 161
nameToID["azshara"] = 181
nameToID["felwood"] = 182
nameToID["ungorocrater"] = 201
nameToID["moonglade"] = 241
nameToID["silithus"] = 261
nameToID["winterspring"] = 281
nameToID["stormwindcity"] = 301
nameToID["orgrimmar"] = 321
nameToID["ironforge"] = 341
nameToID["thunderbluff"] = 362
nameToID["darnassus"] = 381
nameToID["undercity"] = 382
nameToID["alteracvalley"] = 401
nameToID["warsonggulch"] = 443
nameToID["arathibasin"] = 461
--@end-zonedata@

--------------------------------------------------------------------------------------------
-- Lookups
--------------------------------------------------------------------------------------------

-- Resolve a mapID, or a mapFile string, plus an optional floor, to its data table.
-- On vanilla only the cosmic map has floors, where the floor index IS the instance id.
local function getMapDataTable(zone, level)
	if not zone then return nil end
	if type(zone) == "string" then
		zone = mapToID[zone]
	end
	local data = mapData[zone] or cosmicData[zone]
	if not data then return nil end
	if data.floors and type(level) == "number" then
		-- A floor was asked for on a map that HAS floors: give that floor, or nothing.
		-- Falling back to the base entry here would silently resolve a nonexistent floor
		-- against a different one -- e.g. a battleground pin (instance 529) asking the
		-- cosmic map for floor 529 would land at Eastern Kingdoms coordinates and be drawn
		-- at a garbage position instead of being skipped.  Upstream returns nil too.
		return data.floors[level]
	end
	return data
end

-- LibBabble-Zone-2.2 is an OPTIONAL dependency, used only to bridge localized zone names.
-- Without it, coordinates, distances and every mapFile-based lookup work exactly the same;
-- only name-based lookup on a non-enUS client is reduced to zones the player has visited.
-- Resolved lazily, because load order is the consumer's business, not ours.
local babble

local function getBabble()
	-- Cache only a SUCCESSFUL lookup.  Caching "absent" would make the answer depend on
	-- whether anything happened to ask before LibBabble-Zone loaded, and load order is the
	-- consumer's business -- a silent, order-dependent loss of every localized name.
	if not babble then
		babble = LibStub("LibBabble-Zone-2.2", true)
	end
	return babble
end

--- Return the zone's name, localized when that is knowable.
-- @param zone mapID or mapFile
function HBD:GetLocalizedMap(zone)
	local data = getMapDataTable(zone)
	if not data then return nil end
	-- A name observed from the client itself always wins: it is what this client really says.
	if data.localized then return data.localized end
	local B = getBabble()
	if B and B:HasTranslation(data.name) then
		return B:GetTranslation(data.name)
	end
	return data.name
end

--- Return the mapID for a mapFile.
function HBD:GetMapIDFromFile(mapFile)
	if not mapFile then return nil end
	return mapToID[mapFile]
end

--- Return the mapFile for a mapID.
function HBD:GetMapFileFromID(mapID)
	local data = getMapDataTable(mapID)
	return data and data.mapFile or nil
end

--- Look up the mapID for a continent/zone index pair.
-- Zone indices are client state, learned by observation -- see LearnZoneIndices().
-- @param C continent index from GetCurrentMapContinent
-- @param Z zone index from GetCurrentMapZone
function HBD:GetMapIDFromCZ(C, Z)
	if C and continentZoneMap[C] then
		return Z and continentZoneMap[C][Z] or nil
	end
	return nil
end

--- Look up the continent/zone index pair for a mapID.
-- Z is nil until that zone's index has been observed.
function HBD:GetCZFromMapID(mapID)
	local data = getMapDataTable(mapID)
	if not data then return nil, nil end
	return data.C, data.Z
end

--- Return the mapID for a zone name, localized or English.
-- Extension over upstream: replaces walking Astrolabe.ContinentList.
function HBD:GetMapIDFromZoneName(name)
	if type(name) ~= "string" then return nil end
	local id = nameToID[name] or nameToID[strgsub(strlower(name), "[^%a]", "")]
	if id then return id end

	-- A localized name: translate it back to English and try again.
	local B = getBabble()
	if B and B:HasReverseTranslation(name) then
		local english = B:GetReverseTranslation(name)
		return nameToID[english] or nameToID[strgsub(strlower(english), "[^%a]", "")] or nil
	end
	return nil
end

--- Return the size of a zone in yards.
-- @return width, height (0, 0 when unknown)
function HBD:GetZoneSize(zone, level)
	local data = getMapDataTable(zone, level)
	if not data then return 0, 0 end
	return data[1], data[2]
end

--- Vanilla has no multi-level maps, so this is always 0.
function HBD:GetNumFloors(zone)
	return 0
end

--- Return an array of every known mapID.
function HBD:GetAllMapIDs()
	local t = {}
	for id in pairs(mapData) do
		tinsert(t, id)
	end
	return t
end

--------------------------------------------------------------------------------------------
-- Coordinates
--
-- Astrolabe's axes, HereBeDragons' field names: left/top are the zone's MINIMUM x/y in
-- continent yards, and both axes run WITH increasing 0-1 map coordinates (y downward).
-- Upstream HBD uses "left - width * x" instead, i.e. retail's axes.  See docs/zone-data.md.
--------------------------------------------------------------------------------------------

--- Convert 0-1 zone coordinates to world coordinates in yards.
-- @return x, y, instanceID
function HBD:GetWorldCoordinatesFromZone(x, y, zone, level)
	local data = getMapDataTable(zone, level)
	-- Upstream tests data[0], which is always nil, so it never catches a zero height.
	if not data or data[1] == 0 or data[2] == 0 then return nil, nil, nil end
	if not x or not y then return nil, nil, nil end

	return data.left + data[1] * x, data.top + data[2] * y, data.instance
end

--- Convert world coordinates in yards to 0-1 zone coordinates.
-- @param allowOutOfBounds return coordinates outside 0-1 instead of nil
function HBD:GetZoneCoordinatesFromWorld(x, y, zone, level, allowOutOfBounds)
	local data = getMapDataTable(zone, level)
	if not data or data[1] == 0 or data[2] == 0 then return nil, nil end
	if not x or not y then return nil, nil end

	x, y = (x - data.left) / data[1], (y - data.top) / data[2]

	if not allowOutOfBounds and (x < 0 or x > 1 or y < 0 or y > 1) then return nil, nil end

	return x, y
end

--- Translate 0-1 coordinates from one zone to another.
function HBD:TranslateZoneCoordinates(x, y, oZone, oLevel, dZone, dLevel, allowOutOfBounds)
	local xCoord, yCoord, instance = self:GetWorldCoordinatesFromZone(x, y, oZone, oLevel)
	if not xCoord then return nil, nil end

	local data = getMapDataTable(dZone, dLevel)
	if not data or data.instance ~= instance then return nil, nil end

	return self:GetZoneCoordinatesFromWorld(xCoord, yCoord, dZone, dLevel, allowOutOfBounds)
end

--- Distance in yards between two world positions in the same instance.
-- @return distance, deltaX, deltaY
function HBD:GetWorldDistance(instanceID, oX, oY, dX, dY)
	if not oX or not oY or not dX or not dY then return nil, nil, nil end
	local deltaX, deltaY = dX - oX, dY - oY
	return msqrt(deltaX * deltaX + deltaY * deltaY), deltaX, deltaY
end

--- Distance in yards between two 0-1 positions, possibly on different maps.
-- nil across instances (different continents, or a battleground).
function HBD:GetZoneDistance(oZone, oLevel, oX, oY, dZone, dLevel, dX, dY)
	local oWX, oWY, oInstance = self:GetWorldCoordinatesFromZone(oX, oY, oZone, oLevel)
	if not oWX then return nil, nil, nil end

	local dWX, dWY, dInstance = self:GetWorldCoordinatesFromZone(dX, dY, dZone, dLevel)
	if not dWX then return nil, nil, nil end

	if oInstance ~= dInstance then return nil, nil, nil end

	return self:GetWorldDistance(oInstance, oWX, oWY, dWX, dWY)
end

--- Angle and distance from one world position to another.
-- @return angle in RADIANS, 0 = north, growing clockwise; distance in yards
function HBD:GetWorldVector(instanceID, oX, oY, dX, dY)
	local distance, deltaX, deltaY = self:GetWorldDistance(instanceID, oX, oY, dX, dY)
	if not distance then return nil, nil end

	-- y grows downward here, so north is -deltaY.
	local angle = matan2(deltaX, -deltaY)
	if ATAN2_DEG then
		angle = angle * PI2 / 360
	end
	if angle < 0 then
		angle = angle + PI2
	end

	return angle, distance
end

--- Angle and distance between two 0-1 positions.  Extension over upstream, symmetric with
--- GetZoneDistance -- it collapses a "get distance then get direction" pair into one call.
-- @return angle in radians, distance in yards
function HBD:GetZoneVector(oZone, oLevel, oX, oY, dZone, dLevel, dX, dY)
	local oWX, oWY, oInstance = self:GetWorldCoordinatesFromZone(oX, oY, oZone, oLevel)
	if not oWX then return nil, nil end

	local dWX, dWY, dInstance = self:GetWorldCoordinatesFromZone(dX, dY, dZone, dLevel)
	if not dWX or oInstance ~= dInstance then return nil, nil end

	return self:GetWorldVector(oInstance, oWX, oWY, dWX, dWY)
end

--------------------------------------------------------------------------------------------
-- Player position
--
-- There is no UnitPosition on this client: the only measurable quantity is
-- GetPlayerMapPosition, which is 0-1 on the CURRENTLY VIEWED map.  So the model is
-- UV-first and world yards are always derived.
--------------------------------------------------------------------------------------------

local currentMapID, currentMapFile, currentX, currentY
local inObserve

-- Record what the currently viewed map is, learning its zone index at the same time.
-- The three reads describe ONE map, so a GetMapZones that ignores its argument cannot
-- produce a wrong (C, Z) -> mapID pairing here, only a missing one.
-- `isPlayerZone` says whether the map on screen is the one the player is standing in.  Only the
-- caller that has just forced the map there can promise that.
local function observeCurrentMap(isPlayerZone)
	local mapFile = GetMapInfo()
	local C, Z = GetCurrentMapContinent(), GetCurrentMapZone()
	local id = mapFile and mapToID[mapFile] or nil

	-- Safe from either caller: mapFile, C and Z all describe the same map, the displayed one.
	if id and C and C > 0 and Z and Z > 0 then
		if not continentZoneMap[C] then continentZoneMap[C] = {} end
		continentZoneMap[C][Z] = id
		mapData[id].Z = Z
	end

	-- Learn this client's own name for the zone -- free, exact, and locale-independent.  But
	-- GetRealZoneText names the zone the PLAYER is in, while `id` is the map being DISPLAYED, so
	-- this is only valid when they are the same map.  Browsing the world map with this
	-- unguarded wrote the player's zone name onto whatever map was on screen: standing in the
	-- Barrens and opening Durotar's map made "Durotar" answer as "The Barrens", and poisoned
	-- nameToID in both directions with it.
	if isPlayerZone and id and GetRealZoneText then
		local real = GetRealZoneText()
		if real and real ~= "" and not mapData[id].localized then
			mapData[id].localized = real
			nameToID[real] = id
			nameToID[strgsub(strlower(real), "[^%a]", "")] = id
		end
	end

	return id, C, Z
end

local function updateCurrentPosition(force)
	if inObserve then return end

	-- Never move a map the user is looking at; serve the cached position instead.
	local mapOpen = WorldMapFrame and WorldMapFrame:IsVisible()

	if not mapOpen then
		inObserve = true
		SetMapToCurrentZone()
		local id = observeCurrentMap(true)   -- SetMapToCurrentZone above makes this the player's zone
		local x, y = GetPlayerMapPosition("player")
		inObserve = nil

		if id and x and y and not (x == 0 and y == 0) then
			currentX, currentY = x, y
			if id ~= currentMapID or force then
				currentMapID, currentMapFile = id, mapData[id].mapFile
				HBD.callbacks:Fire("PlayerZoneChanged", 3, currentMapID, nil, currentMapFile)
			end
		else
			-- An instance, or a map with no data: keep the zone, drop the position.
			currentX, currentY = nil, nil
		end
	end
end

--- Force a re-read of the player's zone and position.
function HBD:RefreshPlayerPosition()
	updateCurrentPosition(true)
end

--- The player's current zone.
-- @return mapID, level (always nil), mapFile
function HBD:GetPlayerZone()
	return currentMapID, nil, currentMapFile
end

--- The player's 0-1 position on their current zone map.
-- @return x, y, mapID, level (always nil), mapFile
function HBD:GetPlayerZonePosition()
	if not currentMapID or not currentX then return nil, nil, nil, nil, nil end
	return currentX, currentY, currentMapID, nil, currentMapFile
end

--- The player's world position in yards.  Derived from the 0-1 position, so only as
--- accurate as the zone table -- upstream reads UnitPosition, which does not exist here.
-- @return x, y, instanceID
function HBD:GetPlayerWorldPosition()
	if not currentMapID or not currentX then return nil, nil, nil end
	return self:GetWorldCoordinatesFromZone(currentX, currentY, currentMapID)
end

--- A unit's world position, if it projects onto the currently viewed map.
-- @return x, y, instanceID
function HBD:GetUnitWorldPosition(unitId)
	if not currentMapID then return nil, nil, nil end
	local x, y = GetPlayerMapPosition(unitId)
	if not x or (x == 0 and y == 0) then return nil, nil, nil end
	return self:GetWorldCoordinatesFromZone(x, y, currentMapID)
end

--- Astrolabe-shaped shim, so consumers porting off Astrolabe need the smallest diff.
-- @return C, Z, x, y
function HBD:GetCurrentPlayerPosition()
	if not currentMapID or not currentX then return nil, nil, nil, nil end
	local data = mapData[currentMapID]
	return data.C, data.Z, currentX, currentY
end

--- The mapID currently DISPLAYED on the world map (not the player's zone).
-- @return mapID, mapFile
function HBD:GetCurrentMapID()
	local mapFile = GetMapInfo()
	if mapFile and mapToID[mapFile] then
		return mapToID[mapFile], mapFile
	end
	if GetCurrentMapContinent() == 0 then
		return COSMIC_ID, cosmicData[COSMIC_ID].mapFile
	end
	return nil, nil
end

--- The player's facing in radians, or nil if this client cannot report it.
--
-- Three sources, in order:
--   1. the global GetPlayerFacing -- present on Unreal Azeroth (undocumented), absent on
--      stock 1.12.1;
--   2. MiniMapCompassRing, but only while the minimap is rotating: in that mode the arrow
--      model stays put and the ring turns instead, with the opposite sign;
--   3. the minimap's player-arrow Model.
--
-- (3) is detected the way pfQuest does it (compat/client.lua:63-72): an UNNAMED Model child of
-- Minimap whose model path is interface\minimap\minimaparrow.  NOT by child index -- a
-- hardcoded index is what TomTom used, and on this client the ninth child is not the arrow, so
-- it died on a nil GetFacing every frame.  The index also shifts as soon as any addon parents
-- a child to Minimap, so it can never be relied on.
local facingModel

local function minimapArrowModel()
	if facingModel and facingModel.GetFacing then return facingModel end
	if not Minimap or not Minimap.GetChildren then return nil end

	local kids = { Minimap:GetChildren() }
	for i = 1, tgetn(kids) do
		local k = kids[i]
		if k and k.IsObjectType and k.GetModel and k.GetFacing
		   and k:IsObjectType("Model") and (not k.GetName or not k:GetName()) then
			local ok, model = pcall(k.GetModel, k)
			if ok and type(model) == "string"
			   and strfind(strlower(model), "interface\\minimap\\minimaparrow", 1, true) then
				facingModel = k
				return k
			end
		end
	end
	return nil
end

-- Is the minimap rotating?  Same capability gate as the pins library: GetCVar answers "0" for
-- an unregistered name, so GetCVarDefault is what actually says whether it exists.
local function rotatingMinimap()
	if type(GetCVar) ~= "function" then return false end
	if type(GetCVarDefault) == "function" and GetCVarDefault("rotateMinimap") == nil then
		return false
	end
	return GetCVar("rotateMinimap") == "1"
end

function HBD:GetPlayerFacing()
	if type(GetPlayerFacing) == "function" then
		local ok, facing = pcall(GetPlayerFacing)
		if ok and facing then return facing end
	end

	if rotatingMinimap() and MiniMapCompassRing and MiniMapCompassRing.GetFacing then
		local ok, facing = pcall(MiniMapCompassRing.GetFacing, MiniMapCompassRing)
		if ok and facing then return -facing end
	end

	local arrow = minimapArrowModel()
	if arrow then
		local ok, facing = pcall(arrow.GetFacing, arrow)
		if ok then return facing end
		facingModel = nil                     -- it stopped answering; look again next time
	end

	return nil
end

--------------------------------------------------------------------------------------------
-- Zone index learning
--------------------------------------------------------------------------------------------

--- Fill in the (C, Z) -> mapID map for one continent, or the current one.
--
-- One SetMapZoom(C) per continent, never SetMapZoom(C, Z) per zone: that is the sweep that
-- breaks on Unreal Azeroth.  GetMapZones is then called with the continent that is actually
-- selected, which is the only contract it honours there.  Never called automatically.
-- @return the number of indices learned
function HBD:LearnZoneIndices(C)
	if inObserve then return 0 end
	if WorldMapFrame and WorldMapFrame:IsVisible() then return 0 end

	local prevC, prevZ = GetCurrentMapContinent(), GetCurrentMapZone()
	C = C or prevC
	if not C or C < 1 then return 0 end

	inObserve = true
	SetMapZoom(C)
	local names = { GetMapZones(C) }
	inObserve = nil

	local learned = 0
	if not continentZoneMap[C] then continentZoneMap[C] = {} end
	for Z = 1, tgetn(names) do
		local id = self:GetMapIDFromZoneName(names[Z])
		if id and mapData[id] and mapData[id].C == C then
			continentZoneMap[C][Z] = id
			mapData[id].Z = Z
			learned = learned + 1
		end
	end

	-- Restore the user's view.
	inObserve = true
	if prevZ and prevZ > 0 then
		SetMapZoom(prevC, prevZ)
	elseif prevC then
		SetMapZoom(prevC)
	else
		SetMapToCurrentZone()
	end
	inObserve = nil

	return learned
end

--------------------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------------------

local frame = HBD.eventFrame
-- UnregisterAllEvents (and UnregisterEvent) are silent no-ops on Unreal Azeroth, so this
-- cannot be relied on to clear anything.  It is kept only because re-registering an event
-- that is already registered is idempotent, so a LibStub upgrade reusing this same frame is
-- harmless either way.  Nothing here relies on delivery actually stopping.
frame:UnregisterAllEvents()
frame:SetScript("OnEvent", function()
	-- Vanilla passes event arguments as globals, not parameters.
	if event == "WORLD_MAP_UPDATE" then
		-- No flag: the user may be browsing any map, so no name may be learned from here.
		if not inObserve then observeCurrentMap(false) end
	else
		updateCurrentPosition()
	end
end)
frame:RegisterEvent("ZONE_CHANGED")
frame:RegisterEvent("ZONE_CHANGED_INDOORS")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("NEW_WMO_CHUNK")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("WORLD_MAP_UPDATE")

-- Cheap per-frame refresh of the 0-1 position.  Touches no map state: between our own
-- SetMapToCurrentZone calls the map is still on the player's zone, so this is a valid read.
-- No C_Timer on this client, and the OnUpdate elapsed argument is unreliable on
-- Lua-created frames, so drive the safety poll from GetTime().
local lastPoll = 0
frame:SetScript("OnUpdate", function()
	if inObserve or not currentMapID then return end
	if WorldMapFrame and WorldMapFrame:IsVisible() then return end

	local x, y = GetPlayerMapPosition("player")
	if x and y and not (x == 0 and y == 0) then
		currentX, currentY = x, y
	end

	local now = GetTime()
	if now - lastPoll >= 1 then
		lastPoll = now
		updateCurrentPosition()
	end
end)

--- Report the library version.
function HBD:GetLibraryVersion()
	return MAJOR, MINOR
end

-- Register under the upstream name too, so an addon written against HereBeDragons-1.0
-- finds it unmodified.  See docs/output-conventions.md.
local alias = LibStub:NewLibrary("HereBeDragons-1.0", MINOR)
if alias then
	LibStub.libs["HereBeDragons-1.0"] = HBD
end

updateCurrentPosition(true)
