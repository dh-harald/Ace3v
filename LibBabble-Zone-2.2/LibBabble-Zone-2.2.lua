--[[
Name: LibBabble-Zone-2.2
Revision: $Rev: 1 $
Ported from: Babble-Zone-2.2 r17779
Author(s): ckknight (ckknight@gmail.com), Ace3v port
Website: http://ckknight.wowinterface.com/
Documentation: http://wiki.wowace.com/index.php/Babble-Zone-2.2
SVN: http://svn.wowace.com/root/trunk/Babble-2.2/Babble-Zone-2.2
Description: A library to provide localizations for zones.
Dependencies: LibStub, AceLocale-3.0
Note: Ace3v port of Babble-Zone-2.2, API-compatible. The Ace2 original was an
      AceLocale-2.2 instance registered into AceLibrary; this is a plain LibStub
      library that reproduces the instance API on top of AceLocale-3.0.
]]

local MAJOR_VERSION, MINOR_VERSION = "LibBabble-Zone-2.2", 2

local BabbleZone = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)

if not BabbleZone then return end -- No upgrade needed

local AceLocale = LibStub("AceLocale-3.0")

-- Ace3v: the original listed ["Battlegrounds"] twice, with the same value.

local L = AceLocale:NewLocale(MAJOR_VERSION, "enUS", true, true)
if L then
	L["Battlegrounds"] = true
	L["The Black Morass"] = true
	L["Dalaran"] = true
	L["Ahn'Qiraj"] = true
	L["Alterac Mountains"] = true
	L["Alterac Valley"] = true
	L["Arathi Basin"] = true
	L["Arathi Highlands"] = true
	L["Ashenvale"] = true
	L["Auberdine"] = true
	L["Azshara"] = true
	L["Badlands"] = true
	L["The Barrens"] = true
	L["Blackfathom Deeps"] = true
	L["Blackrock Depths"] = true
	L["Blackrock Mountain"] = true
	L["Blackrock Spire"] = true
	L["Blackwing Lair"] = true
	L["Blasted Lands"] = true
	L["Booty Bay"] = true
	L["Burning Steppes"] = true
	L["Darkshore"] = true
	L["Darnassus"] = true
	L["The Deadmines"] = true
	L["Deadwind Pass"] = true
	L["Deeprun Tram"] = true
	L["Desolace"] = true
	L["Dire Maul"] = true
	L["Dire Maul (East)"] = true
	L["Dire Maul (West)"] = true
	L["Dire Maul (North)"] = true
	L["Dun Morogh"] = true
	L["Durotar"] = true
	L["Duskwood"] = true
	L["Dustwallow Marsh"] = true
	L["Eastern Kingdoms"] = true
	L["Eastern Plaguelands"] = true
	L["Elwynn Forest"] = true
	L["Everlook"] = true
	L["Felwood"] = true
	L["Feralas"] = true
	L["The Forbidding Sea"] = true
	L["Gadgetzan"] = true
	L["Gates of Ahn'Qiraj"] = true
	L["Gnomeregan"] = true
	L["The Great Sea"] = true
	L["Grom'gol Base Camp"] = true
	L["Hall of Legends"] = true
	L["Hillsbrad Foothills"] = true
	L["The Hinterlands"] = true
	L["Hyjal"] = true
	L["Ironforge"] = true
	L["Kalimdor"] = true
	L["Loch Modan"] = true
	L["Lower Blackrock Spire"] = true
	L["Maraudon"] = true
	L["Menethil Harbor"] = true
	L["Molten Core"] = true
	L["Moonglade"] = true
	L["Mulgore"] = true
	L["Naxxramas"] = true
	L["Onyxia's Lair"] = true
	L["Orgrimmar"] = true
	L["Ratchet"] = true
	L["Ragefire Chasm"] = true
	L["Razorfen Downs"] = true
	L["Razorfen Kraul"] = true
	L["Redridge Mountains"] = true
	L["Ruins of Ahn'Qiraj"] = true
	L["Scarlet Monastery"] = true
	L["Scarlet Monastery (Armory)"] = true
	L["Scarlet Monastery (Cathedral)"] = true
	L["Scarlet Monastery (Graveyard)"] = true
	L["Scarlet Monastery (Library)"] = true
	L["Scholomance"] = true
	L["Searing Gorge"] = true
	L["Shadowfang Keep"] = true
	L["Silithus"] = true
	L["Silverpine Forest"] = true
	L["The Stockade"] = true
	L["Stonetalon Mountains"] = true
	L["Stormwind City"] = true
	L["Stranglethorn Vale"] = true
	L["Stratholme"] = true
	L["Swamp of Sorrows"] = true
	L["Tanaris"] = true
	L["Teldrassil"] = true
	L["Temple of Ahn'Qiraj"] = true
	L["The Temple of Atal'Hakkar"] = true
	L["The Sunken Temple"] = true
	L["Theramore Isle"] = true
	L["Thousand Needles"] = true
	L["Thunder Bluff"] = true
	L["Tirisfal Glades"] = true
	L["Uldaman"] = true
	L["Un'Goro Crater"] = true
	L["Undercity"] = true
	L["Upper Blackrock Spire"] = true
	L["Wailing Caverns"] = true
	L["Warsong Gulch"] = true
	L["Western Plaguelands"] = true
	L["Westfall"] = true
	L["Wetlands"] = true
	L["Winterspring"] = true
	L["Zul'Farrak"] = true
	L["Zul'Gurub"] = true
end

