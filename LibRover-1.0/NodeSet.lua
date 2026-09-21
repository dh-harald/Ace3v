-- LibRover-1.0 plain node set.  WoW 1.12.1 port of ZygorGuidesViewerClassic's NodeSet.lua.
--
-- The linear-search open set the heap replaced.  Kept because the original ships it and it is a
-- drop-in alternative to LibRover_NodeSetHeap; nothing in the library uses it.

LibRover_NodeSet = {}

local NodeSet = LibRover_NodeSet

local Lib

local length = 0

local pairs, next, setmetatable = pairs, next, setmetatable

local function wipe(t)
	for k in pairs(t) do t[k] = nil end
	table.setn(t, 0)
	return t
end

function NodeSet:New()
	local new = {}
	setmetatable(new, {__index = self})
	return new
end

function NodeSet:Add(node)
	if not self[node] then length = length + 1 end
	self[node] = 1
end

function NodeSet:Remove(node)
	if self[node] then length = length - 1 end
	self[node] = nil
end

function NodeSet:Clear()
	wipe(self)
	length = 0
end

function NodeSet:GetCheapest()
	-- find cheapest open node
	if Lib.force_next and self[Lib.force_next] then return Lib.force_next end -- bully.

	local cheapest = next(self)
	if not cheapest then return nil end
	local minscore = cheapest.score or 999999999
	for node in pairs(self) do
		if node.score < minscore then minscore = node.score cheapest = node end
	end

	return cheapest
end

function NodeSet:Length()
	return length
end

function NodeSet:InterfaceWithLib(lib)
	Lib = lib
end
