# LibVanillaDurations-1.0

Aura names and durations for the vanilla 1.12.1 client and Unreal Azeroth.

On these clients `UnitDebuff(unit, index)` returns only the texture, the
stack count and the dispel type: no name, no duration, no time left. This
library supplies them the way pfUI's libdebuff does:

- the **name** from a hidden tooltip (`SetUnitDebuff`);
- the **duration** from a spell-name table (pfUI's, extracted from the
  1.12.1 client's spell data, English names);
- the **start** from the scan that first finds the debuff on the unit,
  keyed by the unit's name (1.12 has no GUIDs).

Every time comes with an **`estimated`** flag:

- **exact** (`estimated` = `nil`): the previous scan of the same unit, at
  most 3 seconds earlier, did not have the debuff — it was seen landing,
  so the start is right to the scan interval;
- **estimated** (`true`): the first scan of the unit (also after a login or
  a reload), a debuff that was already there, or one that ran out while
  still on the unit (refreshed at an unknown moment). The full duration is
  counted from that scan, as pfUI does.

An addon that only wants real times ignores estimated ones, and keeps its
units scanned (`CheckUnit`, cheap while a unit has no debuffs) so their next
debuff is seen landing.

Other limits, the same as pfUI's: another caster's spell with several ranks
counts as the highest rank; non-English clients get names that are not in
the table, so no timers.

When a debuff is gone from a unit (dispelled, faded early), its stamp is
dropped, so a debuff applied again starts over.

```lua
local LVD = LibStub("LibVanillaDurations-1.0")

local i
for i = 1, 16 do
	local texture, stacks, debuffType = UnitDebuff("raid7", i)
	if texture then
		local name, timeLeft, duration, start, estimated = LVD:GetDebuff("raid7", i)
		-- timeLeft is nil when the spell has no known duration
		if timeLeft and not estimated then
			-- a real time left
		end
	end
end
```

Use the **unfiltered** index — the one `UnitDebuff(unit, index)` takes
without its third argument. Unreal Azeroth ignores the filter argument of
`GameTooltip:SetUnitDebuff`, so the name of a filtered index could belong to
another debuff there.

## API

| Call | Returns |
|---|---|
| `lib:GetDuration(name [, rank])` | seconds, or `nil` |
| `lib:GetDebuff(unit, index)` | `name, timeLeft, duration, start, estimated`; all but the name `nil` without a known duration; nothing for an empty slot |
| `lib:GetDebuffName(unit, index)` | name, or `nil` |
| `lib:GetTimeLeft(unit, name)` | `timeLeft, duration, start, estimated` of `name` on the unit, stamping it now (estimated) if it has no stamp yet; `nil` without a known duration |
| `lib:SetStamp(unitName, name, start, duration, mine, estimated)` | for an addon that knows a cast's exact start (its own casts); the last two optional |
| `lib:GetStamp(unitName, name)` | `start, duration, mine, estimated`, or `nil` |
| `lib:CheckUnit(unit)` | rescans the unit if its scan is stale |
| `lib:UpdateUnit(unit)` | rescans the unit now |

A unit's debuffs are rescanned at most once a second, or sooner after
`UNIT_AURA` for that unit id, a target change or a roster change. A stamp
set with `SetStamp(..., mine)` survives scans that do not find the debuff
yet for one second (the aura lands after the cast).

## Loading

Embed the folder and load `LibVanillaDurations-1.0.xml` (LibStub first).
The duration table is versioned separately (`DATA_VERSION` in
`Durations.lua`), so the newest table wins among embedded copies.

## License

MIT (`LICENSE`); the duration table is pfUI's, MIT, Copyright (c)
2016-2021 Eric Mauser (Shagu).
