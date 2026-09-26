--[[
Name: LibHealComm-1.0
Revision: $Rev: 1 $
Ported from: HealComm-1.0 r11732 -- from the Aviana mirror; the WowAce original is gone
Author(s): aviana (https://github.com/Aviana), Ace3v port
Description: A library to provide communication of heals and resurrections.
Dependencies: LibStub, CallbackHandler-1.0, AceCore-3.0, AceEvent-3.0,
              AceTimer-3.0, AceLocale-3.0, LibRosterLib-2.0,
              LibItemBonusLib-1.0, LibDeformat-2.0
Note: Ace3v port of HealComm-1.0, API-compatible. The addon-channel protocol is
      byte-identical to the Ace2 original so the two interoperate in one raid.
]]

local MAJOR, MINOR = "LibHealComm-1.0", 2

local HealComm, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not HealComm then return end -- No upgrade needed

local AceCore = LibStub("AceCore-3.0")
LibStub("AceEvent-3.0"):Embed(HealComm)
LibStub("AceTimer-3.0"):Embed(HealComm)
HealComm.hooks = HealComm.hooks or {}
-- Vanilla: MINOR 1 fired with an argument count, Fire(event, argc, ...), and its registry may have been
-- built by a CallbackHandler with that Fire. Rebuild it, keeping the registrations.
if oldminor and oldminor < 2 and HealComm.callbacks then
	local old = HealComm.callbacks
	HealComm.callbacks = LibStub("CallbackHandler-1.0"):New(HealComm)
	for event, handlers in pairs(old.events) do
		for owner, func in pairs(handlers) do HealComm.callbacks.events[event][owner] = func end
	end
end
HealComm.callbacks = HealComm.callbacks or LibStub("CallbackHandler-1.0"):New(HealComm)

local roster = LibStub("LibRosterLib-2.0")
local itemBonus = LibStub("LibItemBonusLib-1.0")
local Deformat = LibStub("LibDeformat-2.0")

-- Lua APIs
local tgetn, tinsert = table.getn, table.insert
local strfind, strlen, strlower = string.find, string.len, string.lower
local pairs, tonumber, type = pairs, tonumber, type
local _G = AceCore._G

------------------------------------------------
-- Locales
------------------------------------------------

local L_enUS = LibStub("AceLocale-3.0"):NewLocale(MAJOR, "enUS", true)
if L_enUS then
local T = {
	["Libram of Divinity"] = true,
	["Libram of Light"] = true,
	["Set: Increases the duration of your Rejuvenation spell by 3 sec."] = true,
	["Set: Increases the duration of your Renew spell by 3 sec."] = true,
	["Totem of Life"] = true,
	["Totem of Sustaining"] = true,
	["^Corpse of (.+)$"] = true,
	["Holy Light"] = true,
	["Flash of Light"] = true,
	["Lesser Heal"] = true,
	["Heal"] = true,
	["Greater Heal"] = true,
	["Flash Heal"] = true,
	["Prayer of Healing"] = true,
	["Lesser Healing Wave"] = true,
	["Healing Wave"] = true,
	["Chain Heal"] = true,
	["Healing Touch"] = true,
	["Regrowth"] = true,
	["Resurrection"] = true;
	["Rebirth"] = true;
	["Redemption"] = true;
	["Ancestral Spirit"] = true;
	["Renew"] = true;
	["Rejuvenation"] = true;
	["Power Infusion"] = true,
	["Divine Favor"] = true,
	["Nature Aligned"] = true,
	["Crusader's Wrath"] = true,
	["The Furious Storm"] = true,
	["Holy Power"] = true,
	["Prayer Beads Blessing"] = true,
	["Chromatic Infusion"] = true,
	["Ascendance"] = true,
	["Ephemeral Power"] = true,
	["Unstable Power"] = true,
	["Healing of the Ages"] = true,
	["Essence of Sapphiron"] = true,
	["The Eye of the Dead"] = true,
	["Mortal Strike"] = true,
	["Wound Poison"] = true,
	["Curse of the Deadwood"] = true,
	["Veil of Shadow"] = true,
	["Gehennas' Curse"] = true,
	["Mortal Wound"] = true,
	["Necrotic Poison"] = true,
	["Blood Fury"] = true,
	["Necrotic Aura"] = true,
	["Blessing of Light"] = true,
	["Healing Way"] = true,
	["Warsong Gulch"] = true,
	["Arathi Basin"] = true,
	["Alterac Valley"] = true,
}
for k, v in pairs(T) do L_enUS[k] = v end
end
local L_ruRU = LibStub("AceLocale-3.0"):NewLocale(MAJOR, "ruRU")
if L_ruRU then
local T = {
	["Libram of Divinity"] = "Манускрипт божественности",
	["Libram of Light"] = "Манускрипт света",
	["Set: Increases the duration of your Rejuvenation spell by 3 sec."] = "Комплект: Увеличение длительности заклинания \"Омоложение\" на 3 сек.", -- T2
	["Set: Increases the duration of your Renew spell by 3 sec."] = "Комплект: Увеличение длительности заклинания \"Обновление\" на 3 сек.", -- T2.5
	["Totem of Life"] = "Тотем жизни",
	["Totem of Sustaining"] = "Тотем воодушевления",
	["^Corpse of (.+)$"] = "^Труп (.+)$",
	["Holy Light"] = "Свет небес",
	-- Ace3v: this held the *Improved* Flash of Light talent name, so as a cast
	-- spell key (HealComm.Spells) it could never match. Babble-Spell-2.2 ruRU and
	-- Blizzard both give the spell name used below.
	["Flash of Light"] = "Вспышка Света",
	["Lesser Heal"] = "Малое исцеление",
	["Heal"] = "Исцеление",
	["Greater Heal"] = "Великое исцеление",
	["Flash Heal"] = "Быстрое исцеление",
	["Prayer of Healing"] = "Молитва исцеления",
	["Lesser Healing Wave"] = "Малая волна исцеления",
	["Healing Wave"] = "Волна исцеления",
	["Chain Heal"] = "Цепное исцеление",
	["Healing Touch"] = "Целительное прикосновение",
	["Regrowth"] = "Восстановление",
	["Resurrection"] = "Воскрешение",
	["Rebirth"] = "Возрождение",
	["Redemption"] = "Искупление",
	["Ancestral Spirit"] = "Дух предков",
	["Renew"] = "Обновление",
	["Rejuvenation"] = "Омоложение",
	["Power Infusion"] = "Придание сил",
	["Divine Favor"] = "Божественное одобрение",
	["Nature Aligned"] = "Упорядочение Природы",
	["Crusader's Wrath"] = "Гнев рыцаря Света",
	["The Furious Storm"] = "Яростный шторм",
	["Holy Power"] = "Священная сила",
	["Prayer Beads Blessing"] = "Благословение четок",
	["Chromatic Infusion"] = "Цветной настой",
	["Ascendance"] = "Господство",
	["Ephemeral Power"] = "Эфемерная Власть",
	["Unstable Power"] = "Изменчивая сила",
	["Healing of the Ages"] = "Исцеление Эпох",
	["Essence of Sapphiron"] = "Сущность Сапфирона",
	["The Eye of the Dead"] = "Глаз Мертвого",
	["Mortal Strike"] = "Смертельный удар",
	["Wound Poison"] = "Нейтрализующий яд",
	["Curse of the Deadwood"] = "Проклятие Мертвого Леса",
	["Veil of Shadow"] = "Пелена Тени",
	["Gehennas' Curse"] = "Проклятие Гееннаса",
	["Mortal Wound"] = "Смертоносная рана",
	["Necrotic Poison"] = "Некротический яд",
	["Blood Fury"] = "Кровавое неистовство",
	["Necrotic Aura"] = "Мертвенная аура",
	["Blessing of Light"] = "Благословение Света",
	["Healing Way"] = "Путь исцеления",
	["Warsong Gulch"] = "Ущелье Песни Войны",
	["Arathi Basin"] = "Низина Арати",
	["Alterac Valley"] = "Альтеракская долина",
}
for k, v in pairs(T) do L_ruRU[k] = v end
end
local L_deDE = LibStub("AceLocale-3.0"):NewLocale(MAJOR, "deDE")
if L_deDE then
local T = {
	["Libram of Divinity"] = "Buchband der Offenbarung",
	["Libram of Light"] = "Buchband des Lichts",
	["Set: Increases the duration of your Rejuvenation spell by 3 sec."] = "Set: Erh\195\182ht die Dauer Eures Zaubers \'Verj\195\188ngung\' um 3 Sek.",
	["Set: Increases the duration of your Renew spell by 3 sec."] = "Set: Erh\195\182ht die Dauer Eures Zaubers 'Erneuerung' um 3 Sek.",
	["Totem of Life"] = "Totem des Lebens",
	["Totem of Sustaining"] = "Totem der Erhaltung",
	["^Corpse of (.+)$"] = "^Leichnam von (.+)$",
	["Holy Light"] = "Heiliges Licht",
	["Flash of Light"] = "Lichtblitz",
	["Lesser Heal"] = "Geringes Heilen",
	["Heal"] = "Heilen",
	["Greater Heal"] = "Große Heilung",
	["Flash Heal"] = "Blitzheilung",
	["Prayer of Healing"] = "Gebet der Heilung",
	["Lesser Healing Wave"] = "Geringe Welle der Heilung",
	["Healing Wave"] = "Welle der Heilung",
	["Chain Heal"] = "Kettenheilung",
	["Healing Touch"] = "Heilende Ber\195\188hrung",
	["Regrowth"] = "Nachwachsen",
	["Resurrection"] = "Auferstehung",
	["Rebirth"] = "Wiedergeburt",
	["Redemption"] = "Erl\195\182sung",
	["Ancestral Spirit"] = "Geist der Ahnen",
	["Renew"] = "Erneuerung",
	["Rejuvenation"] = "Verj\195\188ngung",
	["Power Infusion"] = "Seele der Macht",
	["Divine Favor"] = "G\195\182ttliche Gunst",
	["Nature Aligned"] = "Naturverbundenheit",
	["Crusader's Wrath"] = "Zorn des Kreuzfahrers",
	["The Furious Storm"] = "Der wilde Sturm",
	["Holy Power"] = "Heilige Kraft",
	["Prayer Beads Blessing"] = "Segen der Gebetsperlen",
	["Chromatic Infusion"] = "Erf\195\188llt mit chromatischer Macht",
	["Ascendance"] = "Überlegenheit",
	["Ephemeral Power"] = "Ephemere Macht",
	["Unstable Power"] = "Instabile Macht",
	["Healing of the Ages"] = "Heilung der Urzeiten",
	["Essence of Sapphiron"] = "Essenz Saphirons",
	["The Eye of the Dead"] = "Das Auge des Todes",
	["Mortal Strike"] = "T\195\182dlicher Stoß",
	["Wound Poison"] = "Wundgift",
	["Curse of the Deadwood"] = "Fluch der Totenwaldfelle",
	["Veil of Shadow"] = "Schattenschleier",
	["Gehennas' Curse"] = "Gehennas' Fluch",
	["Mortal Wound"] = "Trauma",
	["Necrotic Poison"] = "Nekrotisches Gift",
	["Blood Fury"] = "Kochendes Blut",
	["Necrotic Aura"] = "Nekrotische Aura",
	["Blessing of Light"] = "Segen des Lichts",
	["Healing Way"] = "Pfad der Heilung",
	["Warsong Gulch"] = "Warsongschlucht",
	["Arathi Basin"] = "Arathibecken",
	["Alterac Valley"] = "Alteractal",
}
for k, v in pairs(T) do L_deDE[k] = v end
end
local L_frFR = LibStub("AceLocale-3.0"):NewLocale(MAJOR, "frFR")
if L_frFR then
local T = {
	["Libram of Divinity"] = "Libram de divinit\195\169",
	["Libram of Light"] = "Libram de lumi\195\168re",
	["Set: Increases the duration of your Rejuvenation spell by 3 sec."] = "Set: Augmente la dur\195\169e de votre sort R\195\169cup\195\169ration de 3 s.",
	["Set: Increases the duration of your Renew spell by 3 sec."] = "Set: Augmente la dur\195\169e de votre sort R\195\169novation de 3 s.",	
	["Totem of Life"] = "Totem de vie",
	["Totem of Sustaining"] = "Totem de soutien",
	["^Corpse of (.+)$"] = "^Cadavre |2 (.+)$",
	["Holy Light"] = "Lumi\195\168re sacr\195\169e",
	["Flash of Light"] = "Eclair lumineux",
	["Lesser Heal"] = "Soins inf\195\169rieurs",
	["Heal"] = "Soins",
	["Greater Heal"] = "Soins sup\195\169rieurs",
	["Flash Heal"] = "Soins rapides",
	["Prayer of Healing"] = "Pri\195\168re de soins",
	["Lesser Healing Wave"] = "Vague de soins inf\195\169rieurs",
	["Healing Wave"] = "Vague de soins",
	["Chain Heal"] = "Salve de gu\195\169rison",
	["Healing Touch"] = "Toucher gu\195\169risseur",
	["Regrowth"] = "R\195\169tablissement",
	["Resurrection"] = "R\195\169surrection",
	["Rebirth"] = "Renaissance",
	["Redemption"] = "R\195\169demption",
	["Ancestral Spirit"] = "Esprit ancestral",
	["Renew"] = "R\195\169novation",
	["Rejuvenation"] = "R\195\169cup\195\169ration",
	["Power Infusion"] = "Infusion de puissance",
	["Divine Favor"] = "Faveur divine",
	["Nature Aligned"] = "Alignement sur la nature",
	["Crusader's Wrath"] = "Col\195\168re du crois\195\169",
	["The Furious Storm"] = "La temp\195\170te furieuse",
	["Holy Power"] = "Puissance sacr\195\169e",
	["Prayer Beads Blessing"] = "B\195\169n\195\169diction du chapelet",
	["Chromatic Infusion"] = "Infusion chromatique",
	["Ascendance"] = "Ascendance",
	["Ephemeral Power"] = "Puissance \195\169ph\195\169m\195\168re",
	["Unstable Power"] = "Puissance instable",
	["Healing of the Ages"] = "Soins des \195\162ges",
	["Essence of Sapphiron"] = "Essence de Saphiron",
	["The Eye of the Dead"] = "L'Oeil du mort",
	["Mortal Strike"] = "Frappe mortelle",
	["Wound Poison"] = "Poison douloureux",
	["Curse of the Deadwood"] = "Mal\195\169diction des Mort-bois",
	["Veil of Shadow"] = "Voile de l'ombre",
	["Gehennas' Curse"] = "Mal\195\169diction de Gehennas",
	["Mortal Wound"] = "Blessures mortelles",
	["Necrotic Poison"] = "Poison n\195\169crotique",
	["Blood Fury"] = "Fureur sanguinaire",
	["Necrotic Aura"] = "Aura n\195\169crotique",
	["Blessing of Light"] = "B\195\169n\195\169diction de lumi\195\168re",
	["Healing Way"] = "Flots de soins",
	["Warsong Gulch"] = "Goulet des Warsong",
	["Arathi Basin"] = "Bassin d'Arathi",
	["Alterac Valley"] = "Vall\195\169e d'Alterac",
}
for k, v in pairs(T) do L_frFR[k] = v end
end
local L_zhCN = LibStub("AceLocale-3.0"):NewLocale(MAJOR, "zhCN")
if L_zhCN then
local T = {
	["Libram of Divinity"] = "神性圣契",
	["Libram of Light"] = "光明圣契",
	["Set: Increases the duration of your Rejuvenation spell by 3 sec."] = "套装：使你的回春术的持续时间延长3秒。", -- T2
	["Set: Increases the duration of your Renew spell by 3 sec."] = "套装：使你的恢复术的持续时间延长3秒。", -- T2.5
	["Totem of Life"] = "生命图腾",
	["Totem of Sustaining"] = "持久图腾",
	["^Corpse of (.+)$"] = "(.+)的尸体",
	["Holy Light"] = "圣光术",
	["Flash of Light"] = "圣光闪现",
	["Lesser Heal"] = "次级治疗术",
	["Heal"] = "治疗术",
	["Greater Heal"] = "强效治疗术",
	["Flash Heal"] = "快速治疗",
	["Prayer of Healing"] = "治疗祷言",
	["Lesser Healing Wave"] = "次级治疗波",
	["Healing Wave"] = "治疗波",
	["Chain Heal"] = "治疗链",
	["Healing Touch"] = "治疗之触",
	["Regrowth"] = "愈合",
	["Resurrection"] = "复活",
	["Rebirth"] = "复生",
	["Redemption"] = "救赎",
	["Ancestral Spirit"] = "先祖之魂",
	["Renew"] = "恢复",
	["Rejuvenation"] = "回春术",
	["Power Infusion"] = "能量灌注",
	["Divine Favor"] = "神恩术",
	["Nature Aligned"] = "自然之盟",
	["Crusader's Wrath"] = "十字军之怒",
	["The Furious Storm"] = "狂野风暴",
	["Holy Power"] = "神圣强化",
	["Prayer Beads Blessing"] = "祈祷之珠",
	["Chromatic Infusion"] = "多彩能量",
	["Ascendance"] = "优越",
	["Ephemeral Power"] = "短暂强力",
	["Unstable Power"] = "能量无常",
	["Healing of the Ages"] = "远古治疗",
	["Essence of Sapphiron"] = "萨菲隆的精华",
	["The Eye of the Dead"] = "亡者之眼",
	["Mortal Strike"] = "致死打击",
	["Wound Poison"] = "致伤毒药",
	["Curse of the Deadwood"] = "死木诅咒",
	["Veil of Shadow"] = "暗影之雾", -- 存在多个不同名技能，暗影之雾/暗影迷雾/幽影之雾
	["Gehennas' Curse"] = "基赫纳斯的诅咒",
	["Mortal Wound"] = "重伤",
	["Necrotic Poison"] = "死灵之毒",
	["Blood Fury"] = "血性狂暴",
	["Necrotic Aura"] = "死灵光环",
	["Blessing of Light"] = "光明祝福",
	["Healing Way"] = "治疗之道",
	["Warsong Gulch"] = "战歌峡谷",
	["Arathi Basin"] = "阿拉希盆地",
	["Alterac Valley"] = "奥特兰克山谷",
}
for k, v in pairs(T) do L_zhCN[k] = v end
end
local L_koKR = LibStub("AceLocale-3.0"):NewLocale(MAJOR, "koKR")
if L_koKR then
local T = {
	["Libram of Divinity"] = "신앙의 성서",
	["Libram of Light"] = "빛의 성서",
	["Set: Increases the duration of your Rejuvenation spell by 3 sec."] = true, --needs translation
	["Set: Increases the duration of your Renew spell by 3 sec."] = true, --needs translation
	["Totem of Life"] = "생명의 토템",
	["Totem of Sustaining"] = "지탱의 토템",
	["^Corpse of (.+)$"] = true, --needs translation
	["Holy Light"] = "성스러운 빛",
	["Flash of Light"] = "빛의 섬광",
	["Lesser Heal"] = "하급 치유",
	["Heal"] = "치유",
	["Greater Heal"] = "상급 치유",
	["Flash Heal"] = "순간 치유",
	["Prayer of Healing"] = "치유의 기원",
	["Lesser Healing Wave"] = "하급 치유의 물결",
	["Healing Wave"] = "치유의 물결",
	["Chain Heal"] = "연쇄 치유",
	["Healing Touch"] = "치유의 손길",
	["Regrowth"] = "재생",
	["Resurrection"] = "부활",
	["Rebirth"] = "환생",
	["Redemption"] = "구원",
	["Ancestral Spirit"] = "고대의 영혼",
	["Renew"] = "소생",
	["Rejuvenation"] = "회복",
	["Power Infusion"] = "마력 주입",
	["Divine Favor"] = "신의 은총",
	["Nature Aligned"] = "자연 동화",
	["Crusader's Wrath"] = "성전사의 격노",
	["The Furious Storm"] = "휘몰아치는 폭풍",
	["Holy Power"] = "신성 마법 강화",
	["Prayer Beads Blessing"] = "기원의 묵주의 축복",
	["Chromatic Infusion"] = "오색 용력",
	["Ascendance"] = "승리의 기세",
	["Ephemeral Power"] = "마력의 힘",
	["Unstable Power"] = "불안정한 마력",
	["Healing of the Ages"] = "세월의 치유",
	["Essence of Sapphiron"] = "사피론의 정수",
	["The Eye of the Dead"] = "사자의 눈",
	["Mortal Strike"] = "죽음의 일격",
	["Wound Poison"] = "상처 감염 독",
	["Curse of the Deadwood"] = "마른가지의 저주",
	["Veil of Shadow"] = "암흑의 장막",
	["Gehennas' Curse"] = "게헨나스의 저주",
	["Mortal Wound"] = "죽음의 상처",
	["Necrotic Poison"] = "부패의 독",
	["Blood Fury"] = "피의 격노",
	["Necrotic Aura"] = "괴저 오라",
	["Blessing of Light"] = "빛의 축복",
	["Healing Way"] = "치유의 길",
	["Warsong Gulch"] = "전쟁노래 협곡",
	["Arathi Basin"] = "아라시 분지",
	["Alterac Valley"] = "알터랙 계곡",
}
for k, v in pairs(T) do L_koKR[k] = v end
end
local L_esES = LibStub("AceLocale-3.0"):NewLocale(MAJOR, "esES")
if L_esES then
local T = {
	-- Ace3v: esES was not present in HealComm-1.0. Spell and item names were
	-- resolved from Wowhead Classic Era -- an id is only
	-- accepted when its enUS name matches exactly, so no name is guessed.
	-- Battleground names come from this repo's own Babble-Zone-2.2 esES data.
	--
	-- Deliberately absent, falling back to enUS rather than being invented:
	--   * the two "Set: Increases the duration of ..." strings -- item tooltips do
	--     not expose set-bonus lines, so the Spanish form could not be verified.
	--     Consequence on a Spanish client: getSetBonus() returns nil, so Renew and
	--     Rejuvenation use their base durations (15/12 instead of 18/15).
	--   * "^Corpse of (.+)$" -- the Spanish corpse tooltip wording is unverified,
	--     so resurrect-on-corpse target detection stays English-only.
	--   * 7 trinket buff names (Nature Aligned, Prayer Beads Blessing, Chromatic
	--     Infusion, Ephemeral Power, Healing of the Ages, Essence of Sapphiron,
	--     The Eye of the Dead) -- not resolvable by name search.
	["Ancestral Spirit"] = "Espíritu ancestral",
	["Ascendance"] = "Ascensión",
	["Blessing of Light"] = "Bendición de la luz",
	["Blood Fury"] = "Furia sangrienta",
	["Chain Heal"] = "Curación en cadena",
	["Crusader's Wrath"] = "Ira del cruzado",
	["Curse of the Deadwood"] = "Maldición de los Muertobosque",
	["Divine Favor"] = "Favor divino",
	["Flash Heal"] = "Destello curativo",
	["Flash of Light"] = "Destello de Luz",
	["Gehennas' Curse"] = "Maldición de Gehennas",
	["Greater Heal"] = "Curación superior",
	["Heal"] = "Curar",
	["Healing Touch"] = "Toque curativo",
	["Healing Wave"] = "Onda de curación",
	["Healing Way"] = "Forma curativa",
	["Holy Light"] = "Luz Sagrada",
	["Holy Power"] = "Poder Sagrado",
	["Lesser Heal"] = "Curación inferior",
	["Lesser Healing Wave"] = "Onda inferior de curación",
	["Libram of Divinity"] = "Tratado sobre Divinidad",
	["Libram of Light"] = "Tratado sobre Luz",
	["Mortal Strike"] = "Golpe mortal",
	["Mortal Wound"] = "Herida mortal",
	["Necrotic Aura"] = "Aura necrótica",
	["Necrotic Poison"] = "Veneno necrótico",
	["Power Infusion"] = "Infusión de poder",
	["Prayer of Healing"] = "Rezo de curación",
	["Rebirth"] = "Renacer",
	["Redemption"] = "Redención",
	["Regrowth"] = "Recrecimiento",
	["Rejuvenation"] = "Rejuvenecimiento",
	["Renew"] = "Renovar",
	["Resurrection"] = "Resurrección",
	["The Furious Storm"] = "La tormenta furiosa",
	["Totem of Life"] = "Tótem de vida",
	["Totem of Sustaining"] = "Tótem de Sostenibilidad",
	["Unstable Power"] = "Poder inestable",
	["Veil of Shadow"] = "Velo de Sombras",
	["Wound Poison"] = "Envenenar herida",
	["Warsong Gulch"] = "Garganta Grito de Guerra",
	["Arathi Basin"] = "Cuenca de Arathi",
	["Alterac Valley"] = "Valle de Alterac",
}
for k, v in pairs(T) do L_esES[k] = v end
end


local L = LibStub("AceLocale-3.0"):GetLocale(MAJOR)

------------------------------------------------
-- Startup
------------------------------------------------

-- State that must survive a library upgrade. HealComm-1.0 copied these out of
-- oldLib inside activate(); LibStub hands back the same table, so the or-idiom
-- does the same job.
HealComm.Heals                 = HealComm.Heals or {}
HealComm.GrpHeals              = HealComm.GrpHeals or {}
HealComm.Lookup                = HealComm.Lookup or {}
HealComm.pendingResurrections  = HealComm.pendingResurrections or {}
HealComm.Hots                  = HealComm.Hots or {}
HealComm.SpellCastInfo         = HealComm.SpellCastInfo or {}

-- AceEvent-2.0 had named scheduled events; AceTimer-3.0 allocates ids instead,
-- so keep a name -> id map to reproduce ScheduleEvent / CancelScheduledEvent /
-- IsEventScheduled. A fired timer leaves a stale id behind, which TimerStatus
-- reports as nil, so `scheduled` stays correct without extra bookkeeping.
HealComm.timers = HealComm.timers or {}
local timers = HealComm.timers

local function schedule(self, name, func, delay, argc, a1, a2, a3)
	local old = timers[name]
	if old then self:CancelTimer(old) end
	timers[name] = self:ScheduleTimer(func, delay, argc, a1, a2, a3)
end

local function cancel(self, name)
	local id = timers[name]
	if id then
		self:CancelTimer(id)
		timers[name] = nil
	end
end

local function scheduled(self, name)
	local id = timers[name]
	return id ~= nil and self:TimerStatus(id) ~= nil
end

function HealComm:GetLibraryVersion()
	return MAJOR, MINOR
end

-- Ace3v: the hooks are pass-through replacements of the globals, with the
-- original kept in self.hooks[name] for the handler to call. On Unreal Azeroth
-- replacing these globals measurably works, UseAction and CastSpellByName in
-- combat too, while AceHook's RawHookScript(WorldFrame, "OnMouseDown") raises
-- an error there (WorldFrame:HasScript("OnMouseDown") is false, and a handler
-- set on it never runs), which aborted every hook after it. A click in the 3D
-- world reaches CameraOrSelectOrMoveStart instead, the left-button binding's
-- function, which is hooked in place of WorldFrame's OnMouseDown.
local function hookGlobal(self, name)
	local orig = _G[name]
	if type(orig) ~= "function" or self.hooks[name] then return end
	self.hooks[name] = orig
	_G[name] = function(a1, a2, a3) return self[name](self, a1, a2, a3) end
end

-- World clicks. The 1.12.1 client protects CameraOrSelectOrMoveStart, like
-- every movement and camera function: once an addon has replaced it, each
-- left click in the world is blocked ("blocked from an action only available
-- to the Blizzard UI"). There WorldFrame delivers OnMouseDown, as the Ace2
-- original used it. Unreal Azeroth has no such protection, and a WorldFrame
-- OnMouseDown handler never runs there, so the global is replaced instead.
-- The client is told apart by Unreal Azeroth's own markers (the engine's
-- GetUECvar, interface number 5875), not by WorldFrame:HasScript: a choice
-- made on it at PLAYER_LOGIN lost Unreal Azeroth's world clicks, although it
-- reads false there later.
local function isUnrealAzeroth()
	if _G.GetUECvar then return true end
	if type(_G.GetBuildInfo) == "function" then
		local ok, _, _, _, toc = pcall(_G.GetBuildInfo)
		if ok and tonumber(toc) == 5875 then return true end
	end
	return false
end

local function hookWorldClick(self)
	local WorldFrame = _G.WorldFrame
	if WorldFrame and not isUnrealAzeroth() then
		local orig = WorldFrame:GetScript("OnMouseDown")
		self.hooks.WorldFrameOnMouseDown = orig
		WorldFrame:SetScript("OnMouseDown", function()
			self:OnMouseDown()
			if orig then orig() end
		end)
	else
		hookGlobal(self, "CameraOrSelectOrMoveStart")
	end
end

function HealComm:PLAYER_LOGIN()
	if self.hooked then return end
	self.hooked = true
	hookGlobal(self, "CastSpell")
	hookGlobal(self, "CastSpellByName")
	hookGlobal(self, "UseAction")
	hookGlobal(self, "SpellTargetUnit")
	hookGlobal(self, "SpellStopTargeting")
	hookGlobal(self, "TargetUnit")
	hookWorldClick(self)
end

function HealComm:Enable()
-- not used anymore, but as addons still might be calling this method, we're keeping it.
end


function HealComm:Disable()
-- not used anymore, but as addons still might be calling this method, we're keeping it.
end

------------------------------------------------
-- Addon Code
------------------------------------------------

function strmatch(str, pat, init)
	local a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a13,a14,a15,a16,a17,a18,a19,a20 = string.find(str, pat, init)
	return a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a13,a14,a15,a16,a17,a18,a19,a20
end

HealComm.Spells = {
	[L["Holy Light"]] = {
		[1] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(1,5)
			local hlMod = 4*talentRank/100 + 1
			return (44*hlMod+(((2.5/3.5) * SpellPower)*0.1))
		end;
		[2] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(1,5)
			local hlMod = 4*talentRank/100 + 1
			return (88*hlMod+(((2.5/3.5) * SpellPower)*0.224))
		end;
		[3] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(1,5)
			local hlMod = 4*talentRank/100 + 1
			return (174*hlMod+(((2.5/3.5) * SpellPower)*0.476))
		end;
		[4] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(1,5)
			local hlMod = 4*talentRank/100 + 1
			return (334*hlMod+((2.5/3.5) * SpellPower))
		end;
		[5] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(1,5)
			local hlMod = 4*talentRank/100 + 1
			return (522*hlMod+((2.5/3.5) * SpellPower))
		end;
		[6] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(1,5)
			local hlMod = 4*talentRank/100 + 1
			return (740*hlMod+((2.5/3.5) * SpellPower))
		end;
		[7] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(1,5)
			local hlMod = 4*talentRank/100 + 1
			return (1000*hlMod+((2.5/3.5) * SpellPower))
		end;
		[8] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(1,5)
			local hlMod = 4*talentRank/100 + 1
			return (1318*hlMod+((2.5/3.5) * SpellPower))
		end;
		[9] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(1,5)
			local hlMod = 4*talentRank/100 + 1
			return (1681*hlMod+((2.5/3.5) * SpellPower))
		end;
	};
	[L["Flash of Light"]] = {
		[1] = function (SpellPower)
			local lp = 0
			if GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")) then
				local _,_,itemstring = string.find(GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")), "|H(.+)|h")
				local name = GetItemInfo(itemstring)
				if name == 	L["Libram of Divinity"] then
					lp = 53
				elseif name == L["Libram of Light"] then
					lp = 83
				end
			end
			local _,_,_,_,talentRank,_ = GetTalentInfo(1,5)
			local hlMod = 4*talentRank/100 + 1
			return (68*hlMod+lp+((1.5/3.5) * SpellPower))
		end;
		[2] = function (SpellPower)
			local lp = 0
			if GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")) then
				local _,_,itemstring = string.find(GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")), "|H(.+)|h")
				local name = GetItemInfo(itemstring)
				if name == 	L["Libram of Divinity"] then
					lp = 53
				elseif name == L["Libram of Light"] then
					lp = 83
				end
			end
			local _,_,_,_,talentRank,_ = GetTalentInfo(1,5)
			local hlMod = 4*talentRank/100 + 1
			return (104*hlMod+lp+((1.5/3.5) * SpellPower))
		end;
		[3] = function (SpellPower)
			local lp = 0
			if GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")) then
				local _,_,itemstring = string.find(GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")), "|H(.+)|h")
				local name = GetItemInfo(itemstring)
				if name == 	L["Libram of Divinity"] then
					lp = 53
				elseif name == L["Libram of Light"] then
					lp = 83
				end
			end
			local _,_,_,_,talentRank,_ = GetTalentInfo(1,5)
			local hlMod = 4*talentRank/100 + 1
			return (155*hlMod+lp+((1.5/3.5) * SpellPower))
		end;
		[4] = function (SpellPower)
			local lp = 0
			if GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")) then
				local _,_,itemstring = string.find(GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")), "|H(.+)|h")
				local name = GetItemInfo(itemstring)
				if name == 	L["Libram of Divinity"] then
					lp = 53
				elseif name == L["Libram of Light"] then
					lp = 83
				end
			end
			local _,_,_,_,talentRank,_ = GetTalentInfo(1,5)
			local hlMod = 4*talentRank/100 + 1
			return (210*hlMod+lp+((1.5/3.5) * SpellPower))
		end;
		[5] = function (SpellPower)
			local lp = 0
			if GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")) then
				local _,_,itemstring = string.find(GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")), "|H(.+)|h")
				local name = GetItemInfo(itemstring)
				if name == 	L["Libram of Divinity"] then
					lp = 53
				elseif name == L["Libram of Light"] then
					lp = 83
				end
			end
			local _,_,_,_,talentRank,_ = GetTalentInfo(1,5)
			local hlMod = 4*talentRank/100 + 1
			return (284*hlMod+lp+((1.5/3.5) * SpellPower))
		end;
		[6] = function (SpellPower)
			local lp = 0
			if GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")) then
				local _,_,itemstring = string.find(GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")), "|H(.+)|h")
				local name = GetItemInfo(itemstring)
				if name == 	L["Libram of Divinity"] then
					lp = 53
				elseif name == L["Libram of Light"] then
					lp = 83
				end
			end
			local _,_,_,_,talentRank,_ = GetTalentInfo(1,5)
			local hlMod = 4*talentRank/100 + 1
			return (364*hlMod+lp+((1.5/3.5) * SpellPower))
		end;
		[7] = function (SpellPower)
			local lp = 0
			if GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")) then
				local _,_,itemstring = string.find(GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")), "|H(.+)|h")
				local name = GetItemInfo(itemstring)
				if name == 	L["Libram of Divinity"] then
					lp = 53
				elseif name == L["Libram of Light"] then
					lp = 83
				end
			end
			local _,_,_,_,talentRank,_ = GetTalentInfo(1,5)
			local hlMod = 4*talentRank/100 + 1
			return (481*hlMod+lp+((1.5/3.5) * SpellPower))
		end;
	};
	[L["Healing Wave"]] = {
		[1] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,14)
			local pMod = 2*talentRank/100 + 1
			return (40*pMod+(((1.5/3.5) * SpellPower)*0.22))
		end;
		[2] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,14)
			local pMod = 2*talentRank/100 + 1
			return (72*pMod+(((2/3.5) * SpellPower)*0.38))
		end;
		[3] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,14)
			local pMod = 2*talentRank/100 + 1
			return (143*pMod+(((2.5/3.5) * SpellPower)*0.446))
		end;
		[4] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,14)
			local pMod = 2*talentRank/100 + 1
			return (293*pMod+(((3/3.5) * SpellPower)*0.7))
		end;
		[5] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,14)
			local pMod = 2*talentRank/100 + 1
			return (409*pMod+((3/3.5) * SpellPower))
		end;
		[6] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,14)
			local pMod = 2*talentRank/100 + 1
			return (580*pMod+((3/3.5) * SpellPower))
		end;
		[7] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,14)
			local pMod = 2*talentRank/100 + 1
			return (798*pMod+((3/3.5) * SpellPower))
		end;
		[8] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,14)
			local pMod = 2*talentRank/100 + 1
			return (1093*pMod+((3/3.5) * SpellPower))
		end;
		[9] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,14)
			local pMod = 2*talentRank/100 + 1
			return (1465*pMod+((3/3.5) * SpellPower))
		end;
		[10] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,14)
			local pMod = 2*talentRank/100 + 1
			return (1736*pMod+((3/3.5) * SpellPower))
		end;
	};
	[L["Lesser Healing Wave"]] = {
		[1] = function (SpellPower)
			local tp = 0
			if GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")) then
				local _,_,itemstring = string.find(GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")), "|H(.+)|h")
				local name = GetItemInfo(itemstring)
				if name == L["Totem of Sustaining"] then
					tp = 53
				elseif name == L["Totem of Life"] then
					tp = 80
				end
			end
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,14)
			local pMod = 2*talentRank/100 + 1
			return (175*pMod+tp+((1.5/3.5) * SpellPower))
		end;
		[2] = function (SpellPower)
			local tp = 0
			if GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")) then
				local _,_,itemstring = string.find(GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")), "|H(.+)|h")
				local name = GetItemInfo(itemstring)
				if name == L["Totem of Sustaining"] then
					tp = 53
				elseif name == L["Totem of Life"] then
					tp = 80
				end
			end
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,14)
			local pMod = 2*talentRank/100 + 1
			return (265*pMod+tp+((1.5/3.5) * SpellPower))
		end;
		[3] = function (SpellPower)
			local tp = 0
			if GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")) then
				local _,_,itemstring = string.find(GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")), "|H(.+)|h")
				local name = GetItemInfo(itemstring)
				if name == L["Totem of Sustaining"] then
					tp = 53
				elseif name == L["Totem of Life"] then
					tp = 80
				end
			end
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,14)
			local pMod = 2*talentRank/100 + 1
			return (360*pMod+tp+((1.5/3.5) * SpellPower))
		end;
		[4] = function (SpellPower)
			local tp = 0
			if GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")) then
				local _,_,itemstring = string.find(GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")), "|H(.+)|h")
				local name = GetItemInfo(itemstring)
				if name == L["Totem of Sustaining"] then
					tp = 53
				elseif name == L["Totem of Life"] then
					tp = 80
				end
			end
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,14)
			local pMod = 2*talentRank/100 + 1
			return (487*pMod+tp+((1.5/3.5) * SpellPower))
		end;
		[5] = function (SpellPower)
			local tp = 0
			if GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")) then
				local _,_,itemstring = string.find(GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")), "|H(.+)|h")
				local name = GetItemInfo(itemstring)
				if name == L["Totem of Sustaining"] then
					tp = 53
				elseif name == L["Totem of Life"] then
					tp = 80
				end
			end
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,14)
			local pMod = 2*talentRank/100 + 1
			return (669*pMod+tp+((1.5/3.5) * SpellPower))
		end;
		[6] = function (SpellPower)
			local tp = 0
			if GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")) then
				local _,_,itemstring = string.find(GetInventoryItemLink("player",GetInventorySlotInfo("RangedSlot")), "|H(.+)|h")
				local name = GetItemInfo(itemstring)
				if name == L["Totem of Sustaining"] then
					tp = 53
				elseif name == L["Totem of Life"] then
					tp = 80
				end
			end
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,14)
			local pMod = 2*talentRank/100 + 1
			return (881*pMod+tp+((1.5/3.5) * SpellPower))
		end;
	};
	[L["Chain Heal"]] = {
		[1] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,14)
			local pMod = 2*talentRank/100 + 1
			return (344*pMod+((2.5/3.5) * SpellPower))
		end;
		[2] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,14)
			local pMod = 2*talentRank/100 + 1
			return (435*pMod+((2.5/3.5) * SpellPower))
		end;
		[3] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,14)
			local pMod = 2*talentRank/100 + 1
			return (591*pMod+((2.5/3.5) * SpellPower))
		end;
	};
	[L["Lesser Heal"]] = {
		[1] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (52*shMod+((1.5/3.5) * (SpellPower+sgMod))*0.19)
		end;
		[2] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (79*shMod+((2/3.5) * (SpellPower+sgMod))*0.34)
		end;
		[3] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (147*shMod+((2.5/3.5) * (SpellPower+sgMod))*0.6)
		end;
	};
	[L["Heal"]] = {
		[1] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (319*shMod+((3/3.5) * (SpellPower+sgMod))*0.586)
		end;
		[2] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (471*shMod+((3/3.5) * (SpellPower+sgMod)))
		end;
		[3] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (610*shMod+((3/3.5) * (SpellPower+sgMod)))
		end;
		[4] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (759*shMod+((3/3.5) * (SpellPower+sgMod)))
		end;
	};
	[L["Flash Heal"]] = {
		[1] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (216*shMod+((1.5/3.5) * (SpellPower+sgMod)))
		end;
		[2] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (287*shMod+((1.5/3.5) * (SpellPower+sgMod)))
		end;
		[3] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (361*shMod+((1.5/3.5) * (SpellPower+sgMod)))
		end;
		[4] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (440*shMod+((1.5/3.5) * (SpellPower+sgMod)))
		end;
		[5] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (568*shMod+((1.5/3.5) * (SpellPower+sgMod)))
		end;
		[6] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (705*shMod+((1.5/3.5) * (SpellPower+sgMod)))
		end;
		[7] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (886*shMod+((1.5/3.5) * (SpellPower+sgMod)))
		end;
	};
	[L["Greater Heal"]] = {
		[1] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (957*shMod+((3/3.5) * (SpellPower+sgMod)))
		end;
		[2] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (1220*shMod+((3/3.5) * (SpellPower+sgMod)))
		end;
		[3] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (1524*shMod+((3/3.5) * (SpellPower+sgMod)))
		end;
		[4] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (1903*shMod+((3/3.5) * (SpellPower+sgMod)))
		end;
		[5] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (2081*shMod+((3/3.5) * (SpellPower+sgMod)))
		end;
	};
	[L["Prayer of Healing"]] = {
		[1] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (311*shMod+((3/3.5/3) * (SpellPower+sgMod)))
		end;
		[2] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (460*shMod+((3/3.5/3) * (SpellPower+sgMod)))
		end;
		[3] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (676*shMod+((3/3.5/3) * (SpellPower+sgMod)))
		end;
		[4] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (965*shMod+((3/3.5/3) * (SpellPower+sgMod)))
		end;
		[5] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(2,14)
			local _,Spirit,_,_ = UnitStat("player",5)
			local sgMod = Spirit * 5*talentRank/100
			local _,_,_,_,talentRank2,_ = GetTalentInfo(2,15)
			local shMod = 2*talentRank2/100 + 1
			return (1070*shMod+((3/3.5/3) * (SpellPower+sgMod)))
		end;
	};
	[L["Healing Touch"]] = {
		[1] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,12)
			local gnMod = 2*talentRank/100 + 1
			return (43*gnMod+((1.5/3.5) * SpellPower * (1-((20-4)*0.0375))))
		end;
		[2] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,12)
			local gnMod = 2*talentRank/100 + 1
			return (101*gnMod+((2/3.5) * SpellPower * (1-((20-13)*0.0375))))
		end;
		[3] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,12)
			local gnMod = 2*talentRank/100 + 1
			return (220*gnMod+((2.5/3.5) * SpellPower))
		end;
		[4] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,12)
			local gnMod = 2*talentRank/100 + 1
			return (435*gnMod+((3/3.5) * SpellPower))
		end;
		[5] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,12)
			local gnMod = 2*talentRank/100 + 1
			return ((634*gnMod)+SpellPower)
		end;
		[6] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,12)
			local gnMod = 2*talentRank/100 + 1
			return ((819*gnMod)+SpellPower)
		end;
		[7] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,12)
			local gnMod = 2*talentRank/100 + 1
			return ((1029*gnMod)+SpellPower)
		end;
		[8] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,12)
			local gnMod = 2*talentRank/100 + 1
			return ((1314*gnMod)+SpellPower)
		end;
		[9] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,12)
			local gnMod = 2*talentRank/100 + 1
			return ((1657*gnMod)+SpellPower)
		end;
		[10] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,12)
			local gnMod = 2*talentRank/100 + 1
			return ((2061*gnMod)+SpellPower)
		end;
		[11] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,12)
			local gnMod = 2*talentRank/100 + 1
			return ((2473*gnMod)+SpellPower)
		end;
	};
	[L["Regrowth"]] = {
		[1] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,12)
			local gnMod = 2*talentRank/100 + 1
			return ((91*gnMod)+(((2/3.5)*SpellPower)*0.5*0.38))
		end;
		[2] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,12)
			local gnMod = 2*talentRank/100 + 1
			return ((177*gnMod)+(((2/3.5)*SpellPower)*0.5*0.513))
		end;
		[3] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,12)
			local gnMod = 2*talentRank/100 + 1
			return ((258*gnMod)+(((2/3.5)*SpellPower)*0.5))
		end;
		[4] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,12)
			local gnMod = 2*talentRank/100 + 1
			return ((340*gnMod)+(((2/3.5)*SpellPower)*0.5))
		end;
		[5] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,12)
			local gnMod = 2*talentRank/100 + 1
			return ((432*gnMod)+(((2/3.5)*SpellPower)*0.5))
		end;
		[6] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,12)
			local gnMod = 2*talentRank/100 + 1
			return ((544*gnMod)+(((2/3.5)*SpellPower)*0.5))
		end;
		[7] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,12)
			local gnMod = 2*talentRank/100 + 1
			return ((686*gnMod)+(((2/3.5)*SpellPower)*0.5))
		end;
		[8] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,12)
			local gnMod = 2*talentRank/100 + 1
			return ((858*gnMod)+(((2/3.5)*SpellPower)*0.5))
		end;
		[9] = function (SpellPower)
			local _,_,_,_,talentRank,_ = GetTalentInfo(3,12)
			local gnMod = 2*talentRank/100 + 1
			return ((1062*gnMod)+(((2/3.5)*SpellPower)*0.5))
		end;
	};
}

