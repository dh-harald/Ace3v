--[[
Name: LibVanillaThreat-1.0
Author(s): dh-harald
Description: Threat estimation for the 1.12.1 client and Unreal Azeroth,
             which have no threat API: the player's and the pet's threat on
             every mob, rebuilt from the combat log the way the server
             counts it, and the group's over the addon channel.
Dependencies: LibStub, CallbackHandler-1.0

How it works:
  * The library's structure and API follow LibThreatClassic2 (the Classic
    1.13 library from before Blizzard's threat API): per-unit threat tables
    keyed by mob, ThreatUpdated / ThreatCleared callbacks, GetThreat,
    GetMaxThreatOnTarget, IterateGroupThreatForTarget.
  * The numbers and formulas follow the vmangos server (both Unreal Azeroth
    and the Elysium-line 1.12.1 servers derive from it): ThreatManager,
    HostileRefManager::threatAssist, Spell::HandleThreatSpells,
    Spell::EffectThreat and the world database's spell_threat table. The
    data is generated into Spells.lua.
  * 1.12 has no GUIDs: a mob is keyed by its NAME. Two mobs of one name
    share one entry.
  * The combat log is plain localized text. Every line is matched against
    the client's own GlobalStrings format strings (compiled at startup), so
    the parser works on any client language; spell, buff and talent names
    in Spells.lua are English, so threat modifiers and ability bonuses only
    apply on English clients.

Threat, per actor (the player, the pet) and mob (vmangos):
  * damage: amount x spell_threat multiplier x threat modifiers of the
    damage's school;
  * a spell_threat flat bonus and a SPELL_EFFECT_THREAT value (Growl,
    Torment, Distracting Shot, Cower, Feint, ...; base + per level x
    (caster level - spell level), level clamped to base..max level) on a
    landed hit only, x modifiers. A miss reported after the landing line
    takes it back;
  * healing: effective heal x 0.5 (a paladin's direct heal 0.25) x
    spell_threat multiplier, split evenly over the mobs that have the HEALED
    unit on their threat list, x the healer's modifiers. For the player and
    the pet that list is their own threat table; for another group member
    the mobs the group fought recently;
  * a pet's threat creates a zero entry for its owner (the server adds the
    owner to the mob's threat list);
  * death, Feign Death (unless the client reported it resisted) and leaving
    combat clear an actor's table; a mob's death removes its entries.
  Threat modifiers: SPELL_AURA_MOD_THREAT auras, multiplied per school
  (stances, forms, Salvation, Tranquil Air, talents, enchants); a dead
  actor deals none. Direct energize generates no threat on the server.

Effective healing: the combat log reports a heal with its overheal. The
overheal is estimated from the recipient's health deficit at the line,
measured from the value before a health rise seen within the last half
second (the UNIT_HEALTH update may arrive before or after the line) --
the method of MikScrollingBattleText's 1.12.1 / Unreal Azeroth port. Only
exact for group units; other recipients count as fully effective.

Aggro (vmangos ThreatContainer::selectNextVictim): a unit takes the mob
over from its current victim with more than 110% of the victim's threat
while the mob reaches it in melee, more than 130% otherwise. The client
measures distances from the player only: the player's range to the mob is
CheckInteractDistance(mob, 3) (about 10 yards on 1.12.1; Unreal Azeroth
folds every index below 4 into its interact range), both a little wider
than melee reach, so the player near the mob counts as melee. Every other
unit counts as melee (LibThreatClassic2 does the same for every unit).
The tank follows LibThreatClassic2: the mob's target, unless the unit with
the most threat has enough to have pulled it off them; with no visible
target (or a target without known threat), the unit with the most threat.

Sync: every copy of the library publishes its player's and pet's threat over
the addon channel, on the prefix LVT1, so a group member without the library
has no threat here. A mob is keyed by its name, so the group has to share a
client language.

API:
  lib:GetThreat(unitName, mobName)            -> threat or nil
  lib:GetMobThreat(mobName [, out])           -> { [unitName] = threat }
  lib:GetMaxThreatOnTarget(mobName)           -> threat, unitName
  lib:IterateGroupThreatForTarget(mobName)    -> iterator: unitName, threat,
                                                 highest first
  lib:GetPullAggroRangeModifier(unitName [, mobUnit]) -> 1.1 or 1.3
  lib:GetTank(mobName [, mobUnit])            -> unitName, threat (nil, 0
                                                 when nobody is known)
  lib:UnitDetailedThreatSituation(unit, mobUnit)
      -> isTanking, status, threatPercent, rawThreatPercent, threat
         (LibThreatClassic2 / Blizzard semantics: status 3 = tanking with
         the most threat, 2 = tanking without it, 1 = more threat than the
         tank, 0 = less; threatPercent is the share of the threat that
         pulls aggro, 100 while tanking; rawThreatPercent the share of the
         tank's threat; both nil when the unit has no threat on the mob)
  lib:UnitThreatSituation(unit, mobUnit)      -> status
  lib:EstimateHeal(unitName, amount)          -> effective, overheal
  lib:IsGroupName(name), lib:GetUnitByName(name)
  lib.playerName, lib.petName
  lib.Parser                                  -> Compile, Parse, rules, missing

Callbacks (lib.RegisterCallback(target, event, method)):
  "CombatLine"   (category, record, event)  every recognized line; the
                 record table is reused: read it inside the call
  "UnparsedLine" (event, text)              a line no template matched
  "ThreatUpdated"(unitName, mobName, threat) threat is nil when removed
  "ThreatCleared"(unitName)                 the unit's whole table is gone
  "ThreatEvent"  (unitName, mobName, delta, threat, reason)  every change,
                 with a readable reason, for debugging and validation
]]

local MAJOR, MINOR = "LibVanillaThreat-1.0", 1

local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

local CallbackHandler = LibStub("CallbackHandler-1.0")
lib.callbacks = lib.callbacks or CallbackHandler:New(lib)
local callbacks = lib.callbacks

local getn, tinsert, tremove = table.getn, table.insert, table.remove
local strfind, strsub, strlen, strgsub = string.find, string.sub, string.len, string.gsub
local floor = math.floor

-- Yes/no API returns as a real boolean: the 1.12.1 client returns 1/nil,
-- Unreal Azeroth true/false, some getters 0.
local function Bool(value)
	return value ~= nil and value ~= false and value ~= 0
end

------------------------------------------------------------------------
-- Parser
------------------------------------------------------------------------

local Parser = {}
lib.Parser = Parser

-- Template definitions: global name, kind, critical, the field each format
-- argument fills (in the argument order of the enUS string; positional
-- specifiers in other locales map back to it), and which side is the player
-- ("You hit %s" names no source, "heals you" names no target).
local DAMAGE = {
	{ "COMBATHITSELFOTHER", "melee", false, { "target", "amount" }, "source" },
	{ "COMBATHITCRITSELFOTHER", "melee", true, { "target", "amount" }, "source" },
	{ "COMBATHITSCHOOLSELFOTHER", "melee", false, { "target", "amount", "school" }, "source" },
	{ "COMBATHITCRITSCHOOLSELFOTHER", "melee", true, { "target", "amount", "school" }, "source" },
	{ "COMBATHITOTHEROTHER", "melee", false, { "source", "target", "amount" } },
	{ "COMBATHITCRITOTHEROTHER", "melee", true, { "source", "target", "amount" } },
	{ "COMBATHITSCHOOLOTHEROTHER", "melee", false, { "source", "target", "amount", "school" } },
	{ "COMBATHITCRITSCHOOLOTHEROTHER", "melee", true, { "source", "target", "amount", "school" } },
	{ "COMBATHITOTHERSELF", "melee", false, { "source", "amount" }, "target" },
	{ "COMBATHITCRITOTHERSELF", "melee", true, { "source", "amount" }, "target" },
	{ "COMBATHITSCHOOLOTHERSELF", "melee", false, { "source", "amount", "school" }, "target" },
	{ "COMBATHITCRITSCHOOLOTHERSELF", "melee", true, { "source", "amount", "school" }, "target" },
	{ "SPELLLOGSELFOTHER", "spell", false, { "spell", "target", "amount" }, "source" },
	{ "SPELLLOGCRITSELFOTHER", "spell", true, { "spell", "target", "amount" }, "source" },
	{ "SPELLLOGSCHOOLSELFOTHER", "spell", false, { "spell", "target", "amount", "school" }, "source" },
	{ "SPELLLOGCRITSCHOOLSELFOTHER", "spell", true, { "spell", "target", "amount", "school" }, "source" },
	{ "SPELLLOGOTHEROTHER", "spell", false, { "source", "spell", "target", "amount" } },
	{ "SPELLLOGCRITOTHEROTHER", "spell", true, { "source", "spell", "target", "amount" } },
	{ "SPELLLOGSCHOOLOTHEROTHER", "spell", false, { "source", "spell", "target", "amount", "school" } },
	{ "SPELLLOGCRITSCHOOLOTHEROTHER", "spell", true, { "source", "spell", "target", "amount", "school" } },
	{ "SPELLLOGOTHERSELF", "spell", false, { "source", "spell", "amount" }, "target" },
	{ "SPELLLOGCRITOTHERSELF", "spell", true, { "source", "spell", "amount" }, "target" },
	{ "SPELLLOGSCHOOLOTHERSELF", "spell", false, { "source", "spell", "amount", "school" }, "target" },
	{ "SPELLLOGCRITSCHOOLOTHERSELF", "spell", true, { "source", "spell", "amount", "school" }, "target" },
	{ "SPELLSPLITDAMAGESELFOTHER", "spell", false, { "spell", "target", "amount" }, "source" },
	{ "SPELLSPLITDAMAGEOTHEROTHER", "spell", false, { "source", "spell", "target", "amount" } },
	{ "SPELLSPLITDAMAGEOTHERSELF", "spell", false, { "source", "spell", "amount" }, "target" },
	{ "PERIODICAURADAMAGESELFOTHER", "dot", false, { "target", "amount", "school", "spell" }, "source" },
	{ "PERIODICAURADAMAGEOTHEROTHER", "dot", false, { "target", "amount", "school", "source", "spell" } },
	{ "PERIODICAURADAMAGEOTHERSELF", "dot", false, { "amount", "school", "source", "spell" }, "target" },
	{ "DAMAGESHIELDSELFOTHER", "shield", false, { "amount", "school", "target" }, "source" },
	{ "DAMAGESHIELDOTHEROTHER", "shield", false, { "source", "amount", "school", "target" } },
	{ "DAMAGESHIELDOTHERSELF", "shield", false, { "source", "amount", "school" }, "target" },
}

local HEAL = {
	{ "HEALEDSELFSELF", "heal", false, { "spell", "amount" }, "both" },
	{ "HEALEDCRITSELFSELF", "heal", true, { "spell", "amount" }, "both" },
	{ "HEALEDSELFOTHER", "heal", false, { "spell", "target", "amount" }, "source" },
	{ "HEALEDCRITSELFOTHER", "heal", true, { "spell", "target", "amount" }, "source" },
	{ "HEALEDOTHEROTHER", "heal", false, { "source", "spell", "target", "amount" } },
	{ "HEALEDCRITOTHEROTHER", "heal", true, { "source", "spell", "target", "amount" } },
	{ "HEALEDOTHERSELF", "heal", false, { "source", "spell", "amount" }, "target" },
	{ "HEALEDCRITOTHERSELF", "heal", true, { "source", "spell", "amount" }, "target" },
	{ "PERIODICAURAHEALSELFSELF", "hot", false, { "amount", "spell" }, "both" },
	{ "PERIODICAURAHEALSELFOTHER", "hot", false, { "target", "amount", "spell" }, "source" },
	{ "PERIODICAURAHEALOTHEROTHER", "hot", false, { "target", "amount", "source", "spell" } },
	{ "PERIODICAURAHEALOTHERSELF", "hot", false, { "amount", "source", "spell" }, "target" },
}

local POWER = {
	{ "POWERGAINSELFSELF", "power", false, { "amount", "power", "spell" }, "both" },
	{ "POWERGAINSELFOTHER", "power", false, { "target", "amount", "power", "spell" }, "source" },
	{ "POWERGAINOTHERSELF", "power", false, { "amount", "power", "source", "spell" }, "target" },
	{ "POWERGAINOTHEROTHER", "power", false, { "target", "amount", "power", "source", "spell" } },
}

-- Casts, aura gains and fades. "start" is a cast bar beginning (Unreal
-- Azeroth also prints it for instant spells), "cast" a finished cast,
-- "afflict" / "gain" an aura landing (no caster named), "fade" its end.
local CAST = {
	{ "SPELLCASTGOSELFTARGETTED", "cast", false, { "spell", "target" }, "source" },
	{ "SPELLCASTGOSELF", "cast", false, { "spell" }, "source" },
	{ "SPELLPERFORMGOSELFTARGETTED", "cast", false, { "spell", "target" }, "source" },
	{ "SPELLPERFORMGOSELF", "cast", false, { "spell" }, "source" },
	{ "SPELLCASTGOOTHERTARGETTED", "cast", false, { "source", "spell", "target" } },
	{ "SPELLCASTGOOTHER", "cast", false, { "source", "spell" } },
	{ "SPELLPERFORMGOOTHERTARGETTED", "cast", false, { "source", "spell", "target" } },
	{ "SPELLPERFORMGOOTHER", "cast", false, { "source", "spell" } },
	{ "SPELLCASTSELFSTART", "start", false, { "spell" }, "source" },
	{ "SPELLPERFORMSELFSTART", "start", false, { "spell" }, "source" },
	{ "SPELLCASTOTHERSTART", "start", false, { "source", "spell" } },
	{ "SPELLPERFORMOTHERSTART", "start", false, { "source", "spell" } },
	{ "AURAAPPLICATIONADDEDOTHERHARMFUL", "afflict", false, { "target", "spell", "stacks" } },
	{ "AURAADDEDOTHERHARMFUL", "afflict", false, { "target", "spell" } },
	{ "AURAAPPLICATIONADDEDSELFHARMFUL", "afflict", false, { "spell", "stacks" }, "target" },
	{ "AURAADDEDSELFHARMFUL", "afflict", false, { "spell" }, "target" },
	{ "AURAAPPLICATIONADDEDOTHERHELPFUL", "gain", false, { "target", "spell", "stacks" } },
	{ "AURAADDEDOTHERHELPFUL", "gain", false, { "target", "spell" } },
	{ "AURAAPPLICATIONADDEDSELFHELPFUL", "gain", false, { "spell", "stacks" }, "target" },
	{ "AURAADDEDSELFHELPFUL", "gain", false, { "spell" }, "target" },
	{ "AURAREMOVEDOTHER", "fade", false, { "spell", "target" } },
	{ "AURAREMOVEDSELF", "fade", false, { "spell" }, "target" },
}

-- A spell that did not land: missed, resisted, dodged, ... absorbed. The
-- server adds no ability threat for these.
local MISS = {
	{ "SPELLMISSSELFOTHER", "miss", false, { "spell", "target" }, "source" },
	{ "SPELLRESISTSELFOTHER", "miss", false, { "spell", "target" }, "source" },
	{ "SPELLDODGEDSELFOTHER", "miss", false, { "spell", "target" }, "source" },
	{ "SPELLPARRIEDSELFOTHER", "miss", false, { "spell", "target" }, "source" },
	{ "SPELLBLOCKEDSELFOTHER", "miss", false, { "spell", "target" }, "source" },
	{ "SPELLEVADEDSELFOTHER", "miss", false, { "spell", "target" }, "source" },
	{ "SPELLIMMUNESELFOTHER", "miss", false, { "spell", "target" }, "source" },
	{ "IMMUNESPELLSELFOTHER", "miss", false, { "target", "spell" }, "source" },
	{ "SPELLDEFLECTEDSELFOTHER", "miss", false, { "spell", "target" }, "source" },
	{ "SPELLREFLECTSELFOTHER", "miss", false, { "spell", "target" }, "source" },
	{ "PROCRESISTSELFOTHER", "miss", false, { "target", "spell" }, "source" },
	{ "SPELLLOGABSORBSELFOTHER", "miss", false, { "spell", "target" }, "source" },
	{ "SPELLMISSOTHEROTHER", "miss", false, { "source", "spell", "target" } },
	{ "SPELLRESISTOTHEROTHER", "miss", false, { "source", "spell", "target" } },
	{ "SPELLDODGEDOTHEROTHER", "miss", false, { "source", "spell", "target" } },
	{ "SPELLPARRIEDOTHEROTHER", "miss", false, { "source", "spell", "target" } },
	{ "SPELLBLOCKEDOTHEROTHER", "miss", false, { "source", "spell", "target" } },
	{ "SPELLEVADEDOTHEROTHER", "miss", false, { "source", "spell", "target" } },
	{ "SPELLIMMUNEOTHEROTHER", "miss", false, { "source", "spell", "target" } },
	{ "IMMUNESPELLOTHEROTHER", "miss", false, { "target", "source", "spell" } },
	{ "SPELLDEFLECTEDOTHEROTHER", "miss", false, { "source", "spell", "target" } },
	{ "SPELLREFLECTOTHEROTHER", "miss", false, { "source", "spell", "target" } },
	{ "PROCRESISTOTHEROTHER", "miss", false, { "target", "source", "spell" } },
	{ "SPELLLOGABSORBOTHEROTHER", "miss", false, { "source", "spell", "target" } },
}

local DEATH = {
	{ "SELFKILLOTHER", "death", false, { "target" }, "source" },
	{ "PARTYKILLOTHER", "death", false, { "target", "source" } },
	{ "UNITDIESOTHER", "death", false, { "target" } },
	{ "UNITDESTROYEDOTHER", "death", false, { "target" } },
	{ "UNITDIESSELF", "death", false, {}, "target" },
}

-- Damage trailers, appended after the closing period, possibly several.
local TRAILERS = {
	{ "ABSORB_TRAILER", "absorbed" },
	{ "BLOCK_TRAILER", "blocked" },
	{ "RESIST_TRAILER", "resisted" },
	{ "VULNERABLE_TRAILER", "vulnerable" },
	{ "CRUSHING_TRAILER", "crushing" },
	{ "GLANCING_TRAILER", "glancing" },
}

-- The categories each combat log event may carry, tried in order: a heal
-- line ("You gain 14 health from X.") also fits the aura gain template
-- ("You gain %s."), so heal and power come before cast. Pet buffs and pet
-- heal-over-time ticks arrive on CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS on
-- Unreal Azeroth.
local DMG = { "damage" }
local SPELL_DMG = { "damage", "miss", "cast" }
local PERIODIC_DMG = { "damage", "cast" }
local BUFF = { "heal", "power", "cast" }
local FADE = { "cast" }
local DIES = { "death" }

Parser.EVENTS = {
	CHAT_MSG_COMBAT_SELF_HITS = DMG,
	CHAT_MSG_SPELL_SELF_DAMAGE = SPELL_DMG,
	CHAT_MSG_COMBAT_PET_HITS = DMG,
	CHAT_MSG_SPELL_PET_DAMAGE = SPELL_DMG,
	CHAT_MSG_COMBAT_PARTY_HITS = DMG,
	CHAT_MSG_SPELL_PARTY_DAMAGE = SPELL_DMG,
	CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS = DMG,
	CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE = SPELL_DMG,
	CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE = PERIODIC_DMG,
	CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE = PERIODIC_DMG,
	CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE = PERIODIC_DMG,
	CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE = PERIODIC_DMG,
	CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF = DMG,
	CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS = DMG,
	CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS = DMG,
	CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS = DMG,
	CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS = DMG,
	CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE = SPELL_DMG,
	CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE = SPELL_DMG,
	CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE = SPELL_DMG,
	CHAT_MSG_SPELL_SELF_BUFF = BUFF,
	CHAT_MSG_SPELL_PET_BUFF = BUFF,
	CHAT_MSG_SPELL_PARTY_BUFF = BUFF,
	CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF = BUFF,
	CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS = BUFF,
	CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS = BUFF,
	CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS = BUFF,
	CHAT_MSG_SPELL_AURA_GONE_SELF = FADE,
	CHAT_MSG_SPELL_AURA_GONE_OTHER = FADE,
	CHAT_MSG_SPELL_AURA_GONE_PARTY = FADE,
	CHAT_MSG_COMBAT_HOSTILE_DEATH = DIES,
	CHAT_MSG_COMBAT_FRIENDLY_DEATH = DIES,
}

local RECORD_FIELDS = {
	"source", "target", "spell", "amount", "school", "crit", "kind", "rule",
	"category", "power", "stacks", "effective", "overheal",
	"absorbed", "blocked", "resisted", "vulnerable", "crushing", "glancing",
}

local record = {}
local trailers = {}
local captures = {}

-- A capture is a lazy string or an unsigned integer; at most five per
-- template (PERIODICAURADAMAGEOTHEROTHER and POWERGAINOTHEROTHER have five).
local MAX_CAPTURES = 5

local function EscapeLiteral(text)
	local escaped = strgsub(text, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
	return escaped
end

-- Compiles a printf-style format string into an unanchored Lua pattern.
-- Returns the pattern, the argument index of each capture in text order
-- ("%2$s" positional specifiers reorder them; "%2d" is a width, not a
-- position), and the number of literal characters, which ranks templates by
-- specificity. Only %s, %d and %% are supported; any other specifier makes
-- the template unusable and returns nil.
function Parser.Compile(format)
	local pattern, order, literal = "", {}, 0
	local pos, count, nextArg = 1, 0, 1
	local length = strlen(format)

	while pos <= length do
		local s = strfind(format, "%", pos, true)
		if not s then
			literal = literal + length - pos + 1
			pattern = pattern .. EscapeLiteral(strsub(format, pos))
			break
		end

		literal = literal + s - pos
		pattern = pattern .. EscapeLiteral(strsub(format, pos, s - 1))

		local _, e, index, dollar, kind = strfind(format, "^(%d*)(%$?)([sd%%])", s + 1)
		if not e then
			return nil
		end

		if kind == "%" then
			literal = literal + 1
			pattern = pattern .. "%%"
		else
			count = count + 1
			if dollar == "$" and index ~= "" then
				order[count] = tonumber(index)
			else
				order[count] = nextArg
				nextArg = nextArg + 1
			end
			if kind == "d" then
				pattern = pattern .. "(%d+)"
			else
				pattern = pattern .. "(.-)"
			end
		end

		pos = e + 1
	end

	return pattern, order, literal
end

local function SortRules(a, b)
	if a.literal ~= b.literal then
		return a.literal > b.literal
	end
	return a.name < b.name
end

local function BuildRules(defs, missing)
	local rules = {}

	for i = 1, getn(defs) do
		local def = defs[i]
		local format = getglobal(def[1])
		local pattern, order, literal
		if type(format) == "string" then
			pattern, order, literal = Parser.Compile(format)
		end

		local count = order and getn(order) or -1
		if pattern and count == getn(def[4]) and count <= MAX_CAPTURES then
			tinsert(rules, {
				name = def[1],
				kind = def[2],
				crit = def[3],
				fields = def[4],
				player = def[5],
				pattern = "^" .. pattern .. "$",
				order = order,
				count = count,
				literal = literal,
			})
		else
			tinsert(missing, def[1])
		end
	end

	table.sort(rules, SortRules)
	rules.n = getn(rules)
	return rules
end

-- Compiles every template from the client's GlobalStrings. Templates the
-- client lacks, or that use an unsupported specifier, are listed in
-- Parser.missing and simply never match.
function Parser.Build()
	local missing = {}
	Parser.rules = {
		damage = BuildRules(DAMAGE, missing),
		heal = BuildRules(HEAL, missing),
		power = BuildRules(POWER, missing),
		cast = BuildRules(CAST, missing),
		miss = BuildRules(MISS, missing),
		death = BuildRules(DEATH, missing),
	}

	for i = getn(trailers), 1, -1 do
		tremove(trailers, i)
	end
	for i = 1, getn(TRAILERS) do
		local format = getglobal(TRAILERS[i][1])
		local pattern
		if type(format) == "string" then
			pattern = Parser.Compile(format)
		end
		if pattern then
			tinsert(trailers, { pattern = pattern .. "$", field = TRAILERS[i][2] })
		else
			tinsert(missing, TRAILERS[i][1])
		end
	end

	Parser.missing = missing
end

local function StripTrailers(text)
	local stripped = true
	while stripped do
		stripped = false
		for i = 1, getn(trailers) do
			local s, _, value = strfind(text, trailers[i].pattern)
			if s then
				record[trailers[i].field] = tonumber(value) or true
				text = strsub(text, 1, s - 1)
				stripped = true
				break
			end
		end
	end
	return text
end

local function MatchRules(rules, text)
	for i = 1, rules.n do
		local rule = rules[i]
		local s, _, c1, c2, c3, c4, c5 = strfind(text, rule.pattern)
		if s then
			captures[1], captures[2], captures[3], captures[4], captures[5] = c1, c2, c3, c4, c5
			for j = 1, rule.count do
				local field = rule.fields[rule.order[j]]
				if field == "amount" or field == "stacks" then
					record[field] = tonumber(captures[j])
				else
					record[field] = captures[j]
				end
			end
			return rule
		end
	end
	return nil
end

-- Matches one combat log line of the given category. Returns the shared
-- record table, or nil when no template matches.
function Parser.Parse(category, text)
	local rules = Parser.rules and Parser.rules[category]
	if not rules or type(text) ~= "string" then
		return nil
	end

	for i = 1, getn(RECORD_FIELDS) do
		record[RECORD_FIELDS[i]] = nil
	end

	if category == "damage" then
		text = StripTrailers(text)
	end

	local rule = MatchRules(rules, text)
	if not rule then
		return nil
	end

	if rule.player == "source" or rule.player == "both" then
		record.source = lib.playerName
	end
	if rule.player == "target" or rule.player == "both" then
		record.target = lib.playerName
	end
	record.kind = rule.kind
	record.crit = rule.crit
	record.rule = rule.name
	record.category = category
	return record
end

------------------------------------------------------------------------
-- Roster: the group's names, their unit ids, and the pets
------------------------------------------------------------------------

lib.roster = lib.roster or {}
local rosterDirty = true

local function AddRosterUnit(roster, unit)
	if not Bool(UnitExists(unit)) then return end
	local name = UnitName(unit)
	if not name or name == UNKNOWNOBJECT then return end
	if not roster[name] then
		roster[name] = unit
	end
	return name
end

local function RebuildRoster()
	local roster = {}
	lib.playerName = AddRosterUnit(roster, "player") or lib.playerName
	lib.petName = AddRosterUnit(roster, "pet")

	local raid = GetNumRaidMembers() or 0
	if raid > 0 then
		for i = 1, raid do
			AddRosterUnit(roster, "raid" .. i)
			AddRosterUnit(roster, "raidpet" .. i)
		end
	else
		for i = 1, GetNumPartyMembers() or 0 do
			AddRosterUnit(roster, "party" .. i)
			AddRosterUnit(roster, "partypet" .. i)
		end
	end

	lib.roster = roster
	rosterDirty = false
end

function lib:GetUnitByName(name)
	if not name then return nil end
	local unit = self.roster[name]
	if not unit and rosterDirty then
		RebuildRoster()
		unit = self.roster[name]
	end
	return unit
end

function lib:IsGroupName(name)
	return self:GetUnitByName(name) ~= nil
end

------------------------------------------------------------------------
-- Effective healing
------------------------------------------------------------------------

local HEALTH_CHANGE_WINDOW = 0.5
local healthHistory = {}

local function OnUnitHealth(unit)
	if not unit then return end
	local current = UnitHealth(unit)
	local entry = healthHistory[unit]
	if not entry then
		entry = { current = current }
		healthHistory[unit] = entry
	end
	entry.previous = entry.current
	entry.current = current
	entry.time = GetTime()
end

function lib:EstimateHeal(name, amount)
	local unit = self:GetUnitByName(name)
	if not unit or not amount then
		return amount, 0
	end

	local maxHealth = UnitHealthMax(unit)
	local health = UnitHealth(unit)
	if not maxHealth or maxHealth <= 0 or not health then
		return amount, 0
	end

	local deficit = maxHealth - health
	local history = healthHistory[unit]
	if history and history.time and GetTime() - history.time <= HEALTH_CHANGE_WINDOW
		and history.current == health and history.previous and history.previous < health then
		deficit = maxHealth - history.previous
	end
	if deficit < 0 then
		deficit = 0
	end

	if amount > deficit then
		return deficit, amount - deficit
	end
	return amount, 0
end

------------------------------------------------------------------------
-- Threat tables
------------------------------------------------------------------------

-- threat[unitName][mobName] = value, for every unit the library knows of.
-- The player's and the pet's tables are their actors' own tables; the other
-- group members' tables come from their own copies (see Sync).
lib.threat = lib.threat or {}

-- actors.player / actors.pet = { unit, name, table }
lib.actors = lib.actors or {}

-- Mobs the group fought recently: mobName = time of the last exchange. The
-- fallback set for heal threat on a unit whose threat list is unknown.
lib.engaged = lib.engaged or {}

local function Fire(event, a, b, c, d, e)
	callbacks:Fire(event, a, b, c, d, e)
end

local function Actor(kind)
	local actor = lib.actors[kind]
	if not actor then
		actor = { unit = kind, table = {} }
		lib.actors[kind] = actor
	end
	return actor
end

-- The actor (player or pet) a combat log name belongs to, or nil.
local function ActorByName(name)
	if not name then return nil end
	if name == lib.playerName then return Actor("player") end
	if name == lib.petName and lib.petName then return Actor("pet") end
	return nil
end
lib.ActorByName = ActorByName

-- Keeps lib.threat pointing at the actors' tables under their current names.
local function SyncActorName(actor, name)
	if actor.name == name then return end
	if actor.name and lib.threat[actor.name] == actor.table then
		lib.threat[actor.name] = nil
	end
	actor.name = name
	if name then
		lib.threat[name] = actor.table
	end
end

local function SetThreat(actor, mob, value, delta, reason)
	actor.table[mob] = value
	Fire("ThreatUpdated", actor.name, mob, value)
	Fire("ThreatEvent", actor.name, mob, delta, value, reason)
end

-- Ensures a zero entry: the mob has the actor on its threat list.
local function Engage(actor, mob)
	if not actor.name or not mob then return end
	if actor.table[mob] == nil then
		SetThreat(actor, mob, 0, 0, "engage")
	end
end

local function AddThreat(actor, mob, amount, reason)
	if not actor.name or not mob then return 0 end
	if Bool(UnitIsDeadOrGhost(actor.unit)) then return 0 end
	local old = actor.table[mob] or 0
	local value = old + amount
	if value < 0 then value = 0 end
	SetThreat(actor, mob, value, value - old, reason)
	-- A pet's threat puts its owner on the mob's threat list as well.
	if actor.unit == "pet" and amount >= 0 then
		Engage(Actor("player"), mob)
	end
	return value - old
end

local function ClearActor(actor, reason)
	local mob
	for mob in pairs(actor.table) do
		actor.table[mob] = nil
	end
	if actor.name then
		Fire("ThreatCleared", actor.name)
		Fire("ThreatEvent", actor.name, nil, 0, 0, reason)
	end
end

local function WipeActor(actor, reason)
	local mobs = {}
	local mob
	for mob in pairs(actor.table) do
		tinsert(mobs, mob)
	end
	for i = 1, getn(mobs) do
		local old = actor.table[mobs[i]] or 0
		SetThreat(actor, mobs[i], 0, -old, reason)
	end
end

local function RemoveMob(mob)
	local name, threat
	for name, threat in pairs(lib.threat) do
		if threat[mob] ~= nil then
			threat[mob] = nil
			Fire("ThreatUpdated", name, mob, nil)
			Fire("ThreatEvent", name, mob, 0, nil, "died")
		end
	end
	lib.engaged[mob] = nil
end

------------------------------------------------------------------------
-- Threat modifiers (SPELL_AURA_MOD_THREAT), per actor and school
------------------------------------------------------------------------

-- School bits, as the server's spell school masks.
local SCHOOL_PHYSICAL, SCHOOL_HOLY, SCHOOL_FIRE, SCHOOL_NATURE = 1, 2, 4, 8
local SCHOOL_FROST, SCHOOL_SHADOW, SCHOOL_ARCANE = 16, 32, 64
local SCHOOL_BITS = { 1, 2, 4, 8, 16, 32, 64 }

-- The school a localized school name in a combat log line stands for.
local schoolByName

local function SchoolOf(name)
	if not name then return SCHOOL_PHYSICAL end
	if not schoolByName then
		schoolByName = {}
		for i = 0, 6 do
			local text = getglobal("SPELL_SCHOOL" .. i .. "_CAP")
			if text then
				schoolByName[text] = SCHOOL_BITS[i + 1]
			end
		end
	end
	return schoolByName[name] or SCHOOL_PHYSICAL
end
lib.SchoolOf = SchoolOf

local function HasBit(mask, bit)
	return floor(mask / bit) - floor(mask / (bit * 2)) * 2 == 1
end

-- Aura names a shapeshift form or class contributes (vmangos passives).
local FORM_AURAS = {
	["Battle Stance"] = "Battle Stance Passive",
	["Defensive Stance"] = "Defensive Stance Passive",
	["Berserker Stance"] = "Berserker Stance Passive",
	["Bear Form"] = "Bear Form (Passive2)",
	["Dire Bear Form"] = "Bear Form (Passive2)",
	["Cat Form"] = "Cat Form (Passive)",
}
local CLASS_AURAS = { ROGUE = "Rogue Passive (DND)" }

-- Talents with a threat aura; the rank comes from the talent itself.
-- Defiance only works in Defensive Stance.
local THREAT_TALENTS = {
	["Defiance"] = "Defensive Stance",
	["Burning Soul"] = true,
	["Frost Channeling"] = true,
	["Arcane Subtlety"] = true,
	["Silent Resolve"] = true,
}

-- Item enchants that act as threat auras: gloves "Threat", cloak "Subtlety".
local ENCHANT_AURAS = {
	{ slot = 10, id = 2613, aura = "Increase Threat" },
	{ slot = 15, id = 2621, aura = "Decrease Threat" },
}

local scanTooltip

local function AuraName(unit, index, debuff)
	if not scanTooltip then
		local ok, tip = pcall(CreateFrame, "GameTooltip", "LibVanillaThreatScanTip", nil, "GameTooltipTemplate")
		if not ok or not tip then return nil end
		scanTooltip = tip
	end
	-- The owner is set on every scan: hiding a tooltip clears its owner, and
	-- an ownerless tooltip is not filled.
	pcall(scanTooltip.SetOwner, scanTooltip, UIParent, "ANCHOR_NONE")
	pcall(scanTooltip.ClearLines, scanTooltip)
	local ok
	if debuff then
		ok = pcall(scanTooltip.SetUnitDebuff, scanTooltip, unit, index)
	else
		ok = pcall(scanTooltip.SetUnitBuff, scanTooltip, unit, index)
	end
	local name
	if ok then
		local line = getglobal("LibVanillaThreatScanTipTextLeft1")
		name = line and line:GetText()
	end
	pcall(scanTooltip.Hide, scanTooltip)
	if name == "" then name = nil end
	return name
end

local function TalentRank(talent)
	local tabs = GetNumTalentTabs and GetNumTalentTabs() or 0
	for tab = 1, tabs do
		for i = 1, GetNumTalents(tab) or 0 do
			local name, _, _, _, rank = GetTalentInfo(tab, i)
			if name == talent then
				return rank or 0
			end
		end
	end
	return 0
end

local function ActiveForm()
	local count = GetNumShapeshiftForms and GetNumShapeshiftForms() or 0
	for i = 1, count do
		local _, name, active = GetShapeshiftFormInfo(i)
		if active and active ~= 0 then
			return name
		end
	end
	return nil
end

-- Applies one aura's percent to the school multipliers it covers.
local function ApplyAura(mods, auraName, rank)
	local data = lib.threatAuras and lib.threatAuras[auraName]
	if not data then return end
	local entry = data[rank or 0] or data[0] or data[1]
	if not entry then return end
	local factor = (100 + entry[1]) / 100
	for i = 1, getn(SCHOOL_BITS) do
		local bit = SCHOOL_BITS[i]
		if HasBit(entry[2], bit) then
			mods[bit] = mods[bit] * factor
		end
	end
end

local function ApplyUnitAuras(mods, unit, isPlayer)
	for i = 1, 32 do
		if not UnitBuff(unit, i) then break end
		local name = AuraName(unit, i, false)
		if name == "Master Demonologist" then
			-- Only the imp's version reduces threat; the rank is the talent's.
			local _, petClass = UnitClass("pet")
			if isPlayer and petClass == "MAGE" then
				ApplyAura(mods, name, TalentRank(name))
			end
		elseif name then
			ApplyAura(mods, name)
		end
	end
	for i = 1, 16 do
		if not UnitDebuff(unit, i) then break end
		local name = AuraName(unit, i, true)
		if name then
			ApplyAura(mods, name)
		end
	end
end

local function ApplyPlayerPassives(mods)
	local form = ActiveForm()
	if form and FORM_AURAS[form] then
		ApplyAura(mods, FORM_AURAS[form])
	end

	local _, class = UnitClass("player")
	if class and CLASS_AURAS[class] then
		ApplyAura(mods, CLASS_AURAS[class])
	end

	local talent, condition
	for talent, condition in pairs(THREAT_TALENTS) do
		if condition == true or condition == form then
			local rank = TalentRank(talent)
			if rank > 0 then
				ApplyAura(mods, talent, rank)
			end
		end
	end

	for i = 1, getn(ENCHANT_AURAS) do
		local enchant = ENCHANT_AURAS[i]
		local link = GetInventoryItemLink("player", enchant.slot)
		local _, _, id = strfind(link or "", "item:%d+:(%d+)")
		if tonumber(id) == enchant.id then
			ApplyAura(mods, enchant.aura)
		end
	end
end

local function ComputeMods(actor)
	local mods = actor.mods or {}
	for i = 1, getn(SCHOOL_BITS) do
		mods[SCHOOL_BITS[i]] = 1
	end
	if Bool(UnitExists(actor.unit)) then
		ApplyUnitAuras(mods, actor.unit, actor.unit == "player")
		if actor.unit == "player" then
			ApplyPlayerPassives(mods)
		end
	end
	actor.mods = mods
	actor.modsDirty = false
	return mods
end

local function ThreatMod(actor, school)
	local mods = actor.mods
	if actor.modsDirty or not mods then
		mods = ComputeMods(actor)
	end
	return mods[school or SCHOOL_PHYSICAL] or 1
end
lib.ThreatMod = ThreatMod

local function MarkModsDirty(unit)
	if unit == "player" or unit == nil then Actor("player").modsDirty = true end
	if unit == "pet" or unit == nil then Actor("pet").modsDirty = true end
end

------------------------------------------------------------------------
-- Spell data lookups (Spells.lua)
------------------------------------------------------------------------

local spellbookRanks
local SPELL_BOOK_MAX = 400

-- The highest rank of a spell in the player's spellbook (0 when unranked or
-- unknown). The combat log names no rank; vmangos takes the cast rank, and
-- the highest known is what the player normally casts.
local function SpellbookRank(spell)
	if not spellbookRanks then
		spellbookRanks = {}
		for i = 1, SPELL_BOOK_MAX do
			local name, subtext = GetSpellName(i, BOOKTYPE_SPELL or "spell")
			if not name then break end
			local _, _, rank = strfind(subtext or "", "(%d+)")
			rank = tonumber(rank) or 0
			if rank > (spellbookRanks[name] or 0) then
				spellbookRanks[name] = rank
			else
				spellbookRanks[name] = spellbookRanks[name] or 0
			end
		end
	end
	return spellbookRanks[spell] or 0
end

-- The rank of a pet ability on the pet action bar ("Rank 3").
local function PetActionRank(spell)
	for i = 1, 10 do
		local name, subtext = GetPetActionInfo(i)
		if name == spell then
			local _, _, rank = strfind(subtext or "", "(%d+)")
			return tonumber(rank) or 0
		end
	end
	return 0
end

local function ActorRank(actor, spell)
	if actor.unit == "pet" then
		return PetActionRank(spell)
	end
	return SpellbookRank(spell)
end

local function RankEntry(ranks, rank)
	if not ranks then return nil end
	if ranks[rank] then return ranks[rank] end
	if rank == 0 then
		local best, r
		for r in pairs(ranks) do
			if not best or r > best then best = r end
		end
		return best and ranks[best]
	end
	return ranks[0]
end

-- spell_threat: flat bonus and damage/heal multiplier of the actor's spell.
local function SpellThreatEntry(actor, spell)
	if not spell or not lib.spellThreat then return nil end
	local ranks = lib.spellThreat[spell]
	if not ranks then return nil end
	return RankEntry(ranks, ActorRank(actor, spell))
end

local function SpellMultiplier(actor, spell)
	local entry = SpellThreatEntry(actor, spell)
	if entry then return entry[2] end
	return 1
end

-- SPELL_EFFECT_THREAT value at the actor's level (vmangos
-- CalculateSpellEffectValue): base + perLevel x (level - spell level), the
-- level clamped to the spell's base..max level.
local function EffectThreat(actor, spell)
	local effects = lib.threatEffects and lib.threatEffects[actor.unit]
	local entry = RankEntry(effects and effects[spell], ActorRank(actor, spell))
	if not entry then return nil end
	local level = UnitLevel(actor.unit) or 0
	local base, perLevel, spellLevel, baseLevel, maxLevel = entry[1], entry[2], entry[3], entry[4], entry[5]
	if maxLevel > 0 and level > maxLevel then
		level = maxLevel
	elseif level < baseLevel then
		level = baseLevel
	end
	return base + perLevel * (level - spellLevel)
end
lib.EffectThreat = EffectThreat

------------------------------------------------------------------------
-- Ability threat on landing, with take-back on a later miss line
------------------------------------------------------------------------

local LANDING_WINDOW = 1.5
-- landed[actorUnit .. spell .. target] = { time, delta }
local landed = {}
-- started[actorUnit .. spell] = time of the actor's cast start line
local started = {}

local function LandingKey(actor, spell, target)
	return actor.unit .. "\001" .. spell .. "\001" .. (target or "")
end

-- Flat and effect threat of a landed ability, once per landing.
local function AbilityLanded(actor, spell, target, school)
	if not spell or not target then return end
	local key = LandingKey(actor, spell, target)
	local now = GetTime()
	local prev = landed[key]
	if prev and now - prev.time < LANDING_WINDOW then return end

	local amount, reason = 0, nil
	local effect = EffectThreat(actor, spell)
	if effect then
		amount = amount + effect
		reason = spell .. " effect " .. effect
	end
	local entry = SpellThreatEntry(actor, spell)
	if entry and entry[1] ~= 0 then
		amount = amount + entry[1]
		reason = (reason and (reason .. ", ") or "") .. spell .. " bonus " .. entry[1]
	end
	if amount == 0 then return end

	local mod = ThreatMod(actor, school)
	local delta = AddThreat(actor, target, amount * mod, reason .. " x" .. mod)
	landed[key] = { time = now, delta = delta }
end

local function AbilityMissed(actor, spell, target)
	if not spell or not target then return end
	local key = LandingKey(actor, spell, target)
	local now = GetTime()
	local prev = landed[key]
	if prev and now - prev.time < LANDING_WINDOW and prev.delta ~= 0 then
		AddThreat(actor, target, -prev.delta, spell .. " missed: taken back")
	end
	-- A landing line after the miss line must not add it again.
	landed[key] = { time = now, delta = 0 }
end

------------------------------------------------------------------------
-- Feign Death
------------------------------------------------------------------------

local FEIGN_DEATH = "Feign Death"
local FEIGN_DELAY = 0.3
local feignAt, feignResistedAt

local function FeignDeathSeen()
	if not feignAt then
		feignAt = GetTime()
	end
end

local function CheckFeignDeath(now)
	if not feignAt or now - feignAt < FEIGN_DELAY then return end
	local resisted = feignResistedAt and math.abs(feignResistedAt - feignAt) < 1
	feignAt = nil
	if not resisted then
		WipeActor(Actor("player"), "Feign Death")
	end
end

------------------------------------------------------------------------
-- Combat log handlers
------------------------------------------------------------------------

local HEAL_COEFFICIENT, PALADIN_HEAL_COEFFICIENT = 0.5, 0.25
local ENGAGED_WINDOW = 10

-- Heal schools by class: the combat log names none, and school-limited
-- modifiers (Silent Resolve) depend on it.
local HEAL_SCHOOL = {
	PRIEST = SCHOOL_HOLY, PALADIN = SCHOOL_HOLY, DRUID = SCHOOL_NATURE,
	SHAMAN = SCHOOL_NATURE, HUNTER = SCHOOL_NATURE, WARLOCK = SCHOOL_SHADOW,
}

local function MarkEngaged(mob)
	if mob then
		lib.engaged[mob] = GetTime()
	end
end

local function OnDamage(rec)
	local source, target = rec.source, rec.target
	local actor = ActorByName(source)
	if actor then
		if lib:IsGroupName(target) then return end
		MarkEngaged(target)
		local school = SchoolOf(rec.school)
		local mult = SpellMultiplier(actor, rec.spell)
		local mod = ThreatMod(actor, school)
		local reason = (rec.spell or "melee") .. " " .. rec.amount
		if mult ~= 1 then reason = reason .. " x" .. mult end
		AddThreat(actor, target, rec.amount * mult * mod, reason .. " x" .. mod)
		if rec.spell and rec.kind == "spell" then
			AbilityLanded(actor, rec.spell, target, school)
		end
		return
	end

	if lib:IsGroupName(source) then
		MarkEngaged(target)
		return
	end

	-- A mob hitting the player or the pet puts it on the mob's threat list.
	local victim = ActorByName(target)
	if victim then
		Engage(victim, source)
	end
	if lib:IsGroupName(target) then
		MarkEngaged(source)
	end
end

-- The mobs that have `name` on their threat list.
local function HostileMobs(name)
	local mobs = {}
	local actor = ActorByName(name)
	local threat = (actor and actor.table) or lib.threat[name]
	if threat then
		local mob
		for mob in pairs(threat) do
			tinsert(mobs, mob)
		end
		if getn(mobs) > 0 or actor then
			return mobs
		end
	end
	local now = GetTime()
	local mob, time
	for mob, time in pairs(lib.engaged) do
		if now - time <= ENGAGED_WINDOW then
			tinsert(mobs, mob)
		end
	end
	return mobs
end

local function OnHeal(rec)
	local actor = ActorByName(rec.source)
	if not actor or not rec.effective or rec.effective <= 0 then return end

	local _, class = UnitClass(actor.unit)
	local coefficient = HEAL_COEFFICIENT
	if class == "PALADIN" and rec.kind == "heal" then
		coefficient = PALADIN_HEAL_COEFFICIENT
	end

	local mobs = HostileMobs(rec.target)
	local count = getn(mobs)
	if count == 0 then return end

	local total = rec.effective * coefficient * SpellMultiplier(actor, rec.spell)
	local mod = ThreatMod(actor, HEAL_SCHOOL[class or ""] or SCHOOL_HOLY)
	local share = total / count
	local reason = rec.spell .. " heal " .. rec.effective .. " x" .. coefficient .. " /" .. count .. " x" .. mod
	for i = 1, count do
		AddThreat(actor, mobs[i], share * mod, reason)
	end
end

local function OnCast(rec)
	local actor = ActorByName(rec.source)
	local kind, spell = rec.kind, rec.spell

	if spell == FEIGN_DEATH and (rec.source == lib.playerName or rec.target == lib.playerName)
		and (kind == "start" or kind == "cast" or kind == "gain") then
		FeignDeathSeen()
		return
	end

	if kind == "start" and actor then
		started[actor.unit .. "\001" .. spell] = GetTime()
	elseif kind == "cast" and actor and rec.target and not lib:IsGroupName(rec.target) then
		MarkEngaged(rec.target)
		AbilityLanded(actor, spell, rec.target, SCHOOL_PHYSICAL)
	elseif kind == "afflict" and rec.target and not lib:IsGroupName(rec.target) then
		-- No caster is named: the debuff is the player's or the pet's when
		-- that actor began it just before.
		local now = GetTime()
		local kindName
		for kindName in pairs(lib.actors) do
			local candidate = lib.actors[kindName]
			local at = started[kindName .. "\001" .. spell]
			if at and now - at < LANDING_WINDOW then
				AbilityLanded(candidate, spell, rec.target, SCHOOL_PHYSICAL)
			end
		end
	end
end

local function OnMiss(rec)
	local actor = ActorByName(rec.source)
	if actor then
		AbilityMissed(actor, rec.spell, rec.target)
	end
end

local function OnDeath(rec)
	local target = rec.target
	if not target then return end
	local actor = ActorByName(target)
	if actor then
		WipeActor(actor, "died")
	elseif not lib:IsGroupName(target) then
		RemoveMob(target)
	end
end

local HANDLERS = {
	damage = OnDamage,
	heal = OnHeal,
	cast = OnCast,
	miss = OnMiss,
	death = OnDeath,
}

local function ParseLine(event, message)
	local categories = Parser.EVENTS[event]
	if not categories then return end

	for i = 1, getn(categories) do
		local category = categories[i]
		local rec = Parser.Parse(category, message)
		if rec then
			if category == "heal" then
				rec.effective, rec.overheal = lib:EstimateHeal(rec.target, rec.amount)
			end
			local handler = HANDLERS[category]
			if handler then
				handler(rec)
			end
			Fire("CombatLine", category, rec, event)
			return
		end
	end
	Fire("UnparsedLine", event, message)
end
lib.ParseLine = ParseLine

------------------------------------------------------------------------
-- Combat state
------------------------------------------------------------------------

local function InCombat(unit)
	return Bool(UnitAffectingCombat(unit))
end

local function LeaveCombat()
	ClearActor(Actor("player"), "left combat")
	local mob
	for mob in pairs(lib.engaged) do
		lib.engaged[mob] = nil
	end
end

local function CheckPet()
	local pet = Actor("pet")
	if lib.petName ~= pet.name then
		ClearActor(pet, "pet changed")
		SyncActorName(pet, lib.petName)
	end
	if pet.name and next(pet.table) and not InCombat("player") and not InCombat("pet") then
		ClearActor(pet, "left combat")
	end
end

------------------------------------------------------------------------
-- Sync: the group's threat over the addon channel
------------------------------------------------------------------------

-- Every copy publishes its own player's and pet's threat, so the others'
-- tables fill from their senders. Two messages:
--   TU<unit>:<mob>=<threat>;<mob>=;   whole numbers, what changed since the
--                                     last one; no number: off the mob's list
--   LC<unit>                          the unit's whole table is gone
-- A mob name may hold "=" (an entry splits at its last one), never ";". The
-- prefix carries the protocol version. Messages stay short and one goes per
-- actor per publish: whatever does not fit waits for the next publish.
local COMM_PREFIX = "LVT1"
local COMM_MAX = 200
-- Everything is sent again this often, for a member who joined or reloaded,
-- and it keeps a live sender from expiring while its threat stands still.
local COMM_RESEND = 10
-- A sender silent for this long (disconnected, crashed) loses its tables.
local COMM_EXPIRY = 30
local BATTLEFIELD_QUEUES = 3

-- Units whose table came from a sender: unitName = { sender, time }
lib.synced = lib.synced or {}

local commNext, commResend = 0, 0

-- PARTY has to be named outside a raid: the 1.12.1 client delivers a RAID
-- message to the party, Unreal Azeroth drops it.
local function CommChannel()
	if GetBattlefieldStatus then
		local i
		for i = 1, BATTLEFIELD_QUEUES do
			if GetBattlefieldStatus(i) == "active" then return "BATTLEGROUND" end
		end
	end
	if (GetNumRaidMembers() or 0) > 0 then return "RAID" end
	if (GetNumPartyMembers() or 0) > 0 then return "PARTY" end
end

-- A tank's threat matters most to the others, so it goes out twice as often
-- (LibThreatClassic2's intervals).
local function PublishInterval()
	local _, class = UnitClass("player")
	if class == "WARRIOR" or (Bool(UnitExists("targettarget")) and Bool(UnitIsUnit("targettarget", "player"))) then
		return 1
	end
	return 2
end

-- Appends what changed to `body`, as far as it fits, and records it as sent.
local function AppendChanges(actor, body)
	local sent = actor.sent
	local mob, value
	for mob, value in pairs(actor.table) do
		local whole = floor(value)
		if sent[mob] ~= whole then
			local entry = mob .. "=" .. whole .. ";"
			if strlen(body) + strlen(entry) > COMM_MAX then return body end
			body = body .. entry
			sent[mob] = whole
		end
	end
	for mob in pairs(sent) do
		if actor.table[mob] == nil then
			local entry = mob .. "=;"
			if strlen(body) + strlen(entry) > COMM_MAX then return body end
			body = body .. entry
			sent[mob] = nil
		end
	end
	return body
end

local function PublishActor(actor, channel)
	if not actor.sent then actor.sent = {} end
	-- sentName: the name the receivers hold a table under.
	if actor.sentName and (actor.sentName ~= actor.name or not next(actor.table)) then
		SendAddonMessage(COMM_PREFIX, "LC" .. actor.sentName, channel)
		actor.sent = {}
		actor.sentName = nil
	end
	if not actor.name or not next(actor.table) then return end

	local head = "TU" .. actor.name .. ":"
	local body = AppendChanges(actor, head)
	if body ~= head then
		SendAddonMessage(COMM_PREFIX, body, channel)
		actor.sentName = actor.name
	end
end

local function DropSynced(name, reason)
	lib.synced[name] = nil
	-- The player's or the pet's own table may have taken the name since.
	if ActorByName(name) or not lib.threat[name] then return end
	lib.threat[name] = nil
	Fire("ThreatCleared", name)
	Fire("ThreatEvent", name, nil, 0, 0, reason)
end

local function ExpireSynced(now)
	local name, entry
	for name, entry in pairs(lib.synced) do
		if now - entry.time > COMM_EXPIRY or not lib.roster[entry.sender] then
			DropSynced(name, "sync lost")
		end
	end
end

local function CommTick(now)
	if now < commNext then return end
	commNext = now + PublishInterval()
	ExpireSynced(now)

	local player, pet = Actor("player"), Actor("pet")
	local channel = CommChannel()
	if not channel then
		player.sent, player.sentName = nil, nil
		pet.sent, pet.sentName = nil, nil
		return
	end
	PublishActor(player, channel)
	PublishActor(pet, channel)
	-- After the publish: emptying `sent` first would lose the removals.
	if now >= commResend then
		commResend = now + COMM_RESEND
		player.sent, pet.sent = nil, nil
	end
end

-- A pet's name can repeat in the group: never into the local actors' tables.
local function ReceiveThreat(sender, name, message, start)
	if ActorByName(name) then return end
	local threat = lib.threat[name]
	if not threat then
		threat = {}
		lib.threat[name] = threat
	end
	local entry = lib.synced[name]
	if not entry then
		entry = {}
		lib.synced[name] = entry
	end
	entry.sender, entry.time = sender, GetTime()

	while true do
		local _, stop, mob, value = strfind(message, "([^;]+)=(%d*);", start)
		if not stop then return end
		start = stop + 1
		local old, new = threat[mob], tonumber(value)
		threat[mob] = new
		if old ~= new then
			Fire("ThreatUpdated", name, mob, new)
			Fire("ThreatEvent", name, mob, (new or 0) - (old or 0), new, "sync")
		end
	end
end

local function OnAddonMessage(prefix, message, sender)
	if prefix ~= COMM_PREFIX or not message or not sender then return end
	if sender == lib.playerName or not lib:IsGroupName(sender) then return end

	local command = strsub(message, 1, 2)
	if command == "TU" then
		local _, stop, name = strfind(message, "^TU([^:]+):")
		if name then
			ReceiveThreat(sender, name, message, stop + 1)
		end
	elseif command == "LC" then
		local name = strsub(message, 3)
		local entry = lib.synced[name]
		if entry and entry.sender == sender then
			DropSynced(name, "left combat")
		end
	end
end

------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------

local EVENTS = {
	"PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE", "UNIT_PET", "UNIT_NAME_UPDATE",
	"PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED",
	"UNIT_HEALTH", "UNIT_AURA", "UNIT_INVENTORY_CHANGED", "UPDATE_SHAPESHIFT_FORMS",
	"CHARACTER_POINTS_CHANGED", "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB",
	"UI_ERROR_MESSAGE", "PLAYER_DEAD", "CHAT_MSG_ADDON",
}

local function OnEvent(event, a1, a2, a3, a4)
	if Parser.EVENTS[event] then
		ParseLine(event, a1)
	elseif event == "UNIT_HEALTH" then
		OnUnitHealth(a1)
	elseif event == "UNIT_AURA" or event == "UNIT_INVENTORY_CHANGED" then
		MarkModsDirty(a1)
	elseif event == "UPDATE_SHAPESHIFT_FORMS" or event == "CHARACTER_POINTS_CHANGED" then
		MarkModsDirty(nil)
	elseif event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB" then
		spellbookRanks = nil
	elseif event == "PLAYER_REGEN_DISABLED" then
		MarkModsDirty(nil)
	elseif event == "PLAYER_REGEN_ENABLED" then
		LeaveCombat()
	elseif event == "PLAYER_DEAD" then
		WipeActor(Actor("player"), "died")
	elseif event == "CHAT_MSG_ADDON" then
		OnAddonMessage(a1, a2, a4)
	elseif event == "UI_ERROR_MESSAGE" then
		if a1 == ERR_FEIGN_DEATH_RESISTED then
			feignResistedAt = GetTime()
		end
	else
		rosterDirty = true
		if event == "UNIT_PET" or event == "PLAYER_ENTERING_WORLD" then
			MarkModsDirty(nil)
		end
	end
end
lib.OnEvent = OnEvent

local TICK = 0.25
local lastTick = 0

local function OnUpdate()
	local now = GetTime()
	if now - lastTick < TICK then return end
	lastTick = now

	if rosterDirty then
		RebuildRoster()
	end
	SyncActorName(Actor("player"), lib.playerName)
	CheckPet()
	CheckFeignDeath(now)
	CommTick(now)
end
lib.OnUpdate = OnUpdate

-- Starts the library: compiles the templates and registers the events.
-- Runs at load; the 1.12.1 client has the GlobalStrings by then.
function lib:Enable()
	Parser.Build()
	RebuildRoster()
	SyncActorName(Actor("player"), lib.playerName)
	SyncActorName(Actor("pet"), lib.petName)

	local frame = self.frame or CreateFrame("Frame")
	self.frame = frame
	frame:UnregisterAllEvents()
	local name
	for name in pairs(Parser.EVENTS) do
		frame:RegisterEvent(name)
	end
	for i = 1, getn(EVENTS) do
		frame:RegisterEvent(EVENTS[i])
	end
	-- Event arguments come from the globals: the 1.12.1 client passes none
	-- to the handler, Unreal Azeroth sets the globals as well. (No local in
	-- this function may be called `event`: it would hide the global.)
	frame:SetScript("OnEvent", function(f, e, a)
		OnEvent(event or e, arg1 or a, arg2, arg3, arg4)
	end)
	frame:SetScript("OnUpdate", OnUpdate)
end

------------------------------------------------------------------------
-- API
------------------------------------------------------------------------

function lib:GetThreat(unitName, mobName)
	local threat = self.threat[unitName or ""]
	return threat and threat[mobName or ""]
end

function lib:GetMobThreat(mobName, out)
	out = out or {}
	local name, threat
	for name in pairs(out) do
		out[name] = nil
	end
	for name, threat in pairs(self.threat) do
		local value = threat[mobName or ""]
		if value then
			out[name] = value
		end
	end
	return out
end

function lib:GetMaxThreatOnTarget(mobName)
	local best, bestName
	local name, threat
	for name, threat in pairs(self.threat) do
		local value = threat[mobName or ""]
		if value and (not best or value > best) then
			best, bestName = value, name
		end
	end
	return best or 0, bestName
end

function lib:IterateGroupThreatForTarget(mobName)
	local list = {}
	local name, threat
	for name, threat in pairs(self.threat) do
		local value = threat[mobName or ""]
		if value then
			tinsert(list, { name = name, value = value })
		end
	end
	table.sort(list, function(a, b) return a.value > b.value end)
	local i = 0
	return function()
		i = i + 1
		local entry = list[i]
		if entry then
			return entry.name, entry.value
		end
	end
end

local PULL_MELEE, PULL_RANGED = 1.1, 1.3

function lib:GetPullAggroRangeModifier(unitName, mobUnit)
	if unitName and unitName == self.playerName and mobUnit and Bool(UnitExists(mobUnit))
		and type(CheckInteractDistance) == "function" then
		if Bool(CheckInteractDistance(mobUnit, 3)) then
			return PULL_MELEE
		end
		return PULL_RANGED
	end
	return PULL_MELEE
end

function lib:GetTank(mobName, mobUnit)
	local maxThreat, maxName = self:GetMaxThreatOnTarget(mobName)
	local victim
	if mobUnit and Bool(UnitExists(mobUnit .. "target")) then
		victim = UnitName(mobUnit .. "target")
	end
	if not victim then
		return maxName, maxThreat
	end
	local victimThreat = self:GetThreat(victim, mobName) or 0
	if maxName and maxThreat > victimThreat * self:GetPullAggroRangeModifier(maxName, mobUnit) then
		return maxName, maxThreat
	end
	return victim, victimThreat
end

function lib:UnitDetailedThreatSituation(unit, mobUnit)
	if not (Bool(UnitExists(unit)) and Bool(UnitExists(mobUnit))) then
		return false, 0, nil, nil, 0
	end
	local name, mobName = UnitName(unit), UnitName(mobUnit)
	local value = self:GetThreat(name, mobName) or 0
	if value <= 0 then
		return false, 0, nil, nil, 0
	end

	-- The tank's threat is positive here: with a zero-threat victim the
	-- unit with the most threat (at least this one's) is the tank.
	local _, maxName = self:GetMaxThreatOnTarget(mobName)
	local tankName, tankThreat = self:GetTank(mobName, mobUnit)
	local isTanking = name == tankName
	local status = 0
	if value >= tankThreat then
		if isTanking and name == maxName then
			status = 3
		elseif isTanking then
			status = 2
		else
			status = 1
		end
	end

	local rawPercent = value / tankThreat * 100
	local percent = 100
	if not isTanking then
		percent = rawPercent / self:GetPullAggroRangeModifier(name, mobUnit)
	end
	return isTanking, status, percent, rawPercent, floor(value)
end

function lib:UnitThreatSituation(unit, mobUnit)
	local _, status = self:UnitDetailedThreatSituation(unit, mobUnit)
	return status
end

-- Takes over the tables of Spells.lua, unless the ones in use are as new.
function lib:AdoptData(data)
	if (self.dataVersion or 0) >= data.version then return end
	self.dataVersion = data.version
	self.spellThreat = data.spellThreat
	self.threatEffects = data.threatEffects
	self.threatAuras = data.threatAuras
end

-- Spells.lua comes first in the XML, and this file last: on Unreal Azeroth a
-- file listed before another in a library's XML can run ahead of every other
-- library, and this one needs CallbackHandler-1.0 at load. So Spells.lua
-- only leaves its tables in this global.
if LibVanillaThreat_Data then
	lib:AdoptData(LibVanillaThreat_Data)
	LibVanillaThreat_Data = nil
end

lib:Enable()
