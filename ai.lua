require 'mem'
require 'controller'
require 'enemies'
require 'helpers'
require 'hud'
require 'maps'

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

-- A thing draws near!
function onEncounter(address)
  local mapId = getMapId()
  if (mapId > 0) then
    print ("entering battle vs a " .. Enemies[getEnemyId()])
  end
end

function onPlayerMove(memory, overworld)
  return function(address)
    print("x: " .. memory:getX() .. " y: " .. memory:getY())
    -- todo: will have to fix this to check if on world map.
    overworld:printVisibleGrid(memory:getX(), memory:getY())
    print("percentageOfWorldSeen: " .. overworld:percentageOfWorldSeen())
  end
end

-------------------
---- MAIN LOOP ----
-------------------

function main()
  mem = Memory(memory, rom)
  overworld = OverWorld(readOverworldFromROM(mem))
  memory.registerexecute(0xcf44, onEncounter)
  memory.registerwrite(0x3a, onPlayerMove(mem, overworld))
  memory.registerwrite(0x3b, onPlayerMove(mem, overworld))

  hud_main()

  local charlock = readOtherMapFromRom(mem, 2):printMap()

--   runGameStartScript()

  emu.speedmode("normal")
  while true do
    emu.frameadvance()
  end
end

main ()