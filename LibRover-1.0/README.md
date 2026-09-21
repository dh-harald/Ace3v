# LibRover-1.0

A travel router. Give it two points on Kalimdor or the Eastern Kingdoms and it answers with a
route: walk across zone borders, take a known flight path, a boat, a zeppelin, a portal, the
Deeprun Tram, a class teleport or the hearthstone, leg by leg, each leg carrying the text to show
the player. It builds a node graph out of its data files at startup (spread over frames as a list
of steps) and searches it with A*, also spread over frames, so neither blocks the client.

This is a port of **ZygorGuidesViewerClassic's LibRover-1.0** to **WoW 1.12.1** (stock and Unreal
Azeroth), built on LibStub, AceEvent-3.0, AceTimer-3.0, `LibTaxi-1.0` and `LibHereBeDragons-1.0`.
The Classic original needs `C_Map`, `C_TaxiMap`, `C_Garrison`, the retail flight map and a baked
neighbour cache; none of that exists here. **The single biggest consequence: 1.12 has no flying
mounts, so every implicit link in the graph is a walk** — see
*Differences from the ZygorGuidesViewerClassic version*.

## Dependencies

Load order, top to bottom:

```
LibStub\LibStub.lua
CallbackHandler-1.0\CallbackHandler-1.0.xml
AceEvent-3.0\AceEvent-3.0.xml
AceTimer-3.0\AceTimer-3.0.xml
LibHereBeDragons-1.0\LibHereBeDragons-1.0.xml
LibTaxi-1.0\LibTaxi-1.0.xml
LibRover-1.0\LibRover-1.0.xml
```

All are **hard** dependencies. `LibTaxi-1.0` must have been started (`LibTaxi:Startup(savedTable)`)
before LibRover's startup runs, because LibRover reads its flight points and their costs.
`LibBabble-Zone-2.2` is optional and only affects the localized zone names in leg texts, through
LibHereBeDragons-1.0.

## Loading and usage

```lua
local LibRover = LibStub("LibRover-1.0")
```

The library is also exported as the global `LibRover`, as the original was. It is not embeddable.

```lua
-- once, after PLAYER_LOGIN and after LibTaxi:Startup()
LibRover:SetHost{
	profile = MyAddonDB.profile,          -- optional, see UpdateConfig
	GetPlayerLevel = function() return UnitLevel("player") end,
	QuestComplete = function(id) return MyAddon:IsQuestComplete(id) end,
	GetReputation = function(factionid) return MyAddon:GetStanding(factionid) end,
	condEnv = { MyCondition = function() return true end },
}
LibRover:DoStartup()

-- then, whenever a destination is set
LibRover:QueueFindPath(0, 0, 0, destMapID, destX, destY, function(state, path, extra, reason)
	if state == "success" then MyAddon:ShowRoute(path) end
end, { player = true })
```

`am = 0` means "from the player's current position". Coordinates are **0-1**, as
LibHereBeDragons-1.0 uses them. `DoStartup` creates the library's own frame and drives both
startup and the searches from its `OnUpdate`.

## API

### Startup and configuration

| Signature | Does |
|---|---|
| `LibRover:DoStartup()` | build the node graph; spread over frames. Safe to call twice |
| `LibRover:StartupStep([ms])` | do up to `ms` of startup work now, for a host that drives its own startup queue |
| `LibRover:SetHost(table)` | supply the callbacks and the profile listed above; fields are optional and merge |
| `LibRover:UpdateConfig(profile)` | map a profile onto the config: `pathfinding`, `travelusehs`, `traveluseitems`, `travelusespells`, `pathfinding_comfort`, `pathfinding_speed` |
| `LibRover:GetCFG(field)` | read one config field, honouring `cfgNodeOverride` |
| `LibRover:SetGroundSpeed(mult)` | the player's ground speed as a multiplier of 7 yd/s (`1`, `1.6`, `2.0`); without it the level decides |
| `LibRover:SetDebug(on [, func])` | turn on the library's debug lines |
| `LibRover.ready`, `.initializing`, `.init_progress` | startup state; `init_progress` is 0-1 |
| `LibRover.ERRORS` | array of strings: data problems noticed at startup or while routing |

### Finding a path

| Signature | Does |
|---|---|
| `LibRover:QueueFindPath(am, ax, ay, bm, bx, by, handler, extradata)` | queue a search; the queue runs one at a time through an AceTimer |
| `LibRover:FindPath(am, ax, ay, bm, bx, by, handler, extradata)` | start a search now, replacing any running one |
| `LibRover:UpdateNow([quiet [, speed]])` | re-run the current search from the player's position |
| `LibRover:Abort(whence [, quiet])` | drop the queue and the running search |
| `LibRover:Stop()` | stop calculating but stay ready to update |
| `LibRover:ClearQueue()` | drop the queue only |
| `LibRover:IsDestinationImpossible(fromMap, toMap)` | `impossible, code, reason` — a destination off the two continents cannot be routed |

