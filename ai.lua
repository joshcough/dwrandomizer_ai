require 'mem'
require 'Class'
require 'controller'
require 'enemies'
require 'game'
require 'helpers'
require 'hud'
require 'locations'
require 'map_scripts'
require 'overworld'
require 'static_maps'

-- TODO:
-- * keep track of monster abilities (so that we can make better decisions about running/fighting)
-- * ive seen it soft lock opening a chest... maybe use the menuing x/y coordinates to fix this.
-- * fight the dragon lord
-- * save the princess
-- * use heal in battle
-- * if enemy isn't worth fighting (too low xp) then we should run from it.
-- * we can't open a chest when we have a full inventory. we dont know how to detect that and/or drop something.
-- * we will eventually want to be able to grind in dungeons
-- * we will definitely want to be able to grind on spike tiles
-- *   in fact, we haven't really dealt with spike tiles at all! we really need to.
-- * i haven't seen it go into the basement of charlock. i think its time to adjust that script.
-- * are healing locations actually working? i dont remember if we are going to heal when we need to or not. check.
-- * we sometimes get into weird RNG loops where we end up dying to the same monster over and over.here
--   i am not sure how to fix this... maybe we need to start keeping track of where we are dying
--   and what is happening during battles... and if we die the same way a few times in a row
--   then choose a different location to go to. i guess...
--   or if we can somehow detect we are in an RNG loop, maybe we can take a few unnecessary steps
--   in the throne room to disrupt the loop
-- * i think it might be a good idea to put the static map children directly into the parent, like a tree
-- * instead of (or at least in addition to) having all the ids inside of the `StaticMap:childrenIds()` function

-- 12/21/21
-- * when we die, we dont hit the overworld, and so doors are still open, and we can't create a path
--   to the grave in garinham. so... we have to do _something_ there, im just not sure what yet.

AI = class(function(a, game) a.game = game end)

function AI:onEncounter()      return function(address) self.game:startEncounter()   end end
function AI:enemyRun()         return function(address) self.game:enemyRun()         end end
function AI:playerRunSuccess() return function(address) self.game:playerRunSuccess() end end
function AI:playerRunFailed()  return function(address) self.game:playerRunFailed()  end end
function AI:onPlayerMove()     return function(address) self.game:onPlayerMove()     end end
function AI:onMapChange()      return function(address) self.game:onMapChange()      end end
function AI:endRepelTimer()    return function(address) self.game:endRepelTimer()    end end
function AI:nextLevel()        return function(address) self.game:nextLevel()        end end
function AI:deathBySwamp()     return function(address) self.game:deathBySwamp()     end end
function AI:enemyDefeated()    return function(address) self.game:enemyDefeated()    end end
function AI:playerDefeated()   return function(address) self.game:playerDefeated()   end end

function AI:openCmdWindow()    return function(address) self.game:openCmdWindow()    end end
function AI:closeCmdWindow()   return function(address) self.game:closeCmdWindow()   end end
function AI:windowXCursor()    return function(address) self.game:windowXCursor()    end end
function AI:windowYCursor()    return function(address) self.game:windowYCursor()    end end

function AI:register(memory)
  memory.registerexecute(0xE4DF, self:onEncounter())
  memory.registerexecute(0xefc8, self:enemyRun())
  memory.registerexecute(0xe8a4, self:playerRunSuccess())
  memory.registerexecute(0xe89D, self:playerRunFailed())
  memory.registerwrite  (0x3a,   self:onPlayerMove())
  memory.registerwrite  (0x3b,   self:onPlayerMove())
  memory.registerwrite  (0x45,   self:onMapChange())
  memory.registerexecute(0xca83, self:endRepelTimer())
  memory.registerexecute(0xEA90, self:nextLevel())      -- LEA90:  LDA #MSC_LEVEL_UP       ;Level up music.
  memory.registerexecute(0xCDF8, self:deathBySwamp())   -- LCDE6:  LDA #$00                ;Player is dead. set HP to 0.
  memory.registerexecute(0xE98F, self:enemyDefeated())
  memory.registerexecute(0xED9C, self:playerDefeated()) -- PlayerHasDied: LED9C:  LDA #MSC_DEATH          ;Death music.
  memory.registerexecute(0xCF5A, self:openCmdWindow())
  memory.registerexecute(0xCF6A, self:closeCmdWindow())
  memory.registerwrite(0xD8, self:windowXCursor())
  memory.registerwrite(0xD9, self:windowYCursor())
