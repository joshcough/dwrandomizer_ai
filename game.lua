require 'Class'
require 'controller'
enum = require("enum")
require 'helpers'
require 'map_scripts'
require 'mem'
require 'overworld'
require 'player_data'
require 'static_maps'

Game = class(function(a, memory, warps, overworld, maps, graphsWithKeys, graphsWithoutKeys)
  -- map related stuff
  a.scripts = Scripts(memory)
  a.memory = memory
  a.warps = warps
  a.overworld = overworld
  a.maps = maps
  a.graphsWithKeys = graphsWithKeys
  a.graphsWithoutKeys = graphsWithoutKeys

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
end)

function newGame(memory)
  local overworld = OverWorld(readOverworldFromROM(memory))
  local warps = table.concat(WARPS, list.map(WARPS, swapSrcAndDest))
  local maps = readAllStaticMaps(memory, warps)
  local graphsWithKeys = readAllGraphs(memory, true, maps, warps)
  local graphsWithoutKeys = readAllGraphs(memory, false, maps, warps)
  return Game(memory, warps, overworld, maps, graphsWithKeys, graphsWithoutKeys)
end

function newGameWithNoOverworld(memory)
  local warps = table.concat(WARPS, list.map(WARPS, swapSrcAndDest))
  local maps = readAllStaticMaps(memory, warps)
  local graphsWithKeys = readAllGraphs(memory, true, maps, warps)
  local graphsWithoutKeys = readAllGraphs(memory, false, maps, warps)
  return Game(memory, warps, nil, maps, graphsWithKeys, graphsWithoutKeys)
end

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
  return self.overworld:printVisibleGrid(self:getX(), self:getY())
end

-- these are reasons that we have exited the followPath function
GotoExitValues = enum.new("Follow Path Exit Values", {"AT_LOCATION", "IN_BATTLE", "REPEL_TIMER", "DEAD", "NO_PATH", "BUG"})

function Game:goTo(dest)
  local loc = self:getLocation()
  if loc:equals(dest) then
    -- print("I was asked to go to: " .. tostring(dest) .. ", but I am already there!")
    return GotoExitValues.AT_LOCATION
  end
  local path = self:shortestPath(loc, dest)
  if path == nil or #path == 0 then
    print("ERROR: Could not create path from: " .. tostring(loc) .. " to: " .. tostring(dest))
    -- something went wrong, we can't get a path there, and we aren't at the destination
    -- so return false indicating that we didn't make it.
    return GotoExitValues.NO_PATH
  else
    local res = self:followPath(path)
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
    else
      return res -- TODO: can we even do anything with the others? NO_PATH, BUG? AT_LOCATION?
    end
  end
end

-- TODO: we need a way to interrupt this path taking.
-- if we discover a new location while walking to a path
-- we immediately want to abandon this path, and walk to the new path.
function Game:followPath(path)
  local commands = convertPathToCommands(path, self.maps)
  if commands == nil or #commands == 0 then return GotoExitValues.NO_PATH end
  local dest = nil
  for i,c in pairs(commands) do
    -- if we are in battle or the repel window opened, then abort
    if self.inBattle then return GotoExitValues.IN_BATTLE
    elseif self.repelTimerWindowOpen then return GotoExitValues.REPEL_TIMER
    elseif c.direction == "Door" then self:interpretScript(self.scripts.OpenDoor(c.to))
    elseif c.direction == "Stairs" then self:interpretScript(self.scripts.TakeStairs)
    else
      local startingLoc = self:getLocation()
      holdButtonUntil(c.direction, "we are at " .. tostring(c.to), function ()
        dest = c.to
        local loc = self:getLocation()
        if loc.mapId == 1 and not loc:equals(startingLoc) then
          self.overworld:getVisibleOverworldGrid(self:getX(), self:getY())
          local currentPercentageSeen = round(self:percentageOfWorldSeen())
          if self.lastPrintedPercentage < currentPercentageSeen then
            print("percentageOfWorldSeen: " .. currentPercentageSeen)
            self.lastPrintedPercentage = currentPercentageSeen
          end
        end
        -- print("current point: ", memory:getLocation(), "c.to: ", c.to, "equal?: ", p:equals(c.to))
        return loc:equals(c.to) or self.inBattle or self.repelTimerWindowOpen or self.dead
      end)
    end
  end

  if self.inBattle then return GotoExitValues.IN_BATTLE
  elseif self.repelTimerWindowOpen then return GotoExitValues.REPEL_TIMER
  -- we think we have completed the path, and this should always be the case
  -- but, do a last second double check just in case.
  elseif self:getLocation():equals(dest) then return GotoExitValues.AT_LOCATION
  -- we should be at the location, but somehow we werent. this must be a bug.
  else return GotoExitValues.BUG
  end
