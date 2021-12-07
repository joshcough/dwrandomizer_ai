require 'helpers'
require 'Class'
require 'graph'
require 'locations'

-- MAP_DATA = {
--   [1] = {["name"] = "Overworld", ["size"] = {["w"]=120,["h"]=120}, ["romAddr"] = 0x1D6D},
-- }

OverworldTile = class(function(a,id,name,weight)
  a.id = id
  a.tileId = id
  a.name = name
  a.weight = weight
  a.walkable = weight ~= nil
end)

function OverworldTile:__tostring()
  local w = self.walkable and "true" or "false"
  return "{ tileId: " .. self.tileId .. ", name: " .. self.name
     .. ", walkable: " .. w .. ", weight: " .. self.weight .. "}"
end

GrassId    = 0
DesertId   = 1
HillsId    = 2
MountainId = 3
WaterId    = 4
StoneId    = 5
ForestId   = 6
SwampId    = 7
TownId     = 8
CaveId     = 9
CastleId   = 10
BridgeId   = 11
StairsId   = 12

Grass    = OverworldTile(GrassId,    "Grass   ", 1)    -- "🟩",
Desert   = OverworldTile(DesertId,   "Desert  ", 5)    -- "🏜",
Hills    = OverworldTile(HillsId,    "Hills   ", 2)    -- "🏞"
Mountain = OverworldTile(MountainId, "Mountain", nil)  -- "⛰",
Water    = OverworldTile(WaterId,    "Water   ", nil)  -- "🌊",
Stone    = OverworldTile(StoneId,    "Stone   ", nil)  -- "⬛",
Forest   = OverworldTile(ForestId,   "Forest  ", 2)    -- "🌳",
Swamp    = OverworldTile(SwampId,    "Swamp   ", 20)
Town     = OverworldTile(TownId,     "Town    ", 1000)
Cave     = OverworldTile(CaveId,     "Cave    ", 1000)
Castle   = OverworldTile(CastleId,   "Castle  ", 1000) -- "🏰"
Bridge   = OverworldTile(BridgeId,   "Bridge  ", 1)    -- "🌉",
Stairs   = OverworldTile(StairsId,   "Stairs  ", 1)

OVERWORLD_TILES = {
  [Grass.id]    = Grass,
  [Desert.id]   = Desert,
  [Hills.id]    = Hills,
  [Mountain.id] = Mountain,
  [Water.id]    = Water,
  [Stone.id]    = Stone,
  [Forest.id]   = Forest,
  [Swamp.id]    = Swamp,
  [Town.id]     = Town,
  [Cave.id]     = Cave,
  [Castle.id]   = Castle,
  [Bridge.id]   = Bridge,
  [Stairs.id]   = Stairs,
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
end)

function OverWorld:percentageOfWorldSeen()
  return self.nrTilesSeen/MAX_TILES*100
end

function OverWorld:getTileAt(x, y, game)
  -- log.debug("OverWorld:getTileAt(x, y, game)", x, y)
  return OVERWORLD_TILES[self:getTileIdAt(x, y, game)]
end

function OverWorld:getTileAt_NoUpdate(x, y)
  return OVERWORLD_TILES[self.overworldRows[y][x]]
end

function OverWorld:updateKnownWorld(x, y, tileId, game)
  if self.knownWorld[y] == nil then self.knownWorld[y] = {} end
  if self.knownWorld[y][x] == nil
    then
      self.knownWorld[y][x] = tileId
      self.nrTilesSeen=self.nrTilesSeen+1
      game:discoverOverworldTile(x, y)
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

  function insertNeighbor(x,y,dir)
    table.insert(res,Neighbor(OverWorldId, x, y, dir))
  end

  if x > 0   and isWalkable(x-1, y) then insertNeighbor(x-1, y, NeighborDir.LEFT) end
  if x < 119 and isWalkable(x+1, y) then insertNeighbor(x+1, y, NeighborDir.RIGHT) end
  if y > 0   and isWalkable(x, y-1) then insertNeighbor(x, y-1, NeighborDir.UP) end
  if y < 119 and isWalkable(x, y+1) then insertNeighbor(x, y+1, NeighborDir.DOWN) end
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
          -- this is saying: if one of your neighbors is nil
          -- then YOU are on the border. you are a border tile.
          -- because you bump up against the unknown, basically.
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
function OverWorld:getTileIdAt(x, y, game)
  -- log.debug("OverWorld:getTileIdAt", x, y)
  local tileId = self.overworldRows[y][x]
  -- optimization... each time we get a visible tile, record it in what we have seen
  self:updateKnownWorld(x, y, tileId, game)
  return tileId
end

-- TODO: big TODO... we need to update the graph when we do this.
-- we only currently call this function when we use the rainbow drop
-- maybe we can just get rid of it altogether, but, probably not.
-- because sometimes we check the map to see what tile is there.
function OverWorld:setOverworldMapTileIdAt(x, y, tileId, game)
  self.overworldRows[y][x] = tileId
end

-- this is always done from one tile right of where the bridge will be
function OverWorld:useRainbowDrop(loc, game)
  self:setOverworldMapTileIdAt(loc.x - 1, loc.y, 0xB, game) -- 0xB is a bridge
end

function OverWorld:getVisibleOverworldGrid(currentX, currentY, game)
  -- log.debug("in getVisibleOverworldGrid", currentX, currentY)
  local upperLeftX = math.max(0, currentX - 8)
  local upperLeftY = math.max(0, currentY - 6)

  local bottomRightX = math.min(119, currentX + 7)
  local bottomRightY = math.min(119, currentY + 7)

  local res = {}
  for y = upperLeftY, bottomRightY do
    res[y-upperLeftY] = {}
    for x = upperLeftX, bottomRightX do
      res[y-upperLeftY][x-upperLeftX]=self:getTileIdAt(x, y, game)
    end
  end
  return res
end

function OverWorld:printVisibleGrid (currentX, currentY, game)
  local grid = self:getVisibleOverworldGrid(currentX, currentY, game)
  for y = 0, #(grid) do
    local row = ""
    for x = 0, #(grid[y]) do
      row = row .. " | " .. getOverworldTileName(grid[y][x])
    end
    log.debug(row .. " |")
  end
end