`handler(state, path, extradata, reason)` is called with `state`:

| state | meaning |
|---|---|
| `"progress"` | still searching; `extradata.progress` grows |
| `"success"` | `path` is the route, an array of nodes |
| `"failure"` | `reason` says why |
| `"arrival"` | the destination is already within arrival distance |

`extradata` is passed back untouched; `player = true` marks the start as the player, `title`
names the destination, `multiple_ends` is an array of extra end nodes, `direct = true` asks for a
straight line.

### The route

`path[1]` is the start, `path[n]` the destination. Each node carries:

| Field | Meaning |
|---|---|
| `m`, `x`, `y` | LibHereBeDragons map id and 0-1 position |
| `link` | how this node was reached: `{mode, cost, title, ...}`. `mode` is `walk`, `taxi`, `ship`, `zeppelin`, `portal`, `tram`, `teleport`, `hearth`, `astralrecall`, `useitem` |
| `text` | the line to show the player ("Ride the Zeppelin to Undercity") |
| `maplabel` | a short label for a map pin |
| `type` | node kind: `start`, `end`, `taxi`, `inn`, `border`, `portal`, `ship`, `zeppelin`, `misc` |
| `is_arrival` | this node is the *arrival* half of a transport pair, so a display may skip it |
| `taxiDestination`, `taxiFinal` | on a flight, the point the flight ends at |
| `cost`, `time` | accumulated cost and estimated seconds |

Also on the library: `RESULTS` (the last route), `RESULTS_FAIL` (the last too-expensive one),
`RESULTS_SKIPPED_START` / `RESULTS_SKIPPED_END` (legs the optimiser removed, with the reason),
`RESULTS_ASSUMED_TAXI` (the route uses a flight point whose state is unknown).

### Nodes and maps

| Signature | Returns |
|---|---|
| `LibRover:GetMapByNameFloor(name [, floor])` | map id for an English zone name; `"Zone/0"` is accepted |
| `LibRover:GetFloorByMapID(m)` | always `0` — vanilla maps have one floor |
| `LibRover:GetMapContinent(m)` | `13` (Kalimdor) or `14` (Eastern Kingdoms), else `nil` |
| `LibRover:GetPlayerPosition()` | `x, y, m` |
| `LibRover:GetNearestTaxiInZone()` | `node, distance` for the nearest flight point in the player's zone |
| `LibRover:CheckMaxSpeeds()` | recompute `maxspeedinzone`; `{maxspeed, runspeed, flyspeed}` per zone, flyspeed always `0` |
| `LibRover:FindNode(m, f, x, y)` | the node at that spot, if any |
| `LibRover:Explain()`, `:PathToString([path])` | a text dump of the graph state and the last route |
| `LibRover.nodes` | `all`, and one array per type: `taxi`, `inn`, `border`, `mageteleport`, … |
| `LibRover.banned_nodes` | `[node] = true` makes the router avoid it |

### Messages

Through AceEvent-3.0's message bus:

```lua
LibRover.RegisterMessage(self, "LIBROVER_READY", function(event) ... end)
LibRover.RegisterMessage(self, "LIBROVER_TRAVEL_REPORTED", function(event) ... end)
```

`LIBROVER_READY` fires when startup finishes, `LIBROVER_TRAVEL_REPORTED` after each successful
route. The library itself listens for `LibTaxi_KnowledgeChanged` and re-plans when the character
learns a flight path.

## Example

```lua
local LibRover, LibTaxi = LibStub("LibRover-1.0"), LibStub("LibTaxi-1.0")
local HBD = LibStub("LibHereBeDragons-1.0")

MyAddonTaxis = MyAddonTaxis or {}

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	LibTaxi:Startup(MyAddonTaxis)
	LibRover:DoStartup()
end)

LibRover.RegisterMessage("MyAddon", "LIBROVER_READY", function()
	-- route to the Undercity bank
	local dest = HBD:GetMapIDFromZoneName("Undercity")
	LibRover:QueueFindPath(0, 0, 0, dest, 0.63, 0.48, function(state, path, extra, reason)
		if state == "success" then
			for i = 2, table.getn(path) do
				DEFAULT_CHAT_FRAME:AddMessage(i-1 .. ". " .. path[i].text)
			end
		elseif state == "failure" then
			DEFAULT_CHAT_FRAME:AddMessage("no route: " .. tostring(reason))
		end
	end, { player = true })
end)
```

