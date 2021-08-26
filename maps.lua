require 'helpers'
require 'Class'

MapData = {
  [1] = {["name"] = "Overworld", ["size"] = {["w"]=120,["h"]=120}, ["romAddr"] = 0x1D6D},
  [2] = {["name"] = "Charlock", ["size"] = {["w"]=20,["h"]=20}, ["romAddr"] = 0xC0},
  [3] = {["name"] = "Hauksness", ["size"] = {["w"]=20,["h"]=20}, ["romAddr"] = 0x188},
  [4] = {["name"] = "Tantegel", ["size"] = {["w"]=30,["h"]=30}, ["romAddr"] = 0x250},
  [5] = {["name"] = "Tantegel Throne Room", ["size"] = {["w"]=10,["h"]=10}, ["romAddr"] = 0x412},
  [6] = {["name"] = "Charlock Throne Room", ["size"] = {["w"]=30,["h"]=30}, ["romAddr"] = 0x444},
  [7] = {["name"] = "Kol", ["size"] = {["w"]=24,["h"]=24}, ["romAddr"] = 0x606},
  [8] = {["name"] = "Brecconary", ["size"] = {["w"]=30,["h"]=30}, ["romAddr"] = 0x726},
  [9] = {["name"] = "Garinham", ["size"] = {["w"]=20,["h"]=20}, ["romAddr"] = 0xAAA},
  [10]= {["name"] = "Cantlin", ["size"] = {["w"]=30,["h"]=30}, ["romAddr"] = 0x8E8},
  [11]= {["name"] = "Rimuldar", ["size"] = {["w"]=30,["h"]=30}, ["romAddr"] = 0xB72},
  [12]= {["name"] = "Tantegel Basement", ["size"] = {["w"]=10,["h"]=10}, ["romAddr"] = 0xD34},
  [13]= {["name"] = "Northern Shrine", ["size"] = {["w"]=10,["h"]=10}, ["romAddr"] = 0xD66},
  [14]= {["name"] = "Southern Shrine", ["size"] = {["w"]=10,["h"]=10}, ["romAddr"] = 0xD98},
  [15]= {["name"] = "Charlock Cave Lv 1", ["size"] = {["w"]=20,["h"]=20}, ["romAddr"] = 0xDCA},
  [16]= {["name"] = "Charlock Cave Lv 2", ["size"] = {["w"]=10,["h"]=10}, ["romAddr"] = 0xE92},
  [17]= {["name"] = "Charlock Cave Lv 3", ["size"] = {["w"]=10,["h"]=10}, ["romAddr"] = 0xEC4},
  [18]= {["name"] = "Charlock Cave Lv 4", ["size"] = {["w"]=10,["h"]=10}, ["romAddr"] = 0xEF6},
  [19]= {["name"] = "Charlock Cave Lv 5", ["size"] = {["w"]=10,["h"]=10}, ["romAddr"] = 0xF28},
  [20]= {["name"] = "Charlock Cave Lv 6", ["size"] = {["w"]=10,["h"]=10}, ["romAddr"] = 0xF5A},
  [21]= {["name"] = "Swamp Cave", ["size"] = {["w"]=6,["h"]=30}, ["romAddr"] = 0xF8C},
  [22]= {["name"] = "Mountain Cave", ["size"] = {["w"]=14,["h"]=14}, ["romAddr"] = 0xFE6},
  [23]= {["name"] = "Mountain Cave Lv 2", ["size"] = {["w"]=14,["h"]=14}, ["romAddr"] = 0x1048},
  [24]= {["name"] = "Garin's Grave Lv 1", ["size"] = {["w"]=20,["h"]=20}, ["romAddr"] = 0x10AA},
  [25]= {["name"] = "Garin's Grave Lv 2", ["size"] = {["w"]=14,["h"]=12}, ["romAddr"] = 0x126C},
  [26]= {["name"] = "Garin's Grave Lv 3", ["size"] = {["w"]=20,["h"]=20}, ["romAddr"] = 0x1172},
  [27]= {["name"] = "Garin's Grave Lv 4", ["size"] = {["w"]=10,["h"]=10}, ["romAddr"] = 0x123A},
  [28]= {["name"] = "Erdrick's Cave", ["size"] = {["w"]=10,["h"]=10}, ["romAddr"] = 0x12C0},
  [29]= {["name"] = "Erdrick's Cave Lv 2", ["size"] = {["w"]=10,["h"]=10}, ["romAddr"] = 0x12F2},
}