-- Ace3v: the amounts in HealComm.Spells are fixed per rank, but a spell's base
-- heal grows with the caster's level: min(level, maxLevel) - spellLevel times
-- the per-level points is added to both ends of the range (the 1.12.1 client's
-- Spell.dbc fields SpellLevel, MaxLevel, EffectRealPointsPerLevel; Healing
-- Wave rank 2 is 64-78 at level 6 and 69-83 from level 11, as its tooltip
-- shows). SpellLevels holds that data per rank, { min, max, spellLevel,
-- maxLevel, pointsPerLevel } (trailing comment: the spell id), taken from the
-- client's Spell.dbc. GetSpellAmount replaces the table's base amount with this
-- one and keeps the rest of the formula (talents, spell power).
HealComm.SpellLevels = {
	[L["Holy Light"]] = {
		{ 39, 47, 1, 5, 0.8 }, -- 635
		{ 76, 90, 6, 11, 1.1 }, -- 639
		{ 159, 187, 14, 19, 1.7 }, -- 647
		{ 310, 356, 22, 27, 2.4 }, -- 1026
		{ 491, 553, 30, 35, 3.1 }, -- 1042
		{ 698, 780, 38, 43, 3.8 }, -- 3472
		{ 945, 1053, 46, 51, 4.6 }, -- 10328
		{ 1246, 1388, 54, 59, 5.2 }, -- 10329
		{ 1590, 1770, 60, 65, 5.8 }, -- 25292
	},
	[L["Flash of Light"]] = {
		{ 62, 72, 20, 25, 1 }, -- 19750
		{ 96, 110, 26, 31, 1.3 }, -- 19939
		{ 145, 163, 34, 39, 1.6 }, -- 19940
		{ 197, 221, 42, 47, 1.9 }, -- 19941
		{ 267, 299, 50, 55, 2.2 }, -- 19942
		{ 343, 383, 58, 63, 2.6 }, -- 19943
	},
	[L["Lesser Heal"]] = {
		{ 46, 56, 1, 3, 0.9 }, -- 2050
		{ 71, 85, 4, 9, 1.1 }, -- 2052
		{ 135, 157, 10, 15, 1.6 }, -- 2053
	},
	[L["Heal"]] = {
		{ 295, 341, 16, 21, 2.4 }, -- 2054
		{ 429, 491, 22, 27, 3.2 }, -- 2055
		{ 566, 642, 28, 33, 4 }, -- 6063
		{ 712, 804, 34, 39, 4.5 }, -- 6064
	},
	[L["Greater Heal"]] = {
		{ 899, 1013, 40, 45, 5.1 }, -- 2060
		{ 1149, 1289, 46, 51, 5.8 }, -- 10963
		{ 1437, 1609, 52, 57, 6.6 }, -- 10964
		{ 1798, 2006, 58, 63, 7.5 }, -- 10965
		{ 1966, 2194, 60, 65, 8.1 }, -- 25314
	},
	[L["Flash Heal"]] = {
		{ 193, 237, 20, 25, 1.9 }, -- 2061
		{ 258, 314, 26, 31, 2.2 }, -- 9472
		{ 327, 393, 32, 37, 2.5 }, -- 9473
		{ 400, 478, 38, 43, 2.8 }, -- 9474
		{ 518, 616, 44, 49, 3.3 }, -- 10915
		{ 644, 764, 50, 55, 3.7 }, -- 10916
		{ 812, 958, 56, 61, 4.2 }, -- 10917
	},
	[L["Prayer of Healing"]] = {
		{ 301, 321, 30, 39, 1.3 }, -- 596
		{ 444, 472, 40, 49, 1.6 }, -- 996
		{ 657, 695, 50, 59, 2 }, -- 10960
		{ 939, 991, 60, 69, 2.4 }, -- 10961
		{ 1041, 1099, 60, 69, 2.5 }, -- 25316
	},
	[L["Lesser Healing Wave"]] = {
		{ 162, 186, 20, 25, 1.7 }, -- 8004
		{ 247, 281, 28, 33, 2.1 }, -- 8008
		{ 337, 381, 36, 41, 2.5 }, -- 8010
		{ 458, 514, 44, 49, 3 }, -- 10466
		{ 631, 705, 52, 57, 3.6 }, -- 10467
		{ 832, 928, 60, 65, 4.2 }, -- 10468
	},
	[L["Healing Wave"]] = {
		{ 34, 44, 1, 5, 0.7 }, -- 331
		{ 64, 78, 6, 11, 1 }, -- 332
		{ 129, 155, 12, 17, 1.5 }, -- 547
		{ 268, 316, 18, 23, 2.3 }, -- 913
		{ 376, 440, 24, 29, 2.7 }, -- 939
		{ 536, 622, 32, 37, 3.3 }, -- 959
		{ 740, 854, 40, 45, 3.9 }, -- 8005
		{ 1017, 1167, 48, 53, 4.7 }, -- 10395
		{ 1367, 1561, 56, 61, 5.5 }, -- 10396
		{ 1620, 1850, 60, 65, 5.5 }, -- 25357
	},
	[L["Chain Heal"]] = {
		{ 320, 368, 40, 45, 2.5 }, -- 1064
		{ 405, 465, 46, 51, 2.8 }, -- 10622
		{ 551, 629, 54, 59, 3.3 }, -- 10623
	},
	[L["Healing Touch"]] = {
		{ 37, 51, 1, 5, 0.8 }, -- 5185
		{ 88, 112, 8, 13, 1.3 }, -- 5186
		{ 195, 243, 14, 19, 1.9 }, -- 5187
		{ 363, 445, 20, 25, 2.7 }, -- 5188
		{ 572, 694, 26, 31, 3.5 }, -- 5189
		{ 742, 894, 32, 37, 4 }, -- 6778
		{ 936, 1120, 38, 43, 4.5 }, -- 8903
		{ 1199, 1427, 44, 49, 5.2 }, -- 9758
		{ 1516, 1796, 50, 55, 5.9 }, -- 9888
		{ 1890, 2230, 56, 61, 6.6 }, -- 9889
		{ 2267, 2677, 60, 65, 7.3 }, -- 25297
	},
	[L["Regrowth"]] = {
		{ 84, 98, 12, 17, 1.8 }, -- 8936
		{ 164, 188, 18, 23, 2.5 }, -- 8938
		{ 240, 274, 24, 29, 3.1 }, -- 8939
		{ 318, 360, 30, 35, 3.6 }, -- 8940
		{ 405, 457, 36, 41, 4.1 }, -- 8941
		{ 511, 575, 42, 47, 4.7 }, -- 9750
		{ 646, 724, 48, 53, 5.3 }, -- 9856
		{ 809, 905, 54, 59, 6 }, -- 9857
		{ 1003, 1119, 60, 65, 6.8 }, -- 9858
	},
}

