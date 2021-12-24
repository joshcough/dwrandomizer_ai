require 'Class'
require 'controller'
require 'helpers'
require 'locations'

Charlock           = 2
Hauksness          = 3
Tantegel           = 4
TantegelThroneRoom = 5
CharlockThroneRoom = 6
Kol                = 7
Brecconary         = 8
Garinham           = 9
Cantlin            = 10
Rimuldar           = 11
TantegelBasement   = 12
NorthernShrine     = 13
SouthernShrine     = 14
CharlockCaveLv1    = 15
CharlockCaveLv2    = 16
CharlockCaveLv3    = 17
CharlockCaveLv4    = 18
CharlockCaveLv5    = 19
CharlockCaveLv6    = 20
SwampCave          = 21
MountainCaveLv1    = 22
MountainCaveLv2    = 23
GarinsGraveLv1     = 24
GarinsGraveLv2     = 25
GarinsGraveLv3     = 26
GarinsGraveLv4     = 27
ErdricksCaveLv1    = 28
ErdricksCaveLv2    = 29

TantegelEntrance       = Point(Tantegel, 11, 29)
TantegelBasementStairs = Point(Tantegel, 29, 29)
SwampNorthEntrance     = Point(SwampCave, 0, 0)
SwampSouthEntrance     = Point(SwampCave, 0, 29)

Warp = class(function(a, src, dest)
  a.src = src
  a.dest = dest
end)

function Warp:swap()
  return Warp(self.dest, self.src)
end

function Warp:__tostring()
  return "{Warp src: " .. tostring(self.src) .. ", dest: " .. tostring(self.dest) .. "}"
end

function Warp:equals(w)
  return (self.src:equals(w.src) and self.dest:equals(w.dest)) or
         (self.src:equals(w.dest) and self.dest:equals(w.src))
end

WARPS = {
   Warp(Point(Charlock, 10, 1),          Point(CharlockCaveLv1, 9, 0))
 , Warp(Point(Charlock, 4, 14),          Point(CharlockCaveLv1, 8, 13))
 , Warp(Point(Charlock, 15, 14),         Point(CharlockCaveLv1, 17, 15))
 , Warp(Point(TantegelThroneRoom, 1, 8), Point(Tantegel, 1, 7))
 , Warp(Point(TantegelThroneRoom, 8, 8), Point(Tantegel, 7, 7))
 -- 9 = garinham, 24 = GarinsGrave -- this one has to be discovered, like the basement
 -- , Warp(Point(9, 19, 0), Point(24, 6, 11))
 , Warp(Point(CharlockCaveLv1, 15,  1),  Point(CharlockCaveLv2,  8,  0))
 , Warp(Point(CharlockCaveLv1, 13,  7),  Point(CharlockCaveLv2,  4,  4))
 , Warp(Point(CharlockCaveLv1, 19,  7),  Point(CharlockCaveLv2,  9,  8))
 , Warp(Point(CharlockCaveLv1, 14,  9),  Point(CharlockCaveLv2,  8,  9))
 , Warp(Point(CharlockCaveLv1,  2, 14),  Point(CharlockCaveLv2,  0,  1))
 , Warp(Point(CharlockCaveLv1,  2,  4),  Point(CharlockCaveLv2,  0,  0))
 , Warp(Point(CharlockCaveLv1,  8, 19),  Point(CharlockCaveLv2,  5,  0))
 , Warp(Point(CharlockCaveLv2,  3,  0),  Point(CharlockCaveLv3,  7,  0))
 , Warp(Point(CharlockCaveLv2,  9,  1),  Point(CharlockCaveLv3,  2,  2))
 , Warp(Point(CharlockCaveLv2,  0,  8),  Point(CharlockCaveLv3,  5,  4))
 , Warp(Point(CharlockCaveLv2,  1,  9),  Point(CharlockCaveLv3,  0,  9))
 , Warp(Point(CharlockCaveLv3,  1,  6),  Point(CharlockCaveLv4,  0,  9))
 , Warp(Point(CharlockCaveLv3,  7,  7),  Point(CharlockCaveLv4,  7,  7))
 , Warp(Point(CharlockCaveLv4,  2,  2),  Point(CharlockCaveLv5,  9,  0))
 , Warp(Point(CharlockCaveLv4,  8,  1),  Point(CharlockCaveLv5,  4,  0))
 , Warp(Point(CharlockCaveLv5,  5,  5),  Point(CharlockCaveLv6,  0,  0))
 , Warp(Point(CharlockCaveLv5,  0,  0),  Point(CharlockCaveLv6,  0,  6))
 , Warp(Point(CharlockCaveLv6,  9,  0),  Point(CharlockCaveLv6,  0,  0))
 , Warp(Point(CharlockCaveLv6,  9,  6),  Point(CharlockThroneRoom, 10, 29))
 , Warp(Point(MountainCaveLv1,  0,  0),  Point(MountainCaveLv2,  0,  0))
 , Warp(Point(MountainCaveLv1,  6,  5),  Point(MountainCaveLv2,  6,  5))
 , Warp(Point(MountainCaveLv1, 12, 12),  Point(MountainCaveLv2, 12, 12))
 , Warp(Point(GarinsGraveLv1,   1, 18),  Point(GarinsGraveLv2,  11,  2))
 , Warp(Point(GarinsGraveLv2,   1,  1),  Point(GarinsGraveLv3,   1, 16))
 , Warp(Point(GarinsGraveLv2,  12,  1),  Point(GarinsGraveLv3,  18,  1))
 , Warp(Point(GarinsGraveLv2,   5,  6),  Point(GarinsGraveLv3,   6, 11))
 , Warp(Point(GarinsGraveLv2,   1, 10),  Point(GarinsGraveLv3,   2, 17))
 , Warp(Point(GarinsGraveLv2,  12, 10),  Point(GarinsGraveLv3,  18, 13))
 , Warp(Point(GarinsGraveLv3,   9,  5),  Point(GarinsGraveLv4,   0,  4))
 , Warp(Point(GarinsGraveLv3,  10,  9),  Point(GarinsGraveLv4,   5,  4))
 , Warp(Point(ErdricksCaveLv1,  9,  9),  Point(ErdricksCaveLv2,  8,  9))
}

