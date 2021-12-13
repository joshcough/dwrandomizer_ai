require "Class"
enum = require("enum")

OverWorldId = 1

Point = class(function(a, mapId, x, y)
  a.mapId = mapId
  a.x = x
  a.y = y
end)

function Point:__tostring()
  return "<Point mapId:" .. tostring(self.mapId) .. ", x:" .. tostring(self.x) .. ", y:" .. tostring(self.y) .. ">"
end

function Point:equals(p2)
  if p2 == nil then return false end
  return self.mapId == p2.mapId and self.x == p2.x and self.y == p2.y
end

function Point:equalsPoint(p2) return self:equals(p2) end

-- SQUARE:
--  * TL: (M, 5,5)
--  * BR: (M, 10,10)
-- XY: (M, 7,8) -> true
-- XY: (M, 11,8) -> false
-- XY: (M, 8,11) -> false
function Point:inSquare(sq)
  return self.mapId == sq.topLeft.mapId and
         self.x >= sq.topLeft.x and
         self.x <= sq.bottomRight.x and
         self.y >= sq.topLeft.y and
         self.y <= sq.bottomRight.y
end

Square = class(function(a, topLeft, bottomRight)
  if topLeft.mapId ~= bottomRight.mapId then
    log.err("Arguments to Square did not have the same mapId", topLeft, bottomRight)
  end
  -- TODO: could also check here that tl.x <= br.x, tl.y <= br.y
  -- or could figure out which one really is the top left and just swap them if needed.
  -- for now this is fine though. whatever.
  a.topLeft = topLeft
  a.bottomRight = bottomRight
end)

function Square:dimensions()
  return { width = bottomRight.x - topLeft.x, height = bottomRight.y - topLeft.y }
end

function Square:width()  return self:dimensions().width  end
function Square:height() return self:dimensions().height end

function Square:titleRow()
  local res = "    |"
  for x = self.topLeft.x, self.bottomRight.x do
    res = res .. padded(x) .. "|"
  end
  return res .. "\n"
end

function Square:__tostring()
  return "<Square topLeft:" .. tostring(self.topLeft) .. ", bottomRight:" .. tostring(self.bottomRight) .. ">"
end

function Square:equals(s2)
  if s2 == nil then return false end
  return self.topLeft:equals(s2.topLeft) and self.bottomRight:equals(s2.bottomRight)
end

function Square:iterate(f, startRow, endRow)
  for y = self.topLeft.y, self.bottomRight.y do
    if startRow ~= nil then startRow(y) end
    for x = self.topLeft.x, self.bottomRight.x do
      f(x,y)
    end
    if endRow ~= nil then endRow(y) end
  end
end

NeighborDir = enum.new("Neighbor Direction", {
  "LEFT",
  "RIGHT",
  "UP",
  "DOWN",
  "STAIRS",
})

-- TODO: can this be NeighborDir:oppositeDirection? can we put functions on enums?
function oppositeDirection(newNeighborDir)
  if     newNeighborDir == NeighborDir.LEFT  then return NeighborDir.RIGHT
  elseif newNeighborDir == NeighborDir.RIGHT then return NeighborDir.LEFT
  elseif newNeighborDir == NeighborDir.UP    then return NeighborDir.DOWN
  elseif newNeighborDir == NeighborDir.DOWN  then return NeighborDir.UP
  else return NeighborDir.STAIRS
  end
end

Neighbor = class(function(a, mapId, x, y, dir)
  a.mapId = mapId
  a.x = x
  a.y = y
  a.dir = dir
  a.loc = Point(mapId, x, y)
end)

function Neighbor:__tostring()
  return "<Neighbor mapId:" .. self.mapId .. ", x:" .. self.x .. ", y:" .. self.y .. ", dir: " .. self.dir.name .. ">"
end

function Neighbor:equals(n)
  if n == nil then return false end
  return self.mapId == n.mapId and self.x == n.x and self.y == n.y -- and self.dir == n.dir
end

function Neighbor:equalsPoint(p)
  if n == nil then return false end
  return self.loc:equals(n)
end

function Neighbor:getPoint()
  return Point(self.mapId, self.x, self.y)
end

-- TODO:
-- we need to have important locations for tantegel basement and garinham basement.
-- we need one for the princess too, probably
-- we might need one for the old man in cantlin, because its behind a locked door
-- so in that case i think we also need one for the shop in cantlin behind a locked door
-- and the chests inside rimuldar and charlock
-- but i think chests will just sorta get added automatically. or they should...

GoalType = enum.new("GoalType", {
  "CHARLOCK",
  "TANTEGEL",
  "TOWN",
  "CAVE",
  "CHEST",
  "SPIKE",
  "COORDINATES",
  "BASEMENT"
})

-- TODO: Here we have a goal that we can't just walk to. similar to how we can't just walk to Charlock
-- in this particular case, we need to walk to the static map and then probably interpret that script
-- or maybe the goal itself has a script! one of the best ideas ever really.

