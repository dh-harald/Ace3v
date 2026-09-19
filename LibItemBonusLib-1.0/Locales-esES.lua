-- LibItemBonusLib-1.0 / esES
-- Ace3v port. Spanish strings come from upstream ItemBonusLib r54839 (WowAce,
-- 2007-11-15), contributed by "bailon"; see docs/library-status.md.
-- Filtered to vanilla 1.12.1: the TBC-only PATTERNS_SKILL_RATING table is
-- dropped, and every entry kept here references only bonus keys that the
-- vanilla enUS locale defines.
--
-- The subcommand words (show/details/item/slot) and CHAT_COMMANDS are
-- deliberately not translated -- they fall back to enUS, as in deDE and frFR.
--
-- COVERAGE: NAMES complete (44/44); PATTERNS_GENERIC_LOOKUP complete, so the
-- ordinary "+10 Aguante" stat lines parse on every item. PATTERNS_PASSIVE now
-- covers all but two bonus keys; PATTERNS_OTHER is 4 of 13.
--
-- MANAREGNORMAL has no esES pattern on purpose: it is dead code on 1.12.1. Its
-- enUS pattern expects the old combined wording "Increases your normal health
-- and mana regeneration by N", which the client no longer renders -- item 10659
-- shows two separate lines instead ("Restores N mana per 5 sec." / "...health
-- per 5 sec."), and the library already covers those under MANAREG/HEALTHREG.
-- So nothing is lost by leaving it unset.
--
-- CAVEAT: these patterns are derived from Classic Era tooltips, which are not
-- always worded exactly as vanilla 1.12. One proven case: the CHEAPERDRUID
-- sentence gained a comma and a double space in Classic. So treat a
-- non-matching line as a wording drift, not necessarily a missing pattern; turn
-- debugging on and read the "Unmatched bonus line" output on a Spanish client.

LibItemBonusLib_Locales = LibItemBonusLib_Locales or {}
LibItemBonusLib_Locales.esES = {
	-- interface strings
	["An addon to get information about bonus from equipped items"] = "Un addon para obtener los bonus de los items equipados",
	["Show all bonuses from the current equipment"] = "Muestra los bonus de los items equipados",
	["Current equipment bonuses:"] = "Bonus del equipo actual :",
	["Shows bonuses with slot distribution"] = "Muestra los bonus de cada posición",
	["Current equipment bonus details:"] = "Detalles de los bonus del equipo actual :",
	["show bonuses of given itemlink"] = "Muesra los bonus del objeto indicado",
	["Bonuses for %s:"] = "Bonus de %s :",
	["Item is part of set [%s]"] = "El objeto forma parte del conjunto [%s]",
	[" %sBonus for %d pieces :"] = " %sBonus por %d partes :",
	["show bonuses of given slot"] = "Muestra los bonus de la posición indicada",
	["<slotname>"] = "<posición>",
	["Bonuses of slot %s:"] = "Bonus de la posición %s:",

	-- bonus names
	NAMES = {
		AGI = "Agilidad",
		ARCANEDMG = "Daño Arcano",
		ARCANERES = "Resistencia Arcana",
		ARMOR = "Armadura",
		ATTACKPOWER = "Poder de Ataque",
		ATTACKPOWERFERAL = "Poder de Ataque en forma feral",
		ATTACKPOWERUNDEAD = "Poder de Ataque contra no-muertos",
		BLOCK = "Probabilidad de bloqueo",
		BLOCKVALUE = "Valor de bloqueo",
		CRIT = "Golpes Críticos",
		DEFENSE = "Defensa",
		DMG = "Daño de Hechizo",
		DMGUNDEAD = "Daño de Hechizo contra no-muertos",
		DODGE = "Esquivar",
		FIREDMG = "Daño de Fuego",
		FIRERES = "Resistencia al Fuego",
		FISHING = "Pesca",
		FROSTDMG = "Daño de Escarcha",
		FROSTRES = "Resistencia a la Escarcha",
		HEAL = "Sanación",
		HEALTH = "Puntos de Salud",
		HEALTHREG = "Regeneración de Salud",
		HERBALISM = "Botánica",
		HOLYCRIT = "Cr?tico de Sanación",
		HOLYDMG = "Daño Sagrado",
		INT = "Inteligencia",
		MANA = "Puntos de Maná",
		MANAREG = "Regeneración de Maná",
		MINING = "Minería",
		NATUREDMG = "Daño de Naturaleza",
		NATURERES = "Resistencia a la Naturaleza",
		PARRY = "Parar",
		RANGEDATTACKPOWER = "Poder de Ataque a distancia",
		RANGEDCRIT = "Disparos Críticos",
		SHADOWDMG = "Daño de Sombras",
		SHADOWRES = "Resistencia a las Sombras",
		SKINNING = "Desuello",
		SPELLCRIT = "Críticos de Hechizo",
		SPELLPEN = "Penetración de Hechizoa",
		SPELLTOHIT = "Probabilidad de golpear con hechizos",
		SPI = "Espíritu",
		STA = "Aguante",
		STR = "Fuerza",
		TOHIT = "Probabilidad de Golpear",
	},

	PATTERNS_PASSIVE = {
		-- derived from live Classic Era item and item-set tooltips, verified by
		-- matching the enUS line first, then translating the result back to English.
		{ pattern = "Mejora tu probabilidad de conseguir un golpe crítico en (%d+)%%%.", effect = "CRIT" },	-- item 19137
		{ pattern = "Mejora tu probabilidad de alcanzar el objetivo en un (%d+)%%%.", effect = "TOHIT" },	-- item 19137
		{ pattern = "Aumenta la probabilidad de esquivar un ataque en un (%d+)%%%.", effect = "DODGE" },	-- item 19406
		{ pattern = "Aumenta la probabilidad de bloquear ataques con un escudo en un (%d+)%%%.", effect = "BLOCK" },	-- item 17066
		{ pattern = "%-0%.(%d+) segundos de tiempo de lanzamiento de tu hechizo Curación en cadena%.", effect = "CASTINGCHAINHEAL" },	-- item-set 501
		{ pattern = "%-0%.(%d+) s de tiempo de lanzamiento de tu hechizo Curación instantánea%.", effect = "CASTINGFLASHHEAL" },	-- item-set 202
		{ pattern = "Reduce el tiempo de lanzamiento de tu hechizo Toque curativo en 0,(%d+) s%.", effect = "CASTINGHEALINGTOUCH" },	-- item 22399
		{ pattern = "Reduce el tiempo de lanzamiento de tu Hechizo de luz Sagrada en 0%.(%d+) s%.", effect = "CASTINGHOLYLIGHT" },	-- item-set 475
		{ pattern = "Reduce el tiempo de lanzamiento de tu hechizo Recrecimiento en 0%.(%d+) s%.", effect = "CASTINGREGROWTH" },	-- item-set 214
		{ pattern = "Reduce el coste de maná de tus hechizos Toque curativo, Recrecimiento, Rejuvenecimiento y Tranquilidad en un (%d+)%%%.", effect = "CHEAPERDRUID" },	-- item-set 521
		{ pattern = "Reduce el coste de maná de tu hechizo Renovar en un (%d+)%%%.", effect = "CHEAPERRENEW" },	-- item-set 525
		{ pattern = "Aumenta en (%d+) segundos la duración de tu hechizo Rejuvenecimiento%.", effect = "DURATIONREJUV" },	-- item-set 214
		{ pattern = "Aumenta en (%d+) segundos la duración de tu hechizo Renovar%.", effect = "DURATIONRENEW" },	-- item-set 507
		{ pattern = "Mejora tu probabilidad de conseguir un golpe crítico en (%d+)%% con los hechizos Sagrados%.", effect = "HOLYCRIT" },	-- item-set 202
		{ pattern = "Aumenta en un (%d+)%% la efectividad del hechizo de curación en cadena a objetivos próximos al primero%.", effect = "IMPCHAINHEAL" },	-- item-set 216
		{ pattern = "Aumenta el daño causado por Destello de Luz hasta en (%d+) p%.", effect = "IMPFLASHOFLIGHT" },	-- item 23201
		{ pattern = "Aumenta el daño causado por Onda inferior de curación hasta en (%d+) p%.", effect = "IMPLESSERHEALINGWAVE" },	-- item 22396
		{ pattern = "Aumenta el daño causado por Rejuvenecimiento hasta en (%d+) p%.", effect = "IMPREJUVENATION" },	-- item 22398
		{ pattern = "Tu Onda de curación saltará a otros objetivos cercanos%. Cada salto reduce la eficacia de la curación en un (%d+)%%%. El hechizo saltará a un máximo de 2 objetivos extra%.", effect = "JUMPHEALINGWAVE" },	-- item-set 207
		{ pattern = "Mejora tu probabilidad de conseguir un golpe crítico en (%d+)%% con los hechizos de Naturaleza%.", effect = "NATURECRIT" },	-- item-set 216
		{ pattern = "Aumenta la probabilidad de parar un ataque en un (%d+)%%%.", effect = "PARRY" },	-- item-set 123
		{ pattern = "Tras haber lanzado un hechizo Onda de curación u Onda inferior de curación, proporciona un (%d+)%% de probabilidad de obtener el 35%% del total de maná consumido en el hechizo%.", effect = "REFUNDHEALINGWAVE" },	-- item-set 207
		{ pattern = "En golpes críticos de Toque de curación recuperarás el (%d+)%% del coste de maná del hechizo%.", effect = "REFUNDHTCRIT" },	-- item-set 521
		{ pattern = "Mejora tu probabilidad de alcanzar el objetivo con hechizos en un (%d+)%%%.", effect = "SPELLTOHIT" },	-- item-set 462
		{ pattern = "Mejora tu probabilidad de conseguir un golpe crítico en (%d+)%% con los misiles%.", effect = "RANGEDCRIT" },	-- item 7348
		{ pattern = "Restaura (%d+) p%. de maná cada 5 s%.", effect = "MANAREG" },	-- item 10659
		{ pattern = "Restaura (%d+) p%. de salud cada 5 s%.", effect = "HEALTHREG" },	-- item 10659

		{ pattern = "Aumenta el poder de ataque a distancia en (%d+)%.", effect = "RANGEDATTACKPOWER" },
		{ pattern = "Aumenta el valor de bloqueo de tu escudo en (%d+)%.", effect = "BLOCKVALUE" },
		{ pattern = "Aumenta el daño de tus hechizos arcanos y los efectos hasta en (%d+)%.", effect = "ARCANEDMG" },
		{ pattern = "Aumenta el daño de tus hechizos de fuego y los efectos hasta en (%d+)%.", effect = "FIREDMG" },
		{ pattern = "Aumenta el daño de tus hechizos de escarcha y los efectos hasta en (%d+)%.", effect = "FROSTDMG" },
		{ pattern = "Aumenta el daño de tus hechizos sagrados y los efectos hasta en (%d+)%.", effect = "HOLYDMG" },
		{ pattern = "Aumenta el daño de tus hechizos de naturaleza y los efectos hasta en (%d+)%.", effect = "NATUREDMG" },
		{ pattern = "Aumenta el daño de tus hechizos de sombras y los efectos hasta en (%d+)%.", effect = "SHADOWDMG" },
		{ pattern = "Aumenta la sanación con hechizos y los efectos hasta en (%d+)%.", effect = "HEAL" },
		{ pattern = "Aumenta el daño a no-muertos con hechizos y los efectos hasta en (%d+)%.", effect = "DMGUNDEAD" },
		{ pattern = "Aumenta el poder de ataque en (%d+) al pelear contra no-muertos%.", effect = "ATTACKPOWERUNDEAD" },
		{ pattern = "Restaura (%d+) salud cada 5 seg%.", effect = "HEALTHREG" },
		{ pattern = "Restaura (%d+) salud cada 5 seg%.", effect = "HEALTHREG" },
		{ pattern = "Restaura (%d+) maná cada 5 seg%.", effect = "MANAREG" },
		{ pattern = "Aumenta el daño con hechizos hasta en (%d+) y la sanación hasta en (%d+)%.", effect = { "DMG", "HEAL" } },
		{ pattern = "Increases healing done by magical spells and effects of all party members within %d+ yards by up to (%d+)%.", effect = "HEAL" },
		{ pattern = "Restores (%d+) mana per 5 seconds to all party members within %d+ yards%.", effect = "MANAREG" },
		{ pattern = "Increases the spell critical chance of all party members within %d+ yards by (%d+)%%%.", effect = "SPELLCRIT" },
		{ pattern = "Allow (%d+)%% of your Mana regeneration to continue while casting%.", effect = "CASTINGREG" },
		{ pattern = "Increases your spell penetration by (%d+)%.", effect = "SPELLPEN" },
		{ pattern = "Aumenta el poder de ataque en (%d+)% p.", effect = "ATTACKPOWER" },
		{ pattern = "Aumenta en +(%d+) p. el poder de ataque bajo formas felinas, de oso, de oso temible y de lechúcico lunar.%.", effect = "ATTACKPOWERFERAL" },
		{ pattern = "Restores (%d+) health every 4 sec%.", effect = "HEALTHREG" },
		{ pattern = "Gives (%d+) additional stamina to party members within %d+ yards%.", effect = "STA" },
	},

	-- both the lowercase form (as upstream stored them) and a capitalised form,
	-- because our CheckToken does not lowercase the tooltip token
	PATTERNS_GENERIC_LOOKUP = {
		["Attack Power when fighting Undead"] = "ATTACKPOWERUNDEAD",
		["Block Value"] = "BLOCKVALUE",
		["Blocking"] = "BLOCK",
		["Bloqueo"] = "BLOCKVALUE",
		["Botánica"] = "HERBALISM",
		["Critical"] = "CRIT",
		["Critical Hit"] = "CRIT",
		["Desuello"] = "SKINNING",
		["Esquivar"] = "DODGE",
		["Fishing Lure"] = "FISHING",
		["Golpe"] = "TOHIT",
		["Golpe con Hechizo"] = "SPELLTOHIT",
		["HP"] = "HEALTH",
		["Healing"] = "HEAL",
		["Healing Spells"] = "HEAL",
		["Health"] = "HEALTH",
		["Increased Defense"] = "DEFENSE",
		["Increased Fishing"] = "FISHING",
		["Increases Healing"] = "HEAL",
		["Mana"] = "MANA",
		["Mana Per 5 sec"] = "MANAREG",
		["Mana Regen"] = "MANAREG",
		["Mana every 5 Sec"] = "MANAREG",
		["Mana every 5 seconds"] = "MANAREG",
		["Mana per 5 Seconds"] = "MANAREG",
		["Minería"] = "MINING",
		["Pesca"] = "FISHING",
		["Poder de Ataque"] = "ATTACKPOWER",
		["Ranged Attack Power"] = "RANGEDATTACKPOWER",
		["Resist All"] = { "ARCANERES", "FIRERES", "FROSTRES", "NATURERES", "SHADOWRES" },
		["Spell Penetration"] = "SPELLPEN",
		["agilidad"] = "AGI",
		["Agilidad"] = "AGI",
		["aguante"] = "STA",
		["Aguante"] = "STA",
		["espíritu"] = "SPI",
		["Espíritu"] = "SPI",
		["fuerza"] = "STR",
		["Fuerza"] = "STR",
		["healing Spells"] = "HEAL",
		["Healing Spells"] = "HEAL",
		["health every 5 sec"] = "HEALTHREG",
		["Health every 5 sec"] = "HEALTHREG",
		["intelecto"] = "INT",
		["Intelecto"] = "INT",
		["mana every 5 sec"] = "MANAREG",
		["Mana every 5 sec"] = "MANAREG",
		["mana per 5 sec"] = "MANAREG",
		["Mana per 5 sec"] = "MANAREG",
		["todas las características"] = { "STR", "AGI", "STA", "INT", "SPI" },
		["Todas las características"] = { "STR", "AGI", "STA", "INT", "SPI" },
		["todas las resistencias"] = { "ARCANERES", "FIRERES", "FROSTRES", "NATURERES", "SHADOWRES" },
		["Todas las resistencias"] = { "ARCANERES", "FIRERES", "FROSTRES", "NATURERES", "SHADOWRES" },
			-- Ace3v: tokens harvested from live Classic Era enchant tooltips, by
		-- aligning the enUS and localized tooltips of the same enchant. Added
		-- only where this
		-- locale had no entry; nothing existing was replaced. Note that the
		-- Classic Era wording can differ from vanilla's -- ruRU in particular
		-- uses post-vanilla "rating" terminology here.
		["de agilidad"] = "AGI",
		["Armadura reforzada"] = "ARMOR",
		["de armadura"] = "ARMOR",
		["Bloquear"] = "BLOCK",
		["Impacto crítico"] = "CRIT",
		["de defensa"] = "DEFENSE",
		["de daño"] = "DMG",
		["Cebo de pesca"] = "FISHING",
		["Pescar"] = "FISHING",
		["Aumenta curación"] = "HEAL",
		["Salud"] = "HEALTH",
		["Herboristería"] = "HERBALISM",
		["de intelecto"] = "INT",
		["Maná"] = "MANA",
		["Excavar"] = "MINING",
		["Desollar"] = "SKINNING",
		["de fuerza"] = "STR",
		["de impacto"] = "TOHIT",
		["Todas las estadísticas"] = { "STR", "AGI", "STA", "INT", "SPI" },
			-- Ace3v: tokens harvested from live Classic Era enchant tooltips, by
		-- aligning the enUS and localized tooltips of the same enchant. Added
		-- only where this
		-- locale had no entry; nothing existing was replaced. Note that the
		-- Classic Era wording can differ from vanilla's -- ruRU in particular
		-- uses post-vanilla "rating" terminology here.
		["Hechizos de curación"] = "HEAL",
		["de daño y Hechizos de curación"] = { "HEAL", "DMG" },
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
		["de poder de ataque contra no-muertos"] = "ATTACKPOWERUNDEAD",
		["de daño de hechizos contra no-muertos"] = "DMGUNDEAD",
	},

	PATTERNS_GENERIC_STAGE1 = {
		{ pattern = "Arcano", effect = "ARCANE" },
		{ pattern = "Fuego", effect = "FIRE" },
		{ pattern = "Escarcha", effect = "FROST" },
		{ pattern = "Sagrado", effect = "HOLY" },
		{ pattern = "Sombras", effect = "SHADOW" },
		{ pattern = "Naturaleza", effect = "NATURE" },
	},

	PATTERNS_GENERIC_STAGE2 = {
		{ pattern = "Resistencia", effect = "RES" },
		{ pattern = "Daño", effect = "DMG" },
		{ pattern = "Efectos", effect = "DMG" },
	},

	PATTERNS_OTHER = {
		{ pattern = "Vitality", effect = { "MANAREG", "HEALTHREG" }, value = {4, 4} },
		{ pattern = "Soulfrost", effect = { "FROSTDMG", "SHADOWDMG" }, value = {54, 54} },
		{ pattern = "Sunfire", effect = { "ARCANEDMG", "FIREDMG" }, value = {50, 50} },
		{ pattern = "Savagery", effect = "ATTACKPOWER", value = 70 },
	},
}