Tiles = {
  [0]   = "Grass ",
  [1]   = "Sand  ",
  [2]   = "Water ",
  [3]   = "Chest ",
  [4]   = "Stone ",
  [5]   = "Up    ",
  [6]   = "Brick ",
  [7]   = "Down  ",
  [8]   = "Trees ",
  [9]   = "Swamp ",
  [0xA] = "Field ",
  [0xB] = "Door  ",
  [0xC] = "Weapon",
  [0xD] = "Inn   ",
  [0xE] = "Bridge",
  [0xF] = "Tile  ",
}

DungeonTiles = {
  [0]   = "Stone",
  [1]   = "Up   ",
  [2]   = "Brick",
  [3]   = "Down ",
  [4]   = "Chest",
  [5]   = "Door ",
  [6]   = "Brick", -- in swamp cave, we get id six where the princess is. its the only 6 we get in any dungeon.
}

OVERWORLD_TILES = {
  [0]   = "Grass   ",
  [1]   = "Desert  ",
  [2]   = "Hills   ",
  [3]   = "Mountain",
  [4]   = "Water   ",
  [5]   = "Rock    ",
  [6]   = "Forest  ",
  [7]   = "Swamp   ",
  [8]   = "Town    ",
  [9]   = "Cave    ",
  [0xA] = "Castle  ",
  [0xB] = "Bridge  ",
  [0xC] = "Stairs  ",
}

function getOverworldTileName(tileId)
  return OVERWORLD_TILES[tileId] and OVERWORLD_TILES[tileId] or "unknown"
end

MAX_TILES=14400

-- This implementation that reads from NES memory basically.
-- We could have an implementation that does it differently
-- such as reading an overworld from a file, or just generating one
-- randomly or whatever... but for now this is all we have.
function readOverworldFromROM (memory)

  -- 1D6D - 2662  | Overworld map          | RLE encoded, 1st nibble is tile, 2nd how many - 1
  -- 2663 - 26DA  | Overworld map pointers | 16 bits each - address of each row of the map. (value - 0x8000 + 16)
  function decodeOverworldPointer (p)
    -- mcgrew: Keep in mind they are in little endian format.
    -- mcgrew: So it's LOW_BYTE, HIGH_BYTE
    -- Also keep in mind they are addresses as the NES sees them, so to get the address in
    -- ROM you'll need to subtract 0x8000 (and add 16 for the header)
    local lowByte = memory:readROM(p)
    local highByte = memory:readROM(p+1)
    -- left shift the high byte by 8
    local shiftedHighByte = highByte * (2 ^ 8)
    local addr = shiftedHighByte + lowByte - 0x8000 + 16
    return addr
  end

  function getOverworldPointers ()
    local res = {}
    for i = 0,119 do
      res[i+1] = decodeOverworldPointer(0x2663 + i * 2)
    end
    return res
  end

  function getOverworldTileRow(overworldPointer)
    local totalCount = 0
    local tileIds = {}
    local currentAddr = overworldPointer

    while( totalCount < 120 )
    do
      tileId = hiNibble(memory:readROM(currentAddr))
      count = loNibble(memory:readROM(currentAddr)) + 1
      for i = 1,count do
        tileIds[totalCount+i] = tileId
      end
      currentAddr = currentAddr + 1
      totalCount = totalCount + count
    end
    return tileIds
  end

  local pointers = getOverworldPointers()
  local rows = {}
  for i = 1,120 do
    rows[i] = getOverworldTileRow(pointers[i])
  end
  return rows
end

function emptyWorldGrid()
  res = {}
  for y = 1, 120 do
    res[y] = {}
    for x = 1, 120 do
      res[y][x]=false
    end
  end
  return res
end

OverWorld = class(function(a,rows)
  a.overworldRows = rows
  a.knownWorld = emptyWorldGrid() -- the world the player has seen. maybe this should be in a Player object!
  a.nrTilesSeen = 0
end)

function OverWorld:percentageOfWorldSeen()
  return self.nrTilesSeen/MAX_TILES*100