end

-- TODO: obviously this will be removed later
-- but for now it just helps me survive to test exploration
-- give ourself gold, xp, best equipment, etc
function cheat(mem)
  log.debug("cheating...")
  cheat_giveMaxXP(mem)
  cheat_giveMaxGold(mem)

  mem:writeRAM(0xbe, 255) -- best equipment
  -- mem:writeRAM(0xbe, 0) -- no equipment
  mem:writeRAM(0xbf, 5)   -- 5 keys
  mem:writeRAM(0xc0, 5)   -- 5 herbs
  mem:writeRAM(0xc1, RainbowDropByte)
  -- mem:writeRAM(0xc1, SilverHarpByte)
  -- TODO: this doesn't seem to be working properly.
  mem:writeRAM(0xdb, 0xff) -- repel always on
end

function cheat_giveMaxXP(mem)
  mem:writeRAM(0xbb, 65535 / 256)
  mem:writeRAM(0xba, 65535 % 256)
end

function cheat_giveMaxGold(mem)
  mem:writeRAM(0xbd, 65535 / 256)
  mem:writeRAM(0xbc, 65535 % 256)
end

-------------------
---- MAIN LOOP ----
-------------------

function main()
  hud_main()

  local mem = Memory(memory, rom)
  -- cheat(mem)

  -- always save the maps man. if we dont do this
  -- we start getting out of date and bad stuff happens.
  -- saveStaticMaps(mem, table.concat(WARPS, list.map(WARPS, swapSrcAndDest)))

  local game = newGame(mem)
  local ai = AI(game)
  ai:register(memory)

  -- TODO: this is a hack
  -- right now this gets called when we move
  -- but we need to call it here once before we move, too.
  if(game:getLocation().mapId == 1) then
    game.overworld:getVisibleOverworldGrid(game:getX(), game:getY(), game.graph)
  end

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

-- 12/20/21
--   log.debug(game.scripts.MapScripts[Garinham])
--   list.debugWithMsg(game.entrances, "entrances")

-- game:cast(Repel)
--     local spells = game.memory:readPlayerData().spells
--     log.debug(spells:spellIndex(Healmore))
--   game:interpretScript(scripts.throneRoomOpeningGameScript())
--   mem:setReturnWarpLocation(30,83) -- tangegel

--   log.debug(game.staticMaps[SwampCave].entrances)
--   log.debug(game.staticMaps[Garinham].entrances)
--   log.debug(game.scripts.MapScripts[Tantegel])

--   mem:printNPCs()
--   log.debug(game.playerData)
--   log.debug(game.weaponAndArmorShops)
--   log.debug(game.searchSpots)
--   log.debug(game.chests)

-- game:gameStartScript()
--   game:goTo(Point(Tantegel, 29,29))
--   game:takeStairs(Point(Tantegel, 29,29))
--   game:goTo(Point(TantegelThroneRoom, 3,4))

--   log.debug(game.memory:readPlayerData().items:hasFairyFlute())

-- i run this each time to make sure nothing has changed.
-- if anything changes, git will tell me.
-- saveStaticMaps(mem, warps)

-- i print this out just to make sure things look sane when i start the script.
-- table.log(shortestPath(Point(TantegelThroneRoom, 1,1), Point(TantegelThroneRoom, 1,8), true, graphs))
-- can also do this, which loads the maps from files instead of memory:
-- table.log(shortestPath(Point(TantegelThroneRoom, 1,1), Point(TantegelThroneRoom, 1,8), true))
-- table.log(shortestPath(Point(Charlock, 10,19), Point(CharlockThroneRoom, 17,24), true))

