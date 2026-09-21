-- LibTaxi-1.0 / deDE
--
-- Flight point names from ZygorGuidesViewerClassic's Libs/LibTaxi-1.0/deDE.lua,
-- which were read off a localized client, cross-checked against VMaNGOS' locales_taxi_node.
-- Reduced to the vanilla flight points; everything TBC and later is dropped.  `true` means
-- the name is the same as the English one in this locale.
--
-- The file only stores its tables; LibTaxi-1.0.lua picks the client's locale out of
-- LibTaxi_Locales and then clears the global. It carries no dependency of its own -- not even
-- GetLocale -- because the 1.12.1 loader may run a locale file ahead of every other script of
-- the including XML (LibItemBonusLib-1.0 README deviation 15).

LibTaxi_Locales = LibTaxi_Locales or {}
LibTaxi_Locales.deDE = {
	TAXINAMES = {
		-- flight points
		["Aerie Peak"] = "Nistgipfel",
		["Astranaar"] = true,
		["Auberdine"] = true,
		["Bloodvenom Post"] = "Blutgiftposten",
		["Booty Bay"] = "Beutebucht",
		["Brackenwall Village"] = "Brackenwall",
		["Camp Mojache"] = true,
		["Camp Taurajo"] = true,
		["Cenarion Hold"] = "Burg Cenarius",
		["Chillwind Camp"] = "Zugwindlager",
		["Crossroads"] = "Das Wegekreuz",
		["Darkshire"] = "Dunkelhain",
		["Everlook"] = "Ewige Warte",
		["Feathermoon"] = "Mondfederfeste",
		["Flame Crest"] = "Flammenkamm",
		["Freewind Post"] = "Freiwindposten",
		["Gadgetzan"] = true,
		["Grom'gol"] = true,
		["Hammerfall"] = true,
		["Ironforge"] = "Eisenschmiede",
		["Kargath"] = true,
		["Lakeshire"] = "Seenhain",
		["Light's Hope Chapel"] = "Kapelle des hoffnungsvollen Lichts",
		["Marshal's Refuge"] = "Marschalls Zuflucht",
		["Menethil Harbor"] = "Hafen von Menethil",
		["Moonglade"] = "Mondlichtung",
		["Morgan's Vigil"] = "Morgans Wacht",
		["Nethergarde Keep"] = "Burg Nethergarde",
		["Nijel's Point"] = "Die Nijelspitze",
		["Orgrimmar"] = true,
		["Ratchet"] = "Ratschet",
		["Refuge Pointe"] = "Die Zuflucht",
		["Revantusk Village"] = "Dorf der Bruchhauer",
		["Rut'theran Village"] = "Rut'theran",
		["Sentinel Hill"] = "Späherkuppe",
		["Shadowprey Village"] = "Schattenflucht",
		["Southshore"] = "Süderstade",
		["Splintertree Post"] = "Splitterholzposten",
		["Stonard"] = "Steinard",
		["Stonetalon Peak"] = "Steinkrallengipfel",
		["Stormwind"] = "Sturmwind",
		["Sun Rock Retreat"] = "Sonnenfels",
		["Talonbranch Glade"] = "Nachtlaublichtung",
		["Talrendis Point"] = "Talrendisspitze",
		["Tarren Mill"] = "Tarrens Mühle",
		["Thalanaar"] = true,
		["The Sepulcher"] = "Das Grabmal",
		["Thelsamar"] = true,
		["Theramore"] = true,
		["Thorium Point"] = "Thoriumspitze",
		["Thunder Bluff"] = "Donnerfels",
		["Undercity"] = "Unterstadt",
		["Valormok"] = true,
		["Zoram'gar Outpost"] = "Außenposten von Zoram'gar",
		-- minimap subzones
		["Trade District"] = "Handelsdistrikt",
		["The Great Forge"] = "Die große Schmiede",
		["Valley of Strength"] = "Tal der Stärke",
	},
}