-- TODO: omg this needs to return a Table3D and not a [[]]
function getWarpsForMap(mapId, allWarps)
  local res = {}
  local warpsForMapId = list.filter(allWarps, function(w)
    return w.src.mapId == mapId
  end)
  for _,w in ipairs(warpsForMapId) do
    if res[w.src.x] == nil then res[w.src.x] = {} end
    if res[w.src.x][w.src.y] == nil then res[w.src.x][w.src.y] = {} end
    table.insert(res[w.src.x][w.src.y], w.dest)
  end
  return res
end

MapSize = class(function(a,width,height)
  a.width = width
  a.height = height
end)

function MapSize:__tostring()
  return "MapSize(height: " .. self.height .. ", width: " .. self.width .. ")"
end

-- 'to' is the source, and `warpRomAddr` contains the address to read the `from`
-- also seen Entrance right below.
EntranceMetaData = class(function(a, to, warpRomAddr, entranceType)
  a.to = to
  a.warpRomAddr = warpRomAddr
  a.entranceType = entranceType
end)

function EntranceMetaData:__tostring()
  return "<EntranceMetaData to:" .. tostring(self.to) .. ", warpRomAddr:" .. tostring(self.warpRomAddr) .. ">"
end

-- TODO: at this point... is an Entrance any different from a Warp?
-- could we get rid of Entrance and just use Warp?
-- NOTE: 'from' is the "overworld"
-- (""s because the entrance could be to a basement and so from might actually be tantegel or garinham)
Entrance = class(function(a, from, to, entranceType)
  a.to = to
  a.from = from
  a.entranceType = entranceType
end)

function Entrance:__tostring()
  return "<Entrance from:" .. tostring(self.from) ..
                 ", to:" .. tostring(self.to) ..
                 ", entranceType:" .. tostring(self.entranceType) .. ">"
end

function Entrance:equals(e)
  return self.from:equals(e.from) and self.to:equals(e.to)
end

function EntranceMetaData:convertToEntrance(memory)
  local from = Point(memory:readROM(self.warpRomAddr), memory:readROM(self.warpRomAddr+1), memory:readROM(self.warpRomAddr+2))
  local res = Entrance(from, self.to, self.entranceType)
  return res
