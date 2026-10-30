# LibVanillaThreat-1.0

Threat estimation for the vanilla 1.12.1 client and Unreal Azeroth. Neither
client has a threat API, so the library rebuilds the player's and the pet's
threat on every mob from the combat log, **the way the server counts it**,
and shares it with the group over the addon channel.

- **Numbers and formulas: the vmangos server.** Unreal Azeroth's server is
  derived from vmangos, and the Elysium-line 1.12.1 servers come from the
  same lineage. The library follows its `ThreatManager`,
  `HostileRefManager::threatAssist`, `Spell::HandleThreatSpells`,
  `Spell::EffectThreat`, and the world database's `spell_threat` table; the
  data is generated into `Spells.lua`.
- **Structure and API: LibThreatClassic2**, the Classic 1.13 library from
  before Blizzard's threat API: per-unit threat tables keyed by mob,
  `ThreatUpdated` / `ThreatCleared` callbacks, `GetThreat`,
  `GetMaxThreatOnTarget`, `IterateGroupThreatForTarget`.

```lua
local LVT = LibStub("LibVanillaThreat-1.0")

local mob = UnitName("target")
local mine = LVT:GetThreat(UnitName("player"), mob)
local top, topName = LVT:GetMaxThreatOnTarget(mob)

LVT.RegisterCallback(MyAddon, "ThreatUpdated", function(event, unitName, mobName, threat)
	-- threat is nil when the entry was removed (the mob died)
end)
```

The library also exposes its combat log parser: one `CombatLine` callback per
recognized line, so a damage meter can share the parsing instead of doing it
a second time.

## Limits

- **1.12 has no GUIDs: a mob is keyed by its name.** Two mobs of one name
  share one entry, and one of them dying removes it.
- Only the player's and the pet's own threat is computed. Another group
  member's threat comes from their own copy of the library, over the addon
  channel; a member without the library has none, and when such a member is
  the mob's target, `GetTank` falls back to the unit with the most threat.
- Pets of one name share one entry (the default pet name is the beast's
  family), and another member's pet with your pet's name is not received.
- Mob names differ per client language: the group has to share one for the
  synced values to meet.
- Spell, buff and talent names in the data are **English**; on other client
  languages the parser still works (it compiles the client's own combat log
  format strings), but threat modifiers and ability bonuses do not apply.
- The combat log names no spell rank: a spell counts at the highest rank in
  the spellbook (a pet ability at its rank on the pet action bar).
- Heal threat goes to the mobs that have the healed unit on their threat
  list. That list is known for the player, the pet and every member who
  syncs; for any other group member the library uses the mobs the group
  fought in the last 10 seconds.
- The server gives no assist threat to a feared or stunned mob; the library
  cannot see that.

## Threat, as the server counts it

