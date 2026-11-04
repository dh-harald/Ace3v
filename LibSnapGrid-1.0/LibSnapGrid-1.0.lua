--[[
	Name: LibSnapGrid-1.0
	Revision: $Rev: 1 $
	Author(s): Criminal
	Description: Alignment grid and a snapping drag for movable frames.
	Dependencies: LibStub
	Note: Runs on the real 1.12.1 client (Lua 5.0) and on Unreal Azeroth (Lua 5.1).
]]

-------------------------------------------------------------------------------
-- Overview
--
-- * A screen-wide alignment grid. The screen's width is split into a number of
--   columns (64 by default, the ElvUI gridSize convention); the cells are
--   square, and the lines are drawn outwards from the screen's centre, so the
--   two centre lines are exactly in the middle. The centre lines are red.
--
-- * A drag that snaps. While a frame is dragged, the rectangle that is snapped
--   (the frame itself or any rectangle moving with it) is shifted on each axis:
--     - its centre onto the screen's centre line when it is within the capture
--       distance of it; a solid red guide line shows while it sits there;
--     - otherwise its nearer edge onto the nearest grid line or screen edge,
--       when that is within the capture distance;
--     - otherwise not at all.
--   The capture distance is a fraction of the screen's width (1/256 by
--   default), so it scales with the screen rather than being a fixed number of
--   pixels, on both axes. Moving on releases the snap by itself; holding Shift
--   drags freely. The rectangle is always kept on the screen.
--
-- * A screen anchor for a rectangle: the screen point nearest to it (the screen
--   cut into thirds on both axes) and the offset of the rectangle's own matching
--   point from it, as ElvUI's movers store positions. A small offset from the
--   nearest edge or corner survives a resolution or UI scale change.
--
-- All coordinates are in UIParent's units, with the screen's bottom left corner
-- at 0, 0. A dragged frame must be drawn at UIParent's scale.
--
-- How a drag starts and ends differs between the two clients (the same recipe
-- as LibConfig-1.0's thumb drag):
--   * Real 1.12.1: RegisterForDrag with OnDragStart / OnDragStop, the client's
--     own machinery.
--   * Unreal Azeroth: a RegisterForDrag list keeps the frame stuck to the cursor
--     and swallows the release, so the drag starts on OnMouseDown; for its
--     duration the handle's hit rectangle is expanded to the whole screen and
--     the handle raised, so its own OnMouseUp arrives wherever the button is let
--     go. GetButtonState() == "PUSHED" is a second opinion, trusted only after it
--     has been seen once in the drag, and a dead-man timer ends a drag that
--     never got its release. The expanded hit rectangle must not be used on the
--     real client, where it leaves the handle looking hovered everywhere.
-- The frame is never handed to StartMoving: it is placed from the cursor on
-- every frame, which is what lets the snap move it, and re-anchoring a frame
-- the client is moving drops the drag on Unreal Azeroth.
-------------------------------------------------------------------------------

local MAJOR, MINOR = "LibSnapGrid-1.0", 1

local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

local math_abs, math_floor = math.abs, math.floor
local pcall, type, tonumber = pcall, type, tonumber
local table_getn, table_insert = table.getn, table.insert

local WHITE = "Interface\\Buttons\\WHITE8x8"
local DEFAULT_DIVISIONS = 64
local MIN_DIVISIONS, MAX_DIVISIONS = 4, 256
local DEFAULT_CAPTURE = 256
local MIN_CAPTURE, MAX_CAPTURE = 16, 2048
local GRID_LINE = { 0, 0, 0, 0.5 }
local GRID_CENTRE = { 1, 0, 0, 0.5 }
local GUIDE = { 1, 0, 0, 1 }
local GUIDE_THICKNESS = 2
local DRAG_CAPTURE_INSET = -4000
local DRAG_MAX_SECONDS = 60
local RAISE_LEVELS = 50

lib.divisions = lib.divisions or DEFAULT_DIVISIONS
lib.capture = lib.capture or DEFAULT_CAPTURE

function lib:GetLibraryVersion()
	return MAJOR, MINOR
end

-------------------------------------------------------------------------------
-- Client and screen
-------------------------------------------------------------------------------

-- Unreal Azeroth: the engine's own cvar accessor, or the 5875 interface build.
-- Not the Lua version: 3.3.5 runs Lua 5.1 as well.
local function DetectUA()
	if GetUECvar then return true end
	if type(GetBuildInfo) == "function" then
		local _, _, _, tocversion = GetBuildInfo()
		if tocversion == 5875 then return true end
	end
	return false
end

local IS_UA = DetectUA()

-- The screen's extent from UIParent's edges. GetWidth/GetHeight of an
-- anchor-sized frame can come back multiplied by the UI scale on 1.12.1.
local function ScreenSize()
	local width, height = UIParent:GetRight(), UIParent:GetTop()
	if not width or not height then return nil end
	return width, height
end

local function Round(value)
	return math_floor(value + 0.5)
end

local function ClampDivisions(divisions)
	divisions = tonumber(divisions) or DEFAULT_DIVISIONS
	divisions = math_floor(divisions)
	if divisions < MIN_DIVISIONS then divisions = MIN_DIVISIONS end
	if divisions > MAX_DIVISIONS then divisions = MAX_DIVISIONS end
	return divisions
end

local function IsShiftDown()
	if type(IsShiftKeyDown) ~= "function" then return false end
	local down = IsShiftKeyDown()
	return down and down ~= 0 and true or false
end

-------------------------------------------------------------------------------
-- Snapping
-------------------------------------------------------------------------------

local function Closer(best, shift)
	if best == nil or math_abs(shift) < math_abs(best) then return shift end
	return best
end

local function GridLine(value, middle, step)
	return middle + math_floor((value - middle) / step + 0.5) * step
end

-- One axis: low / high are the rectangle's edges, size the screen's extent,
-- step the grid's step, range the capture distance. Returns the shift to apply
-- and whether the rectangle's centre ends up on the screen's centre line.
local function SnapAxis(low, high, size, step, range, free)
	local middle = size / 2
	local shift = 0

	if not free then
		local centreShift = middle - (low + high) / 2
		if math_abs(centreShift) <= range then
			shift = centreShift
		else
			local best
			best = Closer(best, GridLine(low, middle, step) - low)
			best = Closer(best, GridLine(high, middle, step) - high)
			best = Closer(best, -low)
			best = Closer(best, size - high)
			if math_abs(best) <= range then shift = best end
		end
	end

	-- On the screen, the low edge first when the rectangle is larger than it.
	if high + shift > size then shift = size - high end
	if low + shift < 0 then shift = -low end

	local centred = math_abs((low + high) / 2 + shift - middle) < 0.01
	return shift, centred
end

--- Where a rectangle (left, right, bottom, top) snaps to.
--- Returns the shift on each axis and whether the rectangle's centre is on the
--- screen's vertical / horizontal centre line. `free` only keeps it on the
--- screen.
function lib:Snap(left, right, bottom, top, free)
	local width, height = ScreenSize()
	if not width then return 0, 0, false, false end
	local step, range = width / self.divisions, width / self.capture
	local dx, centredX = SnapAxis(left, right, width, step, range, free)
	local dy, centredY = SnapAxis(bottom, top, height, step, range, free)
	return dx, dy, centredX, centredY
end

--- Sets the capture distance as a fraction of the screen's width: 1/divisor
--- (default 256, kept between 16 and 2048).
function lib:SetCapture(divisor)
	divisor = math_floor(tonumber(divisor) or DEFAULT_CAPTURE)
	if divisor < MIN_CAPTURE then divisor = MIN_CAPTURE end
	if divisor > MAX_CAPTURE then divisor = MAX_CAPTURE end
	self.capture = divisor
end

-------------------------------------------------------------------------------
-- Screen anchor
-------------------------------------------------------------------------------

-- The position of a point on a rectangle.
local function PointPosition(point, left, right, bottom, top)
	local x, y = (left + right) / 2, (bottom + top) / 2
	if string.find(point, "LEFT") then x = left end
	if string.find(point, "RIGHT") then x = right end
	if string.find(point, "TOP") then y = top end
	if string.find(point, "BOTTOM") then y = bottom end
	return x, y
end

--- The screen point nearest to a rectangle, and the offset of the rectangle's
--- own matching point from it, rounded: the arguments of
--- SetPoint(point, UIParent, point, x, y) for that point of the rectangle.
--- The screen is cut into thirds on both axes; the middle third is centred.
function lib:GetAnchor(left, right, bottom, top)
	local width, height = ScreenSize()
	if not width or not left then return nil end

	local cx, cy = (left + right) / 2, (bottom + top) / 2
	local point = ""
	if cy >= height * 2 / 3 then
		point = "TOP"
	elseif cy <= height / 3 then
		point = "BOTTOM"
	end
	if cx >= width * 2 / 3 then
		point = point .. "RIGHT"
	elseif cx <= width / 3 then
		point = point .. "LEFT"
	end
	if point == "" then point = "CENTER" end

	local x, y = PointPosition(point, left, right, bottom, top)
	local px, py = PointPosition(point, 0, width, 0, height)
	return point, Round(x - px), Round(y - py)
end

--- The offset of a point of a width x height rectangle from its top left
--- corner: converts an anchor of that point into an anchor of the corner.
function lib:PointOffset(point, width, height)
	local x, y = PointPosition(point, 0, width, -height, 0)
	return x, y
end

--- The edges of a frame, or nil while it has no position.
function lib:GetBounds(frame)
	local left, right = frame:GetLeft(), frame:GetRight()
	local bottom, top = frame:GetBottom(), frame:GetTop()
	if not left or not right or not bottom or not top then return nil end
	return left, right, bottom, top
end

-------------------------------------------------------------------------------
-- Drawing
-------------------------------------------------------------------------------

-- A parent's Hide does not hide its children on Unreal Azeroth, so every
-- texture is shown and hidden by itself.
local function ShowAll(textures, shown)
	local i
	for i = 1, table_getn(textures) do
		if shown then textures[i]:Show() else textures[i]:Hide() end
	end
end

local function NewLine(parent, layer, color)
	local texture = parent:CreateTexture(nil, layer)
	texture:SetTexture(WHITE)
	texture:SetVertexColor(color[1], color[2], color[3], color[4])
	return texture
end

local function PlaceVertical(texture, parent, x, thickness)
	texture:ClearAllPoints()
	texture:SetWidth(thickness)
	texture:SetPoint("TOPLEFT", parent, "TOPLEFT", x - thickness / 2, 0)
	texture:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", x - thickness / 2, 0)
end

local function PlaceHorizontal(texture, parent, y, thickness)
	texture:ClearAllPoints()
	texture:SetHeight(thickness)
	texture:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, y - thickness / 2)
	texture:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, y - thickness / 2)
