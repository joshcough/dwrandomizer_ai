require 'Class'
require 'controller'
enum = require("enum")
require 'helpers'
require 'locations'
require 'map_scripts'
require 'mem'
require 'overworld'
require 'player_data'
require 'static_maps'

Game = class(function(a, memory, warps, graph, overworld, staticMaps)
  -- map related stuff
  a.entrances = getAllEntranceCoordinates(memory)
  a.scripts = Scripts(a.entrances)
  a.memory = memory
  a.warps = warps
  a.graph = graph
  a.overworld = overworld
  a.staticMaps = staticMaps

  -- events/signals that happen in game
  a.inBattle = false
  a.enemy = nil
  a.repelTimerWindowOpen = false
  a.mapChanged = false
  a.leveledUp = false
  a.dead = false
  a.enemyKilled = false

  -- various other things
  a.exploreDest = nil
  a.unlockedDoors = {}
  a.weaponAndArmorShops = memory:readWeaponAndArmorShops()
  a.searchSpots = memory:readSearchSpots()
  a.chests = memory:readChests()
  a.lastPrintedPercentage = 0
  -- we start on the menu screen, so on no map at all.
  a.currentMapId = 0

  a.goals = buildAllGoals(a.staticMaps, a.chests, a.searchSpots)

  a.file_descriptor = io.open("/Users/joshcough/work/dwrandomizer_ai/ai.out", "w")
end)

function newGame(memory)
  local warps = table.concat(WARPS, list.map(WARPS, swapSrcAndDest))
  local staticMaps = readAllStaticMaps(memory, warps)
  local graph = Graph(staticMaps)
  local overworld = readOverworldFromROM(memory)
  return Game(memory, warps, graph, overworld, staticMaps)
end

-- function newGameWithNoOverworld(memory)
--   local warps = table.concat(WARPS, list.map(WARPS, swapSrcAndDest))
--   local staticMaps = readAllStaticMaps(memory, warps)
--   local graphsWithKeys = readAllGraphs(memory, true, staticMaps, warps)
--   local graphsWithoutKeys = readAllGraphs(memory, false, staticMaps, warps)
--   return Game(memory, warps, nil, staticMaps, graphsWithKeys, graphsWithoutKeys)
-- end

function Game:readPlayerData()
  return self.memory:readPlayerData()
end

function Game:getMapId()
  return self.memory:getMapId()
end

function Game:getEnemyId()
  return self.memory:getEnemyId()
end

function Game:getX()
  return self.memory:getX()
end

function Game:getY()
  return self.memory:getY()
end

function Game:getLocation()
  return self.memory:getLocation()
end

function Game:percentageOfWorldSeen()
  return self.overworld:percentageOfWorldSeen()
end

function Game:printVisibleGrid()
  return self.overworld:printVisibleGrid(self:getX(), self:getY(), self)
end

-- these are reasons that we have exited the followPath function
GotoExitValues = enum.new("Follow Path Exit Values", {
  "AT_LOCATION",
  "IN_BATTLE",
  "REPEL_TIMER",
  "DEAD",
  "MAP_CHANGED",
  "BUG"
 })

function Game:goTo(dest)
  local src = self:getLocation()
  if src:equals(dest) then
    -- log.debug("I was asked to go to: " .. tostring(dest) .. ", but I am already there!")
    return GotoExitValues.AT_LOCATION
  end
  local path = self:shortestPath(src, dest)
  -- log.debug("in goto, shortestPath: ", src, dest, path)

  if path == Nothing then
    log.err("ERROR: Could not create path from: " .. tostring(src) .. " to: " .. tostring(dest))
  else
    local res = self:followPath(path)
    -- log.debug("res from followPath is", res)
    if res == GotoExitValues.REPEL_TIMER
      then
        -- we got interruped by repel ending. after closing the window, continue going.
        self:closeRepelTimerWindow()
        self:goTo(dest)
    elseif res == GotoExitValues.IN_BATTLE
      then
        -- we got interruped by a battle. after finishing the battle, continue going.
        self:executeBattle()
        if self.dead then return GotoExitValues.DEAD
        else self:goTo(dest)
        end
    elseif res == GotoExitValues.MAP_CHANGED
      then
        self:dealWithMapChange()
        self:goTo(dest)
    else
      return res
    end
  end
end

-- TODO: we need a way to interrupt this path taking.
-- if we discover a new location while walking to a path
-- we immediately want to abandon this path, and walk to the new path.
function Game:followPath(path)
  if path == Nothing then log.err("follow path was given an empty path (Nothing)") end

  local commands = self:convertPathToCommands(path.value, self.staticMaps)

  if commands.commands == nil or #(commands.commands) == 0 then
    return log.err("path is empty in followPath")
  end

  -- log.debug(commands)

  for i,c in pairs(commands.commands) do
    -- if we are in battle or the repel window opened, then abort
    if self.inBattle then return GotoExitValues.IN_BATTLE
    elseif self.repelTimerWindowOpen then return GotoExitValues.REPEL_TIMER
    else
      if     c.direction == MovementCommandDir.DOOR   then self:interpretScript(self.scripts.OpenDoor(c.to))
      elseif c.direction == MovementCommandDir.STAIRS then self:interpretScript(self.scripts.TakeStairs)
      else
        local startingLoc = self:getLocation()
        -- this must be a Just because of the two cases above
        -- this would be nicer if we had pattern matching, but, we dont.
        local button = movementCommandDirToButton(c.direction).value
        controller.holdButtonUntil(button, "we are at " .. tostring(c.to), function ()
          self:updateOverworld(startingLoc)
          return self:shouldStopTakingPath(c.to)
        end)
      end
    end
  end

  if self.inBattle then return GotoExitValues.IN_BATTLE
  elseif self.repelTimerWindowOpen then return GotoExitValues.REPEL_TIMER
  elseif self.mapChanged then return GotoExitValues.MAP_CHANGED
  -- we think we have completed the path, and this should always be the case
  -- but, do a last second double check just in case.
  elseif self:getLocation():equals(commands.dest) then return GotoExitValues.AT_LOCATION
  -- we should be at the location, but somehow we werent. this must be a bug.
  else
    log.debug("Potential Error: we should be at the location, but somehow we weren't", self:getLocation(), dest)
    return GotoExitValues.BUG
  end
