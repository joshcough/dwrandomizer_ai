require 'hud'

function readMemory(addr) return memory.readbyte(addr) end
function writeMemory(addr, value) memory.writebyte(addr, value) end

function readROM(addr) return rom.readbyte(addr) end
function writeROM(addr, value) rom.writebyte(addr, value) end

function bitwise_and(a, b)
  local result = 0
  local bitval = 1
  while a > 0 and b > 0 do
    if a % 2 == 1 and b % 2 == 1 then -- test the rightmost bits
      result = result + bitval -- set the current bit
    end
    bitval = bitval * 2 -- shift left
    a = math.floor(a/2) -- shift right
    b = math.floor(b/2)
  end
  return result
end

function decimalToHex(num)
    if num == 0 then
        return '0'
    end
    local neg = false
    if num < 0 then
        neg = true
        num = num * -1
    end
    local hexstr = "0123456789ABCDEF"
    local result = ""
    while num > 0 do
        local n = math.mod(num, 16)
        result = string.sub(hexstr, n + 1, n + 1) .. result
        num = math.floor(num / 16)
    end
    if neg then
        result = '-' .. result
    end
    return result
end

-- HI_NIBBLE(b) (((b) >> 4) & 0x0F)
function hiNibble(b) return bitwise_and(math.floor(b/16), 0x0F) end
-- LO_NIBBLE(b) (((b) & 0x0F)
function loNibble(b) return bitwise_and(b, 0x0F) end

function isEven(n) return n%2 == 0 end
function isOdd(n) return n%2 == 1 end

function table.shallow_copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

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

Enemies = {
  "Slime",  -- 0
  "Red Slime",
  "Drakee",
  "Ghost",
  "Magician",
  "Magidrakee", -- 5
  "Scorpion",
  "Druin",
  "Poltergeist",
  "Droll",
  "Drakeema",  --10
  "Skeleton",
  "Warlock",
  "Metal Scorpion",
  "Wolf",
  "Wraith",  --15
  "Metal Slime",
  "Specter",
  "Wolflord",
  "Druinlord",
  "Drollmagi",  --20
  "Wyvern",
  "Rogue Scorpion",
  "Wraith Knight",
  "Golem",
  "Goldman",  -- 25
  "Knight",
  "Magiwyvern",
  "Demon Knight",
  "Werewolf",
  "Green Dragon",  -- 30
  "Starwyvern",
  "Wizard",
  "Axe Knight",
  "Blue Dragon",
  "Stoneman", --35
  "Armored Knight",
  "Red Dragon",
  "Dragonlord",  --first form
  "Dragonlord"  --second form
}


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

OverworldTiles = {
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

-- 1D6D - 2662  | Overworld map          | RLE encoded, 1st nibble is tile, 2nd how many - 1
-- 2663 - 26DA  | Overworld map pointers | 16 bits each - address of each row of the map. (value - 0x8000 + 16)
function decodeWorldPointer (p)
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

function getWorldPointers ()
  local res = {}
  for i = 0,119 do
    res[i+1] = decodeWorldPointer(0x2663 + i * 2)
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

function getWorldRows ()
  local pointers = getWorldPointers()
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

WORLD_ROWS = getWorldRows()
KNOWN_WORLD = emptyWorldGrid()

MAX_TILES=14400
NR_TILES_SEEN=0
function updateKnownWorld(x,y, tileId)
  if KNOWN_WORLD[y+1][x+1] == false
    then
      KNOWN_WORLD[y+1][x+1] = tileId
      NR_TILES_SEEN=NR_TILES_SEEN+1
      print ("discovered new tile at (x: " .. x .. ", y: " .. y .. "), tile is: " .. OverworldTiles[tileId])
  end
end

function percentageOfWorldSeen()
  return NR_TILES_SEEN/MAX_TILES*100
end

-- returns the tile id for the given (x,y) for the overworld
-- {["name"] = "Overworld", ["size"] = {120,120}, ["romAddr"] = {0x1D6D, 0x2668}},
function getOverworldMapTileIdAt(x, y)
  local tileId = WORLD_ROWS[y+1][x+1]
  -- optimization... each time we get a visible tile, record it in what we have seen
  updateKnownWorld(x,y,tileId)
  return tileId
end

function getOverworldMapTileAt(x, y)
  return OverworldTiles[getOverworldMapTileIdAt(x, y)]
end

function getVisibleOverworldGrid()
  local upperLeftX = math.max(0, getX() - 8)
  local upperLeftY = math.max(0, getY() - 6)

  local bottomRightX = math.min(120, getX() + 7)
  local bottomRightY = math.min(120, getY() + 7)

  local res = {}
  for y = upperLeftY, bottomRightY do
    res[y-upperLeftY+1] = {}
    for x = upperLeftX, bottomRightX do
      res[y-upperLeftY+1][x-upperLeftX+1]=getOverworldMapTileIdAt(x, y)
    end
  end
  return res
end

function printVisibleGrid ()
  if getMapId() == 1 -- overworld
    then printVisibleOverworldGrid ()
  end
end

function printVisibleOverworldGrid ()
  local grid = getVisibleOverworldGrid()
  for y = 1, #(grid) do
    local row = ""
    for x = 1, #(grid[y]) do
      row = row .. " | " .. OverworldTiles[grid[y][x]]
    end
    print(row .. " |")
  end
  print("-------------------------")
end


emptyInputs = {
  ["start"] = nil,
  ["A"]     = nil,
  ["B"]     = nil,
  ["up"]    = nil,
  ["down"]  = nil,
  ["left"]  = nil,
  ["right"] = nil,
}

function waitFrames (n)
  for i = 1,n do
    emu.frameadvance();
  end
end

function pressButton (button, wait)
  print("Pressing " .. button)
  e = table.shallow_copy(emptyInputs)
  e[button] = true
  joypad.write(1, e)
  waitFrames(wait)
  joypad.write(1, emptyInputs)
  waitFrames(1)
end

function holdButton (button, frames)
  print("Holding " .. button)
  e = table.shallow_copy(emptyInputs)
  e[button] = true
  for i = 1,frames do
    joypad.write(1, e)
    emu.frameadvance();
  end
  joypad.write(1, emptyInputs)
  emu.frameadvance();
end

function pressStart (wait) pressButton("start", wait) end
function pressSelect (wait) pressButton("select", wait) end
function pressA (wait) pressButton("A", wait) end
function pressB (wait) pressButton("B", wait) end
function pressLeft (wait) pressButton("left", wait) end
function pressRight (wait) pressButton("right", wait) end
function pressUp (wait) pressButton("up", wait) end
function pressDown (wait) pressButton("down", wait) end

function holdStart (frames) holdButton("start", frames) end
function holdSelect (frames) holdButton("select", frames) end
function holdA (frames) holdButton("A", frames) end
function holdB (frames) holdButton("B", frames) end
function holdLeft (frames) holdButton("left", frames) end
function holdRight (frames) holdButton("right", frames) end
function holdUp (frames) holdButton("up", frames) end
function holdDown (frames) holdButton("down", frames) end

function openChest ()
  print("======opening chest=======")
  holdA(30)
  waitFrames(10)
  pressUp(2)
  pressRight(2)
  pressA(20)
end

function openDoor ()
  print("======opening door=======")
  holdA(30)
  waitFrames(10)
  pressDown(2)
  pressDown(2)
  pressRight(2)
  pressA(20)
end

function takeStairs ()
  print("======taking stairs=======")
  holdA(30)
  waitFrames(10)
  pressDown(2)
  pressDown(2)
  pressA(20)
end

function menuScript ()
  print("======executing menu script=======")
  pressStart(30)
  pressStart(30)
  pressA(30)
  pressA(30)
  pressDown(10)
  pressDown(10)
  pressRight(10)
  pressRight(10)
  pressRight(10)
  pressA(30)
  pressDown(10)
  pressDown(10)
  pressDown(10)
  pressRight(10)
  pressRight(10)
  pressRight(10)
  pressRight(10)
  pressA(30)
  pressUp(30)
  pressA(30)
end

function kingScript ()
  print("======executing king script=======")
  holdA(250)
end

function openThroneRoomChests ()
  print("======opening throne room chests=======")
  holdRight(10)
  openChest()
  holdRight(30)
  openChest()
  holdRight(60)
  holdUp(50)
  holdLeft(30)
  openChest()
end

function leaveThroneRoom()
  print("======leaving throne room=====")
  holdRight(60)
  holdDown(60)
  holdLeft(60)
  holdDown(30)
  openDoor()
  holdDown(30)
  holdLeft(45)
  takeStairs()
end

function leaveTantagelFromThroneRoomStairs()
  print("======leaving tantagel from throne room stairs=======")
  waitFrames(60)
  holdDown(30)
  holdLeft(30)
end

function throneRoomScript ()
  print("======executing throne room script=======")
  kingScript ()
  openThroneRoomChests()
  leaveThroneRoom()
end

function gameStartScript ()
  print("======executing game start script=======")
  menuScript()
  throneRoomScript()
  leaveTantagelFromThroneRoomStairs()
end

doneWithGameStart = false

function runGameStartScript ()
  if not doneWithGameStart
    then
      gameStartScript()
      doneWithGameStart = true
  end
end

function printTestData ()
  print("=============")
  print(getMapData())
  print(getXY())
  print(getMapTileIds())
  printMap()
end

function getEnemyId ()
  return memory.readbyte(0x3c)+1
end

-------------------
---- MAIN LOOP ----
-------------------


-- A thing draws near!
function encounter(address)
  local mapId = getMapId()
  if (mapId > 0) then
    print ("entering battle vs a " .. Enemies[getEnemyId()])
  end
end

-- DB10 - DB1F | "Return" placement code
-- 56080 - 56095
function setReturnWarpLocation(x, y)
  writeROM(0xDB15, x)
  writeROM(0xDB1D, y)
end

function playerMove(address)
  print("x: " .. getX() .. " y: " .. getY())
  -- todo: will have to fix this to check if on world map.
  printVisibleGrid()
  print("percentageOfWorldSeen: " .. percentageOfWorldSeen())
end

-- main loop
function main()
  emu.speedmode("normal")
  emu.print("test")
  memory.registerexecute(0xcf44, encounter)
  memory.registerwrite(0x3a, playerMove)
  memory.registerwrite(0x3b, playerMove)
  hud_main()

--   runGameStartScript()
  while true do
    emu.frameadvance()
  end
end

main ()