L = AceLocale:NewLocale(MAJOR_VERSION, "esES", nil, true)
if L then
	L["Ahn'Qiraj"] = "Ahn'Qiraj"
	L["Alterac Mountains"] = "Montañas de Alterac"
	L["Alterac Valley"] = "Valle de Alterac"
	L["Arathi Basin"] = "Cuenca de Arathi"
	L["Arathi Highlands"] = "Tierras Altas de Arathi"
	L["Ashenvale"] = "Vallefresno"
	L["Auberdine"] = "Auberdine"
	L["Azshara"] = "Azshara"
	L["Badlands"] = "Tierras Inhóspitas"
	L["The Barrens"] = "Los Baldíos"
	L["Blackfathom Deeps"] = "Cavernas de Brazanegra"
	L["Blackrock Depths"] = "Profundidades de Roca Negra"
	L["Blackrock Mountain"] = "Montaña Roca Negra"
	L["Blackrock Spire"] = "Cumbre de Roca Negra"
	L["Blackwing Lair"] = "Guarida de Alanegra"
	L["Blasted Lands"] = "Las Tierras Devastadas"
	L["Booty Bay"] = "Bahía del Botín"
	L["Burning Steppes"] = "Las Estepas Ardientes"
	L["Darkshore"] = "Costa Oscura"
	L["Darnassus"] = "Darnassus"
	L["The Deadmines"] = "Las Minas de la Muerte"
	L["Deadwind Pass"] = "Paso de la Muerte"
	L["Deeprun Tram"] = "Tren Subterráneo"
	L["Desolace"] = "Desolace"
	L["Dire Maul"] = "La Masacre"
	L["Dire Maul (North)"] = "La Masacre (Norte)"
	L["Dire Maul (East)"] = "La Masacre (Este)"
	L["Dire Maul (West)"] = "La Masacre (Oeste)"
	L["Dun Morogh"] = "Dun Morogh"
	L["Durotar"] = "Durotar"
	L["Duskwood"] = "Bosque del Ocaso"
	L["Dustwallow Marsh"] = "Marjal Revolcafango"
	L["Eastern Kingdoms"] = "Reinos del Este"
	L["Eastern Plaguelands"] = "Tierras de la Peste del Este"
	L["Elwynn Forest"] = "Bosque de Elwynn"
	L["Everlook"] = "Vista Eterna"
	L["Felwood"] = "Frondavil"
	L["Feralas"] = "Feralas"
	L["The Forbidding Sea"] = "Mar Adusto"
	L["Gadgetzan"] = "Gadgetzan"
	L["Gates of Ahn'Qiraj"] = "Portones de Ahn'Qiraj"
	L["Gnomeregan"] = "Gnomeregan"
	L["Grom'gol Base Camp"] = "Campamento Grom'gol"
	L["The Great Sea"] = "Mare Magnum"
	L["Hall of Legends"] = "Sala de las Leyendas"
	L["Hillsbrad Foothills"] = "Laderas de Trabalomas"
	L["The Hinterlands"] = "Tierras del Interior"
	L["Hyjal"] = "Hyjal"
	L["Ironforge"] = "Forjaz"
	L["Loch Modan"] = "Loch Modan"
	L["Lower Blackrock Spire"] = "Cumbre de Roca Negra Inferior"
	L["Maraudon"] = "Maraudon"
	L["Menethil Harbor"] = "Puerto Menethil"
	L["Molten Core"] = "Núcleo de Magma"
	L["Moonglade"] = "Claro de la Luna"
	L["Mulgore"] = "Mulgore"
	L["Naxxramas"] = "Naxxramas"
	L["Onyxia's Lair"] = "Guarida de Onyxia"
	L["Orgrimmar"] = "Orgrimmar"
	L["Ratchet"] = "Trinquete"
	L["Ragefire Chasm"] = "Sima Ígnea"
	L["Razorfen Downs"] = "Zahúrda Rojocieno"
	L["Razorfen Kraul"] = "Horado Rajacieno"
	L["Redridge Mountains"] = "Montañas Crestagrana"
	L["Ruins of Ahn'Qiraj"] = "Ruinas de Ahn'Qiraj"
	L["Scarlet Monastery"] = "Monasterio Escarleta"
	L["Scholomance"] = "Scholomance"
	L["Searing Gorge"] = "La Garganta de Fuego"
	L["Shadowfang Keep"] = "Castillo de Colmillo Oscuro"
	L["Silithus"] = "Silithus"
	L["Silverpine Forest"] = "Bosque de Argénteos"
	L["The Stockade"] = "Las Mazmorras"
	L["Stonetalon Mountains"] = "Sierra Espolón"
	L["Stormwind City"] = "Ciudad de Ventormenta"
	L["Stranglethorn Vale"] = "Vega de Tuercespina"
	L["Stratholme"] = "Stratholme"
	L["Swamp of Sorrows"] = "Pantano de las Penas"
	L["Tanaris"] = "Tanaris"
	L["Teldrassil"] = "Teldrassil"
	L["Temple of Ahn'Qiraj"] = "Templo de Ahn'Qiraj"
	L["The Temple of Atal'Hakkar"] = "El Templo de Atal'Hakkar"
	L["Theramore Isle"] = "Isla Theramore"
	L["Thousand Needles"] = "Las Mil Agujas"
	L["Thunder Bluff"] = "Cima del Trueno"
	L["Tirisfal Glades"] = "Claros de Tirisfal"
	L["Uldaman"] = "Uldaman"
	L["Un'Goro Crater"] = "Cráter de Un'Goro"
	L["Undercity"] = "Entrañas"
	L["Upper Blackrock Spire"] = "Cumbre de Roca Negra Superior"
	L["Wailing Caverns"] = "Cuevas de los Lamentos"
	L["Warsong Gulch"] = "Garganta Grito de Guerra"
	L["Western Plaguelands"] = "Tierras de la Peste del Oeste"
	L["Westfall"] = "Páramos de Poniente"
	L["Wetlands"] = "Los Humedales"
	L["Winterspring"] = "Cuna del Invierno"
	L["Zul'Farrak"] = "Zul'Farrak"
	L["Zul'Gurub"] = "Zul'Gurub"
end

