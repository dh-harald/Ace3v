-- LibHereBeDragons-Pins-1.0 shows pins/icons on the minimap and the world map.
--
-- A vanilla (WoW 1.12.1 / Unreal Azeroth) implementation of the HereBeDragons-Pins-1.0 API.
-- The minimap maths is upstream's, unchanged.  What differs is capability handling: the
-- minimap CVars this library needs do not exist on Unreal Azeroth, so every read of them
-- goes through one gate -- see docs/status.md, open question 1.
--
-- Dependencies: LibStub, LibHereBeDragons-1.0.

local MAJOR, MINOR = "LibHereBeDragons-Pins-1.0", 1
assert(LibStub, MAJOR .. " requires LibStub")

local pins = LibStub:NewLibrary(MAJOR, MINOR)
if not pins then return end

local HBD = LibStub("LibHereBeDragons-1.0") or LibStub("HereBeDragons-1.0")
assert(HBD, MAJOR .. " requires LibHereBeDragons-1.0")

-- Lua upvalues.  math.* only: WoW's global sin/cos work in DEGREES, and facing is radians.
local mcos, msin, mmax, msqrt = math.cos, math.sin, math.max, math.sqrt
local type, pairs, next = type, pairs, next
local tsetn = table.setn

-- Unnamed frame: on Unreal Azeroth CreateFrame() rewrites every "-" in a frame name.
pins.updateFrame         = pins.updateFrame or CreateFrame("Frame")

pins.minimapPins         = pins.minimapPins or {}
pins.activeMinimapPins   = pins.activeMinimapPins or {}
pins.minimapPinRegistry  = pins.minimapPinRegistry or {}

pins.worldmapPins        = pins.worldmapPins or {}
pins.worldmapPinRegistry = pins.worldmapPinRegistry or {}

pins.Minimap             = pins.Minimap or Minimap
-- Pins are children of this frame and positioned in ITS coordinate space, so they inherit
-- the map's scale automatically -- no GetEffectiveScale maths anywhere.  WorldMapButton
-- overlays the detail area at the same size in the 1.12 default UI; pfQuest has shipped this
-- exact approach on this client class for years (map.lua:873, :903-907).
pins.worldmapAnchor      = pins.worldmapAnchor or WorldMapButton

local worldmapPins        = pins.worldmapPins
local worldmapPinRegistry = pins.worldmapPinRegistry

local minimapPins        = pins.minimapPins
local activeMinimapPins  = pins.activeMinimapPins
local minimapPinRegistry = pins.minimapPinRegistry

local function wipe(t)
	for k in pairs(t) do t[k] = nil end
	tsetn(t, 0)
	return t
end

-- Diameter of the minimap in game yards at each zoom level.  Identical to Astrolabe's
-- MinimapSize and to pfQuest's table -- three independent copies of the same vanilla values.
-- GetZoomLevels() is 6 on both clients, so 0-5 covers it exactly.
local minimap_size = {
	indoor = {
		[0] = 300,
		[1] = 240,
		[2] = 180,
		[3] = 120,
		[4] = 80,
		[5] = 50,
	},
	outdoor = {
		[0] = 466 + 2/3,
		[1] = 400,
		[2] = 333 + 1/3,
		[3] = 266 + 2/6,
		[4] = 200,
		[5] = 133 + 1/3,
	},
}