end

StaticMapMetadata = class(function(a, mapId, name, mapType, size, mapLayoutRomAddr, entrances)
  a.mapId = mapId
  a.name = name
  a.mapType = mapType
  a.size = size
  a.mapLayoutRomAddr = mapLayoutRomAddr
  -- this is a list because swamp cave has two entrances
  -- nil means it doesn't have an overworld location (or a warp location to tantegel or garinham anyway)
  a.entrances = entrances
end)

function StaticMapMetadata:__tostring()
  return "StaticMapMetadata(name: " .. self.name ..
                         ", size: " .. tostring(self.size) ..
                         ", mapId: " .. self.mapId ..
                         ", mapLayoutRomAddr: " .. self.mapLayoutRomAddr ..
                         ", entrances: " .. tostring(self.entrances) .. ")"
end

MapType = enum.new("Map Type", { "TOWN", "DUNGEON", "BOTH", "OTHER" })

STATIC_MAP_METADATA = {
  [2]  = StaticMapMetadata(2,  "Charlock",             MapType.BOTH,    MapSize(20, 20), 0xC0,   {EntranceMetaData(Point( 2, 10, 19), 0xF3EA, GoalType.CHARLOCK)}),
  [3]  = StaticMapMetadata(3,  "Hauksness",            MapType.BOTH,    MapSize(20, 20), 0x188,  {EntranceMetaData(Point( 3,  0, 10), 0xF3F6, GoalType.TOWN)}),
  [4]  = StaticMapMetadata(4,  "Tantegel",             MapType.TOWN,    MapSize(30, 30), 0x250,  {EntranceMetaData(Point( 4, 11, 29), 0xF3E4, GoalType.TANTEGEL)}),
  [5]  = StaticMapMetadata(5,  "Tantegel Throne Room", MapType.OTHER,   MapSize(10, 10), 0x412),
  [6]  = StaticMapMetadata(6,  "Charlock Throne Room", MapType.DUNGEON, MapSize(30, 30), 0x444),
  [7]  = StaticMapMetadata(7,  "Kol",                  MapType.TOWN,    MapSize(24, 24), 0x606,  {EntranceMetaData(Point(  7, 19, 23), 0xF3DE, GoalType.TOWN)}),
  [8]  = StaticMapMetadata(8,  "Brecconary",           MapType.TOWN,    MapSize(30, 30), 0x726,  {EntranceMetaData(Point(  8,  0, 15), 0xF3E1, GoalType.TOWN)}),
  [9]  = StaticMapMetadata(9,  "Garinham",             MapType.TOWN,    MapSize(20, 20), 0xAAA,  {EntranceMetaData(Point(  9,  0, 14), 0xF3D8, GoalType.TOWN)}),
  [10] = StaticMapMetadata(10, "Cantlin",              MapType.TOWN,    MapSize(30, 30), 0x8E8,  {EntranceMetaData(Point( 10,  5, 15), 0xF3F9, GoalType.TOWN)}),
  [11] = StaticMapMetadata(11, "Rimuldar",             MapType.TOWN,    MapSize(30, 30), 0xB72,  {EntranceMetaData(Point( 11, 29, 14), 0xF3F3, GoalType.TOWN)}),
  [12] = StaticMapMetadata(12, "Tantegel Basement",    MapType.OTHER,   MapSize(10, 10), 0xD34,  {EntranceMetaData(Point( 12,  0,  4), 0xF40B, GoalType.CAVE)}),
  [13] = StaticMapMetadata(13, "Northern Shrine",      MapType.OTHER,   MapSize(10, 10), 0xD66,  {EntranceMetaData(Point( 13,  4,  9), 0xF3DB, GoalType.CAVE)}),
  [14] = StaticMapMetadata(14, "Southern Shrine",      MapType.OTHER,   MapSize(10, 10), 0xD98,  {EntranceMetaData(Point( 14,  0,  4), 0xF3FC, GoalType.CAVE)}),
  [15] = StaticMapMetadata(15, "Charlock Cave Lv 1",   MapType.DUNGEON, MapSize(20, 20), 0xDCA),
  [16] = StaticMapMetadata(16, "Charlock Cave Lv 2",   MapType.DUNGEON, MapSize(10, 10), 0xE92),
  [17] = StaticMapMetadata(17, "Charlock Cave Lv 3",   MapType.DUNGEON, MapSize(10, 10), 0xEC4),
  [18] = StaticMapMetadata(18, "Charlock Cave Lv 4",   MapType.DUNGEON, MapSize(10, 10), 0xEF6),
  [19] = StaticMapMetadata(19, "Charlock Cave Lv 5",   MapType.DUNGEON, MapSize(10, 10), 0xF28),
  [20] = StaticMapMetadata(20, "Charlock Cave Lv 6",   MapType.DUNGEON, MapSize(10, 10), 0xF5A),
  [21] = StaticMapMetadata(21, "Swamp Cave",           MapType.DUNGEON, MapSize( 6, 30), 0xF8C,  {EntranceMetaData(Point( 21,  0,  0), 0xF3E7, GoalType.CAVE), EntranceMetaData(Point(21, 0, 29), 0xF3ED, GoalType.CAVE)}),
  [22] = StaticMapMetadata(22, "Mountain Cave",        MapType.DUNGEON, MapSize(14, 14), 0xFE6,  {EntranceMetaData(Point( 22,  0,  7), 0xF3F0, GoalType.CAVE)}),
  [23] = StaticMapMetadata(23, "Mountain Cave Lv 2",   MapType.DUNGEON, MapSize(14, 14), 0x1048),
  [24] = StaticMapMetadata(24, "Garin's Grave Lv 1",   MapType.DUNGEON, MapSize(20, 20), 0x10AA, {EntranceMetaData(Point( 24,  6, 11), 0xF411, GoalType.CAVE)}),
  [25] = StaticMapMetadata(25, "Garin's Grave Lv 2",   MapType.DUNGEON, MapSize(14, 12), 0x126C),
  [26] = StaticMapMetadata(26, "Garin's Grave Lv 3",   MapType.DUNGEON, MapSize(20, 20), 0x1172),
  [27] = StaticMapMetadata(27, "Garin's Grave Lv 4",   MapType.DUNGEON, MapSize(10, 10), 0x123A),
  [28] = StaticMapMetadata(28, "Erdrick's Cave",       MapType.DUNGEON, MapSize(10, 10), 0x12C0, {EntranceMetaData(Point( 28,  0,  0), 0xF3FF, GoalType.CAVE)}),
  [29] = StaticMapMetadata(29, "Erdrick's Cave Lv 2",  MapType.DUNGEON, MapSize(10, 10), 0x12F2),
}

