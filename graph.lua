require 'Class'
enum = require('enum')
require 'helpers'
require 'locations'
PriorityQueue = require('PriorityQueue')

GraphNodeType = enum.new("Type of graph node", {
  "UNKNOWN", -- tiles on the overworld that we haven't discovered yet.
  "KNOWN", -- tiles on the overworld that we have discovered, or tiles on static maps.
})

-- @nodeType :: GraphNodeType
-- @returns :: GraphNode
GraphNode = class(function(a, nodeType)
  a.nodeType = nodeType
  -- invariant: neighbors must be empty if nodeType == UNKNOWN.
  -- it _might_ be empty if we have discovered it
  -- but only if its not walkable, or there's literally no possible way to get to it.
  -- like a grass node surrounded by mountains. there would not be a path to it.
  a.neighbors = {}
end)

-- @staticMaps :: [StaticMap]
-- @returns :: Graph
Graph = class(function (a, staticMaps)
  -- the graphWithKeys has no doors in it. so when you have keys, doors are no obstacle, and this graph is used.
  a.graphWithKeys = NewGraph(createStaticMapGraphs(staticMaps, true), true)
  -- the graphWithout keys has all the doors in it. when you dont have keys, this graph is used.
  a.graphWithoutKeys = NewGraph(createStaticMapGraphs(staticMaps, false), false)
end)

-- what if this function didn't take the haveKeys boolean
-- and instead Path contained both the path without keys and the path with keys
-- and possibly how many keys are required? or something?

-- we need a better way of managing what doors are open/closed
-- and how many keys we need on a path
-- because when we die we create a path back into a dungeon, but i think it thinks
-- that the doors in it are still open, because they don't get closed until we make it
-- back out onto the overworld. and so we are getting stuck at the door

-- the path without keys would ideally have all the doors in it, and so we could know how many keys are needed
-- the path with keys would have no doors i guess, and would be Nothing if there was a door in the way? i think...
-- that is all kind of convoluted though.

-- there are other possible ways, but i haven't completely thought them through yet
-- lets say we have a path that takes us outside to the overword, to garinham, and down into the grave (where a key is required)
-- but, we died in the grave after having opened the door in the grave.
-- i think the game thinks that door is still open when we create the path, but when we get to the overworld, the door closes.
-- so what if we looked at the path to see if it led us out onto the overworld?
-- then i guess we would have to use the graph with keys?
--ugh...

-- what if we abandoned key/no key graphs and just had one graph?
-- even if we always updated it whenever we opened or closed a door... we would still have this overworld problem
-- because we create the paths right now before we hit the overworld, so the door is still open

--- === THIS === ---
-- so what if we didn't create the path until we left tantegel?
-- that would probably work really nice, except for when the path is to whatever is in the tantegel basement.
-- but maybe we could analyze that.
-- we could look at the destination map, and we could follow its parents all the way out
-- if Tantegel is one of its parents, then we do ZZZ (what do we do?)
-- if it is NOT one of its parents, then we could walk outside, then then calculate the path
-- except what if there are doors and we dont have any keys?
-- then maybe we dont' even want to go there at all... and so we have to pick a new destination
-- and it would be kind of weird to have to walk outside tantegel in order to figure this out
-- because its possible (maybe? maybe not actually) that we'd want to walk back into the castle
-- i say "maybe not actually" because if we dont have keys, then there isn't really anything
-- to do in the castle anyway, right? so we wouldn't be going back in there.
--- i think this works actually....
-- i also think we will ahve to rely on the stuff in `Memory:printDoorsAndChests()` to make this work properly
-- basically, whenever we hit the overworld, we should readjust the graph for any doors that just closed
-- and whenever we open a door, we can update the graph too. right? do we do that already?

-- function StaticMap:pathWouldRequireOverworld(allStaticMaps)
--   return not self:isTantegelAParent(allStaticMaps)
-- end

