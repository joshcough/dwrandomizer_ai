require 'helpers'
require 'Class'

MapData = {
  [1] = {["name"] = "Overworld", ["size"] = {120,120}, ["romAddr"] = {0x1D6D, 0x2668}},
  [2] = {["name"] = "Charlock", ["size"] = {20,20}, ["romAddr"] = {0xC0, 0x187}},
  [3] = {["name"] = "Hauksness", ["size"] = {20,20}, ["romAddr"] = {0x188, 0x24f}},
  [4] = {["name"] = "Tantegel", ["size"] = {30,30}, ["romAddr"] = {0x250, 0x411}},
  [5] = {["name"] = "Tantegel Throne Room", ["size"] = {10,10}, ["romAddr"] = {0x412, 0x444}},
  [6] = {["name"] = "Charlock Throne Room", ["size"] = {30,30}, ["romAddr"] = {0x444, 0x605}},
  [7] = {["name"] = "Kol", ["size"] = {24,24}, ["romAddr"] = {0x606, 0x825}},
  [8] = {["name"] = "Brecconary", ["size"] = {30,30}, ["romAddr"] = {0x826, 0x8E7}},
  [9] = {["name"] = "Garinham", ["size"] = {20,20}, ["romAddr"] = {0xAAA, 0xB71}},
  [10]= {["name"] = "Cantlin", ["size"] = {30,30}, ["romAddr"] = {0x8E8, 0xAA9}},
  [11]= {["name"] = "Rimuldar", ["size"] = {30,30}, ["romAddr"] = {0xB72, 0xD33}},
  [12]= {["name"] = "Tantegel Basement", ["size"] = {10,10}, ["romAddr"] = {0xD34,0xD65}},
  [13]= {["name"] = "Northern Shrine", ["size"] = {10,10}, ["romAddr"] = {0xD66,0xD97}},
  [14]= {["name"] = "Southern Shrine", ["size"] = {10,10}, ["romAddr"] = {0xD98,0xDC9}},
  [15]= {["name"] = "Charlock Cave Lv 1", ["size"] = {20,20}, ["romAddr"] = {0xDCA, 0xE91}},
  [16]= {["name"] = "Charlock Cave Lv 2", ["size"] = {10,10}, ["romAddr"] = {0xE92, 0xEC3}},
  [17]= {["name"] = "Charlock Cave Lv 3", ["size"] = {10,10}, ["romAddr"] = {0xEC4, 0xEF5}},
  [18]= {["name"] = "Charlock Cave Lv 4", ["size"] = {10,10}, ["romAddr"] = {0xEF6, 0xF27}},
  [19]= {["name"] = "Charlock Cave Lv 5", ["size"] = {10,10}, ["romAddr"] = {0xF28, 0xF59}},
  [20]= {["name"] = "Charlock Cave Lv 6", ["size"] = {10,10}, ["romAddr"] = {0xF5A, 0xF8B}},
  [21]= {["name"] = "Swamp Cave", ["size"] = {6,30}, ["romAddr"] = {0xF8C, 0xFE5}},
  [22]= {["name"] = "Mountain Cave", ["size"] = {14,14}, ["romAddr"] = {0xFE6, 0x1047}},
  [23]= {["name"] = "Mountain Cave Lv 2", ["size"] = {14,14}, ["romAddr"] = {0x1048, 0x10A9}},
  [24]= {["name"] = "Garin's Grave Lv 1", ["size"] = {20,20}, ["romAddr"] = {0x10AA, 0x1171}},
  [25]= {["name"] = "Garin's Grave Lv 2", ["size"] = {14,12}, ["romAddr"] = {0x126C, 0x12BF}},
  [26]= {["name"] = "Garin's Grave Lv 3", ["size"] = {20,20}, ["romAddr"] = {0x1172, 0x1239}},
  [27]= {["name"] = "Garin's Grave Lv 4", ["size"] = {10,10}, ["romAddr"] = {0x123A, 0x126B}},
  [28]= {["name"] = "Erdrick's Cave", ["size"] = {10,10}, ["romAddr"] = {0x12C0, 0x12F1}},
  [29]= {["name"] = "Erdrick's Cave Lv 2", ["size"] = {10,10}, ["romAddr"] = {0x12F2, 0x1323 }},
}

Tiles = {
  [0] = "Grass",
  [1] = "Sand",
  [2] = "Water",
  [3] = "Treasure Chest",
  [4] = "Stone",
  [5] = "Stairs Up",
  [6] = "Brick",
  [7] = "Stairs Down",
  [8] = "Trees",
  [9] = "Swamp",
  [0xA] = "Force Field",
  [0xB] = "Door",
  [0xC] = "Weapon Shop Sign",
  [0xD] = "Inn Sign",
  [0xE] = "Bridge",
  [0xF] = "Large Tile",
}

