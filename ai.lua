require 'mem'
require 'Class'
require 'controller'
require 'enemies'
require 'game'
require 'helpers'
require 'hud'
require 'map_scripts'
require 'overworld'
require 'static_maps'

-- TODO:
-- Damage calculation is:
-- (atkpwr-(enemy agi/2))/4 through (atkpwr-(enemy agi/2))/2

AI = class(function(a, game) a.game = game end)

function AI:onEncounter()   return function(address) self.game:startEncounter() end end
function AI:enemyRun()      return function(address) self.game:enemyRun() end end
function AI:playerRun()     return function(address) self.game:playerRun() end end
function AI:onPlayerMove()  return function(address) self.game:onPlayerMove() end end
function AI:onMapChange()   return function(address) self.game:onMapChange() end end
function AI:endRepelTimer() return function(address) self.game:endRepelTimer() end end

function AI:register(memory)
  memory.registerexecute(0xcf44, self:onEncounter())
  memory.registerexecute(0xefc8, self:enemyRun())
  memory.registerexecute(0xe8a4, self:playerRun())
  memory.registerwrite  (0x3a,   self:onPlayerMove())
  memory.registerwrite  (0x3b,   self:onPlayerMove())
  memory.registerwrite  (0x45,   self:onMapChange())
  memory.registerexecute(0xca83, self:endRepelTimer())
end

-- TODO: obviously this will be removed later
-- but for now it just helps me survive to test exploration
-- give ourself gold, xp, best equipment, etc
function cheat(mem)
  mem:writeRAM(0xbb, 65535 / 256)
  mem:writeRAM(0xba, 65535 % 256)
  mem:writeRAM(0xbe, 255) -- best equipment
  -- mem:writeRAM(0xbe, 0) -- no equipment
  mem:writeRAM(0xbf, 5)   -- 5 herbs
  mem:writeRAM(0xc0, 5)   -- 5 keys
  -- mem:writeRAM(0xc1, RainbowDropByte)
  -- mem:writeRAM(0xc1, SilverHarpByte)
end

-------------------
---- MAIN LOOP ----
-------------------

function main()
  hud_main()

  local mem = Memory(memory, rom)
  cheat(mem)

  -- always save the maps man. if we dont do this
  -- we start getting out of date and bad stuff happens.
  saveStaticMaps(mem, table.concat(WARPS, list.map(WARPS, swapSrcAndDest)))

  local game = newGame(mem)
  local ai = AI(game)
  ai:register(memory)

  -- TODO: this is a hack
  -- right now this gets called when we move
  -- but we need to call it here once before we move, too.
--   if(game:getLocation().mapId == 1) then
--     game.overworld:getVisibleOverworldGrid(game:getX(), game:getY())
--   end

--   mem:printNPCs()
--   print(game.playerData)
--   print(game.weaponAndArmorShops)
--   print(game.searchSpots)
--   print(game.chests)

  emu.speedmode("normal")
  while true do
    game:stateMachine()
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
--   game:interpretScript(scripts.throneRoomOpeningGameScript())
--   mem:setReturnWarpLocation(30,83) -- tangegel

-- game:gameStartScript()
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

-- These are some cool things, but, I don't think I actually really need them
-- so just dumping them here.

--   -- .alias RadiantTimer     $DA     ;Remaining time for radiant spell.
--   memory.registerwrite(0xDA, function(address)
--     print(self.game.memory:readRAM(0xDA))
--   end)
--   -- .alias RepelTimer       $DB     ;Remining repel spell time.
--   memory.registerwrite(0xDB, function(address)
--     if self.game.memory:getRepelTimer() > 100 then
--       self.game.memory:setRepelTimer(10)
--     end
--   end)

--   game:useItem(Herb)
--   game:useItem(MagicKey)
--   game:useItem(RainbowDrop)