-- TODO: we need a function to get the locations of all the doors.
-- TODO: we need a function to close all the doors (except for throne room door)
-- TODO: when the map is changed to the overworld, we need to call that function
-- TODO: we also need to call it after we die, if the path to whatever destination we have requires
--       going out to the overworld, before we hit the overworld (or before we even move at all)
--       is it really this easy?
--       if we die in the bottom of the grave before we get the chest, this works
--       but what happens if we die after we get the chest? what is our destination then?
--       i think it should change to somehting besides that chest, like back to the entrance of whatever map we are on
--       and in that case this just works out anyway. it shouldnt' be back to the same chest. definitely not.

function Graph:closeAllDoorsExceptThroneRoom()
--   self.graphWithKeys:closeAllDoorsExceptThroneRoom()
--   self.graphWithoutKeys:closeAllDoorsExceptThroneRoom()
end

-- -- @returns :: ()
-- function Graph:unlockThroneRoomDoor()
--   -- log.debug("unlocking throne room door")
--   self.graphWithoutKeys.rows[TantegelThroneRoom] = self.graphWithKeys.rows[TantegelThroneRoom]
-- end


-- @src :: Point
-- @destination :: Point
-- @game :: Game
-- @returns Maybe Path
function Graph:shortestPath(src, destination, haveKeys, game)
  return list.toMaybe(self:shortestPaths(src, {destination}, haveKeys, game))
end

-- @src :: Point
-- @destinations :: [Point]
-- haveKeys :: Bool - if the player has keys or not
-- @game :: Game
-- @returns [Path] (sorted by weight, ASC)
function Graph:shortestPaths(src, destinations, haveKeys, game)
  local res = nil
  res = haveKeys and self.graphWithKeys:shortestPaths(src, destinations, game)
                 or  self.graphWithoutKeys:shortestPaths(src, destinations, game)
  -- log.debug("in shortestPath", res)
  return res
end

-- @overworld :: Overworld
-- @returns :: [Point]
function Graph:knownWorldBorder(overworld)
  return self.graphWithKeys:knownWorldBorder(overworld)
end

-- @x :: Int
-- @y :: Int
-- @game :: Game
-- @returns :: ()
function Graph:discover(x, y, game)
  -- log.debug("Graph:discover", x, y, game == nil)
  self.graphWithKeys:discover(x, y, game)
  self.graphWithoutKeys:discover(x, y, game)
end

-- TODO: get these from elsewhere
TantegelThroneRoom = 5

-- @returns :: ()
function Graph:unlockThroneRoomDoor()
  -- log.debug("unlocking throne room door")
  self.graphWithoutKeys.rows[TantegelThroneRoom] = self.graphWithKeys.rows[TantegelThroneRoom]
end

-- @returns :: ()
function Graph:unlockRimuldar()
  log.debug("unlocking rimular")
  self.graphWithoutKeys.rows[Rimuldar] = self.graphWithKeys.rows[Rimuldar]
end

--when we see an goal (town/cave/castle)
-- we can add the neighbors normally to the neighbors4.
-- but when we actually go into it, then we replace those neighbors
-- with instead of the overworld location, the actual warp location
-- @warp :: Warp
-- @overworld :: Overworld
-- @returns :: ()
function Graph:addWarp(warp, overworld)
  if not (warp.src.mapId == OverWorldId or warp.dest.mapId == OverWorldId) then
    log.debug("Not adding warp because there's no overworld in it.", warp)
  end
  -- log.debug("adding warp in Graph", warp)
  self:discoverTownOrCave(warp, overworld)
end

-- TODO: pretty major one... if we attempt to grind in a dungeon, this is going to all break
-- because the code is assuming the overworld. see `overworld:grindableNeighbors`
-- it really shouldn't be that way. we need a static map version of grindableNeighbors as well.
-- @game :: Game
-- @x :: Int
-- @y :: Int
-- @returns :: [Neighbor]
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

