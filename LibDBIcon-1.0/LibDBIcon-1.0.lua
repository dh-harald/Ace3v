
-----------------------------------------------------------------------
-- LibDBIcon-1.0
--
-- Allows addons to easily create a lightweight minimap icon as an alternative to heavier LDB displays.
--

local DBICON10 = "LibDBIcon-1.0"
local DBICON10_MINOR = 44 -- Bump on changes
if not LibStub then error(DBICON10 .. " requires LibStub.") end
local ldb = LibStub("LibDataBroker-1.1", true)
if not ldb then error(DBICON10 .. " requires LibDataBroker-1.1.") end
local lib = LibStub:NewLibrary(DBICON10, DBICON10_MINOR)
if not lib then return end

LibStub("AceHook-3.0"):Embed(lib)
lib.objects = lib.objects or {}
lib.callbackRegistered = lib.callbackRegistered or nil
lib.callbacks = lib.callbacks or LibStub("CallbackHandler-1.0"):New(lib)
lib.notCreated = lib.notCreated or {}
lib.radius = lib.radius or 5
lib.tooltip = lib.tooltip or CreateFrame("GameTooltip", "LibDBIconTooltip", UIParent, "GameTooltipTemplate")
local next, Minimap = next, Minimap
local tgetn = table.getn
local isDraggingButton = false

-- NOTE: Texture:GetVertexColor() is not implemented in Unreal Azeroth's
-- native binding (it's nil on Texture objects), so calling it directly
-- crashes with "attempt to call method 'GetVertexColor' (a nil
-- value)". Guard GetVertexColor defensively: fall back to
-- opaque white (no tint) when GetVertexColor is unavailable, and
-- silently skip SetVertexColor if it's unavailable too - this is a
-- non-critical cosmetic feature (icon tinting), not worth crashing
-- over.
local function safeGetVertexColor(texture)
	if not texture or not texture.GetVertexColor then
		return 1, 1, 1, 1
	end
	local ok, r, g, b, a = pcall(texture.GetVertexColor, texture)
	if ok then
		return r, g, b, a
	end
	return 1, 1, 1, 1
end

function lib:IconCallback(event, name, key, value)
	if lib.objects[name] then
		if key == "icon" then
			lib.objects[name].icon:SetTexture(value)
		elseif key == "iconCoords" then
			lib.objects[name].icon:UpdateCoord()
		elseif key == "iconR" then
			local _, g, b = safeGetVertexColor(lib.objects[name].icon)
			lib.objects[name].icon:SetVertexColor(value, g, b)
		elseif key == "iconG" then
			local r, _, b = safeGetVertexColor(lib.objects[name].icon)
			lib.objects[name].icon:SetVertexColor(r, value, b)
		elseif key == "iconB" then
			local r, g = safeGetVertexColor(lib.objects[name].icon)
			lib.objects[name].icon:SetVertexColor(r, g, value)
		end
	end
end
if not lib.callbackRegistered then
	ldb.RegisterCallback(lib, "LibDataBroker_AttributeChanged__icon", "IconCallback")
	ldb.RegisterCallback(lib, "LibDataBroker_AttributeChanged__iconCoords", "IconCallback")
	ldb.RegisterCallback(lib, "LibDataBroker_AttributeChanged__iconR", "IconCallback")
	ldb.RegisterCallback(lib, "LibDataBroker_AttributeChanged__iconG", "IconCallback")
	ldb.RegisterCallback(lib, "LibDataBroker_AttributeChanged__iconB", "IconCallback")
	lib.callbackRegistered = true
end

local function getAnchors(frame)
	local x, y = frame:GetCenter()
	if not x or not y then return "CENTER" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end

local function onEnter()
	if isDraggingButton then return end

	for _, button in next, lib.objects do
		if button.showOnMouseover then
			--button.fadeOut:Stop()
			button:SetAlpha(1)
		end
	end

	local obj = this.dataObject
	if obj.OnTooltipShow then
		lib.tooltip:SetOwner(this, "ANCHOR_NONE")
		lib.tooltip:SetPoint(getAnchors(this))
		obj.OnTooltipShow(lib.tooltip)
		lib.tooltip:Show()
	elseif obj.OnEnter then
		obj.OnEnter()
	end
