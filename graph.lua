require 'Class'
enum = require('enum')
require 'helpers'
require 'locations'
PriorityQueue = require('PriorityQueue')

GraphNodeType = enum.new("Type of graph node", {
  "UNKNOWN", -- tiles on the overworld that we haven't discovered yet.
  "KNOWN", -- tiles on the overworld that we have discovered, or tiles on static maps.
})

GraphNode = class(function(a, nodeType)
  a.nodeType = nodeType
  -- invariant: neighbors must be empty if nodeType == UNKNOWN.
  -- it _might_ be empty if we have discovered it
  -- but only if its not walkable, or there's literally no possible way to get to it.
  -- like a grass node surrounded by mountains. there would not be a path to it.
  a.neighbors = {}
end)

Graph = class(function (a, staticMaps)
  a.graphWithKeys = NewGraph(createStaticMapGraphs(staticMaps, true), true)
  a.graphWithoutKeys = NewGraph(createStaticMapGraphs(staticMaps, false), false)
end)

-- TODO: make this call shortestPaths?
function Graph:shortestPath(startNode, endNode, haveKeys, game)
  local res = nil
  res = haveKeys and self.graphWithKeys:shortestPath(startNode, endNode, game)
                 or  self.graphWithoutKeys:shortestPath(startNode, endNode, game)
  -- log.debug("in shortestPath", res)
  return res.path
end

function Graph:shortestPaths(startNode, endNodes, haveKeys, game)
  local res = nil
  res = haveKeys and self.graphWithKeys:shortestPaths(startNode, endNodes, game)
                 or  self.graphWithoutKeys:shortestPaths(startNode, endNodes, game)
  -- log.debug("in shortestPath", res)
  return res
end

function Graph:knownWorldBorder(overworld)
  return self.graphWithKeys:knownWorldBorder(overworld)
end

function Graph:discover(x, y, game)
  -- log.debug("Graph:discover", x, y, game == nil)
  self.graphWithKeys:discover(x, y, game)
  self.graphWithoutKeys:discover(x, y, game)
end

-- TODO: get these from elsewhere
TantegelThroneRoom = 5

function Graph:unlockThroneRoomDoor()
  -- log.debug("unlocking throne room door")
  self.graphWithoutKeys.rows[TantegelThroneRoom] = self.graphWithKeys.rows[TantegelThroneRoom]
end

function Graph:unlockRimuldar()
  log.debug("unlocking rimular")
  self.graphWithoutKeys.rows[Rimuldar] = self.graphWithKeys.rows[Rimuldar]
end

--when we see an important location (town/cave/castle)
-- we can add the neighbors normally to the neighbors4.
-- but when we actually go into it, then we replace those neighbors
-- with instead of the overworld location, the actual warp location
function Graph:addWarp(warp, overworld)
  if not (warp.src.mapId == OverWorldId or warp.dest.mapId == OverWorldId) then
    log.debug("Not adding warp because there's no overworld in it.", warp)
  end
  -- log.debug("adding warp in Graph", warp)
  self:fixOverworldNeighbors(warp, overworld)
end

-- TODO: pretty major one... if we attempt to grind in a dungeon, this is going to all break
-- because the code is assuming the overworld. see `overworld:grindableNeighbors`
-- it really shouldn't be that way. we need a static map version of grindableNeighbors as well.
function Graph:grindableNeighbors(game,x,y)
  -- log.debug("in grindableNeighbors", x, y)
  local neighbors = self.graphWithKeys:getNodeAt(OverWorldId,x,y,game).neighbors
  return list.filter(neighbors, function(n)
    if n.mapId ~= OverWorldId then return false end
    local tileId = game.overworld:getTileIdAt(n.x, n.y, game)
    local res = (tileId ~= SwampId and tileId < TownId) or tileId == BridgeId
    -- log.debug("in grindableNeighbors filter", n.mapId, n.x, n.y, tileId, res)
    return res
  end)
end

