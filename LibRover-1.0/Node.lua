-- LibRover-1.0 nodes.  WoW 1.12.1 port of ZygorGuidesViewerClassic's Node.lua.
--
-- A node is a point on a map plus its links to other nodes.  Links are either *hardwired* (a
-- border crossing, a boat, a portal, a flight path, read from the data files) or *implicit*
-- (walking, worked out by DoLinkage).
--
-- Changes from the original: there is no flying in 1.12, so CanFlyTo always declines and every
-- implicit link is a walk; the baked neighbourhood cache is gone (links are computed at startup);
-- quest, reputation and condition checks go through the host interface; string methods and the
-- length operator are Lua 5.0 calls.

LibRover_Node = {}

local Node = LibRover_Node

local setmetatable, ipairs, pairs, next, type, assert, error, tonumber, unpack =
      setmetatable, ipairs, pairs, next, type, assert, error, tonumber, unpack
local tinsert, tremove, tgetn = table.insert, table.remove, table.getn
local strfind, strgsub, strformat = string.find, string.gsub, string.format
local mabs, matan2, mpi, mmod = math.abs, math.atan2, math.pi, math.mod

local Lib
local Lib_GetDist
local Lib_IsSegmentWalled
local Lib_greenborders

-- IMPORTANT OBSERVATION.
-- Nodes are (almost) ALWAYS separated by "walk"

local Node_meta = {__index = Node}
local Node_n_meta = {__mode = "k"}
function Node:New(data)
	local new = data or {}
	setmetatable(new, Node_meta)
	new.n = {}  -- prepare neighbours
	new.n_iftype = {}
	setmetatable(new.n, Node_n_meta)
	return new
end

local default_maxspeedinzone = {1, 1, 0}

function Node:AddNeigh(node, meta)
	-- tinsert, not `n[tgetn(n)+1] = ...`: in Lua 5.0 a raw assignment does not update the
	-- table's stored size, so the first table.remove on this list would freeze that size and
	-- every later link would overwrite the same slot.  Once the stored size reached 0 with
	-- entries still in the array, table.remove became a no-op and RemoveNeighType span for ever.
	tinsert(self.n, {node, meta})
	assert(node.type, "Node " .. (node.num or "<no num>") .. " has no type? wtf?")
	self.n_iftype[node.type] = 1
end

function Node:RemoveNeighType(type1, type2, type3)
	if not self.n_iftype[type1] and not self.n_iftype[type2] and not self.n_iftype[type3] then
		return
	end
	local neighs = self.n
	local i = 1
	local node = neighs[i]
	while node do
		local typ = node[1].type
		if (typ == type1 or typ == type2 or typ == type3) then tremove(neighs, i) else i = i + 1 end
		node = neighs[i]
	end
	self.n_iftype[type1] = nil
	if type2 then self.n_iftype[type2] = nil end
	if type3 then self.n_iftype[type3] = nil end
end

function Node:IterNeighs()
	local k = 0
	local n = self.n
	return function()
		k = k + 1
		local data = n[k]
		if data then return data[1], data[2] else return end
	end
end

function Node:GetNeigh(node, num)
	if type(node) == "number" then node = Lib.nodes.all[node] end
	local mynum = 0
	for n, meta in self:IterNeighs() do
		if n == node then
			mynum = mynum + 1
			if not num or mynum == num then return meta end
		end
	end
end

-- ONE WAY. Run twice to do two-way.
-- Checks if n1 sees n2, and - if yes - adds it to neighbours.
-- node.m = map id
-- node.ms[mapid] = "does node see nodes in mapid as visible" (crossable borders)
-- node.c = cont id
function Node:DoLinkage(n2, dryrun)
	local n1 = self

	if n1.type == "end" then return false, false, "src is end" end
	if n2.type == "start" or n2.type == "inn" then return false, false, "dest is start or inn" end

	-- NO pathfinding, only direct routes?
	if n1.type == "start" and n2.type == "end" and Lib.extradata and Lib.extradata.direct then
		if not dryrun then n1:AddNeigh(n2, {mode = "walk", cost = Lib.COST_FORCED}) end
		return true, true, "direct"
	end

	if n1.c ~= n2.c then return false, false, "different continents" end
	if n1.onlyhardwire then return false, false, "src is onlyhardwire" end
	if n2.onlyhardwire and not n1.player then return false, false, "dest is onlyhardwire" end
	if n2.onlyhardwire_to then return false, false, "dest is onlyhardwire_to" end
	if n1.border and n1.bordermeta and not n1.border.bordermeta and n1.border ~= n2 then
		return false, false, "src is one-way start, not to dest"
	end
	if n2.border and not n2.bordermeta and n2.border ~= n1 then
		return false, false, "dest is one-way end, not from src"
	end

	-- No flying in 1.12, so there is only one implicit mode: walking.
	local canwalk, reasonwalk, penalty = n1:CanWalkTo(n2, dryrun)
	if not canwalk then return false, false, reasonwalk end

	local meta = {mode = "walk", implicit = true, reason = reasonwalk, penalty = penalty}

	if not dryrun then n1:AddNeigh(n2, meta) end

	-- The "dark" nodes can still see start/end nodes, but through a "mud" penalty.
	-- This guarantees that starts/ends within some special low-visibility areas get connected to
	-- the closest explicit node only, with no excessive beelining.
	if n1.dark or n2.dark then
		if n1 == Lib.startnode then
			meta.mud = 10  -- let's be a little bit lenient on the starts
		elseif n2.type == "end" then
			meta.mud = 100  -- ends better be damn close.
		end
		-- This difference causes routes to have easy starts, but precise endings.
	end

	return canwalk, false, reasonwalk, nil, meta.mode