end

-- When following a path, if we are on the overworld, we need to update it when we see new tiles
-- We also print the percentage of the world seen here, just because fun to know.
-- @self :: Game
-- @startingLoc :: Point
-- @returns :: Unit
function Game:updateOverworld(startingLoc)
  local loc = self:getLocation()
  if loc.mapId == OverWorldId and not loc:equals(startingLoc) then
    self.overworld:getVisibleOverworldGrid(loc.x, loc.y, self)
    local currentPercentageSeen = round(self:percentageOfWorldSeen())
    if self.lastPrintedPercentage < currentPercentageSeen then
      log.debug("percentageOfWorldSeen: " .. currentPercentageSeen)
      self.lastPrintedPercentage = currentPercentageSeen
    end
  end
end

-- Returns true if we are at the given destination, or if we are in battle, dead or the repel timer window opened
-- in each of these cases, we need to abort walking on the current path to deal with those things.
-- @self :: Game
-- @pathDestination :: Point
-- @returns :: Bool
function Game:shouldStopTakingPath(pathDestination)
  local loc = self:getLocation()
  return loc:equals(pathDestination) or self.inBattle or self.repelTimerWindowOpen or self.dead -- or self.mapChanged
end

-- @self :: Game
-- @s :: Script
-- @returns :: TODO what should this function return?
function Game:interpretScript(s)
  -- log.debug("Script: " .. tostring(s))
  -- TODO: im not sure if these first two cases are really needed, but they dont hurt.
  if     self.inBattle then self:executeBattle()
  -- TODO: consider casting repel right here instead of just closing window
  elseif self.repelTimerWindowOpen then self:closeRepelTimerWindow()
  elseif s ~= nil and s:is_a(Script) then
        if s:is_a(Value) then return s.v
    elseif s:is_a(ActionScript)
      then
        -- on these ones, simple `==` will do
        if     s == DoNothing    then return
        elseif s == OpenChest    then self:markChestOpened()
        elseif s == Search       then self:searchGroundScript()
        elseif s == DeathWarp    then self:deathWarp()
        elseif s == SavePrincess then self:savePrincess()
        elseif s == DragonLord   then self:fightDragonLord()
        elseif s == ShopKeeper   then self:talkToShopKeeper()
        elseif s == DoBattle     then self:executeBattle()
        -- == doesn't work on these, so we need is_a
        elseif s:is_a(SaveUnlockedDoor) then self:saveUnlockedDoor(s.loc)
        elseif s:is_a(CastSpell)        then self:cast(s.spell)
        elseif s:is_a(UseItem)          then
          -- this is a little special because we have to fix up the overworld to add the bridge
          if s.item == RainbowDrop then self:useRainbowDrop()
          else self:useItem(s.item)
          end
        end
    elseif s:is_a(Goto) then self:goTo(s.location)
    elseif s:is_a(PlayerDataScript) then return s.playerDataF(self:readPlayerData())
    elseif s:is_a(PlayerDirScript)  then return self.memory:readPlayerDirection()
    elseif s:is_a(IfThenScript)
      then
        -- log.debug("IfThenScript calling evaluateCondition with", s.condition)
        local cond = self:evaluateCondition(s.condition)
        local branch = cond and s.trueBranch or s.falseBranch
        return self:interpretScript(branch)
    elseif s:is_a(Consecutive)
      then for i,branch in pairs(s.scripts) do self:interpretScript(branch) end
    elseif s:is_a(PressButtonScript) then controller.pressButton(s.button, s.waitFrames)
    elseif s:is_a(HoldButtonScript) then controller.holdButton(s.button, s.duration)
    elseif s:is_a(HoldButtonUntilScript) then controller.holdButtonUntil(s.button, tostring(s.condition), function ()
      -- log.debug("HoldButtonUntilScript calling evaluateCondition with", s.condition)
      return self:evaluateCondition(s.condition)
    end)
    elseif s:is_a(WaitFrames) then controller.waitFrames(s.duration)
    elseif s:is_a(WaitUntil) then
      -- log.debug("WaitUntil calling evaluateCondition with", s.condition)
      controller.waitUntil(function() return self:evaluateCondition(s.condition) end, s.duration, s.msg)
    elseif s:is_a(DebugScript) then log.debug(s.name)
    elseif s:is_a(NTimes) then
      local n = self:interpretScript(s.n)
      -- log.debug("in NTimes", "s.n", s.n, "n", n, "s.script", s.script)
      for i = 1, self:interpretScript(s.n) do
        self:interpretScript(s.script)
      end
    elseif s:is_a(BinaryOperator) then
      local lv = self:interpretScript(s.l)
      local rv = self:interpretScript(s.r)
      -- log.debug("in BinaryOperator", s.name, s.l, s.r, lv, rv)
      return s.f(self:interpretScript(s.l), self:interpretScript(s.r))
    elseif s:is_a(ConditionScript) then
      return self:evaluateCondition(s)
    end
  else
    log.debug("Script is not a script! " .. tostring(s))
  end
end

