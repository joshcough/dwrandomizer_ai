-- NOTES

-- for the actual graph for the overworld...
-- when we discover a new tile (by just moving around), we need to get its neighbors and put them in the graph.
-- however, we can only get the neighbors that we've actually seen.
-- for example if we move left to uncover tile at x=10, one of its neighbors is x=9, but we've never seen that
-- so we can't add it to the graph.
-- finally we take another step to uncover x=9, then we need to go back and update the neighbors of x=10 to include x=9
--
-- so basically when we uncover a tile, we need to update its neighbors in the graph
-- but also update its neighbors neighbors! but only for those neighbors that we have seen.
--
-- but how do we know what we have seen?
--
-- one possible approach is to fill in the entire graph with one of these constructors:
--
-- GraphNodeUnknown | GraphNodeKnown
--
-- if its known, it would have neighbors in it, like
--
-- GraphNodeKnown{ neighbors: { ... } }
--
-- and obviously when we uncover a new tile, it would be GraphNodeUnknown in the graph, and we'd change it to GraphNodeKnown
-- and we would get its "Neighbors4" and for each of those at are GraphNodeKnown, we would put them into its neighbors
-- and also for each of those that are GraphNodeKnown, we would include this node into their neighbors.
--
-- when we add a neighbor y to a node x
-- we can then immediately add the neighbor x to node y!

require 'Class'
enum = require('enum')
require 'helpers'
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

function Graph:shortestPath(startNode, endNode, haveKeys, overworld, staticMaps)
  local res = nil
  res = haveKeys and self.graphWithKeys:shortestPath(startNode, endNode, overworld, staticMaps)
                 or  self.graphWithoutKeys:shortestPath(startNode, endNode, overworld, staticMaps)
  -- log.debug("in shortestPath", res)
  return res
end

function Graph:knownWorldBorder(overworld)
  return self.graphWithKeys:knownWorldBorder(overworld)
end

function Graph:discover(x, y, overworld)
  self.graphWithKeys:discover(x, y, overworld)
  self.graphWithoutKeys:discover(x, y, overworld)
end

-- TODO: get these from elsewhere
OverWorldId = 1
TantegelThroneRoom = 5

function Graph:unlockThroneRoomDoor()
  log.debug("unlocking throne room door")
  self.graphWithoutKeys.rows[TantegelThroneRoom] = self.graphWithKeys.rows[TantegelThroneRoom]
end

function Graph:unlockRimuldar()
  log.debug("unlocking rimular")
  self.graphWithoutKeys.rows[Rimuldar] = self.graphWithKeys.rows[Rimuldar]
end

--TODO: when we see an important location (town/cave/castle)
-- we can add the neighbors normally to the neighbors4.
-- but when we actually go into it, then i think we want to replace those neighbors
-- with instead of the overworld location, the actual warp location
function Graph:addWarp(warp, overworld)
  if not (warp.src.mapId == OverWorldId or warp.dest.mapId == OverWorldId) then
    log.debug("Not adding warp because there's no overworld in it.", warp)
  end
  -- log.debug("adding warp in Graph", warp)
  self:fixOverworldNeighbors(warp, overworld)
end

