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

function getEnemyId ()
  return memory.readbyte(0x3c)+1
end

-- DB10 - DB1F | "Return" placement code
-- 56080 - 56095
function setReturnWarpLocation(x, y)
  writeROM(0xDB15, x)
  writeROM(0xDB1D, y)
end

-- A thing draws near!
function onEncounter(address)
  local mapId = getMapId()
  if (mapId > 0) then
    print ("entering battle vs a " .. Enemies[getEnemyId()])
  end
end

function onPlayerMove(address)
  print("x: " .. getX() .. " y: " .. getY())
  -- todo: will have to fix this to check if on world map.
  printVisibleGrid()
  print("percentageOfWorldSeen: " .. percentageOfWorldSeen())
end

-------------------
---- MAIN LOOP ----
-------------------

function main()
  emu.speedmode("normal")
  memory.registerexecute(0xcf44, onEncounter)
  memory.registerwrite(0x3a, onPlayerMove)
  memory.registerwrite(0x3b, onPlayerMove)
  hud_main()

--   runGameStartScript()
  while true do
    emu.frameadvance()
  end
end

main ()