function Game:evaluateCondition(s)
  -- log.debug("evaluateCondition: ", s)
  -- base conditions
      if s:is_a(IsChestOpen) then return self.chests:isChestOpen(s.location)
  elseif s:is_a(IsDoorOpen)  then
    local b = self:isDoorOpen(s.location)
    -- log.debug("IsDoorOpen", b)
    return b
  elseif s:is_a(HasChestEverBeenOpened) then return self.chests:hasChestEverBeenOpened(s.location)
  -- combinators
  elseif s:is_a(BinaryOperator) then
    local lv = self:interpretScript(s.l)
    local rv = self:interpretScript(s.r)
    -- log.debug("in BinaryOperator", s.name, s.l, s.r, lv, rv)
    return s.f(self:interpretScript(s.l), self:interpretScript(s.r))
  elseif s:is_a(Any)      then return list.any(s.conditions, function(x)
    -- log.debug("Any calling evaluateCondition with", x)
    return self:evaluateCondition(x)
  end)
  elseif s:is_a(All)      then return list.all(s.conditions, function(x)
    -- log.debug("All calling evaluateCondition with", s.conditions, x)
    return self:evaluateCondition(x)
  end)
  elseif s:is_a(Contains) then return self:interpretScript(s.container):contains(s.v)
  elseif s:is_a(Not)      then
    -- log.debug("Not calling evaluateCondition with", s.condition)
    return not self:evaluateCondition(s.condition)
  elseif s:is_a(Value)    then return s.v

  -- TODO: hack. PlayerDataScript is not a ConditionScript...gross.
  elseif s:is_a(PlayerDataScript) then return s.playerDataF(self:readPlayerData())

  elseif s:is_a(InBattle) then return self.inBattle
  -- this should be a type error, but, we dont get those in lua.
  else return false
  end
end

-- TODO: could move some of this into map_scripts
function Game:closeRepelTimerWindow()
  if self.repelTimerWindowOpen then
    controller.waitFrames(30)
    controller.pressB(2)
    self.repelTimerWindowOpen = false
  end
end

-- TODO: i have no idea how i am going to do this yet.
function Game:deathWarp ()
end

-- TODO: this one should be easy.
function Game:savePrincess ()
end

-- TODO: this is all messed up.
function Game:fightDragonLord ()
--   self:openMenu()
--   pressA(30)
--   pressA(30)
--   pressDown(2)
--   pressA(2)
--   self.inBattle = true
--   self:executeDragonLordBattle()
end

function Game:markChestOpened ()
  self.chests:openChestAt(self:getLocation())
  self:completeGoalHere(false)
end

function Game:searchGroundScript ()
  self.searchSpots:searchAt(self:getLocation())
end

function Game:addWarp(warp)
  if table.containsUsingDotEquals(self.warps, warp) then
    -- log.debug("NOT Adding warp, it already exists!: " .. tostring(warp))
    return
  end
  log.debug("Adding warp: " .. tostring(warp))
  table.insert(self.warps, warp)
  -- TODO: the next line can probably still be removed. we only use the warps for two reasons:
  -- * building the initial graph (very important)
  -- * printing the message that we've already added the warp (not important)
  -- this business of reversing the warp just isn't useful here
  -- unless somehow we later would try to add the warp reversed... its all weird.
  self.warps = table.concat(self.warps, list.map(self.warps, swapSrcAndDest))
  self.graph:addWarp(warp, self.overworld)
end

function containsPoint(tbl, p)
  if tbl[p.mapId] == nil then return false end
  if tbl[p.mapId][p.x] == nil then return false end
  return tbl[p.mapId][p.x][p.y] ~= nil
end

-- @src :: Point
-- @destination :: Point
-- @returns Maybe Path
function Game:shortestPath(src, destination)
  return self.graph:shortestPath(src, destination, self:haveKeys(), self)
end

-- @src :: Point
-- @destination :: [Point]
-- @returns Maybe Path
function Game:shortestPaths(src, destinations)
  return self.graph:shortestPaths(src, destinations, self:haveKeys(), self)
end

function swapSrcAndDest(w) return w:swap() end

-- TODO: is this really needed? isnt this information just in memory somewhere? i swear it was.
function Game:isDoorOpen(loc)
  local res = table.containsUsingDotEquals(list.map(self.unlockedDoors, function(d) return d.loc end), loc.loc)
  -- log.debug("in Game:isDoorOpen", "loc", loc, "self.unlockedDoors", self.unlockedDoors, res)
  return res
end

function Game:saveUnlockedDoor(loc)
  -- if this is the throne room
  -- then we need to set that tile to brick instead of a door
  -- and then we will probably have to regenerate the graphs or whatever.
  if (loc:equalsPoint(Point(TantegelThroneRoom, 4, 7))) then
    self.graph:unlockThroneRoomDoor()
  elseif (loc:equalsPoint(Point(Rimuldar, 22, 23))) then
    self.graph:unlockRimuldar()
  end
  table.insert(self.unlockedDoors, loc)
end

MovementCommandDir = enum.new("MovementCommand Direction", {
  "LEFT",
  "RIGHT",
  "UP",
  "DOWN",
  "STAIRS",
  "DOOR",
})

-- @dir :: MovementCommandDir
-- @returns :: Maybe Controller.Button
function movementCommandDirToButton(dir)
  if     dir == MovementCommandDir.LEFT  then return Just(Button.LEFT)
  elseif dir == MovementCommandDir.RIGHT then return Just(Button.RIGHT)
  elseif dir == MovementCommandDir.UP    then return Just(Button.UP)
  elseif dir == MovementCommandDir.DOWN  then return Just(Button.DOWN)
  else return Nothing
  end
end

MovementCommand = class(function(a,direction,from,to)
  a.direction = direction
  a.from = from
  a.to = to
end)