function Graph:grindableNeighbors(overworld,x,y)
  -- log.debug("in grindableNeighbors", x, y)
  local neighbors = self.graphWithKeys:getNodeAt(OverWorldId,x,y).neighbors
  return list.filter(neighbors, function(n)
    if n.mapId ~= OverWorldId then return false end
    local tileId = overworld:getTileIdAt(n.x, n.y, self)
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

function NewGraph:getTileAtPoint(p, overworld, staticMaps)
  if p.mapId == OverWorldId then
    return overworld:getTileAt(p.x, p.y, self)
  else
    return staticMaps[p.mapId]:getTileAt(p.x, p.y, self)
  end
end

function NewGraph:getWeightAtPoint(p, overworld, staticMaps)
  return self:getTileAtPoint(p, overworld, staticMaps).weight
end

function NewGraph:discover(x, y, overworld)
  if self:isDiscovered(OverWorldId,x,y) or not overworld:getTileAt_NoUpdate(x,y).walkable
    then return
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

function NewGraph:shortestPath(src, destination, overworld, staticMaps)
  return self:dijkstra(src, destination, overworld, staticMaps)
-- TODO: probably just kill all this code, along with bfs.
--   local b = self:bfs     (src, destination, overworld, staticMaps)
--   local d = self:dijkstra(src, destination, overworld, staticMaps)
--
--   if #b == #d then return d
--   else
--     log.debug("BFS", #b, tostring(b))
--     log.debug("dijkstra",     #d, tostring(d))
--     error("shortestPath and dijkstra not the same!", #b, b, #d, d)
--   end
end

function NewGraph:bfs(startNode, endNode, overworld, staticMaps)
  -- log.debug("in newgraph:bfs", startNode, endNode)
  function insertPoint(tbl, p, value)
    -- log.debug("insertPoint", "p", p, "value", value)
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
      if self:isDiscovered(node.mapId, node.x, node.y) then
        local nodeAtXY = self:getNodeAt(node.mapId, node.x, node.y)
        local neighbors = nodeAtXY.neighbors
        for _, neighbor in ipairs(neighbors) do
          if not containsPoint(visited, neighbor) then
            q:push(neighbor)
            insertPoint(visited, neighbor, true)
            insertPoint(prev, neighbor, {node, neighbor})
          end
        end
      end
    end

    return prev
  end

  function reconstruct(s, e, prev)
    -- log.debug("reconstruct", s, e, prev)
    local path = {}
    local at = e
    while not (at == nil) do
      -- log.debug("at", at)
      if prev[at.mapId] == nil or prev[at.mapId][at.x] == nil or prev[at.mapId][at.x][at.y] == nil
        then
          table.insert(path, at)
          at = nil
        else
          table.insert(path, prev[at.mapId][at.x][at.y][2])
          at = prev[at.mapId][at.x][at.y][1]
      end
    end
    -- TODO: maybe ideally we would throw an error here instead of returning {}, but im honestly not sure yet.
    if #path == 0 then return {}
    else
      local pathR = table.reverse(path)
      if pathR[1] == nil then return {}
      else
        -- log.debug("pathR[1]", pathR[1])
        return pathR[1]:equals(s) and pathR or {}
      end
    end
  end
  return reconstruct(startNode, endNode, solve(startNode))
end

-- Find the shortest path between the current and dest nodes
function NewGraph:dijkstra (src, dest, overworld, staticMaps)
  -- log.debug("entering dijkstra", src, dest)

  function insertPoint3D(tbl, p, value)
    if tbl[p.mapId] == nil then tbl[p.mapId] = {} end
    if tbl[p.mapId][p.x] == nil then tbl[p.mapId][p.x] = {} end
    tbl[p.mapId][p.x][p.y] = value
  end

  function readPoint3D(tbl, p, default)
    if tbl[p.mapId] == nil then return default end
    if tbl[p.mapId][p.x] == nil then return default end
    if tbl[p.mapId][p.x][p.y] == nil then return default end
    return tbl[p.mapId][p.x][p.y]
  end

  local distanceTo, trail = {}, {}
  local pq = PriorityQueue()
  pq:enqueue(src, 0)
  insertPoint3D(distanceTo, src, 0)

  function getDistanceTo(p) return readPoint3D(distanceTo, p, math.huge) end
  function getWeightAtPoint(p) return self:getWeightAtPoint(p, overworld, staticMaps) end
  function getPrevious(p) return readPoint3D(trail, p) end

  function print3dTable(tbl, name)
    log.debug("====" .. name .. "====")
    for i,v in pairs(tbl) do
      for j,v2 in pairs(v) do
        for k,v3 in pairs(v2) do
          log.debug(i, j, k, v3)
        end
      end
    end
    log.debug("====end " .. name .. "====")
  end

  function printTrail() print3dTable(trail, "trail") end
  function printDistanceTo() print3dTable(distanceTo, "distanceTo") end

  while not pq:empty() do
    local current = pq:dequeue()
    local distanceToCurrent = getDistanceTo(current)
    for _,neighbor in pairs(self:getNodeAtPoint(current).neighbors) do
      local newWeight = distanceToCurrent + getWeightAtPoint(neighbor)
      if newWeight < getDistanceTo(neighbor) then
        insertPoint3D(distanceTo, neighbor, newWeight)
        insertPoint3D(trail, neighbor, {mapId = current.mapId, x = current.x, y = current.y, dir = neighbor.dir})
        pq:enqueue(neighbor:getPoint(), newWeight)
      end
    end
  end

  -- Create path string from table of previous nodes
  function followTrailToDest ()
    -- log.debug("followTrailTo", dest, "getPrevious(dest)", getPrevious(dest))
    local path, prev = {}, getPrevious(dest)

    -- if prev is nil it means there was no path to the destination.
    -- for example, it could be on a little island or something that we cant get to.
    if prev == nil then
      -- printTrail()
      -- printDistanceTo()
      -- log.debug("in followTrailToDest, prev is nil!! src", src, "dest", dest)
      return {}
    else
      table.insert(path, Neighbor(dest.mapId, dest.x, dest.y, prev.dir))
    end

    while prev do
      if src:equalsPoint(prev) then
        table.insert(path, Point(prev.mapId, prev.x, prev.y))
      else
        local prev2 = getPrevious(prev)
        table.insert(path, Neighbor(prev.mapId, prev.x, prev.y, prev2.dir))
      end
      prev = getPrevious(prev)
    end
    return path
  end


  local res = table.reverse(followTrailToDest())
--   log.debug("done in dijkstra")
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
    -- log.debug("entranceNeighbors", staticMap.mapId, staticMap.entrances)
    if staticMap.mapType ~= MapType.DUNGEON or staticMap.entrances == nil then return {} end
    local res = {}
    list.foreach(staticMap.entrances, function(e)
      if e.x == x and e.y == y then
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

-- function NewGraph:iterate(f)
--   iterate3(self.rows, f)
-- end
--
-- function iterate3(tbl, f)
--   for mapId, mapRows in ipairs(tbl) do
--     for y, row in ipairs(mapRows) do
--       for x, neighbors in ipairs(row) do
--         f(Point(mapId, x, y), neighbors)
--       end
--     end
--   end
-- end
--
-- function NewGraph:print(mapId)
--   for y, row in ipairs(self.rows[mapId]) do
--     for x, neighbors in ipairs(row) do
--       log.debug(Point(mapId, x, y), neighbors)
--     end
--   end
-- end