end

local function onLeave()
	lib.tooltip:Hide()

	if not isDraggingButton then
		for _, button in next, lib.objects do
			if button.showOnMouseover then
				--button.fadeOut:Play()
			end
		end
	end

	local obj = this.dataObject
	if obj.OnLeave then
		obj.OnLeave()
	end
end

--------------------------------------------------------------------------------

local pressDrag, beginDrag, endDrag, onDragStart, onDragStop, updatePosition

do
	local minimapShapes = {
		["ROUND"] = {true, true, true, true},
		["SQUARE"] = {false, false, false, false},
		["CORNER-TOPLEFT"] = {false, false, false, true},
		["CORNER-TOPRIGHT"] = {false, false, true, false},
		["CORNER-BOTTOMLEFT"] = {false, true, false, false},
		["CORNER-BOTTOMRIGHT"] = {true, false, false, false},
		["SIDE-LEFT"] = {false, true, false, true},
		["SIDE-RIGHT"] = {true, false, true, false},
		["SIDE-TOP"] = {false, false, true, true},
		["SIDE-BOTTOM"] = {true, true, false, false},
		["TRICORNER-TOPLEFT"] = {false, true, true, true},
		["TRICORNER-TOPRIGHT"] = {true, false, true, true},
		["TRICORNER-BOTTOMLEFT"] = {true, true, false, true},
		["TRICORNER-BOTTOMRIGHT"] = {true, true, true, false},
	}

	local rad, cos, sin, sqrt, max, min = math.rad, math.cos, math.sin, math.sqrt, math.max, math.min
	function updatePosition(button, position)
		local angle = rad(position or 225)
		local x, y, q = cos(angle), sin(angle), 1
		if x < 0 then q = q + 1 end
		if y > 0 then q = q + 2 end
		local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
		local quadTable = minimapShapes[minimapShape]
		local w = (Minimap:GetWidth() / 2) + lib.radius
		local h = (Minimap:GetHeight() / 2) + lib.radius
		if quadTable[q] then
			x, y = x*w, y*h
		else
			local diagRadiusW = sqrt(2*(w)^2)-10
			local diagRadiusH = sqrt(2*(h)^2)-10
			x = max(-w, min(x*diagRadiusW, w))
			y = max(-h, min(y*diagRadiusH, h))
		end
		button:SetPoint("CENTER", Minimap, "CENTER", x, y)
	end
end

local function onClick( )
	-- A drag ends where the cursor happens to be, and for the duration of
	-- the drag this button's hit rectangle covers the screen (see
	-- beginDrag), so the release that ends a drag also reads as a click on
	-- this button. Swallow exactly that one click. `dragMoved` is cleared
	-- here and again on the next press, so it cannot leak into a later,
	-- genuine click no matter which order this client delivers OnMouseUp
	-- and OnClick in.
	if this.dragMoved then
		this.dragMoved = nil
		return
	end
	if this.dataObject.OnClick then
		this.dataObject.OnClick( this, arg1)
	end
end

local function onMouseDown()
	this.isMouseDown = true
	this.dragMoved = nil
	this.icon:UpdateCoord()
	pressDrag()
end

local function onMouseUp()
	this.isMouseDown = false
	this.icon:UpdateCoord()
	endDrag(this)
end

-- Hidden mid-drag (lib:Hide, an addon disabling its icon) must not leave a
-- screen-wide hit rectangle behind -- that would swallow every click in the
-- whole UI.
local function onHide()
	endDrag(this)
end

local fmod = function(x, y)
    return x - math.floor(x / y) * y
end

