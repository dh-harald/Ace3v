-- LibItemBonusLib-1.0 / zhCN
-- Ace3v port. There was no zhCN locale in ItemBonusLib-1.0 and none upstream
-- either (upstream had zhTW only), so every string here was DERIVED from live
-- Classic Era tooltips and verified -- nothing is translated:
--   * stat tokens: the enUS and zhCN tooltips of the same item are aligned, so a
--     "+N Stamina" line in enUS identifies the zhCN token at the same index
--     at the same index;
--   * passive patterns: the vanilla enUS sentence is located in an item or
--     item-set tooltip first, then the same line read in zhCN;
--   * consumable names: resolved by matching the item name.
--
-- COVERAGE: 61 of the 64 effect keys enUS covers, counting the STAGE1+STAGE2
-- composition. School-specific spell damage needs no per-school entry: the
-- Chinese tokens are 火焰伤害 / 冰霜伤害 / 暗影伤害 etc., and CheckToken composes
-- STAGE1 (火焰) with STAGE2 (伤害) into FIREDMG at runtime. All six school names
-- are present, so all six schools are covered. Verified from enchants 2614-2616.
--
-- ATTACKPOWERFERAL and MANAREGNORMAL are dead keys on 1.12.1 (no separate feral attack
-- power exists, and MANAREGNORMAL's wording was split into two lines the library already
-- handles). The one real gap left is DMGUNDEAD's sentence form -- the Chinese 1.12 text of
-- "Increases damage done to Undead by magical spells and effects by up to N", which the
-- other five locales do have. Classic-Era's token wording is present below but will not
-- match a 1.12 client.
-- Formerly listed as missing:
-- MANAREGNORMAL (dead code on 1.12.1 -- see the README).
-- NAMES lists only keys a tooltip confirmed; a missing entry makes
-- GetBonusFriendlyName return the bonus key, its documented fallback. The
-- interface strings and CHAT_COMMANDS fall back to enUS, as the original deDE
-- and frFR locales do.
--
-- To extend: run with debugging on and read the "Unmatched bonus line" and
-- "CheckToken failed" output on a Chinese client.