end

-- todo: what should this function return?
function Game:interpretScript(s)
  -- print("Script: " .. tostring(s))
  -- TODO: im not sure if these first two cases are really needed, but they dont hurt.
  if     self.inBattle then self:executeBattle()
  -- TODO: consider casting repel right here instead of just closing window
  elseif self.repelTimerWindowOpen then self:closeRepelTimerWindow()
  elseif s:is_a(Value) then return s.v
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
      elseif s == InnKeeper    then self:talkToInnKeeper()
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
  elseif s:is_a(IfThenScript)
    then
      local cond = self:evaluateCondition(s.condition)
      local branch = cond and s.trueBranch or s.falseBranch
      return self:interpretScript(branch)
  elseif s:is_a(Consecutive)
    then for i,branch in pairs(s.scripts) do self:interpretScript(branch) end
  elseif s:is_a(PressButtonScript) then pressButton(s.button.name, s.waitFrames)
  elseif s:is_a(HoldButtonScript) then holdButton(s.button.name, s.duration)
  elseif s:is_a(WaitFrames) then waitFrames(s.duration)
  elseif s:is_a(WaitUntil) then
    waitUntil(function() return self:evaluateCondition(s.condition) end, s.duration, s.msg)
  elseif s:is_a(DebugScript) then print(s.name)
  end
end

function Game:evaluateCondition(s)
  -- print("evaluateCondition: ", s)
  -- base conditions
      if s:is_a(IsChestOpen) then return self.chests:isChestOpen(s.location)
  elseif s:is_a(IsDoorOpen)  then return self:isDoorOpen(s.location)
  elseif s:is_a(HasChestEverBeenOpened) then return self.chests:hasChestEverBeenOpened(s.location)
  -- combinators
  elseif s:is_a(Eq)       then return self:interpretScript(s.l) == self:interpretScript(s.r)
  elseif s:is_a(DotEq)    then return self:interpretScript(s.l):equals(self:interpretScript(s.r))
  elseif s:is_a(NotEq)    then return self:interpretScript(s.l) ~= self:interpretScript(s.r)
  elseif s:is_a(Lt)       then return self:interpretScript(s.l) < self:interpretScript(s.r)
  elseif s:is_a(LtEq)     then return self:interpretScript(s.l) <= self:interpretScript(s.r)
  elseif s:is_a(Gt)       then return self:interpretScript(s.l) > self:interpretScript(s.r)
  elseif s:is_a(GtEq)     then return self:interpretScript(s.l) >= self:interpretScript(s.r)
  elseif s:is_a(Any)      then return list.any(s.conditions, function(x) return self:evaluateCondition(x) end)
  elseif s:is_a(All)      then return list.all(s.conditions, function(x) return self:evaluateCondition(x) end)
  elseif s:is_a(Contains) then return self:interpretScript(s.container):contains(s.v)
  elseif s:is_a(Not)      then return not self:evaluateCondition(s.condition)

  -- TODO: hack. PlayerDataScript is not a ConditionScript...gross.
  elseif s:is_a(PlayerDataScript) then return s.playerDataF(self:readPlayerData())

  -- this should be a type error, but, we dont get those in lua.
  else return false
  end
end

-- TODO: could move some of this into map_scripts
function Game:closeRepelTimerWindow()
  if self.repelTimerWindowOpen then
    waitFrames(30)
    pressB(2)
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
end

