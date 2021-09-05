require 'helpers'
require 'Class'

-- Overworld = 1
--
-- MAP_DATA = {
--   [1] = {["name"] = "Overworld", ["size"] = {["w"]=120,["h"]=120}, ["romAddr"] = 0x1D6D},
-- }

OverworldTile = class(function(a,name,walkable)
  a.name = name
  a.walkable = walkable
end)

OVERWORLD_TILES = {
  [0]   = OverworldTile("Grass   ", true),  -- "🟩",
  [1]   = OverworldTile("Desert  ", true),  -- "🏜",
  [2]   = OverworldTile("Hills   ", true),  -- "🏞"
  [3]   = OverworldTile("Mountain", false), -- "⛰",
  [4]   = OverworldTile("Water   ", false), -- "🌊",
  [5]   = OverworldTile("Stone   ", false), -- "⬛",
  [6]   = OverworldTile("Forest  ", true),  -- "🌳",
  [7]   = OverworldTile("Swamp   ", true),
  [8]   = OverworldTile("Town    ", true),
  [9]   = OverworldTile("Cave    ", true),
  [0xA] = OverworldTile("Castle  ", true),  -- "🏰"
  [0xB] = OverworldTile("Bridge  ", true),  -- "🌉",
  [0xC] = OverworldTile("Stairs  ", true),
}

function getOverworldTileName(tileId)
  return OVERWORLD_TILES[tileId] and OVERWORLD_TILES[tileId].name or "unknown"
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
  local res = {}
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
      print ("discovered new tile at (x: " .. x .. ", y: " .. y .. ")" .. " tile is: " .. tileName)
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