end

function Node:GetActionTitle(prevnode, nextnode)
	local atitle = self.actiontitle
	if type(atitle) == "function" then atitle = atitle(self, prevnode, nextnode) end
	if atitle then return Lib.L[atitle] end
end

function Node:GetActionIcon(prevnode, nextnode)
	local icon = self.actionicon
	if type(icon) == "function" then icon = icon(self, prevnode, nextnode) end
	return icon
end

function Node:GetTextAsItinerary()
	-- DISPLAY WAYPOINT TEXT AT FINAL NODE when it's goal-bound.
	if self.waypoint and self.waypoint.goal then return self.waypoint:GetTitle() end
	return self.text  -- baked itinerary form
		or self:GetText()
end

-- Run as node:GetText().
-- Additional params allow for contextualization - give a node its predecessor and successor, and
-- get proper "ship from..." display.
function Node:GetText(prevnode, nextnode, dir)
	local MapName = Lib.MapName
	if prevnode and prevnode.node then prevnode = prevnode.node end
	if nextnode and nextnode.node then nextnode = nextnode.node end

	local function FromTo(strfrom, strto)
		if prevnode and prevnode == self.border then return strfrom else return strto end
	end

	local title = self.title
	if type(title) == "function" then title = title(self, prevnode, nextnode) end
	if title then return Lib.L[title] end

	local function destport()
		local b = self.border
		if b and b ~= "multi" then
			return (b.port and strformat("%s, %s", b.port, MapName(b))) or b.name or MapName(b)
		end
	end

	if Lib.debug_verbose_nodes then
		return strformat("[%d] %s %d %d,%d (%s)", self.num, MapName(self.m), self.m,
			self.x*100, self.y*100, self.type)

	elseif self.type == "border" and (self.border or self.ms) then
		return strformat("%s/%s border", MapName(self),
			MapName(self.border or (self.ms and next(self.ms))))
	elseif self.type == "taxi" then
		return strformat("%s flight point", self.localname or self.name or "?")
	elseif self.type == "ship" then
		return strformat(FromTo("Ship from %s", "Ship to %s"), destport() or "?")
	elseif self.type == "zeppelin" then
		return strformat(FromTo("Zeppelin from %s", "Zeppelin to %s"), destport() or "?")
	elseif self.type == "tram" then
		return strformat(FromTo("Tram from %s", "Tram to %s"), destport() or "?")
	elseif self.type == "portal" then
		if self.border and self.border ~= "multi" and self.m == self.border.m then
			return "Portal"
		elseif self.border and self.border ~= "multi" then
			return strformat(FromTo("Portal from %s", "Portal to %s"), destport() or "?")
		elseif prevnode then
			local destportname = prevnode.port or prevnode.name or MapName(prevnode)
			return strformat(FromTo("Portal from %s", "Portal to %s"), destportname)
		else
			return "Portal destination"
		end
	elseif self.type == "inn" then
		return self.name or "Unknown Inn"
	else
		return strformat("%s %d,%d", MapName(self), (self.x or 0)*100, (self.y or 0)*100)
	end
end

local modecolors = {
	walk = "|cffaaaaaa",
	taxi = "|cffaaccaa",
	portal = "|cffccaacc",
	ship = "|cffaabbcc",
	["?"] = "|cff888888",
}

