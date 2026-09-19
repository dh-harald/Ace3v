# LibMobHealth-4.0

Estimates the real health of units the client only reports as a percentage. On 1.12.1
`UnitHealthMax` returns `100` for hostile mobs and players, so their health is only known in
percent. The library watches the damage dealt to the current target (`UNIT_COMBAT`) against the
percentage it loses (`UNIT_HEALTH`), derives the maximum health, and stores it per name and
level. WoW 1.12.1 (Lua 5.0) and Unreal Azeroth port of the TBC LibMobHealth-4.0 r68090 by
ckknight (inspired by MobHealth3), API-compatible. License: LGPL v2.1.

## Dependencies

```
LibStub\LibStub.lua
LibMobHealth-4.0\LibMobHealth-4.0.xml
```

LibStub is the only (hard) dependency.

## Loading / usage

Add the loader to the embedding addon's `.toc` or library XML:

```xml
<Include file="Libraries\LibMobHealth-4.0\LibMobHealth-4.0.xml"/>
```

```lua
local LMH = LibStub("LibMobHealth-4.0")
```

**Saved data.** The learned values live in two globals: `LibMobHealth40DB` (the health
database) and `LibMobHealth40Opt` (`save`, `prune`). To keep them across sessions, the embedding
addon lists them in its `.toc`:

```
## SavedVariables: LibMobHealth40DB, LibMobHealth40Opt
```

The library adopts them at `PLAYER_LOGIN`, when every addon's saved variables are loaded, so any
one addon declaring them is enough and every copy of the library shares the same data. Without
such an addon the data lasts one session. The library must be loaded before `PLAYER_LOGIN`
(not load-on-demand after login): the saved data, pruning and the slash command are set up by
that event.

Slash command: `/lmh`, `/lmh4`, `/libmobhealth`, `/libmobhealth4`:

- `/lmh` or `/lmh help` — show the settings
- `/lmh save` — toggle whether the data is saved (off: the database is dropped at logout)
- `/lmh prune <n>` — maximum number of stored entries, `0` disables pruning (default `1000`)

## API reference

Every function returns the native values untouched when `UnitHealthMax(unit)` is not `100`
(friendly units, party members, Beast Lore), so it can replace `UnitHealth`/`UnitHealthMax`
everywhere.

### `LMH:GetUnitHealth(unit)`

- `unit` (string) — a unit ID
- returns `current` (number), `max` (number), `known` (boolean). When no estimate exists:
  the native percentage values and `false`.

### `LMH:GetUnitMaxHP(unit)`

- returns `max` (number), `known` (boolean)

### `LMH:GetUnitCurrentHP(unit)`

- returns `current` (number), `known` (boolean)

### `LMH:GetMaxHP(name, level [, kind [, difficulty [, known]]])`

- `name` (string), `level` (number)
- `kind` (string, optional) — `"npc"`, `"pc"`, `"pet"` or `"legacy"` (imported MobHealth3
  data). Omitted: tried in that order.
- `difficulty` (number, optional) — always `1` on 1.12.1
- `known` (boolean, optional) — when true, return only an exact name+level match
- returns the maximum health (number) or `nil`

Without `known`, a missing level is extrapolated linearly from the same name at level ±1 or ±2.

Only the unit `"target"` is learned from. The library fires no events or callbacks.

## Example

```lua
local LMH = LibStub("LibMobHealth-4.0", true)

local function GetHealth(unit)
	if LMH then
		local cur, max = LMH:GetUnitHealth(unit)
		return cur, max
	end
	return UnitHealth(unit), UnitHealthMax(unit)
end

local cur, max = GetHealth("target")
DEFAULT_CHAT_FRAME:AddMessage(cur .. " / " .. max)
```

## Differences from the TBC version

1. **Lua 5.0 syntax**: no string methods (`("x"):match`), no `...` expressions, no
   `string.match`; `MINOR` is the literal `68091`.
2. **Event arguments are read from the `event`/`arg1..arg4` globals.** The dispatcher skips
   events whose handler has been cleared, because `UnregisterEvent` does not stop delivery on
   Unreal Azeroth.
3. **No focus unit**: `PLAYER_FOCUS_CHANGED` and every `"focus"` branch are removed.
4. **No instance difficulty**: `GetInstanceDifficulty()` is replaced by a constant `1`; the
   `npc[1..3]` data layout is kept.
5. **Saved data is set up at `PLAYER_LOGIN`, whichever addon declares it.** The TBC version only
   loaded `LibMobHealth40DB` when it ran as its own addon (`ADDON_LOADED` with its own name), so an
   embedded copy never saved anything. `IsLoggedIn()` (missing on 1.12.1) is not used.
6. **Upgrading an older loaded instance no longer clears `LibMobHealth40DB`**, which would have
   discarded the saved table of the declaring addon.
7. `hash_SlashCmdList` (missing on 1.12.1) is not touched; `/lmh` is registered through
   `SlashCmdList` only.
8. Bug fixes: the upgrade path read `oldLib.frame`, which was never stored (now `lib.frame`),
   and called `setmetatable({})` without a metatable; a `UNIT_COMBAT` event without an amount
   is ignored instead of raising an arithmetic error.
9. Kept as in the TBC version: every `UNIT_COMBAT` amount of the target is added up, including
   heals and energize events. A heal is normally discarded because the next `UNIT_HEALTH` shows
   the percentage going up, which resets the pending damage.
10. No standalone `.toc`; the library is embedded.
11. **Compacting and pruning also run at `PLAYER_LOGIN`**, on the data the previous session
    saved. Unreal Azeroth writes the saved variables on logout and `/reload` without delivering
    `PLAYER_LOGOUT` first, so a logout-only pass never ran there; the empty tables a session's
    lookups create are saved there and removed at the next login. With `save` off the database
    is dropped at login as well; on Unreal Azeroth that is the only place it happens, so a
    session that switched `save` off is still written once.