function Graph:fixOverworldNeighbors(warp, overworld)
  local overworldPoint = warp.src.mapId == OverWorldId and warp.src  or warp.dest
  local otherPoint     = warp.src.mapId == OverWorldId and warp.dest or warp.src
  -- log.debug("fixOverworldNeighbors", overworldPoint, otherPoint)

  function go(graph)
    -- we need to get each of the Walkable neighbors4 of the overworldPoint
    -- for each of those points, add add a neighbor (in the correct direction of course) to the otherPoint
    -- there should already be a node in the graph from otherPoint to overworldPoint
    list.foreach(overworld:neighbors(overworldPoint.x,overworldPoint.y), function(outer)
      -- log.debug("OUTER", outer, overworldPoint)
      -- delete the overworldPoint and then add the otherPoint
      graph:getNodeAt(OverWorldId,outer.x,outer.y).neighbors =
        list.map(graph:getNodeAt(OverWorldId,outer.x,outer.y).neighbors, function(inner)
          -- log.debug("INNER", inner, overworldPoint, inner.loc:equals(overworldPoint))
          if inner.loc:equals(overworldPoint) then
            local newNeighbor = Neighbor(otherPoint.mapId, otherPoint.x, otherPoint.y, inner.dir)
            -- log.debug("replacing neighbor of outer", outer, "inner", inner, "with", newNeighbor)
            return newNeighbor
          else
            return inner
          end
        end)
    end)
  end

  go(self.graphWithKeys)
  go(self.graphWithoutKeys)
end

NewGraph = class(function(a, staticMapGraphs, isGraphWithKeys)
  a.rows = {}
  a.isGraphWithKeys = isGraphWithKeys
  a.rows[1] = mkOverworldGraph()
  for i = 2, 29 do
    a.rows[i] = staticMapGraphs[i]
  end
end)

unknown = GraphNode(GraphNodeType.UNKNOWN)

function NewGraph:isDiscovered(m,x,y)
  return self:getNodeAt(m,x,y) ~= unknown
end

function NewGraph:getNodeAt(mapId,x,y)
  return self.rows[mapId][y][x]
end

function NewGraph:getNodeAtPoint(p)
  return self.rows[p.mapId][p.y][p.x]
end

function NewGraph:getTileAtPoint(p, game)
  if p.mapId == OverWorldId then
    return game.overworld:getTileAt_NoUpdate(p.x, p.y, game)
  else
    return game.staticMaps[p.mapId]:getTileAt(p.x, p.y, game)
  end
end

function NewGraph:getWeightAtPoint(p, game)
  return self:getTileAtPoint(p, game).weight
end

function NewGraph:discover(x, y, overworld)
  if self:isDiscovered(OverWorldId,x,y) then return end
  if not overworld:getTileAt_NoUpdate(x,y).walkable
    then self.rows[OverWorldId][y][x] = GraphNode(GraphNodeType.KNOWN)
    return
  end

  function discovered(n) return self:isDiscovered(n.mapId, n.x, n.y) end

  function addNeighbor(n)
    -- log.debug("adding neighbor", n)
    -- first, add the neighbor to m,x,y
    table.insert(self:getNodeAt(OverWorldId,x,y).neighbors, n)
    -- then add OverWorldId,x,y to the neighbors or n
    local reverseNeighbor = Neighbor(OverWorldId, x, y, oppositeDirection(n.dir))
    -- log.debug("adding reverse neighbor", reverseNeighbor)
    table.insert(self:getNodeAt(OverWorldId,n.x,n.y).neighbors, reverseNeighbor)
  end

  self.rows[OverWorldId][y][x] = GraphNode(GraphNodeType.KNOWN)
  local neighborsOfXY = overworld:neighbors(x,y)
  local discoveredNeighborsOfXY = list.filter(neighborsOfXY, discovered)
  -- log.debug("DISCOVERED!", x, y, neighborsOfXY, discoveredNeighborsOfXY)
  list.foreach(discoveredNeighborsOfXY, addNeighbor)