end

-- Built for one column count and screen size; a change builds a new one.
local function BuildGrid(width, height)
	local grid = CreateFrame("Frame", nil, UIParent)
	grid:SetAllPoints(UIParent)
	grid:SetFrameStrata("BACKGROUND")
	grid:EnableMouse(false)
	grid.lines = {}

	local step = width / lib.divisions
	local middle, offset

	middle, offset = width / 2, 0
	while offset <= middle do
		local line = NewLine(grid, "BACKGROUND", offset == 0 and GRID_CENTRE or GRID_LINE)
		PlaceVertical(line, grid, middle + offset, 1)
		table_insert(grid.lines, line)
		if offset > 0 then
			line = NewLine(grid, "BACKGROUND", GRID_LINE)
			PlaceVertical(line, grid, middle - offset, 1)
			table_insert(grid.lines, line)
		end
		offset = offset + step
	end

	middle, offset = height / 2, 0
	while offset <= middle do
		local line = NewLine(grid, "BACKGROUND", offset == 0 and GRID_CENTRE or GRID_LINE)
		PlaceHorizontal(line, grid, middle + offset, 1)
		table_insert(grid.lines, line)
		if offset > 0 then
			line = NewLine(grid, "BACKGROUND", GRID_LINE)
			PlaceHorizontal(line, grid, middle - offset, 1)
			table_insert(grid.lines, line)
		end
		offset = offset + step
	end

	grid.divisions, grid.width, grid.height = lib.divisions, width, height
	return grid
