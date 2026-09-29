# LibBanzai-1.0

Ace3v port of the Ace2 library **Banzai-1.0** (r14544), API-compatible.

Banzai tells you **who in your party or raid has aggro**. Five times a second it looks at what every
group member is targeting: when a member targets a hostile mob whose own target is another member,
that member builds up an aggro score. Above a threshold the member "has aggro"; the library fires an
event whenever that changes, and answers the question on demand.

```lua
local Banzai = LibStub("LibBanzai-1.0")

if Banzai:GetUnitAggroByUnitId("raid7") then
    -- raid7 is being attacked
end

Banzai.RegisterCallback(MyAddon, "Banzai_UnitGainedAggro", "OnGainedAggro")
function MyAddon:OnGainedAggro(event, unitid, targets)
    -- ...
end
```

It only sees a mob that somebody in the group is targeting — the same limitation as the original.
It is purely local: **no addon-channel traffic**, so there is no interoperability concern with
players running the Ace2 original.

## Dependencies

All hard.

```
LibStub\LibStub.lua
CallbackHandler-1.0\CallbackHandler-1.0.xml
AceCore-3.0\AceCore-3.0.xml
AceEvent-3.0\AceEvent-3.0.xml
AceTimer-3.0\AceTimer-3.0.xml
LibRosterLib-2.0\LibRosterLib-2.0.xml
LibBanzai-1.0\LibBanzai-1.0.xml
```

| Dependency | Used for |
|---|---|
| LibStub | registration |
| CallbackHandler-1.0 | the callback registry consumers subscribe to |
| AceCore-3.0 | table recycling (`new`/`del`) for the target lists, replacing the private compost heap |
| AceEvent-3.0 | not used directly; LibRosterLib-2.0 needs it |
| AceTimer-3.0 | the 0.2 s update |
| LibRosterLib-2.0 | the group, keyed by name; Banzai keeps its state in the roster's unit objects |

`CallbackHandler-1.0` must be **MINOR 7 or later** (the one in dh-harald/Ace3v), which fires like
upstream Ace3: `Fire(event, ...)`. With the older vanilla backport (MINOR 6, `Fire(event, argc, ...)`)
every callback payload would arrive shifted by one. LibRosterLib-2.0 must be **MINOR 2 or later**
for the same reason.

## Usage

```lua
local Banzai = LibStub("LibBanzai-1.0")
```

Not embeddable — there is no `:Embed()`, matching the Ace2 original.

The update timer starts when the file loads; there is nothing to enable. Until LibRosterLib-2.0 has
scanned the group (at `PLAYER_LOGIN`) the roster is empty and Banzai does nothing.

## How aggro is scored

Every 0.2 s, for each roster unit (pets included):

1. its score drops by 5 (not below 0);
2. if the unit's target is attackable both ways (`UnitCanAttack` from the player and back) and that
   target's target is a roster member, **that member** gains 10, and the unit's target id
   (`"raid3target"`) is added to the member's list of targets. The player's own target is read
   as `"target"`, whatever the player's roster id is;
3. the score is clamped to 0–25, and the unit has aggro while it is **above 15**.

So one member watching the mob is enough after a few ticks (+5 net per tick); two or more give aggro
at once. The order the roster is walked in affects exactly when a unit crosses the threshold, as in
the original.

## API

### `Banzai:GetUnitAggroByUnitId(unitId)`

`true` if the unit has aggro, `false` if not, `nil` if the unit is not in the roster **or has not been
scored yet** (its first tick after joining). Any unit id LibRosterLib can resolve works (`"party2"`,
`"raid7"`, `"pet"`, `"player"`).

### `Banzai:GetUnitAggroByUnitName(name)`

The same, by player (or pet) name.

### `Banzai:UpdateAggroList()`

One scoring pass. Runs on the timer; calling it yourself only makes the scores move faster.

### `Banzai:GetLibraryVersion()`

Returns `"LibBanzai-1.0", <minor>`. Compatibility shim for code written against AceLibrary.

### Fields on LibRosterLib's unit objects

Banzai writes `banzai` (the answer above), `banzaiModifier` (the score, 0–25 after a tick) and, during
a tick only, `banzaiTarget` into LibRosterLib-2.0's unit objects — `roster:GetUnitObjectFromName(name).banzai`
is the same value as `GetUnitAggroByUnitName(name)`.