L = AceLocale:NewLocale(MAJOR_VERSION, "ruRU", nil, true)
if L then
	L["Ahn'Qiraj"] = "Ан'Кираж"
	L["Alterac Mountains"] = "Альтеракские горы"
	L["Alterac Valley"] = "Альтеракская долина"
	L["Arathi Basin"] = "Низина Арати"
	L["Arathi Highlands"] = "Нагорье Арати"
	L["Ashenvale"] = "Ясеневый лес"
	L["Auberdine"] = "Аубердин"
	L["Azshara"] = "Азшара"
	L["Badlands"] = "Бесплодные земли"
	L["The Barrens"] = "Степи"
	L["Blackfathom Deeps"] = "Непроглядная Пучина"
	L["Blackrock Depths"] = "Глубины Черной горы"
	L["Blackrock Mountain"] = "Черная гора"
	L["Blackrock Spire"] = "Пик Черной горы"
	L["Blackwing Lair"] = "Логово Крыла Тьмы"
	L["Blasted Lands"] = "Выжженные земли"
	L["Booty Bay"] = "Пиратская Бухта"
	L["Burning Steppes"] = "Пылающие степи"
	L["Darkshore"] = "Темные берега"
	L["Darnassus"] = "Дарнас"
	L["The Deadmines"] = "Мертвые копи"
	L["Deadwind Pass"] = "Перевал Мертвого Ветра"
	L["Deeprun Tram"] = "Подземный поезд"
	L["Desolace"] = "Пустоши"
	L["Dire Maul"] = "Забытый Город"
	L["Dire Maul (East)"] = "Забытый город (Восток)"
	L["Dire Maul (West)"] = "Забытый город (Запад)"
	L["Dire Maul (North)"] = "Забытый город (Север)"
	L["Dun Morogh"] = "Дун Морог"
	L["Durotar"] = "Дуротар"
	L["Duskwood"] = "Сумеречный лес"
	L["Dustwallow Marsh"] = "Пылевые топи"
	L["Eastern Kingdoms"] = "Восточные королевства"
	L["Eastern Plaguelands"] = "Восточные Чумные земли"
	L["Elwynn Forest"] = "Элвиннский лес"
	L["Everlook"] = "Круговзор"
	L["Felwood"] = "Оскверненный лес"
	L["Feralas"] = "Фералас"
	L["The Forbidding Sea"] = "Зловещее море"
	L["Gadgetzan"] = "Прибамбасск"
	L["Gates of Ahn'Qiraj"] = "Врата Ан'Киража"
	L["Gnomeregan"] = "Гномреган"
	L["The Great Sea"] = "Великое море"
	L["Grom'gol Base Camp"] = "Лагерь Гром'гол"
	L["Hall of Legends"] = "Зал Легенд"
	L["Hillsbrad Foothills"] = "Предгорья Хилсбрада"
	L["The Hinterlands"] = "Внутренние земли"
	L["Hyjal"] = "Хиджал"
	L["Ironforge"] = "Стальгорн"
	L["Kalimdor"] = "Калимдор"
	L["Loch Modan"] = "Лок Модан"
	L["Lower Blackrock Spire"] = "Низина Черной горы"
	L["Maraudon"] = "Мародон"
	L["Menethil Harbor"] = "Гавань Менетилов"
	L["Molten Core"] = "Огненные Недра"
	L["Moonglade"] = "Лунная поляна"
	L["Mulgore"] = "Мулгор"
	L["Naxxramas"] = "Наксрамас"
	L["Onyxia's Lair"] = "Логово Ониксии"
	L["Orgrimmar"] = "Оргриммар"
	L["Ratchet"] = "Кабестан"
	L["Ragefire Chasm"] = "Огненная Пропасть"
	L["Razorfen Downs"] = "Курганы Иглошкурых"
	L["Razorfen Kraul"] = "Лабиринты Иглошкурых"
	L["Redridge Mountains"] = "Красногорье"
	L["Ruins of Ahn'Qiraj"] = "Руины Ан'Киража"
	L["Scarlet Monastery"] = "Монастырь Алого ордена"
	L["Scholomance"] = "Некроситет"
	L["Searing Gorge"] = "Тлеющее ущелье"
	L["Shadowfang Keep"] = "Крепость Темного Клыка"
	L["Silithus"] = "Силитус"
	L["Silverpine Forest"] = "Серебряный бор"
	L["The Stockade"] = "Тюрьма"
	L["Stonetalon Mountains"] = "Когтистые горы"
	L["Stormwind City"] = "Штормград"
	L["Stranglethorn Vale"] = "Тернистая долина"
	L["Stratholme"] = "Стратхольм"
	L["Swamp of Sorrows"] = "Болото Печали"
	L["Tanaris"] = "Танарис"
	L["Teldrassil"] = "Тельдрассил"
	L["Temple of Ahn'Qiraj"] = "Храм Ан'Кираж"
	L["The Temple of Atal'Hakkar"] = "Храм Атал'Хаккара"
	L["Theramore Isle"] = "Остров Терамор"
	L["Thousand Needles"] = "Тысяча Игл"
	L["Thunder Bluff"] = "Громовой Утес"
	L["Tirisfal Glades"] = "Тирисфальские леса"
	L["Uldaman"] = "Ульдаман"
	L["Un'Goro Crater"] = "Кратер Ун'Горо"
	L["Undercity"] = "Подгород"
	L["Upper Blackrock Spire"] = "Вершина Черной горы"
	L["Wailing Caverns"] = "Пещеры Стенаний"
	L["Warsong Gulch"] = "Ущелье Песни Войны"
	L["Western Plaguelands"] = "Западные Чумные земли"
	L["Westfall"] = "Западный Край"
	L["Wetlands"] = "Болотина"
	L["Winterspring"] = "Зимние Ключи"
	L["Zul'Farrak"] = "Зул'Фаррак"
	L["Zul'Gurub"] = "Зул'Гуруб"
	-- Ace3v: from the localized 1.12 AreaTable.dbc
	L["The Black Morass"] = "Черные топи"
	L["Dalaran"] = "Даларан"
end