-- Three-way: true known, false known-to-be-unknown, nil not established.
-- The second return is a description, the third says whether the node is at least discoverable.
function Node:IsTaxiKnown()
	if self.known_fun then
		self.known = not not self.known_fun()
		return self.known, (self.known and "known (func)" or "unavailable (func)"), self.known
	end

	    if self.known == true then return true, "known", true
	elseif (self.quest and not Lib:HostQuestComplete(self.quest)) then
		return false, "unavailable (quest incomp)", false
	elseif (self.factionid and Lib:HostReputation(self.factionid) < (self.factionstanding or 3)) then
		return false, "unavailable (faction rep)", false
	elseif (self.cond_fun and not self.cond_fun()) then return false, "unavailable (cond fail)", false
	elseif (self.unlocked_fun and not self.unlocked_fun()) then
		return false, "unavailable (unlock fail)", false
	elseif (self.level and Lib:HostPlayerLevel() < self.level) then
		return false, "unavailable (high lvl)", false
	elseif self.known == false then return false, "unknown", true  -- discoverable
	else   return nil, "maybe?", true
	end
end

function Node:tostring(withneighs)
	local stype = self.type or "type?"
	if self.type == "taxi" and self.taxioperator then stype = stype .. "-" .. self.taxioperator end
	local ret = strformat("[%d] %s\"%s\" = %s/%d (%d) %.1f,%.1f [%s]",
		self.num or -1, (self.id and "@" .. self.id .. " " or ""),
		self:GetText() or ("\"#" .. (self.num or -1) .. "\""),
		Lib.MapName(self.m), self.f or 0, self.m or 0,
		(self.x or 0)*100, (self.y or 0)*100, stype)
	if self.region then ret = ret .. strformat(" (REG:%s)", self.region) end
	if self.type == "taxi" then
		local _, desc = self:IsTaxiKnown()
		ret = ret .. strformat(" (taxi %s)", desc)
	end
	if self.is_arrival then ret = ret .. " (arrival)" end
	ret = ret .. strformat(" (state:%s)", self.status or "untouched")
	if self.parentlink then
		ret = ret .. strformat(" (mode:%s from [%s])", self.parentlink.mode,
			self.parent and (self.parent.type == "start" and "start" or self.parent.num) or "?")
	end
	if self.mytime then ret = ret .. strformat(" [my t=%.1f/%.1f]", self.mytime or -1, self.mycost or -1) end
	if self.time then ret = ret .. strformat(" (tot t=%.1f/%.1f)", self.time or -1, self.cost or -1) end
	if self.costdesc and self.costdesc ~= "" then ret = ret .. " WHY: " .. self.costdesc end

	if withneighs then
		local neighs = ""
		for n, link in self:IterNeighs() do
			local mode_colored = (modecolors[link.mode or "?"] or modecolors["?"])
				.. (link.mode or "?") .. "|r"
			neighs = neighs .. "<" .. mode_colored .. "> " .. n:tostring() .. "\n"
		end
		ret = ret .. "\nLinks:\n" .. neighs
	end
	return ret
end

-- Degrees, 0 = north, growing clockwise -- as the original's WoW-global atan2 produced.
function Node:GetAngleTo(node2)
	local dist, xd, yd = Lib_GetDist(self, node2)
	if not xd then return end
	local dir = matan2(xd, -yd) * 180 / mpi
	return mmod(dir + 360, 360)
end

-- Checks if player can walk towards the destination. If this returns true, DoLinkage will create
-- a "walk"-type connection.
local TELDRASSIL
function Node:CanWalkTo(dest, debug)
	local n1 = self
	local n2 = dest

	if n1 == n2 then return false, "same node" end

	local n1_m = n1.m
	local n2_m = n2.m

	local walled, _, _, penalty = Lib_IsSegmentWalled(n1, n2)
	if walled and not penalty then return false, "wall" end

	if n1.type == "taxi" and n2.type == "taxi" and Lib.taxislinked[n1.num .. "-" .. n2.num] then
		return false, "no walking between taxis"
	end

	-- don't connect in dark; startnode and endnode ARE allowed to connect, though - we'll just
	-- run a "mud" penalty for beelines later.
	if (n1.type ~= "start" and n1.type ~= "end" and n2.type ~= "start" and n2.type ~= "end"
	and (n1.dark or n2.dark)) then
		return false, debug and "nodes in dark zone"
	end

	-- Teldrassil: the Rut'theran shore and the top of the tree are not walkable to each other.
	if not TELDRASSIL then TELDRASSIL = Lib:GetMapByNameFloor("Teldrassil") or -1 end
	if n2_m == TELDRASSIL and n1_m == TELDRASSIL and (n1.y - 0.8)*(n2.y - 0.8) < 0 then
		return false, debug and "rut'theran hack"
	end

	if Lib.greenborders:CanCross(n1_m, n2_m) then
		return true, debug and ("greenborder " .. n1_m .. " -> " .. n2_m), penalty
	end
	-- or any of the nodes is in a green-bordered region; these are parts of zones that somehow
	-- logically belong to another zone, NOT their true zone.
	if n1.regionobj and n1.regionobj:HasGreenBorder(n2_m) then
		return true, debug and ("region greenborder " .. n1.region), penalty
	end
	if n2.regionobj and n2.regionobj:HasGreenBorder(n1_m) then
		return true, debug and ("region greenborder " .. n2.region), penalty
	end

	if n1.region and n1.region == n2.region then return true, "same region", penalty end
	if n1.region ~= n2.region then return false, "diff region" end

	if (n1_m == n2_m) or (n2.ms and n2.ms[n1_m]) then return true, "same map or ms", penalty
	else return false, "no walkie"
	end
