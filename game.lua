require 'mem'
require 'controller'
require 'helpers'
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
  a.in_battle = false
  a.exploreDest = nil
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

function Game:goTo(dest, allGraphs)
  local loc = self:getLocation()
  local path = self:shortestPath(loc, dest, true, allGraphs)
  self:followPath(path)
end

function Game:followPath(path)
  local commands = convertPathToCommands(path, self.maps)
  for i,c in pairs(commands) do
    if c.direction == "Door" then self:openDoorScript()
    elseif c.direction == "Stairs" then self:takeStairs(c.from, c.to)
    else holdButtonUntil(c.direction, function ()
          local loc = self:getLocation()
          -- print("current point: ", memory:getLocation(), "c.to: ", c.to, "equal?: ", p.equals(c.to))
          return loc:equals(c.to) or self.in_battle
        end
        )
    end
  end
end


function Game:openChestAt (loc)
  self:goTo(loc)
  self:openChestScript()
end

function Game:openMenu()
  holdA(30)
  waitFrames(10)
end

function Game:openChestScript ()
  print("======opening chest=======")
  self:openMenu()
  pressUp(2)
  pressRight(2)
  pressA(20)
end

function Game:openDoorScript ()
  print("======opening door=======")
  self:openMenu()
  pressDown(2)
  pressDown(2)
  pressRight(2)
  pressA(20)
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

function Game:shortestPath(startNode, endNode, haveKeys, allGraphs)
  if allGraphs == nil then
    allGraphs = haveKeys and self.graphsWithKeys or self.graphsWithoutKeys
  end

  function insertPoint(tbl, p, value)
    if tbl[p.mapId] == nil then tbl[p.mapId] = {} end
    if tbl[p.mapId][p.x] == nil then tbl[p.mapId][p.x] = {} end
    tbl[p.mapId][p.x][p.y] = value
  end

  function containsPoint(tbl, p)
    if tbl[p.mapId] == nil then return false end
    if tbl[p.mapId][p.x] == nil then return false end
    return tbl[p.mapId][p.x][p.y] ~= nil
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


-- TODO: we must pause the state machine (or in this case just exploration)
-- whenever an encounter happens

-- === state machine ===
-- in battle
-- not in battle
--   no destination
--   have destination but not moving to it (because just got out of battle, probably)
--   moving to dest
function Game:explore()
  local loc = self:getLocation()
  -- if we have destination and we aren't at it, move towards it.
  if self.exploreDest ~= nil and not self.exploreDest:equals(loc) then
    print("we have a destination. about to move towards it from: ", self:getLocation(), " to ", self.exploreDest)
    self:exploreMove()
  else
    print("no destination yet, about to get one")
    self:exploreStart()
    print("done setting destination")
  end
end

-- TODO: here, we need to ask a question:
-- can we see any towns/caves that we haven't been to yet?
-- if so, we probably just want to walk directly to them.
-- if not, we want to pick a random place and walk to it.
--   we will want to avoid walking into towns and caves on the way there though.
function Game:exploreStart()
  local seeSomethingNew = false -- TODO: write this
  if seeSomethingNew then
    -- print("spotted something new... walking to it...etc")
    -- self.exploreDest = location of the new thing
  else
    self:chooseNewDestination(function (k) return self:chooseClosestBorderTile(k) end)
  end
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

  local newDestination = tileSelectionStrat(borderOfKnownWorld)
  print("new destination", newDestination, self.overworld:getOverworldMapTileAt(newDestination.x, newDestination.y))
  self.exploreDest = newDestination
end

function Game:exploreMove()
  local graphOfKnownWorld = { Graph(self.overworld:knownWorldGraph(), false) }
  -- TODO: we are calculating the shortest path twice... we need to do better than that
  -- here... if we cant find a path to the destination, then we want to just choose a new destination
  local path = self:shortestPath(self:getLocation(), self.exploreDest, true, graphOfKnownWorld)
  if path == nil or #(path) == 0 then
    print("couldn't find a path from player location: ", self:getLocation(), " to ", self.exploreDest)
    self:chooseNewDestination(function (k) return self:chooseRandomBorderTile(k) end)
  else
    self:cast(Repel)
    self:goTo(self.exploreDest, graphOfKnownWorld)
    -- if we are there, we need to nil this out so we can pick up a new destination
    if self:getLocation().equals(self.exploreDest) then self.exploreDest = nil end
  end
end

function Game:startEncounter()
 if (self:getMapId() > 0) then
    local enemyId = self:getEnemyId()
    print ("entering battle vs a " .. Enemies[enemyId])
    -- actually, set every encounter to a slime. lol!
    self.memory:setEnemyId(0)
    self.in_battle = true
  end
end

function Game:executeBattle()
  waitFrames(120)
  clearController()
  holdA(240)
  waitFrames(60)
  pressA(10)
  self.in_battle = false
end

function Game:onPlayerMove()
  if self:getMapId() == 1
    then
      -- self:printVisibleGrid()
      self.overworld:getVisibleOverworldGrid(self:getX(), self:getY())
      print("percentageOfWorldSeen: " .. self:percentageOfWorldSeen())
  end
end

function Game:openSpellMenu()
  self:openMenu()
  pressRight(2)
  pressA(2)
  waitFrames(30)
end

function Game:cast(spell)
  local spellIndex = self.playerData.spells:spellIndex(spell)
  if spellIndex == nil then
    print("can't cast " .. tostring(spell) .. ", spell hasn't been learned.")
    return
  else
    self:openSpellMenu()
    for i = 1, spellIndex-1 do pressDown(2) end
    pressA(120)
    pressB(2)
  end
end