-- These are some cool things, but, I don't think I actually really need them
-- so just dumping them here.

--   -- .alias RadiantTimer     $DA     ;Remaining time for radiant spell.
--   memory.registerwrite(0xDA, function(address)
--     log.debug(self.game.memory:readRAM(0xDA))
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
--
--   log.debug("levels: ", mem:readLevels())
--   local pd = mem:readPlayerData()
--   log.debug("totalXpToNextLevelFromCurrentLevel:", pd:totalXpToNextLevelFromCurrentLevel())
--   log.debug("totalXpToNextLevel(1):", pd:totalXpToNextLevel(1)) ...
--   log.debug("totalXpToNextLevel(4):", pd:totalXpToNextLevel(4))

--   log.debug(mem:readWeaponAndArmorShops())

-- if we cant find a path, we can print stuff like this to debug:
--   log.debug(self:shortestPath(Point(29,9,3), Point(28,0,0)))
--   log.debug(self:shortestPath(Point(28,0,0), Point(1,86,84)))
--   log.debug("Point(28,0,0)", self.graph.graphWithKeys:getNodeAt(28,0,0))
--   log.debug("Point(1,86,84)", self.graph.graphWithKeys:getNodeAt(1,86,84))
--   log.debug(self.graph.graphWithKeys:printSquare(Square(Point(1, 70, 70), Point(1, 100, 100)), self, true))
--   log.debug(self.graph.graphWithKeys:printMap(28, self, true))
--   log.debug(self.graph.graphWithKeys:printMap(29, self, true))



--- ==== all windowing stuff below ==== ---


-- LEE0A:  LDA #WND_DIALOG         ;Remove dialog window from the screen.
-- LEE0C:  JSR RemoveWindow        ;($A7A2)Remove window from screen.


-- RemoveWindow:
-- LA7A2:  STA WndTypeCopy         ;Save a copy of the window type.

-- ShowNCCmdWindow:
-- LCF5A:  LDA #NPC_STOP           ;Stop NPCs from moving.
-- LCF5C:  STA StopNPCMove         ;
--
-- LCF5E:  JSR Dowindow            ;($C6F0)display on-screen window.
-- LCF61:  .byte WND_POPUP         ;Pop-up window.
--
-- LCF62:  JSR Dowindow            ;($C6F0)display on-screen window.
-- LCF65:  .byte WND_CMD_NONCMB    ;Command window, non-combat.
--
-- LCF66:  CMP #WND_ABORT          ;Did player abort the menu?
-- LCF68:  BNE NCCmdSelected       ;If not, branch.
--
-- ClrNCCmdWnd:
-- LCF6A:  LDA #WND_CMD_NONCMB     ;Remove command window from screen.
-- LCF6C:  JSR RemoveWindow        ;($A7A2)Remove window from screen.


-- int memory.getregister(cpuregistername)
-- Returns the current value of the given hardware register.
-- For example, memory.getregister("pc") will return the main CPU's current Program Counter.
-- Valid registers are: "a", "x", "y", "s", "p", and "pc".

--
-- DoWindow:
-- LC6F0:  PLA                     ;
-- LC6F1:  CLC                     ;
-- LC6F2:  ADC #$01                ;
-- LC6F4:  STA GenPtr3ELB          ;
-- LC6F6:  PLA                     ;Get return address from stack and increment it.
-- LC6F7:  ADC #$00                ;The new return address skips the window data byte.
-- LC6F9:  STA GenPtr3EUB          ;
-- LC6FB:  PHA                     ;
-- LC6FC:  LDA GenPtr3ELB          ;
-- LC6FE:  PHA                     ;
--
-- LC6FF:  LDY #$00                ;Put window data byte in the accumulator.
-- LC701:  LDA (GenPtr3E),Y        ;

-- ;Window types.
-- .alias WND_POPUP        $00     ;Pop-up window with name, level, HP, MP gold and experience.
-- .alias WND_STATUS       $01     ;Status window.
-- .alias WND_DIALOG       $02     ;Dialog window.
-- .alias WND_CMD_NONCMB   $03     ;Command window, non-combat.
-- .alias WND_CMD_CMB      $04     ;Command window, combat.
-- .alias WND_SPELL1       $05     ;Spell window, not used.
-- .alias WND_SPELL2       $06     ;Spell window, points to same window data as above.
-- .alias WND_INVTRY1      $07     ;Inventory window, player inventory.
-- .alias WND_INVTRY2      $08     ;Inventory window, Shop inventory.
-- .alias WND_YES_NO1      $09     ;Yes/no selection window, variant 1.
-- .alias WND_BUY_SELL     $0A     ;Buy/sell window.
-- .alias WND_ALPHBT       $0B     ;Alphabet window.
-- .alias WND_MSG_SPEED    $0C     ;Message speed window.
-- .alias WND_INPT_NAME    $0D     ;Input name window.
-- .alias WND_NM_ENTRY     $0E     ;Name entry window.
-- .alias WND_CNT_CH_ER    $0F     ;Continue, change, erase window.
-- .alias WND_FULL_MNU     $10     ;Full menu window.
-- .alias WND_NEW_QST      $11     ;Begin new quest window.
-- .alias WND_LOG_1_1      $12     ;Log list window, only entry 1, variant 1.
-- .alias WND_ERASE        $20     ;Erase log window.
-- .alias WND_YES_NO2      $21     ;Yes/no selection window, variant 2.


-- 0xd8            | Cursor X pos            |
-- 0xd9            | Cursor Y pos            |
-- .alias WndCol           $D8     ;Window colum currently selected.
-- .alias WndRow           $D9     ;Window row currently selected.
-- .alias WndXPos          $64E0   ;Current X position in window.
-- .alias WndYPos          $64E1   ;Current Y position in window(current tile row being built).
-- .alias WndCursorXPos    $64F2   ;Cursor X position in tiles in current selection window.
-- .alias WndCursorYPos    $64F3   ;Cursor Y position in tiles in current selection window.
-- WND_CMD_CMB
-- .alias WND_ABORT        $FF     ;Window cancelled.
-- .alias RemoveWindow             $A7A2

  -- 0xC6F0
  -- 0xC701
  -- 0xA802

--   -- .alias DoWindow                 $C6F0
--   memory.registerexecute(0xC6F0, function()
--     log.debug("a window opened or is opening!", memory.getregister("a"), memory.getregister("x"), memory.getregister("y"))
--   end)
--
--   -- .alias RemoveWindow             $A7A2
--   memory.registerexecute(0xA7A2, function() -- 0xA802
--     log.debug("a window closed or is closing!",  memory.getregister("a"))
--   end)

-- this is for any window closing, and might be a slightly better address than $A7A2
-- memory.registerexecute(0xA87F, self:closeCmdWindow())

-- this stuff is actually decent:

--   memory.registerexecute(0xDB76, function()
--     log.debug("opening spell window")
--   end)
--
--   -- .alias RemoveWindow             $A7A2
--   memory.registerexecute(0xA7A2, function() -- 0xA802
--     log.debug("a window closed or is closing!",  memory.getregister("a"))
--   end)

-- LDB76:  JSR Dowindow            ;($C6F0)display on-screen window.
-- LDB79:  .byte WND_SPELL2        ;Spell window.

--   memory.registerexecute(0xC6FF, function()
--     log.debug("0xC6FF", memory.getregister("a"), memory.getregister("y"))
--   end)

--   memory.registerexecute(0xC701, function()
--     log.debug("0xC701", memory.getregister("a"))
--   end)

--   LC6FF:  LDY #$00                ;Put window data byte in the accumulator.
--   LC701:  LDA (GenPtr3E),Y        ;

-- DoneRemoveWindow:
-- LA87F:  RTS                     ;Window is now removed. Exit.
