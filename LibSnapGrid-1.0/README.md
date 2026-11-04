# LibSnapGrid-1.0

An alignment grid and a snapping drag for movable frames, for the real 1.12.1 client (Lua 5.0)
and Unreal Azeroth (Lua 5.1).

- **Grid:** the screen's width split into columns (64 by default, ElvUI's `gridSize`
  convention), square cells, drawn outwards from the screen's centre; the two centre lines
  are red.
- **Snapping drag:** while dragged, a rectangle's centre snaps onto the screen's centre line
  when it is within the capture distance of it, and a solid red guide line shows; otherwise
  its nearer edge snaps onto the nearest grid line or screen edge when that is within the
  capture distance; between the lines it moves freely. The capture distance is a fraction of
  the screen's width (1/256 by default), so it scales with the screen. Moving on releases the
  snap; **Shift** drags freely. The rectangle always stays on the screen.
- **Screen anchor:** the screen point nearest to a rectangle (thirds on both axes) and the
  offset of the rectangle's matching point from it, as ElvUI's movers store positions.

```lua
local SnapGrid = LibStub("LibSnapGrid-1.0")

SnapGrid:ShowGrid()          -- on unlock; SnapGrid:HideGrid() on lock

SnapGrid:AttachDrag(handleButton, {
    frame = myFrame,         -- moved while dragging, anchored TOPLEFT to UIParent BOTTOMLEFT
    bounds = nil,            -- optional: function returning left, right, bottom, top to snap
    onStart = function()     -- optional: return false to refuse (e.g. in combat)
    end,
    onStop = function()      -- store the position here
        local point, x, y = SnapGrid:GetAnchor(SnapGrid:GetBounds(myFrame))
        myFrame:ClearAllPoints()
        myFrame:SetPoint(point, UIParent, point, x, y)
    end,
})
```

## API

| Call | |
|---|---|
| `:ShowGrid([divisions])` / `:HideGrid()` / `:IsGridShown()` | the grid; `divisions` 4..256, default 64 |
| `:SetDivisions(n)` | the column count for snapping and drawing |
| `:SetCapture(n)` | the capture distance: 1/n of the screen's width, 16..2048, default 256 |
| `:AttachDrag(handle, spec)` | see above; the handle's `OnMouseDown`, `OnMouseUp`, `OnHide`, `OnDragStart`, `OnDragStop` belong to the library from then on |
| `:StopDrag()` / `:IsDragging()` | end the drag in progress (its `onStop` runs) |
| `:Snap(left, right, bottom, top, free)` | the snap itself: `dx, dy, centredX, centredY` |
| `:GetAnchor(left, right, bottom, top)` | `point, x, y` for `SetPoint(point, UIParent, point, x, y)` of the rectangle's own `point` |
| `:PointOffset(point, width, height)` | offset of a rectangle's `point` from its top left corner |
| `:GetBounds(frame)` | `left, right, bottom, top`, or nil |

All coordinates are in UIParent's units; a dragged frame must be drawn at UIParent's scale.

## Client differences

The drag never uses `StartMoving`: the frame is placed from the cursor on every frame (on Unreal
Azeroth re-anchoring a frame the client is moving drops the drag).

- **1.12.1:** `RegisterForDrag("LeftButton")` with `OnDragStart` / `OnDragStop`.
- **Unreal Azeroth** (detected by `GetUECvar` or interface build 5875): the drag starts on
  `OnMouseDown`; while it lasts the handle's hit rectangle covers the screen and the handle is
  raised 50 levels, so its `OnMouseUp` arrives wherever the button is released;
  `GetButtonState() == "PUSHED"` is a second opinion once seen; a 60 s dead-man timer ends a drag
  that never got its release. A `RegisterForDrag` list on Unreal Azeroth keeps a frame stuck to
  the cursor, and the expanded hit rectangle breaks a handle on 1.12.1, so neither runs on the
  other client.

## Dependencies

```
LibStub\LibStub.lua
LibSnapGrid-1.0\LibSnapGrid-1.0.xml
```
