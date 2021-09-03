require 'helpers'
require 'Class'
require 'controller'

Charlock = 2
Hauksness = 3
Tantegel = 4
TantegelThroneRoom = 5
CharlockThroneRoom = 6
Kol = 7
Brecconary = 8
Garinham = 9
Cantlin = 10
Rimuldar = 11
TantegelBasement = 12
NorthernShrine = 13
SouthernShrine = 14
CharlockCaveLv1 = 15
CharlockCaveLv2 = 16
CharlockCaveLv3 = 17
CharlockCaveLv4 = 18
CharlockCaveLv5 = 19
CharlockCaveLv6 = 20
SwampCave = 21
MountainCaveLv1 = 22
MountainCaveLv2 = 23
GarinsGraveLv1 = 24
GarinsGraveLv2 = 25
GarinsGraveLv3 = 26
GarinsGraveLv4 = 27
ErdricksCaveLv1 = 28
ErdricksCaveLv2 = 29

TantagelBasementStairs = Point3D(Tantegel, 29, 29)

Warp = class(function(a, src, dest)
  a.src = src
  a.dest = dest
end)

function Warp:swap()
  return Warp(self.dest, self.src)
end

WARPS = {
  Warp(Point3D(2, 10, 1), Point3D(15, 9, 0))
, Warp(Point3D(2, 4, 14), Point3D(15, 8, 13))
, Warp(Point3D(2, 15, 14), Point3D(15, 17, 15))
, Warp(Point3D(5, 1, 8), Point3D(4, 1, 7))
, Warp(Point3D(5, 8, 8), Point3D(4, 7, 7))
-- 9 = garinham, 24 = GarinsGrave -- this one has to be discovered, like the basement
-- , Warp(Point3D(9, 19, 0), Point3D(24, 6, 11))
, Warp(Point3D(15, 15, 1), Point3D(16, 8, 0))
, Warp(Point3D(15, 13, 7), Point3D(16, 4, 4))
, Warp(Point3D(15, 19, 7), Point3D(16, 9, 8))
, Warp(Point3D(15, 14, 9), Point3D(16, 8, 9))
, Warp(Point3D(15, 2, 14), Point3D(16, 0, 1))
, Warp(Point3D(15, 2, 4), Point3D(16, 0, 0))
, Warp(Point3D(15, 8, 19), Point3D(16, 5, 0))
, Warp(Point3D(16, 3, 0), Point3D(17, 7, 0))
, Warp(Point3D(16, 9, 1), Point3D(17, 2, 2))
, Warp(Point3D(16, 0, 8), Point3D(17, 5, 4))
, Warp(Point3D(16, 1, 9), Point3D(17, 0, 9))
, Warp(Point3D(17, 1, 6), Point3D(18, 0, 9))
, Warp(Point3D(17, 7, 7), Point3D(18, 7, 7))
, Warp(Point3D(18, 2, 2), Point3D(19, 9, 0))
, Warp(Point3D(18, 8, 1), Point3D(19, 4, 0))
, Warp(Point3D(19, 5, 5), Point3D(20, 0, 0))
, Warp(Point3D(19, 0, 0), Point3D(20, 0, 6))
, Warp(Point3D(20, 9, 0), Point3D(20, 0, 0))
, Warp(Point3D(20, 9, 6), Point3D(6, 10, 29))
, Warp(Point3D(22, 0, 0), Point3D(23, 0, 0))
, Warp(Point3D(22, 6, 5), Point3D(23, 6, 5))
, Warp(Point3D(22, 12, 12), Point3D(23, 12, 12))
, Warp(Point3D(24, 1, 18), Point3D(25, 11, 2))
, Warp(Point3D(25, 1, 1), Point3D(26, 1, 26))
, Warp(Point3D(25, 12, 1), Point3D(26, 18, 1))
, Warp(Point3D(25, 5, 6), Point3D(26, 6, 11))
, Warp(Point3D(25, 1, 10), Point3D(26, 2, 17))
, Warp(Point3D(25, 12, 10), Point3D(26, 18, 13))
, Warp(Point3D(26, 9, 5), Point3D(27, 0, 4))
, Warp(Point3D(26, 10, 9), Point3D(27, 5, 4))
, Warp(Point3D(28, 9, 9), Point3D(29, 8, 9))
}

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

StaticMapMetadata = class(function(a,name,size,romAddr)
  a.name = name
  a.size = size
  a.romAddr = romAddr
end)

