-- LibModifierState-1.0
--
-- Fires MODIFIER_STATE_CHANGED for Shift, Ctrl and Alt on clients that do not
-- have that event: vanilla 1.12.1 and Unreal Azeroth ship none. A per-frame
-- OnUpdate compares IsShiftKeyDown / IsControlKeyDown / IsAltKeyDown against
-- the last seen state (the vanilla branch of Bagzen's Events.lua) and only
-- runs while at least one callback is registered. Polling works on both
-- clients with the cursor over the 3D world and over UI frames (action
-- buttons, bag items) alike.
--
-- Differences from the real (TBC+) event:
--   * the key is "SHIFT", "CTRL" or "ALT", never "LSHIFT"/"RSHIFT" etc.:
--     neither client exposes left/right modifier state;
--   * callbacks receive the key and state as arguments, not in the
--     arg1/arg2 globals. The state is 1 (pressed) or 0 (released), as in the
--     real event.
--
-- Callbacks go through the library's own CallbackHandler-1.0 registry, not
-- through AceEvent-3.0: AceEvent's registry is shared by every Ace3 addon, so
-- a synthetic MODIFIER_STATE_CHANGED there would reach other addons' event
-- handlers, which read arg1/arg2 globals this library cannot set safely.
-- CallbackHandler-1.0 here is the vanilla Ace3 backport (zerosnake0, laytya),
-- whose Fire takes an explicit argument count: Fire(event, argc, a1, ...).
-- Several addons embedding this library share one poller and one registry
-- through LibStub.
--
-- API (CallbackHandler-1.0):
--   lib.RegisterCallback(owner, "MODIFIER_STATE_CHANGED", method)
--     method: function(event, key, state), or the name of a method on the
--             owner table, called as owner[method](owner, event, key, state)
--   lib.UnregisterCallback(owner, "MODIFIER_STATE_CHANGED")
--   lib.UnregisterAllCallbacks(owner)
--   lib:IsDown(key)   "SHIFT" | "CTRL" | "ALT" -> true/false
--   lib:IsAnyDown()   true while any of the three is held
--
-- The key getters return true/false on Unreal Azeroth and 1/nil on vanilla;
-- every reading is normalized to a boolean.

local _G = _G or getfenv()

local MAJOR, MINOR = "LibModifierState-1.0", 1
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

local CallbackHandler = LibStub("CallbackHandler-1.0")

local EVENT = "MODIFIER_STATE_CHANGED"
lib.EVENT = EVENT

local KEYS = { "SHIFT", "CTRL", "ALT" }
local GETTERS = {
	SHIFT = "IsShiftKeyDown",
	CTRL = "IsControlKeyDown",
	ALT = "IsAltKeyDown",
}

lib.callbacks = lib.callbacks or CallbackHandler:New(lib)
lib.state = lib.state or {}
lib.frame = lib.frame or CreateFrame("Frame")

local function ReadKey(key)
	local getter = _G[GETTERS[key]]
	if type(getter) ~= "function" then return false end
	local ok, down = pcall(getter)
	if ok and down then return true end
	return false
end

local function Poll()
	local i
	for i = 1, 3 do
		local key = KEYS[i]
		local down = ReadKey(key)
		if down ~= lib.state[key] then
			lib.state[key] = down
			if down then
				lib.callbacks:Fire(EVENT, 2, key, 1)
			else
				lib.callbacks:Fire(EVENT, 2, key, 0)
			end
		end
	end
end

-- The current state is taken as the baseline, so starting the poller never
-- fires for a key that was already held.
local function Start()
	local i
	for i = 1, 3 do
		lib.state[KEYS[i]] = ReadKey(KEYS[i])
	end
	lib.frame:SetScript("OnUpdate", Poll)
end

local function Stop()
	lib.frame:SetScript("OnUpdate", nil)
end

lib.callbacks.OnUsed = function(registry, target, event)
	if event == EVENT then
		Start()
	end
end

lib.callbacks.OnUnused = function(registry, target, event)
	if event == EVENT then
		Stop()
	end
end

function lib:IsDown(key)
	if not GETTERS[key] then return false end
	return ReadKey(key)
end

function lib:IsAnyDown()
	local i
	for i = 1, 3 do
		if ReadKey(KEYS[i]) then return true end
	end
	return false
end

-- A newer copy loaded over an older, already polling one takes the poller
-- over with its own Poll function. rawget: the registry's events table
-- creates an empty entry on a plain read.
local registered = rawget(lib.callbacks.events, EVENT)
if registered and next(registered) ~= nil then
	Start()
else
	Stop()
end