end

function OverWorld:getOverworldMapTileAt(x, y)
  return OVERWORLD_TILES[self:getOverworldMapTileIdAt(x, y)]
end

function OverWorld:updateKnownWorld(x, y, tileId)
  if self.knownWorld[y+1][x+1] == false
    then
      self.knownWorld[y+1][x+1] = tileId
      self.nrTilesSeen=self.nrTilesSeen+1
      local tileName = getOverworldTileName(tileId)
      print ("discovered new tile at (x: " .. x .. ", y: " .. y .. "), tile is: " .. tileName)
  end
end

-- returns the tile id for the given (x,y) for the overworld
-- {["name"] = "Overworld", ["size"] = {120,120}, ["romAddr"] = {0x1D6D, 0x2668}},
function OverWorld:getOverworldMapTileIdAt(x, y)
  local tileId = self.overworldRows[y+1][x+1]
  -- optimization... each time we get a visible tile, record it in what we have seen
  self:updateKnownWorld(x,y,tileId)
  return tileId
end

function OverWorld:getVisibleOverworldGrid(currentX, currentY)
  local upperLeftX = math.max(0, currentX - 8)
  local upperLeftY = math.max(0, currentY - 6)

  local bottomRightX = math.min(120, currentX + 7)
  local bottomRightY = math.min(120, currentY + 7)

  local res = {}
  for y = upperLeftY, bottomRightY do
    res[y-upperLeftY+1] = {}
    for x = upperLeftX, bottomRightX do
      res[y-upperLeftY+1][x-upperLeftX+1]=self:getOverworldMapTileIdAt(x, y)
    end
  end
  return res
end

function OverWorld:printVisibleGrid (currentX, currentY)
  local grid = self:getVisibleOverworldGrid(currentX, currentY)
  for y = 1, #(grid) do
    local row = ""
    for x = 1, #(grid[y]) do
      row = row .. " | " .. getOverworldTileName(grid[y][x])
    end
    print(row .. " |")
  end
  print("-------------------------")
end

StaticMap = class(function(a, mapId, mapName, width, height, rows)
  a.mapId = mapId
  a.mapName = mapName
  a.width = width
  a.height = height
  a.rows = rows
end)

function StaticMap:getTileSet ()
  return self.mapId < 15 and Tiles or DungeonTiles
end

function StaticMap:toString ()
  local tileSet = self:getTileSet()
  local res = ""
  for y = 1,self.height do
    local row = ""
    for x = 1,self.width do
      row = row .. " | " .. tileSet[self.rows[y][x]]
    end
    res = res .. row .. " |\n"
  end
  return res
end

function StaticMap:writeToFile (file)
  file:write(self.mapName .. "\n")
  file:write(self:toString() .. "\n")
  file:write("------------------\n")
end

function readAllStaticMaps(memory)
  res = {}
  for i = 2, 29 do
    res[i] = readStaticMapFromRom(memory, i)
  end
  return res
end

function writeAllStaticMapsToFile(memory, filename)
  local file = io.open(filename, "w")
  local maps = readAllStaticMaps(memory)
  for i = 2, 29 do
    maps[i]:writeToFile(file)
  end
  file:close()
end

function readStaticMapFromRom(memory, mapId)
  local mapData = MapData[mapId]
  local mapSize = mapData["size"]
  local width = mapSize["w"]
  local height = mapSize["h"]
  local startAddr = mapData["romAddr"]

  -- returns the tile id for the given (x,y) for the current map
  function getMapTileIdAt(x, y)
    local offset = (y*width) + x
    local addr = startAddr + math.floor(offset/2)
    local val = memory:readROM(addr)
    -- TODO: i tried to use 0x111 but it went insane... so just using 7 instead.
    return bitwise_and(isEven(offset) and hiNibble(val) or loNibble(val), 7)
  end

  -- returns a two dimensional grid of tile ids for the current map
  function getMapTileIds ()
    local res = {}
    for y = 0, height-1 do
      res[y+1] = {}
      for x = 0, width-1 do
        res[y+1][x+1]=getMapTileIdAt(x,y)
      end
    end
    return res
  end

  return StaticMap(mapId, mapData["name"], width, height, getMapTileIds())
end