function MovementCommand:__tostring()
  return "<MovementCommand" ..
         " from: "       .. tostring(self.from) ..
         ", to: "        .. tostring(self.to) ..
         ", direction: " .. tostring(self.direction) ..
         ">"
end

function MovementCommand:sameDirection (other)
  return self.direction == other.direction
end

CommandsList = class(function (a, src, dest, commands)
  a.src      = src
  a.dest     = dest
  a.commands = commands
end)

function CommandsList:__tostring()
  return "<CommandsList"  ..
         " src: "         .. tostring(self.src) ..
         ", dest:"        .. tostring(self.dest) ..
         ", commands: {"  .. list.intercalateS(", ", self.commands) .. "}" ..
         ">"
end

-- TODO: this shit seems to work... but im not sure i understand it. lol
-- there is definitely a way to do this that is more intuitive.
function Game:convertPathToCommands(pathIn, maps)
  -- log.debug("pathIn", pathIn)
  function directionFromP1ToP2(p1, p2)
    local res = {}

    function move(next)
      if     p2.dir == NeighborDir.STAIRS then return MovementCommand(MovementCommandDir.STAIRS, p1, next)
      elseif p2.dir == NeighborDir.LEFT   then return MovementCommand(MovementCommandDir.LEFT,   p1, next)
      elseif p2.dir == NeighborDir.RIGHT  then return MovementCommand(MovementCommandDir.RIGHT,  p1, next)
      elseif p2.dir == NeighborDir.UP     then return MovementCommand(MovementCommandDir.UP,     p1, next)
      elseif p2.dir == NeighborDir.DOWN   then return MovementCommand(MovementCommandDir.DOWN,   p1, next)
      else log.err("i have no idea what is going on with the neighbor type", p1, p2, next)
      end
    end

    function nextTileIsDoor()
      if p2.mapId == OverWorldId then return false
      else return maps[p2.mapId]:getTileAt(p2.x, p2.y, self).name == "Door"
      end
    end

    if nextTileIsDoor() then
      -- TODO: this p1 here is so confusing. it does seem to work, but wtf...
      table.insert(res,move(p1))
      table.insert(res, MovementCommand(MovementCommandDir.DOOR, p2, p2))
      table.insert(res,move(p2))
    else
      table.insert(res,move(p2))
    end

    return res
  end

  local zippedPath = list.zipWith(directionFromP1ToP2, pathIn.path, list.drop(1, pathIn.path))
  local joinedZippedPath = list.join(zippedPath)

  local res = list.foldLeft(joinedZippedPath, {}, function(acc, c)
    if c.direction == MovementCommandDir.STAIRS then table.insert(acc, c)
    elseif #(acc) > 0 and acc[#(acc)]:sameDirection(c) then acc[#(acc)].to = c.to
    else table.insert(acc, c)
    end
    return acc
  end)

  return CommandsList(pathIn.src, pathIn.dest, res)
end

-- in grindOrExplore, current location is:	<Point mapId:23, x:10, y:9>
-- not on the overworld, jumping to self:exploreStaticMap()
-- Waiting until: on static map for up to 240 frames.
-- Waited until: on static map waited exactly 0 frames, and condition is: true

function Game:stateMachine()
  -- log.debug(".")
  if self.dead then self:dealWithDeath()
  elseif self.mapChanged then self:dealWithMapChange()
  elseif self:getMapId() == 0 then self:interpretScript(self.scripts.GameStartMenuScript)
  else
    self:grindOrExplore()
  end
end

function Game:getExploreDest()
  -- log.debug("in Game:getExploreDest", "self.exploreDest", self.exploreDest)
  return self.exploreDest
end

function Game:setExploreDest(newDest)
  self.exploreDest = newDest
end

function Game:noExploreDestOrHaventReachedDestYet()
  if self:getExploreDest() == nil then return true end
  return not self:getExploreDest():equals(self:getLocation())
end

function Game:haveExploreDestButHaventReachedDestYet()
  if self:getExploreDest() == nil then return false end
  return not self:getExploreDest():equals(self:getLocation())
end

function Game:atExploreDest()
  if self:getExploreDest() == nil then return false end
  return self:getExploreDest():equals(self:getLocation())
end

function Game:dealWithAnyGoals()
  log.debug("in dealWithAnyGoals")

  self.goals:debug(self)

  local achievableGoals = self.goals:seenButNotCompletedGoals(self)

  return list.toMaybe(achievableGoals):map(function(goal)
    log.debug("goal", goal)
    local newGoal = goal.v.location
    log.debug("Headed towards new location for achievable goal", newGoal)
    return newGoal
  end)
end

function Game:grindOrExplore()
  log.debug("in grindOrExplore, current location is:", self:getLocation())
  self:healIfNecessary()

  -- TODO: i think these if statements can be simplified.
  if self:haveExploreDestButHaventReachedDestYet() then
    log.debug("we had an exploreDest, so going to that instead of grinding", self:getExploreDest())
    self:explore()
    log.debug("returning from grindOrExplore after having called explore()")
  elseif self:atExploreDest()
    then self:reachedDestination()
  elseif self:getMapId() == OverWorldId then
    log.debug("no exploreDest, on the overworld.")
    local newGoal = self:dealWithAnyGoals()
    log.debug("newGoal", newGoal)
    if newGoal ~= Nothing then
      self:chooseNewDestinationDirectly(newGoal.value)
    else
      local pd = self:readPlayerData()
      local grind = getGrindInfo(pd, self)
      -- if we have a good monster to grind on, grind.
      if grind ~= nil then
        log.debug("grind", grind)
        self:grind(grind, pd.stats.level)
      -- if haven't seen anything worth fighting... then i guess just explore...
      else
        log.debug("goal and grind were both nil, so picking a random border tile")
        self:chooseNewDestination(function (k) return self:chooseRandomBorderTile(k) end)
      end
    end
  else
    log.debug("not on the overworld, jumping to self:exploreStaticMap()")
    self:exploreStaticMap()
  end
