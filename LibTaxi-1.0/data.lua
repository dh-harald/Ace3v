-- LibTaxi-1.0 flight point data for WoW 1.12.1.
--
-- Ported from ZygorGuidesViewerClassic's Libs-Classic/LibTaxi-1.0/data.lua.  Plain data in a
-- global: the library adopts this table and clears the global, because the client may run a
-- data file before the library's main file.
--
-- Continent keys are LibHereBeDragons-1.0 map ids (13 Kalimdor, 14 Eastern Kingdoms), zone
-- keys are English zone names, x and y are percent (the library normalises them to 0-1).
-- faction: "A" Alliance, "H" Horde, "B" both.  A flightcost of 0 means "connected, time
-- unknown" and gets estimated.

LibTaxi_Data = {}
local data = LibTaxi_Data

data.taxipoints = {



--------------------
---   KALIMDOR   ---
--------------------

[13]={
	
	["Ashenvale"] = {
		{name="Splintertree Post",faction="H",npc="Vhulgra",npcid=12616,x=73.18,y=61.59},
		{name="Zoram'gar Outpost",faction="H",npc="Andruk",npcid=11901,x=12.24,y=33.80},
		{name="Astranaar",faction="A",npc="Daelyshia",npcid=4267,x=34.41,y=47.99},
	},
	
	["Azshara"] = {
		{name="Talrendis Point",faction="A",npc="Jarrodenus",npcid=12577,x=11.90,y=77.59},
		{name="Valormok",faction="H",npc="Kroum",npcid=8610,x=21.96,y=49.62},
	},
	
	["Darkshore"] = {
		{name="Auberdine",faction="A",npc="Caylais Moonfeather",npcid=3841,x=36.34,y=45.58},
	},
	
	["Desolace"] = {
		{name="Shadowprey Village",faction="H",npc="Thalon",npcid=6726,x=21.60,y=74.13},
		{name="Nijel's Point",faction="A",npc="Baritanas Skyriver",npcid=6706,x=64.66,y=10.54},
	},
	
	["Dustwallow Marsh"] = {
		{name="Brackenwall Village",faction="H",npc="Shardi",npcid=11899,x=35.56,y=31.88},
		{name="Theramore",faction="A",npc="Baldruc",npcid=4321,x=67.48,y=51.30},
	},
	
	["Felwood"] = {
		{name="Bloodvenom Post",faction="H",npc="Brakkar",npcid=11900,x=34.44,y=53.96},
		{name="Talonbranch Glade",faction="A",npc="Mishellena",npcid=12578,x=62.49,y=24.24},
	},
	
	["Feralas"] = {
		{name="Camp Mojache",faction="H",npc="Shyn",npcid=8020,x=75.45,y=44.36},
		{name="Thalanaar",faction="A",npc="Thyssiana",npcid=4319,x=89.50,y=45.85},
		{name="Feathermoon",faction="A",npc="Fyldren Moonfeather",npcid=8019,x=30.24,y=43.25},
	},
	
	["Moonglade"] = {
		{name="Moonglade",faction="H",npc="Faustron",npcid=12740,x=32.09,y=66.61},
		{name="Moonglade",faction="A",npc="Sindrayl",npcid=10897,x=48.10,y=67.34},
		--{name="Nighthaven",faction="A",class="DRUID",npc="Silva Fil'naveth",npcid=11800,x=44.15,y=45.22,forceknown=true},
		--{name="Nighthaven",faction="H",class="DRUID",npc="Bunthen Plainswind",npcid=11798,x=44.29,y=45.87,forceknown=true},
	},
	
	["Orgrimmar"] = {
		{name="Orgrimmar",faction="H",npc="Doras",npcid=3310,x=45.12,y=63.89},
	},
	
	["Silithus"] = {
		{name="Cenarion Hold",faction="H",npc="Runk Windtamer",npcid=15178,x=48.68,y=36.67},
		{name="Cenarion Hold",faction="A",npc="Cloud Skydancer",npcid=15177,x=50.58,y=34.45},
	},
	
	["Stonetalon Mountains"] = {
		{name="Stonetalon Peak",faction="A",npc="Teloren",npcid=4407,x=36.44,y=7.18},
		{name="Sun Rock Retreat",faction="H",npc="Tharm",npcid=4312,x=45.12,y=59.84},
	},
	
	["Tanaris"] = {
		{name="Gadgetzan",faction="H",npc="Bulkrek Ragefist",npcid=7824,x=51.60,y=25.44},
		{name="Gadgetzan",faction="A",npc="Bera Stonehammer",npcid=7823,x=51.01,y=29.35},
	},
	
	["Teldrassil"] = {
		{name="Rut'theran Village",faction="A",npc="Vesprystus",npcid=3838,x=58.40,y=94.02,region="ruttheran"},
	},
	
	["The Barrens"] = {
		{name="Crossroads",faction="H",npc="Devrak",npcid=3615,x=51.51,y=30.36},
		{name="Camp Taurajo",faction="H",npc="Omusa Thunderhorn",npcid=10378,x=44.45,y=59.15},
		{name="Ratchet",faction="B",npc="Bragok",npcid=16227,x=63.08,y=37.16},
	},
	
	["Thousand Needles"] = {
		{name="Freewind Post",faction="H",npc="Nyse",npcid=4317,x=45.14,y=49.11},
	},
	
	["Thunder Bluff"] = {
		{name="Thunder Bluff",faction="H",npc="Tal",npcid=2995,x=46.99,y=49.83},
	},
	
	["Un'Goro Crater"] = {
		{name="Marshal's Refuge",faction="B",npc="Gryfe",npcid=10583,x=45.23,y=5.83},
	},
	
	["Winterspring"] = {
		{name="Everlook",faction="A",npc="Maethrya",npcid=11138,x=62.33,y=36.61},
		{name="Everlook",faction="H",npc="Yugrek",npcid=11139,x=60.47,y=36.30},
	},
},



----------------------------
---   EASTERN KINGDOMS   ---
----------------------------

[14]={
	
	["Arathi Highlands"] = {
		{name="Refuge Pointe",faction="A",npc="Cedrik Prose",npcid=2835,x=45.76,y=46.11},
		{name="Hammerfall",faction="H",npc="Urda",npcid=2851,x=73.06,y=32.68},
	},
	
	["Badlands"] = {
		{name="Kargath",faction="H",npc="Gorrik",npcid=2861,x=3.99,y=44.78},
	},
	
	["Blasted Lands"] = {
		{name="Nethergarde Keep",faction="A",npc="Alexandra Constantine",npcid=8609,x=65.54,y=24.34},
	},
	
	["Burning Steppes"] = {
		{name="Flame Crest",faction="H",npc="Vahgruk",npcid=13177,x=65.69,y=24.22},
		{name="Morgan's Vigil",faction="A",npc="Borgus Stoutarm",npcid=2299,x=84.33,y=68.33},
	},
	
	["Duskwood"] = {
		{name="Darkshire",faction="A",npc="Felicia Maline",npcid=2409,x=77.49,y=44.29},
	},
	
	["Eastern Plaguelands"] = {
		{name="Light's Hope Chapel",faction="A",npc="Khaelyn Steelwing",npcid=12617,x=81.64,y=59.28},
		{name="Light's Hope Chapel",faction="H",npc="Georgia",npcid=12636,x=80.22,y=57.01},
	},
	
	["Hillsbrad Foothills"] = {
		{name="Southshore",faction="A",npc="Darla Harris",npcid=2432,x=49.34,y=52.27},
		{name="Tarren Mill",faction="H",npc="Zarise",npcid=2389,x=60.14,y=18.62},
	},
	
	["Ironforge"] = {
		{name="Ironforge",faction="A",npc="Gryth Thurden",npcid=1573,x=55.50,y=47.74},
	},
	
	["Loch Modan"] = {
		{name="Thelsamar",faction="A",npc="Thorgrum Borrelson",npcid=1572,x=33.94,y=50.95},
	},
	
	["Redridge Mountains"] = {
		{name="Lakeshire",faction="A",npc="Ariena Stormfeather",npcid=931,x=30.59,y=59.41},
	},
	
	["Searing Gorge"] = {
		{name="Thorium Point",faction="H",npc="Grisha",npcid=3305,x=34.84,y=30.87},
		{name="Thorium Point",faction="A",npc="Lanie Reed",npcid=2941,x=37.94,y=30.86},
	},
	
	["Silverpine Forest"] = {
		{name="The Sepulcher",faction="H",npc="Karos Razok",npcid=2226,x=45.62,y=42.60},
	},
	
	["Stranglethorn Vale"] = {
		{name="Grom'gol",faction="H",npc="Thysta",npcid=1387,x=32.54,y=29.35},
		{name="Booty Bay",faction="H",npc="Gringer",npcid=2858,x=26.87,y=77.10},
		{name="Booty Bay",faction="A",npc="Gyll",npcid=2859,x=27.53,y=77.79},
	},
	
	["Swamp of Sorrows"] = {
		{name="Stonard",faction="H",npc="Breyk",npcid=6026,x=46.07,y=54.83},
	},
	
	["Stormwind City"] = {
		{name="Stormwind",faction="A",npc="Dungar Longdrink",npcid=352,x=66.27,y=62.13},
	},
	
	["The Hinterlands"] = {
		{name="Revantusk Village",faction="H",npc="Gorkas",npcid=4314,x=81.70,y=81.76},
		{name="Aerie Peak",faction="A",npc="Guthrum Thunderfist",npcid=8018,x=11.07,y=46.15},
	},
	
	["Undercity"] = {
		{name="Undercity",faction="H",npc="Michael Garrett",npcid=4551,x=63.25,y=48.56},
	},
	
	["Western Plaguelands"] = {
		{name="Chillwind Camp",faction="A",npc="Bibilfaz Featherwhistle",npcid=12596,x=42.92,y=85.06},
	},
	
	["Westfall"] = {
		{name="Sentinel Hill",faction="A",npc="Thor",npcid=523,x=56.55,y=52.64},
	},
	
	["Wetlands"] = {
		{name="Menethil Harbor",faction="A",npc="Shellei Brondir",npcid=1571,x=9.49,y=59.69},
	},
}
}
-- NOTE: If two taxis have the same name but different factions then a factions field must be added in here. See Serpent's Spine.
-- If not then one of the taxis will be marked with the wrong faction so will not properly get neighbors that it should.
-- This data is regenerated when performing a Taxi Connections Dump. Any weird data edits may be lost. 
data.flightcost = {
	[13]={
		{
			tag = "462:396",
			name = "Astranaar",
			neighbors = {
				["390:402"] = 154, -- Stonetalon Peak
				["427:251"] = 149, -- Auberdine
				["610:400"] = 154, -- Talrendis Point
			},
		},
		{
			tag = "427:251",
			name = "Auberdine",
			neighbors = {
				["313:692"] = 473, -- Feathermoon
				["390:402"] = 178, -- Stonetalon Peak
				["396:506"] = 292, -- Nijel's Point
				["416:157"] = 86, -- Rut'theran Village
				["462:396"] = 149, -- Astranaar
				["530:257"] = 190, -- Talonbranch Glade
				["552:205"] = 152, -- Moonglade
				["610:400"] = 302, -- Talrendis Point
				["636:669"] = 676, -- Theramore
			},
		},
		{
			tag = "464:304",
			name = "Bloodvenom Post",
			neighbors = {
				["537:205"] = 0, -- Moonglade
				["557:530"] = 0, -- Crossroads
				["628:443"] = 0, -- Orgrimmar
				["631:361"] = 0, -- Valormok
				["640:232"] = 0, -- Everlook
			},
		},
		{
			tag = "567:641",
			name = "Brackenwall Village",
			neighbors = {
				["449:561"] = 0, -- Thunder Bluff
				["557:530"] = 0, -- Crossroads
				["606:801"] = 0, -- Gadgetzan
				["628:443"] = 0, -- Orgrimmar
			},
		},
		{
			tag = "442:693",
			name = "Camp Mojache",
			neighbors = {
				["316:584"] = 0, -- Shadowprey Village
				["416:792"] = 0, -- Cenarion Hold
				["449:561"] = 0, -- Thunder Bluff
				["549:734"] = 0, -- Freewind Post
				["557:530"] = 0, -- Crossroads
				["606:801"] = 0, -- Gadgetzan
			},
		},
		{
			tag = "528:610",
			name = "Camp Taurajo",
			neighbors = {
				["449:561"] = 0, -- Thunder Bluff
				["549:734"] = 0, -- Freewind Post
				["557:530"] = 0, -- Crossroads
			},
		},
		{
			tag = "418:790",
			name = "Cenarion Hold",
			faction = "A",
			neighbors = {
				["313:692"] = 160, -- Feathermoon
				["497:763"] = 93, -- Marshal's Refuge
				["604:809"] = 0, -- Gadgetzan
			},
		},
		{
			tag = "606:801",
			name = "Gadgetzan",
			faction = "H",
			neighbors = {
				["416:792"] = 0, -- Cenarion Hold
				["442:693"] = 0, -- Camp Mojache
				["449:561"] = 0, -- Thunder Bluff
				["497:763"] = 0, -- Marshal's Refuge
				["549:734"] = 0, -- Freewind Post
				["557:530"] = 0, -- Crossroads
				["567:641"] = 0, -- Brackenwall Village
				["628:443"] = 0, -- Orgrimmar
			},
		},
		{
			tag = "497:763",
			name = "Marshal's Refuge",
			neighbors = {
				["416:792"] = 0, -- Cenarion Hold
				["418:790"] = 93, -- Cenarion Hold
				["604:809"] = 104, -- Gadgetzan
				["606:801"] = 0, -- Gadgetzan
			},
		},
		{
			tag = "645:232",
			name = "Everlook",
			faction = "A",
			neighbors = {
				["530:257"] = 123, -- Talonbranch Glade
				["552:205"] = 131, -- Moonglade
				["610:400"] = 177, -- Talrendis Point
			},
		},
		{
			tag = "640:232",
			name = "Everlook",
			faction = "H",
			neighbors = {
				["464:304"] = 0, -- Bloodvenom Post
				["537:205"] = 0, -- Moonglade
				["628:443"] = 0, -- Orgrimmar
				["631:361"] = 0, -- Valormok
			},
		},
		{
			tag = "416:792",
			name = "Cenarion Hold",
			faction = "H",
			neighbors = {
				["442:693"] = 0, -- Camp Mojache
				["497:763"] = 0, -- Marshal's Refuge
				["606:801"] = 0, -- Gadgetzan
			},
		},
		{
			tag = "549:734",
			name = "Freewind Post",
			neighbors = {
				["442:693"] = 0, -- Camp Mojache
				["449:561"] = 0, -- Thunder Bluff
				["528:610"] = 0, -- Camp Taurajo
				["557:530"] = 0, -- Crossroads
				["606:801"] = 0, -- Gadgetzan
			},
		},
		{
			tag = "604:809",
			name = "Gadgetzan",
			faction = "A",
			neighbors = {
				["418:790"] = 0, -- Cenarion Hold
				["482:696"] = 0, -- Thalanaar
				["497:763"] = 104, -- Marshal's Refuge
				["636:669"] = 155, -- Theramore
			},
		},
		{
			tag = "557:530",
			name = "Crossroads",
			neighbors = {
				["407:472"] = 0, -- Sun Rock Retreat
				["409:373"] = 0, -- Zoram'gar Outpost
				["442:693"] = 0, -- Camp Mojache
				["449:561"] = 0, -- Thunder Bluff
				["464:304"] = 0, -- Bloodvenom Post
				["528:610"] = 0, -- Camp Taurajo
				["549:734"] = 0, -- Freewind Post
				["554:417"] = 0, -- Splintertree Post
				["567:641"] = 0, -- Brackenwall Village
				["605:549"] = 0, -- Ratchet
				["606:801"] = 0, -- Gadgetzan
				["628:443"] = 0, -- Orgrimmar
				["631:361"] = 0, -- Valormok
			},
		},
		{
			tag = "313:692",
			name = "Feathermoon",
			neighbors = {
				["396:506"] = 228, -- Nijel's Point
				["418:790"] = 160, -- Cenarion Hold
				["427:251"] = 473, -- Auberdine
				["482:696"] = 179, -- Thalanaar
			},
		},
		{
			tag = "537:205",
			name = "Moonglade",
			faction = "H",
			neighbors = {
				["464:304"] = 0, -- Bloodvenom Post
				["640:232"] = 0, -- Everlook
			},
		},
		{
			tag = "482:696",
			name = "Thalanaar",
			neighbors = {
				["313:692"] = 179, -- Feathermoon
				["604:809"] = 0, -- Gadgetzan
				["636:669"] = 164, -- Theramore
			},
		},
		{
			tag = "396:506",
			name = "Nijel's Point",
			neighbors = {
				["313:692"] = 228, -- Feathermoon
				["390:402"] = 121, -- Stonetalon Peak
				["427:251"] = 292, -- Auberdine
				["636:669"] = 309, -- Theramore
			},
		},
		{
			tag = "628:443",
			name = "Orgrimmar",
			neighbors = {
				["449:561"] = 0, -- Thunder Bluff
				["464:304"] = 0, -- Bloodvenom Post
				["554:417"] = 0, -- Splintertree Post
				["557:530"] = 0, -- Crossroads
				["567:641"] = 0, -- Brackenwall Village
				["606:801"] = 0, -- Gadgetzan
				["631:361"] = 0, -- Valormok
				["640:232"] = 0, -- Everlook
			},
		},
		{
			tag = "605:549",
			name = "Ratchet",
			neighbors = {
				["557:530"] = 0, -- Crossroads
				["610:400"] = 133, -- Talrendis Point
				["636:669"] = 115, -- Theramore
			},
		},
		{
			tag = "416:157",
			name = "Rut'theran Village",
			neighbors = {
				["427:251"] = 86, -- Auberdine
			},
		},
		{
			tag = "316:584",
			name = "Shadowprey Village",
			neighbors = {
				["407:472"] = 0, -- Sun Rock Retreat
				["442:693"] = 0, -- Camp Mojache
				["449:561"] = 0, -- Thunder Bluff
			},
		},
		{
			tag = "554:417",
			name = "Splintertree Post",
			neighbors = {
				["409:373"] = 0, -- Zoram'gar Outpost
				["557:530"] = 0, -- Crossroads
				["628:443"] = 0, -- Orgrimmar
				["631:361"] = 0, -- Valormok
			},
		},
		{
			tag = "631:361",
			name = "Valormok",
			neighbors = {
				["449:561"] = 0, -- Thunder Bluff
				["464:304"] = 0, -- Bloodvenom Post
				["554:417"] = 0, -- Splintertree Post
				["557:530"] = 0, -- Crossroads
				["628:443"] = 0, -- Orgrimmar
				["640:232"] = 0, -- Everlook
			},
		},
		{
			tag = "552:205",
			name = "Moonglade",
			faction = "A",
			neighbors = {
				["427:251"] = 152, -- Auberdine
				["530:257"] = 68, -- Talonbranch Glade
				["645:232"] = 131, -- Everlook
			},
		},
		{
			tag = "530:257",
			name = "Talonbranch Glade",
			neighbors = {
				["427:251"] = 190, -- Auberdine
				["552:205"] = 68, -- Moonglade
				["610:400"] = 285, -- Talrendis Point
				["645:232"] = 123, -- Everlook
			},
		},
		{
			tag = "610:400",
			name = "Talrendis Point",
			neighbors = {
				["427:251"] = 302, -- Auberdine
				["462:396"] = 154, -- Astranaar
				["530:257"] = 285, -- Talonbranch Glade
				["605:549"] = 133, -- Ratchet
				["636:669"] = 236, -- Theramore
				["645:232"] = 177, -- Everlook
			},
		},
		{
			tag = "390:402",
			name = "Stonetalon Peak",
			neighbors = {
				["396:506"] = 121, -- Nijel's Point
				["427:251"] = 178, -- Auberdine
				["462:396"] = 154, -- Astranaar
			},
		},
		{
			tag = "636:669",
			name = "Theramore",
			neighbors = {
				["396:506"] = 309, -- Nijel's Point
				["427:251"] = 676, -- Auberdine
				["482:696"] = 164, -- Thalanaar
				["604:809"] = 155, -- Gadgetzan
				["605:549"] = 115, -- Ratchet
				["610:400"] = 236, -- Talrendis Point
			},
		},
		{
			tag = "449:561",
			name = "Thunder Bluff",
			neighbors = {
				["316:584"] = 0, -- Shadowprey Village
				["407:472"] = 0, -- Sun Rock Retreat
				["442:693"] = 0, -- Camp Mojache
				["528:610"] = 0, -- Camp Taurajo
				["549:734"] = 0, -- Freewind Post
				["557:530"] = 0, -- Crossroads
				["567:641"] = 0, -- Brackenwall Village
				["606:801"] = 0, -- Gadgetzan
				["628:443"] = 0, -- Orgrimmar
				["631:361"] = 0, -- Valormok
			},
		},
		{
			tag = "407:472",
			name = "Sun Rock Retreat",
			neighbors = {
				["316:584"] = 0, -- Shadowprey Village
				["449:561"] = 0, -- Thunder Bluff
				["557:530"] = 0, -- Crossroads
			},
		},
		{
			tag = "409:373",
			name = "Zoram'gar Outpost",
			neighbors = {
				["554:417"] = 0, -- Splintertree Post
				["557:530"] = 0, -- Crossroads
			},
		},
	},

	[14] = {
		{
			name = "Aerie Peak",
			neighbors = {
				["478:299"] = 0, -- Southshore
				["507:488"] = 0, -- Ironforge
				["520:224"] = 0, -- Chillwind Camp
				["570:323"] = 0, -- Refuge Pointe
				["699:162"] = 0, -- Light's Hope Chapel
			},
			tag="546:253",
		},

		{
			name = "Booty Bay",
			neighbors = {
				["448:836"] = 0, -- Grom'gol
				["554:571"] = 0, -- Kargath
				["605:746"] = 0, -- Stonard
			},
			faction="H",
			tag="431:929",
		},

		{
			name = "Booty Bay",
			neighbors = {
				["407:754"] = 0, -- Sentinel Hill
				["432:672"] = 0, -- Stormwind
				["512:749"] = 0, -- Darkshire
			},
			faction="A",
			tag="433:930",
		},

		{
			name = "Chillwind Camp",
			neighbors = {
				["478:299"] = 0, -- Southshore
				["507:488"] = 0, -- Ironforge
				["546:253"] = 0, -- Aerie Peak
				["699:162"] = 0, -- Light's Hope Chapel
			},
			tag="520:224",
		},

		{
			name = "Darkshire",
			neighbors = {
				["407:754"] = 0, -- Sentinel Hill
				["432:672"] = 0, -- Stormwind
				["433:930"] = 0, -- Booty Bay
				["557:699"] = 0, -- Lakeshire
				["612:776"] = 0, -- Nethergarde Keep
			},
			tag="512:749",
		},

		{
			name = "Flame Crest",
			neighbors = {
				["505:567"] = 0, -- Thorium Point
				["554:571"] = 0, -- Kargath
				["605:746"] = 0, -- Stonard
			},
			tag="555:611",
		},

		{
			name = "Grom'gol",
			neighbors = {
				["431:929"] = 0, -- Booty Bay
				["554:571"] = 0, -- Kargath
				["605:746"] = 0, -- Stonard
			},
			tag="448:836",
		},

		{
			name = "Hammerfall",
			neighbors = {
				["442:194"] = 0, -- Undercity
				["494:266"] = 0, -- Tarren Mill
				["554:571"] = 0, -- Kargath
				["671:296"] = 0, -- Revantusk Village
			},
			tag="615:308",
		},

		{
			name = "Ironforge",
			neighbors = {
				["432:672"] = 0, -- Stormwind
				["478:299"] = 0, -- Southshore
				["490:440"] = 0, -- Menethil Harbor
				["508:567"] = 0, -- Thorium Point
				["520:224"] = 0, -- Chillwind Camp
				["546:253"] = 0, -- Aerie Peak
				["570:323"] = 0, -- Refuge Pointe
				["589:515"] = 0, -- Thelsamar
				["699:162"] = 0, -- Light's Hope Chapel
			},
			tag="507:488",
		},

		{
			name = "Kargath",
			neighbors = {
				["431:929"] = 0, -- Booty Bay
				["442:194"] = 0, -- Undercity
				["448:836"] = 0, -- Grom'gol
				["505:567"] = 0, -- Thorium Point
				["555:611"] = 0, -- Flame Crest
				["605:746"] = 0, -- Stonard
				["615:308"] = 0, -- Hammerfall
			},
			tag="554:571",
		},

		{
			name = "Lakeshire",
			neighbors = {
				["407:754"] = 0, -- Sentinel Hill
				["432:672"] = 0, -- Stormwind
				["512:749"] = 0, -- Darkshire
				["580:650"] = 0, -- Morgan's Vigil
			},
			tag="557:699",
		},

		{
			name = "Light's Hope Chapel",
			neighbors = {
				["507:488"] = 0, -- Ironforge
				["520:224"] = 0, -- Chillwind Camp
				["546:253"] = 0, -- Aerie Peak
			},
			faction="A",
			tag="699:162",
		},

		{
			name = "Light's Hope Chapel",
			neighbors = {
				["442:194"] = 0, -- Undercity
				["671:296"] = 0, -- Revantusk Village
			},
			faction="H",
			tag="697:160",
		},

		{
			name = "Menethil Harbor",
			neighbors = {
				["478:299"] = 0, -- Southshore
				["507:488"] = 0, -- Ironforge
				["570:323"] = 0, -- Refuge Pointe
				["589:515"] = 0, -- Thelsamar
			},
			tag="490:440",
		},

		{
			name = "Morgan's Vigil",
			neighbors = {
				["432:672"] = 0, -- Stormwind
				["508:567"] = 0, -- Thorium Point
				["557:699"] = 0, -- Lakeshire
				["612:776"] = 0, -- Nethergarde Keep
			},
			tag="580:650",
		},

		{
			name = "Nethergarde Keep",
			neighbors = {
				["432:672"] = 0, -- Stormwind
				["512:749"] = 0, -- Darkshire
				["580:650"] = 0, -- Morgan's Vigil
			},
			tag="612:776",
		},

		{
			name = "Refuge Pointe",
			neighbors = {
				["478:299"] = 0, -- Southshore
				["490:440"] = 0, -- Menethil Harbor
				["507:488"] = 0, -- Ironforge
				["546:253"] = 0, -- Aerie Peak
				["589:515"] = 0, -- Thelsamar
			},
			tag="570:323",
		},

		{
			name = "Revantusk Village",
			neighbors = {
				["442:194"] = 0, -- Undercity
				["494:266"] = 0, -- Tarren Mill
				["615:308"] = 0, -- Hammerfall
				["697:160"] = 0, -- Light's Hope Chapel
			},
			tag="671:296",
		},

		{
			name = "Sentinel Hill",
			neighbors = {
				["432:672"] = 0, -- Stormwind
				["433:930"] = 0, -- Booty Bay
				["512:749"] = 0, -- Darkshire
				["557:699"] = 0, -- Lakeshire
			},
			tag="407:754",
		},

		{
			name = "Southshore",
			neighbors = {
				["490:440"] = 0, -- Menethil Harbor
				["507:488"] = 0, -- Ironforge
				["520:224"] = 0, -- Chillwind Camp
				["546:253"] = 0, -- Aerie Peak
				["570:323"] = 0, -- Refuge Pointe
			},
			tag="478:299",
		},

		{
			name = "Stonard",
			neighbors = {
				["431:929"] = 0, -- Booty Bay
				["448:836"] = 0, -- Grom'gol
				["554:571"] = 0, -- Kargath
				["555:611"] = 0, -- Flame Crest
			},
			tag="605:746",
		},

		{
			name = "Stormwind",
			neighbors = {
				["407:754"] = 0, -- Sentinel Hill
				["433:930"] = 0, -- Booty Bay
				["507:488"] = 0, -- Ironforge
				["512:749"] = 0, -- Darkshire
				["557:699"] = 0, -- Lakeshire
				["580:650"] = 0, -- Morgan's Vigil
				["612:776"] = 0, -- Nethergarde Keep
			},
			tag="432:672",
		},

		{
			name = "Tarren Mill",
			neighbors = {
				["384:244"] = 0, -- The Sepulcher
				["442:194"] = 0, -- Undercity
				["615:308"] = 0, -- Hammerfall
				["671:296"] = 0, -- Revantusk Village
			},
			tag="494:266",
		},

		{
			name = "The Sepulcher",
			neighbors = {
				["442:194"] = 0, -- Undercity
				["494:266"] = 0, -- Tarren Mill
			},
			tag="384:244",
		},

		{
			name = "Thelsamar",
			neighbors = {
				["490:440"] = 0, -- Menethil Harbor
				["507:488"] = 0, -- Ironforge
				["570:323"] = 0, -- Refuge Pointe
			},
			tag="589:515",
		},

		{
			name = "Thorium Point",
			neighbors = {
				["554:571"] = 0, -- Kargath
				["555:611"] = 0, -- Flame Crest
			},
			faction="H",
			tag="505:567",
		},

		{
			name = "Thorium Point",
			neighbors = {
				["507:488"] = 0, -- Ironforge
				["580:650"] = 0, -- Morgan's Vigil
			},
			faction="A",
			tag="508:567",
		},

		{
			name = "Undercity",
			neighbors = {
				["384:244"] = 0, -- The Sepulcher
				["494:266"] = 0, -- Tarren Mill
				["554:571"] = 0, -- Kargath
				["615:308"] = 0, -- Hammerfall
				["671:296"] = 0, -- Revantusk Village
				["697:160"] = 0, -- Light's Hope Chapel
			},
			tag="442:194",
		},
	},
}