function StaticMapMetadata:readEntranceCoordinates(memory)
  if self.entrances == nil then return nil end
  local res = list.map(self.entrances, function(e) return e:convertToEntrance(memory) end)
  return res
end

-- ok the idea is this:
-- we return a table 2-29 that has all the entrances in the values
-- then from LeaveOnFoot or whatever, we simply Goto(entrances)
function getAllEntranceCoordinates(memory)
  local res = {}
  for i, meta in pairs(STATIC_MAP_METADATA) do
    res[i] = meta:readEntranceCoordinates(memory)
  end
  return res
end

mockEntranceCoordinates = {
   [2]= {Entrance(Point( 2, 19, 10), Point(1, 54,  87), GoalType.CHARLOCK)},
   [3]= {Entrance(Point( 3, 10,  0), Point(1, 29, 112), GoalType.TOWN)},
   [4]= {Entrance(Point( 4, 29, 11), Point(1, 85,  90), GoalType.TANTEGEL)},
   [7]= {Entrance(Point( 7, 23, 19), Point(1, 55,  67), GoalType.TOWN)},
   [8]= {Entrance(Point( 8, 15,  0), Point(1, 98,  98), GoalType.TOWN)},
   [9]= {Entrance(Point( 9, 14,  0), Point(1, 74, 108), GoalType.TOWN)},
   [10]={Entrance(Point(10, 15,  5), Point(1, 36,  44), GoalType.TOWN)},
   [11]={Entrance(Point(11, 14, 29), Point(1, 74, 110), GoalType.TOWN)},
   [12]={Entrance(Point(12,  4,  0), Point(4, 29,  29), GoalType.CAVE)},
   [13]={Entrance(Point(13,  9,  4), Point(1, 58, 106), GoalType.CAVE)},
   [14]={Entrance(Point(14,  4,  0), Point(1, 82,   8), GoalType.CAVE)},
   [21]={Entrance(Point(21,  0,  0), Point(1, 90,  78), GoalType.CAVE), Entrance(Point(21, 29, 0), Point(1, 93, 63), GoalType.CAVE)},
   [22]={Entrance(Point(22,  7,  0), Point(1, 96,  99), GoalType.CAVE)},
   [24]={Entrance(Point(24, 11,  6), Point(9, 19,   0), GoalType.CAVE)},
   [28]={Entrance(Point(28,  0,  0), Point(1, 86,  84), GoalType.CAVE)}
  }