-- { upper-left, lower-left, upper-right, lower-right }; true means that quadrant is square.
-- A round minimap has no entry, so minimapShape stays nil and the round test is used.
local minimap_shapes = {
	["SQUARE"]                = { false, false, false, false },
	["CORNER-TOPLEFT"]        = { true,  false, false, false },
	["CORNER-TOPRIGHT"]       = { false, false, true,  false },
	["CORNER-BOTTOMLEFT"]     = { false, true,  false, false },
	["CORNER-BOTTOMRIGHT"]    = { false, false, false, true },
	["SIDE-LEFT"]             = { true,  true,  false, false },
	["SIDE-RIGHT"]            = { false, false, true,  true },
	["SIDE-TOP"]              = { true,  false, true,  false },
	["SIDE-BOTTOM"]           = { false, true,  false, true },
	["TRICORNER-TOPLEFT"]     = { true,  true,  true,  false },
	["TRICORNER-TOPRIGHT"]    = { true,  false, true,  true },
	["TRICORNER-BOTTOMLEFT"]  = { true,  true,  false, true },
	["TRICORNER-BOTTOMRIGHT"] = { false, true,  true,  true },
}

-- Show-flag levels.  HereBeDragons-Pins-1.0 has none -- these are 2.0's constants and
-- values, reused so a 2.0-aware consumer's literals still mean the right thing.  A pin
-- always shows on its own zone map; the flag says how much further it reaches.  On vanilla a
-- zone's parent IS its continent, so PARENT and CONTINENT behave identically here.
HBD_PINS_WORLDMAP_SHOW_PARENT    = 1
HBD_PINS_WORLDMAP_SHOW_CONTINENT = 2
HBD_PINS_WORLDMAP_SHOW_WORLD     = 3

local COSMIC_ID = 0

local tableCache = setmetatable({}, {__mode = 'k'})

local function newCachedTable()
	local t = next(tableCache)
	if t then
		tableCache[t] = nil
		wipe(t)
	else
		t = {}
	end
	return t
end

local function recycle(t)
	if t then tableCache[t] = true end
end

--------------------------------------------------------------------------------------------
-- Client capabilities
--
-- GetCVar returns the string "0" for an unregistered name, which is indistinguishable from
-- a real zero, so GetCVarDefault (nil when unregistered) is the probe.  Fail SAFE toward
-- "the CVars work": if GetCVarDefault itself is missing, assume a client that has them, so
-- stock 1.12.1 keeps upstream's exact behaviour.
--------------------------------------------------------------------------------------------

local cvarsUsable, rotateCVarUsable

local function probeCVars()
	if type(GetCVarDefault) ~= "function" then
		cvarsUsable, rotateCVarUsable = true, true
		return
	end
	cvarsUsable = GetCVarDefault("minimapZoom") ~= nil and GetCVarDefault("minimapInsideZoom") ~= nil
	rotateCVarUsable = GetCVarDefault("rotateMinimap") ~= nil
end
probeCVars()

-- "outdoor" | "indoor" | nil (nil = follow the client)
pins.environmentOverride = pins.environmentOverride or nil

local indoors = "outdoor"
local rotateMinimap = false

local function UpdateMinimapZoom()
	if pins.environmentOverride then
		indoors = pins.environmentOverride
		return
	end
	if not cvarsUsable then
		-- Unreal Azeroth registers neither CVar, so the environment cannot be asked for: use
		-- outdoor.  Some interiors there do rescale the minimap art, but the client does not
		-- move addon pins when it does, and no addon compensates -- Astrolabe (:337-352) and
		-- pfQuest (map.lua:95-113) both also land on "outdoor" there, because their
		-- minimapZoom == minimapInsideZoom test is always true when both read as "0" and the
		-- follow-up comparison can then never match.  So this is the ecosystem's answer, not a
		-- guess.  pins:SetMinimapEnvironment("indoor") forces the other table.
		--
		-- Critically: do NOT run upstream's zoom nudge here.  It writes the user's minimap
		-- zoom, and on this client the CVar comparison is always true, so it would fire on
		-- every update for no information at all.
		indoors = "outdoor"
		return
	end
	-- Stock 1.12.1: upstream's method, unchanged.  When the two CVars are equal the
	-- environments are indistinguishable, so nudge the zoom by one, read, and restore.
	local zoom = pins.Minimap:GetZoom()
	if GetCVar("minimapZoom") == GetCVar("minimapInsideZoom") then
		pins.Minimap:SetZoom(zoom < 2 and zoom + 1 or zoom - 1)
	end
	indoors = GetCVar("minimapZoom") + 0 == pins.Minimap:GetZoom() and "outdoor" or "indoor"
	pins.Minimap:SetZoom(zoom)