## Differences from the ZygorGuidesViewerClassic version

1. **No flying, so no fly links.** 1.12 has no flying mounts at all (the original's own
   `HasFlyingMount` returns `false` for Classic). `Node:CanFlyTo` always declines, `DoLinkage`
   only ever creates `walk` links, and `maxspeedinzone`'s third value is always `0`. Everything
   that is not walking is a **hardwired** link out of the data files: a border crossing, a boat, a
   zeppelin, a portal, the tram, a flight path, a teleport, the hearthstone. This removes the
   largest part of the original's cost model and all of its per-zone flight exceptions.
2. **Ground speed comes from the level, or from the host.** 1.12 has no `IsSpellKnown`, no
   `GetUnitSpeed`, and the riding skill cannot be read without matching a localized string, so the
   default is level-based (60 → ×2.0, 40 → ×1.6, else ×1.0). `SetGroundSpeed` overrides it.
3. **No ZGV.** Everything the original read off that global comes from `SetHost` (player level,
   quest completion, reputation, condition functions, the options profile) or from the library
   itself. The `{cond:ZGV:RaceClassMatch('DRUID')}` conditions in the data are now
   `{cond:RaceClassMatch('DRUID')}`, evaluated in the library's own condition environment, which a
   host may extend. No `ZGV` global is read.
4. **Map ids are LibHereBeDragons ids, resolved from English zone names.** The original's
   `data.MapIDsByName` table of Classic uiMapIDs (1411-1464) is gone, as is `RemapData` (it is
   keyed on `UnitPosition` rectangles and 1.12 has no `UnitPosition`). `GetMapByNameFloor` asks
   LibHereBeDragons; `GetPlayerPosition` is `HBD:GetPlayerZonePosition()`.
5. **Floors are gone.** Vanilla maps have one level each: `node.f` is always `0`,
   `GetFloorByMapID` returns `0`, and the floor-crossing and indoor-zone data (both already empty
   in Classic) are kept only as empty tables.
6. **No dungeon maps.** Every entry of Classic's `data_dungeons.lua` is commented out, and a
   vanilla instance has no map coordinates at all, so the file is not shipped, the faked dungeon
   map ids (9001-9026) are gone, and `data.DungeonMaps` is an empty table.
7. **No baked neighbour cache.** `LibRoverCache_ally/horde.lua` index their links by node creation
   order, which this port does not reproduce, so the links are computed at startup instead —
   ~176 nodes, which is small enough to do in the startup steps. `ProcessBakedNeighbourCache`,
   `NeighbourhoodCache_*` and the version/count mismatch warnings are gone with it.
8. **Eastern Kingdoms parts are set tables, not a bitmask.** `zone_same_eastern_part` used
   `bit.band`/`bit.bor`, and whether the `bit` library exists on 1.12.1 and Unreal Azeroth is
   unverified.
9. **`debugprofilestop` is `GetTime()*1000`**, and all 70-odd timing instrumentation counters, the
   `debug_*` node-and-link tracing, the DEV menus, the dump functions, the in-game test framework,
   the Flight Master's Whistle predictor and the mole-machine handler are dropped. `Explain`,
   `PathToString` and `SetDebug` remain, and a node's `costdesc` still records why it cost what it
   cost when debug is on.
10. **Events are Ace3v events read from globals.** `ZONE_CHANGED*`, `PLAYER_ENTERING_WORLD`,
    `LEARNED_SPELL_IN_TAB` and `PLAYER_CONTROL_LOST`/`GAINED` replace `NEW_WMO_CHUNK`,
    `LOADING_SCREEN_DISABLED`, `UNIT_SPELLCAST_SUCCEEDED`, `UNIT_FLAGS` and the achievement and
    vehicle events. Taxi state is `UnitOnTaxi` plus the control events, as in LibTaxi-1.0.
11. **Item and spell lookups are 1.12 shaped.** `IsSpellKnown` is a spellbook scan against
    `LibRover.spellnames` (the eight teleport/recall spells the data uses, by English name — a host
    on a localized realm should replace that table or answer `SetHost{IsSpellKnown=...}`),
    `GetItemCount` and `GetCooldownWithoutGCD` walk the bags with
    `GetContainerItemLink`/`GetContainerItemCooldown`, and there is no global-cooldown spell to
    compare a cooldown against.
12. **Everything TBC and later is gone**: Argus, the Vindicaar, garrisons, Draenor, Legion,
    Pandaria, Shadowlands and Dragonflight zone rules, flying-mount licences, achievements,
    `C_MountJournal`, `C_Garrison`, `C_Scenario`, `C_QuestLog`, toys, the whistle, the mole
    machine, the Dalaran and garrison hearthstones, warlock summons and courtesy portals, and the
    text templates for all of them.
