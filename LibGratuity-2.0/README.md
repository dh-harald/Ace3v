# LibGratuity-2.0

Ace3v port of the Ace2 library **Gratuity-2.0** (r11054), API-compatible.

Gratuity is a **tooltip scanner**. Item and spell data that vanilla's API does not expose — set
bonuses, stat lines, "Binds when picked up", buff descriptions — is only available as tooltip text.
Gratuity owns a hidden `GameTooltip`, loads any game object into it, and lets you read the lines
back as strings without disturbing the player's visible tooltip.

```lua
local Gratuity = LibStub("LibGratuity-2.0")

Gratuity:SetHyperlink("item:12345")
for i = 1, Gratuity:NumLines() do
    local left, right = Gratuity:GetLine(i)
    -- ...
end
```

The hidden tooltip (`LibGratuity20Tooltip`, built from `GameTooltipTemplate`) is created once at
load, so scanning is just reads of its line font strings — no frame churn per call.

## Dependencies

| Dependency | Required? | Why |
|---|---|---|
| LibStub | yes | registration |
| LibDeformat-2.0 | **only for `:FindDeformat()`** | that one method extracts values from a matched line |

Every other method needs nothing but LibStub. Load order:

```
LibStub\LibStub.lua
LibDeformat-2.0\LibDeformat-2.0.xml      (optional -- only if you call :FindDeformat)
LibGratuity-2.0\LibGratuity-2.0.xml
```

In a `.toc`, or via `<Include>` from an addon's XML:

```xml
<Script file="LibStub\LibStub.lua"/>
<Include file="LibDeformat-2.0\LibDeformat-2.0.xml"/>
<Include file="LibGratuity-2.0\LibGratuity-2.0.xml"/>
```

## Usage

```lua
local Gratuity = LibStub("LibGratuity-2.0")
```

Not embeddable — there is no `:Embed()`, matching the Ace2 original. Hold a local reference.

The workflow is always the same: call one of the `Set*` methods to load an object into the hidden
tooltip, then read it with `GetLine`, `Find`, `FindDeformat` or `GetText`. Each `Set*` call erases
the tooltip first, so state never leaks between scans.

## API

### Loading the tooltip

Thirty methods mirror the `GameTooltip` API one-for-one, taking the same arguments as their
Blizzard counterparts:

```
SetBagItem          SetAction            SetAuctionItem       SetAuctionSellItem
SetBuybackItem      SetCraftItem         SetCraftSpell        SetHyperlink
SetInboxItem        SetInventoryItem     SetLootItem          SetLootRollItem
SetMerchantItem     SetPetAction         SetPlayerBuff        SetQuestItem
SetQuestLogItem     SetQuestRewardSpell  SetSendMailItem      SetShapeshift
SetSpell            SetTalent            SetTrackingSpell     SetTradePlayerItem
SetTradeSkillItem   SetTradeTargetItem   SetTrainerService    SetUnit
SetUnitBuff         SetUnitDebuff
```

Each erases the tooltip, then loads the object. `SetAction` additionally checks `HasAction(id)` and
returns early when the slot is empty. A failure inside the underlying tooltip call is re-raised as
an error with the file/line prefix stripped.

### `Gratuity:NumLines([endln])`

Number of lines currently in the tooltip. With `endln`, the result is clamped to it — so
`NumLines(10)` on a 30-line tooltip returns `10`. Returns `0` when the tooltip is empty. Trailing
lines empty on both sides (`nil` or `""`) are not counted.

### `Gratuity:GetLine(line [, getright])`

Reads one line. Without `getright`, returns **left, right**. With a truthy `getright`, returns only
the right-hand text. Returns nothing if `line` is past `NumLines()`. Errors if `line` is not a
number.

```lua
local left, right = Gratuity:GetLine(3)     --> "Chest", "Plate"
local right       = Gratuity:GetLine(3, 1)  --> "Plate"
```

### `Gratuity:Find(txt [, startln [, endln [, ignoreleft [, ignoreright [, exact]]]]])`

Searches the tooltip for `txt` and, on the first hit, returns `string.find`'s results for that line
— `start, stop` plus any captures. Returns nothing if there is no match.

| Argument | Meaning |
|---|---|
| `txt` | string (or number) to search for. **Treated as a Lua pattern**, so escape magic characters: `"%+40 Stamina"`. |
| `startln` | first line to check, default `1` |
| `endln` | last line to check, clamped by `NumLines`, default the whole tooltip |
| `ignoreleft` / `ignoreright` | skip one side of the tooltip |
| `exact` | truthy → the line must equal `txt` in full, instead of merely containing it |

```lua
local _, _, armor = Gratuity:Find("(%d+) Armor")   --> armor == "1234"
```

### `Gratuity:MultiFind(startln, endln, ignoreleft, ignoreright, t1 [, t2 ... t10])`

Runs `Find` for up to ten search strings and returns the result of the first one that hits. Note
the argument order: the search strings come **last**, and there is no `exact` parameter.

### `Gratuity:FindDeformat(txt [, startln [, endln [, ignoreleft [, ignoreright]]]])`

Like `Find`, but `txt` is a **format string** and the return values are the deformatted captures —
this is how you pull numbers out of a localized line without writing a pattern per locale.
Requires LibDeformat-2.0; errors if it is not loaded.

```lua
-- ITEM_SET_NAME == "%s (%d/%d)"
local setName, have, total = Gratuity:FindDeformat(ITEM_SET_NAME)
--> "Dreadnaught's Battlegear", 3, 8
```

### `Gratuity:GetText([startln [, endln [, ignoreleft [, ignoreright]]]])`

