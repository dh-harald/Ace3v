# LibConfig-1.0

A vanilla (WoW 1.12.1 / Lua 5.0) options-window library. It takes an
AceConfig-format options table (the same shape `AceConfigDialog-3.0` consumes)
and renders it into its own window: a list of registered addons/categories on
the left, the selected category's options on the right. It can also render the
same pages into a frame of the host addon (see *Embedding into your own frame*).

It exists to replace `InterfaceOptionsFrame_OpenToCategory` and
`AceConfigDialog-3.0`/`AceGUI-3.0`, which are broken on the Unreal Azeroth
1.12.1 client (and needlessly heavyweight on a plain 1.12.1 client). The window
is the same on both clients.

## Usage

```lua
local LC = LibStub("LibConfig-1.0")

-- Register an options table. The table is AceConfig format:
-- { name = "...", type = "group", args = { ... } }
LC:RegisterOptionsTable("MyAddon", "MyAddon", ConfigTable)

-- Build the panel (returns the panel frame). Optional.
local panel = LC:AddToBlizOptions("MyAddon", "MyAddon")

-- Open the window to a registered category. This is the call that replaces
-- InterfaceOptionsFrame_OpenToCategory("MyAddon").
LC:OpenToCategory("MyAddon")

-- Also available:
-- LC:Open(appName, name)
-- LC:Close()
-- LC:NotifyChange(appName)  -- redraw after the options table itself changed
```

A category registered with `RegisterOptionsTable` shows up in the left sidebar
under its `name`; clicking it renders that category's options on the right.

### Embedding into your own frame

`LC:Embed(frame, options)` renders options pages into a frame of your addon
instead of the window — no sidebar, no page title, the same widgets and the
same refresh rules, with a scrollbar down the frame's right edge when the page
overflows.

```lua
local view = LC:Embed(myPane, {
    name = "MyAddonOptions",  -- global name prefix for the view's frames
    width = 440,              -- row width; default: frame width - 26
    labelWidth = 180,         -- name column left of a control (default 200)
    menuParent = myWindow,    -- parent of the dropdown menus (default: frame)
})

view:Open("MyAddon", "MyAddon")                -- a registered category...
view:Open("MyAddon", "MyAddon", { "general" }) -- ...or a group inside it
view:OpenTable(someTable, "MyAddon:item1", { "display" }) -- an unregistered
                                               -- table (stays out of the sidebar)
view:Refresh()  -- re-read every get (LC:NotifyChange(appName) does it too)
view:Close()    -- release the widgets
```

Open the view only while `frame` is shown, and close it when `frame` is
hidden: on Unreal Azeroth widgets created under a hidden frame do not draw, and
hiding a frame does not hide its children.

`LC:CreateScrollBar(parent, options)` gives an addon the library's own
vertical scrollbar for a list of its own — the one the pages and the dropdown
menus use, with a draggable thumb that works on both clients. It only reports
an offset in pixels; the addon scrolls (or re-lays out) its list itself.

```lua
local bar = LC:CreateScrollBar(myList, {
    name = "MyAddonListScrollBar",   -- global name prefix (optional)
    step = 20,                        -- pixels per arrow click
    onScroll = function(offset) ScrollMyListTo(offset) end,
})
bar.frame:SetPoint("TOPRIGHT", myList, "TOPRIGHT", -4, -4)
bar.frame:SetPoint("BOTTOMRIGHT", myList, "BOTTOMRIGHT", -4, 4)
bar.SetRange(contentHeight - viewHeight, viewHeight / contentHeight)
bar.SetValue(offset)   -- move the thumb without calling onScroll
bar.SetShown(true)     -- shows every piece (bar, arrows, track, thumb)
```

## Supported options

Widgets (`type`):

- `group` — follows AceConfigDialog's tree rules: an inline group
  (`inline` / `guiInline` / `dialogInline`) renders as a section header on its
  parent's page, and so do all of its descendants; any other group becomes its
  own page in the sidebar tree. `childGroups = "tab"` draws the child groups
  as a tab strip instead (see below); `childGroups = "select"` falls back to
  the tree.
- `toggle` — checkbox.
- `input` — text box, committed on Enter or when it loses focus (only if the
  text changed). `multiline = true` or a line count (2–16) gives a taller box
  that keeps line breaks; `width = "full"` puts it under its name at full
  width. Text longer than the box is clipped, not spilled over the page.
- `select` — dropdown; `values` may be a table or a function, and
  `width = "full"` makes it span the content width. `dialogControl =
  "LSM30_Font"` / `"LSM30_Statusbar"` previews each LibSharedMedia entry in its
  own font / texture; `"LSM30_Sound"` gives each row that names a
  LibSharedMedia sound (by its text, or else its value — so both name-keyed
  and path-keyed `values` work) a speaker button at its right end
  (`Media/LibConfigSpeaker.tga`, or `SetMedia{ speaker = path }`; ">" when no
  artwork is found), which plays the sound without picking the row.
- `multiselect` — one checkbox per `values` entry (table or function),
  sorted by text and packed into as many columns as fit, under the option's
  name. `get(info, key)` returns whether an entry is checked;
  `set(info, key, checked)` receives each click.
