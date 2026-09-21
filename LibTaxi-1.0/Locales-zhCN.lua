-- LibTaxi-1.0 / zhCN
--
-- Flight point names from a VMaNGOS 1.12 world database (locales_taxi_node), the only
-- source for this locale; the zone suffix after the full-width comma is dropped.
-- Reduced to the vanilla flight points; everything TBC and later is dropped.  `true` means
-- the name is the same as the English one in this locale.
--
-- The file only stores its tables; LibTaxi-1.0.lua picks the client's locale out of
-- LibTaxi_Locales and then clears the global. It carries no dependency of its own -- not even
-- GetLocale -- because the 1.12.1 loader may run a locale file ahead of every other script of
-- the including XML (LibItemBonusLib-1.0 README deviation 15).

LibTaxi_Locales = LibTaxi_Locales or {}
LibTaxi_Locales.zhCN = {
	TAXINAMES = {
		-- flight points
		["Aerie Peak"] = "鹰巢山",
		["Astranaar"] = "阿斯特兰纳",
		["Auberdine"] = "奥伯丁",
		["Bloodvenom Post"] = "血毒河",
		["Booty Bay"] = "藏宝海湾",
		["Brackenwall Village"] = "蕨墙村",
		["Camp Mojache"] = "莫沙彻营地",
		["Camp Taurajo"] = "陶拉祖营地",
		["Cenarion Hold"] = "塞纳里奥要塞",
		["Chillwind Camp"] = "冰风岗",
		["Crossroads"] = "十字路口",
		["Darkshire"] = "夜色镇",
		["Everlook"] = "永望镇",
		["Feathermoon"] = "羽月要塞",
		["Flame Crest"] = "烈焰峰",
		["Freewind Post"] = "乱风岗",
		["Gadgetzan"] = "加基森",
		["Grom'gol"] = "格罗姆高",
		["Hammerfall"] = "落锤镇",
		["Ironforge"] = "铁炉堡",
		["Kargath"] = "卡加斯",
		["Lakeshire"] = "湖畔镇",
		["Light's Hope Chapel"] = "圣光之愿礼拜堂",
		["Marshal's Refuge"] = "马绍尔营地",
		["Menethil Harbor"] = "米奈希尔港",
		["Moonglade"] = "月光林地",
		["Morgan's Vigil"] = "摩根的岗哨",
		["Nethergarde Keep"] = "守望堡",
		["Nijel's Point"] = "尼耶尔前哨站",
		["Orgrimmar"] = "奥格瑞玛",
		["Ratchet"] = "棘齿城",
		["Refuge Pointe"] = "避难谷地",
		["Revantusk Village"] = "恶齿村",
		["Rut'theran Village"] = "鲁瑟兰村",
		["Sentinel Hill"] = "哨兵岭",
		["Shadowprey Village"] = "葬影村",
		["Southshore"] = "南海镇",
		["Splintertree Post"] = "碎木岗哨",
		["Stonard"] = "斯通纳德",
		["Stonetalon Peak"] = "石爪峰",
		["Stormwind"] = "暴风城",
		["Sun Rock Retreat"] = "烈日石居",
		["Talonbranch Glade"] = "刺枝林地",
		["Talrendis Point"] = "塔伦迪斯营地",
		["Tarren Mill"] = "塔伦米尔",
		["Thalanaar"] = "萨兰纳尔",
		["The Sepulcher"] = "瑟伯切尔",
		["Thelsamar"] = "塞尔萨玛",
		["Theramore"] = "塞拉摩",
		["Thorium Point"] = "瑟银哨塔",
		["Thunder Bluff"] = "雷霆崖",
		["Undercity"] = "幽暗城",
		["Valormok"] = "瓦罗莫克",
		["Zoram'gar Outpost"] = "佐拉姆加前哨站",
		-- minimap subzones
		["Trade District"] = true,
		["The Great Forge"] = true,
		["Valley of Strength"] = true,
	},
	-- flight masters, by creature id
	NPCNAMES = {
		[352] = "杜加尔·朗德瑞克",  -- Stormwind
		[523] = "索尔",  -- Sentinel Hill
		[931] = "艾蕾娜·斯托姆法瑟",  -- Lakeshire
		[1387] = "塞斯塔",  -- Grom'gol
		[1571] = "谢尔雷·布隆迪尔",  -- Menethil Harbor
		[1572] = "索格拉姆·伯雷森",  -- Thelsamar
		[1573] = "格莱斯·瑟登",  -- Ironforge
		[2226] = "卡洛斯·拉佐克",  -- The Sepulcher
		[2299] = "博古斯·粗臂",  -- Morgan's Vigil
		[2389] = "扎瑞斯",  -- Tarren Mill
		[2409] = "菲利希亚·玛林",  -- Darkshire
		[2432] = "达尔拉·哈瑞斯",  -- Southshore
		[2835] = "瑟迪克·普罗斯",  -- Refuge Pointe
		[2851] = "尤尔达",  -- Hammerfall
		[2858] = "格林戈",  -- Booty Bay
		[2859] = "盖尔",  -- Booty Bay
		[2861] = "格里克",  -- Kargath
		[2941] = "兰尼·瑞德",  -- Thorium Point
		[2995] = "塔尔",  -- Thunder Bluff
		[3305] = "格瑞沙",  -- Thorium Point
		[3310] = "多拉斯",  -- Orgrimmar
		[3615] = "迪弗拉克",  -- Crossroads
		[3838] = "维斯派塔斯",  -- Rut'theran Village
		[3841] = "凯莱斯·月羽",  -- Auberdine
		[4267] = "黛琳希亚",  -- Astranaar
		[4312] = "萨尔姆",  -- Sun Rock Retreat
		[4314] = "格卡斯",  -- Revantusk Village
		[4317] = "奈瑟",  -- Freewind Post
		[4319] = "赛希亚娜",  -- Thalanaar
		[4321] = "巴德拉克",  -- Theramore
		[4407] = "泰罗伦",  -- Stonetalon Peak
		[4551] = "迈克尔·加勒特",  -- Undercity
		[6026] = "布雷依克",  -- Stonard
		[6706] = "巴瑞特·克罗斯",  -- Nijel's Point
		[6726] = "萨隆",  -- Shadowprey Village
		[7823] = "博拉·石锤",  -- Gadgetzan
		[7824] = "布科雷克·怒拳",  -- Gadgetzan
		[8018] = "戈斯鲁姆",  -- Aerie Peak
		[8019] = "菲尔迪恩·月羽",  -- Feathermoon
		[8020] = "夏恩",  -- Camp Mojache
		[8609] = "亚莉珊德拉·康斯坦丁",  -- Nethergarde Keep
		[8610] = "克隆姆",  -- Valormok
		[10378] = "欧姆萨·雷角",  -- Camp Taurajo
		[10583] = "格莱菲",  -- Marshal's Refuge
		[10897] = "辛德拉尔",  -- Moonglade
		[11138] = "麦瑟蕾亚",  -- Everlook
		[11139] = "尤格雷克",  -- Everlook
		[11899] = "沙尔迪",  -- Brackenwall Village
		[11900] = "布拉卡尔",  -- Bloodvenom Post
		[11901] = "安德鲁克",  -- Zoram'gar Outpost
		[12577] = "加罗迪努斯",  -- Talrendis Point
		[12578] = "米萨琳娜",  -- Talonbranch Glade
		[12596] = "比比尔法兹",  -- Chillwind Camp
		[12616] = "乌尔格拉",  -- Splintertree Post
		[12617] = "凯琳·斯蒂文",  -- Light's Hope Chapel
		[12636] = "乔吉亚",  -- Light's Hope Chapel
		[12740] = "法斯托恩",  -- Moonglade
		[13177] = "瓦格鲁克",  -- Flame Crest
		[15177] = "克劳德·天舞者",  -- Cenarion Hold
		[15178] = "鲁克·驯风者",  -- Cenarion Hold
		[16227] = "布拉高克",  -- Ratchet
	},
}
