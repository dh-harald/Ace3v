# LibItemPrice-1.1

Vendor sell prices for items, looked up offline from an id, an item link or an item name.
Vanilla-only fork of the wowace `ItemPrice-1.1` (rev 79224) by Bam, whose SVN and versioning are
long gone. Runs on WoW 1.12.1 (Lua 5.0) and on Unreal Azeroth (Lua 5.1) with no compatibility
layer. License: LGPL v2.1.

Two things changed against upstream:

- **The data is vanilla 1.12.1 only, and complete.** It is regenerated from a 1.12 world
  database (`cmangos/classic-db`, `item_template.SellPrice`), which covers 17715 item ids —
  2837 more than upstream carried. Upstream's own numbers were verified against that database
  first: 14877 of its 14878 prices matched exactly, and it contained no id the vanilla database
  does not have, so nothing TBC-era had to be removed.
- **The data no longer lives in the library file.** Any number of price sources register
  themselves, which is what makes a custom-server section possible (see below).

The revision restarts at **1** and is a plain number from here on, instead of upstream's
`$Revision: 79224 $` SVN keyword.

## Dependencies

```
LibStub\LibStub.lua
LibItemPrice-1.1\LibItemPrice-1.1.xml
```

LibStub is the only dependency.

## Loading / usage

```xml
<Include file="Libraries\LibItemPrice-1.1\LibItemPrice-1.1.xml"/>
```

```lua
local LIP = LibStub("ItemPrice-1.1", true)
local copper = LIP and LIP:GetPriceById(2589)
```

The XML loads two files in order: the library, then `Data-Vanilla.lua`, which registers the
vanilla price block into it.

## API

| Call | Returns |
|---|---|
| `LIP:GetPriceById(itemId)` | copper, `0` for an item that sells for nothing, `nil` for an unknown id |
| `LIP:GetPrice(item)` | same, for an item id, a numeric string, an item string or an item link |
| `LIP:GetSellValue(item)` | same, and additionally accepts an item **name**, resolved through `GetItemInfo` |
| `LIP:GetPriceCount()` | how many items all registered sources together know about |

`0` and `nil` mean different things and always have: `0` is a known, worthless item (a quest
item, a Hearthstone), `nil` is an id nothing has priced. Callers that print a vendor value are
expected to treat `nil` and `0` alike, but callers that decide whether an item is *sellable*
should not.

## Adding a server's own items

A server with custom items (re-priced vanilla items, or ids of its own) ships one extra file
that registers on top of the vanilla block. A lookup walks the sources newest-first, so the
later source wins for the ids it covers and everything else falls through to vanilla.

```lua
-- Data-MyServer.lua, loaded after Data-Vanilla.lua
local Lib = LibStub and LibStub("ItemPrice-1.1", true)
if not Lib or not Lib.RegisterPriceTable then return end
if not IsMyServer() then return end       -- whatever identifies the server

Lib:RegisterPriceTable({
	[2589] = 25,        -- vanilla item, re-priced here
	[60001] = 12345,    -- custom item
}, nil, "myserver")
```

- `Lib:RegisterPriceTable(map, count, name)` — sparse `[itemId] = copper` table, for the handful
  of items a server adds or changes.
- `Lib:RegisterPackedPrices(first, last, data, count, name)` — a dense packed block like the
  vanilla one, worth it only for thousands of ids in a contiguous range.

`name` is optional but recommended: registering again under the same name **replaces** that
source instead of stacking another copy on top of it, which keeps reloads and library upgrades
from piling up duplicates. Sources registered by other addons survive a library upgrade, so an
extension loaded by one addon still applies when another addon brings a newer copy of the
library.

The condition is the caller's business — the library never guesses what server it is on.

## Data format

`Data-Vanilla.lua` is generated, not hand-edited. It is a dense block of 3 bytes per item id
starting at id 1, each a big-endian 24-bit copper value, built as one string per source line and
joined with `table.concat`:

- `"\0\0\0"` — no such item, `GetPriceById` returns `nil`.
- `"zzz"` — the item exists and sells for nothing, returns `0`. An all-zero triplet cannot
  express both cases, hence the sentinel; vanilla's dearest item sells for 1632328 copper, far
  below the sentinel's numeric value, so no real price can collide with it.

Ids above 24283 are left out: in 1.12 the only ones are QA and monster-only rows
(`QATest +1000 Spell Dmg Ring`, `Monster - Shield, Legion`).

`Data-Vanilla.lua` is a build product of that database, so a correction belongs in the source it
was generated from, not in the file.
