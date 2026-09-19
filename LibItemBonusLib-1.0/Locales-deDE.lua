-- LibItemBonusLib-1.0 / deDE
-- Ace3v port: the translation tables below are unchanged from
-- ItemBonusLib-1.0. The file only stores its table; LibItemBonusLib-1.0.lua
-- registers it with AceLocale-3.0.

LibItemBonusLib_Locales = LibItemBonusLib_Locales or {}
LibItemBonusLib_Locales.deDE = {
	-- bonus names
	NAMES = {
		STR 		= "Stärke",
		AGI 		= "Beweglichkeit",
		STA 		= "Ausdauer",
		INT 		= "Intelligenz",
		SPI 		= "Willenskraft",
		ARMOR 		= "Verstärkte Rüstung",

		ARCANERES 	= "Arkanwiderstand",	
		FIRERES 	= "Feuerwiderstand",
		NATURERES 	= "Naturwiderstand",
		FROSTRES 	= "Frostwiderstand",
		SHADOWRES 	= "Schattenwiderstand",

		FISHING 	= "Angeln",
		MINING 		= "Bergbau",
		HERBALISM 	= "Kräuterkunde",
		SKINNING 	= "Kürschnerei",
		DEFENSE 	= "Verteidigung",

		BLOCK 		= "Blockchance",
		BLOCKVALUE  = "Blockwert",
		DODGE 		= "Ausweichen",
		PARRY 		= "Parieren",
		ATTACKPOWER = "Angriffskraft",
		ATTACKPOWERUNDEAD = "Angriffskraft gegen Untote",
		ATTACKPOWERFERAL = "Angriffskraft in Tierform",
		CRIT 		= "krit. Treffer",
		RANGEDATTACKPOWER = "Distanzangriffskraft",
		RANGEDCRIT 	= "krit. Schuss",
		TOHIT 		= "Trefferchance",
		DMG			= "Zauberschaden",
		DMGUNDEAD	= "Zauberschaden gegen Untote",
		ARCANEDMG 	= "Arkanschaden",
		FIREDMG 	= "Feuerschaden",
		FROSTDMG 	= "Frostschaden",
		HOLYDMG 	= "Heiligschaden",
		NATUREDMG 	= "Naturschaden",
		SHADOWDMG 	= "Schattenschaden",
		HOLYCRIT 	= "krit. Heiligzauber",	
		SPELLCRIT 	= "krit. Zauber",
		SPELLTOHIT 	= "Zaubertrefferchance",
		SPELLPEN 	= "Magiedurchdringung",
		HEAL 		= "Heilung",
		HEALTHREG 	= "Lebensregeneration",
		MANAREG 	= "Manaregeneration",	
		HEALTH 		= "Lebenspunkte",
		MANA 		= "Manapunkte",	
	},

	PATTERNS_PASSIVE = {
		{ pattern = "%+(%d+) bei allen Widerstandsarten%.", effect = { "ARCANERES", "FIRERES", "FROSTRES", "NATURERES", "SHADOWRES"} },
		{ pattern = "Erhöht Eure Chance, Angriffe mit einem Schild zu blocken, um (%d+)%%%.", effect = "BLOCK" },
		{ pattern = "Erhöht den Blockwert Eures Schilde?s um (%d+)%.", effect = "BLOCKVALUE" },
		{ pattern = "Erhöht Eure Chance, einem Angriff auszuweichen, um (%d+)%%%.", effect = "DODGE" },
		{ pattern = "Erhöht Eure Chance, einen Angriff zu parieren, um (%d+)%%%.", effect = "PARRY" },
		{ pattern = "Erhöht Eure Chance, einen kritischen Treffer durch Zauber zu erzielen, um (%d+)%%%.", effect = "SPELLCRIT" },
		{ pattern = "Erhöht Eure Chance, einen kritischen Treffer durch Heiligzauber zu erzielen, um (%d+)%%%.", effect = "HOLYCRIT" },
		{ pattern = "Erhöht Eure Chance, einen kritischen Treffer zu erzielen, um (%d+)%%%.", effect = "CRIT" },
		{ pattern = "Erhöht Eure Chance, mit Geschosswaffen einen kritischen Schlag zu erzielen, um (%d+)%.", effect = "RANGEDCRIT" },
		{ pattern = "Erhöht durch Arkanzauber und Arkaneffekte zugefügten Schaden um bis zu (%d+)%.", effect = "ARCANEDMG" },
		{ pattern = "Erhöht durch Feuerzauber und Feuereffekte zugefügten Schaden um bis zu (%d+)%.", effect = "FIREDMG" },
		{ pattern = "Erhöht durch Frostzauber und Frosteffekte zugefügten Schaden um bis zu (%d+)%.", effect = "FROSTDMG" },
		{ pattern = "Erhöht durch Heiligzauber und Heiligeffekte zugefügten Schaden um bis zu (%d+)%.", effect = "HOLYDMG" },
		{ pattern = "Erhöht durch Naturzauber und Natureffekte zugefügten Schaden um bis zu (%d+)%.", effect = "NATUREDMG" },
		{ pattern = "Erhöht durch Schattenzauber und Schatteneffekte zugefügten Schaden um bis zu (%d+)%.", effect = "SHADOWDMG" },
		{ pattern = "Erhöht durch Zauber und magische Effekte zugefügten Schaden und Heilung um bis zu (%d+)%.", effect = {"HEAL","DMG"} },
		{ pattern = "Erhöht den durch magische Zauber und magische Effekte zugefügten Schaden gegen Untote um bis zu (%d+)", effect = "DMGUNDEAD" },
		{ pattern = "+(%d+) Angriffskraft gegen Untote.", effect = "ATTACKPOWERUNDEAD" },
		{ pattern = "Erhöht durch Zauber und Effekte verursachte Heilung um bis zu (%d+)%.", effect = "HEAL" },
		{ pattern = "Erhöht die durch Zauber und Effekte verursachte Heilung um bis zu (%d+)%.", effect = "HEAL" },
		{ pattern = "Stellt alle 5 Sek%. (%d+) Punkt%(e%) Gesundheit wieder her%.", effect = "HEALTHREG" },
		{ pattern = "Stellt alle 5 Sek%. (%d+) Punkt%(e%) Mana wieder her%.", effect = "MANAREG" },
		{ pattern = "Verbessert Eure Trefferchance um (%d+)%%%.", effect = "TOHIT" },
		{ pattern = "Erhöht Eure Chance mit Zaubern zu treffen um (%d+)%%%.", effect = "SPELLTOHIT" },
		{ pattern = "Reduziert die Magiewiderstände der Ziele Eurer Zauber um (%d+)%.", effect = "SPELLPEN" }
	,
		-- Ace3v: derived from live Classic Era item / item-set tooltips, by
		-- locating the vanilla enUS sentence first and reading the same line in
		-- this locale. Added only for effects this locale had no
		-- pattern for; nothing existing was replaced.
		{ pattern = "Die Zauberzeit von 'Kettenheilung' wird um 0%.(%d+) Sekunden reduziert%.", effect = "CASTINGCHAINHEAL" },	-- set 501 | -0.4 seconds on the casting time of your Cha
		{ pattern = "Verringert die Zauberzeit für Euren Zauber 'Blitzheilung' um 0%.(%d+)%.", effect = "CASTINGFLASHHEAL" },	-- set 202 | -0.1 sec to the casting time of your Flash H
		{ pattern = "Verringert die Zauberzeit Eures Zaubers 'Heilende Berührung' um 0,(%d+) Sekunden%.", effect = "CASTINGHEALINGTOUCH" },	-- item 22399 | Reduces the casting time of your Healing Tou
		{ pattern = "Verringert die Zauberzeit Eurer Zauber 'Heiliges Licht' um 0%.(%d+) Sekunden%.", effect = "CASTINGHOLYLIGHT" },	-- set 475 | Reduces the casting time of your Holy Light 
		{ pattern = "Verringert die Zauberzeit Eures Zaubers 'Nachwachsen' um 0%.(%d+) Sekunden%.", effect = "CASTINGREGROWTH" },	-- set 214 | Reduces the casting time of your Regrowth sp
		{ pattern = "Verringert die Manakosten Eurer Zauber 'Heilende Berührung', 'Nachwachsen', 'Verjüngung' und 'Gelassenheit' um (%d+)%%%.", effect = "CHEAPERDRUID" },	-- set 521 | Reduces the mana cost of your Healing Touch,
		{ pattern = "Verringert die Manakosten Eures Zaubers 'Erneuerung' um (%d+)%%%.", effect = "CHEAPERRENEW" },	-- set 525 | Reduces the mana cost of your Renew spell by
		{ pattern = "Erhöht die Dauer Eures Zaubers 'Verjüngung' um (%d+) Sek%.", effect = "DURATIONREJUV" },	-- set 214 | Increases the duration of your Rejuvenation 
		{ pattern = "Erhöht die Wirkungsdauer von 'Erneuern' um (%d+) Sekunden%.", effect = "DURATIONRENEW" },	-- set 507 | Increases the duration of your Renew spell b
		{ pattern = "Erhöht den durch 'Kettenheilung' geheilten Wert bei jedem Ziel nach dem ersten um (%d+)%%%.", effect = "IMPCHAINHEAL" },	-- set 216 | Increases the amount healed by Chain Heal to
		{ pattern = "Erhöht durch 'Lichtblitz' verursachte Heilung um bis zu (%d+)%.", effect = "IMPFLASHOFLIGHT" },	-- item 23201 | Increases healing done by Flash of Light by 
		{ pattern = "Erhöht die Heilung Eures Zaubers 'Geringe Welle der Heilung' um bis zu (%d+)%.", effect = "IMPLESSERHEALINGWAVE" },	-- item 22396 | Increases healing done by Lesser Healing Wav
		{ pattern = "Erhöht die Heilwirkung Eures Zaubers 'Verjüngung' um bis zu (%d+)%.", effect = "IMPREJUVENATION" },	-- item 22398 | Increases healing done by Rejuvenation by up
		{ pattern = "Eure Zauber 'Welle der Heilung' springen auf bis zu zwei zusätzliche Ziele über%. Bei jedem Sprung reduziert sich die Effektivität der Heilung um (%d+)%%%.", effect = "JUMPHEALINGWAVE" },	-- set 207 | Your Healing Wave will now jump to additiona
		{ pattern = "Erhöht Eure Chance, einen kritischen Treffer durch Naturzauber zu erzielen, um (%d+)%%%.", effect = "NATURECRIT" },	-- set 216 | Improves your chance to get a critical strik
		{ pattern = "Wenn die Zauber 'Welle der Heilung' oder 'Geringe Welle der Heilung' gewirkt werden, besteht eine Chance von (%d+)%%, Mana zu gewinnen%. Der Managewinn entspricht 35%% der Basiskosten des Zaubers%.", effect = "REFUNDHEALINGWAVE" },	-- set 207 | After casting your Healing Wave or Lesser He
		{ pattern = "Bei kritischen Treffern Eures Zaubers 'Heilende Berührung' erhaltet Ihr (%d+)%% der Manakosten dieses Zaubers zurück%.", effect = "REFUNDHTCRIT" },	-- set 521 | On Healing Touch critical hits, you regain 3
		{ pattern = "Ermöglicht, dass (%d+)%% Eurer Manaregeneration während des Zauberwirkens weiterläuft%.", effect = "CASTINGREG" },	-- set 211 | Allows 15% of your Mana regeneration to cont
	},


	PATTERNS_GENERIC_LOOKUP = {
		["Alle Werte"] 			= {"STR", "AGI", "STA", "INT", "SPI"},
		["Stärke"]				= "STR",
		["Beweglichkeit"]		= "AGI",
		["Ausdauer"]			= "STA",
		["Intelligenz"]			= "INT",
		["Willenskraft"] 		= "SPI",

		["Alle Widerstandsarten"] 	= { "ARCANERES", "FIRERES", "FROSTRES", "NATURERES", "SHADOWRES"},

		["Angeln"]				= "FISHING",
		["Angelköder"]			= "FISHING",
		["Bergbau"]				= "MINING",
		["Kräuterkunde"]		= "HERBALISM",
		["Kürschnerei"]		= "SKINNING",
		["Verteidigung"]		= "DEFENSE",
		["Verteidigungsfertigkeit"] = "DEFENSE",

		["Angriffskraft"] 		= "ATTACKPOWER",
		["Angriffskraft gegen Untote"] = "ATTACKPOWERUNDEAD",
		["Angriffskraft in Katzengestalt, Bärengestalt oder Terrorbärengestalt"] = "ATTACKPOWERFERAL",
		["Ausweichen"] 			= "DODGE",
		["Blocken"]				= "BLOCK",
		["Blockwert"]			= "BLOCKVALUE",
		["Trefferchance"]		= "TOHIT",
		["Distanzangriffskraft"] = "RANGEDATTACKPOWER",
		["Gesundheit alle 5 Sek"] = "HEALTHREG",
		["Heilzauber"] 			= "HEAL",
		["Mana alle 5 Sek"] 	= "MANAREG",
		["Manaregeneration"]	= "MANAREG",
		["Zauberschaden erhöhen"]= "DMG",
		["Kritischer Treffer"] 	= "CRIT",
		["Zauberschaden"] 		= {"HEAL","DMG"},
		["Blocken"]				= "BLOCK",
		["Gesundheit"]			= "HEALTH",
		["HP"]					= "HEALTH",
		["Heilzauber"]			= "HEAL",
		["Heilung und Zauberschaden"] = {"HEAL","DMG"},
		["Zauberschaden und Heilung"] = {"HEAL","DMG"},
		["Schadenszauber und Heilzauber"] = {"HEAL","DMG"},
		["Schadens- und Heilzauber"] = {"HEAL","DMG"},
		["Zaubertrefferchance"]	= "SPELLTOHIT",

		["Mana"]				= "MANA",
		["Rüstung"]			= "ARMOR",
		["Verstärkte Rüstung"]= "ARMOR"
	,
		-- Ace3v: tokens harvested from live Classic Era enchant tooltips, by
		-- aligning the enUS and localized tooltips of the same enchant. Added
		-- only where this
		-- locale had no entry; nothing existing was replaced. Note that the
		-- Classic Era wording can differ from vanilla's -- ruRU in particular
		-- uses post-vanilla "rating" terminology here.
		["Schaden"] = "DMG",
		["Erhöht Heiligeffekte"] = "HEAL",
			-- Ace3v: tokens harvested from live Classic Era enchant tooltips, by
		-- aligning the enUS and localized tooltips of the same enchant. Added
		-- only where this
		-- locale had no entry; nothing existing was replaced. Note that the
		-- Classic Era wording can differ from vanilla's -- ruRU in particular
		-- uses post-vanilla "rating" terminology here.
		-- Ace3v: Classic-Era enchant wording (enchants 2684/2685). On 1.12.1 the client
		-- says "when fighting Undead" in token position (see PATTERNS_GENERIC_LOOKUP above)
		-- and delivers the spell-damage form as a sentence in PATTERNS_PASSIVE. Kept because
		-- entries here are additive and can only widen what matches.
		["Zauberschaden gegen Untote"] = "DMGUNDEAD",
	},
		
	PATTERNS_GENERIC_STAGE1 = {
		{ pattern = "Arkan", 	effect = "ARCANE" },	
		{ pattern = "Feuer", 	effect = "FIRE" },	
		{ pattern = "Frost", 	effect = "FROST" },	
		{ pattern = "Heilig", 	effect = "HOLY" },	
		{ pattern = "Schatten", effect = "SHADOW" },	
		{ pattern = "Natur", 	effect = "NATURE" },
	},

	PATTERNS_GENERIC_STAGE2 = {
		{ pattern = "widerst", 	effect = "RES" },	
		{ pattern = "schaden", 	effect = "DMG" },
		{ pattern = "effekte", 	effect = "DMG" },
	},


	PATTERNS_OTHER = {
		{ pattern = "Manaregeneration (%d+) per 5 Sek%.", effect = "MANAREG" },
		
		{ pattern = "Schwaches Zauberöl", effect = {"DMG", "HEAL"}, value = 8 },
		{ pattern = "Geringes Zauberöl", effect = {"DMG", "HEAL"}, value = 16 },
		{ pattern = "Zauberöl", effect = {"DMG", "HEAL"}, value = 24 },
		{ pattern = "Hervorragendes Zauberöl", effect = {"DMG", "HEAL", "SPELLCRIT"}, value = {36, 36, 1} },

		{ pattern = "Schwaches Manaöl", effect = "MANAREG", value = 4 },
		{ pattern = "Geringes Manaöl", effect = "MANAREG", value = 8 },
		{ pattern = "Hervorragendes Manaöl", effect = { "MANAREG", "HEAL"}, value = {12, 25} },

		{ pattern = "Eterniumschnur", effect = "FISHING", value = 5 },
		
		{ pattern = "Heilung %+31 und 5 Mana alle 5 Sek%.", effect = { "MANAREG", "HEAL"}, value = {5, 31} },
		{ pattern = "Ausdauer %+16 und Rüstung %+100", effect = { "STA", "ARMOR"}, value = {16, 100} },
		{ pattern = "Angriffskraft %+26 und %+1%% kritische Treffer", effect = { "ATTACKPOWER", "CRIT"}, value = {26, 1} },
		{ pattern = "Zauberschaden %+15 und %+1%% kritische Zaubertreffer", effect = { "DMG", "HEAL", "SPELLCRIT"}, value = {15, 15, 1} },
	}
}