MAP_DATA = {
  [2] = StaticMapMetadata("Charlock", MapSize(20, 20), 0xC0),
  [3] = StaticMapMetadata("Hauksness", MapSize(20, 20), 0x188),
  [4] = StaticMapMetadata("Tantegel", MapSize(30, 30), 0x250),
  [5] = StaticMapMetadata("Tantegel Throne Room", MapSize(10, 10), 0x412),
  [6] = StaticMapMetadata("Charlock Throne Room", MapSize(30, 30), 0x444),
  [7] = StaticMapMetadata("Kol", MapSize(24, 24), 0x606),
  [8] = StaticMapMetadata("Brecconary", MapSize(30, 30), 0x726),
  [9] = StaticMapMetadata("Garinham", MapSize(20, 20), 0xAAA),
  [10]= StaticMapMetadata("Cantlin", MapSize(30, 30), 0x8E8),
  [11]= StaticMapMetadata("Rimuldar", MapSize(30, 30), 0xB72),
  [12]= StaticMapMetadata("Tantegel Basement", MapSize(10, 10), 0xD34),
  [13]= StaticMapMetadata("Northern Shrine", MapSize(10, 10), 0xD66),
  [14]= StaticMapMetadata("Southern Shrine", MapSize(10, 10), 0xD98),
  [15]= StaticMapMetadata("Charlock Cave Lv 1", MapSize(20, 20), 0xDCA),
  [16]= StaticMapMetadata("Charlock Cave Lv 2", MapSize(10, 10), 0xE92),
  [17]= StaticMapMetadata("Charlock Cave Lv 3", MapSize(10, 10), 0xEC4),
  [18]= StaticMapMetadata("Charlock Cave Lv 4", MapSize(10, 10), 0xEF6),
  [19]= StaticMapMetadata("Charlock Cave Lv 5", MapSize(10, 10), 0xF28),
  [20]= StaticMapMetadata("Charlock Cave Lv 6", MapSize(10, 10), 0xF5A),
  [21]= StaticMapMetadata("Swamp Cave", MapSize(6, 30), 0xF8C),
  [22]= StaticMapMetadata("Mountain Cave", MapSize(14, 14), 0xFE6),
  [23]= StaticMapMetadata("Mountain Cave Lv 2", MapSize(14, 14), 0x1048),
  [24]= StaticMapMetadata("Garin's Grave Lv 1", MapSize(20, 20), 0x10AA),
  [25]= StaticMapMetadata("Garin's Grave Lv 2", MapSize(14, 12), 0x126C),
  [26]= StaticMapMetadata("Garin's Grave Lv 3", MapSize(20, 20), 0x1172),
  [27]= StaticMapMetadata("Garin's Grave Lv 4", MapSize(10, 10), 0x123A),
  [28]= StaticMapMetadata("Erdrick's Cave", MapSize(10, 10), 0x12C0),
  [29]= StaticMapMetadata("Erdrick's Cave Lv 2", MapSize(10, 10), 0x12F2),
}

StaticMapTile = class(function(a,name,walkable,walkableWithKeys)
  a.name = name
  a.walkable = walkable
  a.walkableWithKeys = walkableWithKeys and true or false
end)

NON_DUNGEON_TILES = {
  [0]   = StaticMapTile("Grass " , true),
  [1]   = StaticMapTile("Sand  " , true),
  [2]   = StaticMapTile("Water " , false),
  [3]   = StaticMapTile("Chest " , true),
  [4]   = StaticMapTile("Stone " , false),
  [5]   = StaticMapTile("Up    " , true),
  [6]   = StaticMapTile("Brick " , true),
  [7]   = StaticMapTile("Down  " , true),
  [8]   = StaticMapTile("Trees " , true),
  [9]   = StaticMapTile("Swamp " , true),
  [0xA] = StaticMapTile("Field " , true),
  [0xB] = StaticMapTile("Door  " , false , true), -- walkableWithKeys
  [0xC] = StaticMapTile("Weapon" , false),
  [0xD] = StaticMapTile("Inn   " , false),
  [0xE] = StaticMapTile("Bridge" , true),
  [0xF] = StaticMapTile("Tile  " , false),
}

DUNGEON_TILES = {
  [0]   = StaticMapTile("Stone" , false),
  [1]   = StaticMapTile("Up   " , true),
  [2]   = StaticMapTile("Brick" , true),
  [3]   = StaticMapTile("Down " , true),
  [4]   = StaticMapTile("Chest" , true),
  [5]   = StaticMapTile("Door  ", false, true), -- walkableWithKeys
  -- in swamp cave, we get id six where the princess is. its the only 6 we get in any dungeon.
  [6]   = StaticMapTile("Brick  ", true),
}