end

function NewGraph:shortestPath(src, destination, game)
  local res = self:dijkstra(src, {destination}, game)
  if #res == 0 then return {} else return res[1] end
end

function NewGraph:shortestPaths(src, destinations, game)
  return self:dijkstra(src, destinations, game)
end

Path = class(function (a, src, dest, weight, path)
  a.src    = src
  a.dest   = dest
  a.weight = weight
  a.path   = path
end)

function Path:__tostring()
  return "<Path src: " .. tostring(self.src) ..
         ", dest:"     .. tostring(self.dest) ..
         ", weight:"   .. tostring(self.weight) ..
         ", path:"     .. list.intercalateS(", ", self.path) ..
         ">"
end

-- Find the shortest path between the current and dest nodes
-- @src :: Point
-- @dests :: [Point]
-- @game :: Game
-- @returns :: [Path] (sorted by weight, ASC)
function NewGraph:dijkstra (src, dests, game)
  -- log.debug("entering dijkstra", src, list.intercalateS(", ", dests))

  local distanceTo, trail = Table3D(), Table3D()
  function getDistanceTo(p) return distanceTo:lookup(p, math.huge) end

  local pq = PriorityQueue()
  pq:enqueue(src, 0)
  distanceTo:insert(src, 0)

  while not pq:empty() do
    local current = pq:dequeue()
    local distanceToCurrent = getDistanceTo(current)
    for _,neighbor in pairs(self:getNodeAtPoint(current).neighbors) do
      local newWeight = distanceToCurrent + self:getWeightAtPoint(neighbor, game)
      if newWeight < getDistanceTo(neighbor) then
        distanceTo:insert(neighbor, newWeight)
        trail:insert(neighbor, {mapId = current.mapId, x = current.x, y = current.y, dir = neighbor.dir})
        pq:enqueue(neighbor:getPoint(), newWeight)
      end
    end
  end

  -- Create path string from table of previous nodes
  -- @dest :: Loc
  -- @returns :: Maybe Path
  function followTrailToDest (dest)
    -- log.debug("followTrailTo", dest, "trail:lookup(dest)", trail:lookup(dest))
    local path, prev = {}, trail:lookup(dest)

    -- if prev is nil it means there was no path to the destination.
    -- for example, it could be on a little island or something that we cant get to.
    if prev == nil then
      -- log.debug("in followTrailToDest, prev is nil!! src", src, "dest", dest)
      return Nothing
    else
      table.insert(path, Neighbor(dest.mapId, dest.x, dest.y, prev.dir))
    end

    while prev do
      if src:equalsPoint(prev) then
        table.insert(path, Point(prev.mapId, prev.x, prev.y))
      else
        local prev2 = trail:lookup(prev)
        table.insert(path, Neighbor(prev.mapId, prev.x, prev.y, prev2.dir))
      end
      prev = trail:lookup(prev)
    end
    local res = Path(src, dest, getDistanceTo(dest), table.reverse(path))
    -- log.debug("res inside", res)
    return Just(res)
  end

  -- trail:debug("trail")
  -- distanceTo:debug("distanceTo")
  local res = list.catMaybes(list.map(dests, followTrailToDest))
  table.sort(res, function(a,b) return a.weight < b.weight end)
  -- log.debug("res", res)
  return res
end


function NewGraph:knownWorldBorder(overworld)
  local res = {}
  for y,row in pairs(self.rows[1]) do
    for x,tile in pairs(row) do
      local overworldTile = overworld:getTileAt_NoUpdate(x,y)
      if overworldTile.walkable and self:isDiscovered(OverWorldId, x, y) then
        local nbrs = overworld:neighbors(x,y)
        -- TODO: potentially adding this more than once if more than one neighbor is nil
        for i = 1, #(nbrs) do
          local nbr = nbrs[i]
          -- this is saying: if you are discovered, one of your neighbors is undiscovered
          -- then YOU are on the border. you are a border tile.
          -- because you bump up against the unknown. :)
          if not self:isDiscovered(nbr.mapId, nbr.x, nbr.y) then
            table.insert(res, Point(OverWorldId, x, y))
          end
        end
      end
    end
  end
  return res