local function zeroTalents()
	return nil, nil, nil, nil, 0, 0
end

-- The formula's base amount: the result with no spell power and every talent
-- read as rank 0.
local function tableBase(fn)
	local realGetTalentInfo = GetTalentInfo
	GetTalentInfo = zeroTalents
	local ok, value = pcall(fn, 0)
	GetTalentInfo = realGetTalentInfo
	if ok then return value end
end

function HealComm:GetSpellAmount(spellName, rank, spellPower)
	local fn = self.Spells[spellName] and self.Spells[spellName][rank]
	if not fn then return 0 end
	local amount = fn(spellPower)
	local data = self.SpellLevels[spellName] and self.SpellLevels[spellName][rank]
	local base = data and tableBase(fn)
	if base and base > 0 then
		local level = UnitLevel("player") or data[3]
		if data[4] > 0 and level > data[4] then level = data[4] end
		if level < data[3] then level = data[3] end
		local levelBase = (data[1] + data[2]) / 2 + (level - data[3]) * data[5]
		-- scale the base difference by the talent multiplier the formula applies
		amount = amount + (levelBase - base) * fn(0) / base
	end
	return amount
end

-- Ace3v: the healing still to come from the player's own heal-over-time
-- spells. HotLevels holds, per rank, { tick, spellLevel, duration, interval }
-- from the client's Spell.dbc (the tick does not grow with level). The addon
-- channel carries only a HoT's target and duration, so another player's HoT
-- has timing (getRenewTime & co.) but no amount.
HealComm.HotLevels = {
	[L["Renew"]] = {
		{ 9, 8, 15, 3 }, -- 139
		{ 20, 14, 15, 3 }, -- 6074
		{ 35, 20, 15, 3 }, -- 6075
		{ 49, 26, 15, 3 }, -- 6076
		{ 63, 32, 15, 3 }, -- 6077
		{ 80, 38, 15, 3 }, -- 6078
		{ 102, 44, 15, 3 }, -- 10927
		{ 130, 50, 15, 3 }, -- 10928
		{ 162, 56, 15, 3 }, -- 10929
		{ 194, 60, 15, 3 }, -- 25315
	},
	[L["Rejuvenation"]] = {
		{ 8, 4, 12, 3 }, -- 774
		{ 14, 10, 12, 3 }, -- 1058
		{ 29, 16, 12, 3 }, -- 1430
		{ 45, 22, 12, 3 }, -- 2090
		{ 61, 28, 12, 3 }, -- 2091
		{ 76, 34, 12, 3 }, -- 3627
		{ 97, 40, 12, 3 }, -- 8910
		{ 122, 46, 12, 3 }, -- 9839
		{ 152, 52, 12, 3 }, -- 9840
		{ 189, 58, 12, 3 }, -- 9841
		{ 222, 60, 12, 3 }, -- 25299
	},
	[L["Regrowth"]] = {
		{ 14, 12, 21, 3 }, -- 8936
		{ 25, 18, 21, 3 }, -- 8938
		{ 37, 24, 21, 3 }, -- 8939
		{ 49, 30, 21, 3 }, -- 8940
		{ 61, 36, 21, 3 }, -- 8941
		{ 78, 42, 21, 3 }, -- 9750
		{ 98, 48, 21, 3 }, -- 9856
		{ 123, 54, 21, 3 }, -- 9857
		{ 152, 60, 21, 3 }, -- 9858
	},
}

