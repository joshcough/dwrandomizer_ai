require 'mem'
require 'Class'
require 'controller'
require 'enemies'
require 'game'
require 'helpers'
require 'hud'
require 'overworld'
require 'static_maps'

AI = class(function(a, game)
  a.game = game
end)

-- A thing draws near!
function AI:onEncounter()
  return function(address)
    self.game:startEncounter()
  end
end

function AI:explore() self.game:explore() end

function AI:stateMachine()
  if self.game.in_battle then
    self:executeBattle()
  else
    print("not in battle, going to explore")
    self:explore()
    print("done with call to explore...")
  end
end

function AI:executeBattle()
  self.game:executeBattle()
end

function AI:enemyRun()
  return function(address)
    self.game:enemyRun()
  end
end

function AI:playerRun()
  return function(address)
    self.game:playerRun()
  end
end

function AI:onPlayerMove()
  return function(address)
    self.game:onPlayerMove()
  end
end

function AI:register(memory)
  memory.registerexecute(0xcf44, self:onEncounter())
  memory.registerexecute(0xefc8, self:enemyRun())
  memory.registerexecute(0xe8a4, self:playerRun())
  memory.registerwrite(0x3a, self:onPlayerMove())
  memory.registerwrite(0x3b, self:onPlayerMove())
end

-------------------
---- MAIN LOOP ----
-------------------

function main()
  hud_main()

  -- give ourself gold, xp, best equipment, etc
  memory.writebyte(0xbb, 65535 / 256)
  memory.writebyte(0xba, 65535 % 256)
  memory.writebyte(0xbe, 255) -- best equipment
  memory.writebyte(0xbf, 6)   -- 6 herbs
  memory.writebyte(0xc0, 6)   -- 6 keys
  memory.writebyte(0xc1, 14)  -- rainbow drop

  local mem = Memory(memory, rom)
  -- always save the maps man. if we dont do this
  -- we start getting out of date and bad stuff happens.
  saveStaticMaps(mem, table.concat(WARPS, list.map(WARPS, swapSrcAndDest)))

  local game = newGame(mem)
  local ai = AI(game)
  ai:register(memory)

  -- TODO: this is a hack
  -- right now this gets called when we move
  -- but we need to call it here once before we move, too.
  game.overworld:getVisibleOverworldGrid(game:getX(), game:getY())

  emu.speedmode("normal")
  while true do
    ai:stateMachine()
    emu.frameadvance()
  end
end

-- for some reason you have to do this trash before actually getting random numbers
-- https://stackoverflow.com/questions/20154991/generating-uniform-random-numbers-in-lua
math.randomseed(os.time()); math.random()

main()

-- oldish stuff that i need to evaluate if i really want to keep
-- game:cast(Repel)
--     local spells = game.memory:readPlayerData().spells
--     print(spells:spellIndex(Healmore))

-- game:gameStartScript()
--   print(game:readPlayerData())
--   game:goTo(Point(Tantegel, 29,29))
--   game:takeStairs(Point(Tantegel, 29,29))
--   game:goTo(Point(TantegelThroneRoom, 3,4))

--   print(game.memory:readPlayerData().items:hasFairyFlute())

-- i run this each time to make sure nothing has changed.
-- if anything changes, git will tell me.
-- saveStaticMaps(mem, warps)

-- i print this out just to make sure things look sane when i start the script.
-- table.print(shortestPath(Point(TantegelThroneRoom, 1,1), Point(TantegelThroneRoom, 1,8), true, graphs))
-- can also do this, which loads the maps from files instead of memory:
-- table.print(shortestPath(Point(TantegelThroneRoom, 1,1), Point(TantegelThroneRoom, 1,8), true))
-- table.print(shortestPath(Point(Charlock, 10,19), Point(CharlockThroneRoom, 17,24), true))

