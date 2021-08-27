require 'helpers'
require 'Class'

Overworld = 1
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

FORWARD_WARPS = {
  {["srcMapId"] = 2, ["srcX"] = 10, ["srcY"] = 1, ["destMapId"] = 15, ["destX"] = 9, ["destY"] = 0}
, {["srcMapId"] = 2, ["srcX"] = 4, ["srcY"] = 14, ["destMapId"] = 15, ["destX"] = 8, ["destY"] = 13}
, {["srcMapId"] = 2, ["srcX"] = 15, ["srcY"] = 14, ["destMapId"] = 15, ["destX"] = 17, ["destY"] = 15}
-- TODO: this one is bad because it isn't 12,0,4
-- really, we can only actually fill this in once we discover where it goes
-- by taking the stairs downwards.
-- TODO: this is also true with garin's grave.
, {["srcMapId"] = 4, ["srcX"] = 29, ["srcY"] = 29, ["destMapId"] = 12, ["destX"] = 0, ["destY"] = 4}
, {["srcMapId"] = 5, ["srcX"] = 1, ["srcY"] = 8, ["destMapId"] = 4, ["destX"] = 1, ["destY"] = 7}
, {["srcMapId"] = 5, ["srcX"] = 8, ["srcY"] = 8, ["destMapId"] = 4, ["destX"] = 7, ["destY"] = 7}
-- 9 = garinham, 24 = GarinsGrave
, {["srcMapId"] = 9, ["srcX"] = 19, ["srcY"] = 0, ["destMapId"] = 24, ["destX"] = 6, ["destY"] = 11}
, {["srcMapId"] = 15, ["srcX"] = 15, ["srcY"] = 1, ["destMapId"] = 16, ["destX"] = 8, ["destY"] = 0}
, {["srcMapId"] = 15, ["srcX"] = 13, ["srcY"] = 7, ["destMapId"] = 16, ["destX"] = 4, ["destY"] = 4}
, {["srcMapId"] = 15, ["srcX"] = 19, ["srcY"] = 7, ["destMapId"] = 16, ["destX"] = 9, ["destY"] = 8}
, {["srcMapId"] = 15, ["srcX"] = 14, ["srcY"] = 9, ["destMapId"] = 16, ["destX"] = 8, ["destY"] = 9}
, {["srcMapId"] = 15, ["srcX"] = 2, ["srcY"] = 14, ["destMapId"] = 16, ["destX"] = 0, ["destY"] = 1}
, {["srcMapId"] = 15, ["srcX"] = 2, ["srcY"] = 4, ["destMapId"] = 16, ["destX"] = 0, ["destY"] = 0}
, {["srcMapId"] = 15, ["srcX"] = 8, ["srcY"] = 19, ["destMapId"] = 16, ["destX"] = 5, ["destY"] = 0}
, {["srcMapId"] = 16, ["srcX"] = 3, ["srcY"] = 0, ["destMapId"] = 17, ["destX"] = 7, ["destY"] = 0}
, {["srcMapId"] = 16, ["srcX"] = 9, ["srcY"] = 1, ["destMapId"] = 17, ["destX"] = 2, ["destY"] = 2}
, {["srcMapId"] = 16, ["srcX"] = 0, ["srcY"] = 8, ["destMapId"] = 17, ["destX"] = 5, ["destY"] = 4}
, {["srcMapId"] = 16, ["srcX"] = 1, ["srcY"] = 9, ["destMapId"] = 17, ["destX"] = 0, ["destY"] = 9}
, {["srcMapId"] = 17, ["srcX"] = 1, ["srcY"] = 6, ["destMapId"] = 18, ["destX"] = 0, ["destY"] = 9}
, {["srcMapId"] = 17, ["srcX"] = 7, ["srcY"] = 7, ["destMapId"] = 18, ["destX"] = 7, ["destY"] = 7}
, {["srcMapId"] = 18, ["srcX"] = 2, ["srcY"] = 2, ["destMapId"] = 19, ["destX"] = 9, ["destY"] = 0}
, {["srcMapId"] = 18, ["srcX"] = 8, ["srcY"] = 1, ["destMapId"] = 19, ["destX"] = 4, ["destY"] = 0}
, {["srcMapId"] = 19, ["srcX"] = 5, ["srcY"] = 5, ["destMapId"] = 20, ["destX"] = 0, ["destY"] = 0}
, {["srcMapId"] = 19, ["srcX"] = 0, ["srcY"] = 0, ["destMapId"] = 20, ["destX"] = 0, ["destY"] = 6}
, {["srcMapId"] = 20, ["srcX"] = 9, ["srcY"] = 0, ["destMapId"] = 20, ["destX"] = 0, ["destY"] = 0}
, {["srcMapId"] = 20, ["srcX"] = 9, ["srcY"] = 6, ["destMapId"] = 6, ["destX"] = 10, ["destY"] = 29}
, {["srcMapId"] = 22, ["srcX"] = 0, ["srcY"] = 0, ["destMapId"] = 23, ["destX"] = 0, ["destY"] = 0}
, {["srcMapId"] = 22, ["srcX"] = 6, ["srcY"] = 5, ["destMapId"] = 23, ["destX"] = 6, ["destY"] = 5}
, {["srcMapId"] = 22, ["srcX"] = 12, ["srcY"] = 12, ["destMapId"] = 23, ["destX"] = 12, ["destY"] = 12}
, {["srcMapId"] = 24, ["srcX"] = 1, ["srcY"] = 18, ["destMapId"] = 25, ["destX"] = 11, ["destY"] = 2}
, {["srcMapId"] = 25, ["srcX"] = 1, ["srcY"] = 1, ["destMapId"] = 26, ["destX"] = 1, ["destY"] = 26}
, {["srcMapId"] = 25, ["srcX"] = 12, ["srcY"] = 1, ["destMapId"] = 26, ["destX"] = 18, ["destY"] = 1}
, {["srcMapId"] = 25, ["srcX"] = 5, ["srcY"] = 6, ["destMapId"] = 26, ["destX"] = 6, ["destY"] = 11}
, {["srcMapId"] = 25, ["srcX"] = 1, ["srcY"] = 10, ["destMapId"] = 26, ["destX"] = 2, ["destY"] = 17}
, {["srcMapId"] = 25, ["srcX"] = 12, ["srcY"] = 10, ["destMapId"] = 26, ["destX"] = 18, ["destY"] = 13}
, {["srcMapId"] = 26, ["srcX"] = 9, ["srcY"] = 5, ["destMapId"] = 27, ["destX"] = 0, ["destY"] = 4}
, {["srcMapId"] = 26, ["srcX"] = 10, ["srcY"] = 9, ["destMapId"] = 27, ["destX"] = 5, ["destY"] = 4}
, {["srcMapId"] = 28, ["srcX"] = 9, ["srcY"] = 9, ["destMapId"] = 29, ["destX"] = 8, ["destY"] = 9}
}