end

function Game:grind(grind, currentLevel)
  log.debug("GRINDING at: ", tostring(grind), "current location: ", self:getLocation())
  -- TODO: if one is forest and the other is desert, we want to pick desert.
  -- in general, we want to pick the tiles with the highest encounter rate.
  local neighbor = self.graph:grindableNeighbors(self, grind.location.x, grind.location.y)[1]
  log.debug("The neighbor to grind on", neighbor)

  while(self.memory:getLevel() == currentLevel and not self.dead) do
    self:goTo(grind.location)
    self:goTo(neighbor)
  end
end

function Game:reachedDestination()
  log.debug("We have reached our destination:" .. tostring(loc))
  self:completeGoalHere(true)
  self:setExploreDest(nil)
end

function Game:explore()
  local loc = self:getLocation()
  log.debug("in explore, self.exploreDest is:" , self:getExploreDest(), "current location: ", loc)
  if loc.mapId == OverWorldId then
    log.debug("in explore, we are on the overworld, calling exploreMove")
    self:exploreMove()
    log.debug("done with exploreMove, returning from explore.")
  else
    log.debug("in explore, and not on the overworld. calling exploreStaticMap")
    self:exploreStaticMap()
    log.debug("done with exploreStaticMap")
  end
end

function Game:exploreStaticMap()
  controller.waitUntil(function() return self:onStaticMap() end, 240, "on static map")
  -- zzz this thing is causing problems i tihnk
  if self.mapChanged then
    log.debug("---- going to deal with map change ----")
    self:dealWithMapChange()
  end
  local loc = self:getLocation()
  local script = self.scripts.MapScripts[loc.mapId]

  log.debug("in exploreStaticMap, loc is", loc)

  if script ~= nil then
    log.debug("script is not nil, so interpreting it")
    self:interpretScript(script)
  else
    if (emu.framecount() % 60 == 0) then
      log.debug("i don't yet know how to explore this map: " .. tostring(loc), ", "
        .. tostring(STATIC_MAP_METADATA[loc.mapId]))
    end
  end
end

-- what we really should do here is pick a random walkable border tile
-- then get one if its unseen neighbors and walk to that location.
-- walking to the border tile itself is kinda useless. we need to walk into unseen territory.
function Game:chooseRandomBorderTile(borderOfKnownWorld)
  log.debug("picking random border tile")
  local nrBorderTiles = #borderOfKnownWorld
  return borderOfKnownWorld[math.random(nrBorderTiles)]
end

function Game:chooseClosestBorderTile(borderOfKnownWorld)
  log.debug("picking closest border tile")
  local loc = self:getLocation()
  local d = list.min(borderOfKnownWorld, function(t)
    return math.abs(t.x - loc.x) + math.abs(t.y - loc.y)
  end)
  return d
end

function Game:chooseNewDestination(tileSelectionStrat)
  -- otherwise, we either dont have a destination so we need to get one
  -- or we are at our destination already, so we need a new one
  local borderOfKnownWorld = self.graph:knownWorldBorder(self.overworld)
  -- log.debug("Border of known world:", borderOfKnownWorld)
  local nrBorderTiles = #borderOfKnownWorld
  -- TODO: this is an error case that i might need to deal with somehow.
  if nrBorderTiles == 0 then
    log.err("NO BORDER TILES!")
    return
  end

  self:chooseNewDestinationDirectly(tileSelectionStrat(borderOfKnownWorld))
end

function Game:chooseNewDestinationDirectly(newDestination)
  log.debug("new destination", newDestination)
  self:setExploreDest(newDestination)
end

function Game:exploreMove()
  log.debug("Moving from: ", self:getLocation(), " to ", self:getExploreDest())
  -- TODO: we are calculating the shortest path twice... we need to do better than that
  -- here... if we cant find a path to the destination, then we want to just choose a new destination
  local path = self:shortestPath(self:getLocation(), self:getExploreDest())

  -- TODO: we should really deal with this todo above ^ ^ ^
  -- because all we do here is check if there is a path...
  if path == Nothing then
    log.debug("couldn't find a path from player location: ", self:getLocation(), " to ", self:getExploreDest())
    self:chooseNewDestination(function (k) return self:chooseRandomBorderTile(k) end)
  else
    self:castRepel()
    local madeItThere = self:goTo(self:getExploreDest()) == GotoExitValues.AT_LOCATION
    -- if we are there, we need to nil this out so we can pick up a new destination
    if madeItThere then
      self:reachedDestination()
      self:setExploreDest(nil)
    end
  end
end

function Game:startEncounter()
 if (self:getMapId() > 0) then
    local enemyId = self:getEnemyId()
    local enemy = Enemies[enemyId]
    log.debug ("entering battle vs a " .. enemy.name)
    self.inBattle = true
    self.enemy = enemy
  end
end

function Game:onStaticMap()
  return self:getMapId() > 1 and self:getMapId() < 30
end

function Game:executeBattle()
  self.enemy:executeBattle(self)

  if self.leveledUp then
    controller.holdA(180)
    self.leveledUp = false
  end

  self.inBattle = false
  self.runSuccess = false
  self.enemyKilled = false
  self.enemy = nil

  self:healIfNecessary()

end

