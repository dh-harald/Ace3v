-- LibTaxi-1.0 / ruRU
--
-- Flight master names from a VMaNGOS 1.12 world database (locales_creature).  Vanilla's
-- TaxiNodes.dbc has no Russian column at all, so the flight point names below are the Russian AREA
-- names of the places those points stand in (locales_area, whose ruRU column the server projects
-- added later) -- each one located through the German, French, Spanish or Chinese name already
-- known for that point, and taken only where two of those agree.
-- Reduced to the vanilla flight points; everything TBC and later is dropped.  `true` means
-- the name is the same as the English one in this locale.
--
-- The file only stores its tables; LibTaxi-1.0.lua picks the client's locale out of
-- LibTaxi_Locales and then clears the global. It carries no dependency of its own -- not even
-- GetLocale -- because the 1.12.1 loader may run a locale file ahead of every other script of
-- the including XML (LibItemBonusLib-1.0 README deviation 15).

LibTaxi_Locales = LibTaxi_Locales or {}
LibTaxi_Locales.ruRU = {
	TAXINAMES = {
		-- flight points
		["Aerie Peak"] = "Заоблачный пик",
		["Astranaar"] = "Астранаар",
		["Auberdine"] = "Аубердин",
		["Bloodvenom Post"] = "Застава Отравленной Крови",
		["Booty Bay"] = "Пиратская Бухта",
		["Brackenwall Village"] = "Деревня Гиблотопь",
		["Camp Mojache"] = "Лагерь Мохаче",
		["Camp Taurajo"] = "Лагерь Таурахо",
		["Cenarion Hold"] = "Крепость Кенария",
		["Chillwind Camp"] = "Лагерь Промозглого Ветра",
		["Crossroads"] = "Перекресток",
		["Darkshire"] = "Темнолесье",
		["Everlook"] = "Круговзор",
		["Feathermoon"] = "Крепость Оперенной Луны",
		["Flame Crest"] = "Пламенеющий Стяг",
		["Freewind Post"] = "Застава Вольного Ветра",
		["Gadgetzan"] = "Прибамбасск",
		["Grom'gol"] = true,
		["Hammerfall"] = "Павший Молот",
		["Ironforge"] = "Стальгорн",
		["Kargath"] = "Каргат",
		["Lakeshire"] = "Приозерье",
		["Light's Hope Chapel"] = "Часовня Последней Надежды",
		["Marshal's Refuge"] = "Укрытие Маршалла",
		["Menethil Harbor"] = "Гавань Менетилов",
		["Moonglade"] = "Лунная поляна",
		["Morgan's Vigil"] = "Дозор Моргана",
		["Nethergarde Keep"] = "Крепость Стражей Пустоты",
		["Nijel's Point"] = "Высота Найджела",
		["Orgrimmar"] = "Оргриммар",
		["Ratchet"] = "Кабестан",
		["Refuge Pointe"] = "Опорный пункт",
		["Revantusk Village"] = "Деревня Сломанного Клыка",
		["Rut'theran Village"] = "Деревня Рут'теран",
		["Sentinel Hill"] = "Сторожевой холм",
		["Shadowprey Village"] = "Деревня Ночных Охотников",
		["Southshore"] = "Южнобережье",
		["Splintertree Post"] = "Застава Расщепленного Дерева",
		["Stonard"] = "Каменор",
		["Stonetalon Peak"] = "Пик Каменного Когтя",
		["Stormwind"] = "Штормград",
		["Sun Rock Retreat"] = "Приют у Солнечного Камня",
		["Talonbranch Glade"] = "Поляна Когтистых Ветвей",
		["Talrendis Point"] = "Застава Талрендис",
		["Tarren Mill"] = "Мельница Таррен",
		["Thalanaar"] = "Таланаар",
		["The Sepulcher"] = "Гробница",
		["Thelsamar"] = "Телcамар",
		["Theramore"] = true,
		["Thorium Point"] = "Лагерь Братства Тория",
		["Thunder Bluff"] = "Громовой Утес",
		["Undercity"] = "Подгород",
		["Valormok"] = "Храбростан",
		["Zoram'gar Outpost"] = "Форт Зорам'гар",
		-- minimap subzones
		["Trade District"] = true,
		["The Great Forge"] = true,
		["Valley of Strength"] = true,
	},
	-- flight masters, by creature id
	NPCNAMES = {
		[352] = "Дунгар Долгопив",  -- Stormwind
		[523] = "Тор",  -- Sentinel Hill
		[931] = "Ариена Штормокрылая",  -- Lakeshire
		[1387] = "Тиста",  -- Grom'gol
		[1571] = "Шелли Брондир",  -- Menethil Harbor
		[1572] = "Торгрум Боррелсон",  -- Thelsamar
		[1573] = "Грит Турден",  -- Ironforge
		[2226] = "Карос Раззок",  -- The Sepulcher
		[2299] = "Боргус Крепкорук",  -- Morgan's Vigil
		[2389] = "Зарисса",  -- Tarren Mill
		[2409] = "Фелисия Мелайн",  -- Darkshire
		[2432] = "Дарла Гаррис",  -- Southshore
		[2835] = "Седрик Проуз",  -- Refuge Pointe
		[2851] = "Урда",  -- Hammerfall
		[2858] = "Грингер",  -- Booty Bay
		[2859] = "Гилл",  -- Booty Bay
		[2861] = "Горрик",  -- Kargath
		[2941] = "Лани Камышинка",  -- Thorium Point
		[2995] = "Тал",  -- Thunder Bluff
		[3305] = "Гриха",  -- Thorium Point
		[3310] = "Дорас",  -- Orgrimmar
		[3615] = "Деврак",  -- Crossroads
		[3838] = "Весприст",  -- Rut'theran Village
		[3841] = "Кайлаис Лунное Перо",  -- Auberdine
		[4267] = "Делишия",  -- Astranaar
		[4312] = "Тарм",  -- Sun Rock Retreat
		[4314] = "Горкас",  -- Revantusk Village
		[4317] = "Нице",  -- Freewind Post
		[4319] = "Тиссиана",  -- Thalanaar
		[4321] = "Балдрик",  -- Theramore
		[4407] = "Телорен",  -- Stonetalon Peak
		[4551] = "Майкл Гарретт",  -- Undercity
		[6026] = "Брейк",  -- Stonard
		[6706] = "Баританес Небесная Река",  -- Nijel's Point
		[6726] = "Фалон",  -- Shadowprey Village
		[7823] = "Бера Камнемолот",  -- Gadgetzan
		[7824] = "Булкрек Десница Гнева",  -- Gadgetzan
		[8018] = "Гутрум Громодлань",  -- Aerie Peak
		[8019] = "Филдрен Лунное Перо",  -- Feathermoon
		[8020] = "Шин",  -- Camp Mojache
		[8609] = "Александра Константин",  -- Nethergarde Keep
		[8610] = "Кроум",  -- Valormok
		[10378] = "Омуса Громовой Рог",  -- Camp Taurajo
		[10583] = "Грайф",  -- Marshal's Refuge
		[10897] = "Синдрайл",  -- Moonglade
		[11138] = "Маетрия",  -- Everlook
		[11139] = "Югрек",  -- Everlook
		[11899] = "Щербушка",  -- Brackenwall Village
		[11900] = "Браккар",  -- Bloodvenom Post
		[11901] = "Андрук",  -- Zoram'gar Outpost
		[12577] = "Джарроден",  -- Talrendis Point
		[12578] = "Мишеллена",  -- Talonbranch Glade
		[12596] = "Бибильфас Перосвист",  -- Chillwind Camp
		[12616] = "Вульгра",  -- Splintertree Post
		[12617] = "Хелин Сталекрылая",  -- Light's Hope Chapel
		[12636] = "Георгия",  -- Light's Hope Chapel
		[12740] = "Фаустрон",  -- Moonglade
		[13177] = "Вагрук",  -- Flame Crest
		[15177] = "Клод Небесный Танец",  -- Cenarion Hold
		[15178] = "Рунк Покоритель Ветров",  -- Cenarion Hold
		[16227] = "Брагок",  -- Ratchet
	},
}
