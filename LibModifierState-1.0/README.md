# LibModifierState-1.0

A tiny library that fires `MODIFIER_STATE_CHANGED` for **Shift**, **Ctrl** and
**Alt** on World of Warcraft clients that do not have that event: vanilla
1.12.1 and Unreal Azeroth.

On TBC and later clients the game itself fires `MODIFIER_STATE_CHANGED`
whenever a modifier key goes down or up. The 1.12.1 client has no such event,
so an addon that wants to react to a modifier press (show a tooltip while Shift
is held, highlight bag items while a key is down, ...) has to poll. This
library does the polling once, for every addon that uses it.

Runs on Lua 5.0 (vanilla 1.12.1) and Lua 5.1 (Unreal Azeroth).

## How it works

- A single hidden frame polls `IsShiftKeyDown`, `IsControlKeyDown` and
  `IsAltKeyDown` every frame and fires a callback when one of them changes.
- The poller **only runs while at least one callback is registered**. With no
  listeners it costs nothing.
- When polling starts, the current key state is taken as the baseline, so a key
  that is already held does not fire.
- Polling works with the cursor over the 3D world and over UI frames (action
  buttons, bag items) alike, on both clients.
- Several addons embedding the library share one poller and one callback
  registry through LibStub.

## Dependencies

- [LibStub](https://www.wowace.com/projects/libstub)
- **CallbackHandler-1.0, MINOR 7 or later.** It fires like upstream Ace3,
  `Fire(event, a1, ...)`, and so does this library since MINOR 2. MINOR 1
  called the older vanilla backport's form with an explicit argument count,
  `Fire(event, argc, a1, ...)` (CallbackHandler MINOR 6, zerosnake0/laytya).

Load both before this library.

## Usage

```lua
local LMS = LibStub("LibModifierState-1.0")

-- With a function: receives (event, key, state).
LMS.RegisterCallback(MyAddon, "MODIFIER_STATE_CHANGED", function(event, key, state)
	if key == "SHIFT" and state == 1 then
		-- Shift went down
	end
end)

-- Or with a method name on the owner table:
function MyAddon:OnModifierStateChanged(event, key, state)
	-- ...
end
LMS.RegisterCallback(MyAddon, "MODIFIER_STATE_CHANGED", "OnModifierStateChanged")

-- Stop listening. When the last listener is gone, polling stops.
LMS.UnregisterCallback(MyAddon, "MODIFIER_STATE_CHANGED")
```

Note the **dot** in `LMS.RegisterCallback(owner, ...)`: these are the
CallbackHandler-1.0 registration functions, and the first argument is your own
owner table, not the library.

CallbackHandler-1.0 keeps one callback per owner and event. If one addon needs
two independent listeners, register them under two different owner tables.

## API

| Call | Description |
|---|---|
| `LMS.RegisterCallback(owner, "MODIFIER_STATE_CHANGED", method)` | `method` is a function `(event, key, state)`, or the name of a method on `owner`, called as `owner[method](owner, event, key, state)`. |
| `LMS.UnregisterCallback(owner, "MODIFIER_STATE_CHANGED")` | Removes the owner's callback. |
| `LMS.UnregisterAllCallbacks(owner)` | Removes every callback of the owner. |
| `LMS:IsDown(key)` | `true`/`false` for `"SHIFT"`, `"CTRL"` or `"ALT"`; `false` for any other key. |
| `LMS:IsAnyDown()` | `true` while any of the three is held. |
| `LMS.EVENT` | The event name, `"MODIFIER_STATE_CHANGED"`. |

Callback arguments:

- `key`: `"SHIFT"`, `"CTRL"` or `"ALT"`.
- `state`: `1` when the key went down, `0` when it was released.

## Differences from the real event

| | Real event (TBC+) | LibModifierState-1.0 |
|---|---|---|
| Key names | `LSHIFT`, `RSHIFT`, `LCTRL`, `RCTRL`, `LALT`, `RALT` | `SHIFT`, `CTRL`, `ALT` |
| Arguments | `arg1` / `arg2` globals (or handler arguments) | callback arguments only |
| Registration | `frame:RegisterEvent` / AceEvent-3.0 | the library's own registry |

- **No left/right distinction:** neither vanilla 1.12.1 nor Unreal Azeroth
  exposes left or right modifier state.
- **Not delivered through AceEvent-3.0 or `RegisterEvent`.** AceEvent's registry
  is shared by every Ace3 addon, so a synthetic event there would reach other
  addons' handlers, which read `arg1`/`arg2` globals this library cannot set
  safely.

An addon that runs on both vanilla and a later client can feed both paths into
one handler, keeping in mind that the key names differ:

```lua
local function OnModifier(key, state) -- state is 1/0 on both paths
	if key == "SHIFT" or key == "LSHIFT" or key == "RSHIFT" then
		-- ...
	end
end

if IsVanillaClient then
	LibStub("LibModifierState-1.0").RegisterCallback(MyAddon, "MODIFIER_STATE_CHANGED",
		function(event, key, state) OnModifier(key, state) end)
else
	-- real MODIFIER_STATE_CHANGED: OnModifier(arg1, arg2)
end
```

## Versioning

Several addons may embed different copies. LibStub keeps the one with the
highest minor version, so **raise the minor version on every change**. A newer
copy loaded over an older one that is already polling takes the poller over.

## Credits

- Library design and implementation: **Peter Nyilas**, **Claude**.
- The polling approach follows the vanilla branch of Bagzen's modifier
  handling.

## License

MIT — see [LICENSE](LICENSE) for the full text.