-- @warp :: Warp
-- @overworld :: OverworldTile
-- @returns :: ()
function Graph:discoverTownOrCave(warp, overworld)
  local overworldPoint = warp.src.mapId == OverWorldId and warp.src  or warp.dest
  local otherPoint     = warp.src.mapId == OverWorldId and warp.dest or warp.src
  -- log.debug("discoverTownOrCave", overworldPoint, otherPoint)

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

-- @staticMapGraphs :: [[[GraphNode]]]
-- @isGraphWithKeys :: Bool
-- @returns :: NewGraph
NewGraph = class(function(a, staticMapGraphs, isGraphWithKeys)
  a.rows = {}
  a.isGraphWithKeys = isGraphWithKeys
  a.rows[1] = mkOverworldGraph()
  for i = 2, 29 do
    a.rows[i] = staticMapGraphs[i]
  end
end)

unknown = GraphNode(GraphNodeType.UNKNOWN)

-- @mapId :: MapId / Int
-- @x :: Int
-- @y :: Int
-- @returns :: Bool
function NewGraph:isDiscovered(mapId,x,y)
  return self:getNodeAt(mapId,x,y) ~= unknown
end

-- @mapId :: MapId / Int
-- @x :: Int
-- @y :: Int
-- @returns :: GraphNode
function NewGraph:getNodeAt(mapId,x,y)
  return self.rows[mapId][y][x]
end

-- @p :: Point
-- @returns :: GraphNode
function NewGraph:getNodeAtPoint(p)
  return self.rows[p.mapId][p.y][p.x]
end

-- zzz i dont think we need to do anything here but delegate the the static map as we already are.
-- @p :: Point
-- @returns :: OverworldTile or StaticMapTile (TODO: maybe a unified type for these)
function NewGraph:getTileAtPoint(p, game)
  if p.mapId == OverWorldId then
    return game.overworld:getTileAt_NoUpdate(p.x, p.y, game)
  else
    return game.staticMaps[p.mapId]:getTileAt(p.x, p.y, game)
  end
end

-- @p :: Point
-- @returns :: Int
function NewGraph:getWeightAtPoint(p, game)
  return self:getTileAtPoint(p, game).weight
end

-- @x :: Int
-- @y :: Int
-- @overworld :: Overworld
-- @returns :: ()
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

-- @src :: Point
-- @destination :: Point
-- @game :: Game
-- @returns Maybe Path
function NewGraph:shortestPath(src, destination, game)
  return list.toMaybe(self:dijkstra(src, {destination}, game))
end

-- @src :: Point
-- @destinations :: [Point]
-- @game :: Game
-- @returns :: [Path] (sorted by weight, ASC)
function NewGraph:shortestPaths(src, destinations, game)
  return self:dijkstra(src, destinations, game)
end

-- @src :: Point
-- @dest :: Point
-- @weight :: Int
-- @path :: [Point/Neighbor] (first one is a Point, rest are Neighbors) TODO: maybe make a better type for this.
Path = class(function (a, src, dest, weight, path)
  a.src    = src
  a.dest   = dest
  a.weight = weight
  a.path   = path
end)

-- @returns :: Bool
function Path:isEmpty() return #(self.path) == 0 end

-- @returns :: String
function Path:__tostring()
  return "<Path " ..
         " src: "      .. tostring(self.src) ..
         ", dest:"     .. tostring(self.dest) ..
         ", weight:"   .. tostring(self.weight) ..
         ", path: {"   .. list.intercalateS(", ", self.path) .. "}" ..
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
  function getDistanceTo(p) return distanceTo:lookup(p):getOrElse(math.huge) end

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
    local path, prevMaybe = {}, trail:lookup(dest)

    -- if prev is nil it means there was no path to the destination.
    -- for example, it could be on a little island or something that we cant get to.
    if prevMaybe == Nothing then
      -- log.debug("in followTrailToDest, prev is Nothing!! src", src, "dest", dest)
      return Nothing
    else
      table.insert(path, Neighbor(dest.mapId, dest.x, dest.y, prevMaybe.value.dir))
    end

    while prevMaybe:isDefined() do
      local prev = prevMaybe.value
      if src:equalsPoint(prev) then
        table.insert(path, Point(prev.mapId, prev.x, prev.y))
      else
        local prev2 = trail:lookup(prev)
        if prev2 == Nothing then
          log.err("prev2 was Nothing!", prev)
        else
          table.insert(path, Neighbor(prev.mapId, prev.x, prev.y, prev2.value.dir))
        end
      end
      prevMaybe = trail:lookup(prev)
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