Returns an array of `{left, right}` pairs for every non-empty line in range, or `nil` if none. A
line whose sides are both `nil` or `""` counts as empty.
`endln` defaults to `30` here and is **not** clamped by `NumLines`.

### `Gratuity:Erase()`

Clears the tooltip completely — both sides, and resets `NumLines`. The `Set*` methods call it for
you; you rarely need it directly.

### `Gratuity:CreateTooltip()` / `Gratuity:CreateSetMethods()`

Internal setup, run once at load. Documented only because they are reachable. `CreateTooltip()`
reuses the named frame if it already exists.

`Gratuity.vars.Llines[i]` / `Gratuity.vars.Rlines[i]` resolve to the tooltip's
`LibGratuity20TooltipTextLeft<i>` / `TextRight<i>` font strings, or `nil` for a line the client
has not created yet.

### `Gratuity:GetLibraryVersion()`

Returns `"LibGratuity-2.0", <minor>`. Compatibility shim for code written against AceLibrary.

## Example

Reading an item's set name and bonus, the way ItemBonusLib does:

```lua
local Gratuity = LibStub("LibGratuity-2.0")

local function GetSetInfo(itemLink)
    Gratuity:SetHyperlink(itemLink)

    -- ITEM_SET_NAME == "%s (%d/%d)"
    local setName, equipped, total = Gratuity:FindDeformat(ITEM_SET_NAME)
    if not setName then return end

    local bonuses = {}
    for i = 1, Gratuity:NumLines() do
        local line = Gratuity:GetLine(i)
        if line then
            local _, _, amount = string.find(line, "Increases healing by (%d+)")
            if amount then table.insert(bonuses, tonumber(amount)) end
        end
    end

    return setName, equipped, total, bonuses
end
```

## Differences from the Ace2 version

1. **Lookup name.** `AceLibrary("Gratuity-2.0")` → `LibStub("LibGratuity-2.0")`.
2. **`MINOR` is a plain integer** (starting at 1) instead of an SVN `$Revision:$` string.
3. **`exact` now accepts any truthy value.** Gratuity-2.0 tested `exact == true`, so passing `1` —
   which one of the two 1.12.1 clients returns where the other returns `true` — silently fell back
   to substring matching. The port tests truthiness, so `true` and `1` behave the same. This is the
   only behavioural change that can affect a correct caller, and it can only make `exact` work
   where it previously did nothing.
4. **Compost-2.0 support removed.** `GetText` used Compost's table recycling when available and
   plain tables otherwise; the port always takes the plain-table path, which is the original's own
   fallback. `Gratuity:InitCompost()` is gone. No consumer in this repository called either.
5. **A leftover debug `print` was removed.** `Find` contained a type check that printed to chat
   instead of erroring when `startln` was not a number. It was development scaffolding; removing it
   only removes chat noise, since a bad `startln` still fails on the `for` loop exactly as before.
6. **`self:argCheck` / `self:assert` / `self:pcall` are gone.** AceLibrary injected these into every
   library; LibStub does not. They are local helpers now, so **error message text differs** —
   `LibGratuity-2.0: bad argument #2 (number expected, got string)` rather than AceLibrary's
   `Bad argument #2 (...)`. The conditions that raise an error are unchanged.
7. **`FindDeformat` requires `LibDeformat-2.0`**, not `Deformat-2.0`, and finds it through
   `LibStub:GetLibrary(..., true)` instead of `AceLibrary:HasInstance`.
8. **State survives a library upgrade differently.** Ace2's `activate` copied `self.vars` from the
   old instance; LibStub hands back the same table, so the port uses `lib.vars = lib.vars or {}` and
   only creates the tooltip if one does not already exist. Net effect is the same: one tooltip per
   session.
9. Lua/WoW functions are upvalued at the top of the file, matching the Ace3v house style. No
   behavioural effect.
10. **The scanning tooltip uses `GameTooltipTemplate`.** Gratuity-2.0 created a templateless
    `GameTooltip`, added 30 of its own font-string pairs with `AddFontStrings` and owned it by
    itself. On Unreal Azeroth such a tooltip stays empty: after `SetHyperlink("item:6948")`,
    `NumLines()` is `0` whether it owns itself or `UIParent` owns it, while a
    `GameTooltipTemplate` tooltip in the same session reads 4 lines, `Hearthstone` first (measured
    in game; the template version was measured on the 1.12.1 client too). The port therefore
    creates the named tooltip `LibGratuity20Tooltip` from the template, owned by `UIParent`, and
    reads its `TextLeftN` / `TextRightN` globals. The template provides the first lines and the
    client adds more when the content needs them, so `vars.Llines` / `vars.Rlines` resolve lines
    by name on first use. `GetText`, which walks to line 30 regardless of `NumLines`, and `Erase`
    skip lines that do not exist yet. The public API is unchanged.
11. **`Erase` clears the left side too, and `NumLines` does not count trailing empty lines.**
    Gratuity-2.0 cleared only the right side and relied on `ClearLines` for the rest. On Unreal
    Azeroth, within one frame, `ClearLines` resets neither the tooltip's `NumLines` nor the left
    text: a 9-line tooltip followed by a 7-line one in the same `/run` reported `NumLines` 9 both
    times, with the first tooltip's lines 8–9 still readable. Over two `/run`s the count was 9, then
    7 (measured in game). A caller scanning several items in one pass therefore read the tail of an
    earlier, longer tooltip as part of a shorter one. The port empties both sides in `Erase`, and
    `NumLines` (which `GetLine`, `Find` and `FindDeformat` go through) drops trailing lines empty
    on both sides; a cleared font string reads `""` there, not `nil`. `GetText` skips such lines
    as well. `MINOR` is 2, so this version replaces a MINOR 1 copy embedded by another addon.