OVERWORLD_TILES = {
  [0] = "Grass",
  [1] = "Desert",
  [2] = "Hills",
  [3] = "Mountain",
  [4] = "Water",
  [5] = "Rock Wall",
  [6] = "Forest",
  [7] = "Swamp",
  [8] = "Town",
  [9] = "Cave",
  [0xA] = "Castle",
  [0xB] = "Bridge",
  [0xC] = "Stairs",
}

function getOverworldTileName(tileId)
  return OVERWORLD_TILES[tileId] and OVERWORLD_TILES[tileId] or "unknown"
end

MapAddress = 0x45
X_ADDR = 0x8e
Y_ADDR = 0x8f

-- get the x coordinate of the player in the current map
function getX () return readMemory(X_ADDR) end
-- get the y coordinate of the player in the current map
function getY () return readMemory(Y_ADDR) end
-- get the x,y coordinates of the player in the current map
function getXY () return {["x"]=getX(), ["y"]=getY()} end
-- get the id of the current map
function getMapId () return readMemory(MapAddress) end
-- get all the map data for the current map
function getMapData() return MapData[getMapId()] end
-- get the name of the current map
function getMapName() return getMapData()["name"] end
-- get the size of the current map
function getMapSize() return getMapData()["size"] end
-- get the address in ram of the current map
function getMapAddr() return getMapData()["romAddr"] end

MAX_TILES=14400

function readOverworldFromROM ()

  -- 1D6D - 2662  | Overworld map          | RLE encoded, 1st nibble is tile, 2nd how many - 1
  -- 2663 - 26DA  | Overworld map pointers | 16 bits each - address of each row of the map. (value - 0x8000 + 16)
  function decodeOverworldPointer (p)
    -- mcgrew: Keep in mind they are in little endian format.
    -- mcgrew: So it's LOW_BYTE, HIGH_BYTE
    -- Also keep in mind they are addresses as the NES sees them, so to get the address in
    -- ROM you'll need to subtract 0x8000 (and add 16 for the header)
    local lowByte = readROM(p)
    local highByte = readROM(p+1)
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
      tileId = hiNibble(rom.readbyte(currentAddr))
      count = loNibble(rom.readbyte(currentAddr)) + 1
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

-- o = OverWorld(emptyWorldGrid())
OverWorld = class(function(a,rows)
  a.overworldRows = rows
  a.knownWorld = emptyWorldGrid() -- the world the player has seen. maybe this should be in a Player object!
  a.nrTilesSeen = 0
end)

-- function OverWorld:dump ()
--   print("OverWorld:")
--   print("  overworldRows: ", self.overworldRows)
--   print("  knownWorld: ",  self.knownWorld)
--   print("  nrTilesSeen: " .. self.nrTilesSeen)
-- end

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

OtherMap = class(function(a,rows)
  a.rows = rows
end)

function OtherMap:dump ()
  print("Map:")
  print("  rows: " .. self.rows)
end

-- this is not for the overworld
-- returns the tile id for the given (x,y) for the current map
function getMapTileIdAt(x, y)
  local startAddr = getMapAddr()[1]
  local size = getMapSize()
  local height = size[1]
  local offset = (y*height) + x
  local addr = startAddr + math.floor(offset/2)
  local res;
  if (isEven(offset))
    then res = hiNibble(rom.readbyte(addr))
    else res = loNibble(rom.readbyte(addr))
  end
  return res
end

-- this is not for the overworld
-- returns a two dimensional grid of tile ids for the current map
function getMapTileIds ()
  local size = getMapSize()
  local width = size[1]
  local height = size[2]
  local res = {}
  for y = 0, height-1 do
    res[y+1] = {}
    for x = 0, width-1 do
      res[y+1][x+1]=getMapTileIdAt(x,y)
    end
  end
  return res
end

-- this is not for the overworld
-- print out the current map to the console
function printMap ()
  local size = getMapSize()
  local width = size[1]
  local height = size[2]
  local tileIds = getMapTileIds()
  for x = 1,width do
  local row = ""
  for y = 1,height do
    row = row .. " | " .. Tiles[tileIds[x][y]]
  end
  print(row .. " |")
  end
end

-- function printVisibleGrid ()
--   if getMapId() == 1 -- overworld
--     then printVisibleOverworldGrid ()
--   end
-- end
