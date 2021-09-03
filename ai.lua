require 'mem'
require 'controller'
require 'enemies'
require 'helpers'
require 'hud'
require 'overworld'
require 'static_maps'

function openChest ()
  print("======opening chest=======")
  holdA(30)
  waitFrames(10)
  pressUp(2)
  pressRight(2)
  pressA(20)
end

function openDoor ()
  print("======opening door=======")
  holdA(30)
  waitFrames(10)
  pressDown(2)
  pressDown(2)
  pressRight(2)
  pressA(20)
end


function menuScript ()
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

function kingScript ()
  print("======executing king script=======")
  holdA(250)
end

function openThroneRoomChests ()
  print("======opening throne room chests=======")
  holdRight(10)
  openChest()
  holdRight(30)
  openChest()
  holdRight(60)
  holdUp(50)
  holdLeft(30)
  openChest()
end

function leaveThroneRoom()
  print("======leaving throne room=====")
  holdRight(60)
  holdDown(60)
  holdLeft(60)
  holdDown(30)
  openDoor()
  holdDown(30)
  holdLeft(45)
  takeStairs()
end

function leaveTantagelFromThroneRoomStairs()
  print("======leaving tantagel from throne room stairs=======")
  waitFrames(60)
  holdDown(30)
  holdLeft(30)
end

function throneRoomScript ()
  print("======executing throne room script=======")
  kingScript ()
  openThroneRoomChests()
  leaveThroneRoom()
end

function gameStartScript ()
  print("======executing game start script=======")
  menuScript()
  throneRoomScript()
  leaveTantagelFromThroneRoomStairs()
end

doneWithGameStart = false

function runGameStartScript ()
  if not doneWithGameStart
    then
      gameStartScript()
      doneWithGameStart = true
  end
end

in_battle2 = false

-- A thing draws near!
function onEncounter2(memory)
  return function(address)
    if (memory:getMapId() > 0) then
      enemyId = memory:getEnemyId()
      print ("entering battle vs a " .. Enemies[enemyId])
      -- actually, set every encounter to a red slime. lol!
      memory:setEnemyId(0)
      in_battle2 = true
    end
  end
end

function executeBattle()
 if (emu.framecount() % 15 == 0) then
    -- print("in_battle2: ", in_battle2)
    if(in_battle2) then
      holdA(240)
      waitFrames(60)
      pressA(10)
      in_battle2 = false
    end
  end
end

function onPlayerMove(memory, overworld)
  return function(address)
--     print("current location", memory:getLocation())
    if memory:getMapId() == 1
      then
        overworld:printVisibleGrid(memory:getX(), memory:getY())
        print("percentageOfWorldSeen: " .. overworld:percentageOfWorldSeen())
    end
  end
end

Game = class(function(a, mem, warps)
  a.mem = mem
  a.maps = readAllStaticMaps(mem, warps)
  a.warps = warps
  a.graphsWithKeys = readAllGraphs(mem, true, a.maps, warps)
  a.graphsWithoutKeys = readAllGraphs(mem, false, a.maps, warps)
end)

function Game:goTo(dest)
  local path = self:shortestPath(self.mem:getLocation(), dest, true)
  local commands = convertPathToCommands(path)
  -- for i,c in pairs(commands) do print(i, c) end
  for i,c in pairs(commands) do
    -- print(i, c)
    if c["direction"] == "Stairs"
      then self:takeStairs(c["from"], c["to"])
      else
        holdButtonUntil(c["direction"], function ()
          local p = self.mem:getLocation()
          -- print("current point: ", mem:getLocation(), "c.to: ", c.to, "equal?: ", p.equals(c.to))
          return p:equals(c.to)
        end
        )
    end
  end
end

-- TODO: looks like the to argument here isn't really needed.
function Game:takeStairs (from, to)
  -- print("======taking stairs=======")
  holdA(30)
  waitFrames(30)
  pressDown(2)
  pressDown(2)
  pressA(60)

  if from:equals(TantagelBasementStairs)
  then
    print("discovered what's in the tantagel basement!")
    self:addWarp(Warp(TantagelBasementStairs, self.mem:getLocation()))
  end
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
  self.maps = readAllStaticMaps(self.mem, self.warps)
  self.graphsWithKeys = readAllGraphs(self.mem, true, self.maps, self.warps)
  self.graphsWithoutKeys = readAllGraphs(self.mem, false, self.maps, self.warps)
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

-------------------
---- MAIN LOOP ----
-------------------

function main()
  hud_main()

  mem = Memory(memory, rom)
  overworld = OverWorld(readOverworldFromROM(mem))
  memory.registerexecute(0xcf44, onEncounter2(mem))
  memory.registerwrite(0x3a, onPlayerMove(mem, overworld))
  memory.registerwrite(0x3b, onPlayerMove(mem, overworld))

  local warps = table.concat(WARPS, list.map(WARPS, swapSrcAndDest))

  -- i run this each time to make sure nothing has changed.
  -- if anything changes, git will tell me.
--   saveStaticMaps(mem, warps)

  local game = Game(mem, warps)

  -- i print this out just to make sure things look sane when i start the script.
  -- table.print(shortestPath(Point3D(TantegelThroneRoom, 1,1), Point3D(TantegelThroneRoom, 1,8), true, graphs))
  -- can also do this, which loads the maps from files instead of memory:
  -- table.print(shortestPath(Point3D(TantegelThroneRoom, 1,1), Point3D(TantegelThroneRoom, 1,8), true))
  -- table.print(shortestPath(Point3D(Charlock, 10,19), Point3D(CharlockThroneRoom, 17,24), true))

  -- runGameStartScript()

--   game:goTo(Point3D(Tantegel, 29,29))
--   game:takeStairs(Point3D(Tantegel, 29,29))
--   game:goTo(Point3D(TantegelThroneRoom, 3,4))

  emu.speedmode("normal")
  while true do
    -- this only happens if we are actually in battle.
    executeBattle()
    emu.frameadvance()
  end
end

main()