-- ok i hate walkableWithKeys and i want it to die horribly.
-- i think we can accomplish that in this PR 12/21/21
StaticMapTile = class(function(a,tileId,name,walkable,walkableWithKeys)
  a.id = tileId
  a.tileId = tileId
  a.name = name
  a.walkable = walkable
  a.walkableWithKeys = walkableWithKeys and true or false
  -- i think 1 here is ok. if its not walkable it wont end up in the graph at all
  -- the only small problem is charlock has some swamp and desert, but... they aren't really
  -- avoidable anyway, and so... it should just be fine to always use 1.
  a.weight = 1
end)

function StaticMapTile:__tostring()
  local w = self.walkable and "true" or "false"
  -- ok this is weird and might expose a hole in the whole program.
  -- but then again maybe not
  local wwk = self.walkableWithKeys and "true" or "true"
  return "<StaticMapTile tileId: " .. self.tileId .. ", name: " .. self.name ..
         ", walkable: " .. w .. ", walkableWithKeys: " .. wwk .. ">"
end

function StaticMapTile:isDoor() return self.name == "Door" end

NON_DUNGEON_TILES = {
  [0]   = StaticMapTile(0,  "Grass" , true),
  [1]   = StaticMapTile(1,  "Sand"  , true),
  [2]   = StaticMapTile(2,  "Water" , false),
  [3]   = StaticMapTile(3,  "Chest" , true),
  [4]   = StaticMapTile(4,  "Stone" , false),
  [5]   = StaticMapTile(5,  "Up"    , true),
  [6]   = StaticMapTile(6,  "Brick" , true),
  [7]   = StaticMapTile(7,  "Down"  , true),
  [8]   = StaticMapTile(8,  "Trees" , true),
  [9]   = StaticMapTile(9,  "Swamp" , true),
  [0xA] = StaticMapTile(10, "Field" , true),
  [0xB] = StaticMapTile(11, "Door"  , false, true), -- walkableWithKeys
  [0xC] = StaticMapTile(12, "Weapon", false),
  [0xD] = StaticMapTile(13, "Inn"   , false),
  [0xE] = StaticMapTile(14, "Bridge", true),
  [0xF] = StaticMapTile(15, "Tile"  , false),
}

DUNGEON_TILES = {
  [0]   = StaticMapTile(0, "Stone", false),
  [1]   = StaticMapTile(1, "Up"   , true),
  [2]   = StaticMapTile(2, "Brick", true),
  [3]   = StaticMapTile(3, "Down" , true),
  [4]   = StaticMapTile(4, "Chest", true),
  [5]   = StaticMapTile(5, "Door" , false, true), -- walkableWithKeys
  -- in swamp cave, we get id six where the princess is. its the only 6 we get in any dungeon.
  [6]   = StaticMapTile(6, "Brick", true),
}

