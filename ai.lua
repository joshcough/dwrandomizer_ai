require 'mem'
require 'controller'
require 'enemies'
require 'game'
require 'helpers'
require 'hud'
require 'overworld'
require 'static_maps'

in_battle2 = false

-- A thing draws near!
function onEncounter2(memory)
  return function(address)
    if (memory:getMapId() > 0) then
      enemyId = memory:getEnemyId()
      print ("entering battle vs a " .. Enemies[enemyId])
      -- actually, set every encounter to a red slime. lol!
      memory:setEnemyId(0)
      in_battle2 = true
    end
  end
end

function executeBattle()
 if (emu.framecount() % 15 == 0) then
    -- print("in_battle2: ", in_battle2)
    if(in_battle2) then
      holdA(240)
      waitFrames(60)
      pressA(10)
      in_battle2 = false
    end
  end
end

function onPlayerMove(memory, overworld)
  return function(address)
--     print("current location", memory:getLocation())
    if memory:getMapId() == 1
      then
        overworld:printVisibleGrid(memory:getX(), memory:getY())
        print("percentageOfWorldSeen: " .. overworld:percentageOfWorldSeen())
    end
  end
end

-------------------
---- MAIN LOOP ----
-------------------

function main()
  hud_main()

  local mem = Memory(memory, rom)
  local overworld = OverWorld(readOverworldFromROM(mem))
  local warps = table.concat(WARPS, list.map(WARPS, swapSrcAndDest))
  local game = Game(mem, warps)

  memory.registerexecute(0xcf44, onEncounter2(mem))
  memory.registerwrite(0x3a, onPlayerMove(mem, overworld))
  memory.registerwrite(0x3b, onPlayerMove(mem, overworld))

  -- i run this each time to make sure nothing has changed.
  -- if anything changes, git will tell me.
  -- saveStaticMaps(mem, warps)

  -- game:gameStartScript()
--   game:goTo(Point(Tantegel, 29,29))
--   game:takeStairs(Point(Tantegel, 29,29))
--   game:goTo(Point(TantegelThroneRoom, 3,4))

  emu.speedmode("normal")
  while true do
    -- this only happens if we are actually in battle.
    executeBattle()
    emu.frameadvance()
  end
end

main()

-- oldish stuff that i need to evaluate if i really want to keep
-- i print this out just to make sure things look sane when i start the script.
-- table.print(shortestPath(Point(TantegelThroneRoom, 1,1), Point(TantegelThroneRoom, 1,8), true, graphs))
-- can also do this, which loads the maps from files instead of memory:
-- table.print(shortestPath(Point(TantegelThroneRoom, 1,1), Point(TantegelThroneRoom, 1,8), true))
-- table.print(shortestPath(Point(Charlock, 10,19), Point(CharlockThroneRoom, 17,24), true))

