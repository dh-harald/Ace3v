# LibTaxi-1.0

A library that records which flight paths the character knows, and what the flights between them
cost. It carries the 61 vanilla flight points of Kalimdor and the Eastern Kingdoms with their
coordinates, factions and flight masters, plus the flight-time graph between them; it learns what
the character knows from the flight master's map and from "New flight path discovered!", and it
keeps that knowledge in the consuming addon's saved variables. `LibRover-1.0` uses it as the taxi
layer of its route finder.

This is a port of **ZygorGuidesViewerClassic's LibTaxi-1.0** to **WoW 1.12.1** (stock and Unreal
Azeroth), built on LibStub, AceEvent-3.0 and `LibHereBeDragons-1.0` instead of the Classic map
API. The Classic original needs `C_TaxiMap`, `C_Map` and the retail flight-map frame; none of
those exist here. The public API is kept where it still makes sense — see
*Differences from the ZygorGuidesViewerClassic version*.

## Dependencies

Load order, top to bottom:

```
LibStub\LibStub.lua
CallbackHandler-1.0\CallbackHandler-1.0.xml
AceEvent-3.0\AceEvent-3.0.xml
LibHereBeDragons-1.0\LibHereBeDragons-1.0.xml
LibTaxi-1.0\LibTaxi-1.0.xml
```

All four are **hard** dependencies. `LibBabble-Zone-2.2` is optional and only affects
LibHereBeDragons-1.0's localized zone names, which this library uses for `LastTaxi.zone`.

There is no dependency on `LibRover-1.0`: the two are independent, and LibRover reads this
library rather than the other way round.

## Loading and usage

Add the lines above to your addon's `.toc` or load XML, then:

```lua
local LibTaxi = LibStub("LibTaxi-1.0")
```

The library is also exported as the global `LibTaxi`, as the original was. It is not embeddable —
there is no `:Embed`.

Nothing happens until the addon starts it with a table to keep the character's knowledge in.
That table belongs in **character-scoped** saved variables:

```lua
LibTaxi:Startup(MyAddonDB.char.taxis)
```

`Startup` reads the data, resolves every flight point onto a LibHereBeDragons map id, restores
what the saved table already knows, hooks `TakeTaxiNode` and registers its events. Call it once,
after `PLAYER_LOGIN` (it reads `UnitFactionGroup`, which answers `nil` earlier).

## API

### Startup and configuration

| Signature | Does |
|---|---|
| `LibTaxi:Startup(savedTable)` | initialise against a character-scoped saved table. Required once |
| `LibTaxi:SetDebug(on [, func])` | turn the library's debug lines on; `func(message)` receives them instead of `DEFAULT_CHAT_FRAME` |
| `LibTaxi.ready` | `true` once `Startup` has finished |
| `LibTaxi.errors` | array of strings: data problems the library noticed (a zone it could not resolve, a flight point on the taxi map that is not in the data, a name with no translation). Empty in the normal case |

### Finding flight points

| Signature | Returns |
|---|---|
| `LibTaxi:FindTaxi(name [, trim])` | the flight point node for an **English** name, or `nil`. Skips the enemy faction's nodes. With `trim`, a `"Name, Zone"` argument is cut down first. Results are cached |
| `LibTaxi:FindTaxiByTag(cont, tag)` | the node for a position tag on a continent, or `nil` |
| `LibTaxi:FindTaxiBySlotData(cont, taxi)` | `node, "tag"|"name"` for one entry of `GetTaxiDataBySlot`, resolved by tag first and by (translated) name second |
| `LibTaxi:GetTaxiByTarget()` | the node whose flight master is the current target, or `nil` |
| `LibTaxi:GetMapContinent(mapID)` | `13` (Kalimdor) or `14` (Eastern Kingdoms) for any zone map id, else `nil` |
| `LibTaxi:GetCurrentMapContinent()` | the same for the player's zone |
| `LibTaxi.TaxiTag(x, y)` | the `"%03d:%03d"` tag of a 0-1 position, as the data records them |
| `LibTaxi.TrimZone(name)` | a flight point name without its `", Zone"` / `"，Zone"` tail |
| `LibTaxi.is_enemy(f1, f2)` | `true` when the two faction letters are opposed |

A **node** is a table from `data.lua`, extended by `Startup`:

