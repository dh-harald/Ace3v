-- LibRover-1.0 base data for WoW 1.12.1.
--
-- Ported from ZygorGuidesViewerClassic's Libs-Classic/LibRover-1.0/data.lua.  Plain data in a
-- global: the client may run a data file before the library's main file, which adopts this
-- table and clears the global.
--
-- Zones are named in English and resolved to LibHereBeDragons-1.0 map ids at startup, so the
-- original's MapIDsByName table of Classic uiMapIDs (1411-1464) is gone -- and with it the
-- faked dungeon map ids, since a vanilla instance has no map coordinates at all.  RemapData is
-- gone too: it is keyed on UnitPosition rectangles, and 1.12 has no UnitPosition.

LibRover_Data = LibRover_Data or {}
local data = LibRover_Data
data.basenodes = data.basenodes or {}

data.version = {
	nodes_version = 5,  -- the Classic data's own version; no baked cache is shipped
}

-- These zone pairs see directly into each other, as they share "green" borders.
data.greenborders = {

	{"Western Plaguelands","Eastern Plaguelands"},
	{"Feralas","Thousand Needles"},
	{"The Barrens","Durotar"},
	{"Mulgore","Thunder Bluff"},
	{"Elwynn Forest","Duskwood"},
	{"Westfall","Duskwood"},
	{"Westfall","Elwynn Forest"},
	{"Hillsbrad Foothills","Alterac Mountains"},
}

-- Per-zone overrides: `hostile` multiplies the cost of walking through, `flyable` is kept for
-- call compatibility and is meaningless here (1.12 has no flying mounts).  The library installs
-- a default-answering metatable, so any zone may be asked.
data.ZoneMeta = {
}

data.walls = {
}

-- Containers the startup thread walks.  Kept, empty, because the Classic data has nothing in
-- them: every dungeon entrance in data_dungeons.lua is commented out, and vanilla has no
-- multi-floor maps, so indoor zones and floor crossings never applied.
data.basenodes.setup = {
}

data.basenodes.indoorzones = {
}

data.basenodes.FloorCrossings = {
}

data.basenodes.DungeonEntrances = {
}

data.basenodes.DungeonFloors = {
}

-- Read by consumers to tell which maps cannot be positioned on.  Empty here: the port has no
-- faked dungeon maps.
data.DungeonMaps = {
}