L = AceLocale:NewLocale(MAJOR_VERSION, "deDE", nil, true)
if L then
	L["Ahn'Qiraj"] = "Ahn'Qiraj"
	L["Alterac Mountains"] = "Alteracgebirge"
	L["Alterac Valley"] = "Alteractal"
	L["Arathi Basin"] = "Arathibecken"
	L["Arathi Highlands"] = "Arathihochland"
	L["Ashenvale"] = "Ashenvale"
	L["Auberdine"] = "Auberdine"
	L["Azshara"] = "Azshara"
	L["Badlands"] = "\195\150dland"
	L["The Barrens"] = "Brachland"
	L["Blackfathom Deeps"] = "Blackfathom-Tiefe"
	L["Blackrock Depths"] = "Blackrocktiefen"
	L["Blackrock Mountain"] = "Der Blackrock"
	L["Blackrock Spire"] = "Blackrockspitze"
	L["Blackwing Lair"] = "Pechschwingenhort"
	L["Blasted Lands"] = "Verw\195\188stete Lande"
	L["Booty Bay"] = "Booty Bay"
	L["Burning Steppes"] = "Brennende Steppe"
	L["Darkshore"] = "Dunkelk\195\188ste"
	L["Darnassus"] = "Darnassus"
	L["The Deadmines"] = "Die Todesminen"
	L["Deadwind Pass"] = "Gebirgspass der Totenwinde"
	L["Deeprun Tram"] = "Die Tiefenbahn"
	L["Desolace"] = "Desolace"
	L["Dire Maul"] = "D\195\188sterbruch"
	L["Dire Maul (North)"] = "D\195\188sterbruch (Nord)"
	L["Dire Maul (East)"] = "D\195\188sterbruch (Ost)"
	L["Dire Maul (West)"] = "D\195\188sterbruch (West)"
	L["Dun Morogh"] = "Dun Morogh"
	L["Durotar"] = "Durotar"
	L["Duskwood"] = "D\195\164mmerwald"
	L["Dustwallow Marsh"] = "Marschen von Dustwallow"
	L["Eastern Plaguelands"] = "\195\150stliche Pestl\195\164nder"
	L["Elwynn Forest"] = "Wald von Elwynn"
	L["Everlook"] = "Everlook"
	L["Felwood"] = "Teufelswald"
	L["Feralas"] = "Feralas"
	L["The Forbidding Sea"] = "Das verbotene Meer"
	L["Gadgetzan"] = "Gadgetzan"
	L["Gates of Ahn'Qiraj"] = "Tore von Ahn'Qiraj"
	L["Gnomeregan"] = "Gnomeregan"
	L["Grom'gol Base Camp"] = "Das Basislager von Grom'gol"
	L["The Great Sea"] = "Das große Meer"
	L["Hall of Legends"] = "Halle der Legenden"
	L["Hillsbrad Foothills"] = "Vorgebirge von Hillsbrad"
	L["The Hinterlands"] = "Hinterland"
	L["Hyjal"] = "Hyjal"
	L["Ironforge"] = "Ironforge" -- Ace3v: the original took "Eisenschmiede" on any Lua 5.1 client
	L["Loch Modan"] = "Loch Modan"
	L["Lower Blackrock Spire"] = "Untere Blockrockspitze"
	L["Maraudon"] = "Maraudon"
	L["Menethil Harbor"] = "Der Hafen von Menethil"
	L["Molten Core"] = "Geschmolzener Kern"
	L["Moonglade"] = "Moonglade"
	L["Mulgore"] = "Mulgore"
	L["Naxxramas"] = "Naxxramas"
	L["Onyxia's Lair"] = "Onyxias Hort"
	L["Orgrimmar"] = "Orgrimmar"
	L["Ratchet"] = "Ratchet"
	L["Ragefire Chasm"] = "Ragefireabgrund"
	L["Razorfen Downs"] = "Die H\195\188gel von Razorfen"
	L["Razorfen Kraul"] = "Der Kral von Razorfen"
	L["Redridge Mountains"] = "Rotkammgebirge"
	L["Ruins of Ahn'Qiraj"] = "Ruinen von Ahn'Qiraj"
	L["Scarlet Monastery"] = "Das scharlachrote Kloster"
	L["Scholomance"] = "Scholomance"
	L["Searing Gorge"] = "Sengende Schlucht"
	L["Shadowfang Keep"] = "Burg Shadowfang"
	L["Silithus"] = "Silithus"
	L["Silverpine Forest"] = "Silberwald"
	L["The Stockade"] = "Das Verlies"
	L["Stonetalon Mountains"] = "Steinkrallengebirge"
	L["Stormwind City"] = "Stormwind" -- Ace3v: the original took "Sturmwind" on any Lua 5.1 client
	L["Stranglethorn Vale"] = "Schlingendorntal"
	L["Stratholme"] = "Stratholme"
	L["Swamp of Sorrows"] = "S\195\188mpfe des Elends"
	L["Tanaris"] = "Tanaris"
	L["Teldrassil"] = "Teldrassil"
	L["Temple of Ahn'Qiraj"] = "Tempel von Ahn'Qiraj"
	L["The Temple of Atal'Hakkar"] = "Der Tempel von Atal'Hakkar"
	L["Theramore Isle"] = "Die Insel Theramore"
	L["Thousand Needles"] = "Tausend Nadeln"
	L["Thunder Bluff"] = "Thunder Bluff"
	L["Tirisfal Glades"] = "Tirisfal"
	L["Uldaman"] = "Uldaman"
	L["Un'Goro Crater"] = "Un'Goro-Krater"
	L["Undercity"] = "Undercity"
	L["Upper Blackrock Spire"] = "Obere Blackrockspitze"
	L["Wailing Caverns"] = "Die H\195\182hlen des Wehklagens"
	L["Warsong Gulch"] = "Warsongschlucht"
	L["Western Plaguelands"] = "Westliche Pestl\195\164nder"
	L["Westfall"] = "Westfall"
	L["Wetlands"] = "Sumpfland"
	L["Winterspring"] = "Winterspring"
	L["Zul'Farrak"] = "Zul'Farrak"
	L["Zul'Gurub"] = "Zul'Gurub"
	-- Ace3v: from the localized 1.12 AreaTable.dbc
	L["The Black Morass"] = "Das schwarze Fenn"
end