-- Share of spell power a whole HoT gets (duration / 15; Regrowth's HoT half of
-- that), reduced below level 20 like the direct heals' formulas.
local HOT_POWER = { [L["Renew"]] = 1, [L["Rejuvenation"]] = 0.8, [L["Regrowth"]] = 0.7 }

local function talentRank(tab, index)
	local _, _, _, _, rank = GetTalentInfo(tab, index)
	return tonumber(rank) or 0
end

-- Talent multiplier: Priest Spiritual Healing (2,15) +2% and Improved Renew
-- (2,2) +5% per rank; Druid Gift of Nature (3,12) +2% and Improved
-- Rejuvenation (3,10) +5% per rank.
local function hotTalentMod(hotName)
	if hotName == L["Renew"] then
		return 1 + 0.02 * talentRank(2, 15) + 0.05 * talentRank(2, 2)
	elseif hotName == L["Rejuvenation"] then
		return 1 + 0.02 * talentRank(3, 12) + 0.05 * talentRank(3, 10)
	end
	return 1 + 0.02 * talentRank(3, 12)
end

-- Amount of one tick of the player's HoT, and the tick interval.
function HealComm:GetHotTick(hotName, rank, spellPower, mod)
	local data = self.HotLevels[hotName] and self.HotLevels[hotName][rank]
	if not data then return end
	local ticks = data[3] / data[4]
	local power = (HOT_POWER[hotName] or 0) * (spellPower or 0)
	if data[2] < 20 then
		power = power * (1 - (20 - data[2]) * 0.0375)
	end
	return (data[1] * hotTalentMod(hotName) + power / ticks) * (mod or 1), data[4]