- `range` — drag-thumb slider (`min`/`max`/`step`) with an editable value box.
  `softMin`/`softMax` narrow the track and `bigStep` sets the drag's step, as
  in AceConfigDialog; a typed value may still go to `min`/`max`, rounded to
  `step`. `isPercent` shows a 0..1 value as 0..100% (readout and end labels)
  and reads a typed value as percent, with or without the `%`; the stored
  value is unchanged.
- `color` — swatch opening the library's own colour dialog (the native
  `ColorPickerFrame` does not keep its colour on Unreal Azeroth); `hasAlpha`
  adds an opacity control. `get` returns r, g, b, a; `set` receives them.
- `execute` — button (`func`, or `set` if `func` is absent).
- `header` / `description` — display-only rows.

Option members (resolved the same way AceConfigDialog resolves them):

- `name`, `desc` — string literals or functions.
- `order` — number or function.
- `hidden`, `disabled` — booleans or functions.
- `get`, `set`, `func`, `values` — function refs or method-name strings
  resolved on the nearest `handler`. `set`/`get` receive an `info` table
  (`info[1..n]` path, `info.arg`, `info.type`, `info.option`, `info.handler`,
  `info.options`, `info.appName`).
- `get`, `set`, `func`, `disabled` and `hidden` are inherited: a leaf without
  its own takes the nearest enclosing group's (a leaf's own value always wins,
  so `disabled = false` on a leaf opts it out of a disabled group).
- Not implemented: `tristate` (on `toggle` and `multiselect`), `keybinding`,
  `confirm`, `validate`, `image`/`imageCoords`.

The page redraws itself the way AceConfigDialog does: after every committed
value (a `range` only when the drag is released, a `color` only on the dialog's
OK), after an `execute`, and — deferred to the next frame — on
`LC:NotifyChange(appName)`, which a `set` that adds or removes entries of the
options table itself should call.

Long lists scroll. Both the content area and the category sidebar get a proper
vertical scrollbar — a dark track between two arrow buttons, with a draggable
thumb sized to how much of the list is visible — shown only when that list
overflows. Dropdown menus use `^` / `v` navigation buttons instead. The mouse
wheel works too where the client allows it, but is unreliable on Unreal Azeroth,
so the buttons and thumb are the dependable path on both clients.

The scrollbar thumb is driven from `GetCursorPosition` rather than
`StartMoving`, which is what keeps it locked to its own axis and inside its
track (`StartMoving` is a free 2D move, so a thumb dragged that way drifts
sideways and can leave the track).

A `childGroups = "tab"` group draws its children as a tab strip. Tabs are
measured at their full label width and wrap onto as many rows as they need, so a
label is never truncated no matter how many tabs a group has; each row is then
justified to the content width.

## Theme

The look borrows **ElvUI's color palette** (dark panel fill, thin 1 px borders,
a yellow `#FFD100` accent); the widget/frame mechanics follow **UnrealUI's**
proven-on-this-client patterns — flat fill backdrops, explicit borders drawn as
textures, a drag-thumb Button for `range` instead of the broken native Slider,
and an own colour dialog instead of the broken native `ColorPickerFrame`.

### Artwork

The library ships its own sprite sheets in `Media/` (`PlusMinusButton.blp` for
the sidebar's expand/collapse markers, `SquareButtonTextures.blp` for the
navigation arrows), so it needs no media from the host addon. Because the
library is *embedded*, its absolute `Interface\AddOns\…` path differs per host;
it recovers its own folder from its chunk name — `debug.getinfo` where the
debug library exists, otherwise `debugstack()`. If that ever fails, the
glyphs degrade to plain `+` / `-` / `^` / `v` characters — never an error.

To supply different artwork, register it before opening the window:

```lua
LC:SetMedia({
    plusMinus = "Interface\\AddOns\\MyAddon\\Media\\MyPlusMinus",
    arrows    = "Interface\\AddOns\\MyAddon\\Media\\MyArrows",
})
```

Both keys are optional and expect ElvUI's sheet layout (the `PLUS`/`MINUS`
halves, and `UP`/`DOWN`/`LEFT`/`RIGHT` cells respectively).

## Requirements

- **Lua 5.0** (WoW 1.12.1). A `Compat/Lua50.lua` shim file is included and is a
  no-op on a Lua 5.1+ client (a future 3.3.5a build).
- **LibStub** (embedded by the host addon).

## Distribution

A LibStub embedded minor. Embed it via your packager's `externals` and load
`LibConfig-1.0.xml` from the host addon's `.toc`. Because it is an embedded
minor, only one copy loads (whichever addon loads first) — keep every embedded
copy in sync.

## Credits

- Library design and implementation: **DeepSeek**, **Claude**.
- Widget/frame mechanics adapted from [UnrealUI](https://github.com/Tom75VN/UnrealUI) (MIT).
- Color palette inspired by [ElvUI](https://github.com/tukui-org/ElvUI).
- `Media/PlusMinusButton.blp` and `Media/SquareButtonTextures.blp` are
  [ElvUI](https://github.com/tukui-org/ElvUI) artwork.

## License

MIT — see [LICENSE](LICENSE) for the full text and the third-party reference
notes (UnrealUI mechanics, ElvUI palette).