end

local function HideGridFrame(grid)
	ShowAll(grid.lines, false)
	grid:Hide()
end

--- Shows the grid. `divisions`: the number of columns across the screen
--- (default 64, kept between 4 and 256); the grid lines are also the snap lines.
function lib:ShowGrid(divisions)
	if divisions then self.divisions = ClampDivisions(divisions) end
	local width, height = ScreenSize()
	if not width then return end

	local grid = self.grid
	if grid and (grid.divisions ~= self.divisions or grid.width ~= width or grid.height ~= height) then
		HideGridFrame(grid)
		grid = nil
	end
	if not grid then
		grid = BuildGrid(width, height)
		self.grid = grid
	end
	grid:Show()
	ShowAll(grid.lines, true)
	self.gridShown = true
end

function lib:HideGrid()
	if self.grid then HideGridFrame(self.grid) end
	self.gridShown = nil
end

function lib:IsGridShown()
	return self.gridShown and true or false
end

--- Sets the number of columns used for snapping and drawing.
function lib:SetDivisions(divisions)
	self.divisions = ClampDivisions(divisions)
	if self.gridShown then self:ShowGrid() end
end

local function Guides()
	local guides = lib.guides
	if guides then return guides end

	guides = CreateFrame("Frame", nil, UIParent)
	guides:SetAllPoints(UIParent)
	guides:SetFrameStrata("HIGH")
	guides:EnableMouse(false)
	guides.vertical = NewLine(guides, "OVERLAY", GUIDE)
	guides.horizontal = NewLine(guides, "OVERLAY", GUIDE)
	guides.vertical:Hide()
	guides.horizontal:Hide()
	lib.guides = guides
	return guides