end

-- Records the tick of a HoT the player just put on `target` (HoT key: "Renew",
-- "Reju", "Regr").
local function recordOwnHot(self, target, key, hotName, rank, targetPower, targetMod)
	local hot = self.Hots[target] and self.Hots[target][key]
	if not hot then return end
	local bonus = itemBonus:GetBonus("HEAL")
	local buffpower, buffmod = self:GetBuffSpellPower()
	hot.tick, hot.interval = self:GetHotTick(hotName, tonumber(rank),
		bonus + buffpower + (targetPower or 0), (buffmod or 1) * (targetMod or 1))
	hot.caster = UnitName("player")
end

-- Another player's HoT, announced on the addon channel without an amount: the
-- tick of the highest rank the caster's level allows, with no spell power or
-- talents, until the first tick seen in the combat log replaces it.
local function estimateHot(self, target, key, hotName, caster)
	local hot = self.Hots[target] and self.Hots[target][key]
	local ranks = self.HotLevels[hotName]
	if not hot or not ranks then return end
	local unit = roster:GetUnitIDFromName(caster)
	local level = unit and UnitLevel(unit)
	if not level or level < 1 then level = UnitLevel("player") end
	local best
	for r = 1, tgetn(ranks) do
		if ranks[r][2] <= level then best = ranks[r] end
	end
	hot.caster = caster
	if best then
		hot.tick, hot.interval = best[1], best[4]
	else
		hot.tick, hot.interval = nil, nil
	end
end
HealComm.recordOwnHot = recordOwnHot

-- Healing still to come from the HoTs on the player named `name`; with
-- `caster`, only from that caster's.
function HealComm:getHotHeal(name, caster)
	local hots = self.Hots[name]
	if not hots then return 0 end
	local now, total = GetTime(), 0
	for _, hot in pairs(hots) do
		if hot.tick and hot.interval and hot.start and hot.dur
			and (not caster or hot.caster == caster) then
			local left = hot.start + tonumber(hot.dur) - now
			if left > 0 then
				local ticks = math.ceil(left / hot.interval - 0.001)
				local all = math.floor(tonumber(hot.dur) / hot.interval + 0.001)
				if ticks > all then ticks = all end
				total = total + ticks * hot.tick
			end
		end
	end
	return total
end

local Resurrections = {
	[L["Resurrection"]] = true;
	[L["Rebirth"]] = true;
	[L["Redemption"]] = true;
	[L["Ancestral Spirit"]] = true;
}

local Hots = {
	[L["Renew"]] = true;
	[L["Rejuvenation"]] = true;
}

