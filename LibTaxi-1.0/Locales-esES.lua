-- LibTaxi-1.0 / esES
--
-- Flight point names from ZygorGuidesViewerClassic's Libs/LibTaxi-1.0/esES.lua,
-- which were read off a localized client, cross-checked against VMaNGOS' locales_taxi_node.
-- Reduced to the vanilla flight points; everything TBC and later is dropped.  `true` means
-- the name is the same as the English one in this locale.
--
-- The file only stores its tables; LibTaxi-1.0.lua picks the client's locale out of
-- LibTaxi_Locales and then clears the global. It carries no dependency of its own -- not even
-- GetLocale -- because the 1.12.1 loader may run a locale file ahead of every other script of
-- the including XML (LibItemBonusLib-1.0 README deviation 15).

LibTaxi_Locales = LibTaxi_Locales or {}
LibTaxi_Locales.esES = {
	TAXINAMES = {
		-- flight points
		["Aerie Peak"] = "Pico Nidal",
		["Astranaar"] = true,
		["Auberdine"] = true,
		["Bloodvenom Post"] = "Puesto del Veneno",
		["Booty Bay"] = "Bahía del Botín",
		["Brackenwall Village"] = "Poblado Murohelecho",
		["Camp Mojache"] = "Campamento Mojache",
		["Camp Taurajo"] = "Campamento Taurajo",
		["Cenarion Hold"] = "Fuerte Cenarion",
		["Chillwind Camp"] = "Campamento del Orvallo",
		["Crossroads"] = "El Cruce",
		["Darkshire"] = "Villa Oscura",
		["Everlook"] = "Vista Eterna",
		["Feathermoon"] = "Plumaluna",
		["Flame Crest"] = "Peñasco Llamarada",
		["Freewind Post"] = "Poblado Viento Libre",
		["Gadgetzan"] = true,
		["Grom'gol"] = true,
		["Hammerfall"] = "Sentencia",
		["Ironforge"] = "Forjaz",
		["Kargath"] = true,
		["Lakeshire"] = "Villa del Lago",
		["Light's Hope Chapel"] = "Capilla de la Esperanza de la Luz",
		["Marshal's Refuge"] = "Refugio de Marshal",
		["Menethil Harbor"] = "Puerto de Menethil",
		["Moonglade"] = "Claro de la Luna",
		["Morgan's Vigil"] = "Vigilia de Morgan",
		["Nethergarde Keep"] = "Castillo de Nethergarde",
		["Nijel's Point"] = "Punta de Nijel",
		["Orgrimmar"] = true,
		["Ratchet"] = "Trinquete",
		["Refuge Pointe"] = "Refugio de la Zaga",
		["Revantusk Village"] = "Poblado Sañadiente",
		["Rut'theran Village"] = "Aldea Rut'theran",
		["Sentinel Hill"] = "Colina del Centinela",
		["Shadowprey Village"] = "Aldea Cazasombras",
		["Southshore"] = "Costasur",
		["Splintertree Post"] = "Puesto del Hachazo",
		["Stonard"] = "Rocal",
		["Stonetalon Peak"] = "Cima del Espolón",
		["Stormwind"] = "Ventormenta",
		["Sun Rock Retreat"] = "Refugio Roca del Sol",
		["Talonbranch Glade"] = "Claro Ramaespolón",
		["Talrendis Point"] = "Punta Talrendis",
		["Tarren Mill"] = "Molino Tarren",
		["Thalanaar"] = true,
		["The Sepulcher"] = "El Sepulcro",
		["Thelsamar"] = true,
		["Theramore"] = true,
		["Thorium Point"] = "Puesto del Torio",
		["Thunder Bluff"] = "Cima del Trueno",
		["Undercity"] = "Entrañas",
		["Valormok"] = true,
		["Zoram'gar Outpost"] = "Avanzada de Zoram'gar",
		-- minimap subzones
		["Trade District"] = "Distrito de Mercaderes",
		["The Great Forge"] = "La Gran Fundición",
		["Valley of Strength"] = "Valle de la Fuerza",
	},
	-- flight masters, by creature id
	NPCNAMES = {
		[352] = "Dungar Tragolargo",  -- Stormwind
		[931] = "Ariena Tempespluma",  -- Lakeshire
		[2299] = "Borgus Brazofuerte",  -- Morgan's Vigil
		[2835] = "Cedrik Prosa",  -- Refuge Pointe
		[3841] = "Caylais Plumalunar",  -- Auberdine
		[6706] = "Baritanas Rioceleste",  -- Nijel's Point
		[7823] = "Bera Rocamartillo",  -- Gadgetzan
		[7824] = "Bulkrek Puñofuria",  -- Gadgetzan
		[8018] = "Guthrum Tronapuño",  -- Aerie Peak
		[8019] = "Fyldren Plumalunar",  -- Feathermoon
		[10378] = "Omusa Tronacuerno",  -- Camp Taurajo
		[12596] = "Bibilfaz Plumasilba",  -- Chillwind Camp
		[12617] = "Khaelyn Alacerada",  -- Light's Hope Chapel
		[15177] = "Danzocielo nuboso",  -- Cenarion Hold
		[15178] = "Runk Domavientos",  -- Cenarion Hold
	},
}
