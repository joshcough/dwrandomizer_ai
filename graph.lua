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

NewGraph = class(function(a)
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
  return self:getNodeAt(m,x,y) ~= unknown
end

function NewGraph:getNodeAt(m,x,y)
  return self.rows[m][y][x]
end

--TODO: when we see an important location (town/cave/castle)
-- we can add the neighbors normally to the neighbors4.
-- but when we actually go into it, then i think we want to remove those neighbors.
function NewGraph:discover(m, x, y, overworld)
  if self:isDiscovered(m,x,y) then return end

  -- log.debug("DISCOVERED!", m, x, y)
  self.rows[m][y][x] = GraphNode(GraphNodeType.KNOWN)

  function discovered(n) return self:isDiscovered(n.mapId, n.x, n.y) end

  function addNeighbor(n)
    -- log.debug("adding neighbor", n)
    -- first, add the neighbor to m,x,y
    table.insert(self:getNodeAt(m,x,y).neighbors, n)
    -- then add m,x,y to the neighbors or n
    local reverseNeighbor = Neighbor(m, x, y, oppositeDirection(n.dir))
    -- log.debug("adding reverse neighbor", reverseNeighbor)
    table.insert(self:getNodeAt(n.mapId,n.x,n.y).neighbors, reverseNeighbor)
  end

  -- TODO: for now, only doing this on overworld.
  -- possibly we only ever do this for the overworld...
  if m == 1 then
    local neighborsOfXY = overworld:newNeighbors(x,y)
    local discoveredNeighborsOfXY = list.filter(neighborsOfXY, discovered)
    list.foreach(discoveredNeighborsOfXY, addNeighbor)
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
--     -- if self.mapId == 7 and x == 19 and y == 23 then log.debug("n", res) end
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
--     -- if self.mapId == 7 and x == 19 and y == 23 then log.debug("w", res) end
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
--     -- if self.mapId == 7 and x == 19 and y == 23 then log.debug("b", res) end
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


function NewGraph:shortestPath(startNode, endNode)
  -- log.debug("in newgraph:shorestpath", startNode, endNode)
  if startNode.mapId ~= 1 or endNode.mapId ~= 1 then return {"no path man"} end

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
      if self:isDiscovered(node.mapId, node.x, node.y) then
        local neighbors = self:getNodeAt(node.mapId, node.x, node.y).neighbors
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

  local r = reconstruct(startNode, endNode, solve(startNode))
  -- log.debug("shortestPath", tostring(r))
  return r
end

function NewGraph:knownWorldBorder(overworld)
  local res = {}
  for y,row in pairs(self.rows[1]) do
    for x,tile in pairs(row) do
      local overworldTile = overworld:getOverworldMapTileAtNoUpdate(x,y)
      if overworldTile.walkable and self:isDiscovered(OverWorldId, x, y) then
        local nbrs = overworld:newNeighbors(x,y)
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