13. **Three bug fixes.** All three are hangs or silent data loss, not behaviour changes:
    - **The open-node heap never emptied.** `RemoveCheapest` did
      `heap[1], heap[self.count] = heap[self.count], nil`; with one node left those are the same
      slot and the order of a multiple assignment is unspecified, so the node could survive the
      removal. `RemoveCheapest` then handed out the same closed node for ever — which is exactly
      what happens on a route that does not exist, and a vanilla router hits that regularly
      (Alliance asking for the Horde zeppelin's far side). Written out explicitly now.
    - **`AddNeigh` used a raw array assignment.** `self.n[#self.n+1] = ...` is fine in Lua 5.1,
      but in 5.0 it does not update the table's stored size, so the first `table.remove` on a
      node's neighbour list froze that size: later links overwrote one slot, and once the stored
      size reached `0` with entries still in the array `table.remove` became a no-op and
      `RemoveNeighType` span for ever. It uses `table.insert` now.
    - **Two caches never filled on the first call.** `CheckMaxSpeeds` and the spellbook cache
      guarded themselves with `GetTime() - stamp < 1` (or `< 5`) starting from a stamp of `0`.
      `GetTime()` is the client's uptime and is under a second right after a reload, so the first
      call was skipped and every zone kept the default speed while every spell read as unknown.
      Both now use `nil` to mean "not measured yet", including where the cache is invalidated.
14. **Two behaviours preserved although they look wrong.** A `<faction:A>` attribute on a *text*
    node is not a faction filter (only `{fac:A}` on a link is, and only `data.faction` on an array
    node) — the mage teleports therefore exist as nodes for both factions, and are excluded by the
    spell being unknown, exactly as in the original. And `StepPath` returning `"TIMEOUT"` at
    `calculation_step_limit` is still not handled by the driver, because no vanilla route comes
    near 9999 steps (the longest in the offline tests is 141); the limit is left in place as a
    tripwire rather than silently raised.

15. **No coroutines.** The 1.12.1 client has no `coroutine` library (Unreal Azeroth does), and the
    original ran both its startup and its search as coroutines. The startup is now a list of
    named steps (`AddStartupStep`), run by `StartupStep` as many per frame as the budget allows,
    with the "wait until pathfinding is on" suspension as a step's `wait` function; the per-item
    yields inside a step are gone, as the vanilla data is small. The search is a state table in
    `Lib.thread`: `PathStep` sets the path up on its first call and runs one A* step per later
    call, returning the codes the coroutine yielded (`PENDING`, `SUCCESS`, `END`, `ERROR`) to
    the unchanged `OnUpdate` driver, which calls it through `pcall` as it called `resume`.
    `InitializePath` runs in one go. `Lib.startup_thread` is replaced by `Lib.startup_steps`.

## Licence

Ported from ZygorGuidesViewerClassic's `Libs/LibRover-1.0/`, author **sinus**
(sinus@sinpi.net). The original declares **MIT** in both places it says anything: the file header
of `LibRover-1.0.lua` and its own `LibRover-1.0.toc` (`## X-License: MIT`). The `X-License: GPL`
on `ZygorGuidesViewerClassic.toc` belongs to the *addon*, not to this embedded library.

MIT asks for the copyright and permission notice to travel with the code, so the original header
block is kept verbatim at the top of every ported file, and this port is marked as a port rather
than as original work. Guide content is not included and was never copied.

## Not verified in game

Measured only by the user, later, on 1.12.1 and Unreal Azeroth. Nothing below is known to work:

1. **Startup time.** 176 nodes and their links are built in 14 steps, as many per frame as fit in
   50 ms; the largest step (`dolinkage`) runs whole within one frame, so a real client's speed
   decides whether it is visible as a hitch.
2. Whether `IsIndoors` and `IsSwimming` exist (both are guarded, and only feed region matching)
   and whether `UnitOnTaxi` answers — without it a flight does not re-plan on landing.
3. `GetBindLocation()`'s text against the inn names in `data_inns.lua`: the match is exact and
   English, so the hearthstone leg is only found on an enUS client. A localized client needs a
   subzone translation, which `LibBabble-SubZone` would provide and this project has not ported.
4. The ground-speed default (deviation 2) against a character who has a mount but is under 40, or
   is 60 without an epic mount.
5. Real routes and re-routing on zone change, on landing from a flight, and while the queue holds
   several requests.
6. That the leg texts read correctly in game, including the `{npc}`, `{item}` and `{spell}`
   substitutions: `{item}` has no item-name source here at all and falls back to the word "item",
   and `{npc}` uses the flight master names LibTaxi-1.0 carries.