-- ---------------------------------------------------------------------
-- Dragging on Unreal Azeroth
--
-- Symptom: the minimap icon stays stuck to the cursor after the mouse is
-- released, and only lets go on the next click.
--
-- ROOT CAUSE (this is the part an earlier fix in this file got wrong):
-- **RegisterForDrag itself is what suppresses the end of the drag.** On
-- this client a non-empty drag registration puts the frame into a pending
-- engine drag on every press (`widgets/Frame.md#registerfordrag`: "This
-- client starts a pending drag whenever the list is non-empty"), and for
-- the duration of that pending drag neither `OnDragStop` NOR the frame's
-- own `OnMouseUp` is delivered. Two independent live confirmations:
--   * LibConfig-1.0's thumbs had exactly this symptom with exactly this
--     OnDragStart-starts / OnDragStop-ends shape, and were only fixed by
--     dropping `RegisterForDrag` entirely and starting from OnMouseDown
--     (confirmed in-game 2026-09-03, "mukodik minden, ahogy kell").
--   * unrealUI hit it too (`modules/character.lua`, USER_CONFIRMED_INGAME):
--     "RegisterForDrag/OnDragStart/OnDragStop alone ... the model kept
--     spinning after the mouse button was released". Their workaround is
--     the opposite direction -- pair the registration with SetMovable +
--     a throwaway StartMoving/StopMovingOrSizing so the engine really
--     owns the move and does emit OnDragStop. That is not usable here:
--     this icon is CLAMPED to the minimap ring by updatePosition on every
--     tick, so handing the move to the engine fights our own SetPoint.
--
-- The previous fix here kept `RegisterForDrag` and tried to make
-- `OnMouseUp` reachable by expanding the hit rectangle. That addressed
-- reachability, but the mouse-up was never being delivered in the first
-- place -- so it could not work, and it didn't.
--
-- What the drag does now, mirroring LibConfig-1.0's `AttachThumbDrag`:
--
--  1. **No `RegisterForDrag`, and the drag starts from `OnMouseDown`.**
--     The press is on the button by definition, and no engine drag is
--     pending, so OnMouseUp comes back.
--  2. **Our own click-vs-drag threshold**, which is the only thing
--     `RegisterForDrag` was still buying us here (the button must stay
--     clickable). A press only becomes a drag once the cursor has
--     travelled DRAG_START_PIXELS; until then the icon does not move and
--     the release is an ordinary click. Same idea as the client's own
--     15-pixel dead zone, just ours, and ~half as far so a real drag
--     feels immediate.
--  3. **Expand the button's own hit rectangle for the duration of the
--     drag.** SetHitRectInsets takes negative values to grow the hit area
--     without touching size, anchors or drawing (documented on UA:
--     widgets/Frame.md#sethitrectinsets). The cursor then cannot leave
--     the button, so its OnMouseUp fires wherever the release happens --
--     which matters because this button is clamped to the ring and the
--     cursor routinely ends up where the button is not. Also a +50 frame
--     LEVEL lift for the same reason: the thing most likely under the
--     cursor while dragging a minimap icon is ANOTHER minimap icon, a
--     sibling at the same level. Both restored on release.
--  4. **`GetButtonState() == "PUSHED"` polled in onUpdate** as a second
--     opinion only, ARMED only once a PUSHED reading has actually been
--     seen during this drag -- this client returns "UNKNOWN" both for a
--     released button and for a plain hover, so an unconditional poll
--     would end every drag on its first tick.
--  5. **A dead-man timer**, plus OnHide teardown. An expanded hit
--     rectangle that never got restored would swallow every click in the
--     UI, which is far worse than a drag that ends a little late.
--
-- (IsMouseButtonDown, the obvious way to ask, does not exist on this
-- client. A separate full-screen catcher shown mid-drag was tried and
-- failed: a frame only receives a mouse-UP for a press that started on
-- it, and a catcher shown mid-hold never saw the press.)
-- ---------------------------------------------------------------------
-- ...and why NONE of the above may run on a real Blizzard client
--
-- Everything described above is a workaround for a UA bug. On the real
-- clients this library also ships to -- 1.12.1, the one it was written
-- for, and 3.3.5 -- `RegisterForDrag` with `OnDragStart`/`OnDragStop`
-- works exactly as intended, and applying the workaround there is not
-- merely redundant, it BREAKS the button.
--
-- Observed live 2026-09-04 on real 1.12.1, two icons (Bagzen +
-- ZygorGuidesViewerNG), all fine until the first drag:
--   * after dragging icon A, hovering A no longer produced its tooltip;
--   * hovering B still worked, and LEAVING B popped up A's tooltip,
--     anchored at A, which then only went away by hovering B again;
--   * dragging repeatedly grabbed the two icons alternately -- aim at A
--     and B moves, aim again and A moves.
-- What is certain from that: after the drag, mouse targeting no longer
-- matches where the icons actually are, and `endDrag` itself did run
-- (`isDraggingButton` had been cleared, or no icon would have shown a
-- tooltip at all -- one did). The exact mechanism is NOT established:
-- resetting the insets may not undo an expansion on this client, or the
-- cached mouse focus may simply never be re-evaluated because the cursor
-- never "left" the screen-sized frame. Both fit; neither was measured,
-- and neither needs to be.
--
-- Rather than chase a second workaround for the workaround, the
-- non-UA path is simply upstream's: `RegisterForDrag`, `OnDragStart`
-- starts, `OnDragStop` ends, no hit-rect capture, no `GetButtonState`
-- poll (without the expanded rectangle the button un-pushes the moment
-- the cursor leaves it, so the poll would end every drag instantly).
--
-- Detecting UA: ported from the user's own `Bagzen.IsUA`
-- (`source/Bagzen/Bagzen.lua:25`), NOT from `_VERSION`. `_VERSION ==
-- "Lua 5.1"` is this project's usual client probe, but it is wrong here:
-- this library also runs on 3.3.5, which is Lua 5.1 too and would take
-- the UA path. `GetUECvar` is the Unreal engine's own cvar accessor and
-- exists nowhere else; the 5875 interface number is the second half of
-- the same check upstream in Bagzen. Keep the two in sync if that one
-- ever changes.
local function detectUA()
	if GetUECvar then return true end
	if type(GetBuildInfo) == "function" then
		local _, _, _, tocversion = GetBuildInfo()
		if tocversion == 5875 then return true end
	end
	return false
end

local USE_DRAG_CAPTURE = detectUA()

local DRAG_CAPTURE_INSET = -4000
local DRAG_MAX_SECONDS = 60
local DRAG_START_PIXELS = 8

do
	local deg, atan2 = math.deg, math.atan2

	local function buttonStillHeld(button)
		if not button or not button.GetButtonState then return nil end
		local ok, state = pcall(button.GetButtonState, button)
		if not ok or type(state) ~= "string" then return nil end
		return state == "PUSHED"
	end

	-- Cursor position in the same units updatePosition works in, so the
	-- travel threshold is measured against the same scale the icon moves in.
	local function cursorPosition(button)
		local ok, px, py = pcall(GetCursorPosition)
		if not ok or not tonumber(px) then return nil end
		local scaleOk, scale = pcall(button.GetEffectiveScale, button)
		if not scaleOk or not tonumber(scale) or scale == 0 then scale = 1 end
		return px / scale, py / scale
	end

	local function trackCursor(button)
		local mx, my = Minimap:GetCenter()
		local px, py = cursorPosition(button)
		if not px or not mx then return end
		local pos = fmod(deg(atan2(py - my, px - mx)), 360)
		if button.db then
			button.db.minimapPos = pos
		else
			button.minimapPos = pos
		end
		updatePosition(button, pos)
	end

	local function onUpdate()
		local button = this

		-- Still deciding whether this press is a click or a drag: don't
		-- move the icon, don't claim the cursor, just watch the travel.
		if button.dragPending then
			local px, py = cursorPosition(button)
			if px and button.dragStartX then
				local dx, dy = px - button.dragStartX, py - button.dragStartY
				if dx * dx + dy * dy >= DRAG_START_PIXELS * DRAG_START_PIXELS then
					beginDrag(button)
				end
			end
		end

		if button.dragActive then
			trackCursor(button)

			-- Only meaningful while the hit rectangle keeps the cursor on
			-- the button. Without it the button un-pushes as soon as the
			-- cursor moves off, and this would end every drag instantly.
			if USE_DRAG_CAPTURE then
				local held = buttonStillHeld(button)
				if held == true then
					button.dragArmed = true
				elseif held == false and button.dragArmed then
					endDrag(button)
					return
				end
			end
		end

		-- Runs for a pending press too: a press that is never released
		-- (client hiccup, alt-tab) must not leave an OnUpdate ticking, and
		-- once the drag is live it must not leave a screen-wide hit
		-- rectangle behind either.
		if button.dragStartedAt and type(GetTime) == "function" then
			local now = GetTime()
			if tonumber(now) and now - button.dragStartedAt > DRAG_MAX_SECONDS then
				endDrag(button)
			end
		end
	end

	-- A press landed on the button. Nothing visible happens yet -- see
	-- beginDrag for the point of no return.
	function pressDrag()
		local button = this
		-- Real Blizzard clients start their drags from OnDragStart
		-- instead; letting this run there would give every press a
		-- second, competing start.
		if not USE_DRAG_CAPTURE then return end
		if not button or button.dragLocked then return end
		if button.dragPending or button.dragActive then return end
		-- OnMouseDown reports the button in arg1 on a client that passes
		-- it; treat "no idea" as left so this still works if it doesn't.
		if type(arg1) == "string" and arg1 ~= "LeftButton" then return end
		button.dragPending = true
		button.dragArmed = false
		button.dragStartX, button.dragStartY = cursorPosition(button)
		button.dragStartedAt = (type(GetTime) == "function" and GetTime()) or nil
		button:SetScript("OnUpdate", onUpdate)
	end

	-- The press has travelled far enough to be a drag. From here the icon
	-- follows the cursor and the button owns the cursor until release.
	function beginDrag(button)
		button = button or this
		if not button or button.dragActive then return end
		button.dragPending = nil
		button.dragActive = true
		button.dragMoved = true
		isDraggingButton = true
		button:LockHighlight()
		button.isMouseDown = true
		button.icon:UpdateCoord()
		if not button.dragStartedAt and type(GetTime) == "function" then
			button.dragStartedAt = GetTime()
		end
		if USE_DRAG_CAPTURE then
			pcall(button.SetHitRectInsets, button,
				DRAG_CAPTURE_INSET, DRAG_CAPTURE_INSET, DRAG_CAPTURE_INSET, DRAG_CAPTURE_INSET)
			local levelOk, level = pcall(button.GetFrameLevel, button)
			if levelOk and tonumber(level) then
				button.dragRestoreLevel = level
				pcall(button.SetFrameLevel, button, level + 50)
			end
		end
		lib.tooltip:Hide()
		for _, other in next, lib.objects do
			if other.showOnMouseover then
				--other.fadeOut:Stop()
				other:SetAlpha(1)
			end
		end
	end

	-- Real-client path (1.12.1 / 3.3.5), upstream's own: the client
	-- delivers both ends of the drag by itself, so there is nothing to
	-- compensate for. The travel the client requires before OnDragStart
	-- is also what keeps the button clickable here, which is why this
	-- path needs no threshold of its own.
	function onDragStart()
		local button = this
		if not button or button.dragLocked then return end
		beginDrag(button)
		button:SetScript("OnUpdate", onUpdate)
	end

	function onDragStop()
		endDrag(this)
	end
end

-- Ends a pending press or a live drag, and is safe to call on a button
-- doing neither. Takes the button explicitly: it is called from lib:Lock
-- and from OnHide as well as from the button's own handlers, and `this` is
-- only meaningful inside the latter.
function endDrag(button)
	button = button or this
	if not button then return end
	if not button.dragPending and not button.dragActive then return end

	local wasActive = button.dragActive
	button.dragPending = nil
	button.dragActive = nil
	button.dragArmed = false
	button.dragStartedAt = nil
	button.dragStartX, button.dragStartY = nil, nil
	button:SetScript("OnUpdate", nil)
	button.isMouseDown = false
	if button.icon then button.icon:UpdateCoord() end
	-- Only ever touched under USE_DRAG_CAPTURE -- don't reset insets this
	-- library never set, and on a real client the reset is precisely what
	-- was observed not to restore normal mouse targeting.
	if USE_DRAG_CAPTURE then
		pcall(button.SetHitRectInsets, button, 0, 0, 0, 0)
	end
	if button.dragRestoreLevel then
		pcall(button.SetFrameLevel, button, button.dragRestoreLevel)
		button.dragRestoreLevel = nil
	end

	if wasActive then
		isDraggingButton = false
		button:UnlockHighlight()
		for _, other in next, lib.objects do
			if other.showOnMouseover then
				--other.fadeOut:Play()
			end
		end
	end
end

local defaultCoords = {0, 1, 0, 1}
local function updateCoord(self)
	local coords = self:GetParent().dataObject.iconCoords or defaultCoords
	local deltaX, deltaY = 0, 0
	if not self:GetParent().isMouseDown then
		deltaX = (coords[2] - coords[1]) * 0.05
		deltaY = (coords[4] - coords[3]) * 0.05
	end
	self:SetTexCoord(coords[1] + deltaX, coords[2] - deltaX, coords[3] + deltaY, coords[4] - deltaY)
end

local function createButton(name, object, db)
	local button = CreateFrame("Button", "LibDBIcon10_"..name, Minimap)
	button.dataObject = object
	button.db = db
	button:SetFrameStrata("MEDIUM")
	button:SetWidth(31)
	button:SetHeight(31)
	button:SetFrameLevel(8)
	button:SetFrameStrata("HIGH")
	button:SetFrameLevel(7)
	button:EnableMouse(true)
	--button:EnableMouseWheel(true)
	button:SetMovable(true)
	button:RegisterForClicks("LeftButtonUp","RightButtonUp")
	-- On UA, deliberately NOT RegisterForDrag'd -- see the "Dragging on
	-- Unreal Azeroth" block above. A non-empty drag registration puts that
	-- client into a pending engine drag on every press, and that is what
	-- stops OnDragStop AND OnMouseUp from ever arriving; the drag starts
	-- from OnMouseDown with our own click-vs-drag threshold instead. Note
	-- there is no way back once registered on UA: RegisterForDrag only ever
	-- APPENDS, and calling it with no arguments leaves the list unchanged.
	-- On real 1.12.1 this is upstream's normal, working mechanism.
	if not USE_DRAG_CAPTURE then
		button:RegisterForDrag("LeftButton")
	end
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	local overlay = button:CreateTexture(nil, "OVERLAY")
	overlay:SetWidth(53)
	overlay:SetHeight(53)
	overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	overlay:SetPoint("TOPLEFT",0,0)
	local background = button:CreateTexture(nil, "BACKGROUND")
	background:SetWidth(20)
	background:SetHeight(20)
	background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	background:SetPoint("TOPLEFT", 7, -5)
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetWidth(17)
	icon:SetHeight(17)
	icon:SetTexture(object.icon)
	icon:SetPoint("TOPLEFT", 7, -6)
	button.icon = icon
	icon.parent = button
	button.isMouseDown = false

	local r, g, b = safeGetVertexColor(icon)
	icon:SetVertexColor(object.iconR or r, object.iconG or g, object.iconB or b)

	icon.UpdateCoord = updateCoord
	icon:UpdateCoord()

	button:SetScript("OnEnter", onEnter)
	button:SetScript("OnLeave", onLeave)
	button:SetScript("OnClick",  onClick)
	-- `dragLocked` replaces the old "wire/unwire OnDragStart" way of
	-- locking an icon in place -- one flag both drag paths honour, instead
	-- of one path's handler existing and the other's not.
	button.dragLocked = (db and db.lock) and true or nil
	if not USE_DRAG_CAPTURE then
		button:SetScript("OnDragStart", onDragStart)
		button:SetScript("OnDragStop", onDragStop)
	end
	button:SetScript("OnMouseDown", onMouseDown)
	button:SetScript("OnMouseUp", onMouseUp)
	button:SetScript("OnHide", onHide)
--[[
	button.fadeOut = button:CreateAnimationGroup()
	local animOut = button.fadeOut:CreateAnimation("Alpha")
	animOut:SetOrder(1)
	animOut:SetDuration(0.2)
	animOut:SetFromAlpha(1)
	animOut:SetToAlpha(0)
	animOut:SetStartDelay(1)
	button.fadeOut:SetToFinalAlpha(true)
]]
	lib.objects[name] = button

	if lib.loggedIn then
		updatePosition(button, db and db.minimapPos)
		if not db or not db.hide then
			button:Show()
		else
			button:Hide()
		end
	end
	lib.callbacks:Fire("LibDBIcon_IconCreated", 2, button, name) -- Fire 'Icon Created' callback
end

-- We could use a metatable.__index on lib.objects, but then we'd create
-- the icons when checking things like :IsRegistered, which is not necessary.
local function check(name)
	if lib.notCreated[name] then
		createButton(name, lib.notCreated[name][1], lib.notCreated[name][2])
		lib.notCreated[name] = nil
	end
end

-- Wait a bit with the initial positioning to let any GetMinimapShape addons
-- load up.
if not lib.loggedIn then
	local f = CreateFrame("Frame")
	f:SetScript("OnEvent", function()
		for _, button in next, lib.objects do
			updatePosition(button, button.db and button.db.minimapPos)
			if not button.db or not button.db.hide then
				button:Show()
			else
				button:Hide()
			end
		end
		lib.loggedIn = true
		this:SetScript("OnEvent", nil)
	end)
	f:RegisterEvent("PLAYER_LOGIN")
end

local function getDatabase(name)
	return lib.notCreated[name] and lib.notCreated[name][2] or lib.objects[name].db
end

function lib:Register(name, object, db)
	if not object.icon then error("Can't register LDB objects without icons set!") end
	if lib.objects[name] or lib.notCreated[name] then error(DBICON10.. ": Object '".. name .."' is already registered.") end
	if not db or not db.hide then
		createButton(name, object, db)
	else
		lib.notCreated[name] = {object, db}
	end
end

function lib:Lock(name)
	if not lib:IsRegistered(name) then return end
	if lib.objects[name] then
		lib.objects[name].dragLocked = true
		-- Locking mid-drag must also end the drag in progress, or the
		-- expanded hit rectangle stays on the button forever.
		endDrag(lib.objects[name])
	end
	local db = getDatabase(name)
	if db then
		db.lock = true
	end
end

function lib:Unlock(name)
	if not lib:IsRegistered(name) then return end
	if lib.objects[name] then
		lib.objects[name].dragLocked = nil
	end
	local db = getDatabase(name)
	if db then
		db.lock = nil
	end
end

function lib:Hide(name)
	if not lib.objects[name] then return end
	lib.objects[name]:Hide()
end

function lib:Show(name)
	check(name)
	local button = lib.objects[name]
	if button then
		button:Show()
		updatePosition(button, button.db and button.db.minimapPos or button.minimapPos)
	end
end

function lib:IsRegistered(name)
	return (lib.objects[name] or lib.notCreated[name]) and true or false
end

function lib:Refresh(name, db)
	check(name)
	local button = lib.objects[name]
	if db then
		button.db = db
	end
	updatePosition(button, button.db and button.db.minimapPos or button.minimapPos)
	if not button.db or not button.db.hide then
		button:Show()
	else
		button:Hide()
	end
	if not button.db or not button.db.lock then
		button.dragLocked = nil
	else
		button.dragLocked = true
		endDrag(button)
	end
end

function lib:GetMinimapButton(name)
	return lib.objects[name]
end

do
	local function OnMinimapEnter()
		if isDraggingButton then return end
		for _, button in next, lib.objects do
			if button.showOnMouseover then
			--	button.fadeOut:Stop()
				button:SetAlpha(1)
			end
		end
	end
	local function OnMinimapLeave()
		if isDraggingButton then return end
		for _, button in next, lib.objects do
			if button.showOnMouseover then
			--	button.fadeOut:Play()
			end
		end
	end
	-- NOTE: lib:HookScript(Minimap, "OnEnter"/"OnLeave", ...) used to be
	-- used here, but AceHook-3.0's HookScript refuses with "You can
	-- only hook a script on a frame object" on this client: its
	-- validation calls Minimap:HasScript(method), which incorrectly
	-- returns false here even though Minimap:GetScript()/:SetScript()
	-- both work fine (binding-level bug, not something fixable from
	-- here). Hook manually instead, preserving any existing handler.
	local origMinimapOnEnter = Minimap:GetScript("OnEnter")
	Minimap:SetScript("OnEnter", function()
		if origMinimapOnEnter then origMinimapOnEnter() end
		OnMinimapEnter()
	end)
	local origMinimapOnLeave = Minimap:GetScript("OnLeave")
	Minimap:SetScript("OnLeave", function()
		if origMinimapOnLeave then origMinimapOnLeave() end
		OnMinimapLeave()
	end)

	function lib:ShowOnEnter(name, value)
		local button = lib.objects[name]
		if button then
			if value then
				button.showOnMouseover = true
			--	button.fadeOut:Stop()
				button:SetAlpha(0)
			else
				button.showOnMouseover = false
			--	button.fadeOut:Stop()
				button:SetAlpha(1)
			end
		end
	end
end

function lib:GetButtonList()
	local t = {}
	for name in next, lib.objects do
		tinsert(t, name)
	end
	return t
end

function lib:SetButtonRadius(radius)
	if type(radius) == "number" then
		lib.radius = radius
		for _, button in next, lib.objects do
			updatePosition(button, button.db and button.db.minimapPos or button.minimapPos)
		end
	end
end

function lib:SetButtonToPosition(button, position)
	updatePosition(lib.objects[button] or button, position)
end

-- Upgrade!
for name, button in next, lib.objects do
	local db = getDatabase(name)
	button.dragLocked = (db and db.lock) and true or nil
	if USE_DRAG_CAPTURE then
		-- Buttons created by an OLDER copy of this library were already
		-- RegisterForDrag'd, and on UA that cannot be undone from Lua
		-- (RegisterForDrag only appends; no-arg leaves the list unchanged).
		-- Nil out the handlers so nothing acts on the engine drag -- the
		-- pending drag itself stays, so such a button may still not release
		-- properly. Reloading the UI recreates it clean.
		button:SetScript("OnDragStart", nil)
		button:SetScript("OnDragStop", nil)
	else
		-- Appending an already-present button name is a no-op, so this is
		-- safe whether the older copy registered the button or not.
		pcall(button.RegisterForDrag, button, "LeftButton")
		button:SetScript("OnDragStart", onDragStart)
		button:SetScript("OnDragStop", onDragStop)
	end
	button:SetScript("OnEnter", onEnter)
	button:SetScript("OnLeave", onLeave)
	button:SetScript("OnClick", onClick)
	button:SetScript("OnMouseDown", onMouseDown)
	button:SetScript("OnMouseUp", onMouseUp)
	button:SetScript("OnHide", onHide)
--[[
	if not button.fadeOut then -- Upgrade to 39
		button.fadeOut = button:CreateAnimationGroup()
		local animOut = button.fadeOut:CreateAnimation("Alpha")
		animOut:SetOrder(1)
		animOut:SetDuration(0.2)
		animOut:SetFromAlpha(1)
		animOut:SetToAlpha(0)
		animOut:SetStartDelay(1)
		button.fadeOut:SetToFinalAlpha(true)
	end
	]]
end
lib:SetButtonRadius(lib.radius) -- Upgrade to 40