function Game:searchGroundScript ()
  self.searchSpots:searchAt(self:getLocation())
end

-- TODO: this whole function needs to get redone completely. this is just a hack.
function Game:addWarp(warp)
  if table.containsUsingDotEquals(self.warps, warp) then
    -- print("NOT Adding warp, it already exists!: " .. tostring(warp))
    return
  end

  print("Adding warp: " .. tostring(warp))
  table.insert(self.warps, warp)

  -- TODO: this is just terrible....
  self.warps = table.concat(self.warps, list.map(self.warps, swapSrcAndDest))

  -- TODO: these two lines just reload absolutely everything.
  -- this is really not ideal, but, its probably fine for now.
  -- eventually we will want to do the minimal amount of work possible here.
  for i = 2, 29 do self.maps[i]:resetWarps(self.warps) end
  self:resetGraphs()
end

function Game:resetGraphs()
  self.graphsWithKeys = readAllGraphs(self.memory, true, self.maps, self.warps)
  self.graphsWithoutKeys = readAllGraphs(self.memory, false, self.maps, self.warps)
end

function containsPoint(tbl, p)
  if tbl[p.mapId] == nil then return false end
  if tbl[p.mapId][p.x] == nil then return false end
  return tbl[p.mapId][p.x][p.y] ~= nil
end

function Game:shortestPath(startNode, endNode)
  local allGraphs = self:getCombinedGraphs()

  function insertPoint(tbl, p, value)
    if tbl[p.mapId] == nil then tbl[p.mapId] = {} end
    if tbl[p.mapId][p.x] == nil then tbl[p.mapId][p.x] = {} end
    tbl[p.mapId][p.x][p.y] = value
  end

  function solve(s)
    local q = Queue()
    q:push(s)

    local visited = {}
    local prev = {}
    insertPoint(visited, s, true)

    while not q:isEmpty() do
      local node = q:pop()
      -- we have to do this check here because we may have pushed on a neighbor that we've never seen on the overworld.
      -- and therefore it wouldn't appear in the graph.
      if allGraphs[node.mapId].graph[node.y] ~= nil then
        local neighbors = allGraphs[node.mapId].graph[node.y][node.x]

        if neighbors ~= nil then -- it can be nil if we've never seen it on the overworld.
          for _, neighbor in ipairs(neighbors) do
            if not containsPoint(visited, neighbor) then
              q:push(neighbor)
              insertPoint(visited, neighbor, true)
              insertPoint(prev, neighbor, {node, neighbor} )
            end
          end
        end
      end
    end

    return prev
  end

  function reconstruct(s, e, prev)
    local path = {}
    local at = e
    while not (at == nil) do
      if prev[at.mapId] == nil or prev[at.mapId][at.x] == nil or prev[at.mapId][at.x][at.y] == nil
        then
          table.insert(path, at)
          at = nil
        else
          table.insert(path, prev[at.mapId][at.x][at.y][2])
          at = prev[at.mapId][at.x][at.y][1]
      end
    end
    local pathR = table.reverse(path)
    return pathR[1]:equals(s) and pathR or {}
  end

  return reconstruct(startNode, endNode, solve(startNode))
end

function swapSrcAndDest(w) return w:swap() end

function Game:isDoorOpen(loc)
  return containsPoint(self.unlockedDoors, loc)
end

function Game:saveUnlockedDoor(loc)
  -- todo: if this is the throne room
  -- then we need to set that tile to brick instead of a door
  -- and then we will probably have to regenerate the graphs or whatever.
  if (loc:equalsPoint(Point(TantegelThroneRoom, 4, 7))) then
    self.maps[TantegelThroneRoom]:setTileAt(4, 7, 6) -- 6 for brick. TODO: we need names for things like that
    self:resetGraphs()
  end
  table.insert(self.unlockedDoors, loc)
end

MovementCommand = class(function(a,direction,from,to)
  a.direction = direction
  a.from = from
  a.to = to
end)

function MovementCommand:sameDirection (other)
  return self.direction == other.direction