L = AceLocale:NewLocale(MAJOR_VERSION, "frFR", nil, true)
if L then
	L["Ahn'Qiraj"] = "Ahn'Qiraj"
	L["Alterac Mountains"] = "Montagnes d'Alterac"
	L["Alterac Valley"] = "Vall\195\169e d'Alterac"
	L["Arathi Basin"] = "Bassin d'Arathi"
	L["Arathi Highlands"] = "Hautes-terres d'Arathi"
	L["Ashenvale"] = "Ashenvale"
	L["Auberdine"] = "Auberdine"
	L["Azshara"] = "Azshara"
	L["Badlands"] = "Terres ingrates (Badlands)"
	L["The Barrens"] = "Les Tarides (the Barrens)"
	L["Blackfathom Deeps"] = "Profondeurs de Brassenoire"
	L["Blackrock Depths"] = "Profondeurs de Blackrock"
	L["Blackrock Mountain"] = "Mont Blackrock"
	L["Blackrock Spire"] = "Pic Blackrock"
	L["Blackwing Lair"] = "Repaire de l'Aile noire"
	L["Blasted Lands"] = "Terres foudroy\195\169es (Blasted Lands)"
	L["Booty Bay"] = "Baie-du-Butin"
	L["Burning Steppes"] = "Steppes ardentes"
	L["Darkshore"] = "Sombrivage (Darkshore)"
	L["Darnassus"] = "Darnassus"
	L["The Deadmines"] = "Les Mortemines"
	L["Deadwind Pass"] = "D\195\169fil\195\169 de Deuillevent (Deadwind Pass)"
	L["Deeprun Tram"] = "Tram des profondeurs"
	L["Desolace"] = "D\195\169solace"
	L["Dire Maul"] = "Hache-tripes"
	L["Dire Maul (East)"] = "Hache-tripes (Est)"
	L["Dire Maul (West)"] = "Hache-tripes (Ouest)"
	L["Dire Maul (North)"] = "Hache-tripes (Nord)"
	L["Dun Morogh"] = "Dun Morogh"
	L["Durotar"] = "Durotar"
	L["Duskwood"] = "Bois de la P\195\169nombre (Duskwood)"
	L["Dustwallow Marsh"] = "Mar\195\169cage d'\195\130prefange (Dustwallow Marsh)"
	L["Eastern Plaguelands"] = "Maleterres de l'est (Eastern Plaguelands)"
	L["Elwynn Forest"] = "For\195\170t d'Elwynn"
	L["Everlook"] = "Long-guet"
	L["Felwood"] = "Gangrebois (Felwood)"
	L["Feralas"] = "Feralas"
	L["The Forbidding Sea"] = "La Mer interdite"
	L["Gadgetzan"] = "Gadgetzan"
	L["Gates of Ahn'Qiraj"] = "Portes d'Ahn'Qiraj"
	L["Gnomeregan"] = "Gnomeregan"
	L["Grom'gol Base Camp"] = "Campement Grom'gol"
	L["The Great Sea"] = "La Grande mer"
	L["Hall of Legends"] = "Hall des L\195\169gendes"
	L["Hillsbrad Foothills"] = "Contreforts d'Hillsbrad"
	L["The Hinterlands"] = "Les Hinterlands"
	L["Hyjal"] = "Hyjal"
	L["Ironforge"] = "Ironforge"
	L["Loch Modan"] = "Loch Modan"
	L["Lower Blackrock Spire"] = "Pic de Blackrock inf\195\169rieur"
	L["Maraudon"] = "Maraudon"
	L["Menethil Harbor"] = "Port de Menethil"
	L["Molten Core"] = "C\197\147ur du Magma"
	L["Moonglade"] = "Reflet-de-Lune (Moonglade)"
	L["Mulgore"] = "Mulgore"
	L["Onyxia's Lair"] = "Repaire d'Onyxia"
	L["Naxxramas"] = "Naxxramas"
	L["Orgrimmar"] = "Orgrimmar"
	L["Ratchet"] = "Ratchet"
	L["Ragefire Chasm"] = "Gouffre de Ragefeu"
	L["Razorfen Downs"] = "Souilles de Tranchebauge"
	L["Razorfen Kraul"] = "Kraal de Tranchebauge"
	L["Redridge Mountains"] = "Les Carmines (Redridge Mts)"
	L["Ruins of Ahn'Qiraj"] = "Ruines d'Ahn'Qiraj"
	L["Scarlet Monastery"] = "Monast\195\168re \195\169carlate"
	L["Scholomance"] = "Scholomance"
	L["Searing Gorge"] = "Gorge des Vents br\195\187lants (Searing Gorge)"
	L["Shadowfang Keep"] = "Donjon d'Ombrecroc"
	L["Silithus"] = "Silithus"
	L["Silverpine Forest"] = "For\195\170t des Pins argent\195\169s (Silverpine Forest)"
	L["The Stockade"] = "La Prison"
	L["Stonetalon Mountains"] = "Les Serres-Rocheuses (Stonetalon Mts)"
	L["Stormwind City"] = "Cit\195\169 de Stormwind"
	L["Stranglethorn Vale"] = "Vall\195\169e de Strangleronce (Stranglethorn Vale)"
	L["Stratholme"] = "Stratholme"
	L["Swamp of Sorrows"] = "Marais des Chagrins (Swamp of Sorrows)"
	L["Tanaris"] = "Tanaris"
	L["Teldrassil"] = "Teldrassil"
	L["Temple of Ahn'Qiraj"] = "Le temple d'Ahn'Qiraj"
	L["The Temple of Atal'Hakkar"] = "Le temple d'Atal'Hakkar"
	L["Theramore Isle"] = "Ile de Theramore"
	L["Thousand Needles"] = "Mille pointes (Thousand Needles)"
	L["Thunder Bluff"] = "Thunder Bluff"
	L["Tirisfal Glades"] = "Clairi\195\168res de Tirisfal"
	L["Uldaman"] = "Uldaman"
	L["Un'Goro Crater"] = "Crat\195\168re d'Un'Goro"
	L["Undercity"] = "Undercity"
	L["Upper Blackrock Spire"] = "Pic de Blackrock sup\195\169rieur"
	L["Wailing Caverns"] = "Cavernes des lamentations"
	L["Warsong Gulch"] = "Goulet des Warsong"
	L["Western Plaguelands"] = "Maleterres de l'ouest (Western Plaguelands)"
	L["Westfall"] = "Marche de l'Ouest (Westfall)"
	L["Wetlands"] = "Les Paluns (Wetlands)"
	L["Winterspring"] = "Berceau-de-l'Hiver (Winterspring)"
	L["Zul'Farrak"] = "Zul'Farrak"
	L["Zul'Gurub"] = "Zul'Gurub"
	-- Ace3v: from the localized 1.12 AreaTable.dbc
	L["The Black Morass"] = "Le Noir Marécage"
end