function Game:healIfNecessary()
  function needHealing()
    local pd = self:readPlayerData()
    return pd.stats.currentHP / pd.stats.maxHP < 0.5
  end

  function needMP()
    local pd = self:readPlayerData()
    local currentMP = pd.stats.currentMP
    return (pd.spells:contains(Healmore) and currentMP < 8) or
           (pd.spells:contains(Heal)     and currentMP < 3) or
           (pd.spells:contains(Hurtmore) and currentMP < 5) or
           (pd.spells:contains(Hurt)     and currentMP < 2)
  end

  function castMaybe(spell) if needHealing() then  self:cast(spell) end end

  -- TODO: we can do better than all this
  -- like, if we have 20 out of 40 HP, we should only cast heal
  castMaybe(Healmore)
  castMaybe(Heal)

  if needMP() then
    -- if we need mp, we should go the the closest healing location
    local healingLoc = self:closestHealingLocation()
    log.debug("closest healing location:", healingLoc)
    if healingLoc ~= Nothing then
      self:interpretScript(self.scripts.InnScripts[healingLoc.mapId])
    end
  end

end

-- TODO: this is broken
function Game:executeDragonLordBattle()
--   function battleEnded () return not self.inBattle end
--   controller.waitUntil(battleEnded, 120)
--   controller.holdAUntil(battleEnded, 240)
--   controller.waitUntil(battleEnded, 60)
--   controller.pressA(10)
--   self.inBattle = false
end

function Game:enemyRun()
  log.debug("the enemy is running!")
  self.inBattle = false
end

function Game:playerRunSuccess()
  log.debug("you are running!")
  self.runSuccess = true
end

function Game:playerRunFailed()
  log.debug("you are NOT running!")
  self.runSuccess = false
end

function Game:onPlayerMove()
  -- this wasn't working quite right
  -- so i just folded it into the followPath algo.
  -- i think that is a better spot for it anyway
  -- log.debug("position as changed to: " .. tostring(self:getLocation()))
end

function Game:onMapChange()
  -- log.debug("recording that the map has changed.")
  self.mapChanged = true
end

function Game:dealWithDeath()
  controller.waitFrames(120)
  controller.holdAUntil(function () return self:getMapId() == 5 end, "map is throne room", 240)
  self.dead = false
end

function Game:dealWithMapChange()
  local oldMapId = self.currentMapId
  local newMapId = self:getMapId()
  local newLoc   = self:getLocation()
  log.debug("dealing with map change... oldMap", oldMapId, "newMap", newMapId, "newLoc", newLoc)

  if oldMapId == newMapId then
    self.mapChanged = false
    return
  end

  -- catch transition from 0 to 5!
  -- this means that the game is just starting
  -- we have to do some monkey business here because when you are on the menu screen,
  -- the game thinks that you have already left the throne room.
  if oldMapId == 0 or oldMap == nil then
    local b = self:readPlayerData().statuses.leftThroneRoom
    -- TODO: is there actually any reason to update the map here?
    -- i doubt it. we probably just need to update the graph.
    -- except... maybe we do because we get the tile at (x,y) and if its a door it might have infinite weight?
    -- anyway, we have to double check on this.
    self.staticMaps[TantegelThroneRoom]:setTileAt(4, 7, b and 6 or 11)
    if b then self.graph:unlockThroneRoomDoor() end
  end

  if newMapId < OverWorldId then
    -- log.debug("The map changed, but dood, we are on map 0, so must be the menu or something...")
    return
  end

  -- log.debug("The map has changed! current position: " ..  tostring(newLoc) .. ", old map: " .. tostring(oldMapId))

  if newMapId == OverWorldId then
    self.chests:closeAll()
    -- we can see a bunch of new land now (potentially on another continent)
    -- we have to call this so that the knownWorld gets updated properly to see the new land.
    self.overworld:getVisibleOverworldGrid(newLoc.x, newLoc.y, self)
  elseif newMapId > OverWorldId and newMapId <= 29 then
    if not self.staticMaps[newMapId].seenByPlayer then
      self.staticMaps[newMapId]:markSeenByPlayer(self.staticMaps)
    end
  end

  -- we have entered a town or a cave
  if newMapId ~= 1 and newMapId ~= Tantegel then
    local entrances = self.staticMaps[newMapId].entrances
    if entrances ~= nil then
      if #entrances == 1 then
        self:addWarp(Warp(newLoc, entrances[1].from))
      else
        -- this must be swamp cave, because it has more than one entrance
        if newLoc:equals(SwampNorthEntrance) then
          log.debug("adding warp to SwampNorthEntrance")
          self:addWarp(Warp(newLoc, entrances[1].from))
        elseif newLoc:equals(SwampSouthEntrance) then
          log.debug("adding warp to SwampSouthEntrance")
          self:addWarp(Warp(newLoc, entrances[2].from))
        end
      end
    end
  elseif oldMapId == SwampCave then
    log.debug("leaving swamp cave")
    -- we also need to add the warp to the overworld
    local entrances = self.staticMaps[SwampCave].entrances
    if newLoc:equals(entrances[1].from) then
      log.debug("adding warp to SwampNorthEntrance")
      self:addWarp(Warp(newLoc, SwampNorthEntrance))
    else
      log.debug("adding warp to SwampSouthEntrance")
      self:addWarp(Warp(newLoc, SwampSouthEntrance))
    end
  elseif oldMapId == Tantegel then
    log.debug("leaving Tantegel")
    self:addWarp(Warp(TantegelEntrance, self.staticMaps[Tantegel].entrances[1].from))
  else
    log.debug("nothing to do in dealWithMapChange")
  end

  self:markMapsSeen(newMapId)

  self.currentMapId = newMapId
  self.mapChanged = false
end

-- here, we have to mark any children goals to be seenByPlayer
-- for example all the chests in a dungeon/town or the basement locations
-- so that we can actually go to the basement when we have keys
-- TODO: when we go to a town, we instantly execute the town script
--       but...sometimes we might just want to go to the goal, no?
function Game:markMapsSeen(newMapId)
  if newMapId > OverWorldId then
    local goals = self.staticMaps[newMapId]:childGoals(self.goals, self.staticMaps)
    list.foreach(goals, function(goal) goal.seenByPlayer = true end)
  end