| Source | Threat |
|---|---|
| Damage | amount × `spell_threat` multiplier × threat modifiers of the damage's school |
| Ability on a landed hit | `spell_threat` flat bonus + `SPELL_EFFECT_THREAT` value (Growl, Torment, Suffering, Distracting Shot, Cower, Disengage, Feint, Intimidation, …: `base + perLevel × (level − spell level)`, level clamped to the spell's base…max level), × modifiers; a miss line after the landing line takes it back |
| Healing | effective heal × 0.5 (a paladin's direct heal × 0.25) × `spell_threat` multiplier, split evenly over the mobs that have the healed unit on their threat list, × the healer's modifiers |
| Pet threat | also puts the owner on the mob's threat list (zero) |
| Mana / rage / energy gains | none (the server adds none for direct energize) |

Threat modifiers are the `SPELL_AURA_MOD_THREAT` auras, multiplied per
school: stances and forms, Rogue passive, Blessing of Salvation, Tranquil
Air, Arcane Shroud, The Eye of Diminution, Fungal Bloom, Master Demonologist
(imp), Righteous Fury (holy), the Defiance, Burning Soul, Frost Channeling,
Arcane Subtlety and Silent Resolve talents, and the gloves "Threat" / cloak
"Subtlety" enchants.

Death, Feign Death (unless the client reports "Resisted") and leaving combat
clear the actor's table; a mob's death removes its entries.

## Effective healing

The combat log reports a heal with its overheal. The library estimates the
overheal from the recipient's health deficit when the line arrives, measured
from the value before a health rise seen in the last half second (the
`UNIT_HEALTH` update may come before or after the line) — the method of
MikScrollingBattleText's 1.12.1 / Unreal Azeroth port. It is exact for group
units; other recipients count as fully effective. Heal records carry
`effective` and `overheal`.

## Aggro and the tank

A unit pulls the mob off its current victim with **more than 110%** of the
victim's threat while the mob reaches it in melee, **more than 130%**
otherwise (vmangos `ThreatContainer::selectNextVictim`). The client measures
distances from the player only: the player's range is
`CheckInteractDistance(mob, 3)` (about 10 yards on 1.12.1; Unreal Azeroth
folds every index below 4 into its interact range), a little wider than
melee reach. Every other unit counts as melee, as in LibThreatClassic2.

The tank is the mob's target, unless the unit with the most threat has
enough to have pulled it off them (LibThreatClassic2's rule); with no
visible target, or a target whose threat is unknown, it is the unit with
the most threat. `threatPercent` is the share of the threat that pulls
aggro (100 while tanking), `rawThreatPercent` the share of the tank's
threat.

## Sync

Every copy publishes its player's and pet's threat, and needs nothing from
the addon using it: the synced tables sit next to the local ones, so every
call and callback below covers them.

- Prefix `LVT1`; `RAID` in a raid, `PARTY` in a party (Unreal Azeroth drops a
  `RAID` message there), `BATTLEGROUND` in a battleground.
- `TU<unit>:<mob>=<threat>;<mob>=;` — whole numbers, only what changed; an
  entry without a number takes the unit off that mob's list.
- `LC<unit>` — the unit's table is gone (it left combat, or the pet changed).
- A publish goes out every 2 seconds, every second from a warrior or from
  the target's target, and at most one message of 200 characters per unit:
  the rest waits for the next publish. Nothing is sent while nothing changes,
  and everything is sent again every 10 seconds while the table holds
  anything.
- A sender who stays silent for 30 seconds, or leaves the group, loses their
  tables.
- Healing threat uses the synced table of the healed unit as its mob list.

## API

| Call | Returns |
|---|---|
| `lib:GetThreat(unitName, mobName)` | threat, or `nil` |
| `lib:GetMobThreat(mobName [, out])` | `{ [unitName] = threat }` (fills and returns `out`) |
| `lib:GetMaxThreatOnTarget(mobName)` | `threat, unitName` |
| `lib:IterateGroupThreatForTarget(mobName)` | iterator of `unitName, threat`, highest first |
| `lib:GetPullAggroRangeModifier(unitName [, mobUnit])` | `1.1` (melee) or `1.3` (ranged) |
| `lib:GetTank(mobName [, mobUnit])` | `unitName, threat` of the unit the mob attacks (`nil, 0` when nobody is known) |
| `lib:UnitDetailedThreatSituation(unit, mobUnit)` | `isTanking, status, threatPercent, rawThreatPercent, threat` — LibThreatClassic2 / Blizzard semantics |
| `lib:UnitThreatSituation(unit, mobUnit)` | `status` (3 tanking with the most threat, 2 tanking without it, 1 above the tank, 0 below) |
| `lib:EstimateHeal(unitName, amount)` | `effective, overheal` |
| `lib:IsGroupName(name)`, `lib:GetUnitByName(name)` | group membership, unit id |
| `lib.playerName`, `lib.petName` | the current names |
| `lib.Parser` | `Compile`, `Parse(category, text)`, `rules`, `missing` |

## Callbacks

`lib.RegisterCallback(target, event, method)`:

| Event | Arguments |
|---|---|
| `CombatLine` | `category, record, event` — every recognized line; `category` is `damage`, `heal`, `power`, `cast`, `miss` or `death`. The record table is reused: read it inside the call |
| `UnparsedLine` | `event, text` — a combat log line no template matched |
| `ThreatUpdated` | `unitName, mobName, threat` — `nil` threat: the entry is gone |
| `ThreatCleared` | `unitName` — the unit's whole table is gone |
| `ThreatEvent` | `unitName, mobName, delta, threat, reason` — every change with a readable reason (`sync` for a received value), for debugging and validating the numbers |

## Loading

Embed the folder and load `LibVanillaThreat-1.0.xml`, after LibStub and
CallbackHandler-1.0. The data table is versioned separately (`DATA_VERSION`
in `Spells.lua`), so the newest data wins among embedded copies.

The XML lists `Spells.lua` first and the library last, and the two files work
in either order. Keep the library last: on Unreal Azeroth a file listed before
another in a library's XML can run ahead of every other library, and the
library needs CallbackHandler-1.0 at load.

`Spells.lua` is generated: `scripts/gen_threat_data.py` in the Stuffs
repository, from the vmangos world database (`spell_threat`,
`spell_template`, build 5875).

## License

MIT, see `LICENSE`. The data comes from the vmangos world database; no
vmangos or LibThreatClassic2 code is included.
