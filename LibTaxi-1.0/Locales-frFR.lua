-- LibTaxi-1.0 / frFR
--
-- Flight point names from ZygorGuidesViewerClassic's Libs/LibTaxi-1.0/frFR.lua,
-- which were read off a localized client, cross-checked against VMaNGOS' locales_taxi_node.
-- Reduced to the vanilla flight points; everything TBC and later is dropped.  `true` means
-- the name is the same as the English one in this locale.
--
-- The file only stores its tables; LibTaxi-1.0.lua picks the client's locale out of
-- LibTaxi_Locales and then clears the global. It carries no dependency of its own -- not even
-- GetLocale -- because the 1.12.1 loader may run a locale file ahead of every other script of
-- the including XML (LibItemBonusLib-1.0 README deviation 15).

LibTaxi_Locales = LibTaxi_Locales or {}
LibTaxi_Locales.frFR = {
	TAXINAMES = {
		-- flight points
		["Aerie Peak"] = "Nid-de-l'Aigle",
		["Astranaar"] = true,
		["Auberdine"] = true,
		["Bloodvenom Post"] = "Poste de la Vénéneuse",
		["Booty Bay"] = "Baie-du-Butin",
		["Brackenwall Village"] = "Mur-de-Fougères",
		["Camp Mojache"] = true,
		["Camp Taurajo"] = true,
		["Cenarion Hold"] = "Fort cénarien",
		["Chillwind Camp"] = "Camp du Noroît",
		["Crossroads"] = "La Croisée",
		["Darkshire"] = "Sombre-comté",
		["Everlook"] = "Long-guet",
		["Feathermoon"] = "Pennelune",
		["Flame Crest"] = "Corniche des flammes",
		["Freewind Post"] = "Poste de Librevent",
		["Gadgetzan"] = true,
		["Grom'gol"] = true,
		["Hammerfall"] = "Trépas-d'Orgrim",
		["Ironforge"] = "Forgefer",
		["Kargath"] = true,
		["Lakeshire"] = "Comté-du-lac",
		["Light's Hope Chapel"] = "Chapelle de l'Espoir de Lumière",
		["Marshal's Refuge"] = "Refuge des Marshal",
		["Menethil Harbor"] = "Port de Menethil",
		["Moonglade"] = "Reflet-de-Lune",
		["Morgan's Vigil"] = "Veille de Morgan",
		["Nethergarde Keep"] = "Rempart-du-Néant",
		["Nijel's Point"] = "Combe de Nijel",
		["Orgrimmar"] = true,
		["Ratchet"] = "Cabestan",
		["Refuge Pointe"] = "Refuge de l'Ornière",
		["Revantusk Village"] = "Village des Vengebroches",
		["Rut'theran Village"] = "Rut'theran",
		["Sentinel Hill"] = "Colline des sentinelles",
		["Shadowprey Village"] = "Proie-de-l'Ombre",
		["Southshore"] = "Austrivage",
		["Splintertree Post"] = "Poste de Bois-brisé",
		["Stonard"] = "Pierrêche",
		["Stonetalon Peak"] = "Pic des Serres-Rocheuses",
		["Stormwind"] = "Hurlevent",
		["Sun Rock Retreat"] = "Retraite de Roche-Soleil",
		["Talonbranch Glade"] = "Clairière de Griffebranche",
		["Talrendis Point"] = "Halte de Talrendis",
		["Tarren Mill"] = "Moulin-de-Tarren",
		["Thalanaar"] = true,
		["The Sepulcher"] = "Le Sépulcre",
		["Thelsamar"] = true,
		["Theramore"] = true,
		["Thorium Point"] = "Halte du Thorium",
		["Thunder Bluff"] = "Les Pitons du Tonnerre",
		["Undercity"] = "Fossoyeuse",
		["Valormok"] = true,
		["Zoram'gar Outpost"] = "Avant-poste de Zoram'gar",
		-- minimap subzones
		["Trade District"] = "Quartier commerçant",
		["The Great Forge"] = "La Grande Forge",
		["Valley of Strength"] = "Vallée de la Force",
	},
}