end

-- 1.12 has no flying mounts at all: the only way off the ground is a flight path, which is a
-- hardwired taxi link.  Kept so that data and callers asking for it get a straight answer.
function Node:CanFlyTo(dest, debug)
	return false, debug and "no flying in 1.12"
end

function Node:CanConnectTo(dest)
	if type(dest) == "number" then dest = Lib.nodes.all[dest] end
	for neigh, neighmeta in self:IterNeighs() do
		if neigh == dest then return neighmeta end
	end
end

function Node:AssignRegion(regionobj)
	-- handle {indoors}
	if type(self.indoors) == "string" and self.type ~= "start" then
		regionobj = Lib.NodeRegions:AddNewRegion{name = self.indoors, mapzone = self.m,
			zonematch = "*/*/*/" .. self.indoors, indoors = 1, nofly = 1}
		self.indoors = not not self.indoors
	end

	if not regionobj then
		Lib.NodeRegions:Assign(self)
	else
		self.region = regionobj.name
		self.regionobj = regionobj
		self.dark = self.dark or regionobj.dark
		self.nofly = self.nofly or regionobj.nofly
		self.minizone = self.minizone or regionobj.minizone
		if regionobj.indoors then self.indoors = true end
	end
end

function Node:AssignSpecialMap()
	Lib.SpecialMapNodeData:Assign(self)
end

-- Parse a node out of its data form: "Zone/0 12.34,56.78 <attr:value> @id", or a table whose
-- first element is that string and whose other keys are node attributes.
function Node:Parse(text)
	if not text then return end
	local dat
	if type(text) == "table" then
		dat = text
		text = text[1]
		dat[1] = nil
	else
		dat = {}
	end
	if type(text) ~= "string" then return end

	-- <field:value> attributes
	local function grab_dat(s)
		s = strgsub(s, "%%GT%%", ">")
		local _, _, k, v = strfind(s, "(.-):(.+)")
		if k then dat[k] = v end
		return ""
	end
	text = strgsub(text, "%s*<(.-)>", grab_dat)

	-- now extract map and coords.
	local _, _, trimmed = strfind(text, "^%s*(.-)%s*$")
	text = trimmed or text
	local _, _, rest, id = strfind(text, "^(.-)%s*@(%S+)$")  -- "Map/1 12,34 @id"
	if id and rest == "" then  -- just id!
		if string.sub(id, 1, 1) == "!" then
			-- COPY the old node! Wasteful, but special spell/item nodes can't handle multiple
			-- arrivals yet.
			id = string.sub(id, 2)
			local node = Lib.nodes.id[id]
			if node then return node.m, node.f, node.x, node.y, id, dat end
		end
		return nil, nil, nil, nil, id
	end
	if rest and rest ~= "" then text = rest end

	local _, _, m, x, y = strfind(text, "^(.-)[%s,]+(%-?[0-9%.]+),(%-?[0-9%.]+)$")
	local f
	if m then
		local _, _, mm, ff = strfind(m, "^(.-)%s*/%s*(%d+)$")
		if ff then m, f = mm, ff end
	end
	m = m or text

	if type(m) == "string" then m, f = Lib:GetMapByNameFloor(m, f) end

	assert(m, "Bad map/floor in Node:Parse(\"" .. tostring(text) .. "\")")

	return m, tonumber(f) or 0, x and tonumber(x)/100, y and tonumber(y)/100, id, dat
end

function Node:CacheMaxSpeeds()
	-- kept for call compatibility; the port reads Lib.maxspeedinzone directly
end

function Node:InterfaceWithLib(lib)
	Lib = lib
	Lib_GetDist = Lib.GetDist
	Lib_IsSegmentWalled = Lib.IsSegmentWalled
	Lib_greenborders = Lib.greenborders
end