end

local function UpdateRotateMinimap()
	if not rotateCVarUsable then
		-- Not readable, so we cannot know.  Treat rotation as OFF rather than hiding every
		-- pin, which is what upstream does when it cannot resolve facing.  Unreal Azeroth
		-- has no rotating minimap, so this is also simply correct there.
		rotateMinimap = false
		return
	end
	rotateMinimap = GetCVar("rotateMinimap") == "1"
end
UpdateRotateMinimap()

--- Force the indoor/outdoor environment instead of asking the client.
-- @param mode "outdoor", "indoor", or nil/"auto" to follow the client
function pins:SetMinimapEnvironment(mode)
	if mode == "auto" then mode = nil end
	if mode ~= nil and mode ~= "indoor" and mode ~= "outdoor" then
		error(MAJOR .. ": SetMinimapEnvironment: mode must be \"indoor\", \"outdoor\" or nil", 2)
	end
	pins.environmentOverride = mode
	UpdateMinimapZoom()
	pins.queueFullUpdate = true
end

--- Report what the library decided, and whether it could ask the client.
-- @return "indoor"|"outdoor", cvarsUsable, rotateMinimap
function pins:GetMinimapEnvironment()
	return indoors, cvarsUsable, rotateMinimap
end

-- Third-party square-minimap addons predate the GetMinimapShape convention.  Astrolabe
-- (:368) and TomTom (Waypoints.lua:273) each hand-code this test; owning it here lets both
-- copies be deleted.
local function getMinimapShape()
	if GetMinimapShape then
		return GetMinimapShape()
	end
	if Squeenix then
		return "SQUARE"
	end
	if simpleMinimap_Skins and simpleMinimap_Skins.GetShape
	   and simpleMinimap_Skins:GetShape() == "square" then
		return "SQUARE"
	end
	return nil
end