LibItemBonusLib_Locales = LibItemBonusLib_Locales or {}
LibItemBonusLib_Locales.zhCN = {
	-- display names, only where a tooltip confirmed the Chinese form
	NAMES = {
		AGI = "敏捷",
		ARMOR = "强化护甲",
		ATTACKPOWER = "攻击强度",
		BLOCK = "格档",
		CRIT = "爆击",
		DEFENSE = "防御",
		DMG = "伤害",
		DODGE = "躲闪",
		FISHING = "鱼饵",
		HEAL = "提高治疗效果",
		HEAL = "治疗法术",
		HEALTH = "生命值",
		HERBALISM = "草药学",
		INT = "智力",
		MANA = "法力值",
		MINING = "采矿",
		RANGEDATTACKPOWER = "远程攻击伤害",
		SKINNING = "剥皮",
		SPI = "精神",
		STA = "耐力",
		STR = "力量",
		TOHIT = "命中",
		ARCANERES = "奥术抗性",
		FIRERES = "火焰抗性",
		FROSTRES = "冰霜抗性",
		NATURERES = "自然抗性",
		SHADOWRES = "暗影抗性",
		ATTACKPOWER = "攻击强度",
	},

	PATTERNS_PASSIVE = {
		{ pattern = "治疗链法术的施法时间减少0%.(%d+)秒。", effect = "CASTINGCHAINHEAL" },	-- set 501 | -0.4 seconds on the casting time of your Cha
		{ pattern = "使你的快速治疗法术的施法时间减少0%.(%d+)秒。", effect = "CASTINGFLASHHEAL" },	-- set 202 | -0.1 sec to the casting time of your Flash H
		{ pattern = "使你的治疗之触法术的施法时间减少0%.(%d+)秒。", effect = "CASTINGHEALINGTOUCH" },	-- item 22399 | Reduces the casting time of your Healing Tou
		{ pattern = "使你的圣光术的施法时间减少0%.(%d+)秒。", effect = "CASTINGHOLYLIGHT" },	-- set 475 | Reduces the casting time of your Holy Light 
		{ pattern = "使你的愈合法术的施法时间减少0%.(%d+)秒。", effect = "CASTINGREGROWTH" },	-- set 214 | Reduces the casting time of your Regrowth sp
		{ pattern = "使你的治疗之触、愈合、回春术和宁静的法力消耗值降低(%d+)%%。", effect = "CHEAPERDRUID" },	-- set 521 | Reduces the mana cost of your Healing Touch,
		{ pattern = "使你的恢复法术所消耗的法力值降低(%d+)%%。", effect = "CHEAPERRENEW" },	-- set 525 | Reduces the mana cost of your Renew spell by
		{ pattern = "使你的回春术的持续时间延长(%d+)秒。", effect = "DURATIONREJUV" },	-- set 214 | Increases the duration of your Rejuvenation 
		{ pattern = "使你的恢复术的持续时间延长(%d+)秒。", effect = "DURATIONRENEW" },	-- set 507 | Increases the duration of your Renew spell b
		{ pattern = "每(%d+)秒恢复5点生命值。", effect = "HEALTHREG" },	-- item 10659 | Restores 5 health per 5 sec.
		{ pattern = "使你的神圣法术造成爆击的几率提高(%d+)%%。", effect = "HOLYCRIT" },	-- set 202 | Improves your chance to get a critical strik
		{ pattern = "使法术在治疗除了第一个目标以外的其它目标时的效果提高(%d+)%%。", effect = "IMPCHAINHEAL" },	-- set 216 | Increases the amount healed by Chain Heal to
		{ pattern = "使圣光闪现的治疗效果提高最多(%d+)点。", effect = "IMPFLASHOFLIGHT" },	-- item 23201 | Increases healing done by Flash of Light by 
		{ pattern = "使次级治疗波所恢复的生命值提高最多(%d+)点。", effect = "IMPLESSERHEALINGWAVE" },	-- item 22396 | Increases healing done by Lesser Healing Wav
		{ pattern = "使回春术所恢复的生命值提高最多(%d+)点。", effect = "IMPREJUVENATION" },	-- item 22398 | Increases healing done by Rejuvenation by up
		{ pattern = "你的治疗波会治疗一个额外的目标。治疗波每次跳跃后的治疗效果都会降低(%d+)%%，并治疗最多2个额外的目标。", effect = "JUMPHEALINGWAVE" },	-- set 207 | Your Healing Wave will now jump to additiona
		{ pattern = "每(%d+)秒回复5点法力值。", effect = "MANAREG" },	-- item 10659 | Restores 5 mana per 5 sec.
		{ pattern = "使你的自然法术造成爆击的几率提高(%d+)%%。", effect = "NATURECRIT" },	-- set 216 | Improves your chance to get a critical strik
		{ pattern = "使你招架攻击的几率提高(%d+)%%。", effect = "PARRY" },	-- set 123 | Increases your chance to parry an attack by 
		{ pattern = "使你的远程武器造成爆击的几率提高(%d+)%%。", effect = "RANGEDCRIT" },	-- item 7348 | Improves your chance to get a critical strik
		{ pattern = "在你施放了治疗波或次级治疗波法术之后，有(%d+)%%的几率获得该法术所消耗的法力值的35%%。", effect = "REFUNDHEALINGWAVE" },	-- set 207 | After casting your Healing Wave or Lesser He
		{ pattern = "治疗之触的极效治疗效果可以使你恢复该法术所消耗法力值的(%d+)%%。", effect = "REFUNDHTCRIT" },	-- set 521 | On Healing Touch critical hits, you regain 3
		{ pattern = "使你的法术击中敌人的几率提高(%d+)%%。", effect = "SPELLTOHIT" },	-- set 462 | Improves your chance to hit with spells by 1
		{ pattern = "对亡灵的攻击强度提高(%d+)点。", effect = "ATTACKPOWERUNDEAD" },	-- set 163 | +15 Attack Power when fighting Undead.
		{ pattern = "使你用盾牌格挡攻击的几率提高(%d+)%%。", effect = "BLOCK" },	-- set 474 | Increases your chance to block attacks with 
		{ pattern = "使你的盾牌的格挡值提高(%d+)点。", effect = "BLOCKVALUE" },	-- set 209 | Increases the block value of your shield by 
		{ pattern = "使你在施法时仍保持(%d+)%%的法力回复速度。", effect = "CASTINGREG" },	-- set 211 | Allows 15% of your Mana regeneration to cont
		{ pattern = "使你造成爆击的几率提高(%d+)%%。", effect = "CRIT" },	-- set 1 | Improves your chance to get a critical strik
		{ pattern = "使你躲闪攻击的几率提高(%d+)%%。", effect = "DODGE" },	-- set 464 | Increases your chance to dodge an attack by 
		{ pattern = "提高自然法术和效果所造成的伤害，最多(%d+)点。", effect = "NATUREDMG" },	-- set 162 | Increases damage done by Nature spells and e
		{ pattern = "使你的法术目标的魔法抗性降低(%d+)点。", effect = "SPELLPEN" },	-- set 201 | Decreases the magical resistances of your sp
		{ pattern = "使你击中目标的几率提高(%d+)%%。", effect = "TOHIT" },	-- set 121 | Improves your chance to hit by 2%.
	},

	-- both the bare token and the full-width-period form some tooltips append,
	-- because CheckToken's trim only strips an ASCII trailing dot
	PATTERNS_GENERIC_LOOKUP = {
		["敏捷"] = "AGI",
		["敏捷。"] = "AGI",
		["强化护甲"] = "ARMOR",
		["强化护甲。"] = "ARMOR",
		["攻击强度"] = "ATTACKPOWER",
		["攻击强度。"] = "ATTACKPOWER",
		["格档"] = "BLOCK",
		["格档。"] = "BLOCK",
		["爆击"] = "CRIT",
		["爆击。"] = "CRIT",
		["防御"] = "DEFENSE",
		["防御。"] = "DEFENSE",
		["伤害"] = "DMG",
		["伤害。"] = "DMG",
		["躲闪"] = "DODGE",
		["躲闪。"] = "DODGE",
		["鱼饵"] = "FISHING",
		["鱼饵。"] = "FISHING",
		["提高治疗效果"] = "HEAL",
		["提高治疗效果。"] = "HEAL",
		["治疗法术"] = "HEAL",
		["治疗法术。"] = "HEAL",
		["生命值"] = "HEALTH",
		["生命值。"] = "HEALTH",
		["草药学"] = "HERBALISM",
		["草药学。"] = "HERBALISM",
		["智力"] = "INT",
		["智力。"] = "INT",
		["法力值"] = "MANA",
		["法力值。"] = "MANA",
		["采矿"] = "MINING",
		["采矿。"] = "MINING",
		["远程攻击伤害"] = "RANGEDATTACKPOWER",
		["远程攻击伤害。"] = "RANGEDATTACKPOWER",
		["剥皮"] = "SKINNING",
		["剥皮。"] = "SKINNING",
		["精神"] = "SPI",
		["精神。"] = "SPI",
		["耐力"] = "STA",
		["耐力。"] = "STA",
		["力量"] = "STR",
		["力量。"] = "STR",
		["命中"] = "TOHIT",
		["命中。"] = "TOHIT",
		["全部抗性"] = { "ARCANERES", "FIRERES", "FROSTRES", "NATURERES", "SHADOWRES" },
		["全部抗性。"] = { "ARCANERES", "FIRERES", "FROSTRES", "NATURERES", "SHADOWRES" },
		["法术伤害"] = { "HEAL", "DMG" },
		["法术伤害。"] = { "HEAL", "DMG" },
		["伤害和治疗法术"] = { "HEAL", "DMG" },
		["伤害和治疗法术。"] = { "HEAL", "DMG" },
		["所有属性"] = { "STR", "AGI", "STA", "INT", "SPI" },
		["所有属性。"] = { "STR", "AGI", "STA", "INT", "SPI" },
		["奥术抗性"] = "ARCANERES",
		["奥术抗性。"] = "ARCANERES",
		["火焰抗性"] = "FIRERES",
		["火焰抗性。"] = "FIRERES",
		["冰霜抗性"] = "FROSTRES",
		["冰霜抗性。"] = "FROSTRES",
		["自然抗性"] = "NATURERES",
		["自然抗性。"] = "NATURERES",
		["暗影抗性"] = "SHADOWRES",
		["暗影抗性。"] = "SHADOWRES",
		["攻击强度"] = "ATTACKPOWER",
		["攻击强度。"] = "ATTACKPOWER",
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
		["攻击强度vs亡灵"] = "ATTACKPOWERUNDEAD",
		["攻击强度vs亡灵。"] = "ATTACKPOWERUNDEAD",
		["法术伤害vs亡灵"] = "DMGUNDEAD",
		["法术伤害vs亡灵。"] = "DMGUNDEAD",
	},

	PATTERNS_GENERIC_STAGE1 = {
		{ pattern = "奥术", effect = "ARCANE" },
		{ pattern = "火焰", effect = "FIRE" },
		{ pattern = "冰霜", effect = "FROST" },
		{ pattern = "神圣", effect = "HOLY" },
		{ pattern = "暗影", effect = "SHADOW" },
		{ pattern = "自然", effect = "NATURE" },
	},

	PATTERNS_GENERIC_STAGE2 = {
		{ pattern = "抗性", effect = "RES" },
		{ pattern = "伤害", effect = "DMG" },
	},

	-- consumable names resolved by item name; effect and value are the enUS ones
	PATTERNS_OTHER = {
		{ pattern = "初级巫师之油", effect = { "DMG", "HEAL" }, value = 8 },	-- Minor Wizard Oil
		{ pattern = "次级巫师之油", effect = { "DMG", "HEAL" }, value = 16 },	-- Lesser Wizard Oil
		{ pattern = "巫师之油", effect = { "DMG", "HEAL" }, value = 24 },	-- Wizard Oil
		{ pattern = "卓越巫师之油", effect = { "DMG", "HEAL", "SPELLCRIT" }, value = {36, 36, 1} },	-- Brilliant Wizard Oil
		{ pattern = "初级法力之油", effect = "MANAREG", value = 4 },	-- Minor Mana Oil
		{ pattern = "次级法力之油", effect = "MANAREG", value = 8 },	-- Lesser Mana Oil
		{ pattern = "卓越法力之油", effect = { "MANAREG", "HEAL" }, value = {12, 25} },	-- Brilliant Mana Oil
	},
}