IMMOBILE_NPCS = {
  [Charlock]           = {},
  [Hauksness]          = {},
  [Tantegel]           = {{2,8}, {8,6}, {8,8}, {27,5}, {26,15}, {9,27}, {12,27}, {15, 20}},
  [TantegelThroneRoom] = {{3,6}, {5,6}},
  [CharlockThroneRoom] = {},
  [Kol]                = {},
  [Brecconary]         = {{1,13}, {4,7}, {10,26}, {20,23}, {28,1}},
  [Garinham]           = {{2,17}, {9,6}, {14,1}},
  [Cantlin]            = {{0,0}},
  [Rimuldar]           = {{2,4}, {27,0}},
  [TantegelBasement]   = {},
  [NorthernShrine]     = {},
  [SouthernShrine]     = {},
  [CharlockCaveLv1]    = {},
  [CharlockCaveLv2]    = {},
  [CharlockCaveLv3]    = {},
  [CharlockCaveLv4]    = {},
  [CharlockCaveLv5]    = {},
  [CharlockCaveLv6]    = {},
  [SwampCave]          = {},
  [MountainCaveLv1]    = {},
  [MountainCaveLv2]    = {},
  [GarinsGraveLv1]     = {},
  [GarinsGraveLv2]     = {},
  [GarinsGraveLv3]     = {},
  [GarinsGraveLv4]     = {},
  [ErdricksCaveLv1]    = {},
  [ErdricksCaveLv2]    = {},
}

-- @mapId     :: MapId / Int
-- @mapName   :: String
-- @mapType   :: MapType
-- @entrances :: [Entrance] -- TODO: could/should this be a Table3D?
-- @width     :: Int
-- @height    :: Int
-- @rows      :: [[Int]] -- TODO: i think we can/should make it a [[StaticMapTile]]
-- @allWarps  :: [Warp]
StaticMap = class(function(a, mapId, mapName, mapType, entrances, width, height, rows, allWarps)
  a.mapId = mapId
  a.mapName = mapName
  a.mapType = mapType
  a.entrances = entrances
  a.width = width
  a.height = height
  a.rows = rows
  -- both of these are weird.
  -- i feel like we should call these functions outside of here and pass the result in
  -- and just do the assignment here.
  a.warps = getWarpsForMap(mapId, allWarps)
  -- @doors :: Table3D StaticMapTile
  a.doors = getAllDoors(mapId, rows)
  a.immobileScps = list.map(IMMOBILE_NPCS[mapId], function(xy) return Point(mapId, xy[1], xy[2]) end)
  a.seenByPlayer = false
end)

-- @rows :: [[StaticMapTile]]
-- @returns :: Table3D StaticMapTile
function getAllDoors(mapId, rows)
  local tileSet = getTileSetFromMapId(mapId)
  local res = Table3D()
  for y,row in pairs(rows) do
    for x,tileId in pairs(row) do
      local tile = tileSet[tileId]
      if tile:isDoor() then res:insert(Point(mapId, x, y), tileSet[tile.id]) end
    end
  end
  return res
end

function StaticMap:resetWarps (allWarps)
  self.warps = getWarpsForMap(self.mapId, allWarps)
end

function getTileSetFromMapId(mapId)
  return mapId < 15 and NON_DUNGEON_TILES or DUNGEON_TILES
end

function StaticMap:getTileSet ()
  return getTileSetFromMapId(self.mapId)
end

function StaticMap:getTileAt(x, y)
  return self:getTileSet()[self.rows[y][x]]
end

function StaticMap:setTileAt(x, y, newTileId)
  self.rows[y][x] = newTileId
end

-- @self :: StaticMap
-- @returns :: [MapId] (aka [Int])
function StaticMap:childrenIds()
  if     self.mapId ==  2 then return {6,15,16,17,18,19,20}
  elseif self.mapId ==  4 then return {5}
  elseif self.mapId ==  5 then return {4}
  elseif self.mapId == 22 then return {23}
  elseif self.mapId == 24 then return {25,26,27}
  elseif self.mapId == 28 then return {29}
  else return {}
  end
end

local OverWorldId = 1 -- TODO: get this constant from somewhere else!