end

-- TODO: does this work in battle as well as on the overworld?
-- it probably should, but, i have not checked yet.
-- TODO: didn't work completely for RainbowDrop
-- might need to do a little extra work there.
function Game:useItem(item)
  local itemIndex = self:readPlayerData().items:itemIndex(item)
  -- log.debug("itemIndex", itemIndex)
  if itemIndex == nil then
    log.debug("can't use " .. ITEMS[item] .. ", we don't have it.")
    return
  else
    self:interpretScript(self.scripts.OpenItemMenu)
    -- TODO: if it is faster to press UP, we should do that
    for i = 1, itemIndex-1 do controller.pressDown(2) end
    -- wait 2 seconds for the item to be done being used.
    -- TODO: do all items take the same length to use?
    -- or is it possible to get out sooner than 2 seconds?
    controller.pressA(120)
    controller.pressB(2)
  end
end

-- TODO: does this work in battle as well as on the overworld?
-- it probably should, but, i have not checked yet.
function Game:cast(spell)
  local pd = self:readPlayerData()
  local spellIndex = pd.spells:spellIndex(spell)
  if spellIndex == nil then
    -- log.debug("can't cast " .. tostring(spell) .. ", spell hasn't been learned.")
    return
  elseif pd.stats.currentMP < spell.mp then
    log.debug("can't cast " .. tostring(spell) .. ", not enough mp.")
    return
  else
    self:interpretScript(self.scripts.OpenSpellMenu)
    -- TODO: if it is faster to press UP, we should do that
    for i = 1, spellIndex-1 do controller.pressDown(2) end
    -- wait 2 seconds for the spell to be done casting.
    -- TODO: do all spells take the same length to cast?
    -- or is it possible to get out sooner than 2 seconds?
    controller.pressA(120)
    controller.pressB(2)
  end
end

function Game:castRepel(disregardTimer)
  if disregardTimer then self:cast(Repel)
  else
    if self.memory:getRepelTimer() > 1  then
      log.debug("wanted to cast repel, but it is still on! Won't cast it.")
    else
      self:cast(Repel)
    end
  end
end

function Game:useRainbowDrop()
  self:useItem(RainbowDrop)
  self.overworld:useRainbowDrop(self:getLocation(), self)
end

function Game:haveKeys()
  return self:readPlayerData().items:haveKeys()
end

function Game:endRepelTimer()
  log.debug("repel has ended")
  self.repelTimerWindowOpen = true
end

function Game:nextLevel()
  log.debug("i just leveled up.")
  self.leveledUp = true
end

function Game:deathBySwamp()
  log.debug("i just died in a swamp.")
  self.dead = true
end

function Game:enemyDefeated()
  -- log.debug("Killed an enemy.")
  self.enemyKilled = true
  self.inBattle = false
end

function Game:playerDefeated()
  log.debug("I just got killed.")
  self.dead = true
  self.inBattle = false
end

function Game:talkToShopKeeper()
  local loc = self:getLocation()
  self.weaponAndArmorShops:visitShopAt(loc)
  local shop = self.weaponAndArmorShops:getShopAt(loc)

  local upgrades = shop:getAffordableUpgrades(self:readPlayerData())

  if upgrades:isEmpty() then
    log.debug("No upgrades here.")
    controller.pressB(20)
    controller.pressB(2)
  else
    self:buyUpgrades(shop)
  end
end

function Game:buyUpgrades(shop)
  log.debug(tostring(shop))
  -- Note: here, we keep re-reading the player data because its possible
  -- that it might have changed when purchased something.
  -- possible that we can no longer afford the best armor after we buy a weapon, for example.
  local pd = self:readPlayerData()
  local bestWeaponToBuy = shop:getMostExpensiveAffordableWeaponUpgrade(pd)
  if(bestWeaponToBuy ~= nil) then
    log.debug("buying weapon: ", tostring(bestWeaponToBuy))
    self:buyItem(shop, bestWeaponToBuy.id, pd.equipment.weapon ~= nil)
  end
  pd = self:readPlayerData()
  local bestArmorToBuy  = shop:getMostExpensiveAffordableArmorUpgrade(pd)
  if(bestArmorToBuy ~= nil) then
    if(bestWeaponToBuy ~= nil) then
      -- log.debug("i bought a weapon, and am trying to say to buy armor")
      controller.pressA(60) -- we already bought something, and we want to buy more
    end
    log.debug("buying armor: ", tostring(bestArmorToBuy))
    self:buyItem(shop, bestArmorToBuy.id, pd.equipment.armor ~= nil)
  end
  pd = self:readPlayerData()
  local bestShieldToBuy = shop:getMostExpensiveAffordableShieldUpgrade(pd)
  if(bestShieldToBuy ~= nil) then
    if(bestWeaponToBuy ~= nil or bestArmorToBuy ~= nil) then
      -- log.debug("i bought a weapon or armor, and am trying to say to buy a shield")
      controller.pressA(60) -- we already bought something, and we want to buy more
    end
    log.debug("buying shield: ", tostring(bestShieldToBuy))
    self:buyItem(shop, bestShieldToBuy.id, pd.equipment.shield ~= nil)
  end

  -- we bought something, but finally we want to say no to buying anything else
  if (bestWeaponToBuy ~= nil or bestArmorToBuy ~= nil or bestShieldToBuy ~= nil) then
    controller.pressDown(30)
    controller.pressA(30)
    controller.pressB(2)
  end

end