L = AceLocale:NewLocale(MAJOR_VERSION, "zhCN", nil, true)
if L then
	L["Ahn'Qiraj"] = "安其拉"
	L["Alterac Mountains"] = "奥特兰克山脉"
	L["Alterac Valley"] = "奥特兰克山谷"
	L["Arathi Basin"] = "阿拉希盆地"
	L["Arathi Highlands"] = "阿拉希高地"
	L["Ashenvale"] = "灰谷"
	L["Auberdine"] = "奥伯丁"
	L["Azshara"] = "艾萨拉"
	L["Badlands"] = "荒芜之地"
	L["The Barrens"] = "贫瘠之地"
	L["Blackfathom Deeps"] = "黑暗深渊"
	L["Blackrock Depths"] = "黑石深渊"
	L["Blackrock Mountain"] = "黑石山"
	L["Blackrock Spire"] = "黑石塔"
	L["Blackwing Lair"] = "黑翼之巢"
	L["Blasted Lands"] = "诅咒之地"
	L["Booty Bay"] = "藏宝海湾"
	L["Burning Steppes"] = "燃烧平原"
	L["Darkshore"] = "黑海岸"
	L["Darnassus"] = "达纳苏斯"
	L["The Deadmines"] = "死亡矿井"
	L["Deadwind Pass"] = "逆风小径"
	L["Deeprun Tram"] = "矿道地铁"
	L["Desolace"] = "凄凉之地"
	L["Dire Maul"] = "厄运之槌"
	L["Dire Maul (East)"] = "厄运之槌(东)"
	L["Dire Maul (West)"] = "厄运之槌(西)"
	L["Dire Maul (North)"] = "厄运之槌(北)"
	L["Dun Morogh"] = "丹莫罗"
	L["Durotar"] = "杜隆塔尔"
	L["Duskwood"] = "暮色森林"
	L["Dustwallow Marsh"] = "尘泥沼泽"
	L["Eastern Plaguelands"] = "东瘟疫之地"
	L["Elwynn Forest"] = "艾尔文森林"
	L["Everlook"] = "永望镇"
	L["Felwood"] = "费伍德森林"
	L["Feralas"] = "菲拉斯"
	L["The Forbidding Sea"] = "禁忌之海"
	L["Gadgetzan"] = "加基森"
	L["Gates of Ahn'Qiraj"] = "安其拉之门"
	L["Gnomeregan"] = "诺莫瑞根"
	L["The Great Sea"] = "无尽之海"
	L["Grom'gol Base Camp"] = "格罗姆高营地"
	L["Hall of Legends"] = "传说大厅"
	L["Hillsbrad Foothills"] = "希尔斯布莱德丘陵"
	L["The Hinterlands"] = "辛特兰"
	L["Hyjal"] = "海加尔山"
	L["Ironforge"] = "铁炉堡"
	L["Loch Modan"] = "洛克莫丹"
	--L["Lower Blackrock Spire"] = true
	L["Maraudon"] = "玛拉顿"
	L["Menethil Harbor"] = "米奈希尔港"
	L["Molten Core"] = "熔火之心"
	L["Moonglade"] = "月光林地"
	L["Mulgore"] = "莫高雷"
	L["Naxxramas"] = "纳克萨玛斯"
	L["Onyxia's Lair"] = "奥妮克希亚的巢穴"
	L["Orgrimmar"] = "奥格瑞玛"
	L["Ratchet"] = "棘齿城"
	L["Ragefire Chasm"] = "怒焰裂谷"
	L["Razorfen Downs"] = "剃刀高地"
	L["Razorfen Kraul"] = "剃刀沼泽"
	L["Redridge Mountains"] = "赤脊山"
	L["Ruins of Ahn'Qiraj"] = "安其拉废墟"
	L["Scarlet Monastery"] = "血色修道院"
	L["Scholomance"] = "通灵学院"
	L["Searing Gorge"] = "灼热峡谷"
	L["Shadowfang Keep"] = "影牙城堡"
	L["Silithus"] = "希利苏斯"
	L["Silverpine Forest"] = "银松森林"
	L["The Stockade"] = "监狱"
	L["Stonetalon Mountains"] = "石爪山脉"
	L["Stormwind City"] = "暴风城"
	L["Stranglethorn Vale"] = "荆棘谷"
	L["Stratholme"] = "斯坦索姆"
	L["Swamp of Sorrows"] = "悲伤沼泽"
	L["Tanaris"] = "塔纳利斯"
	L["Teldrassil"] = "泰达希尔"
	L["Temple of Ahn'Qiraj"] = "安其拉神殿"
	L["The Temple of Atal'Hakkar"] = "阿塔哈卡神庙"
	L["Theramore Isle"] = "塞拉摩岛"
	L["Thousand Needles"] = "千针石林"
	L["Thunder Bluff"] = "雷霆崖"
	L["Tirisfal Glades"] = "提瑞斯法林地"
	L["Uldaman"] = "奥达曼"
	L["Un'Goro Crater"] = "安戈洛环形山"
	L["Undercity"] = "幽暗城"
	--L["Upper Blackrock Spire"] = true
	L["Wailing Caverns"] = "哀嚎洞穴"
	L["Warsong Gulch"] = "战歌峡谷"
	L["Western Plaguelands"] = "西瘟疫之地"
	L["Westfall"] = "西部荒野"
	L["Wetlands"] = "湿地"
	L["Winterspring"] = "冬泉谷"
	L["Zul'Farrak"] = "祖尔法拉克"
	L["Zul'Gurub"] = "祖尔格拉布"
	-- Ace3v: from the localized 1.12 AreaTable.dbc
	L["The Black Morass"] = "黑色沼泽"
	L["Dalaran"] = "达拉然"
end