-- @returns :: [MapId] aka [Int]
function StaticMap:parentIds()
  -- Note:
  --   This whole function could be written in a simpler way (and used to be)
  --   However, it is easier to see and understand when it is written out completely like it is now.
  function parentIdsFromEntrances() return list.map(self.entrances, function(e) return e.from.mapId end) end
  if     self.mapId == Charlock           then return {OverWorldId}
  elseif self.mapId == Hauksness          then return {OverWorldId}
  elseif self.mapId == Tantegel           then return {OverWorldId}
  elseif self.mapId == TantegelThroneRoom then return {Tantegel}
  elseif self.mapId == CharlockThroneRoom then return {Charlock}
  elseif self.mapId >= CharlockCaveLv1 and self.mapId <= CharlockCaveLv6 then return {Charlock}
  elseif self.mapId == Kol                then return {OverWorldId}
  elseif self.mapId == Brecconary         then return {OverWorldId}
  elseif self.mapId == Garinham           then return {OverWorldId}
  elseif self.mapId == Cantlin            then return {OverWorldId}
  elseif self.mapId == Rimuldar           then return {OverWorldId}
  elseif self.mapId == TantegelBasement   then return parentIdsFromEntrances()
  elseif self.mapId == NorthernShrine     then return parentIdsFromEntrances()
  elseif self.mapId == SouthernShrine     then return parentIdsFromEntrances()
  elseif self.mapId == MountainCaveLv1    then return parentIdsFromEntrances()
  elseif self.mapId == MountainCaveLv2    then return {MountainCaveLv1}
  elseif self.mapId == ErdricksCaveLv1    then return parentIdsFromEntrances()
  elseif self.mapId == ErdricksCaveLv2    then return {ErdricksCaveLv1}
  elseif self.mapId == SwampCave          then return parentIdsFromEntrances()
  elseif self.mapId == GarinsGraveLv1     then return parentIdsFromEntrances()
  elseif self.mapId >= GarinsGraveLv2  and self.mapId <= GarinsGraveLv4  then return {GarinsGraveLv1}
  -- This should never happen. we just don't have proper pattern matching.
  else log.error("unhandled map id in parentIds", self.mapId, self.mapName)
  end
end

-- Returns true if walking from TantegelThroneRoom to the given map would require going out
-- to the overworld (vs say, just walking into the basement of Tantegel).
-- Returns false otherwise (if the mapId is Tantegel or is somewhere in the basement of it)
-- @allStaticMaps :: [StaticMap]
-- @returns :: Bool
function StaticMap:pathWouldRequireOverworld(allStaticMaps)
  return not self:isTantegelAParent(allStaticMaps)
end

-- @allStaticMaps :: [StaticMap]
-- @returns :: [MapId]
function StaticMap:walkParentIds(allStaticMaps)
  return list.bind(self:parentIds(), function(pid)
    if pid == OverWorldId then return {OverWorldId}
    else return table.concat({pid}, allStaticMaps[pid]:parentIds())
    end
  end)
end

-- @allStaticMaps :: [StaticMap]
-- @returns :: Bool
function StaticMap:isTantegelAParent(allStaticMaps)
  return list.any(self:walkParentIds(allStaticMaps), function(pid) return pid == Tantegel end)
end

-- Get the point that you warp to when you enter this map from the overworld (or tantegel/garinham)
-- if this map is a child (like say, CharlockCaveLv6), then itll return
-- the point of the parent (Charlock, in this example)
-- returns a list because Swamp Cave can have multiple entrances
-- @allStaticMaps :: [StaticMap]
-- @returns :: [Point]
function StaticMap:getFirstStep(allStaticMaps)
  if self.entrances ~= nil then
    return list.map(self.entrances, function(e) return e.to end)
  else
    -- TODO: constant... use OverWorldId
    return list.bind(list.filter(self:parentIds(), function(pid) return pid ~= 1 end) , function(pid)
      return allStaticMaps[pid]:getFirstStep(allStaticMaps)
    end)
  end
end

function StaticMap:markSeenByPlayer(allStaticMaps)
  log.debug("now seen by player: ", self.mapName)
  self.seenByPlayer = true
  for _,childId in pairs(self:childrenIds()) do
    log.debug("now seen by player: ", allStaticMaps[childId].mapName)
    allStaticMaps[childId].seenByPlayer = true
  end
end

-- @goals :: Goals
-- @allStaticMaps :: [StaticMap]
-- @returns :: [Goal]
function StaticMap:childGoals(goals, allStaticMaps)
  local myLoc = goals:allEntriesForMap(self.mapId)
  local childLocs = list.bind(self:childrenIds(), function(cId) return goals:allEntriesForMap(cId) end)
  return table.concat(myLoc, childLocs)
end

PRINT_TILE_NAME    = 1
PRINT_TILE_NO_KEYS = 2
PRINT_TILE_KEYS    = 3