local function strsplit(pString, pPattern)
	local Table = {}
	local fpat = "(.-)" .. pPattern
	local last_end = 1
	local s, e, cap = strfind(pString, fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			table.insert(Table,cap)
		end
		last_end = e+1
		s, e, cap = strfind(pString, fpat, last_end)
	end
	if last_end <= strlen(pString) then
		cap = strfind(pString, last_end)
		table.insert(Table, cap)
	end
	return Table
end

local healcommTip = CreateFrame("GameTooltip", "healcommTip", nil, "GameTooltipTemplate")

-- Ace3v: a tooltip loses its owner whenever it hides, and an unowned tooltip
-- is not filled by its Set* methods, so the owner is set again before each
-- scan (unconditionally: IsOwned's return shape differs between clients).
-- UIParent is the owner LibGratuity-2.0 uses, measured on both clients.
local function scanTip()
	healcommTip:SetOwner(UIParent, "ANCHOR_NONE")
	return healcommTip
end

HealComm.Buffs = {
	[L["Power Infusion"]] = {amount = 0, mod = 0.2, icon = "Interface\\Icons\\Spell_Holy_PowerInfusion"};
	[L["Divine Favor"]] = {amount = 0, mod = 0.5, icon = "Interface\\Icons\\Spell_Holy_Heal"};
	[L["Nature Aligned"]] = {amount = 0, mod = 0.2, icon = "Interface\\Icons\\Spell_Nature_SpiritArmor"};
	[L["Crusader's Wrath"]] = {amount = 95, mod = 0, icon = "Interface\\Icons\\Spell_Nature_GroundingTotem"};
	[L["The Furious Storm"]] = {amount = 95, mod = 0, icon = "Interface\\Icons\\Spell_Nature_CallStorm"};
	[L["Holy Power"]] = {amount = 80, mod = 0, icon = "Interface\\Icons\\Spell_Holy_HolyNova"};
	[L["Prayer Beads Blessing"]] = {amount = 190, mod = 0, icon = "Interface\\Icons\\Inv_Jewelry_Necklace_11"};
	[L["Chromatic Infusion"]] = {amount = 190, mod = 0, icon = "Interface\\Icons\\Spell_Holy_MindVision"};
	[L["Ascendance"]] = {amount = 75, mod = 0, icon = "Interface\\Icons\\Spell_Lightning_LightningBolt01"};
	[L["Ephemeral Power"]] = {amount = 175, mod = 0, icon = "Interface\\Icons\\Spell_Holy_MindVision"};
	[L["Unstable Power"]] = {amount = 34, mod = 0, icon = "Interface\\Icons\\Spell_Lightning_LightningBolt01"};
	[L["Healing of the Ages"]] = {amount = 350, mod = 0, icon = "Interface\\Icons\\Spell_Nature_HealingWaveGreater"};
	[L["Essence of Sapphiron"]] = {amount = 130, mod = 0, icon = "Interface\\Icons\\Inv_Trinket_Naxxramas06"};
	[L["The Eye of the Dead"]] = {amount = 450, mod = 0, icon = "Interface\\Icons\\Inv_Trinket_Naxxramas01"}
}
	
HealComm.Debuffs = {
	[L["Mortal Strike"]] = {amount = 0, mod = 0.5, icon = "Interface\\Icons\\Ability_Warrior_SavageBlow"};
	[L["Wound Poison"]] = {amount = -135, mod = 0, icon = "Interface\\Icons\\Inv_Misc_Herb_16"};
	[L["Curse of the Deadwood"]] = {amount = 0, mod = 0.5, icon = "Interface\\Icons\\Spell_Shadow_GatherShadows"};
	[L["Veil of Shadow"]] = {amount = 0, mod = 0.75, icon = "Interface\\Icons\\Spell_Shadow_GatherShadows"};
	[L["Gehennas' Curse"]] = {amount = 0, mod = 0.75, icon = "Interface\\Icons\\Spell_Shadow_GatherShadows"};
	[L["Mortal Wound"]] = {amount = 0, mod = 0.1, icon = "Interface\\Icons\\Ability_CriticalStrike"};
	[L["Necrotic Poison"]] = {amount = 0, mod = 0.9, icon = "Interface\\Icons\\Ability_Creature_Poison_03"};
	[L["Blood Fury"]] = {amount = 0, mod = 0.5, icon = "Interface\\Icons\\Ability_Rogue_FeignDeath"};
	[L["Necrotic Aura"]] = {amount = 0, mod = 1, icon = "Interface\\Icons\\Ability_Creature_Disease_05"}
}
	
local function getSetBonus()
	scanTip():SetInventoryItem("player", 1)
	local text = "healcommTipTextLeft"..(healcommTip:NumLines() or 1)
	local text = _G[text]
	if text then
		text = text:GetText()
	else
		return nil
	end
	if text == L["Set: Increases the duration of your Rejuvenation spell by 3 sec."] or text == L["Set: Increases the duration of your Renew spell by 3 sec."] then
		return true
	else
		return nil
	end
end
	
function HealComm:GetBuffSpellPower()
	local Spellpower = 0
	local healmod = 1
	for i=1, 32 do
		local buffTexture, buffApplications = UnitBuff("player", i)
		if not buffTexture then
			return Spellpower, healmod
		end
		scanTip():SetUnitBuff("player", i)
		local buffName = healcommTipTextLeft1:GetText()
		if self.Buffs[buffName] and self.Buffs[buffName].icon == buffTexture then
			Spellpower = (self.Buffs[buffName].amount * buffApplications) + Spellpower
			healmod = (self.Buffs[buffName].mod * buffApplications) + healmod
		end
	end
	return Spellpower, healmod
end

function HealComm:GetUnitSpellPower(unit, spell)
	local targetpower = 0
	local targetmod = 1
	local buffTexture, buffApplications
	local debuffTexture, debuffApplications
	local buffName
	for i=1, 32 do
		if UnitIsVisible(unit) and UnitIsConnected(unit) and UnitCanAssist("player", unit) then
			buffTexture, buffApplications = UnitBuff(unit, i)
			scanTip():SetUnitBuff(unit, i)
		else
			buffTexture, buffApplications = UnitBuff("player", i)
			scanTip():SetUnitBuff("player", i)
		end
		if not buffTexture then
			break
		end
		buffName = healcommTipTextLeft1:GetText()
		if buffName == L["Blessing of Light"] then
			local HLBonus, FoLBonus = strmatch(healcommTipTextLeft2:GetText(),"(%d+).-(%d+)")
			if (spell == L["Flash of Light"]) then
				targetpower = FoLBonus + targetpower
			elseif spell == L["Holy Light"] then
				targetpower = HLBonus + targetpower
			end
		end
		if buffName == L["Healing Way"] and spell == L["Healing Wave"] then
			targetmod = targetmod * ((buffApplications * 0.06) + 1)
		end
	end
	for i=1, 16 do
		if UnitIsVisible(unit) and UnitIsConnected(unit) and UnitCanAssist("player", unit) then
			debuffTexture, debuffApplications = UnitDebuff(unit, i)
			scanTip():SetUnitDebuff(unit, i)
		else
			debuffTexture, debuffApplications = UnitDebuff("player", i)
			scanTip():SetUnitDebuff("player", i)
		end
		if not debuffTexture then
			break
		end
		local debuffName = healcommTipTextLeft1:GetText()
		if self.Debuffs[debuffName] then
			targetpower = (self.Debuffs[debuffName].amount * debuffApplications) + targetpower
			targetmod = (1-(self.Debuffs[debuffName].mod * debuffApplications)) * targetmod
		end
	end
	return targetpower, targetmod
end			

function HealComm:UNIT_HEALTH()
	local name = UnitName(arg1)
	if self.pendingResurrections[name] then
		for k,v in pairs(self.pendingResurrections[name]) do
			self.pendingResurrections[name][k] = nil
		end
		self.callbacks:Fire("HealComm_Ressupdate", name)
	end
end
			
function HealComm:stopHeal(caster)
	if scheduled(self, "Healcomm_"..caster) then
		cancel(self, "Healcomm_"..caster)
	end
	if self.Lookup[caster] then
		self.Heals[self.Lookup[caster]][caster] = nil
		self.callbacks:Fire("HealComm_Healupdate", self.Lookup[caster])
		self.Lookup[caster] = nil
	end
end

function HealComm:startHeal(caster, target, size, casttime)
	schedule(self, "Healcomm_"..caster, self.stopHeal, (casttime/1000), 2, self, caster)
	if not self.Heals[target] then
		self.Heals[target] = {}
	end
	if self.Lookup[caster] then
		self.Heals[self.Lookup[caster]][caster] = nil
		self.Lookup[caster] = nil
	end
	self.Heals[target][caster] = {amount = math.floor(size), ctime = (casttime/1000)+GetTime()}
	self.Lookup[caster] = target
	self.callbacks:Fire("HealComm_Healupdate", target)
end

function HealComm:delayHeal(caster, delay)
	cancel(self, "Healcomm_"..caster)
	if self.Lookup[caster] and self.Heals[self.Lookup[caster]] then
		self.Heals[self.Lookup[caster]][caster].ctime = self.Heals[self.Lookup[caster]][caster].ctime + (delay/1000)
		schedule(self, "Healcomm_"..caster, self.stopHeal, (self.Heals[self.Lookup[caster]][caster].ctime-GetTime()), 2, self, caster)
	end
end

function HealComm:startGrpHeal(caster, size, casttime, party1, party2, party3, party4, party5)
	schedule(self, "Healcomm_"..caster, self.stopGrpHeal, (casttime/1000), 2, self, caster)
	self.GrpHeals[caster] = {amount = math.floor(size), ctime = (casttime/1000)+GetTime(), targets = {party1, party2, party3, party4, party5}}
	for i=1,tgetn(self.GrpHeals[caster].targets) do
		self.callbacks:Fire("HealComm_Healupdate", self.GrpHeals[caster].targets[i])
	end
end

function HealComm:stopGrpHeal(caster)
	if scheduled(self, "Healcomm_"..caster) then
		cancel(self, "Healcomm_"..caster)
	end
	local targets
	if self.GrpHeals[caster] then
		targets = self.GrpHeals[caster].targets
	end
	self.GrpHeals[caster] = nil
	if targets then
		for i=1,tgetn(targets) do
			self.callbacks:Fire("HealComm_Healupdate", targets[i])
		end
	end
end

function HealComm:delayGrpHeal(caster, delay)
	cancel(self, "Healcomm_"..caster)
	if self.GrpHeals[caster] then
		self.GrpHeals[caster].ctime = self.GrpHeals[caster].ctime + (delay/1000)
		schedule(self, "Healcomm_"..caster, self.stopGrpHeal, (self.GrpHeals[caster].ctime-GetTime()), 2, self, caster)
	end
end

function HealComm:startResurrection(caster, target)
	if not self.pendingResurrections[target] then
		self.pendingResurrections[target] = {}
	end
	self.pendingResurrections[target][caster] = GetTime()+70
	schedule(self, "Healcomm_"..caster..target, self.RessExpire, 70, 3, self, caster, target)
	self.callbacks:Fire("HealComm_Ressupdate", target)
end

function HealComm:cancelResurrection(caster)
	for k,v in pairs(self.pendingResurrections) do
		if v[caster] and (v[caster]-GetTime()) > 60 then
			self.pendingResurrections[k][caster] = nil
			self.callbacks:Fire("HealComm_Ressupdate", k)
		end
	end
end

function HealComm:RessExpire(caster, target)
	self.pendingResurrections[target][caster] = nil
	self.callbacks:Fire("HealComm_Ressupdate", target)
end

-- Outside a raid the message goes to PARTY explicitly: the 1.12.1 client
-- delivers a RAID message to the party when there is no raid, the Unreal
-- Azeroth client drops it. Solo it still goes to RAID, where both drop it.
function HealComm:SendAddonMessage(msg)
	local zone = GetRealZoneText()
	if zone == L["Warsong Gulch"] or zone == L["Arathi Basin"] or zone == L["Alterac Valley"] then
		SendAddonMessage("HealComm", msg, "BATTLEGROUND")
	elseif GetNumRaidMembers() == 0 and GetNumPartyMembers() > 0 then
		SendAddonMessage("HealComm", msg, "PARTY")
	else
		SendAddonMessage("HealComm", msg, "RAID")
	end
end

function HealComm:SPELLCAST_START()
	self:ResolveWorldClick(arg1)
	if ( self.SpellCastInfo and self.SpellCastInfo[1] == arg1 and self.Spells[arg1] ) then
		local Bonus = itemBonus:GetBonus("HEAL")
		local buffpower, buffmod = self:GetBuffSpellPower()
		local targetpower, targetmod = self.SpellCastInfo[4], self.SpellCastInfo[5]
		local Bonus = Bonus + buffpower
		local amount = ((math.floor(self:GetSpellAmount(self.SpellCastInfo[1], tonumber(self.SpellCastInfo[2]), Bonus))+targetpower)*buffmod*targetmod)
		if arg1 == L["Prayer of Healing"] then
			local targets = {UnitName("player")}
			local targetsstring = UnitName("player").."/"
			for i=1,4 do
				if CheckInteractDistance("party"..i, 4) then
					table.insert(targets, i ,UnitName("party"..i))
					targetsstring = targetsstring..UnitName("party"..i).."/"
				end
			end
			self:SendAddonMessage("GrpHeal/"..amount.."/"..arg2.."/"..targetsstring)
			self:startGrpHeal(UnitName("player"), amount, arg2, targets[1], targets[2], targets[3], targets[4], targets[5])
		else
			self:SendAddonMessage("Heal/"..self.SpellCastInfo[3].."/"..amount.."/"..arg2.."/")
			self:startHeal(UnitName("player"), self.SpellCastInfo[3], amount, arg2)
		end
	elseif ( self.SpellCastInfo and self.SpellCastInfo[1] == arg1 and Resurrections[arg1] ) then
		self:SendAddonMessage("Resurrection/"..self.SpellCastInfo[3].."/start/")
		self:startResurrection(UnitName("player"), self.SpellCastInfo[3])
	end
	self.spellIsCasting = arg1
end

function HealComm:SPELLCAST_INTERRUPTED()
	if scheduled(self, "TriggerRegrowthHot") then
		cancel(self, "TriggerRegrowthHot")
	end

	if self.Spells[self.spellIsCasting] then
		if self.spellIsCasting == L["Prayer of Healing"] then
			self:SendAddonMessage("GrpHealstop")
			self:stopGrpHeal(UnitName("player"))
		else
			self:SendAddonMessage("Healstop")
			self:stopHeal(UnitName("player"))
		end
	elseif Resurrections[self.spellIsCasting] then
		self:SendAddonMessage("Resurrection/stop/")
		self:cancelResurrection(UnitName("player"))
	end
	self.CurrentSpellRank = nil
	self.CurrentSpellName =  nil
	self.spellIsCasting = nil
	for key in pairs(self.SpellCastInfo) do
		self.SpellCastInfo[key] = nil
	end
end

function HealComm:SPELLCAST_FAILED()
	self.failed = true
	self.worldClickSpell = nil
end

function HealComm:SPELLCAST_DELAYED()
	if self.spellIsCasting == L["Prayer of Healing"] then
		self:SendAddonMessage("GrpHealdelay/"..arg1.."/")
		self:delayGrpHeal(UnitName("player"), arg1)
	else
		self:SendAddonMessage("Healdelay/"..arg1.."/")
		self:delayHeal(UnitName("player"), arg1)
	end
end

function HealComm:TriggerRegrowthHot()
	local dur = 21
	self:SendAddonMessage("Regr/"..self.savetarget.."/"..dur.."/")
	if not self.Hots[self.savetarget] then
		self.Hots[self.savetarget] = {}
	end
	if not self.Hots[self.savetarget]["Regr"] then
		self.Hots[self.savetarget]["Regr"]= {}
	end
	self.Hots[self.savetarget]["Regr"].start = GetTime()
	self.Hots[self.savetarget]["Regr"].dur = dur
	recordOwnHot(self, self.savetarget, "Regr", L["Regrowth"], self.saverank, self.savepower, self.savemod)
	self.callbacks:Fire("HealComm_Hotupdate", roster:GetUnitIDFromName(self.savetarget), "Regrowth")
end

function HealComm:SPELLCAST_STOP()
	if not self.SpellCastInfo then return end
	local targetUnit = roster:GetUnitIDFromName(self.SpellCastInfo[3])
	if targetUnit then
		if self.SpellCastInfo[1] == L["Renew"] then
			local dur = getSetBonus() and 18 or 15
			self:SendAddonMessage("Renew/"..self.SpellCastInfo[3].."/"..dur.."/")
			if not self.Hots[self.SpellCastInfo[3]] then
				self.Hots[self.SpellCastInfo[3]] = {}
			end
			if not self.Hots[self.SpellCastInfo[3]]["Renew"] then
				self.Hots[self.SpellCastInfo[3]]["Renew"]= {}
			end
			self.Hots[self.SpellCastInfo[3]]["Renew"].start = GetTime()
			self.Hots[self.SpellCastInfo[3]]["Renew"].dur = dur
			recordOwnHot(self, self.SpellCastInfo[3], "Renew", L["Renew"], self.SpellCastInfo[2], self.SpellCastInfo[4], self.SpellCastInfo[5])
			self.callbacks:Fire("HealComm_Hotupdate", targetUnit, "Renew")
		elseif self.SpellCastInfo[1] == L["Rejuvenation"] then
			local dur = getSetBonus() and 15 or 12
			self:SendAddonMessage("Reju/"..self.SpellCastInfo[3].."/"..dur.."/")
			if not self.Hots[self.SpellCastInfo[3]] then
				self.Hots[self.SpellCastInfo[3]] = {}
			end
			if not self.Hots[self.SpellCastInfo[3]]["Reju"] then
				self.Hots[self.SpellCastInfo[3]]["Reju"]= {}
			end
			self.Hots[self.SpellCastInfo[3]]["Reju"].start = GetTime()
			self.Hots[self.SpellCastInfo[3]]["Reju"].dur = dur
			recordOwnHot(self, self.SpellCastInfo[3], "Reju", L["Rejuvenation"], self.SpellCastInfo[2], self.SpellCastInfo[4], self.SpellCastInfo[5])
			self.callbacks:Fire("HealComm_Hotupdate", targetUnit, "Rejuvenation")
		elseif self.SpellCastInfo[1] == L["Regrowth"] then
			self.savetarget = self.SpellCastInfo[3]
			self.saverank, self.savepower, self.savemod = self.SpellCastInfo[2], self.SpellCastInfo[4], self.SpellCastInfo[5]
			schedule(self, "TriggerRegrowthHot", self.TriggerRegrowthHot, 0.3, 1, self)
		end
	end
	self.CurrentSpellRank = nil
	self.CurrentSpellName =  nil
	for key in pairs(self.SpellCastInfo) do
		self.SpellCastInfo[key] = nil
	end
end

function HealComm:CHAT_MSG_ADDON()
	if arg1 == "HealComm" and arg4 ~= UnitName("player") then
		local result = strsplit(arg2,"/")
		if result[1] == "Heal" then
			self:startHeal(arg4, result[2], result[3], result[4])
		elseif arg2 == "Healstop" then
			self:stopHeal(arg4)
		elseif result[1] == "Healdelay" then
			self:delayHeal(arg4, result[2])
		elseif result[1] == "Resurrection" and result[2] == "stop" then
			self:cancelResurrection(arg4)
		elseif result[1] == "Resurrection" and result[3] == "start" then
			self:startResurrection(arg4, result[2])
		elseif result[1] == "GrpHeal" then
			self:startGrpHeal(arg4, result[2], result[3], result[4], result[5], result[6], result[7], result[8])
		elseif arg2 == "GrpHealstop" then
			self:stopGrpHeal(arg4)
		elseif result[1] == "GrpHealdelay" then
			self:delayGrpHeal(arg4, result[2])
		elseif result[1] == "Renew" then
			if not self.Hots[result[2]] then
				self.Hots[result[2]] = {}
			end
			if not self.Hots[result[2]]["Renew"] then
				self.Hots[result[2]]["Renew"]= {}
			end
			self.Hots[result[2]]["Renew"].dur = result[3]
			self.Hots[result[2]]["Renew"].start = GetTime()
			estimateHot(self, result[2], "Renew", L["Renew"], arg4)
			local targetUnit = roster:GetUnitIDFromName(result[2])
			self.callbacks:Fire("HealComm_Hotupdate", targetUnit, "Renew")
		elseif result[1] == "Reju" then
			if not self.Hots[result[2]] then
				self.Hots[result[2]] = {}
			end
			if not self.Hots[result[2]]["Reju"] then
				self.Hots[result[2]]["Reju"]= {}
			end
			self.Hots[result[2]]["Reju"].dur = result[3]
			self.Hots[result[2]]["Reju"].start = GetTime()
			estimateHot(self, result[2], "Reju", L["Rejuvenation"], arg4)
			local targetUnit = roster:GetUnitIDFromName(result[2])
			self.callbacks:Fire("HealComm_Hotupdate", targetUnit, "Rejuvenation")
		elseif result[1] == "Regr" then
			if not self.Hots[result[2]] then
				self.Hots[result[2]] = {}
			end
			if not self.Hots[result[2]]["Regr"] then
				self.Hots[result[2]]["Regr"]= {}
			end
			self.Hots[result[2]]["Regr"].dur = result[3]
			self.Hots[result[2]]["Regr"].start = GetTime()
			estimateHot(self, result[2], "Regr", L["Regrowth"], arg4)
			local targetUnit = roster:GetUnitIDFromName(result[2])
			self.callbacks:Fire("HealComm_Hotupdate", targetUnit, "Regrowth")
		end
	end
end

-- Ace3v: a HoT's real tick, read from the combat log with the client's own
-- format strings (so any locale works), replaces the formula or estimate for
-- the rest of that HoT, and re-aligns its start on the tick. No message is sent
-- for a tick on a unit at full health, so the value then stays as it was.
local HOT_KEYS = { [L["Renew"]] = "Renew", [L["Rejuvenation"]] = "Reju", [L["Regrowth"]] = "Regr" }

-- The four tick messages: "You gain 10 health from Rejuvenation." etc.
local function parseHotTick(msg)
	local me = UnitName("player")
	local target, amount, caster, spell
	if PERIODICAURAHEALOTHEROTHER then
		target, amount, caster, spell = Deformat(msg, PERIODICAURAHEALOTHEROTHER)
		if target then return target, amount, caster, spell end
	end
	if PERIODICAURAHEALOTHERSELF then
		amount, caster, spell = Deformat(msg, PERIODICAURAHEALOTHERSELF)
		if amount then return me, amount, caster, spell end
	end
	if PERIODICAURAHEALSELFOTHER then
		target, amount, spell = Deformat(msg, PERIODICAURAHEALSELFOTHER)
		if target then return target, amount, me, spell end
	end
	if PERIODICAURAHEALSELFSELF then
		amount, spell = Deformat(msg, PERIODICAURAHEALSELFSELF)
		if amount then return me, amount, me, spell end
	end
end
HealComm.parseHotTick = parseHotTick

function HealComm:HotTickMessage()
	local target, amount, caster, spell = parseHotTick(arg1 or "")
	local key = spell and HOT_KEYS[spell]
	amount = tonumber(amount)
	if not key or not amount then return end
	local hot = self.Hots[target] and self.Hots[target][key]
	if not hot or hot.caster ~= caster or not hot.interval or not hot.start then return end
	hot.tick = amount
	local now = GetTime()
	local ticks = math.floor((now - hot.start) / hot.interval + 0.5)
	if ticks < 1 then ticks = 1 end
	hot.start = now - ticks * hot.interval
	self.callbacks:Fire("HealComm_Hotupdate", roster:GetUnitIDFromName(target), spell)
end

function HealComm:UNIT_AURA()
	local name = UnitName(arg1)
	if self.Hots[name] and (self.Hots[name]["Regr"] or self.Hots[name]["Reju"] or self.Hots[name]["Renew"]) then
		local regr,reju,renew
		for i=1,32 do
			if not UnitBuff(arg1,i) then
				break
			end
			healcommTip:ClearLines()
			scanTip():SetUnitBuff(arg1,i)
			regr = regr or healcommTipTextLeft1:GetText() == L["Regrowth"]
			reju = reju or healcommTipTextLeft1:GetText() == L["Rejuvenation"]
			renew = renew or healcommTipTextLeft1:GetText() == L["Renew"]
		end
		-- Ace3v: HealComm-1.0 fired the callback for every HoT not on the unit,
		-- on every UNIT_AURA, even when it had none recorded; only a HoT that
		-- was recorded and is gone fires now.
		if not regr and self.Hots[name]["Regr"] then
			self.Hots[name]["Regr"] = nil
			self.callbacks:Fire("HealComm_Hotupdate", arg1, "Regrowth")
		end
		if not reju and self.Hots[name]["Reju"] then
			self.Hots[name]["Reju"] = nil
			self.callbacks:Fire("HealComm_Hotupdate", arg1, "Rejuvenation")
		end
		if not renew and self.Hots[name]["Renew"] then
			self.Hots[name]["Renew"] = nil
			self.callbacks:Fire("HealComm_Hotupdate", arg1, "Renew")
		end			
	end
end

function HealComm:getRegrTime(unit)
	if unit == UNKNOWNOBJECT or unit == UNKNOWNBEING then
		return
 	end
	local dbUnit = self.Hots[UnitName(unit)]
	if dbUnit and dbUnit["Regr"] and (dbUnit["Regr"].start + dbUnit["Regr"].dur) > GetTime() then
		return dbUnit["Regr"].start, dbUnit["Regr"].dur
	else
		return
	end
end
	
function HealComm:getRejuTime(unit)
	if unit == UNKNOWNOBJECT or unit == UNKNOWNBEING then
		return
 	end
	local dbUnit = self.Hots[UnitName(unit)]
	if dbUnit and dbUnit["Reju"] and (dbUnit["Reju"].start + dbUnit["Reju"].dur) > GetTime() then
		return dbUnit["Reju"].start, dbUnit["Reju"].dur
	else
		return
	end
end

function HealComm:getRenewTime(unit)
	if unit == UNKNOWNOBJECT or unit == UNKNOWNBEING then
		return
 	end
	local dbUnit = self.Hots[UnitName(unit)]
	if dbUnit and dbUnit["Renew"] and (dbUnit["Renew"].start + dbUnit["Renew"].dur) > GetTime() then
		return dbUnit["Renew"].start, dbUnit["Renew"].dur
	else
		return
	end
end

function HealComm:getHeal(unit)
	if unit == UNKNOWNOBJECT or unit == UNKNOWNBEING then
		return 0
 	end
	local healamount = 0
	if self.Heals[unit] then
		for k,v in pairs(self.Heals[unit]) do
			healamount = healamount+v.amount
		end
	end
	for k,v in pairs(self.GrpHeals) do
		for j,c in pairs(v.targets) do
			if unit == c then
				healamount = healamount+v.amount
			end
		end
	end
	return healamount
end

function HealComm:UnitisResurrecting(unit)
	local resstime
	if self.pendingResurrections[unit] then
		for k,v in pairs(self.pendingResurrections[unit]) do
			if v < GetTime() then
				self.pendingResurrections[unit][k] = nil
			elseif not resstime or resstime > v then
				resstime = v
			end
		end
	end
	return resstime
end

function HealComm:getNumHeals(unit)
	if unit == UNKNOWNOBJECT or unit == UNKNOWNBEING then
		return 0
 	end
	local heals = 0
	if self.Heals[unit] then
		for _ in pairs(self.Heals[unit]) do
			heals = heals + 1
		end
	end
	for _,v in pairs(self.GrpHeals) do
		for _,c in pairs(v.targets) do
			if unit == c then
				heals = heals + 1
			end
		end
	end
	return heals
end


function HealComm:CastSpell(spellId, spellbookTabNum)
	self.worldClickSpell = nil
	self.hooks.CastSpell(spellId, spellbookTabNum)
	
	if self.failed or (self.CurrentSpellName and not SpellIsTargeting()) then
		self.failed = nil
		return
	end
	
	-- Rankless spells (Find Minerals, ...) return a nil rank on Unreal Azeroth.
	local spellName, rank = GetSpellName(spellId, spellbookTabNum)
	if rank then
		_,_,rank = string.find(rank,"(%d+)")
	end
	
	if not (self.Spells[spellName] or Resurrections[spellName] or Hots[spellName]) then return end

	self.CurrentSpellName = spellName
	self.CurrentSpellRank = rank
	if not SpellIsTargeting() then
		if ( UnitIsVisible("target") and UnitIsConnected("target") and UnitCanAssist("player", "target") ) then
			-- Spell is being cast on the current target.  
			if UnitIsPlayer("target") then
				self:ProcessSpellCast("target")
			end
		else
			self:ProcessSpellCast("player")
		end
	end
end

function HealComm:CastSpellByName(spellName, onSelf)
	self.worldClickSpell = nil
	self.hooks.CastSpellByName(spellName, onSelf)
	
	if self.failed then
		self.failed = nil
		return
	end
	
	if (self.CurrentSpellName and not SpellIsTargeting()) or (GetCVar("AutoSelfCast") == "0" and onSelf ~= 1 and not SpellIsTargeting() and not (UnitExists("target") and UnitCanAssist("player", "target"))) then return end
	
	local _,_,rank = string.find(spellName,"(%d+)")
	local _, _, spellName = string.find(spellName, "^([^%(]+)")
	spellName = string.lower(spellName)
	local i = 1
	while GetSpellName(i, BOOKTYPE_SPELL) do
		local s, r = GetSpellName(i, BOOKTYPE_SPELL)
		if string.lower(s) == spellName then
			spellName = s
			if rank then
				break
			else
				while s == spellName do
					rank = r
					i = i+1
					s, r = GetSpellName(i, BOOKTYPE_SPELL)
				end
				break
			end
		end
		i = i+1
	end
	if rank then
		_,_,rank = string.find(rank,"(%d+)")
	end
	if spellName then
		if not (self.Spells[spellName] or Resurrections[spellName] or Hots[spellName]) then return end
		self.CurrentSpellName = spellName
		self.CurrentSpellRank = rank
		
		if not SpellIsTargeting() then
			if UnitIsVisible("target") and UnitIsConnected("target") and UnitCanAssist("player", "target") and onSelf ~= 1 then
				if UnitIsPlayer("target") then
					self:ProcessSpellCast("target")
				end
			else
				self:ProcessSpellCast("player")
			end
		end
	end
end

-- A left click in the 3D world (Unreal Azeroth only). Under a spell cursor
-- that client reports no "mouseover" for any unit at the click and shows no
-- tooltip, so the target cannot be read here: the click is only remembered and
-- SPELLCAST_START resolves it. By then the spell cursor is gone and the unit
-- under the cursor is "mouseover" again (UPDATE_MOUSEOVER_UNIT arrives before
-- SPELLCAST_START). The own character never gives a "mouseover" on Unreal
-- Azeroth, and a click on empty ground starts no cast, so a cast that follows a
-- world click without a "mouseover" is on the player. OnMouseDown still runs
-- first, in case the client does report a "mouseover" at the click.
function HealComm:CameraOrSelectOrMoveStart(a1)
	self:OnMouseDown()
	if self.CurrentSpellName and SpellIsTargeting() and not self.SpellCastInfo[3] then
		self.worldClickSpell = self.CurrentSpellName
	end
	self.hooks.CameraOrSelectOrMoveStart(a1)
end

-- Resolves a world click remembered by CameraOrSelectOrMoveStart, at the start
-- of the cast it triggered. A "mouseover" that is not a player (an NPC) records
-- nothing, as on every other cast path.
function HealComm:ResolveWorldClick(spellName)
	local pending = self.worldClickSpell
	self.worldClickSpell = nil
	if pending and pending == spellName and self.CurrentSpellName and not self.SpellCastInfo[3] then
		if UnitExists("mouseover") then
			if UnitIsPlayer("mouseover") then
				self:ProcessSpellCast("mouseover")
			end
		else
			self:ProcessSpellCast("player")
		end
	end
end

function HealComm:OnMouseDown()
	local unit = "mouseover"
	if ( self.CurrentSpellName and GameTooltipTextLeft1:IsVisible() ) then
		local _, _, name = string.find(GameTooltipTextLeft1:GetText(), L["^Corpse of (.+)$"])
		if ( name ) then
			unit = roster:GetUnitIDFromName(name)
		end
	end
	-- Ace3v: players only, like every other cast path (HealComm-1.0 recorded
	-- any unit here, so a heal on an NPC was predicted and broadcast).
	if ( self.CurrentSpellName and SpellIsTargeting() and UnitExists(unit) and UnitIsPlayer(unit) ) then
		self:ProcessSpellCast(unit)
	end
end

function HealComm:UseAction(slot, checkCursor, onSelf)
	self.worldClickSpell = nil
	healcommTip:ClearLines()
	scanTip():SetAction(slot)
	local spellName = healcommTipTextLeft1:GetText()
	
	self.hooks.UseAction(slot, checkCursor, onSelf)
	
	-- Test to see if this is a macro
	if self.failed or GetActionText(slot) or (self.CurrentSpellName and not SpellIsTargeting()) or not (self.Spells[spellName] or Resurrections[spellName] or Hots[spellName]) then
		self.failed = nil
		return
	end
	
	self.CurrentSpellName = spellName
	local rank = healcommTipTextRight1:GetText()
	if rank then
		_,_,rank = string.find(rank,"(%d+)")
	end
	self.CurrentSpellRank = rank or 1
	
	if not SpellIsTargeting() then
		if ( UnitIsVisible("target") and UnitIsConnected("target") and UnitCanAssist("player", "target") and onSelf ~= 1) then
			-- Spell is being cast on the current target
			if UnitIsPlayer("target") then
				self:ProcessSpellCast("target")
			end
		else
			-- Spell is being cast on the player
			self:ProcessSpellCast("player")
		end
	end
end

function HealComm:SpellTargetUnit(unit)
	local shallTargetUnit
	if ( SpellIsTargeting() ) then
		shallTargetUnit = true
	end
	self.hooks.SpellTargetUnit(unit)
	
	if ( shallTargetUnit and self.CurrentSpellName and not SpellIsTargeting() ) then
		if UnitIsPlayer(unit) then
			self:ProcessSpellCast(unit)
		end
		self.CurrentSpellName = nil
		self.CurrentSpellRank = nil
	end
end

function HealComm:SpellStopTargeting()
	self.hooks.SpellStopTargeting()
	self.worldClickSpell = nil
	self.CurrentSpellName = nil
	self.CurrentSpellRank = nil
end

function HealComm:TargetUnit(unit)
	-- Look to see if we're currently waiting for a target internally
	-- If we are, then well glean the target info here.
	if ( self.CurrentSpellName and UnitExists(unit) ) and UnitIsPlayer(unit) then
		self:ProcessSpellCast(unit)
	end
	self.hooks.TargetUnit(unit)
end

function HealComm:ProcessSpellCast(unit)
	local power, mod = self:GetUnitSpellPower(unit, self.CurrentSpellName)
	self.SpellCastInfo[1] = (self.SpellCastInfo[1] or self.CurrentSpellName)
	self.SpellCastInfo[2] = (self.SpellCastInfo[2] or self.CurrentSpellRank)
	self.SpellCastInfo[3] = (self.SpellCastInfo[3] or UnitName(unit))
	self.SpellCastInfo[4] = (self.SpellCastInfo[4] or power)
	self.SpellCastInfo[5] = (self.SpellCastInfo[5] or mod)
end

-- HealComm-1.0 did this from external() as soon as AceEvent-2.0 appeared.
HealComm:RegisterEvent("SPELLCAST_START")
HealComm:RegisterEvent("SPELLCAST_INTERRUPTED")
HealComm:RegisterEvent("SPELLCAST_FAILED")
HealComm:RegisterEvent("SPELLCAST_DELAYED")
HealComm:RegisterEvent("SPELLCAST_STOP")
HealComm:RegisterEvent("CHAT_MSG_ADDON")
HealComm:RegisterEvent("UNIT_AURA")
HealComm:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS", "HotTickMessage")
HealComm:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS", "HotTickMessage")
HealComm:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS", "HotTickMessage")
HealComm:RegisterEvent("UNIT_HEALTH")
HealComm:RegisterEvent("PLAYER_LOGIN")
HealComm.callbacks:Fire("HealComm_Enabled")

-- On a mid-session upgrade PLAYER_LOGIN will not fire again, so re-hook now.
if HealComm.hooked then
	HealComm.hooked = nil
	HealComm:PLAYER_LOGIN()
end