end

local function ShowGuides(vertical, horizontal)
	local guides = Guides()
	local width, height = ScreenSize()
	if vertical and width then
		PlaceVertical(guides.vertical, guides, width / 2, GUIDE_THICKNESS)
		guides.vertical:Show()
	else
		guides.vertical:Hide()
	end
	if horizontal and height then
		PlaceHorizontal(guides.horizontal, guides, height / 2, GUIDE_THICKNESS)
		guides.horizontal:Show()
	else
		guides.horizontal:Hide()
	end
	if vertical or horizontal then guides:Show() else guides:Hide() end
end

-------------------------------------------------------------------------------
-- Dragging
-------------------------------------------------------------------------------

local ticker = lib.ticker or CreateFrame("Frame", nil, UIParent)
lib.ticker = ticker
ticker:Hide()

-- The drag in progress: { handle, spec, cursorX, cursorY, frameLeft, frameTop,
-- left, right, bottom, top, startedAt, armed, restoreLevel, x, y }.
local drag

local function CursorPoint()
	if type(GetCursorPosition) ~= "function" then return nil end
	local x, y = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale()
	if not tonumber(x) or not tonumber(y) or not tonumber(scale) or scale <= 0 then return nil end
	return x / scale, y / scale
end

-- true / false, or nil when the client does not tell.
local function ButtonStillHeld(button)
	if not button.GetButtonState then return nil end
	local ok, state = pcall(button.GetButtonState, button)
	if not ok or type(state) ~= "string" then return nil end
	return state == "PUSHED"
end

local function SpecBounds(spec)
	if spec.bounds then return spec.bounds() end
	return lib:GetBounds(spec.frame)
end

local function Place(frame, x, y)
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
end

local function Stop()
	local current = drag
	if not current then return end
	drag = nil
	ticker:Hide()
	ShowGuides(false, false)

	local handle = current.handle
	if IS_UA then
		pcall(handle.SetHitRectInsets, handle, 0, 0, 0, 0)
	end
	if current.restoreLevel then
		pcall(handle.SetFrameLevel, handle, current.restoreLevel)
	end
	if current.spec.onStop then current.spec.onStop() end
end

