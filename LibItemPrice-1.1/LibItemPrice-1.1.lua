--[[
Name: ItemPrice-1.1
Revision: 1
Author(s): Bam (original), Jerry (compression technique)
Maintainer: dh-harald
Description: Library with vendor sell prices for items.
Dependencies: LibStub
License: LGPL v2.1

Vanilla-only fork of the wowace ItemPrice-1.1 (rev 79224), whose versioning
died with the SVN. The revision restarts at 1 and is a plain number from here
on; every consumer takes this copy from the one repo, so nothing needs to win
a revision race against the SVN-era numbering any more.

Runs on Lua 5.0 (WoW 1.12.1) as well as 5.1 with no compatibility layer: item
ids come out of item links with string.find captures, because string.match
does not exist in 5.0, and nothing here uses the `#`, `%` or `...` syntax 5.0
cannot parse.

The price data does not live in this file. Any number of sources register
themselves through RegisterPackedPrices / RegisterPriceTable; a lookup walks
them newest-first, so a later source overrides an earlier one for the ids it
covers. Data-Vanilla.lua ships the 1.12.1 set; a server with custom items adds
its own file that registers on top of it under a different name, guarded by
whatever condition identifies that server.
]]

local MAJOR, MINOR = "ItemPrice-1.1", 1
local Lib = LibStub:NewLibrary(MAJOR, MINOR)
if not Lib then return end

local type, tonumber, pairs = type, tonumber, pairs
local find, byte = string.find, string.byte
local GetItemInfo = GetItemInfo

-- Kept across library upgrades: an already loaded extension source must not be
-- dropped when a newer copy of this file loads after it. Sources are replaced
-- by name, so a reloaded data file refreshes its own entry instead of piling up.
Lib.sources = Lib.sources or {}
Lib.sources.n = Lib.sources.n or 0

local function addSource(source)
	local list = Lib.sources
	if source.name then
		for i = 1, list.n do
			if list[i].name == source.name then
				list[i] = source
				return
			end
		end
	end
	list.n = list.n + 1
	list[list.n] = source
end

-- Packed source: dense 3-byte block, one triplet per id from `first` to `last`,
-- price stored as a big-endian 24-bit copper value. "\000\000\000" means the id
-- is unknown (nil), "zzz" means a real price of 0 -- an all-zero triplet cannot
-- express both. Vanilla's dearest item sells for 1632328, so no real price can
-- collide with the sentinel.
function Lib:RegisterPackedPrices(first, last, data, count, name)
	if type(first) ~= "number" or type(last) ~= "number" or type(data) ~= "string" then
		error("Usage: RegisterPackedPrices(first, last, data [, count [, name]])", 2)
	end
	addSource({ first = first, last = last, data = data, count = count or 0, name = name })
end

-- Sparse source: a plain [itemId] = copper table. Meant for the handful of
-- custom items a server adds, where a dense block would be mostly holes. A
-- value of 0 is honoured as "sells for nothing", same as the packed sentinel.
function Lib:RegisterPriceTable(map, count, name)
	if type(map) ~= "table" then
		error("Usage: RegisterPriceTable(map [, count [, name]])", 2)
	end
	if not count then
		count = 0
		for _ in pairs(map) do count = count + 1 end
	end
	addSource({ map = map, count = count, name = name })
end

local function get(id)
	if type(id) ~= "number" or id < 1 then return end
	local list = Lib.sources
	for i = list.n, 1, -1 do
		local source = list[i]
		local map = source.map
		if map then
			local price = map[id]
			if price then return price end
		elseif id >= source.first and id <= source.last then
			local index = (id - source.first + 1) * 3
			local data = source.data
			local a, b, c = byte(data, index - 2), byte(data, index - 1), byte(data, index)
			if a == 122 and b == 122 and c == 122 then return 0 end
			if a and (a ~= 0 or b ~= 0 or c ~= 0) then
				return a * 65536 + b * 256 + c
			end
		end
	end
end

-- Item id from an item link or item string ("item:1234:0:0:0"), or nil.
local function LinkItemId(link)
	local _, _, id = find(link, "item:(%d+)")
	return tonumber(id)
end

function Lib:GetPriceById(itemId)
	return get(itemId)
end

function Lib:GetPrice(item)
	local t = type(item)
	if t == "number" then return get(item) end
	if t == "string" then return get(tonumber(item) or LinkItemId(item)) end
end

function Lib:GetPriceCount()
	local list = Lib.sources
	local total = 0
	for i = 1, list.n do
		total = total + (list[i].count or 0)
	end
	return total
end

function Lib:GetSellValue(id)
	if type(id) ~= "number" and type(id) ~= "string" then return end

	if type(id) == "string" then
		if not find(id, "item:") then
			local _
			_, id = GetItemInfo(id)

			if not id then return end
		end

		id = LinkItemId(id)
	end

	return self:GetPriceById(id)
end
