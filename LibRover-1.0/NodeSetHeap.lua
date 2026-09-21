-- LibRover-1.0 open-node heap.  WoW 1.12.1 port of ZygorGuidesViewerClassic's NodeSetHeap.lua.
--
-- A min-heap on node.cost, holding the A* open set.  Unchanged except for Lua 5.0 syntax and a
-- local wipe; `heap` and `indices` are file locals rather than parameters, exactly as in the
-- original, to keep the compare out of a function call.

LibRover_NodeSetHeap = {}

local NodeSet = LibRover_NodeSetHeap

local Lib

local heap    -- Store "self" here to avoid array func calls. Nasty, evil, bad.
local indices

local floor = math.floor
local pairs, setmetatable = pairs, setmetatable

local function wipe(t)
	for k in pairs(t) do t[k] = nil end
	table.setn(t, 0)
	return t
end

local function CompareNodes(i, j)
	return heap[i].cost > heap[j].cost
end

local function HeapSwimMinUp(num)
	local half = floor(num/2)
	local it = heap[num]
	while (num > 1 and CompareNodes(half, num)) do
		heap[half], heap[num] = heap[num], heap[half]
		indices[heap[num]] = num
		num = half
		half = floor(num/2)
	end
	indices[it] = num
end

local function SinkNodeDown()
	local k = 1 --first value in array
	local size = heap.count
	local it = heap[k]
	if not it then return end
	while ((k*2) <= size) do
		local j = k*2  -- J is always a left leaf since it is even.
		if (j < size and CompareNodes(j, j+1)) then j = j+1 end  -- compare left and right leafs
		if not CompareNodes(k, j) then break end  -- smaller than its children? done
		heap[k], heap[j] = heap[j], heap[k]  -- Swap!
		indices[heap[k]] = k
		k = j
	end
	indices[it] = k
end

function NodeSet:New()
	local new = {}
	setmetatable(new, {__index = self})
	new.indices = {}
	new.count = 0
	return new
end

function NodeSet:Add(node)
	if not node.cost then node.cost = -9999999 end

	self.count = self.count + 1
	self[self.count] = node

	heap = self
	indices = self.indices
	HeapSwimMinUp(self.count)
end

function NodeSet:RemoveCheapest(keep)
	-- find cheapest open node
	if Lib.force_next and self[Lib.force_next] then return Lib.force_next end -- bully.

	local ret = self[1]
	if keep or not ret then return ret end

	heap = self
	indices = self.indices

	indices[ret] = nil
	-- Put the last node at the top and sink it.  Written out rather than as the original's
	-- `heap[1],heap[self.count] = heap[self.count],nil`: when the heap holds one node those are
	-- the same slot, the order of a multiple assignment is unspecified, and leaving the node in
	-- place makes RemoveCheapest hand out the same closed node for ever -- which is exactly what
	-- happens on a route that does not exist.
	local last = self.count
	self[1] = self[last]
	self[last] = nil
	self.count = last - 1

	if self.count > 0 then SinkNodeDown() end

	return ret
end

function NodeSet:BubbleUp(node)
	local ind = self.indices[node]
	if not ind then
		Lib:Debug("HEAP CRASHED! No index in heap for node %s. Calculations might be crazy.",
			tostring(node.num))
		return
	end
	heap = self
	indices = self.indices
	HeapSwimMinUp(ind)
end

function NodeSet:Clear()
	wipe(self)
	self.indices = {}
	self.count = 0
end

function NodeSet:Length()
	return self.count
end

function NodeSet:InterfaceWithLib(lib)
	Lib = lib
end