L = AceLocale:NewLocale(MAJOR_VERSION, "zhTW", nil, true)
if L then
	L["Ahn'Qiraj"] = "安其拉"
	L["Alterac Mountains"] = "奧特蘭克山脈"
	L["Alterac Valley"] = "奧特蘭克山谷"
	L["Arathi Basin"] = "阿拉希盆地"
	L["Arathi Highlands"] = "阿拉希高地"
	L["Ashenvale"] = "梣谷"
	L["Auberdine"] = "奧伯丁"
	L["Azshara"] = "艾薩拉"
	L["Badlands"] = "荒蕪之地"
	L["The Barrens"] = "貧瘠之地"
	L["Blackfathom Deeps"] = "黑暗深淵"
	L["Blackrock Depths"] = "黑石深淵"
	L["Blackrock Mountain"] = "黑石山"
	L["Blackrock Spire"] = "黑石塔"
	L["Blackwing Lair"] = "黑翼之巢"
	L["Blasted Lands"] = "詛咒之地"
	L["Booty Bay"] = "藏寶海灣"
	L["Burning Steppes"] = "燃燒平原"
	L["Darkshore"] = "黑海岸"
	L["Darnassus"] = "達納蘇斯"
	L["The Deadmines"] = "死亡礦坑"
	L["Deadwind Pass"] = "逆風小徑"
	L["Deeprun Tram"] = "礦道地鐵"
	L["Desolace"] = "淒涼之地"
	L["Dire Maul"] = "厄運之槌"
	L["Dire Maul (West)"] = "厄運之槌（西）"
	L["Dire Maul (North)"] = "厄運之槌（北）"
	L["Dire Maul (East)"] = "厄運之槌（東）"
	L["Dun Morogh"] = "丹莫洛"
	L["Durotar"] = "杜洛塔"
	L["Duskwood"] = "暮色森林"
	L["Dustwallow Marsh"] = "塵泥沼澤"
	L["Eastern Plaguelands"] = "東瘟疫之地"
	L["Elwynn Forest"] = "艾爾文森林"
	L["Everlook"] = "永望鎮"
	L["Felwood"] = "費伍德森林"
	L["Feralas"] = "菲拉斯"
	L["The Forbidding Sea"] = "禁忌之海"
	L["Gadgetzan"] = "加基森"
	L["Gates of Ahn'Qiraj"] = "安其拉之門"
	L["Gnomeregan"] = "諾姆瑞根"
	L["The Great Sea"] = "無盡之海"
	L["Grom'gol Base Camp"] = "格羅姆高營地"
	L["Hall of Legends"] = "傳說大廳"
	L["Hillsbrad Foothills"] = "希爾斯布萊德丘陵"
	L["The Hinterlands"] = "辛特蘭"
	L["Hyjal"] = "海加爾山"
	L["Ironforge"] = "鐵爐堡"
	L["Loch Modan"] = "洛克莫丹"
	L["Lower Blackrock Spire"] = "黑石塔（下層）"
	L["Maraudon"] = "瑪拉頓"
	L["Menethil Harbor"] = "米奈希爾港"
	L["Molten Core"] = "熔火之心"
	L["Moonglade"] = "月光林地"
	L["Mulgore"] = "莫高雷"
	L["Naxxramas"] = "納克薩瑪斯"
	L["Onyxia's Lair"] = "奧妮克希亞的巢穴"
	L["Orgrimmar"] = "奧格瑪"
	L["Ratchet"] = "棘齒城"
	L["Ragefire Chasm"] = "怒焰裂谷"
	L["Razorfen Downs"] = "剃刀高地"
	L["Razorfen Kraul"] = "剃刀沼澤"
	L["Redridge Mountains"] = "赤脊山"
	L["Ruins of Ahn'Qiraj"] = "安其拉廢墟"
	L["Scarlet Monastery"] = "血色修道院"
	L["Scholomance"] = "通靈學院"
	L["Searing Gorge"] = "灼熱峽谷"
	L["Shadowfang Keep"] = "影牙城堡"
	L["Silithus"] = "希利蘇斯"
	L["Silverpine Forest"] = "銀松森林"
	L["The Stockade"] = "監獄"
	L["Stonetalon Mountains"] = "石爪山脈"
	L["Stormwind City"] = "暴風城"
	L["Stranglethorn Vale"] = "荊棘谷"
	L["Stratholme"] = "斯坦索姆"
	L["Swamp of Sorrows"] = "悲傷沼澤"
	L["Tanaris"] = "塔納利斯"
	L["Teldrassil"] = "泰達希爾"
	L["Temple of Ahn'Qiraj"] = "安其拉神廟"
	L["The Temple of Atal'Hakkar"] = "阿塔哈卡神廟"
	L["Theramore Isle"] = "塞拉摩島"
	L["Thousand Needles"] = "千針石林"
	L["Thunder Bluff"] = "雷霆崖"
	L["Tirisfal Glades"] = "提里斯法林地"
	L["Uldaman"] = "奧達曼"
	L["Un'Goro Crater"] = "安戈洛環形山"
	L["Undercity"] = "幽暗城"
	L["Upper Blackrock Spire"] = "黑石塔（上層）"
	L["Wailing Caverns"] = "哀嚎洞穴"
	L["Warsong Gulch"] = "戰歌峽谷"
	L["Western Plaguelands"] = "西瘟疫之地"
	L["Westfall"] = "西部荒野"
	L["Wetlands"] = "濕地"
	L["Winterspring"] = "冬泉谷"
	L["Zul'Farrak"] = "祖爾法拉克"
	L["Zul'Gurub"] = "祖爾格拉布"
end