function Game:buyItem(shop, itemId, sellExisting)
  local itemIndex = shop:indexOf(itemId)
  -- log.debug("itemIndex: ", itemIndex)

  -- TODO: i think i can make this into a script
  -- by just adding `NTimes(n, script)` to the language.
  -- the rest of this should be easy too, but
  -- it will need to take a boolean argument `sellExisting`
  -- and we will need to deal with it being like
  -- just a regular boolean or a `Value(bool)` or soemthing like that
  for i = 1, itemIndex-1 do controller.pressDown(10) end
  controller.pressA(30)

  if sellExisting then
    controller.pressA(30)
    controller.pressA(30)
  end

  controller.pressA(60)
end

-- discover a tile on the overworld
function Game:discoverOverworldTile(x,y)
  self.graph:discover(x, y, self.overworld)

  -- there are two definitions of seen
  -- one is that we have spotted it on the overworld, but not yet entered
  -- and the other is that we have actually entered it (or actually opened the chest, searched, etc)

  -- they are defined like so:
  -- a.seenByPlayer = false
  -- a.completed = false

  -- when we spot a location on the overworld, we mark it as seenByPlayer
  -- and when we actually enter/open/search, we will mark it as completed.

  -- then when exploring, we check for goals that are seen by the player, but not completed
  -- if there are any, pick the closest one and go to it. finally when there, mark it as completed.
  local newGoal = self:goalAt(Point(OverWorldId, x, y))
  if newGoal ~= nil then
    log.debug("Discovered " .. tostring(newGoal.type) .. " at " .. tostring(newGoal.location))
    newGoal.seenByPlayer = true

    if newGoal.type == GoalType.TANTEGEL then
      log.debug("I see Tantegel.")
      newGoal.completed = true
    elseif newGoal.type == GoalType.CHARLOCK then
      log.debug("I see Charlock!")
      -- TODO: JC 12/5/21 this is really weird now...
      -- i feel like we should have a function for dealing with goals
      -- like an interpreter, and this next line should be in there.
      -- self:interpretScript(self.scripts.EnterCharlock)
      -- newGoal.completed = true
    end
  end
end

-- TODO: i feel like all this shit should get moved to locations.lua
HealingLocationType = enum.new("HealingLocationType", { "INN", "OLD_MAN" })

HealingLocation = class(function(a, location, heading, type)
  a.location = location
  a.heading = heading
  a.type = type
end)

function HealingLocation:__tostring()
  return "<HealingLocation - loc: " .. tostring(self.location) .. ", type: " .. tostring(self.type) .. ">"
end

OldMan        = HealingLocation(Point(Tantegel,   18, 26), FaceRight, HealingLocationType.OLD_MAN)
KolInn        = HealingLocation(Point(Kol,        19,  2), FaceDown,  HealingLocationType.INN)
CantlinInn    = HealingLocation(Point(Cantlin,     8,  5), FaceUp,    HealingLocationType.INN)
RimuldarInn   = HealingLocation(Point(Rimuldar,   19,  2), FaceLeft,  HealingLocationType.INN)
BrecconaryInn = HealingLocation(Point(Brecconary,  8, 21), FaceRight, HealingLocationType.INN)
GarinhamInn   = HealingLocation(Point(Garinham,   15, 15), FaceRight, HealingLocationType.INN)

-- for all the towns that we have seen, return the locations of the inns
-- if we have a heal spell, then tantegel castle old man that refills mp
-- @returns (Table3D HealingLocation)
function Game:healingLocations()
  local res = Table3D()
  function insert(hLoc) res.insert(hLoc.location, hloc) end

  if self.staticMaps[Brecconary].seenByPlayer then insert(BrecconaryInn) end
  if self.staticMaps[Kol].seenByPlayer        then insert(KolInn)        end
  if self.staticMaps[Garinham].seenByPlayer   then insert(GarinhamInn)   end
  if self.staticMaps[Cantlin].seenByPlayer    then insert(CantlinInn)    end
  if self.staticMaps[Rimuldar].seenByPlayer   then insert(RimuldarInn)   end
  local spells = self:readPlayerData().spells
  if spells:contains(Heal) or spells:contains(Healmore) then insert(OldMan) end

  return res
end

-- @returns (Maybe HealingLocationWithPath)
function Game:closestHealingLocation()
  return list.toMaybe(self:getPathsForTable3D(self:getLocation(), self:healingLocations()))
end

-- @p :: Point
-- @returns :: Maybe Goal
function Game:goalAt(p) return self.goals:goalAt(p) end

ObjectWithPath = class(function (a, v, path)
  a.v    = v
  a.path = path
end)

function ObjectWithPath:__tostring()
  return "<ObjectWithPath v: " .. tostring(self.v) .. ", path:" .. tostring(self.path) .. ">"
end

function Game:completeGoalHere(wait)
  local loc = self:getLocation()
  local goalHere = self:goalAt(loc)
  if goalHere ~= nil
  then
    if wait then controller.waitFrames(60) end
    goalHere.completed = true
    log.debug("setting completed to true", goalHere)
    return true
  else return false
  end
end

-- @currentLoc :: Point
-- @table3d :: (Table3D a) (where is is something that has a .location field)
-- @returns [ObjectWithPath a] ordered by distance (from currentLoc) ASC
function Game:getPathsForTable3D(currentLoc, table3d)

  -- @locs :: [Point]
  local locs = list.map(table3d:toList(), function(loc) return loc.location end)

  -- @paths :: [Path] (sorted by weight, ASC)
  -- paths will only contain paths to locations that we can actually reach. we exclude
  -- things we can't reach them because they are on an island or we dont have keys or whatever.
  local paths = self:shortestPaths(currentLoc, locs)

  local res = list.map(paths, function(path)
    return ObjectWithPath(table3d:lookup(path.dest), path)
  end)

  return res
end