local function Update()
	local current = drag
	if not current then return end

	local x, y = CursorPoint()
	if x then
		local dx, dy = x - current.cursorX, y - current.cursorY
		-- A press without a move must not snap the frame anywhere.
		if dx ~= 0 or dy ~= 0 or current.moved then
			current.moved = true
			local sx, sy, centredX, centredY = lib:Snap(current.left + dx, current.right + dx,
				current.bottom + dy, current.top + dy, IsShiftDown())
			local newX = current.frameLeft + dx + sx
			local newY = current.frameTop + dy + sy
			if newX ~= current.x or newY ~= current.y then
				current.x, current.y = newX, newY
				Place(current.spec.frame, newX, newY)
			end
			ShowGuides(centredX, centredY)
		end
	end

	if IS_UA then
		local held = ButtonStillHeld(current.handle)
		if held == true then
			current.armed = true
		elseif held == false and current.armed then
			Stop()
			return
		end
	end
	if current.startedAt and type(GetTime) == "function" and GetTime() - current.startedAt > DRAG_MAX_SECONDS then
		Stop()
	end
end

ticker:SetScript("OnUpdate", function() Update() end)

local function Start(handle, spec)
	if drag then return end
	if spec.onStart and spec.onStart() == false then return end

	local frame = spec.frame
	local cursorX, cursorY = CursorPoint()
	local frameLeft, frameTop = frame:GetLeft(), frame:GetTop()
	local left, right, bottom, top = SpecBounds(spec)
	if not cursorX or not frameLeft or not frameTop or not left then return end

	drag = {
		handle = handle, spec = spec,
		cursorX = cursorX, cursorY = cursorY,
		frameLeft = frameLeft, frameTop = frameTop,
		left = left, right = right, bottom = bottom, top = top,
		startedAt = type(GetTime) == "function" and GetTime() or nil,
	}

	if IS_UA then
		pcall(handle.SetHitRectInsets, handle,
			DRAG_CAPTURE_INSET, DRAG_CAPTURE_INSET, DRAG_CAPTURE_INSET, DRAG_CAPTURE_INSET)
		-- An expanded hit rectangle only wins the cursor where nothing sits
		-- above the handle.
		local ok, level = pcall(handle.GetFrameLevel, handle)
		if ok and tonumber(level) then
			drag.restoreLevel = level
			pcall(handle.SetFrameLevel, handle, level + RAISE_LEVELS)
		end
	end
	ticker:Show()
end

-- The mouse button of a script call: Unreal Azeroth may pass it as an argument,
-- 1.12.1 sets arg1.
local function ScriptButton(a1, a2)
	if type(a1) == "string" then return a1 end
	if type(a2) == "string" then return a2 end
	return arg1
end

--- Makes `handle` (a Button) drag a frame with snapping. `spec`:
---   frame    the frame that moves; it is anchored TOPLEFT to UIParent's
---            BOTTOMLEFT while dragged, and the caller stores and re-applies its
---            position in onStop
---   bounds   optional function returning the left, right, bottom, top of the
---            rectangle to snap, moving with the frame (default: the frame's own)
---   onStart  optional function; returning false refuses the drag
---   onStop   optional function, called once when the drag ends
--- The handle's OnMouseDown, OnMouseUp, OnHide, OnDragStart and OnDragStop
--- scripts belong to the library from then on.
function lib:AttachDrag(handle, spec)
	if IS_UA then
		handle:SetScript("OnMouseDown", function(a1, a2)
			local button = ScriptButton(a1, a2)
			if button and button ~= "LeftButton" then return end
			Start(handle, spec)
		end)
	else
		pcall(handle.RegisterForDrag, handle, "LeftButton")
		handle:SetScript("OnDragStart", function() Start(handle, spec) end)
		handle:SetScript("OnDragStop", function()
			if drag and drag.handle == handle then Stop() end
		end)
	end
	handle:SetScript("OnMouseUp", function()
		if drag and drag.handle == handle then Stop() end
	end)
	-- A handle hidden mid-drag must not leave the drag, or on Unreal Azeroth a
	-- screen-wide hit rectangle, behind.
	handle:SetScript("OnHide", function()
		if drag and drag.handle == handle then Stop() end
	end)
end

--- Ends the drag in progress, if any (its onStop runs).
function lib:StopDrag()
	Stop()
end

function lib:IsDragging()
	return drag ~= nil
end