-- Returns the list of points that are on the edge of what we have discovered so far.
-- @overworld :: Overworld
-- @returns [Point]
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

-- Returns an empty overworld grid (the one that we would have before we ever leave tantegel)
-- of size 120x120, where every node in the grid is the UNKNOWN graph node.
-- @returns :: [[GraphNode]]
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

-- @staticMaps :: [StaticMap]
-- @haveKeys :: Bool
-- @returns :: [[[GraphNode]]] -- TODO: maybe we need a good type for this?
function createStaticMapGraphs(staticMaps, haveKeys)
  local res = {}
  for i = 2, 29 do
    local g = mkStaticMapGraph(staticMaps[i], haveKeys)
    res[i] = g
  end
  return res
end

-- @staticMap :: StaticMap
-- @x :: Int
-- @y :: Int
-- @haveKeys :: Bool
-- @returns :: [[GraphNode]]
function neighborsAt(staticMap,x,y,haveKeys)
  local tileSet = staticMap:getTileSet()

  function isWalkable(x,y)
    local t = tileSet[staticMap.rows[y][x]]
    if list.any(staticMap.immobileScps, function(l) l:equals(Point(staticMap.mapId, x, y)) end)
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
  -- todo: maybe use list.join here instead of table.concatAll
  return table.concatAll({neighbors(x,y), borderNeighbors(x,y), warpNeighbors(x,y), entranceNeighbors(x,y)})
end

-- at the beginning of the game, all doors should be locked
-- and so we should have a graph missing some potential neighbors because of that
-- and that is exactly what we want.
-- @staticMap :: StaticMap
-- @haveKeys :: Bool
-- @returns :: [[GraphNode]]
function mkStaticMapGraph (staticMap, haveKeys)
  local res = {}
  for y = 0, staticMap.height - 1 do
    res[y] = {}
    for x = 0, staticMap.width - 1 do
      res[y][x] = GraphNode(GraphNodeType.KNOWN)
      res[y][x].neighbors = neighborsAt(staticMap,x,y,haveKeys)
    end
  end
  return res
end

-- @mapId :: MapId / Int
-- @game :: Game
-- @printGoals :: Bool
-- @returns :: ()
function NewGraph:printMap(mapId, game, printGoals)
  local bottomRight = nil
  if mapId == OverWorldId
    then bottomRight = Point(mapId, 119, 119)
    else bottomRight = Point(mapId, game.staticMaps[mapId].width - 1, game.staticMaps[mapId].height - 1)
  end
  return self:printSquare(Square(Point(mapId, 0, 0), bottomRight), game, printGoals)
end

-- bounds :: Square
-- game   :: Game
function NewGraph:printSquare(square, game, printGoals)
  -- log.debug("printSquare", square, printGoals)
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
      return i.value
    end

    -- TODO: i feel like this needs to be redone using the Neighbors direction
    -- instead of all this stuff: findNeighbor(x-1,y), ..., findNeighbor(x,y+1)
    local l,r,t,b = findNeighbor(x-1,y), findNeighbor(x+1,y), findNeighbor(x,y-1), findNeighbor(x,y+1)

    if l ~= nil then res = res .. "←" else res = res .. " " end
    local tile = self:getTileAtPoint(Point(mapId, x, y), game)
    if mapId == OverWorldId and printGoals and tile.id >= 8 and tile.id <= 10 then
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
