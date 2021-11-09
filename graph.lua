require 'Class'
enum = require("enum")
require 'helpers'

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

NewNeighborDir = enum.new("Neighbor Direction", {
  "LEFT",
  "RIGHT",
  "UP",
  "DOWN",
  "STAIRS",
})

-- todo: can this be NewNeighborDir:oppositeDirection? can we put functions on enums?
function oppositeDirection(newNeighborDir)
  if      newNeighborDir == NewNeighborDir.LEFT  then return NewNeighborDir.RIGHT
  elseif newNeighborDir == NewNeighborDir.RIGHT then return NewNeighborDir.LEFT
  elseif newNeighborDir == NewNeighborDir.UP    then return NewNeighborDir.DOWN
  elseif newNeighborDir == NewNeighborDir.DOWN  then return NewNeighborDir.UP
  else return NewNeighborDir.STAIRS
  end
end

NewNeighbor = class(function(a, mapId, x, y, dir)
  a.mapId = mapId
  a.x = x
  a.y = y
  a.dir = dir
end)

function NewNeighbor:__tostring()
  return "<Neighbor mapId:" .. self.mapId .. ", x:" .. self.x .. ", y:" .. self.y .. ", dir: " .. self.dir.name .. ">"
end

function NewNeighbor:equalsPoint(p)
  if p == nil then return false end
  return self.mapId == p.mapId and self.x == p.x and self.y == p.y
end

function NewNeighbor:getPoint()
  return Point(self.mapId, self.x, self.y)
end

NewGraph = class(function(a, overworld)
  a.overworld = overworld
  a.rows = {}
  a.rows[1] = mkOverworldGraph()
end)

unknown = GraphNode(GraphNodeType.UNKNOWN)

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

function NewGraph:isDiscovered(m,x,y)
  print("NewGraph:isDiscovered", m, x, y)
  return self.rows[m][y][x] ~= unknown
end

--TODO: when we see an important location (town/cave/castle)
-- we can add the neighbors normally to the neighbors4.
-- but when we actually go into it, then i think we want to remove those neighbors.
function NewGraph:discover(m, x, y)
  if self:isDiscovered(m,x,y) then return end

  local newNode = GraphNode(GraphNodeType.KNOWN)
  self.rows[m][y][x] = newNode

  function discovered(n) return self:isDiscovered(n.mapId, n.x, n.y) end

  function addNeighbor(n)
    -- first, add the neighbor to m,x,y
    table.insert(newNode.neighbors, n)
    -- then add m,x,y to the neighbors or n
    table.insert(self.rows[n.mapId][n.y][n.x], NewNeighbor(m, x, y, oppositeDirection(n.dir)))
  end

  -- TODO: for now, only doing this on overworld.
  if m == 1 then
    local neighborsOfXY = self.overworld:newNeighbors(x,y)
    local discoveredNeighborsOfXY = list.filter(neighborsOfXY, discovered)
    list.foreach(self.overworld:newNeighbors(x,y), addNeighbor)
  end
end

-- NewGraph = class(function(a, haveKeys, staticMaps)
--   a.staticMaps = staticMaps
--   a.haveKeys = haveKeys
--
--   a.rows = {}
--   a.rows[1] = mkOverworldGraph()
--   for i = 2, 29 do
--     a.rows[i] = mkGraphFromStaticMap(staticMaps[i])
--   end
-- end)
--
-- function mkGraphFromStaticMap(staticMap, haveKeys)
-- end
--
-- function StaticMap:mkGraph (haveKeys)
--   local tileSet = self:getTileSet()
--
--   function isWalkable(x,y)
--     local t = tileSet[self.rows[y][x]]
--     if table.containsUsingDotEquals(self.immobileScps, Point(self.mapId, x, y))
--       then return false
--       else return haveKeys and (t.walkableWithKeys or t.walkable) or t.walkable
--     end
--   end
--
--   --         x,y-1
--   -- x-1,y   x,y     x+1,y
--   --         x,y+1
--   function neighbors(x,y)
--     -- if we can't walk to the node, dont bother including the node in the graph at all
--     if not isWalkable(x,y) then return {} end
--     local res = {}
--     function insertNeighbor(x,y) table.insert(res, Neighbor(self.mapId, x, y, NeighborType.SAME_MAP)) end
--     if x > 0 and isWalkable(x-1, y) then insertNeighbor(x-1, y) end
--     if x < self.width - 1 and isWalkable(x+1, y) then insertNeighbor(x+1, y) end
--     if y > 0 and isWalkable(x, y-1) then insertNeighbor(x, y-1) end
--     if y < self.height - 1 and isWalkable(x, y+1) then insertNeighbor(x, y+1) end
--     -- really useful for debugging pathing. just plug in the location you care about
--     -- if self.mapId == 7 and x == 19 and y == 23 then print("n", res) end
--     return res
--   end
--
--   function warpNeighbors(x,y)
--     local res = {}
--     if self.warps[x] ~= nil then
--       if self.warps[x][y] ~= nil then
--         for _, w in pairs(self.warps[x][y]) do
--           table.insert(res, Neighbor(w.mapId, w.x, w.y, NeighborType.STAIRS))
--         end
--       end
--     end
--     -- really useful for debugging pathing. just plug in the location you care about
--     -- if self.mapId == 7 and x == 19 and y == 23 then print("w", res) end
--     return res
--   end
--
--   function borderNeighbors(x,y)
--     -- this only applies to maps where you can walk directly out onto the overworld.
--     if self.mapType ~= MapType.TOWN and self.mapType ~= MapType.BOTH then return {} end
--     if not isWalkable(x,y) then return {} end
--     local res = {}
--     local coor = self.overworldCoordinates[1]
--     function insertNeighbor(dir) table.insert(res, Neighbor(coor.mapId, coor.x, coor.y, dir)) end
--     if     x == 0               then insertNeighbor(NeighborType.BORDER_LEFT)
--     elseif x == self.width  - 1 then insertNeighbor(NeighborType.BORDER_RIGHT)
--     elseif y == 0               then insertNeighbor(NeighborType.BORDER_UP)
--     elseif y == self.height - 1 then insertNeighbor(NeighborType.BORDER_DOWN)
--     end
--     -- really useful for debugging pathing. just plug in the location you care about
--     -- if self.mapId == 7 and x == 19 and y == 23 then print("b", res) end
--     return res
--   end
--
--   local res = {}
--   for y = 0,self.height-1 do
--     res[y] = {}
--     for x = 0,self.width-1 do
--       res[y][x] = table.concatAll({neighbors(x,y), borderNeighbors(x,y), warpNeighbors(x,y)})
--     end
--   end
--   return Graph(res, haveKeys, self)
-- end
--
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
