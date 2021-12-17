require "Class"
enum = require("enum")

-- TODO: import these. but in order to do that, we will have go create a Goal module.
OverWorldId = 1
Tantegel    = 4
Garinham    = 9

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

GoalType = enum.new("GoalType", {
  "CHARLOCK",
  "TANTEGEL",
  "TOWN",
  "CAVE",
  "CHEST",
  "SPIKE",
  "SEARCH",
  "BASEMENT"
})

-- @location :: Point
-- @type :: GoalType
-- @children :: Table3D Goal
-- @script :: Script
Goal = class(function(a, location, type, children, script)
  a.location = location
  a.type = type
  a.children = children
  a.script = script
  a.seenByPlayer = false
  a.completed = false
end)

-- TODO: would be sick to add padding to all these, though unnecessary.
function Goal:__tostring()
  -- TODO: maybe we want to print script or loc here, but... those are long.
  return "<Goal location:" .. tostring(self.location)
          .. ", type:" .. tostring(self.type)
          .. ", seenByPlayer:" .. tostring(self.seenByPlayer)
          .. ", completed:" .. tostring(self.completed)
          .. ", children: {"  .. list.intercalateS(", ", self.children:toList()) .. "}"
          .. ">"
end

Goal_Overworld = class(Goal, function(a, staticMap, entrance, children)
  Goal.init(a, entrance.from, entrance.entranceType, children)
  a.staticMap = staticMap
  a.entrance = entrance
end)

Goal_Chest = class(Goal, function(a, chest)
  Goal.init(a, chest.location, GoalType.CHEST, Table3D())
  a.chest = chest
end)

-- the search spot / coordinates / token location or whatever tf.
Goal_SearchSpot = class(Goal, function(a, searchSpot)
  Goal.init(a, searchSpot.location, GoalType.SEARCH, Table3D())
  a.searchSpot = searchSpot
end)

Goal_Basement = class(Goal, function(a, entrance, children)
  Goal.init(a, entrance.from, GoalType.BASEMENT, children, Nothing)
  a.entrance = entrance
end)

-- TODO: is this actually needed?
-- -- swamp cave spike, hauksness spike, charlock spike
-- Goal_Spike = class(Goal, function(a, mapId, x, y)
--   Goal.init(a, Point(mapId, x, y), GoalType.SPIKE, Table3D())
-- end)

-- TODO: maybe we should make a StaticMaps, and then maybe even a Maps (which includes the overworld)
-- @staticMaps :: [StaticMap]
-- @chests :: Chests
-- @searchSpots :: SearchSpots
function buildAllGoals(allStaticMaps, allChests, searchSpots)

  local allEntrances = list.bind(allStaticMaps, function(m) return m.entrances end)
  local harpGoal = nil
  local northernShrineGoal = nil

  -- @staticMap :: StaticMap
  function childGoalsOfStaticMap(staticMap)
    local res = Table3D()

    local mapId = staticMap.mapId

    -- @returns :: ()
    function addBasementGoal()
      local entrance = list.find(allEntrances, function(e) return e.from.mapId == mapId end).value
      local basementChildren = childGoalsOfStaticMap(allStaticMaps[entrance.to.mapId], allStaticMaps, allChests, allEntrances)
      local goal = Goal_Basement(entrance, basementChildren)
      log.debug("adding goal for basement: ", entrance.from, goal)
      res:insert(entrance.from, goal)
    end

    if mapId == Tantegel then addBasementGoal() end
    if mapId == Garinham then addBasementGoal() end

    -- ok now for all the children of this map, add all the chests in it

    local childIds = staticMap:childrenIds()
    local mapIds = table.concat({mapId}, childIds)
    local chestsForMap = list.bind(mapIds, function(childId) return allChests:chestsForMap(childId) end)

    list.foreach(chestsForMap, function(chest)
      local goal = Goal_Chest(chest)
      if chest.item == SilverHarp then harpGoal = goal end
      -- we dont add the northernShrineGoal to res here
      -- we need to add it to the children of the harp goal
      if chest.location.mapId == NorthernShrine then
        log.debug("not adding goal for NorthernShrine chest: ", goal)
        northernShrineGoal = goal
      else
        log.debug("adding goal for chest: ", goal)
        res:insert(goal.location, goal)
      end
    end)

    return res
  end

  function addGoalsForAllMaps(res)
    -- for all the static maps that have entrances, we do stuff
    for mapId, staticMap in pairs(allStaticMaps) do
      if staticMap.entrances ~= nil then
        for _, entrance in pairs(staticMap.entrances) do
          if entrance.from.mapId == OverWorldId then
            local goalChildren = childGoalsOfStaticMap(staticMap)
            local goal = Goal_Overworld(staticMap, entrance, goalChildren)
            log.debug("adding goal for overworld: ", goal, entrance)
            res:insert(entrance.from, goal)
          end
        end
      end
    end
  end

  function addGoalsForAllSearchSpots(res)
    function addSearchSpotGoal(searchSpot)
      local goal = Goal_SearchSpot(searchSpot)
      if searchSpot.item == SilverHarp then harpGoal = goal end
      log.debug("adding goal for search spot: ", goal, entrance)
      res:insert(searchSpot.location, goal)
    end
    addSearchSpotGoal(searchSpots.coordinates)
    addSearchSpotGoal(searchSpots.kol)
    addSearchSpotGoal(searchSpots.hauksness)
  end

  local res = Table3D()
  addGoalsForAllMaps(res)
  addGoalsForAllSearchSpots(res)
  harpGoal.children:insert(northernShrineGoal.location, northernShrineGoal)

  res:debug("ALL GOALS")
  return res