| Field | Meaning |
|---|---|
| `name` | English flight point name |
| `localname` | the name this client shows, when known |
| `faction` | `"A"`, `"H"` or `"B"` (both); absent means both |
| `npc`, `npcid` | the flight master, English name and creature id |
| `localnpc` | the flight master's name in this locale, when the locale file has one |
| `x`, `y` | **0-1** position on its zone map (`data.lua` stores percent; `Startup` divides) |
| `m` | LibHereBeDragons map id of the zone |
| `c` | continent map id, `13` or `14` |
| `taxitag` | position tag, assigned by `MergeData` from the flight-cost data |
| `known` | `true` known, `false` known to be unknown, `nil` not established |
| `taxicosts` | `[neighbour node] = seconds`; `0` means "connected, time unknown" |

### Knowledge

| Signature | Does |
|---|---|
| `LibTaxi:LearnTaxi(node, learn)` | set one node's `known` state and write it to the saved table, under both its name and its tag |
| `LibTaxi:LearnCurrentTaxi([false])` | learn (or with `false` unlearn) the flight point the player is standing at; returns the node. Tries the target's flight master, then the minimap subzone, then the zone |
| `LibTaxi:MarkKnownTaxis()` | fill every node's `known` from the saved table |
| `LibTaxi:MarkContinentSeen(cont [, operator])` | mark the continent scanned: every node still `nil` there becomes `false` |
| `LibTaxi:MarkNeightboursUnknown(node)` | mark the neighbours of a node with no paths unknown (needs LibRover's links) |
| `LibTaxi:ClearContinentKnowledge(cont, operator, status)` | set one continent's nodes to `status`; `operator` `"all"` for every node |
| `LibTaxi:ClearAllKnowledge([status])` | the same for both continents; also wipes the saved table unless `status` is `true`, keeping the measured trip times and localized names |
| `LibTaxi:ResetKnowledge()` | `ClearAllKnowledge` then `MarkKnownTaxis` |
| `LibTaxi:IsContinentKnown([cont])` | `known, suspicious` — whether that continent has been scanned |

`LibTaxi.master` is the saved table itself. Reading it gives a three-way answer: `true` known,
`false` seen-but-not-known, `nil` never established.

### The flight master's map

| Signature | Does |
|---|---|
| `LibTaxi:ScanTaxiMap()` | read the open flight map: mark every node known or unknown, record the names it shows, mark the continent seen. Runs by itself on `TAXIMAP_OPENED` |
| `LibTaxi:GetTaxiDataBySlot()` | `taxidata, taxidata_by_slot` — one entry per slot of the open map: `name`, `slotIndex`, `state`, `taxitype`, `position = {x, y}`, `taxitag` |
| `LibTaxi.FlightPathState` | `{ Current = 0, Reachable = 1, Unreachable = 2 }`, the `state` values |

### Flights taken, and their times

| Signature | Does |
|---|---|
| `LibTaxi.LastTaxi` | the flight the player last boarded: `{ name, fullname, zone, node, route, eta, departure, cont }`. `route` is the list of slot entries the flight passes, `eta` its estimated length in seconds (`nil` when it cannot be worked out), `departure` the `GetTime()` of boarding |
| `LibTaxi:GetTaxiTripTime(tag1, tag2)` | `seconds, precise` for a direct flight; `precise` is `false` when the number is a distance estimate. `false, false, reason` when it cannot answer |
| `LibTaxi:RecordTripTime(seconds)` | attribute a measured flight time to `LastTaxi`'s connection (single-hop flights only) |
| `LibTaxi:ImportTaxiTimes()` | load previously measured times out of the saved table |

Single-hop flights are timed automatically and saved, so the many `0` entries in the shipped
flight-cost graph fill in as the character flies.

### Messages

Through AceEvent-3.0's message bus, so any AceEvent-3.0 embedder can listen:

```lua
LibTaxi.RegisterMessage(self, "LibTaxi_KnowledgeChanged", function(event) ... end)
LibTaxi.RegisterMessage(self, "LibTaxi_TaxiTaken", function(event, lastTaxi) ... end)
```

| Message | Payload | Fired when |
|---|---|---|
| `LibTaxi_KnowledgeChanged` | none | a flight map was scanned, or a flight path was learned or unlearned |
| `LibTaxi_TaxiTaken` | `LastTaxi` | the player boarded a flight |

Note the `.` on `RegisterMessage`, and that a handler receives the message name first. The
original called into ZGV and LibRover directly; these messages replace that.

## Example

```lua
local LibTaxi = LibStub("LibTaxi-1.0")

-- one character-scoped table, kept in saved variables
MyAddonTaxis = MyAddonTaxis or {}

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	LibTaxi:Startup(MyAddonTaxis)

	local node = LibTaxi:FindTaxi("Crossroads")
	if node and node.known then
		DEFAULT_CHAT_FRAME:AddMessage(node.name .. " is known, at "
			.. string.format("%.1f, %.1f", node.x * 100, node.y * 100))
	end

	local seconds, precise = LibTaxi:GetTaxiTripTime(node.taxitag, "628:443")
	if seconds then
		DEFAULT_CHAT_FRAME:AddMessage(string.format("%d s to Orgrimmar%s",
			seconds, precise and "" or " (estimated)"))
	end
end)

LibTaxi.RegisterMessage("MyAddon", "LibTaxi_KnowledgeChanged", function(event)
	-- re-plan whatever depended on which flight paths are known
end)
```

## Differences from the ZygorGuidesViewerClassic version

1. **No ZGV.** Every `ZGV.*` reference is gone: `ZGV.db` is replaced by the table passed to
   `Startup`, `ZGV:Debug` by `SetDebug`, `ZGV.CoroPairs` / `ZGV.OrderedPairs` by local helpers,
   and the direct calls into ZGV and LibRover by the two messages above. No `ZGV` global is read.
2. **Continent keys are LibHereBeDragons map ids.** `data.lua` is keyed `13` (Kalimdor) and `14`
   (Eastern Kingdoms) instead of the Classic uiMapIDs 1414 / 1415, and `GetMapContinent` returns
   one value instead of the Classic `cont, cont_scan, extracont` triple. Zone keys stay English
   names and are resolved with `HBD:GetMapIDFromZoneName`.
3. **Coordinates are normalised to 0-1 at startup.** `data.lua` keeps the original percent
   values; `Startup` divides them, so `node.x` is 0-1 and works directly with
   LibHereBeDragons. In Classic this division happened by accident, later, inside LibRover's
   `AddNode`, which left `GetTaxiTripTime`'s distance estimate 100× too large until then.
4. **Node ids are gone.** Vanilla has no `TaxiNodeID`, and neither the Classic data nor the
   client offers one here, so `FindTaxiByNodeID`, `fc_by_nodeID`, `fcnames_by_nodeID`,
   `fnode_by_nodeID` and the `nodeID` half of every lookup are dropped. The position **tag**
   (`"%03d:%03d"` of `TaxiNodePosition`) is the primary key, the flight point **name** the
   secondary one.
5. **The slot tag is read with the y axis either way, and the name is a second chance.** Both 1.12.1
   and Unreal Azeroth give `TaxiNodePosition`'s y from the bottom of the map (measured: Thunder
   Bluff reads `0.4495, 0.4385` against the recorded `449:561`, Orgrimmar `628:556` against
   `628:443`); the Classic client the tags were taken on measures from the top. `GetTaxiDataBySlot` keeps the reading the continent's recorded tags know, so the slot's
   `taxitag` is always in the data's form, which `GetTaxiTripTime` and the flight timing rely on.
   A slot that matches neither way is matched by its name — translated through the locale table,
   and with the `", Zone"` tail cut off. The Classic original only ever matched by tag or node id.