IMMOBILE_NPCS = {
  [Tantegel] = {{2,8}, {8,6}, {8,8}, {27,5}, {26,15}, {9,27}, {12,27}, {15, 20}},
  [TantegelThroneRoom] = {{3,6}, {5,6}}
}

function getImmobileNPCsForMap(mapId)
  if IMMOBILE_NPCS[mapId] == nil then return {} end
  return list.map(IMMOBILE_NPCS[mapId], function(xy) return Point3D(mapId, xy[1], xy[2]) end)
end

StaticMap = class(function(a, mapId, mapName, width, height, rows, allWarps)
  a.mapId = mapId
  a.mapName = mapName
  a.width = width
  a.height = height
  a.rows = rows
  a.warps = getWarpsForMap(mapId, allWarps)
  a.immobileScps = getImmobileNPCsForMap(mapId)
end)

function StaticMap:getTileSet ()
  return self.mapId < 15 and NON_DUNGEON_TILES or DUNGEON_TILES
end

PRINT_TILE_NAME = 1
PRINT_TILE_NO_KEYS = 2
PRINT_TILE_KEYS = 3

function StaticMap:__tostring (printStrat)
  function printTile(t)
    if printStrat == PRINT_TILE_NAME or printStrat == nil
      then return t.name
      else
        if printStrat == PRINT_TILE_NO_KEYS
          then return t.walkable and "O" or " "
          else return (t.walkableWithKeys or t.walkable) and "O" or " "
        end
    end
  end

  local tileSet = self:getTileSet()
  local res = ""
  for y = 0,self.height-1 do
    local row = ""
    for x = 0,self.width-1 do
      local t = tileSet[self.rows[y][x]]
      row = row .. " | " .. (printTile(t))
    end
    res = res .. row .. " |\n"
  end
  return self.mapName .. "\n" .. res
end

Graph = class(function(a, graph, haveKeys, staticMap)
  a.graph = graph
  a.haveKeys = haveKeys
  a.staticMap = staticMap
end)

function StaticMap:mkGraph (haveKeys)
  local tileSet = self:getTileSet()

  function isWalkable(x,y)
    local t = tileSet[self.rows[y][x]]
    if table.containsUsingDotEquals(self.immobileScps, Point3D(self.mapId, x, y))
      then return false
      else return haveKeys and (t.walkableWithKeys or t.walkable) or t.walkable
    end
  end

  --         x,y-1
  -- x-1,y   x,y     x+1,y
  --         x,y+1
  function neighbors(x,y)
    -- if we can't walk to the node, dont bother including the node in the graph at all
    if not isWalkable(x,y) then return {} end
    local res = {}
    if x > 0 and isWalkable(x-1, y) then table.insert(res, Point3D(self.mapId, x-1, y)) end
    if x < self.width - 1 and isWalkable(x+1, y) then table.insert(res, Point3D(self.mapId, x+1, y)) end
    if y > 0 and isWalkable(x, y-1) then table.insert(res, Point3D(self.mapId, x, y-1)) end
    if y < self.height - 1 and isWalkable(x, y+1) then table.insert(res, Point3D(self.mapId, x, y+1)) end

    if self.warps[x] ~= nil then
      if self.warps[x][y] ~= nil then
        for _, w in pairs(self.warps[x][y]) do table.insert(res, w)  end
      end
    end

    return res
  end

  local res = {}
  for y = 0,self.height-1 do
    res[y] = {}
    for x = 0,self.width-1 do
      res[y][x] = neighbors(x,y)
    end
  end
  return Graph(res, haveKeys, self)
end

function Graph:__tostring ()

  local contains = table.containsUsingDotEquals

  function printTile(x,y,neighbors)
    if neighbors == nil then return "   " end
    local res = ""
    if contains(neighbors, Point3D(self.staticMap.mapId, x-1, y)) then res = res .. "←" else res = res .. " " end
    if contains(neighbors, Point3D(self.staticMap.mapId, x, y-1)) and contains(neighbors, Point3D(self.staticMap.mapId, x, y+1))
      then res = res .. "↕"
      else if contains(neighbors, Point3D(self.staticMap.mapId, x, y-1)) then res = res .. "↑"
      else if contains(neighbors, Point3D(self.staticMap.mapId, x, y+1)) then res = res .. "↓"
      else res = res .. " "
      end end
    end
    if contains(neighbors, Point3D(self.staticMap.mapId, x+1, y)) then res = res .. "→" else res = res .. " " end
    return res
  end

  local tileSet = self.staticMap:getTileSet()
  local res = ""
  for y = 0,self.staticMap.height-1 do
    local row = ""
    for x = 0,self.staticMap.width-1 do
      row = row .. "|" .. printTile(x, y, self.graph[y][x])
    end
    res = res .. row .. " |\n"
  end
  return res
