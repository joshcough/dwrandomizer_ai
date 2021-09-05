require 'mem'
require 'controller'
require 'helpers'
require 'overworld'
require 'static_maps'

Game = class(function(a, memory, warps, overworld, maps, graphsWithKeys, graphsWithoutKeys)
  a.memory = memory
  a.warps = warps
  a.overworld = overworld
  a.maps = maps
  a.graphsWithKeys = graphsWithKeys
  a.graphsWithoutKeys = graphsWithoutKeys
end)

function newGame(memory)
  local overworld = OverWorld(readOverworldFromROM(memory))
  local warps = table.concat(WARPS, list.map(WARPS, swapSrcAndDest))
  local maps = readAllStaticMaps(memory, warps)
  local graphsWithKeys = readAllGraphs(memory, true, maps, warps)
  local graphsWithoutKeys = readAllGraphs(memory, false, maps, warps)
  return Game(memory, warps, overworld, maps, graphsWithKeys, graphsWithoutKeys)
end

function Game:goTo(dest)
  local path = self:shortestPath(self.memory:getLocation(), dest, true)
  local commands = convertPathToCommands(path, self.maps)
  -- for i,c in pairs(commands) do print(i, c) end
  for i,c in pairs(commands) do
    -- print(i, c)
    if c.direction == "Door" then self:openDoorScript()
    elseif c.direction == "Stairs" then self:takeStairs(c.from, c.to)
    else holdButtonUntil(c.direction, function ()
          local p = self.memory:getLocation()
          -- print("current point: ", memory:getLocation(), "c.to: ", c.to, "equal?: ", p.equals(c.to))
          return p:equals(c.to)
        end
        )
    end
  end
end

function Game:openChestAt (loc)
  self:goTo(loc)
  self:openChestScript()
end

function Game:openChestScript ()
  print("======opening chest=======")
  holdA(30)
  waitFrames(10)
  pressUp(2)
  pressRight(2)
  pressA(20)
end

function Game:openDoorScript ()
  print("======opening door=======")
  holdA(30)
  waitFrames(10)
  pressDown(2)
  pressDown(2)
  pressRight(2)
  pressA(20)
end

-- TODO: looks like the to argument here isn't really needed.
function Game:takeStairs (from, to)
  -- print("======taking stairs=======")
  holdA(30)
  waitFrames(30)
  pressDown(2)
  pressDown(2)
  pressA(60)

  if from:equals(TantegelBasementStairs)
  then
    local loc = self.memory:getLocation()
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

  function solve(s)
    local q = Queue()
    q:push(s)

    local visited = {}
    for m = 2, 29 do
      visited[m] = {}
      for y = 0, allGraphs[m].staticMap.height-1 do visited[m][y] = {} end
    end

    visited[s.mapId][s.y][s.x] = true

    local prev = {}

    for m = 2, 29 do
      prev[m] = {}
      for y = 0, allGraphs[m].staticMap.height-1 do prev[m][y] = {} end
    end

    while not q:isEmpty() do
      local node = q:pop()
      local neighbors = allGraphs[node.mapId].graph[node.y][node.x]

      for _, neighbor in ipairs(neighbors) do
        if not visited[neighbor.mapId][neighbor.y][neighbor.x] then
      	  q:push(neighbor)
      	  visited[neighbor.mapId][neighbor.y][neighbor.x] = true
      	  prev[neighbor.mapId][neighbor.y][neighbor.x] = node
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
      at = prev[at.mapId][at.y][at.x]
    end
    local pathR = table.reverse(path)
    return pathR[1]:equals(s) and pathR or {}
  end

  local prev = solve(startNode)
  return reconstruct(startNode, endNode, prev)
end

function swapSrcAndDest(w) return w:swap() end