--------------------------------------------------------------------------------------------
-- Minimap pin placement (upstream's maths, unchanged)
--------------------------------------------------------------------------------------------

local minimapPinCount = 0
pins.queueFullUpdate = false
local minimapScale, minimapShape, mapRadius, minimapWidth, minimapHeight, mapSin, mapCos
local lastZoom, lastFacing, lastXY, lastYY

local function drawMinimapPin(pin, data)
	-- NOTE the delta direction.  Upstream writes "lastXY - data.x" because retail's world
	-- axes run AGAINST increasing map coordinates (its GetWorldCoordinatesFromZone is
	-- "left - width * x").  This port uses Astrolabe's additive axes instead -- +x is map
	-- right/east, +y is map down/south -- so the deltas must be "pin minus player" for the
	-- pin to be drawn on the correct side.  Getting this backwards mirrors every pin through
	-- the centre, which looks plausible right up until you walk towards one.
	local xDist, yDist = data.x - lastXY, data.y - lastYY

	if rotateMinimap then
		local dx, dy = xDist, yDist
		xDist = dx * mapCos - dy * mapSin
		yDist = dx * mapSin + dy * mapCos
	end

	local diffX = xDist / mapRadius
	local diffY = yDist / mapRadius

	local isRound = true
	if minimapShape and not (xDist == 0 or yDist == 0) then
		isRound = (xDist < 0) and 1 or 3
		if yDist < 0 then
			isRound = minimapShape[isRound]
		else
			isRound = minimapShape[isRound + 1]
		end
	end

	local dist
	if isRound then
		dist = (diffX * diffX + diffY * diffY) / 0.9^2
	else
		dist = mmax(diffX * diffX, diffY * diffY) / 0.9^2
	end

	-- Outside the rim: either slide along it, or hide.
	if dist > 1 and data.floatOnEdge then
		dist = msqrt(dist)
		diffX = diffX / dist
		diffY = diffY / dist
	end

	if dist <= 1 or data.floatOnEdge then
		pin:Show()
		pin:ClearAllPoints()
		pin:SetPoint("CENTER", pins.Minimap, "CENTER", diffX * minimapWidth, -diffY * minimapHeight)
		data.onEdge = (dist > 1)
	else
		pin:Hide()
		data.onEdge = nil
		data.keep = nil
	end
end

local function UpdateMinimapPins(force)
	local x, y, instanceID = HBD:GetPlayerWorldPosition()
	local mapID, mapFloor = HBD:GetPlayerZone()

	local zoom = pins.Minimap:GetZoom()
	local diffZoom = zoom ~= lastZoom

	local facing
	if rotateMinimap then
		facing = HBD:GetPlayerFacing()
	else
		facing = lastFacing
	end

	-- No position (an instance, or a map we have no data for), or rotation is on and this
	-- client cannot tell us the facing: hide everything rather than draw it wrong.
	if not x or not y or (rotateMinimap and not facing) then
		minimapPinCount = 0
		for pin in pairs(activeMinimapPins) do
			pin:Hide()
			activeMinimapPins[pin] = nil
		end
		return
	end

	local newScale = pins.Minimap:GetScale()
	if minimapScale ~= newScale then
		minimapScale = newScale
		force = true
	end

	if x ~= lastXY or y ~= lastYY or diffZoom or facing ~= lastFacing or force then
		minimapShape = minimap_shapes[getMinimapShape() or "ROUND"]
		mapRadius = minimap_size[indoors][zoom] / 2
		minimapWidth = pins.Minimap:GetWidth() / 2
		minimapHeight = pins.Minimap:GetHeight() / 2

		lastZoom = zoom
		lastFacing = facing
		lastXY, lastYY = x, y

		if rotateMinimap then
			mapSin = msin(facing)
			mapCos = mcos(facing)
		end

		for pin, data in pairs(minimapPins) do
			if data.instanceID == instanceID
			   and (not data.floor or (data.floor == mapFloor
			                           and (data.floor == 0 or data.mapID == mapID))) then
				activeMinimapPins[pin] = data
				data.keep = true
				drawMinimapPin(pin, data)      -- may clear data.keep if off the map
			end
		end

		minimapPinCount = 0
		for pin, data in pairs(activeMinimapPins) do
			if not data.keep then
				pin:Hide()
				activeMinimapPins[pin] = nil
			else
				minimapPinCount = minimapPinCount + 1
				data.keep = nil
			end
		end
	end
end

local function UpdateMinimapIconPosition()
	local zoom = pins.Minimap:GetZoom()
	if zoom ~= lastZoom then
		UpdateMinimapPins()
		return
	end

	if minimapPinCount == 0 then return end

	local x, y = HBD:GetPlayerWorldPosition()

	local facing
	if rotateMinimap then
		facing = HBD:GetPlayerFacing()
	else
		facing = lastFacing
	end

	if not x or not y or (rotateMinimap and not facing) then
		UpdateMinimapPins()
		return
	end

	local refresh
	local newScale = pins.Minimap:GetScale()
	if minimapScale ~= newScale then
		minimapScale = newScale
		refresh = true
	end

	if x ~= lastXY or y ~= lastYY or facing ~= lastFacing or refresh then
		mapRadius = minimap_size[indoors][zoom] / 2
		lastXY, lastYY = x, y
		lastFacing = facing

		if rotateMinimap then
			mapSin = msin(facing)
			mapCos = mcos(facing)
		end

		for pin, data in pairs(activeMinimapPins) do
			drawMinimapPin(pin, data)
		end
	end
end

--------------------------------------------------------------------------------------------
-- Minimap API
--------------------------------------------------------------------------------------------

--- Add an icon to the minimap, in world coordinates.
-- No floor parameter: floors are map-specific, not instance-wide.  Use the MF version.
-- @param ref your addon (table or string) -- icons are tracked per ref
-- @param icon the icon frame
-- @param instanceID instance of the coordinates
-- @param x, y world coordinates in yards
-- @param floatOnEdge slide along the rim when out of range instead of hiding
function pins:AddMinimapIconWorld(ref, icon, instanceID, x, y, floatOnEdge)
	if not ref then
		error(MAJOR .. ": AddMinimapIconWorld: 'ref' must not be nil", 2)
	end
	if type(icon) ~= "table" or not icon.SetPoint then
		error(MAJOR .. ": AddMinimapIconWorld: 'icon' must be a frame", 2)
	end
	if type(instanceID) ~= "number" or type(x) ~= "number" or type(y) ~= "number" then
		error(MAJOR .. ": AddMinimapIconWorld: 'instanceID', 'x' and 'y' must be numbers", 2)
	end

	if not minimapPinRegistry[ref] then
		minimapPinRegistry[ref] = {}
	end
	minimapPinRegistry[ref][icon] = true

	local t = minimapPins[icon] or newCachedTable()
	t.instanceID = instanceID
	t.x, t.y = x, y
	t.floatOnEdge = floatOnEdge
	t.mapID, t.floor = nil, nil

	minimapPins[icon] = t
	pins.queueFullUpdate = true

	icon:SetParent(pins.Minimap)

	return true
end

--- Add an icon to the minimap, in 0-1 zone coordinates.
-- @param mapID mapID (or mapFile) of the zone
-- @param mapFloor always nil on vanilla
-- @return true, or false when the coordinates cannot be converted
function pins:AddMinimapIconMF(ref, icon, mapID, mapFloor, x, y, floatOnEdge)
	if not ref then
		error(MAJOR .. ": AddMinimapIconMF: 'ref' must not be nil", 2)
	end
	if type(icon) ~= "table" or not icon.SetPoint then
		error(MAJOR .. ": AddMinimapIconMF: 'icon' must be a frame", 2)
	end
	if (type(mapID) ~= "number" and type(mapID) ~= "string")
	   or type(x) ~= "number" or type(y) ~= "number" then
		error(MAJOR .. ": AddMinimapIconMF: 'mapID', 'x' and 'y' must be numbers", 2)
	end

	local xCoord, yCoord, instanceID = HBD:GetWorldCoordinatesFromZone(x, y, mapID, mapFloor)
	if not xCoord then return false end

	self:AddMinimapIconWorld(ref, icon, instanceID, xCoord, yCoord, floatOnEdge)

	minimapPins[icon].mapID = HBD:GetMapIDFromFile(mapID) or mapID
	minimapPins[icon].floor = mapFloor

	return true
end

--- Is a floating icon currently pinned to the rim?
function pins:IsMinimapIconOnEdge(icon)
	if not icon then return false end
	local data = minimapPins[icon]
	if not data then return nil end
	return data.onEdge
end

--- Remove one minimap icon.
function pins:RemoveMinimapIcon(ref, icon)
	if not ref or not icon or not minimapPinRegistry[ref] then return end
	minimapPinRegistry[ref][icon] = nil
	if minimapPins[icon] then
		recycle(minimapPins[icon])
		minimapPins[icon] = nil
		activeMinimapPins[icon] = nil
	end
	icon:Hide()
end

--- Remove every minimap icon registered under ref.
function pins:RemoveAllMinimapIcons(ref)
	if not ref or not minimapPinRegistry[ref] then return end
	for icon in pairs(minimapPinRegistry[ref]) do
		recycle(minimapPins[icon])
		minimapPins[icon] = nil
		activeMinimapPins[icon] = nil
		icon:Hide()
	end
	wipe(minimapPinRegistry[ref])
end

--- Retarget every pin at another Minimap-like frame, or nil to restore the default.
function pins:SetMinimapObject(minimapObject)
	pins.Minimap = minimapObject or Minimap
	for pin in pairs(minimapPins) do
		pin:SetParent(pins.Minimap)
	end
	UpdateMinimapPins(true)
end

--- Angle and distance from the player to a pin.
-- @return angle in RADIANS (0 = north, clockwise), distance in yards
function pins:GetVectorToIcon(icon)
	if not icon then return nil, nil end
	local data = minimapPins[icon] or worldmapPins[icon]
	if not data then return nil, nil end

	local x, y, instanceID = HBD:GetPlayerWorldPosition()
	if not x or instanceID ~= data.instanceID then return nil, nil end

	return HBD:GetWorldVector(instanceID, x, y, data.x, data.y)
end

--------------------------------------------------------------------------------------------
-- World map
--------------------------------------------------------------------------------------------

local worldmapWidth, worldmapHeight
local anchorWarned

local function worldmapAnchorFrame()
	local anchor = pins.worldmapAnchor or WorldMapButton
	-- UA is a modified client, so do not assume WorldMapButton still overlays the detail
	-- frame exactly.  Say so once rather than silently misplacing every pin.
	if not anchorWarned and WorldMapDetailFrame and anchor == WorldMapButton
	   and WorldMapDetailFrame.GetWidth then
		anchorWarned = true
		local a, d = anchor:GetWidth(), WorldMapDetailFrame:GetWidth()
		if a and d and math.abs(a - d) > 1 then
			DEFAULT_CHAT_FRAME:AddMessage(MAJOR .. ": WorldMapButton (" .. a
				.. ") and WorldMapDetailFrame (" .. d
				.. ") differ in width; world map pins may be offset. Use "
				.. "pins:SetWorldMapAnchor(WorldMapDetailFrame) if they are.")
		end
	end
	return anchor
end

-- A continent map, as opposed to a zone or a battleground: only the two continent rows carry
-- areaID 0.  Data-driven, so it needs no hardcoded ids.
local function isContinentMap(mapID)
	local d = HBD.mapData[mapID]
	return d and d.areaID == 0 or false
end

local function shouldShowOnMap(data, mapID)
	if mapID == data.mapID then return true end          -- always on its own zone map
	local flag = data.showFlag
	if not flag then return false end
	if mapID == COSMIC_ID then
		return flag >= HBD_PINS_WORLDMAP_SHOW_WORLD
	end
	if isContinentMap(mapID) then
		-- PARENT and CONTINENT collapse on vanilla; both are >= SHOW_PARENT.
		return flag >= HBD_PINS_WORLDMAP_SHOW_PARENT
			and HBD.mapData[mapID].instance == data.instanceID
	end
	return false
end

local function positionWorldMapIcon(icon, data, currentMapID, currentFloor, anchor)
	-- The cosmic map has one floor per continent and the floor index IS the instance id, so
	-- a pin from either continent resolves by passing its own instance.  Upstream's trick.
	if currentMapID == COSMIC_ID then
		currentFloor = data.instanceID
	end

	local x, y = HBD:GetZoneCoordinatesFromWorld(data.x, data.y, currentMapID, currentFloor)
	if x and y then
		icon:ClearAllPoints()
		icon:SetPoint("CENTER", anchor, "TOPLEFT", x * worldmapWidth, -y * worldmapHeight)
		icon:Show()
	else
		icon:Hide()
	end
end

local function UpdateWorldMap()
	local anchor = worldmapAnchorFrame()
	if not anchor or not anchor:IsVisible() then return end

	local mapID = HBD:GetCurrentMapID()
	if not mapID then
		for icon in pairs(worldmapPins) do
			icon:Hide()
		end
		return
	end

	-- Re-read every pass so resizing the map frame is handled.
	worldmapWidth  = anchor:GetWidth()
	worldmapHeight = anchor:GetHeight()

	for icon, data in pairs(worldmapPins) do
		if shouldShowOnMap(data, mapID) then
			positionWorldMapIcon(icon, data, mapID, nil, anchor)
		else
			icon:Hide()
		end
	end
end

--- Add an icon to the world map, in world coordinates.
-- @param showFlag one of the HBD_PINS_WORLDMAP_SHOW_* levels, or nil for its own zone only
function pins:AddWorldMapIconWorld(ref, icon, instanceID, x, y, showFlag)
	if not ref then
		error(MAJOR .. ": AddWorldMapIconWorld: \'ref\' must not be nil", 2)
	end
	if type(icon) ~= "table" or not icon.SetPoint then
		error(MAJOR .. ": AddWorldMapIconWorld: \'icon\' must be a frame", 2)
	end
	if type(instanceID) ~= "number" or type(x) ~= "number" or type(y) ~= "number" then
		error(MAJOR .. ": AddWorldMapIconWorld: \'instanceID\', \'x\' and \'y\' must be numbers", 2)
	end

	if not worldmapPinRegistry[ref] then
		worldmapPinRegistry[ref] = {}
	end
	worldmapPinRegistry[ref][icon] = true

	local t = worldmapPins[icon] or newCachedTable()
	t.instanceID = instanceID
	t.x, t.y = x, y
	t.showFlag = showFlag
	t.mapID, t.floor = nil, nil

	worldmapPins[icon] = t

	icon:SetParent(worldmapAnchorFrame())
	UpdateWorldMap()

	return true
end

--- Add an icon to the world map, in 0-1 zone coordinates.
-- @return true, or false when the coordinates cannot be converted
function pins:AddWorldMapIconMF(ref, icon, mapID, mapFloor, x, y, showFlag)
	if not ref then
		error(MAJOR .. ": AddWorldMapIconMF: \'ref\' must not be nil", 2)
	end
	if type(icon) ~= "table" or not icon.SetPoint then
		error(MAJOR .. ": AddWorldMapIconMF: \'icon\' must be a frame", 2)
	end
	if (type(mapID) ~= "number" and type(mapID) ~= "string")
	   or type(x) ~= "number" or type(y) ~= "number" then
		error(MAJOR .. ": AddWorldMapIconMF: \'mapID\', \'x\' and \'y\' must be numbers", 2)
	end

	local xCoord, yCoord, instanceID = HBD:GetWorldCoordinatesFromZone(x, y, mapID, mapFloor)
	if not xCoord then return false end

	self:AddWorldMapIconWorld(ref, icon, instanceID, xCoord, yCoord, showFlag)

	worldmapPins[icon].mapID = HBD:GetMapIDFromFile(mapID) or mapID
	worldmapPins[icon].floor = mapFloor

	UpdateWorldMap()
	return true
end

--- Remove one world map icon.
function pins:RemoveWorldMapIcon(ref, icon)
	if not ref or not icon or not worldmapPinRegistry[ref] then return end
	worldmapPinRegistry[ref][icon] = nil
	if worldmapPins[icon] then
		recycle(worldmapPins[icon])
		worldmapPins[icon] = nil
	end
	icon:Hide()
end

--- Remove every world map icon registered under ref.
function pins:RemoveAllWorldMapIcons(ref)
	if not ref or not worldmapPinRegistry[ref] then return end
	for icon in pairs(worldmapPinRegistry[ref]) do
		recycle(worldmapPins[icon])
		worldmapPins[icon] = nil
		icon:Hide()
	end
	wipe(worldmapPinRegistry[ref])
end

--- Reparent world map pins onto another frame, or nil to restore WorldMapButton.
-- Needed if a client or a UI replacement does not have WorldMapButton covering the map art.
function pins:SetWorldMapAnchor(frame)
	pins.worldmapAnchor = frame or WorldMapButton
	anchorWarned = nil
	for icon in pairs(worldmapPins) do
		icon:SetParent(pins.worldmapAnchor)
	end
	UpdateWorldMap()
end

--------------------------------------------------------------------------------------------
-- Update loop
--
-- No C_Timer, and the OnUpdate elapsed argument is unreliable on Lua-created frames in
-- 1.12, so drive everything from GetTime().  UpdateMinimapZoom is called only from the
-- event path, never from here: on stock clients it writes the minimap zoom to disambiguate
-- the environments, and doing that per frame is what makes pfQuest fight the user's zoom.
--------------------------------------------------------------------------------------------

local lastFullUpdate, lastWorldUpdate = 0, 0

pins.updateFrame:SetScript("OnUpdate", function()
	if pins.Minimap and not pins.Minimap:IsVisible() then return end

	local now = GetTime()
	if pins.queueFullUpdate or (now - lastFullUpdate) >= 1 then
		-- Pass the flag through as `force`: without it UpdateMinimapPins skips its whole
		-- body when the player has not moved, so a pin added while standing still would
		-- never be drawn.  This is what queueFullUpdate is for.
		UpdateMinimapPins(pins.queueFullUpdate)
		lastFullUpdate = now
		pins.queueFullUpdate = false
	else
		UpdateMinimapIconPosition()
	end

	-- WORLD_MAP_UPDATE is not reliably fired on this client -- TomTom carries its own
	-- RedrawWorldMapIcons loop (Waypoints.lua:174-190) precisely because of that -- so also
	-- refresh on a throttle while the map is open.  Belt and braces.
	local anchor = pins.worldmapAnchor
	if anchor and anchor.IsVisible and anchor:IsVisible() and (now - lastWorldUpdate) >= 0.1 then
		lastWorldUpdate = now
		UpdateWorldMap()
	end
end)

-- UnregisterAllEvents (and UnregisterEvent) are silent no-ops on Unreal Azeroth, so this
-- cannot be relied on to clear anything.  It is kept only because re-registering an event
-- that is already registered is idempotent, so a LibStub upgrade reusing this same frame is
-- harmless either way.  Nothing here relies on delivery actually stopping.
pins.updateFrame:UnregisterAllEvents()
pins.updateFrame:SetScript("OnEvent", function()
	-- Vanilla passes event arguments as globals.
	if event == "CVAR_UPDATE" then
		-- Payload spelling differs between clients; re-probe on either.
		if arg1 == "ROTATE_MINIMAP" or arg1 == "rotateMinimap" then
			UpdateRotateMinimap()
			pins.queueFullUpdate = true
		end
	elseif event == "MINIMAP_UPDATE_ZOOM" then
		UpdateMinimapZoom()
		pins.queueFullUpdate = true
	elseif event == "WORLD_MAP_UPDATE" then
		UpdateWorldMap()
	else                                   -- PLAYER_LOGIN, PLAYER_ENTERING_WORLD
		probeCVars()
		UpdateRotateMinimap()
		UpdateMinimapZoom()
		pins.queueFullUpdate = true
		UpdateWorldMap()
	end
end)
pins.updateFrame:RegisterEvent("CVAR_UPDATE")
pins.updateFrame:RegisterEvent("MINIMAP_UPDATE_ZOOM")
pins.updateFrame:RegisterEvent("PLAYER_LOGIN")
pins.updateFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
pins.updateFrame:RegisterEvent("WORLD_MAP_UPDATE")

HBD.RegisterCallback(pins, "PlayerZoneChanged", function()
	pins.queueFullUpdate = true
	UpdateWorldMap()
end)

UpdateMinimapZoom()

--- Report the library version.
function pins:GetLibraryVersion()
	return MAJOR, MINOR
end

-- Register under the upstream name too, so an addon written against
-- HereBeDragons-Pins-1.0 finds it unmodified.
local alias = LibStub:NewLibrary("HereBeDragons-Pins-1.0", MINOR)
if alias then
	LibStub.libs["HereBeDragons-Pins-1.0"] = pins
end