end

-- this is the empty overworld graph. the one that we would have before we ever leave tantegel.
function mkOverworldGraph()
  local res = {}
  for y = 0,119 do
    res[y] = {}
    for x = 0,119 do
      res[y][x] = unknown
    end
  end
  return res
end

function createStaticMapGraphs(staticMaps, haveKeys)
  local res = {}
  for i = 2, 29 do
    local g = mkStaticMapGraph(staticMaps[i], haveKeys)
    res[i] = g
  end
  return res
end

function mkStaticMapGraph (staticMap, haveKeys)
  local tileSet = staticMap:getTileSet()

  function isWalkable(x,y)
    local t = tileSet[staticMap.rows[y][x]]
    if table.containsUsingDotEquals(staticMap.immobileScps, Point(staticMap.mapId, x, y))
      then return false
      else return haveKeys and (t.walkableWithKeys or t.walkable) or t.walkable
    end
  end

  --         x,y-1
  -- x-1,y   x,y     x+1,y
  --         x,y+1
  function neighbors(x,y)
    -- if we can't walk to the node, dont bother including the node in the graph at all
    if not isWalkable(x,y) then return {} end
    local res = {}
    function insertNeighbor(x,y,dir) table.insert(res, Neighbor(staticMap.mapId, x, y, dir)) end
    if x > 0                    and isWalkable(x-1, y) then insertNeighbor(x-1, y, NeighborDir.LEFT) end
    if x < staticMap.width - 1  and isWalkable(x+1, y) then insertNeighbor(x+1, y, NeighborDir.RIGHT) end
    if y > 0                    and isWalkable(x, y-1) then insertNeighbor(x, y-1, NeighborDir.UP) end
    if y < staticMap.height - 1 and isWalkable(x, y+1) then insertNeighbor(x, y+1, NeighborDir.DOWN) end
    -- really useful for debugging pathing. just plug in the location you care about
    -- if staticMap.mapId == 7 and x == 19 and y == 23 then log.debug("n", res) end
    return res
  end

  function warpNeighbors(x,y)
    local res = {}
    if staticMap.warps[x] ~= nil then
      if staticMap.warps[x][y] ~= nil then
        for _, w in pairs(staticMap.warps[x][y]) do
          local neighbor = Neighbor(w.mapId, w.x, w.y, NeighborDir.STAIRS)
          -- log.debug("adding warp neighbor: ", staticMap.mapId, x, y, neighbor)
          table.insert(res, neighbor)
        end
      end
    end
    -- really useful for debugging pathing. just plug in the location you care about
    -- if staticMap.mapId == 7 and x == 19 and y == 23 then log.debug("w", res) end
    return res
  end

  function borderNeighbors(x,y)
    -- this only applies to maps where you can walk directly out onto the overworld.
    if staticMap.mapType ~= MapType.TOWN and staticMap.mapType ~= MapType.BOTH then return {} end
    if not isWalkable(x,y) then return {} end
    local coor = staticMap.entrances[1]
    if coor == nil then return {} end
    local res = {}
    function insertNeighbor(dir)
      local bn = Neighbor(coor.from.mapId, coor.from.x, coor.from.y, dir)
      -- log.debug("adding border neighbor: ", staticMap.mapId, x, y, bn)
      table.insert(res, Neighbor(coor.from.mapId, coor.from.x, coor.from.y, dir))
    end
    if     x == 0                    then insertNeighbor(NeighborDir.LEFT)
    elseif x == staticMap.width  - 1 then insertNeighbor(NeighborDir.RIGHT)
    elseif y == 0                    then insertNeighbor(NeighborDir.UP)
    elseif y == staticMap.height - 1 then insertNeighbor(NeighborDir.DOWN)
    end
    -- really useful for debugging pathing. just plug in the location you care about
    -- if staticMap.mapId == 7 and x == 19 and y == 23 then log.debug("b", res) end
    return res
  end

  function entranceNeighbors(x,y)
    if staticMap.mapType ~= MapType.DUNGEON or staticMap.entrances == nil then return {} end
    local res = {}
    list.foreach(staticMap.entrances, function(e)
      if e.to.x == x and e.to.y == y then
        local neighbor = Neighbor(e.from.mapId, e.from.x, e.from.y, NeighborDir.STAIRS)
        -- log.debug("adding entrance neighbor: ", staticMap.mapId, x, y, neighbor)
        table.insert(res, neighbor)
      end
    end)
    return res
  end

  local res = {}
  for y = 0, staticMap.height - 1 do
    res[y] = {}
    for x = 0, staticMap.width - 1 do
      res[y][x] = GraphNode(GraphNodeType.KNOWN)
      res[y][x].neighbors = table.concatAll({neighbors(x,y), borderNeighbors(x,y), warpNeighbors(x,y), entranceNeighbors(x,y)})
    end
  end
  return res