end

-- TODO: this shit seems to work... but im not sure i understand it. lol
-- there is definitely a way to do this that is more intuitive.
function convertPathToCommands(pathIn, maps)
  function directionFromP1ToP2(p1, p2)
    local res = {}

    function move(next)
      if p2.type == NeighborType.STAIRS then return MovementCommand("Stairs", p1, p2) end
      if p2.type == NeighborType.BORDER_LEFT then return MovementCommand(LEFT, p1, p2) end
      if p2.type == NeighborType.BORDER_RIGHT then return MovementCommand(RIGHT, p1, p2) end
      if p2.type == NeighborType.BORDER_UP then return MovementCommand(UP, p1, p2) end
      if p2.type == NeighborType.BORDER_DOWN then return MovementCommand(DOWN, p1, p2) end
      if p2.type == NeighborType.SAME_MAP then
        if p2.y < p1.y then return MovementCommand(UP, p1, next) end
        if p2.y > p1.y then return MovementCommand(DOWN, p1, next) end
        if p2.x < p1.x then return MovementCommand(LEFT, p1, next) end
        if p2.x > p1.x then return MovementCommand(RIGHT, p1, next) end
      else print("i have no idea what is going on with the neighbor type")
      end
    end

    function nextTileIsDoor()
      if p2.mapId == OverWorldId then return false
      else return maps[p2.mapId]:getTileAt(p2.x, p2.y).name == "Door"
      end
    end

    if nextTileIsDoor() then
      table.insert(res,move(p1))
      table.insert(res, MovementCommand("Door", p2, p2))
      table.insert(res,move(p2))
    else
      table.insert(res,move(p2))
    end

    return res
  end

  local path = table.copy(pathIn)

  -- todo: consider if we should just throw an error here.
  -- an empty path would be really weird
  if(#(path) == 0) then return {} end

  local commands = list.join(list.zipWith(directionFromP1ToP2, path, list.drop(1, path)))

  return list.foldLeft(commands, {}, function(acc, c)
    if c.direction == "Stairs" then table.insert(acc, c)
    elseif #(acc) > 0 and acc[#(acc)]:sameDirection(c) then acc[#(acc)].to = c.to
    else table.insert(acc, c)
    end
    return acc
  end)
end

function Game:stateMachine()
  if self.dead then self:dealWithDeath()
  elseif self.mapChanged then self:dealWithMapChange()
  elseif self:getMapId() == 0 then
    -- print("I think we are still on map 0 man!")
    self:interpretScript(self.scripts.GameStartMenuScript)
  else self:grindOrExplore()
  end
end

function Game:grindOrExplore()
  local pd = self:readPlayerData()
  local currentLevel = pd.stats.level
  local grind = getGrindInfo(pd)
  if self:getMapId() == OverWorldId and grind ~= nil
    -- we have a good monster to grind on, so, grind.
    then self:grind(grind, currentLevel)
    -- if haven't seen anything worth fighting... then i guess just explore...
    else self:explore()
  end
end

function Game:grind(grind, currentLevel)
  print("GRINDING: ", tostring(grind))
  -- TODO: if one is forest and the other is desert, we want to pick desert.
  -- in general, we want to pick the tiles with the highest encounter rate.
  local neighbor = self.overworld:grindableNeighbors(grind.location.x, grind.location.y)[1]

  while(self.memory:getLevel() == currentLevel and not self.dead) do
    self:goTo(grind.location)
    self:goTo(neighbor)
  end
end

function Game:atFirstImportantLocation()
  return self.overworld.importantLocations ~= nil and
         #(self.overworld.importantLocations) > 0 and
         self.overworld.importantLocations[1].location:equals(self:getLocation())
end

function Game:explore()
  local loc = self:getLocation()
  local atDestination = self.exploreDest ~= nil and self.exploreDest:equals(loc)

  if atDestination then
    -- print("we are already at our destination...so gonna pick a new one... currently at: " .. tostring(loc))
    if loc.mapId == OverWorldId then
      -- if the location is in overworld.importantLocations, then we have to remove it.
      -- TODO: this code is awful
      if self:atFirstImportantLocation()
      then
        -- print("removing important location")
        self:removeFirstImportantLocation()
        self.exploreDest = nil
        self:exploreStaticMap()
     else
        self:exploreStart()
      end
    else self:exploreStaticMap()
    end
  else
    if loc.mapId == OverWorldId then
      if self.exploreDest ~= nil then self:exploreMove()
      else self:exploreStart()
      end
    else self:exploreStaticMap()
    end
  end
end

function Game:exploreStaticMap()
  waitUntil(function() return self:onStaticMap() end, 240, "on static map")
  self:dealWithMapChange()
  local loc = self:getLocation()
  local script = self.scripts.MapScripts[loc.mapId]

  if script ~= nil then self:interpretScript(script)
  else
    if (emu.framecount() % 60 == 0) then
      print("i don't yet know how to explore this map: " .. tostring(loc), ", " .. tostring(STATIC_MAP_METADATA[loc.mapId]))
    end
  end
end

function Game:removeFirstImportantLocation()
  self.overworld.importantLocations = list.delete(self.overworld.importantLocations, 1)
end

function Game:exploreStart()
  -- print("no destination yet, about to get one")
  local loc = self:getLocation()
  -- TODO: if there are multiple new locations, we should pick the closest one.
  local seeSomethingNew = #(self.overworld.importantLocations) > 0
  if seeSomethingNew then
    local newImportantLoc = self.overworld.importantLocations[1].location
    -- if the the new location we have spotted on the overworld is tantegel itself, ignore it.
    if newImportantLoc:equals(self.scripts.tantegelLocation) then
      -- print("I see a castle, but its just tantegel, so I'm ignoring it")
      self:removeFirstImportantLocation()
    elseif self.overworld.importantLocations[1].type == ImportantLocationType.CHARLOCK then
      print("I see Charlock!")
      self:interpretScript(self.scripts.EnterCharlock)
      self:removeFirstImportantLocation()
    else
      if self.exploreDest == nil or not self.exploreDest:equals(newImportantLoc) then
        print("I see something new at: ", newImportantLoc)
        self:chooseNewDestinationDirectly(self.overworld.importantLocations[1].location)
      end
    end
  else
    self:chooseNewDestination(function (k) return self:chooseClosestBorderTile(k) end)
  end
  print("new destination is: " .. tostring(self.exploreDest))
end

-- what we really should do here is pick a random walkable border tile
-- then get one if its unseen neighbors and walk to that location.
-- walking to the border tile itself is kinda useless. we need to walk into unseen territory.
function Game:chooseRandomBorderTile(borderOfKnownWorld)
  print("picking random border tile")
  local nrBorderTiles = #borderOfKnownWorld
  return borderOfKnownWorld[math.random(nrBorderTiles)]
end

function Game:chooseClosestBorderTile(borderOfKnownWorld)
  print("picking closest border tile")
  local loc = self:getLocation()
  local d = list.min(borderOfKnownWorld, function(t)
    return math.abs(t.x - loc.x) + math.abs(t.y - loc.y)
  end)
  return d
end

function Game:chooseNewDestination(tileSelectionStrat)
  -- otherwise, we either dont have a destination so we need to get one
  -- or we are at our destination already, so we need a new one
  local borderOfKnownWorld = self.overworld:knownWorldBorder()
--   table.print(borderOfKnownWorld)
  local nrBorderTiles = #borderOfKnownWorld
  -- TODO: this is an error case that i might need to deal with somehow.
  if nrBorderTiles == 0 then
    print("NO BORDER TILES!")
    return
  end

  self:chooseNewDestinationDirectly(tileSelectionStrat(borderOfKnownWorld))
end

function Game:chooseNewDestinationDirectly(newDestination)
  -- print("new destination", newDestination, self.overworld:getOverworldMapTileAt(newDestination.x, newDestination.y))
  self.exploreDest = newDestination
end

function Game:getCombinedGraphs()
  local staticGraphs = self:haveKeys() and self.graphsWithKeys or self.graphsWithoutKeys
  local graphs = {}
  graphs[1] = Graph(self.overworld:knownWorldGraph(), self:haveKeys())
  for i, g in pairs(staticGraphs) do graphs[i] = g end
  return graphs
end

function Game:exploreMove()
  print("Moving from: ", self:getLocation(), " to ", self.exploreDest)
  -- TODO: we are calculating the shortest path twice... we need to do better than that
  -- here... if we cant find a path to the destination, then we want to just choose a new destination
  local path = self:shortestPath(self:getLocation(), self.exploreDest)
  if path == nil or #(path) == 0 then
    print("couldn't find a path from player location: ", self:getLocation(), " to ", self.exploreDest)
    self:chooseNewDestination(function (k) return self:chooseRandomBorderTile(k) end)
  else
    self:castRepel()
    local madeItThere = self:goTo(self.exploreDest) == GotoExitValues.AT_LOCATION
    -- if we are there, we need to nil this out so we can pick up a new destination
    if madeItThere then self.exploreDest = nil end
  end
end

function Game:startEncounter()
 if (self:getMapId() > 0) then
    local enemyId = self:getEnemyId()
    local enemy = Enemies[enemyId]
    print ("entering battle vs a " .. enemy.name .. " " .. tostring(enemy))
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
    holdA(180)
    self.leveledUp = false
  end

  self.inBattle = false
  self.runSuccess = false
  self.enemyKilled = false
  self.enemy = nil
end

-- TODO: this is broken
function Game:executeDragonLordBattle()
--   function battleEnded () return not self.inBattle end
--   waitUntil(battleEnded, 120)
--   holdAUntil(battleEnded, 240)
--   waitUntil(battleEnded, 60)
--   pressA(10)
--   self.inBattle = false
end

function Game:enemyRun()
  print("the enemy is running!")
  self.inBattle = false
end

function Game:playerRunSuccess()
  print("you are running!")
  self.runSuccess = true
end

function Game:playerRunFailed()
  print("you are NOT running!")
  self.runSuccess = false
end

function Game:onPlayerMove()
  -- this wasn't working quite right
  -- so i just folded it into the followPath algo.
  -- i think that is a better spot for it anyway
  -- print("position as changed to: " .. tostring(self:getLocation()))
end

function Game:onMapChange()
  -- print("recording that the map has changed.")
  self.mapChanged = true
end

function Game:dealWithDeath()
  waitFrames(120)
  holdAUntil(function () return self:getMapId() == 5 end, "map is throne room", 240)
  self.dead = false
end

function Game:dealWithMapChange()
  local newMapId = self:getMapId()

  if newMapId < 1 then
    -- print("The map changed, but dood, we are on map 0, so must be the menu or something...")
    return
  end

  local oldMapId = self.currentMapId
  local newLoc   = self:getLocation()
  -- print("The map has changed! current position: " ..  tostring(newLoc) .. ", old map: " .. tostring(oldMapId))

  if newMapId == OverWorldId then self.chests:closeAll()
  elseif newMapId > 1 and newMapId <= 29 then
    if not self.maps[newMapId].seenByPlayer then
      print("now seen by player: ", self.maps[newMapId].mapName)
      self.maps[newMapId].seenByPlayer = true
    end
  end

  if newMapId ~= 1 and newMapId ~= Tantegel then
    local coordinatesList = self.maps[newMapId].overworldCoordinates
    if coordinatesList ~= nil then
      if #coordinatesList == 1 then
        self:addWarp(Warp(newLoc, coordinatesList[1]))
      else
        -- this must be swamp cave, because it has more than one entrance
        if newLoc:equals(SwampNorthEntrance) then
          print("adding warp to SwampNorthEntrance")
          self:addWarp(Warp(newLoc, coordinatesList[1]))
        elseif newLoc:equals(SwampSouthEntrance) then
          print("adding warp to SwampSouthEntrance")
          self:addWarp(Warp(newLoc, coordinatesList[2]))
        end
      end
    end
  elseif oldMapId == SwampCave then
    print("leaving swamp cave")
    local coordinatesList = self.maps[SwampCave].overworldCoordinates
    if newLoc:equals(coordinatesList[1]) then
      print("adding warp to SwampNorthEntrance")
      self:addWarp(Warp(newLoc, SwampNorthEntrance))
    else
      print("adding warp to SwampSouthEntrance")
      self:addWarp(Warp(newLoc, SwampSouthEntrance))
    end
--   elseif oldMapId == Tantegel then
--     print("leaving Tantegel")
--     self:addWarp(Warp(TantegelEntrance, self.maps[Tantegel].overworldCoordinates[1]))
  end

  self.currentMapId = newMapId
  self.mapChanged = false
end

-- TODO: does this work in battle as well as on the overworld?
-- it probably should, but, i have not checked yet.
-- TODO: didn't work completely for RainbowDrop
-- might need to do a little extra work there.
function Game:useItem(item)
  local itemIndex = self:readPlayerData().items:itemIndex(item)
  -- print("itemIndex", itemIndex)
  if itemIndex == nil then
    print("can't use " .. ITEMS[item] .. ", we don't have it.")
    return
  else
    self:interpretScript(self.scripts.OpenItemMenu)
    -- TODO: if it is faster to press UP, we should do that
    for i = 1, itemIndex-1 do pressDown(2) end
    -- wait 2 seconds for the item to be done being used.
    -- TODO: do all items take the same length to use?
    -- or is it possible to get out sooner than 2 seconds?
    pressA(120)
    pressB(2)
  end
end

-- TODO: does this work in battle as well as on the overworld?
-- it probably should, but, i have not checked yet.
function Game:cast(spell)
  local pd = self:readPlayerData()
  local spellIndex = pd.spells:spellIndex(spell)
  if spellIndex == nil then
    -- print("can't cast " .. tostring(spell) .. ", spell hasn't been learned.")
    return
  elseif pd.stats.currentMP < spell.mp then
    print("can't cast " .. tostring(spell) .. ", not enough mp.")
    return
  else
    self:interpretScript(self.scripts.OpenSpellMenu)
    -- TODO: if it is faster to press UP, we should do that
    for i = 1, spellIndex-1 do pressDown(2) end
    -- wait 2 seconds for the spell to be done casting.
    -- TODO: do all spells take the same length to cast?
    -- or is it possible to get out sooner than 2 seconds?
    pressA(120)
    pressB(2)
  end
end

function Game:castRepel(disregardTimer)
  if disregardTimer then self:cast(Repel)
  else
    if self.memory:getRepelTimer() > 1  then
      print("wanted to cast repel, but it is still on! Won't cast it.")
    else
      self:cast(Repel)
    end
  end
end

function Game:useRainbowDrop()
  self:useItem(RainbowDrop)
  self.overworld:useRainbowDrop(self:getLocation())
end

function Game:haveKeys()
  return self:readPlayerData().items:haveKeys()
end

function Game:endRepelTimer()
  print("repel has ended")
  self.repelTimerWindowOpen = true
end

function Game:nextLevel()
  print("i think i just leveled up.")
  self.leveledUp = true
end

function Game:deathBySwamp()
  print("i think i just died in a swamp.")
  self.dead = true
end

function Game:enemyDefeated()
  -- print("Killed an enemy.")
  self.enemyKilled = true
  self.inBattle = false
end

function Game:playerDefeated()
  print("I just got killed.")
  self.dead = true
  self.inBattle = false
end

function Game:talkToShopKeeper()
  self.weaponAndArmorShops:visitShopAt(self:getLocation())
  -- TODO: here, we just print out things that we know.
  -- but really, we need to make a decision on if we should buy the upgrade
  -- and if so, then go ahead and actualy buy it.
  local pd = self:readPlayerData()
  print(self.weaponAndArmorShops:getAllKnownUpgrades(pd))
  print(self.weaponAndArmorShops:getAllKnownAffordableUpgrades(pd))
end

function Game:talkToInnKeeper()
  print("TODO: talkToInnKeeper")
end