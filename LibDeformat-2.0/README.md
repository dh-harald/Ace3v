# LibDeformat-2.0

Ace3v port of the Ace2 library **Deformat-2.0** (r6804), API-compatible.

Deformat is the inverse of `string.format`. Given a piece of text and the format string that
produced it, it extracts the values that were substituted in. It exists because WoW's localized
global strings (`ITEM_SET_NAME`, `SPELL_RANK`, combat log messages, …) are format strings, and an
addon that needs the numbers back out of a rendered message would otherwise have to hand-write a
Lua pattern per locale.

```lua
local Deformat = LibStub("LibDeformat-2.0")
local name, have, total = Deformat("Dreadnaught's Battlegear (3/8)", "%s (%d/%d)")
--> "Dreadnaught's Battlegear", 3, 8
```

Numeric specifiers (`%d`, `%f`, `%g`, `%.1f`) are returned as **numbers**; `%s` and `%c` as
**strings**. Compiled patterns are cached, so repeated calls with the same format string are cheap
— which is what makes it usable on combat log traffic.

## Dependencies

Only LibStub. No AceEvent, no frames, no WoW API calls at all.

```
LibStub\LibStub.lua
LibDeformat-2.0\LibDeformat-2.0.xml
```

In a `.toc`:

```
LibStub\LibStub.lua
LibDeformat-2.0\LibDeformat-2.0.xml
```

Or from an addon's own XML:

```xml
<Script file="LibStub\LibStub.lua"/>
<Include file="LibDeformat-2.0\LibDeformat-2.0.xml"/>
```

## Usage

```lua
local Deformat = LibStub("LibDeformat-2.0")
```

The library is not embeddable — there is no `:Embed()`. Hold a local reference to it.

## API

### `Deformat(text, pattern [, pattern2, pattern3, pattern4, pattern5])`
### `Deformat:Deformat(text, pattern [, pattern2, ... pattern5])`

Both forms are equivalent; the plain-call form goes through the library's `__call` metamethod.

| Argument | Type | Meaning |
|---|---|---|
| `text` | string | the rendered text to pull values out of. Required. |
| `pattern` | string | the format string that produced it. Required. |
| `pattern2 … pattern5` | string | optional extra fragments, concatenated onto `pattern` before matching. Useful for building a pattern out of several global strings. |

**Returns** the captured values in order, up to 9 of them — numbers for `%d`, `%f`, `%g` and
`%.Nf`, strings for `%s` and `%c`.

**Returns nothing** when `text` does not match `pattern`, or when `pattern` contains no format
specifier at all. Callers must therefore be prepared for `nil`:

```lua
local rank = Deformat(text, SPELL_RANK)
if rank then
    -- matched
end
```

**Errors** if `text` or `pattern` is not a string.

Supported specifiers: `%d` (and width forms like `%2d`), `%s`, `%f`, `%g`, `%.Nf`, `%.Ng`, `%c`,
and positional forms `%1$s`, `%2$d`, … which locales such as ruRU, koKR and zhCN use to reorder
arguments. A literal `%%` in the pattern is matched literally and captures nothing.

### `Deformat:GetLibraryVersion()`

Returns `"LibDeformat-2.0", <minor>`. Compatibility shim for code written against AceLibrary.

## Example

```lua
local Deformat = LibStub("LibDeformat-2.0")

-- ITEM_SET_NAME == "%s (%d/%d)"
local function ParseSetLine(line)
    local setName, equipped, total = Deformat(line, ITEM_SET_NAME)
    if not setName then return end
    return setName, equipped, total
end

-- Building a pattern from fragments, and reading a number back out
local bonus = Deformat("Bonus: 15 Healing", "Bonus: ", "%d", " Healing")   --> 15
```

## Differences from the Ace2 version

1. **Lookup name.** `AceLibrary("Deformat-2.0")` → `LibStub("LibDeformat-2.0")`. The library is
   registered with LibStub under the `Lib`-prefixed major, per this project's naming convention.
2. **`MINOR` is a plain integer** (starting at 1) instead of an SVN `$Revision:$` string.
3. **A capture-less pattern no longer errors.** `Deformat(text, "Hello")` — a pattern with no
   format specifier — crashed in Deformat-2.0 with *"attempt to call field `?` (a nil value)"*,
   because its internal `Curry()` returned nothing and the result was then called anyway. This
   port returns nothing instead. The negative result is also memoized, so it no longer re-compiles
   the pattern on every call. No successful return value changes; only the crash is gone.
4. **`self:argCheck` is gone.** AceLibrary injected `:error`, `:assert`, `:argCheck` and `:pcall`
   into every library; LibStub does not. Argument checking is now a local helper, and the error
   text reads `LibDeformat-2.0: bad argument #N (string expected, got X)`.
5. Lua/WoW functions are upvalued at the top of the file, matching the Ace3v house style. No
   behavioural effect.

Everything else is unchanged, including the shared internal state used by the positional-argument
code path — this port reproduces Deformat-2.0's output on that path exactly, quirks included.
