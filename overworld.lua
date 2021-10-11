require 'helpers'
require 'Class'

OverWorldId = 1

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
      res[i] = decodeOverworldPointer(0x2663 + i * 2)
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
      for i = 0,count-1 do
        tileIds[totalCount+i] = tileId
      end
      currentAddr = currentAddr + 1
      totalCount = totalCount + count
    end
    return tileIds
  end

  local pointers = getOverworldPointers()
  local rows = {}
  for i = 0,119 do
    rows[i] = getOverworldTileRow(pointers[i])
  end
  return rows
end

OverWorld = class(function(a,rows)
  a.overworldRows = rows
  a.knownWorld = {}
  a.nrTilesSeen = 0
  a.importantLocations = {}
end)

function OverWorld:percentageOfWorldSeen()
  return self.nrTilesSeen/MAX_TILES*100
end

function OverWorld:getOverworldMapTileAt(x, y)
  return OVERWORLD_TILES[self:getOverworldMapTileIdAt(x, y)]
end

ImportantLocationType = enum.new("Tyoes of important locations on the Overworld", {
  "CHARLOCK", -- Could be CASTLE, but, we already know where Tantegel is, so, it just must be Charlock
  "TOWN",
  "CAVE",
})

function locationTypeFromTile(tileId)
  if     tileId == 8  then return ImportantLocationType.TOWN
  elseif tileId == 9  then return ImportantLocationType.CAVE
  elseif tileId == 10 then return ImportantLocationType.CHARLOCK
  end
end

ImportantLocation = class(function(a,x,y,tileId)
  a.location = Point(OverWorldId, x, y)
  a.type = locationTypeFromTile(tileId)
end)

function OverWorld:updateKnownWorld(x, y, tileId)
  if self.knownWorld[y] == nil then self.knownWorld[y] = {} end
  if self.knownWorld[y][x] == nil
    then
      self.knownWorld[y][x] = tileId
      self.nrTilesSeen=self.nrTilesSeen+1
      local tileName = getOverworldTileName(tileId)
      -- this print statement is important... but its so damn noisy.
      -- print ("discovered new tile at (x: " .. x .. ", y: " .. y .. ")" .. " tile is: " .. tileName .. " tile id is: " .. tileId)
      if tileId >= 8 and tileId <= 10 then
        print ("discovered important location at (x: " .. x .. ", y: " .. y .. ")" .. " it is a: " .. tileName)
        table.insert(self.importantLocations, ImportantLocation(x, y, tileId))
      end
  end
end

--         x,y-1
-- x-1,y   x,y     x+1,y
--         x,y+1
function OverWorld:neighbors(x,y)
  function isWalkable(x,y)
    if self.overworldRows[y] == nil then return false end
    if self.overworldRows[y][x] == nil then return false end
    return OVERWORLD_TILES[self.overworldRows[y][x]].walkable
  end
  local res = {}

  function insertNeighbor(x,y)
    table.insert(res,Neighbor(OverWorldId, x, y, NeighborType.SAME_MAP))
  end

  if x > 0   and isWalkable(x-1, y) then insertNeighbor(x-1, y) end
  if x < 119 and isWalkable(x+1, y) then insertNeighbor(x+1, y) end
  if y > 0   and isWalkable(x, y-1) then insertNeighbor(x, y-1) end
  if y < 119 and isWalkable(x, y+1) then insertNeighbor(x, y+1) end
  return res
end

function OverWorld:getKnownWorldTileAt(x,y)
  if self.knownWorld[y] == nil then return nil end
  return self.knownWorld[y][x]
end

-- TODO: we need to either change this function or create a new function
-- which returns us the "border + 1" ... that is... all the unseen tiles that surround this border
-- because we need to pick one of THOSE to walk to. not one of the ones that we've already seen.
-- returns all the walkable tiles on the border of the known world
function OverWorld:knownWorldBorder()
  local res = {}
  for y,row in pairs(self.knownWorld) do
    for x,tile in pairs(row) do
      local overworldTile = OVERWORLD_TILES[self.overworldRows[y][x]]
      if overworldTile.walkable then
        local nbrs = self:neighbors(x,y)
        -- TODO: potentially adding this more than once if more than one neighbor is nil
        for i = 1, #(nbrs) do
          local p = nbrs[i]
          if self:getKnownWorldTileAt(p.x,p.y) == nil then
            table.insert(res, Point(OverWorldId, x, y))
          end
        end
      end
    end
  end
  return res
end

-- returns a graph for all the tiles in the known world.
function OverWorld:knownWorldGraph()
  local res = {}
  for y,row in pairs(self.knownWorld) do
    for x,tile in pairs(row) do
      local overworldTile = OVERWORLD_TILES[self.overworldRows[y][x]]
      if overworldTile.walkable then
        if res[y] == nil then res[y] = {} end
        res[y][x] = self:neighbors(x,y)
      end
    end
  end
  return res
end

-- returns the tile id for the given (x,y) for the overworld
-- {["name"] = "Overworld", ["size"] = {120,120}, ["romAddr"] = {0x1D6D, 0x2668}},
function OverWorld:getOverworldMapTileIdAt(x, y)
  local tileId = self.overworldRows[y][x]
  -- optimization... each time we get a visible tile, record it in what we have seen
  self:updateKnownWorld(x,y,tileId)
  return tileId
end

function OverWorld:setOverworldMapTileIdAt(x, y, tileId)
  self.overworldRows[y][x] = tileId
end

-- this is always done from one tile right of where the brige will be
function OverWorld:useRainbowDrop(loc)
  self:setOverworldMapTileIdAt(loc.x - 1, loc.y, 0xB) -- 0xB is a bridge
end

function OverWorld:getVisibleOverworldGrid(currentX, currentY)
  local upperLeftX = math.max(0, currentX - 8)
  local upperLeftY = math.max(0, currentY - 6)

  local bottomRightX = math.min(119, currentX + 7)
  local bottomRightY = math.min(119, currentY + 7)

  local res = {}
  for y = upperLeftY, bottomRightY do
    res[y-upperLeftY] = {}
    for x = upperLeftX, bottomRightX do
      res[y-upperLeftY][x-upperLeftX]=self:getOverworldMapTileIdAt(x, y)
    end
  end
  return res
end

function OverWorld:printVisibleGrid (currentX, currentY)
  local grid = self:getVisibleOverworldGrid(currentX, currentY)
  for y = 0, #(grid) do
    local row = ""
    for x = 0, #(grid[y]) do
      row = row .. " | " .. getOverworldTileName(grid[y][x])
    end
    print(row .. " |")
  end
end