function StaticMap:__tostring (printStrat)
  function printTile(t)
    if printStrat == PRINT_TILE_NAME or printStrat == nil then return t.name
    elseif printStrat == PRINT_TILE_NO_KEYS then return t.walkable and "O" or " "
    else return (t.walkableWithKeys or t.walkable) and "O" or " "
    end
  end

  local tileSet = self:getTileSet()
  local res = ""
  for y = 0,self.height-1 do
    local row = ""
    for x = 0,self.width-1 do
      local t = tileSet[self.rows[y][x]]
      row = row .. " | " .. printTile(t)
    end
    res = res .. row .. " |\n"
  end
  return self.mapName .. "\n" .. res
end

function StaticMap:writeTileNamesToFile (file)
  file:write(self:__tostring() .. "\n")
end

MAP_DIRECTORY = "/Users/joshuacough/work/dwrandomizer_ai/maps/"
STATIC_MAPS_FILE = MAP_DIRECTORY .. "static_maps.txt"

function StaticMap:saveIdsToFile ()
  local mapFileName = MAP_DIRECTORY .. self.mapName
  table.save(self.rows, mapFileName)
end

function StaticMap:saveGraphToFile ()
  local graphNoKeysFileName = MAP_DIRECTORY .. self.mapName .. ".graph"
  local graphWithKeysFileName = MAP_DIRECTORY .. self.mapName .. ".with_keys.graph"
  table.save(self:mkGraph(false), graphNoKeysFileName)
  table.save(self:mkGraph(true), graphWithKeysFileName)
end

-- TODO: i dont really think the next two functions work anymore.
function quickPrintGraph(mapId, allWarps)
  log.debug(loadStaticMapFromFile(mapId, allWarps):mkGraph(false))
  log.debug(loadStaticMapFromFile(mapId, allWarps):mkGraph(true))
end

function loadStaticMapFromFile (mapId, allWarps)
  if mapId < 2 then return nil end
  local mapData = STATIC_MAP_METADATA[mapId]
  local mapName = mapData.name
  local mapFileName = MAP_DIRECTORY .. mapName
  -- TODO: these overworld coordinates are wrong. we definitely have a problem
  -- reading from files now.
  return StaticMap(mapId, mapName, mapData.mapType, mapData.overworldCoordinates,
                   mapData.size.width, mapData.size.height, table.load(mapFileName), allWarps)
end

function readAllStaticMaps(memory, allWarps)
  local res = {}
  for i = 2, 29 do
    res[i] = readStaticMapFromRom(memory, i, allWarps)
  end
  return res
end

function saveStaticMaps(memory, allWarps)
  local file = io.open(STATIC_MAPS_FILE, "w")
  local maps = readAllStaticMaps(memory, allWarps)
  for i = 2, 29 do
    maps[i]:writeTileNamesToFile(file)
    maps[i]:saveIdsToFile()
    maps[i]:saveGraphToFile()
  end
  file:close()
end

function readStaticMapFromRom(memory, mapId, allWarps)
  local mapData = STATIC_MAP_METADATA[mapId]

  -- returns the tile id for the given (x,y) for the current map
  function readTileIdAt(x, y)
    local offset = (y*mapData.size.width) + x
    local addr = mapData.mapLayoutRomAddr + math.floor(offset/2)
    local val = memory:readROM(addr)
    local tile = isEven(offset) and hiNibble(val) or loNibble(val)
    -- TODO: i tried to use 0x111 but it went insane... so just using 7 instead.
    return mapId < 12 and tile or bitwise_and(tile, 7)
  end

  -- returns a two dimensional grid of tile ids for the current map
  function readTileIds ()
    local res = {}
    for y = 0, mapData.size.height-1 do
      res[y] = {}
      for x = 0, mapData.size.width-1 do
        res[y][x]=readTileIdAt(x,y)
      end
    end
    return res
  end

  local entrances = nil
  if mapData.entrances ~= nil then
    entrances = list.map(mapData.entrances, function(e) return e:convertToEntrance(memory) end)
  end

  return StaticMap(mapId, mapData.name, mapData.mapType, mapData:readEntranceCoordinates(memory),
                   mapData.size.width, mapData.size.height, readTileIds(), allWarps)
end
