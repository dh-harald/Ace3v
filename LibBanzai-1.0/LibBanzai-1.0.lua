--[[
	Name: LibBanzai-1.0
	Revision: $Rev: 1 $
	Ported from: Banzai-1.0 r14544
	Author(s): Rabbit (rabbit.magtheridon@gmail.com), maia, Ace3v port
	Description: Aggro notification library.
	Dependencies: LibStub, CallbackHandler-1.0, AceCore-3.0, AceTimer-3.0, LibRosterLib-2.0
	Note: Ace3v port of Banzai-1.0, API-compatible.
]]

-------------------------------------------------------------------------------
-- Locals
-------------------------------------------------------------------------------

local MAJOR, MINOR = "LibBanzai-1.0", 1

local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

local AceCore = LibStub("AceCore-3.0")
local new, del = AceCore.new, AceCore.del

LibStub("AceTimer-3.0"):Embed(lib)
lib.callbacks = lib.callbacks or LibStub("CallbackHandler-1.0"):New(lib)

local RL = LibStub("LibRosterLib-2.0")
local roster = RL.roster
local playerName = nil

local pairs, tinsert, max, min = pairs, table.insert, math.max, math.min

function lib:GetLibraryVersion()
	return MAJOR, MINOR
end

-------------------------------------------------------------------------------
-- Library
-------------------------------------------------------------------------------

function lib:UpdateAggroList()
	if not roster then return end
	-- Ace3v: read here, not once at load, where the name may not be known yet
	playerName = UnitName("player")
	local oldBanzai = new()

	for i, unit in pairs(roster) do
		oldBanzai[unit.unitid] = unit.banzai

		-- deduct aggro for all, increase it later for everyone with aggro
		if not unit.banzaiModifier then unit.banzaiModifier = 0 end
		unit.banzaiModifier = max(0, unit.banzaiModifier - 5)

		-- check for aggro
		-- Ace3v: the player's own target is read as "target". Unreal Azeroth
		-- has no "playertarget" unit, and in a raid the player's roster id
		-- would make it "raid4target".
		local targetId
		if unit.name == playerName then
			targetId = "target"
		else
			targetId = unit.unitid .. "target"
		end
		local targetName = UnitName(targetId .. "target")
		if roster[targetName] and UnitCanAttack("player", targetId) and UnitCanAttack(targetId, "player") then
			if not roster[targetName].banzaiModifier then roster[targetName].banzaiModifier = 0 end
			roster[targetName].banzaiModifier = roster[targetName].banzaiModifier + 10
			if not roster[targetName].banzaiTarget then roster[targetName].banzaiTarget = new() end
			tinsert(roster[targetName].banzaiTarget, targetId)
		end

		-- cleanup
		unit.banzaiModifier = max(0, unit.banzaiModifier)
		unit.banzaiModifier = min(25, unit.banzaiModifier)

		-- set aggro
		unit.banzai = (unit.banzaiModifier > 15)
	end

	for i, unit in pairs(roster) do
		if oldBanzai[unit.unitid] ~= nil and oldBanzai[unit.unitid] ~= unit.banzai then
			-- Aggro status has changed.
			if unit.banzai == true and unit.banzaiTarget then
				-- Unit has aggro
				self.callbacks:Fire("Banzai_UnitGainedAggro", unit.unitid, unit.banzaiTarget)
				if unit.name == playerName then
					self.callbacks:Fire("Banzai_PlayerGainedAggro", unit.banzaiTarget)
				end
			elseif unit.banzai == false then
				-- Unit lost aggro
				self.callbacks:Fire("Banzai_UnitLostAggro", unit.unitid)
				if unit.name == playerName then
					self.callbacks:Fire("Banzai_PlayerLostAggro", unit.unitid)
				end
			end
		end
		if unit.banzaiTarget then del(unit.banzaiTarget) end
		unit.banzaiTarget = nil
	end

	del(oldBanzai)
end

-------------------------------------------------------------------------------
-- API
-------------------------------------------------------------------------------

function lib:GetUnitAggroByUnitId( unitId )
	local rosterUnit = RL:GetUnitObjectFromUnit(unitId)
	if not rosterUnit then return nil end
	return rosterUnit.banzai
end

function lib:GetUnitAggroByUnitName( unitName )
	local rosterUnit = RL:GetUnitObjectFromName(unitName)
	if not rosterUnit then return nil end
	return rosterUnit.banzai
end

-------------------------------------------------------------------------------
-- Startup
-------------------------------------------------------------------------------

if lib.updateTimer then lib:CancelTimer(lib.updateTimer) end
lib.updateTimer = lib:ScheduleRepeatingTimer("UpdateAggroList", 0.2, 0)
