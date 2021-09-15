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
  a.memory = memory
  a.warps = warps
  a.overworld = overworld
  a.maps = maps
  a.graphsWithKeys = graphsWithKeys
  a.graphsWithoutKeys = graphsWithoutKeys
  a.playerData = memory:readPlayerData()
  a.inBattle = false
  a.exploreDest = nil
  a.tantegelLoc = nil
  a.repelTimerWindowOpen = false
  a.unlockedDoors = {}
  -- TODO: when we get back on the overworld, we need to set this back to {}
  a.openChests = {}
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
GotoExitValues = enum.new("Follow Path Exit Values", {"AT_LOCATION", "IN_BATTLE", "REPEL_TIMER", "NO_PATH", "BUG"})

function Game:goTo(dest)
  local loc = self:getLocation()
  if loc:equals(dest) then
    print("I was asked to go to: " .. tostring(dest) .. ", but I am already there!")
    return GotoExitValues.AT_LOCATION
  end
  local path = self:shortestPath(loc, dest)
  if path == nil or #path == 0 then
    print("Could not create path from: " .. tostring(loc) .. " to: " .. tostring(dest))
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
        self:goTo(dest)
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
    elseif c.direction == "Door" then self:openDoorScript(c.to)
    elseif c.direction == "Stairs" then self:takeStairs(c.from, c.to)
    else
      holdButtonUntil(c.direction, function ()
        dest = c.to
        local loc = self:getLocation()
        -- print("current point: ", memory:getLocation(), "c.to: ", c.to, "equal?: ", p:equals(c.to))
        return loc:equals(c.to) or self.inBattle or self.repelTimerWindowOpen
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
  print(s)
  if     self.inBattle then self:executeBattle()
  elseif self.repelTimerWindowOpen then self:closeRepelTimerWindow()
  elseif s:is_a(ActionScript)
    then
      if     s.enum == Actions.DO_NOTHING then return
      elseif s.enum == Actions.OPEN_CHEST then self:openChestScript()
      elseif s.enum == Actions.SEARCH     then self:searchGroundScript()
      elseif s.enum == Actions.EXIT       then self:exitDungeonScript()
      elseif s.enum == Actions.DEATH_WARP then self:deathWarp()
      elseif s.enum == Actions.DEATH_WARP then self:savePrincess()
      elseif s.enum == Actions.DEATH_WARP then self:fightDragonLord()
      end
  elseif s:is_a(Goto) then self:goTo(s.location)
  elseif s:is_a(BranchScript)
    then
      local branch = self:evaluateCondition(s.condition) and s.trueBranch or s.falseBranch
      -- future debugging, i promise: print(branch)
      self:interpretScript(branch)
  elseif s:is_a(ListScript)
    then
      for i,branch in pairs(s.scripts) do
        self:interpretScript(branch)
      end
  end
end

function Game:evaluateCondition(s)
  if s == HaveKeys then return self:haveKeys()
  elseif s:is_a(IsChestOpen) then
    print("is the chest open at " .. tostring(s.location), table.containsUsingDotEquals(self.openChests, s.location))
    return table.containsUsingDotEquals(self.openChests, s.location)
  else return false
  end
end

function Game:closeRepelTimerWindow()
  if self.repelTimerWindowOpen then
    waitFrames(30)
    pressB(2)
    self.repelTimerWindowOpen = false
  end
end

function Game:openChestAt (loc)
  local madeItThere = self:goTo(loc)
  if madeItThere then self:openChestScript() end
  return madeItThere
end

function Game:openMenu()
  holdA(30)
  waitFrames(10)
end

-- TODO: we have to implement this. it might be hard
-- we can either cast outside (if possible)
-- or we have to like, lookup the warp point out of this dungeon
-- (which means we will have to keep track of that better)
-- and then follow the path out of that.
-- but lets how we even follow paths in this interpreter first.
-- for now, doing nothing.
function Game:exitDungeonScript ()
end

-- TODO: i have no idea how i am going to do this yet.
function Game:deathWarp ()
end

-- TODO: this one should be easy.
function Game:savePrincess ()
end

-- todo: this one shouldn't really be that hard either
function Game:fightDragonLord ()
end

-- TODO: we could just implement this the same way as `self:searchGroundScript()`
function Game:openChestScript ()
  print("======opening chest=======")
  self:openMenu()
  pressUp(2)
  pressRight(2)
  table.insert(self.openChests, self:getLocation())
  pressA(40)
end

function Game:searchGroundScript ()
  print("======searching ground=======")
  self:openMenu()
  pressUp(2)
  pressA(40)
end

function Game:openDoorScript (point)
  print("======opening door at " .. tostring(point) .. "=======")
  if self:isDoorOpen(point) then
    print("actually, that door is already open")
    return
  end
  self:openMenu()
  pressDown(2)
  pressDown(2)
  pressRight(2)
  pressA(20)
  self:saveUnlockedDoor(point)
end

-- TODO: looks like the to argument here isn't really needed.
function Game:takeStairs (from, to)
  -- print("======taking stairs=======")
  self:openMenu()
  pressDown(2)
  pressDown(2)
  pressA(60)

  if from:equals(TantegelBasementStairs)
  then
    local loc = self:getLocation()
    print("Discovered what's in Tantegel's basement ... it's " .. self.maps[loc.mapId].mapName .. "!!!")
    self:addWarp(Warp(TantegelBasementStairs, loc))
  end
end

function Game:openThroneRoomChests ()
  print("======opening throne room chests=======")
  self:openChestAt(Point(TantegelThroneRoom, 4, 4))
  self:openChestAt(Point(TantegelThroneRoom, 5, 4))
  self:openChestAt(Point(TantegelThroneRoom, 6, 1))
end

function Game:leaveThroneRoom()
  print("======leaving throne room=====")
  self:goTo(Point(Tantegel, 0, 9))
end

function Game:menuScript ()
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

function Game:kingScript ()
  print("======executing king script=======")
  holdA(250)
end

function Game:leaveTantegelFromX0Y9()
  print("======leaving tantegel =======")
  holdLeft(30)
  self.tantegelLoc = self:getLocation()
  print("self.tantegelLoc: ", self.tantegelLoc)
end

function Game:throneRoomScript ()
  print("======executing throne room script=======")
  self:kingScript ()
  self:openThroneRoomChests()
  self:leaveThroneRoom()
end

function Game:gameStartScript ()
  print("======executing game start script=======")
  self:menuScript()
  self:throneRoomScript()
  self:leaveTantegelFromX0Y9()
end

-- TODO: this whole function needs to get redone completely. this is just a hack.
function Game:addWarp(warp)
  table.insert(self.warps, warp)
  table.insert(self.warps, warp)

  -- TODO: this is just terrible....
  self.warps = table.concat(self.warps, list.map(self.warps, swapSrcAndDest))

  -- TODO: these three lines just reload absolutely everything.
  -- this is really not ideal, but, its probably fine for now.
  -- eventually we will want to do the minimal amount of work possible here.
  self.maps = readAllStaticMaps(self.memory, self.warps)
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

        if neighbors ~= nil then -- it can be nil if we've never visited it on the overworld.
          for _, neighbor in ipairs(neighbors) do
            if not containsPoint(visited, neighbor) then
              q:push(neighbor)
              insertPoint(visited, neighbor, true)
              insertPoint(prev, neighbor, node)
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
      table.insert(path, at)
      if prev[at.mapId] == nil or prev[at.mapId][at.x] == nil or prev[at.mapId][at.x][at.y] == nil
        then at = nil
        else at = prev[at.mapId][at.x][at.y]
      end
    end
    local pathR = table.reverse(path)
    return pathR[1]:equals(s) and pathR or {}
  end

  return reconstruct(startNode, endNode, solve(startNode))
end

function swapSrcAndDest(w) return w:swap() end

function Game:isDoorOpen(point)
  return containsPoint(self.unlockedDoors, point)
end

function Game:saveUnlockedDoor(point)
  table.insert(self.unlockedDoors, point)
end

-- TODO: this shit seems to work... but im not sure i understand it. lol
-- there is definitely a way to do this that is more intuitive.
function convertPathToCommands(pathIn, maps)
  function directionFromP1ToP2(p1, p2)
    local res = {}

    function move(next)
      if p1.mapId ~= p2.mapId then return MovementCommand("Stairs", p1, p2) end
      if p2.y < p1.y then return MovementCommand(UP, p1, next) end
      if p2.y > p1.y then return MovementCommand(DOWN, p1, next) end
      if p2.x < p1.x then return MovementCommand(LEFT, p1, next) end
      if p2.x > p1.x then return MovementCommand(RIGHT, p1, next) end
    end

    function nextTileIsDoor()
      if p2.mapId == Overworld then return false
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
  self:explore()
end

function Game:atFirstImportantLocation()
  return self.overworld.importantLocations ~= nil and
         #(self.overworld.importantLocations) > 0 and
         self.overworld.importantLocations[1]:equals(self:getLocation())
end

function Game:explore()
  local loc = self:getLocation()
  local atDestination = self.exploreDest ~= nil and self.exploreDest:equals(loc)

  if atDestination then
    print("we are already at our destination...so gonna pick a new one... currently at: " .. tostring(loc))
    if loc.mapId == Overworld then
      -- if the location is in overworld.importantLocations, then we have to remove it.
      -- TODO: this code is awful
      if self:atFirstImportantLocation()
      then
        print("removing important location")
        self.overworld.importantLocations = list.delete(self.overworld.importantLocations, 1)
        self.exploreDest = nil
        self:exploreStaticMap()
     else
        self:exploreStart()
      end
    else self:exploreStaticMap()
    end
  else
    if loc.mapId == Overworld then
      if self.exploreDest ~= nil then self:exploreMove()
      else self:exploreStart()
      end
    else self:exploreStaticMap() end
  end
end

-- TODO: the logic here for getting a script for a map should probably belong in map_scripts.lua
function Game:exploreStaticMap()
  waitUntil(function() return self:onStaticMap() end, 240)
  local loc = self:getLocation()
  if loc.mapId == GarinsGraveLv1
  then self:interpretScript(scripts.exploreGraveScript())
  else
    if (emu.framecount() % 60 == 0) then
      print("i don't yet know how to explore this map: " .. tostring(loc), ", " .. tostring(MAP_DATA[loc.mapId]))
    end
  end
end

function Game:exploreStart()
  print("no destination yet, about to get one")
  local loc = self:getLocation()
  -- TODO: if there are multiple new locations, we should pick the closest one.
  local seeSomethingNew = #(self.overworld.importantLocations) > 0
  if seeSomethingNew then
    local newImportantLoc = self.overworld.importantLocations[1]
    -- if the the new location we have spotted on the overworld is tantegel itself, ignore it.
    if newImportantLoc:equals(self.tantegelLoc) then
      print("I see a castle, but its just tantegel, so I'm ignoring it")
      self.overworld.importantLocations = list.delete(self.overworld.importantLocations, 1)
    else
      if self.exploreDest == nil or not self.exploreDest:equals(newImportantLoc) then
        print("I see something new at: ", newImportantLoc)
        self:chooseNewDestinationDirectly(self.overworld.importantLocations[1])
        -- TODO: once we make it into the new destination, we have some work to do
        --   we have to adjust the warps
        --   record somehow that we have been here
        --   we have to remove this location from self.overworld.importantLocations
      end
    end
  else
    self:chooseNewDestination(function (k) return self:chooseClosestBorderTile(k) end)
  end
  print("done setting destination: " .. tostring(self.exploreDest))
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
  local nrBorderTiles = #borderOfKnownWorld
  -- TODO: this is an error case that i might need to deal with somehow.
  if nrBorderTiles == 0 then return end

  self:chooseNewDestinationDirectly(tileSelectionStrat(borderOfKnownWorld))
end

function Game:chooseNewDestinationDirectly(newDestination)
  print("new destination", newDestination, self.overworld:getOverworldMapTileAt(newDestination.x, newDestination.y))
  self.exploreDest = newDestination
end

function Game:getCombinedGraphs()
  local staticGraphs = self:haveKeys() and self.graphsWithKeys or self.graphsWithoutKeys
  local graphs = {}
  graphs[1] = Graph(self.overworld:knownWorldGraph(), self:haveKeys())
  for i, g in pairs(staticGraphs) do
    graphs[i] = g
  end

  return graphs
end


function Game:exploreMove()
  print("we have a destination. about to move towards it from: ", self:getLocation(), " to ", self.exploreDest)
  -- TODO: we are calculating the shortest path twice... we need to do better than that
  -- here... if we cant find a path to the destination, then we want to just choose a new destination
  local path = self:shortestPath(self:getLocation(), self.exploreDest)
  if path == nil or #(path) == 0 then
    print("couldn't find a path from player location: ", self:getLocation(), " to ", self.exploreDest)
    self:chooseNewDestination(function (k) return self:chooseRandomBorderTile(k) end)
  else
    self:castRepel()
    -- TODO: this is no longer a boolean! dafuq
    local madeItThere = self:goTo(self.exploreDest) == GotoExitValues.AT_LOCATION
    -- if we are there, we need to nil this out so we can pick up a new destination
    if madeItThere then self.exploreDest = nil end
  end
end

function Game:startEncounter()
 if (self:getMapId() > 0) then
    local enemyId = self:getEnemyId()
    print ("entering battle vs a " .. Enemies[enemyId])
    -- actually, set every encounter to a slime. lol!
    self.memory:setEnemyId(0)
    self.inBattle = true
  end
end

function Game:onStaticMap()
  return self:getMapId() > 1 and self:getMapId() < 30
end

function Game:executeBattle()
  function battleEnded () return not self.inBattle end
  waitUntil(battleEnded, 120)
  clearController() -- TODO is this really needed? double check
  holdAUntil(battleEnded, 240)
  waitUntil(battleEnded, 60)
  pressA(10)
  self.inBattle = false
end

function Game:enemyRun()
  print("the enemy is running!")
  self.inBattle = false
end

function Game:playerRun()
  print("you are running!")
  self.inBattle = false
end

function Game:onPlayerMove()
  if self:getMapId() == 1
    then
      -- print(self:getLocation())
      -- self:printVisibleGrid()
      self.overworld:getVisibleOverworldGrid(self:getX(), self:getY())
      print("percentageOfWorldSeen: " .. self:percentageOfWorldSeen())
  end
end

function Game:onMapChange()
  print("The map has changed! currentLoc: " .. tostring(self:getLocation()))
end

function Game:openSpellMenu()
  self:openMenu()
  pressRight(2)
  pressA(2)
  waitFrames(30)
end

-- TODO: does this work in battle as well as on the overworld?
-- it probably should, but, i have not checked yet.
function Game:cast(spell)
  local spellIndex = self.playerData.spells:spellIndex(spell)
  if spellIndex == nil then
    print("can't cast " .. tostring(spell) .. ", spell hasn't been learned.")
    return
  elseif self.playerData.stats.currentMP < spell.mp then
    print("can't cast " .. tostring(spell) .. ", not enough mp.")
    return
  else
    self:openSpellMenu()
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

function Game:haveKeys()
  return self.playerData.items:haveKeys()
end

function Game:endRepelTimer()
  print("repel has ended")
  self.repelTimerWindowOpen = true
end