end

function NewGraph:printMap(mapId, game, printImportantLocations)
  local bottomRight = nil
  if mapId == OverWorldId
    then bottomRight = Point(mapId, 119, 119)
    else bottomRight = Point(mapId, game.staticMaps[mapId].width - 1, game.staticMaps[mapId].height - 1)
  end

  return self:printSquare(Square(Point(mapId, 0, 0), bottomRight), game, printImportantLocations)
end

-- bounds :: Square
-- game   :: Game
-- TODO: i feel like this needs to be redone using the Neighbors direction
-- instead of all this stuff: findNeighbor(x-1,y), ..., findNeighbor(x,y+1)
function NewGraph:printSquare(square, game, printImportantLocations)
  -- log.debug("printSquare", square, printImportantLocations)
  local mapId = square.topLeft.mapId

  function printTile(x,y,neighbors)

    if not self:isDiscovered(mapId, x, y) then return " ? " end

    local neighborsCopy = table.copy(neighbors)
    if neighborsCopy == nil then return "   " end
    local res = ""

    function findNeighbor(x,y)
      local i = list.findWithIndex(neighborsCopy, function(n)
        local res = n:getPoint():equals(Point(mapId,x,y))
        return res
      end)
      if i ~= nil then list.delete(neighborsCopy, i.index) end
      return i
    end

    local l,r,t,b = findNeighbor(x-1,y), findNeighbor(x+1,y), findNeighbor(x,y-1), findNeighbor(x,y+1)

    if l ~= nil then res = res .. "←" else res = res .. " " end
    local tile = self:getTileAtPoint(Point(mapId, x, y), game)
    if mapId == OverWorldId and printImportantLocations and tile.id >= 8 and tile.id <= 10 then
      -- log.debug("x", x, "y", y, "tileId", tile.id)
      if tile.id == 8  then res = res .. "T"  end -- town
      if tile.id == 9  then res = res .. "@"  end -- cave
      if tile.id == 10 then res = res .. "C" end -- castle
    else
      if t ~= nil and b ~= nil
        then res = res .. "↕"
        elseif t ~= nil then res = res .. "↑"
        elseif b ~= nil then res = res .. "↓"
        else res = res .. " "
      end
    end
    if r ~= nil then res = res .. "→" else res = res .. " " end

    -- TODO: here we can iterate through any remaining neighbors (which must be to another map or something)
    return res
  end

  local res = square:titleRow()
  local row = ""

  square:iterate(
    function(x,y) row = row .. "|" .. printTile(x, y, self:getNodeAt(mapId,x,y).neighbors) end,
    function(y) row = padded(y) .. " " end,
    function(y) res = res .. row .. "|\n" end
  )
  return res
end
