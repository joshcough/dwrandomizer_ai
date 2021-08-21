function readMemory(addr) return memory.readbyte(addr) end
function writeMemory(addr, value) memory.writebyte(addr, value) end

function bitand(a, b)
 local result = 0
 local bitval = 1
 while a > 0 and b > 0 do
 if a % 2 == 1 and b % 2 == 1 then -- test the rightmost bits
 result = result + bitval -- set the current bit
 end
 bitval = bitval * 2 -- shift left
 a = math.floor(a/2) -- shift right
 b = math.floor(b/2)
 end
 return result
end

-- HI_NIBBLE(b) (((b) >> 4) & 0x0F)
function hiNibble(b) return bitand(math.floor(b/16), 0x0F) end
-- LO_NIBBLE(b) (((b) & 0x0F)
function loNibble(b) return bitand(b, 0x0F) end

function isEven(n) return n%2 == 0 end
function isOdd(n) return n%2 == 1 end

MapData = {
 [1] = {["name"] = "Overworld", ["size"] = {120,120}, ["romAddr"]={0x1D6, 0x2668}},
 [2] = {["name"] = "Charlock", ["size"] = {20,20}, ["romAddr"]={0xC0, 0x187}},
 [3] = {["name"] = "Hauksness", ["size"] = {20,20}, ["romAddr"]={0x188, 0x24f}},
 [4] = {["name"] = "Tantegel", ["size"] = {30,30}, ["romAddr"]={0x250, 0x411}},
 [5] = {["name"] = "Tantegel Throne Room", ["size"] = {10,10}, ["romAddr"]={0x412, 0x444}},
 [6] = {["name"] = "Charlock Throne Room", ["size"] = {30,30}, ["romAddr"]={0x444, 0x605}},
 [7] = {["name"] = "Kol", ["size"] = {24,24}, ["romAddr"]={0x606, 0x825}},
 [8] = {["name"] = "Brecconary", ["size"] = {30,30}, ["romAddr"]={0x826, 0x8E7}},
 [9] = {["name"] = "Garinham", ["size"] = {20,20}, ["romAddr"]={0xAAA, 0xB71}},
 [10]= {["name"] = "Cantlin", ["size"] = {30,30}, ["romAddr"]={0x8E8, 0xAA9}},
 [11]= {["name"] = "Rimuldar", ["size"] = {30,30}, ["romAddr"]={0xB72, 0xD33}},
 [12]= {["name"] = "Tantegel Basement", ["size"] = {10,10}, ["romAddr"]={0xD34,0xD65}},
 [13]= {["name"] = "Northern Shrine", ["size"] = {10,10}, ["romAddr"]={0xD66,0xD97}},
 [14]= {["name"] = "Southern Shrine", ["size"] = {10,10}, ["romAddr"]={0xD98,0xDC9}},
 [15]= {["name"] = "Charlock Cave Lv 1", ["size"] = {20,20}, ["romAddr"]={0xDCA, 0xE91}},
 [16]= {["name"] = "Charlock Cave Lv 2", ["size"] = {10,10}, ["romAddr"]={0xE92, 0xEC3}},
 [17]= {["name"] = "Charlock Cave Lv 3", ["size"] = {10,10}, ["romAddr"]={0xEC4, 0xEF5}},
 [18]= {["name"] = "Charlock Cave Lv 4", ["size"] = {10,10}, ["romAddr"]={0xEF6, 0xF27}},
 [19]= {["name"] = "Charlock Cave Lv 5", ["size"] = {10,10}, ["romAddr"]={0xF28, 0xF59}},
 [20]= {["name"] = "Charlock Cave Lv 6", ["size"] = {10,10}, ["romAddr"]={0xF5A, 0xF8B}},
 [21]= {["name"] = "Swamp Cave", ["size"] = {6,30}, ["romAddr"]={0xF8C, 0xFE5}},
 [22]= {["name"] = "Mountain Cave", ["size"] = {14,14}, ["romAddr"]={0xFE6, 0x1047}},
 [23]= {["name"] = "Mountain Cave Lv 2", ["size"] = {14,14}, ["romAddr"]={0x1048, 0x10A9}},
 [24]= {["name"] = "Garin's Grave Lv 1", ["size"] = {20,20}, ["romAddr"]={0x10AA, 0x1171}},
 [25]= {["name"] = "Garin's Grave Lv 2", ["size"] = {14,12}, ["romAddr"]={0x126C, 0x12BF}},
 [26]= {["name"] = "Garin's Grave Lv 3", ["size"] = {20,20}, ["romAddr"]={0x1172, 0x1239}},
 [27]= {["name"] = "Garin's Grave Lv 4", ["size"] = {10,10}, ["romAddr"]={0x123A, 0x126B}},
 [28]= {["name"] = "Erdrick's Cave", ["size"] = {10,10}, ["romAddr"]={0x12C0, 0x12F1}},
 [29]= {["name"] = "Erdrick's Cave Lv 2", ["size"] = {10,10}, ["romAddr"]={0x12F2, 0x1323 }},
}

Tiles = {
 [0] = "Grass",
 [1] = "Sand",
 [2] = "Water",
 [3] = "Treasure Chest",
 [4] = "Stone",
 [5] = "Stairs Up",
 [6] = "Brick",
 [7] = "Stairs Down",
 [8] = "Trees",
 [9] = "Swamp",
 [0xA] = "Force Field",
 [0xB] = "Door",
 [0xC] = "Weapon Shop Sign",
 [0xD] = "Inn Sign",
 [0xE] = "Bridge",
 [0xF] = "Large Tile",
}

MapAddress = 0x45
X_ADDR = 0x8e
Y_ADDR = 0x8f

function getX () return readMemory(X_ADDR) end
function getY () return readMemory(Y_ADDR) end
function getXY () return {["x"]=getX(), ["y"]=getY()} end
function getMapId () return readMemory(MapAddress) end
function getMapData() return MapData[getMapId()] end
function getMapName() return getMapData()["name"] end
function getMapSize() return getMapData()["size"] end
function getMapAddr() return getMapData()["romAddr"] end

function getMapTileAt(x, y)
 local startAddr = getMapAddr()[1]
 local size = getMapSize()
 local height = size[1]
 local offset = (y*height) + x
 local addr = startAddr + math.floor(offset/2)


 local res;
 if (isEven(offset))
 then res = Tiles[hiNibble(rom.readbyte(addr))]
 else res = Tiles[loNibble(rom.readbyte(addr))]
 end

 return res
end

function getMapTiles ()
 local size = getMapSize()
 local width = size[1]
 local height = size[2]
 local res = {}
 for y = 0, height-1 do
 res[y+1] = {}
 for x = 0, width-1 do
 res[y+1][x+1]=getMapTileAt(x,y)
 end
 end
 return res
end


function printMap ()
 local size = getMapSize()
 local width = size[1]
 local height = size[2]
 local tiles = getMapTiles()
 for x = 1,width do
 local row = ""
 for y = 1,height do
 row = row .. "| " .. tiles[x][y]
 end
 print(row .. "|")
 end
end

-------------------
---- MAIN LOOP ----
-------------------

emu.speedmode("normal")

while true do
 print("=============")
 print(getMapData())
 print(getXY())
 print(getMapTiles())
 printMap()
 emu.frameadvance() -- This essentially tells FCEUX to keep running
end