## Callbacks

Subscribe with a **dot call**, passing your own object first. The handler receives the **event name**
as its first argument.

```lua
Banzai.RegisterCallback(MyAddon, "Banzai_UnitGainedAggro", "OnGainedAggro")
Banzai.UnregisterCallback(MyAddon, "Banzai_UnitGainedAggro")
Banzai.UnregisterAllCallbacks(MyAddon)
```

Events fire only on a **change**, never on a unit's first tick.

| Event | Payload after `event` |
|---|---|
| `Banzai_UnitGainedAggro` | `unitid, targets` |
| `Banzai_UnitLostAggro` | `unitid` |
| `Banzai_PlayerGainedAggro` | `targets` |
| `Banzai_PlayerLostAggro` | `unitid` — the player's roster unit id (`"raid4"`), not the mob; the original does the same |

`targets` is an array of the unit ids through which the attacker was seen, e.g.
`{ "target", "raid5target" }` — any of them works as a unit id for the mob while the event
runs. **The table is recycled as soon as the event returns — copy anything you need.**

The player events fire right after the unit event for the player's own roster entry.

## Example

```lua
local Banzai = LibStub("LibBanzai-1.0")

MyAddon = {}
Banzai.RegisterCallback(MyAddon, "Banzai_UnitGainedAggro", "OnGainedAggro")
Banzai.RegisterCallback(MyAddon, "Banzai_UnitLostAggro", "OnLostAggro")

function MyAddon:OnGainedAggro(event, unitid, targets)
    local mob = UnitName(targets[1])
    DEFAULT_CHAT_FRAME:AddMessage(UnitName(unitid) .. " has aggro from " .. (mob or "?"))
end

function MyAddon:OnLostAggro(event, unitid)
    DEFAULT_CHAT_FRAME:AddMessage(UnitName(unitid) .. " is safe")
end

-- pull style: no callback needed
local function IsTanking(unit)
    return Banzai:GetUnitAggroByUnitId(unit) == true
end
```

## Differences from the Ace2 version

1. **Lookup name.** `AceLibrary("Banzai-1.0")` → `LibStub("LibBanzai-1.0")`.
2. **`MINOR` is a plain integer** (starting at 1) instead of an SVN `$Revision:$` string.
3. **Callbacks instead of AceEvent-2.0.** Where you wrote
   `self:RegisterEvent("Banzai_UnitGainedAggro")`, now write
   `Banzai.RegisterCallback(self, "Banzai_UnitGainedAggro")`, and the handler gains a leading `event`
   parameter. The event names and payloads are unchanged.
4. **Built on LibRosterLib-2.0** instead of RosterLib-2.0, so its fixes apply here too — notably pets
   are refreshed (their aggro follows them when their unit id changes) and a renamed pet keeps one
   entry. See that library's README.
5. **The player's name is read on every tick**, not once when the library loads. The original stored
   `UnitName("player")` at load time; if the name was not known yet, the two `Banzai_Player*` events
   never fired for the whole session. Nothing changes when the name was right.
6. **No global `activate`.** The original declared its Ace2 activation function without `local`, so it
   overwrote any global of that name. The startup code is now local to the file.
7. **The private compost heap is replaced by AceCore-3.0's `new`/`del`.** The `targets` tables come
   from that shared pool, so the "copy what you need" rule is stricter than before: a table you keep
   may be handed to another library.
8. **The AceEvent-2.0 methods are gone from the library object** (`Banzai:RegisterEvent`,
   `:TriggerEvent`, `:ScheduleEvent`, ...). They came from embedding AceEvent-2.0 and were never part
   of the API. The library now carries AceTimer-3.0's methods instead.
9. **The unused `vars` field** the original copied between versions is dropped.
10. **`self:argCheck` / `:error` / `:assert` are gone**, since LibStub does not inject them. Banzai
    never used them.
11. **The player's own target is `"target"`**, not the roster id plus `"target"` (`"playertarget"`
    out of a raid, `"raid4target"` in one). Unreal Azeroth has no `"playertarget"` unit, so the
    original never saw the mob the player targets there. On the 1.12.1 client both name the same
    unit, so nothing changes there. A mob seen through the player appears as `"target"` in the
    `targets` lists.