-- Goals we can't just walk to:
-- * staff of rain blocked by old man
-- * rainbow drop blocked by jerk
-- * charlock blocked by rainbow drop

-- additionally: this Goal has prerequisites!
-- here we are in the Northern Shrine (mapId:13) where we must trade the silver harp for the staff of rain
-- so the Silver Harp goal must be a prerequisite for the Staff of Rain goal

-- All goals with prerequisites:
-- * staff of rain requires silver harp
-- * jerk cave requires all three key items (staff, stones, token) to get rainbow drop
-- * charlock requires rainbow drop
-- * coordinates requires either talking to old man or Gwaelin's Love
-- * Gwaelin's Love requires the princess
-- * we could also make it so that each chest has a prerequisite of finding the map that its in,
--   but im not sure that makes sense - we dont have Goal_Town, Goal_Dungeon.
--   instead, we can keep using the seenByPlayer stuff probably.

-- goal	<ObjectWithPath v: <Goal location:<Point mapId:13, x:3, y:4>,
-- type:<GoalType.CHEST: 5>, seenByPlayer:true, completed:false>,
-- path:<Path  src: <Point mapId:1, x:58, y:106>, dest:<Point mapId:13, x:3, y:4>, weight:17,
-- path: {<Point mapId:1, x:58, y:106>,
-- <Neighbor mapId:1, x:59, y:106, dir: RIGHT>,
--- ...
-- <Neighbor mapId:13, x:4, y:4, dir: LEFT>,
-- <Neighbor mapId:13, x:3, y:4, dir: LEFT>}>>

Goal = class(function(a, location, type)
  a.location = location
  a.type = type
  a.seenByPlayer = false
  a.completed = false
end)

function Goal:__tostring()
  return "<Goal location:" .. tostring(self.location)
          .. ", type:" .. tostring(self.type)
          .. ", seenByPlayer:" .. tostring(self.seenByPlayer)
          .. ", completed:" .. tostring(self.completed) .. ">"
end

Goal_Overworld = class(Goal, function(a, entrance)
  Goal.init(a, entrance.from, entrance.entranceType)
  a.entrance = entrance
end)

Goal_Chest = class(Goal, function(a, chest)
  Goal.init(a, chest.location, GoalType.CHEST)
  a.chest = chest
end)

-- TODO: these three seem like they don't really add anything...could possibly just use the Goal constructor
-- swamp cave spike, hauksness spike, charlock spike
Goal_Spike = class(Goal, function(a, mapId, x, y)
  Goal.init(a, Point(mapId, x, y), GoalType.SPIKE)
end)

-- the search spot / coordinates / token location or whatever tf.
Goal_Coordinates = class(Goal, function(a, loc)
  Goal.init(a, loc, GoalType.COORDINATES)
end)

Goal_Basement = class(Goal, function(a, entrance)
  Goal.init(a, entrance.from, GoalType.BASEMENT)
  a.entrance = entrance
end)

--[[
  * 7 chests in tantegel plus the basement stairs. (and possibly the key shop...)
  * each town should have one (and possibly have one for each of their shops and inns... maybe?)
  * garinham has 3 chests and basement stairs.
  * rimuldar has a chest
  *& hauksness has a spike tile
  * canlin has a shop behind a locked door, and an old man too
  * each of the caves should have an entry
  * and each of the chests in each of the caves should too
  * we could potentially add the coordinates here, and just have a
  * flag that they are inaccessible until we talk to the old man
  things are accessible if we have been to the parent map (and have keys, if they are behind a door)
  * swamp cave: spike tile and princess?
    * also if they go in swamp north... we should add swamp south as an important location, and vice versa.
      in my opinion anyway, its worth trying. it opens up a huge section of the world, so we might want to make it
      a priority.
]]

-- TODO: this just builds the overworld locs, not the chests and others.
function buildAllGoals(staticMaps, chests)
  local res = Table3D()

  function addLocsFromEntrances()
    for mapId, m in pairs(staticMaps) do
      if m.entrances ~= nil then
        for _, entrance in pairs(m.entrances) do
          -- log.debug(mapId, entrance)
          -- TODO: why is this only on the overworld?
          -- yes we have a Goal_Basement, but, is it actually needed?
          -- why can't we just use something like Goal_Entrance
          if entrance.from.mapId == OverWorldId then
            local loc = Goal_Overworld(entrance)
            log.debug("adding important overworld location: ", loc)
            res:insert(loc.location, loc)
          else
            local loc = Goal_Basement(entrance)
            log.debug("adding important basement location: ", loc)
            res:insert(loc.location, loc)
          end
        end
      end
    end
  end

  function addLocsFromChests()
    for i = 1, #chests.chests do
      local loc = Goal_Chest(chests.chests[i])
      log.debug("adding important location from chest: ", loc)
      res:insert(loc.location, loc)
    end
  end

  addLocsFromEntrances()
  addLocsFromChests()

  return res
end