end

function StaticMap:writeTileNamesToFile (file)
  file:write(self:__tostring() .. "\n")
end

MAP_DIRECTORY = "/Users/joshcough/work/dwrandomizer_ai/maps/"
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

function quickPrintGraph(mapId, allWarps)
  print(loadStaticMapFromFile(mapId, allWarps):mkGraph(false))
  print(loadStaticMapFromFile(mapId, allWarps):mkGraph(true))
end

function loadStaticMapFromFile (mapId, allWarps)
  if mapId < 2 then return nil end
  local mapData = MAP_DATA[mapId]
  local mapName = mapData["name"]
  local mapFileName = MAP_DIRECTORY .. mapName
  return StaticMap(mapId, mapName, mapData["size"]["w"], mapData["size"]["h"], table.load(mapFileName), allWarps)
end

function readAllStaticMaps(memory, allWarps)
  local res = {}
  for i = 2, 29 do
    res[i] = memory == nil and loadStaticMapFromFile(i, allWarps) or readStaticMapFromRom(memory, i, allWarps)
  end
  return res
end

function readAllGraphs(memory, haveKeys, maps, allWarps)
  if maps == nil then maps = readAllStaticMaps(memory, allWarps) end
  local res = {}
  for i = 2, 29 do
    local g = maps[i]:mkGraph(haveKeys)
    res[i] = g
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
  local mapData = MAP_DATA[mapId]

  -- returns the tile id for the given (x,y) for the current map
  function getMapTileIdAt(x, y)
    local offset = (y*mapData.size.width) + x
    local addr = mapData.romAddr + math.floor(offset/2)
    local val = memory:readROM(addr)
    local tile = isEven(offset) and hiNibble(val) or loNibble(val)
    -- TODO: i tried to use 0x111 but it went insane... so just using 7 instead.
    return mapId < 12 and tile or bitwise_and(tile, 7)
  end

  -- returns a two dimensional grid of tile ids for the current map
  function getMapTileIds ()
    local res = {}
    for y = 0, mapData.size.height-1 do
      res[y] = {}
      for x = 0, mapData.size.width-1 do
        res[y][x]=getMapTileIdAt(x,y)
      end
    end
    return res
  end

  return StaticMap(mapId, mapData.name, mapData.size.width, mapData.size.height, getMapTileIds(), allWarps)
end

MovementCommand = class(function(a,direction,from,to)
  a.direction = direction
  a.from = from
  a.to = to
end)

function up    (f, t) return MovementCommand(UP, f, t) end
function down  (f, t) return MovementCommand(DOWN, f, t) end
function right (f, t) return MovementCommand(LEFT, f, t) end
function left  (f, t) return MovementCommand(RIGHT, f, t) end
function stairs  (f, t) return MovementCommand("Stairs", f, t) end
-- function assume(p) return { ["Assume"] = c, ["start"] = p } end

function directionFromP1ToP2(p1, p2)
  if p1.mapId ~= p2.mapId then return stairs(p1, p2) end
  if p2.y < p1.y then return up(p1, p2) end
  if p2.y > p1.y then return down(p1, p2) end
  if p2.x < p1.x then return right(p1, p2) end
  if p2.x > p1.x then return left(p1, p2) end
end

function sameDirection (c1, c2)
  return c1.direction == c2.direction
end

-- i want to turn a path into a set of commands like so, assuming the start is (4,4)
-- { direction = "Assume", x = 4, y = 4 }
-- { direction = "Up", until y = 7 }
-- { direction = "Assume", x = 4, y = 7 }
-- { direction = "Right", until x = 9 }
-- todo can we get rid of this? just have the algo check that we are always in the expected places?:
-- -- -- { direction = "Assume", x = 9, y = 7 }
-- { direction = "Down", y = 4 }
function convertPathToCommands(pathIn)
  local path = table.copy(pathIn)

  -- todo: consider if we should just throw an error here.
  -- an empty path would be really weird
  if(#(path) == 0) then return {} end
--   if(#(path) == 1) then return assume(path[1]) end

  local commands = list.zipWith(directionFromP1ToP2, path, list.drop(1, path))

  return list.foldLeft(commands, {}, function(acc, c)
    if c.direction == "Stairs"
      then table.insert(acc, c)
      else
        if #(acc) > 0 and sameDirection(acc[#(acc)], c)
        then acc[#(acc)].to = c.to
        else table.insert(acc, c)
        end
    end
    return acc
  end)
end