REVERSE_WARPS = {
  {["srcMapId"] = 15, ["srcX"] = 9, ["srcY"] = 0, ["destMapId"] = 2, ["destX"] = 10, ["destY"] = 1}
, {["srcMapId"] = 15, ["srcX"] = 8, ["srcY"] = 13, ["destMapId"] = 2, ["destX"] = 4, ["destY"] = 14}
, {["srcMapId"] = 15, ["srcX"] = 17, ["srcY"] = 15, ["destMapId"] = 2, ["destX"] = 15, ["destY"] = 14}
-- TODO: this one is bad because it isn't 12,0,4
, {["srcMapId"] = 12, ["srcX"] = 0, ["srcY"] = 4, ["destMapId"] = 4, ["destX"] = 29, ["destY"] = 29}
, {["srcMapId"] = 4, ["srcX"] = 7, ["srcY"] = 7, ["destMapId"] = 5, ["destX"] = 8, ["destY"] = 8}
-- 9 = garinham, 24 = GarinsGrave
, {["srcMapId"] = 24, ["srcX"] = 6, ["srcY"] = 11, ["destMapId"] = 9, ["destX"] = 19, ["destY"] = 0}
, {["srcMapId"] = 16, ["srcX"] = 8, ["srcY"] = 0, ["destMapId"] = 15, ["destX"] = 15, ["destY"] = 1}
, {["srcMapId"] = 16, ["srcX"] = 4, ["srcY"] = 4, ["destMapId"] = 15, ["destX"] = 13, ["destY"] = 7}
, {["srcMapId"] = 16, ["srcX"] = 9, ["srcY"] = 8, ["destMapId"] = 15, ["destX"] = 19, ["destY"] = 7}
, {["srcMapId"] = 16, ["srcX"] = 8, ["srcY"] = 9, ["destMapId"] = 15, ["destX"] = 14, ["destY"] = 9}
, {["srcMapId"] = 16, ["srcX"] = 0, ["srcY"] = 1, ["destMapId"] = 15, ["destX"] = 2, ["destY"] = 14}
, {["srcMapId"] = 16, ["srcX"] = 0, ["srcY"] = 0, ["destMapId"] = 15, ["destX"] = 2, ["destY"] = 4}
, {["srcMapId"] = 16, ["srcX"] = 5, ["srcY"] = 0, ["destMapId"] = 15, ["destX"] = 8, ["destY"] = 19}
, {["srcMapId"] = 17, ["srcX"] = 7, ["srcY"] = 0, ["destMapId"] = 16, ["destX"] = 3, ["destY"] = 0}
, {["srcMapId"] = 17, ["srcX"] = 2, ["srcY"] = 2, ["destMapId"] = 16, ["destX"] = 9, ["destY"] = 1}
, {["srcMapId"] = 17, ["srcX"] = 5, ["srcY"] = 4, ["destMapId"] = 16, ["destX"] = 0, ["destY"] = 8}
, {["srcMapId"] = 17, ["srcX"] = 0, ["srcY"] = 9, ["destMapId"] = 16, ["destX"] = 1, ["destY"] = 9}
, {["srcMapId"] = 18, ["srcX"] = 0, ["srcY"] = 9, ["destMapId"] = 17, ["destX"] = 1, ["destY"] = 6}
, {["srcMapId"] = 18, ["srcX"] = 7, ["srcY"] = 7, ["destMapId"] = 17, ["destX"] = 7, ["destY"] = 7}
, {["srcMapId"] = 19, ["srcX"] = 9, ["srcY"] = 0, ["destMapId"] = 18, ["destX"] = 2, ["destY"] = 2}
, {["srcMapId"] = 19, ["srcX"] = 4, ["srcY"] = 0, ["destMapId"] = 18, ["destX"] = 8, ["destY"] = 1}
, {["srcMapId"] = 20, ["srcX"] = 0, ["srcY"] = 0, ["destMapId"] = 19, ["destX"] = 5, ["destY"] = 5}
, {["srcMapId"] = 20, ["srcX"] = 0, ["srcY"] = 6, ["destMapId"] = 19, ["destX"] = 0, ["destY"] = 0}
, {["srcMapId"] = 20, ["srcX"] = 0, ["srcY"] = 0, ["destMapId"] = 20, ["destX"] = 9, ["destY"] = 0}
, {["srcMapId"] = 6, ["srcX"] = 10, ["srcY"] = 29, ["destMapId"] = 20, ["destX"] = 9, ["destY"] = 6}
, {["srcMapId"] = 23, ["srcX"] = 0, ["srcY"] = 0, ["destMapId"] = 22, ["destX"] = 0, ["destY"] = 0}
, {["srcMapId"] = 23, ["srcX"] = 6, ["srcY"] = 5, ["destMapId"] = 22, ["destX"] = 6, ["destY"] = 5}
, {["srcMapId"] = 23, ["srcX"] = 12, ["srcY"] = 12, ["destMapId"] = 22, ["destX"] = 12, ["destY"] = 12}
, {["srcMapId"] = 25, ["srcX"] = 11, ["srcY"] = 2, ["destMapId"] = 24, ["destX"] = 1, ["destY"] = 18}
, {["srcMapId"] = 26, ["srcX"] = 1, ["srcY"] = 26, ["destMapId"] = 25, ["destX"] = 1, ["destY"] = 1}
, {["srcMapId"] = 26, ["srcX"] = 18, ["srcY"] = 1, ["destMapId"] = 25, ["destX"] = 12, ["destY"] = 1}
, {["srcMapId"] = 26, ["srcX"] = 6, ["srcY"] = 11, ["destMapId"] = 25, ["destX"] = 5, ["destY"] = 6}
, {["srcMapId"] = 26, ["srcX"] = 2, ["srcY"] = 17, ["destMapId"] = 25, ["destX"] = 1, ["destY"] = 10}
, {["srcMapId"] = 26, ["srcX"] = 18, ["srcY"] = 13, ["destMapId"] = 25, ["destX"] = 12, ["destY"] = 10}
, {["srcMapId"] = 27, ["srcX"] = 0, ["srcY"] = 4, ["destMapId"] = 26, ["destX"] = 9, ["destY"] = 5}
, {["srcMapId"] = 27, ["srcX"] = 5, ["srcY"] = 4, ["destMapId"] = 26, ["destX"] = 10, ["destY"] = 9}
, {["srcMapId"] = 29, ["srcX"] = 8, ["srcY"] = 9, ["destMapId"] = 28, ["destX"] = 9, ["destY"] = 9}
}