L = AceLocale:NewLocale(MAJOR_VERSION, "koKR", nil, true)
if L then
	L["Ahn'Qiraj"] = "안퀴라즈"
	L["Alterac Mountains"] = "알터랙 산맥"
	L["Alterac Valley"] = "알터랙 계곡"
	L["Arathi Basin"] = "아라시 분지"
	L["Arathi Highlands"] = "아라시 고원"
	L["Ashenvale"] = "잿빛 골짜기"
	L["Auberdine"] = "아우버다인"
	L["Azshara"] = "아즈샤라"
	L["Badlands"] = "황야의 땅"
	L["The Barrens"] = "불모의 땅"
	L["Blackfathom Deeps"] = "검은심연의 나락"
	L["Blackrock Depths"] = "검은바위 나락"
	L["Blackrock Mountain"] = "검은바위 산"
	L["Blackrock Spire"] = "검은바위 첨탑"
	L["Blackwing Lair"] = "검은날개 둥지"
	L["Blasted Lands"] = "저주받은 땅"
	L["Booty Bay"] = "무법항"
	L["Burning Steppes"] = "불타는 평원"
	L["Darkshore"] = "어둠의 해안"
	L["Darnassus"] = "다르나서스"
	L["The Deadmines"] = "죽음의 폐광"
	L["Deadwind Pass"] = "죽음의 고개"
	L["Deeprun Tram"] = "깊은굴 지하철"
	L["Desolace"] = "잊혀진 땅"
	L["Dire Maul"] = "혈투의 전장"
	L["Dire Maul (East)"] = "혈투의 전장 동부"
	L["Dire Maul (West)"] = "혈투의 전장 서부"
	L["Dire Maul (North)"] = "혈투의 전장 북부"
	L["Dun Morogh"] = "던 모로"
	L["Durotar"] = "듀로타"
	L["Duskwood"] = "그늘숲"
	L["Dustwallow Marsh"] = "먼지진흙 습지대"
	L["Eastern Plaguelands"] = "동부 역병지대"
	L["Elwynn Forest"] = "엘윈 숲"
	L["Everlook"] = "눈망루 마을"
	L["Felwood"] = "악령의 숲"
	L["Feralas"] = "페랄라스"
	L["The Forbidding Sea"] = "성난 바다"
	L["Gadgetzan"] = "가젯잔"
	L["Gates of Ahn'Qiraj"] = "안퀴라즈 성문"
	L["Gnomeregan"] = "놈리건"
	L["The Great Sea"] = "대해"
	L["Grom'gol Base Camp"] = "그롬골 주둔지"
	L["Hall of Legends"] = "전설의 전당"
	L["Hillsbrad Foothills"] = "힐스브래드 구릉지"
	L["The Hinterlands"] = "동부 내륙지"
	L["Hyjal"] = "하이잘 산"
	L["Ironforge"] = "아이언포지"
	L["Loch Modan"] = "모단 호수"
	L["Lower Blackrock Spire"] = "검은바위 첨탑 하층"
	L["Maraudon"] = "마라우돈"
	L["Menethil Harbor"] = "메네실 항구"
	L["Molten Core"] = "화산 심장부"
	L["Moonglade"] = "달의 숲"
	L["Mulgore"] = "멀고어"
	L["Naxxramas"] = "낙스라마스"
	L["Onyxia's Lair"] = "오닉시아의 둥지"
	L["Orgrimmar"] = "오그리마"
	L["Ratchet"] = "톱니항"
	L["Ragefire Chasm"] = "성난불길 협곡"
	L["Razorfen Downs"] = "가시덩굴 구릉"
	L["Razorfen Kraul"] = "가시덩굴 우리"
	L["Redridge Mountains"] = "붉은마루 산맥"
	L["Ruins of Ahn'Qiraj"] = "안퀴라즈 폐허"
	L["Scarlet Monastery"] = "붉은십자군 수도원"
	L["Scholomance"] = "스칼로맨스"
	L["Searing Gorge"] = "이글거리는 협곡"
	L["Shadowfang Keep"] = "그림자송곳니 성채"
	L["Silithus"] = "실리더스"
	L["Silverpine Forest"] = "은빛소나무 숲"
	L["The Stockade"] = "스톰윈드 지하감옥"
	L["Stonetalon Mountains"] = "돌발톱 산맥"
	L["Stormwind City"] = "스톰윈드"
	L["Stranglethorn Vale"] = "가시덤불 골짜기"
	L["Stratholme"] = "스트라솔름"
	L["Swamp of Sorrows"] = "슬픔의 늪"
	L["Tanaris"] = "타나리스"
	L["Teldrassil"] = "텔드랏실"
	L["Temple of Ahn'Qiraj"] = "안퀴라즈 사원"
	L["The Temple of Atal'Hakkar"] = "아탈학카르 신전"
	L["Theramore Isle"] = "테라모어 섬"
	L["Thousand Needles"] = "버섯구름 봉우리"
	L["Thunder Bluff"] = "썬더 블러프"
	L["Tirisfal Glades"] = "티리스팔 숲"
	L["Uldaman"] = "울다만"
	L["Un'Goro Crater"] = "운고로 분화구"
	L["Undercity"] = "언더시티"
	L["Upper Blackrock Spire"] = "검은바위 첨탑 상층"
	L["Wailing Caverns"] = "통곡의 동굴"
	L["Warsong Gulch"] = "전쟁노래 협곡"
	L["Western Plaguelands"] = "서부 역병지대"
	L["Westfall"] = "서부 몰락지대"
	L["Wetlands"] = "저습지"
	L["Winterspring"] = "여명의 설원"
	L["Zul'Farrak"] = "줄파락"
	L["Zul'Gurub"] = "줄구룹"
	-- Ace3v: from the localized 1.12 AreaTable.dbc
	L["The Black Morass"] = "검은늪"
	L["Dalaran"] = "달라란"
end

local translations = AceLocale:GetLocale(MAJOR_VERSION)

-- Ace3v: AceLocale-2.2 built the reverse map lazily on first use; kept, since
-- most consumers only ever translate one way.
local reverse

local availableLocales = {}
for _, locale in ipairs({"enUS", "esES", "ruRU", "deDE", "frFR", "zhCN", "zhTW", "koKR"}) do
	availableLocales[locale] = true
end

local gameLocale = GAME_LOCALE or GetLocale()
local currentLocale = availableLocales[gameLocale] and gameLocale or "enUS"

local next, rawget, error, tostring = next, rawget, error, tostring

-- Ace3v: should two zones ever share one localized name, the alphabetically
-- first English name is kept, so both clients give the same answer.
local function initReverse()
	reverse = {}
	for base, localized in next, translations do
		local old = reverse[localized]
		if not old or base < old then
			reverse[localized] = base
		end
	end
end

------------------------------------------------
-- The AceLocale-2.2 instance API
------------------------------------------------

function BabbleZone:GetTranslation(text)
	return self[text]
end

function BabbleZone:GetStrictTranslation(text)
	local value = rawget(translations, text)
	if value == nil then
		error(MAJOR_VERSION .. ": Translation \"" .. tostring(text) .. "\" does not exist for locale " .. currentLocale, 2)
	end
	return value
end

function BabbleZone:GetReverseTranslation(text)
	if not reverse then initReverse() end
	local translation = reverse[text]
	if not translation then
		error(MAJOR_VERSION .. ": Reverse translation for \"" .. tostring(text) .. "\" does not exist", 2)
	end
	return translation
end

function BabbleZone:HasTranslation(text)
	return rawget(translations, text) and true
end

function BabbleZone:HasReverseTranslation(text)
	if not reverse then initReverse() end
	return reverse[text] and true
end

function BabbleZone:GetIterator()
	return next, translations, nil
end

function BabbleZone:GetReverseIterator()
	if not reverse then initReverse() end
	return next, reverse, nil
end

function BabbleZone:GetLocale()
	return currentLocale
end

function BabbleZone:HasLocale(locale)
	return availableLocales[locale] and true
end

function BabbleZone:IterateAvailableLocales()
	return next, availableLocales, nil
end

-- Ace3v: no-ops. AceLocale-3.0 has no strictness setting -- see the README -- and
-- no debugging mode; kept so callers of the Ace2 API do not break.
function BabbleZone:SetStrictness()
end

function BabbleZone:EnableDebugging()
end

function BabbleZone:EnableDynamicLocales()
end

function BabbleZone:Debug()
end

function BabbleZone:GetLibraryVersion()
	return MAJOR_VERSION, MINOR_VERSION
end

-- Ace3v: what makes the library indexable, as `Z["Elwynn Forest"]`. Methods are
-- raw keys on BabbleZone itself, so they are found before this ever runs. The
-- lookup is raw, so a miss never adds a key that HasTranslation would then see.
local warned = {}
setmetatable(BabbleZone, {
	__index = function(self, key)
		local value = rawget(translations, key)
		if value == nil then
			if not warned[key] then
				warned[key] = true
				geterrorhandler()(MAJOR_VERSION .. ": Translation \"" .. tostring(key) .. "\" does not exist.")
			end
			return key
		end
		return value
	end,
	__tostring = function(self)
		return MAJOR_VERSION
	end,
})
