-- LibRover-1.0 regions.  WoW 1.12.1 port of ZygorGuidesViewerClassic's Region.lua.
--
-- A region is a named area -- a circle around a node, or a zone/subzone name match -- that keeps
-- the path finder from beelining across something it should walk around.  Nodes in different
-- regions do not see each other as walkable.
--
-- Changes from the original: no LibBabble-SubZone (the zone names a region matches come from the
-- client, and are compared as the client reports them), zone names resolve through the library's
-- GetMapByNameFloor, and the "player can fly" early-out is gone because 1.12 has no flying.

LibRover_Region = {}

local Region = LibRover_Region

local Lib

local pairs, ipairs, type, tremove, setmetatable = pairs, ipairs, type, table.remove, setmetatable
local strfind, pcall = string.find, pcall

function Region:New(data)
	local region = data
	setmetatable(region, {__index = self})

	local self = region

	if self[1] == "REGION" then tremove(self, 1) end

	local m1, f1, x1, y1, id1 = LibRover_Node:Parse(self.center)   self.center = nil
	self.centernode = self.centernode
		or (x1 and LibRover_Node:New{c = Lib:GetMapContinent(m1), m = m1, f = f1, x = x1, y = y1,
			id = id1, type = "misc"})
		or Lib.nodes.id[self.centernodeid] or Lib.nodes.id[id1]

	if self.greenborders then
		for ni, n in ipairs(self.greenborders) do
			local f
			if type(n) == "table" then
				f = n[2]
				n = n[1]
			end
			local id = Lib:GetMapByNameFloor(n)
			if id then self.greenborders[id] = f or true end
		end
	end

	if self.zonematch then
		local _, _, zone, realzone, subzone, minizone =
			strfind(self.zonematch, "^(.-)/(.-)/(.-)/(.-)$")
		local function verify(z)
			if z == "*" then return nil end
			return z
		end
		if zone then
			self.zone = verify(zone)
			self.realzone = verify(realzone)
			self.subzone = verify(subzone)
			self.minizone = verify(minizone)
		end
	end

	local booleans = {"indoors", "nofly", "in_flight", "submerged"}
	for _, boo in ipairs(booleans) do
		if self[boo] ~= nil then self[boo] = (self[boo] == 1 or self[boo] == true) end
	end

	if type(self.mapzone) == "string" then self.mapzone = Lib:GetMapByNameFloor(self.mapzone) end

	return region
end

function Region:Contains(node, debug)
	if self.name == node.region then
		return true, debug and "already in"  -- that's a no-brainer
	elseif node.region then
		return false, debug and "already in diff region: " .. node.region  -- in different region
	else
		if not self.centernode and not self.zonematch then
			return false, debug and "no center nor zone"
		end
		if self.centernode then
			local centermatch = self.centernode.m == node.m
				and Lib.GetDist(self.centernode, node) < self.radius
			if not centermatch then return false, debug and "center mismatch" end
		end
		if self.zonematch then
			-- if any map name is specified, then it needs to match
			local zonematch = (not self.mapzone or node.m == self.mapzone)
				and (not self.zone or node.zone == self.zone)
				and (not self.realzone or node.realzone == self.realzone)
				and (not self.subzone or node.subzone == self.subzone)
				and (not self.minizone or node.minizone == self.minizone)
			if not zonematch then return false, debug and "zonematch mismatch" end
		end
		if self.indoors ~= nil and node.indoors ~= self.indoors then
			return false, debug and "indoors mismatch"
		end
		if self.submerged ~= nil and node.submerged ~= self.submerged then
			return false, debug and "submerged mismatch"
		end
		if self.cond_fun then
			local ok, result = pcall(self.cond_fun)
			if not ok or not result then return false, debug and "cond_fun fail" end
		end
		return true  -- passed both
	end
end

function Region:HasGreenBorder(mapid)
	return self.greenborders and self.greenborders[mapid]
end

function Region:tostring()
	return self.name
end

function Region:InterfaceWithLib(lib)
	Lib = lib
end