WARPS = table.concat(FORWARD_WARPS, REVERSE_WARPS)

function getWarpsForMap(mapId)
  local res = {}
  for _,v in ipairs(WARPS) do
    if(v["srcMapId"] == mapId) then
      if res[v["srcX"]] == nil then  res[v["srcX"]] = {} end
      if res[v["srcX"]][v["srcY"]] == nil then res[v["srcX"]][v["srcY"]] = {} end
      table.insert(res[v["srcX"]][v["srcY"]], Point3D(v["destMapId"], v["destX"], v["destY"]))
    end
  end
  return res
end

MAP_DATA = {
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

NON_DUNGEON_TILES = {
  [0]   = {["name"] = "Grass ", ["walkable"] = true },
  [1]   = {["name"] = "Sand  ", ["walkable"] = true },
  [2]   = {["name"] = "Water ", ["walkable"] = false },
  [3]   = {["name"] = "Chest ", ["walkable"] = true },
  [4]   = {["name"] = "Stone ", ["walkable"] = false },
  [5]   = {["name"] = "Up    ", ["walkable"] = true },
  [6]   = {["name"] = "Brick ", ["walkable"] = true },
  [7]   = {["name"] = "Down  ", ["walkable"] = true },
  [8]   = {["name"] = "Trees ", ["walkable"] = true },
  [9]   = {["name"] = "Swamp ", ["walkable"] = true },
  [0xA] = {["name"] = "Field ", ["walkable"] = true },
  [0xB] = {["name"] = "Door  ", ["walkable"] = false, ["walkableWithKeys"] = true },
  [0xC] = {["name"] = "Weapon", ["walkable"] = false },
  [0xD] = {["name"] = "Inn   ", ["walkable"] = false },
  [0xE] = {["name"] = "Bridge", ["walkable"] = true },
  [0xF] = {["name"] = "Tile  ", ["walkable"] = false },
}

DUNGEON_TILES = {
  [0]   = {["name"] = "Stone", ["walkable"] = false },
  [1]   = {["name"] = "Up   ", ["walkable"] = true },
  [2]   = {["name"] = "Brick", ["walkable"] = true },
  [3]   = {["name"] = "Down ", ["walkable"] = true },
  [4]   = {["name"] = "Chest", ["walkable"] = true },
  [5]   = {["name"] = "Door ", ["walkable"] = false, ["walkableWithKeys"] = true },
  -- in swamp cave, we get id six where the princess is. its the only 6 we get in any dungeon.
  [6]   = {["name"] = "Brick",  ["walkable"] = true },
}

OVERWORLD_TILES = {
  [0]   = {["name"] = "Grass   ", ["walkable"] = true },
  [1]   = {["name"] = "Desert  ", ["walkable"] = true },
  [2]   = {["name"] = "Hills   ", ["walkable"] = true },
  [3]   = {["name"] = "Mountain", ["walkable"] = false },
  [4]   = {["name"] = "Water   ", ["walkable"] = false },
  [5]   = {["name"] = "Stone   ", ["walkable"] = false },
  [6]   = {["name"] = "Forest  ", ["walkable"] = true },
  [7]   = {["name"] = "Swamp   ", ["walkable"] = true },
  [8]   = {["name"] = "Town    ", ["walkable"] = true },
  [9]   = {["name"] = "Cave    ", ["walkable"] = true },
  [0xA] = {["name"] = "Castle  ", ["walkable"] = true },
  [0xB] = {["name"] = "Bridge  ", ["walkable"] = true },
  [0xC] = {["name"] = "Stairs  ", ["walkable"] = true },
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
  a.warps = getWarpsForMap(mapId)
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
      then return t["name"]
      else
        if printStrat == PRINT_TILE_NO_KEYS
          then return t["walkable"] and "O" or " "
          else return (t["walkableWithKeys"] or t["walkable"]) and "O" or " "
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

-- this second argument just makes the map easier to see when i print it out
function StaticMap:mkGraph (haveKeys)
  local tileSet = self:getTileSet()

  function isWalkable(x,y)
    local t = tileSet[self.rows[y][x]]
    return haveKeys and (t["walkableWithKeys"] or t["walkable"]) or t["walkable"]
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
        for _, v in pairs(self.warps[x][y]) do table.insert(res, v)  end
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

function Graph:graphToString ()

  function contains(list, x)
    return table.contains(list, x, function(v1, v2) return v1:equals(v2) end)
  end

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
      row = row .. "|" .. printTile(x, y, graph[y][x])
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

function quickPrintGraph(mapId)
  print(loadStaticMapFromFile(mapId):mkGraph(false))
  print(loadStaticMapFromFile(mapId):mkGraph(true))
end

function loadStaticMapFromFile (mapId)
  local mapData = MAP_DATA[mapId]
  local mapName = mapData["name"]
  local mapFileName = MAP_DIRECTORY .. mapName
  return StaticMap(mapId, mapName, mapData["size"]["w"], mapData["size"]["h"], table.load(mapFileName))
end

function readAllStaticMaps(memory)
  res = {}
  for i = 2, 29 do
    res[i] = memory == nil and loadStaticMapFromFile(i) or readStaticMapFromRom(memory, i)
  end
  return res
end

function giantGraph(maps)
  res = {}
  for i = 2, 29 do
    local g = maps[i]:mkGraph(true)
    res[i] = g
  end
  return res
end

function saveStaticMaps(memory)
  local file = io.open(STATIC_MAPS_FILE, "w")
  local maps = readAllStaticMaps(memory)
  for i = 2, 29 do
    maps[i]:writeTileNamesToFile(file)
    maps[i]:saveIdsToFile()
    maps[i]:saveGraphToFile()
  end
  file:close()
end

function readStaticMapFromRom(memory, mapId)
  local mapData = MAP_DATA[mapId]
  local mapSize = mapData["size"]
  local width = mapSize["w"]
  local height = mapSize["h"]
  local startAddr = mapData["romAddr"]

  -- returns the tile id for the given (x,y) for the current map
  function getMapTileIdAt(x, y)
    local offset = (y*width) + x
    local addr = startAddr + math.floor(offset/2)
    local val = memory:readROM(addr)
    local tile = isEven(offset) and hiNibble(val) or loNibble(val)
    -- TODO: i tried to use 0x111 but it went insane... so just using 7 instead.
    return mapId < 12 and tile or bitwise_and(tile, 7)
  end

  -- returns a two dimensional grid of tile ids for the current map
  function getMapTileIds ()
    local res = {}
    for y = 0, height-1 do
      res[y] = {}
      for x = 0, width-1 do
        res[y][x]=getMapTileIdAt(x,y)
      end
    end
    return res
  end

  return StaticMap(mapId, mapData["name"], width, height, getMapTileIds())
end