6. **The flight master is recognised by name, not by GUID.** 1.12 has no `UnitGUID`, so
   `GetTaxiByTarget` matches `UnitName("target")` against the flight master names in the data
   (`npc2node`, English plus the locale's own names). The enemy faction's flight masters are not
   in that index.
7. **`LearnCurrentTaxi` has a third attempt.** Target's flight master, then `GetMinimapZoneText`,
   then `GetRealZoneText` — the last one covers the capitals, whose flight point is named after
   the city. The three minimap subzone exceptions (Trade District, The Great Forge, Valley of
   Strength) are kept; the TBC ones (Terrace of Light, The Stair of Destiny) are dropped.
8. **`ERR_NEWTAXIPATH` and `ERR_TAXINOPATHS` are read from `arg1`.** The Classic original read
   `arg2`; in 1.12 `UI_INFO_MESSAGE` / `UI_ERROR_MESSAGE` put the text in `arg1`. Handlers read
   the `arg1` global, because Ace3v's AceEvent-3.0 passes only the event name.
9. **Taxi state comes from `PLAYER_CONTROL_LOST` / `PLAYER_CONTROL_GAINED` plus `UnitOnTaxi`**,
   not `UNIT_FLAGS`, and the flight is timed off `LastTaxi` instead of guessing the nearest
   flight point. A single-hop flight's measured time is written into the flight-cost graph and
   into `savedTable.taxitimes`, and `ImportTaxiTimes` restores it next session. The Classic
   original kept those in `ZGV.db.global.taxitimes` and only measured them for developers.
10. **`TakeTaxiNode` is replaced by a plain global wrapper**, not hooked through AceHook, and it
    is called with one argument (the Classic call passed two extra retail ones). This is the same
    pattern LibHealComm-1.0 uses, measured to work on both clients. The recording runs inside
    `pcall`, so a data problem can never stop a flight.
11. **Everything TBC and later is gone**, with the code that served it: Argus (`UpdateAntoranTaxis`,
    the rotating-node table, the `argusportal` operator), `C_TaxiMap`, `C_Map`, `Enum.FlightPathState`,
    `FlightMapFrame`, `hooksecurefunc(WorldMapFrame, ...)`, `FlashClientIcon`, the Shattrath and
    Dark Portal minimap exceptions, the TBC/WotLK flight point names in the locale tables, and the
    Aldor/Scryers slot patch in `GetTaxiDataBySlot`.
12. **Every developer function is dropped**: `DeepScanTaxiMap`, `DEV_ViewTaxiMapData`,
    `DEV_FindNodeIDs`, `DEV_ConvertCostsToNodeID`, `DEV_FixByDupes`, `DEV_DumpFlightCosts`,
    `Debug_HookButtons`, `SetupTaxiTooltips`, `OnTimer`, `TestAllFlights`, `DumpTaxiByTarget`,
    `MarkKnownByLevels` (which was already dead), and the in-memory flight-cost mutation
    `ScanTaxiMap` did for them. A flight point on the map that is not in the data is recorded in
    `LibTaxi.errors` instead.
13. **`ScanTaxiMap` works on the first flight master of a session.** In Classic, `Startup` cached
    the tag→node map *before* `MergeData` assigned the tags, so the cache stayed empty and the
    first scan of every session resolved nothing (it only worked from the second flight master
    on, because the scan re-cached at its end). `MergeData` now caches between its two passes.
14. **`MarkKnownTaxis` falls back to the name key.** The Classic original looked up
    `master[nodeID or tag or name]`, so a node with a tag never consulted its name. Both are
    tried now, tag first, which is what makes a saved table survive a client whose
    `TaxiNodePosition` disagrees with the recorded tags.
15. **The locale files are plain data, picked up by the main file.** Each `Locales-<locale>.lua`
    stores `LibTaxi_Locales.<locale> = { TAXINAMES = ..., NPCNAMES = ... }` and depends on
    nothing; `LibTaxi-1.0.lua` takes the client's locale out of it and clears the global. `data.lua`
    does the same with `LibTaxi_Data`. Both are adopted at load *and* at `Startup`, so either
    order of the XML's scripts works. This is forced by the 1.12.1 client silently skipping a
    `<Script>` path with a subdirectory, and by Unreal Azeroth having been seen running locale
    files ahead of every other script of the including XML.
16. **The reverse name lookup is fixed, and silent.** The original converted its `true` values
    with `if lo==1`, which never matched, so every untranslated name landed in the reverse table
    under the boolean key `true` — one entry for all of them. It also printed a "please report
    this to Zygor" line for every missing key. Missing keys now return the key itself and are
    recorded once each in `LibTaxi.errors`.
17. **Locale coverage, and where it comes from.** The flight point names for deDE, esES and frFR
    are the original's client-extracted tables, reduced to the vanilla flight points, with one
    repair: the esES name for Booty Bay was byte-damaged (`"Baháa del Botán"`) and is now
    `"Bahía del Botín"`. zhCN is new, from a VMaNGOS 1.12 world database. Flight **master** names
    (server-side strings, so the world database is authoritative) are shipped for esES, ruRU and
    zhCN; deDE and frFR keep the English ones, which is what the database says they are.
    **ruRU flight point names are derived, not extracted.** Vanilla's `TaxiNodes.dbc` has no
    Russian column at all — there was no Russian 1.12 client — so no client and no database carries
    these names. What the world database does carry is `locales_area`, whose ruRU column the server
    projects added later, and a flight point's name is the name of the place it stands in. Each
    Russian area name was located through the German, French, Spanish or Chinese name already known
    for that point, and taken only where **two of those agree** on the same area row: 52 of the 54
    names, 59 of the 61 flight points. `Grom'gol` and `Theramore` found no match and fall back to
    English. This is the one locale whose names are inferred rather than read off a client — verify
    it in game before trusting it. koKR and zhTW are available from the same source but not shipped.
18. **`GetTaxiTripTime` takes tags**, never node ids, and estimates through
    `HBD:GetZoneDistance` (returning `false, false, "no distance"` across continents, where
    LibHereBeDragons declines to guess) instead of `ZGV.MapCoords.Mdist`.
19. **Behaviour deliberately preserved, though it looks wrong.** The `known_by_continent_mt`
    metatable looks up `path2cont[name]`, which holds a bare continent id, while every writer
    marks a scanned continent as `"c_<id>"` — so the metatable's middle state is unreachable. It
    is kept: `MarkContinentSeen` already writes `false` to every unseen node explicitly, so the
    dead branch changes nothing. `MarkContinentSeen` likewise tests `node.operator`, while the
    data only ever sets `taxioperator`; with the vanilla data both are `nil`, so every unseen node
    is falsified as intended. Enemy-faction flight points are **not** pruned from the data, which
    is what the original did too (its `enemyfac` was the string `"DON'T PRUNE"`).

## Licence

Ported from ZygorGuidesViewerClassic's `Libs/LibTaxi-1.0/`, author **sinus** (sinus@sinpi.net).
The original makes **two declarations that do not agree**, and both are recorded here because the
choice matters:

- `LibTaxi-1.0.lua`'s header: *"Free for non-commercial use, except for Zygor Guides."*
- `Libs-Classic/LibTaxi-1.0/LibTaxi-1.0.toc`: `## X-License: MIT`

Which one governs does not have to be settled for **use**, because the intended use is inside both:
the consuming project (ZygorGuidesViewerNG) is a **non-commercial hobby project whose author is not
part of the Zygor team**, and non-commercial use is permitted under MIT (which permits everything)
and under the header (which permits exactly that). The `X-License: GPL` on
`ZygorGuidesViewerClassic.toc` belongs to the *addon*, not to this embedded library — and that
declaration has no licence text, no version and no per-file notice behind it, besides contradicting
this library's non-commercial line, which a GPL work cannot validly contain.

The two readings do **diverge on redistribution**. MIT grants it in as many words ("copy, modify,
merge, publish, distribute"); the header speaks only of *use*. So publishing a copy — into the
public Ace3v repository, say — leans on the more permissive of two statements the same author wrote,
rather than on their intersection. That is a defensible position, not an identical one, and it is
recorded here rather than smoothed over. Nothing here is legal advice.

MIT's one condition is that the notice travels with the code, so the original header block is kept
verbatim at the top of the ported file, this port is marked as a port rather than as original work,
and guide content is not included and was never copied.

## Not verified in game

Measured only by the user, later, on 1.12.1 and Unreal Azeroth. Nothing below is known to work:

1. The flipped tag for every flight point (deviation 5): measured for the nine Horde Kalimdor
   points on 1.12.1 and Orgrimmar on Unreal Azeroth, all matching by tag. A flight point matching
   neither reading still matches by name.
2. Whether `UnitOnTaxi` exists and answers on both clients; without it no flight is timed.
3. That opening a flight master records the known flight paths, and that
   "New flight path discovered!" learns the new one, on a localized client too.
4. The flight master name matching on a localized realm (deviation 6): the world database this
   was built from must be the realm's own.
5. The seven deDE and two frFR names where the original's table and the world database disagree
   on the translation rather than on whether there is one: Chillwind Camp
   (`Zugwindlager` / `Chillwind-Lager`), Marshal's Refuge (`Marschalls Zuflucht` /
   `Marshals Zuflucht`), Revantusk Village (`Dorf der Bruchhauer` / `Revantusk`), Shadowprey
   Village (`Schattenflucht` / `Shadowprey`), Splintertree Post (`Splitterholzposten` /
   `Splintertreeposten`), Zoram'gar Outpost (`Außenposten von Zoram'gar` /
   `Zoram'gar-Außenposten`), frFR Flame Crest (`Corniche des flammes` / `Corniches des flammes`)
   and Revantusk Village (`Village des Vengebroches` / `Village des Revantusk`), plus esES
   Thorium Point (`Puesto del Torio` / `Puesto del Thorium`). The first spelling is shipped.
6. That the zhCN client's flight point names really carry the full-width comma the zone suffix is
   trimmed at.
7. **The ruRU names above**, which are derived from area names rather than read off a client
   (deviation 17): a Russian realm's client may spell a flight point differently from the place it
   stands in. The tag and flight master paths do not depend on them.
8. The druid-only Moonglade flight points (Nighthaven) are **not in the data** — they are
   commented out in the original and were left that way.