end

-- TODO:
-- we need to have important locations for tantegel basement and garinham basement.
-- we need one for the princess too, probably
-- we might need one for the old man in cantlin, because its behind a locked door
-- so in that case i think we also need one for the shop in cantlin behind a locked door
-- and the chests inside rimuldar and charlock
-- but i think chests will just sorta get added automatically. or they should...

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

-- goal	<ObjectWithPath v: <Goal location:<Point mapId:13, x:3, y:4>,
-- type:<GoalType.CHEST: 5>, seenByPlayer:true, completed:false>,
-- path:<Path  src: <Point mapId:1, x:58, y:106>, dest:<Point mapId:13, x:3, y:4>, weight:17,
-- path: {<Point mapId:1, x:58, y:106>,
-- <Neighbor mapId:1, x:59, y:106, dir: RIGHT>,
--- ...
-- <Neighbor mapId:13, x:4, y:4, dir: LEFT>,
-- <Neighbor mapId:13, x:3, y:4, dir: LEFT>}>>

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

-- All goals with prerequisites:
-- * staff of rain requires silver harp
-- * jerk cave requires all three key items (staff, stones, token) to get rainbow drop
-- * charlock requires rainbow drop
-- * coordinates requires either talking to old man or Gwaelin's Love
-- * Gwaelin's Love requires the princess
-- * we could also make it so that each chest has a prerequisite of finding the map that its in,
--   but im not sure that makes sense - we dont have Goal_Town, Goal_Dungeon.
--   instead, we can keep using the seenByPlayer stuff probably.

-- NorthernShrine     = 13
-- SouthernShrine     = 14  --- TODO: there IS NO GOAL for SouthernShrine! that's because the chest isn't real.
--                                    so we probably need to specially add one.

-- TODO: question: does it even matter what type of goal it is, if every goal has a script? probably not. maybe delete.

--[[
TODO:
what if we start with the overworld, and unfold...
and instead of adding prerequisites, we add children
the overworld has many children, and those are the root nodes of the tree
(since each node must have a location, and the overworld itself does not have a single location)
for each of those children, they might have chests which will be their children
and they will have sublevels (potentially), which would lead to more children.
not sure the sublevels are really needed, we can just immediately make available all
the chests in the dungeon/town when we enter the top level of it.

right away we automatically find tantegel, and its completed
and the throneroom, and it is completed.
and we find all the chests for both. they are seen, but not completed until we open them
and we find the basement. it is seen, but not completed.
when we go into the basement, it becomes completed, and any children it has would become available.

we could maintain the tree of prereqs, but also a list of available prereqs.
as we discover them, they go into the list.
]]

-- TODO: search spots, scripts for everything?
-- TODO: the southern shrine doesn't fit the `children` model, but instead fits the prereq model. :(
-- it has a prereq of (Stones AND Token AND Staff)
-- similarly, the coordinates too. it has a prereq of (OldMan OR Princess)

-- TODO:
-- i think we need a goal for the old man in cantlin
-- and we need to have the coordinates be a child of that
-- but the coordinates can _also_ be a child of the princess...
-- a princess goal doesnt exist. it will be a little more difficult than the others
-- since we complete it when we return her. but, can be done.