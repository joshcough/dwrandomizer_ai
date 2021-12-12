require "Class"
enum = require("enum")

function bitwise_and(a, b)
  return AND(a, b)
end

function decimalToHex(num)
    if num == 0 then
        return '0'
    end
    local neg = false
    if num < 0 then
        neg = true
        num = num * -1
    end
    local hexstr = "0123456789ABCDEF"
    local result = ""
    while num > 0 do
        local n = math.mod(num, 16)
        result = string.sub(hexstr, n + 1, n + 1) .. result
        num = math.floor(num / 16)
    end
    if neg then
        result = '-' .. result
    end
    return result
end

-- HI_NIBBLE(b) (((b) >> 4) & 0x0F)
function hiNibble(b) return bitwise_and(math.floor(b/16), 0x0F) end
-- LO_NIBBLE(b) (((b) & 0x0F)
function loNibble(b) return bitwise_and(b, 0x0F) end

function isEven(n) return n%2 == 0 end
function isOdd(n) return n%2 == 1 end

function round(n)
  return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

aiLogFile = io.open("/Users/joshcough/work/dwrandomizer_ai/ai.out", "w")

log = {}

function log.debug(...)
  local args = { ... }
	log.debugArgs(args)
end

function log.debugArgs(args)
	for _, v in ipairs( args ) do
		aiLogFile:write(tostring(v) .. "\t")
	end
  aiLogFile:write("\n")
  aiLogFile:flush()
end

function log.err(msg, ...)
  local args = { ... }
  log.debug("ERROR: ", msg)
  log.debug("args were:")
	log.debugArgs(args)
  error(msg)
end

function table.shallow_copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

 -- declare local variables
 --// exportstring( string )
 --// returns a "Lua" portable version of the string
 local function exportstring( s )
    return string.format("%q", s)
 end

 --// The Save Function
function table.save(tbl, filename)
  local charS,charE = "   ","\n"
  local file,err = io.open( filename, "wb" )
  if err then return err end

  -- initiate variables for save procedure
  local tables,lookup = { tbl },{ [tbl] = 1 }
  file:write( "return {"..charE )

  for idx,t in ipairs( tables ) do
     file:write( "-- Table: {"..idx.."}"..charE )
     file:write( "{"..charE )
     local thandled = {}

     for i,v in ipairs( t ) do
        thandled[i] = true
        local stype = type( v )
        -- only handle value
        if stype == "table" then
           if not lookup[v] then
              table.insert( tables, v )
              lookup[v] = #tables
           end
           file:write( charS.."{"..lookup[v].."},"..charE )
        elseif stype == "string" then
           file:write(  charS..exportstring( v )..","..charE )
        elseif stype == "number" then
           file:write(  charS..tostring( v )..","..charE )
        end
     end

     for i,v in pairs( t ) do
        -- escape handled values
        if (not thandled[i]) then

           local str = ""
           local stype = type( i )
           -- handle index
           if stype == "table" then
              if not lookup[i] then
                 table.insert( tables,i )
                 lookup[i] = #tables
              end
              str = charS.."[{"..lookup[i].."}]="
           elseif stype == "string" then
              str = charS.."["..exportstring( i ).."]="
           elseif stype == "number" then
              str = charS.."["..tostring( i ).."]="
           end

           if str ~= "" then
              stype = type( v )
              -- handle value
              if stype == "table" then
                 if not lookup[v] then
                    table.insert( tables,v )
                    lookup[v] = #tables
                 end
                 file:write( str.."{"..lookup[v].."},"..charE )
              elseif stype == "string" then
                 file:write( str..exportstring( v )..","..charE )
              elseif stype == "number" then
                 file:write( str..tostring( v )..","..charE )
              end
           end
        end
     end
     file:write( "},"..charE )
  end
  file:write( "}" )
  file:close()
end

--// The Load Function
function table.load( sfile )
  local ftables,err = loadfile( sfile )
  if err then return _,err end
  local tables = ftables()
  for idx = 1,#tables do
     local tolinki = {}
     for i,v in pairs( tables[idx] ) do
        if type( v ) == "table" then
           tables[idx][i] = tables[v[1]]
        end
        if type( i ) == "table" and tables[i[1]] then
           table.insert( tolinki,{ i,tables[i[1]] } )
        end
     end
     -- link indices
     for _,v in ipairs( tolinki ) do
        tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
     end
  end
  return tables[1]
end

function table.dump( t )
  for i,v in pairs(t) do
    log.debug(i,v)
  end
end

function table.contains(list, x, equalityOp)
  for _, v in pairs(list) do
    if equalityOp == nil and x == v then return true
    elseif equalityOp(x, v) then return true
    end
  end
  return false
end

function table.containsUsingDotEquals(t, x)
  return table.contains(t, x, function(v1, v2) return v1:equals(v2) end)
end

function table.count(list, x, equalityOp)
  local res = 0
  for _, v in pairs(list) do
    if equalityOp == nil then if v == x then res = res + 1 end
    elseif equalityOp(x, v) then res = res + 1
    end
  end
  return res
end

function table.copy(tbl)
  local t = {}
  for _, v in pairs(tbl) do table.insert(t, v)  end
  return t
end

-- TODO: maybe this should be list.reverse, along with several other functions in here.
function table.reverse(tbl)
  local t = {}
  for i=1, #tbl do
     table.insert(t, tbl[#tbl + 1 - i])
  end
  return t
end

-- TODO: this should be list.concat right?
function table.concat(tbl1, tbl2)
  local res = table.copy(tbl1)
  for _,v in ipairs(tbl2) do
      table.insert(res, v)
  end
  return res
end

-- TODO: is this join? it looks identical
function table.concatAll(tbls)
  local res = {}
  for i=1, #tbls do
    for _,v in ipairs(tbls[i]) do
      table.insert(res, v)
    end
  end
  return res
end

list = {}

function list.drop(n, t)
  local res = {}
  if n > #(t) then return {} end
  for i = n+1, #(t) do
    table.insert(res, t[i])
  end
  return res
end

function list.zip(t1, t2)
  return list.zipWith(t1, t2, function(l,r) return {l,r} end)
end

function list.zipWith(f, t1, t2)
  local res = {}
  for i = 1, math.min(#(t1), #(t2)) do
    table.insert(res, f(t1[i], t2[i]))
  end
  return res
end

function list.foldLeft(t, initialValue, op)
  local res = initialValue
  for i = 1, #(t) do res = op(res, t[i]) end
  return res
end

function list.map(t, f)
  local res = {}
  for i = 1, #(t) do table.insert(res, f(t[i])) end
  return res
end

function list.foreach(t, f)
  if t == nil then return nil end
  for i = 1, #(t) do f(t[i]) end
end

-- join :: [[a]] -> [a]
function list.join(t)
  local res = {}
  for i = 1, #(t) do
    for j = 1, #(t[i]) do
      table.insert(res, t[i][j])
    end
  end
  return res
end

-- bind :: [a] -> (a -> [b]) -> [b]
function list.bind(l, f)
  return list.join(list.map(l,f))
end

-- intersperse :: a -> [a] -> [a]
--The intersperse function takes an element and a list and `intersperses'
-- that element between the elements of the list. For example,
-- >>> intersperse ',' "abcde"
-- "a,b,c,d,e"
function list.intersperse(a, t)
  local res = {}
  for i = 1, #(t) do
    table.insert(res, t[i])
    if i < #(t) then table.insert(res, a) end
  end
  return res
end

-- intercalateS :: String -> [String] -> String
function list.intercalateS(a, t)
  local res = ""
  for i = 1, #(t) do
    res = res .. tostring(t[i])
    if i < #(t) then res = res .. a end
  end
  return res
end

function list.indexOf(t, v, eqOp)
  for i = 1, #t do
    if eqOp == nil then
      if v == t[i] then return i end
    else
      if eqOp(v,t[i]) then return i end
    end
  end
  return nil
end

function list.find(t, predicate)
  for i = 1, #t do
    if predicate(t[i]) then return t[i] end
  end
  return nil
end

function list.findWithIndex(t, predicate)
  for i = 1, #t do
    if predicate(t[i]) then return { index=i, value=t[i] } end
  end
  return nil
end

function list.exists(t, v, eqOp)
  return list.indexOf(t, v, eqOp) ~= nil
end

function list.delete(t, index)
  local res = {}
  for i = 1, #t do
    if i ~= index then table.insert(res, t[i]) end
  end
  return res
end

function list.min(t, f)
  if #(t) == 0 then return nil end
  return list.foldLeft(t, {false, f(t[1]) + 1}, function(acc, c)
    local v = f(c)
    if v < acc[2] then return {c, v} else return acc end
  end)[1]
end

function list.max(t, f)
  if #(t) == 0 then return nil end
  return list.foldLeft(t, {false, f(t[1]) - 1}, function(acc, c)
    local v = f(c)
    if v > acc[2] then return {c, v} else return acc end
  end)[1]
end

function list.all(t, f)
  for i = 1, #t do
    if not f(t[i]) then return false end
  end
  return true
end

function list.any(t, f)
  for i = 1, #t do
    if f(t[i]) then return true end
  end
  return false
end

function list.filter(t, f)
  local res = {}
  for i = 1, #(t) do
    if f(t[i]) then table.insert(res, t[i]) end
  end
  return res
end

function list.filter3(t, f)
  return
    list.filter(t,
      function(t2)
        return list.filter(t2, function(t3) return list.filter(t3, f) end)
      end)
end

function list.span(t, pred)
  local resL = {}
  local resR = {}
  if #(t) == 0 then return {{}, {}} end

  local b = pred(t[1])
  local doneWithL =  false
  for i = 1, #(t) do
    if pred(t[i]) == b and not doneWithL then
      table.insert(resL, t[i])
    else
      doneWithL = true
      table.insert(resR, t[i])
    end
  end
  return {resL, resR}
end

function list.debug(l) list.foreach(l, log.debug) end
function list.print(l) list.foreach(l, print) end

function table.log(arr, indentLevel)
    local str = ""
    local indentStr = "#"

    if(indentLevel == nil) then
        log.debug(table.log(arr, 0))
        return
    end

    for i = 0, indentLevel do
        indentStr = indentStr.."\t"
    end

    for index,value in pairs(arr) do
        if type(value) == "table" then
            str = str..indentStr..index..": \n"..table.log(value, (indentLevel + 1))
        else
            str = str..indentStr..index..": "..tostring(value).."\n"
        end
    end
    return str
end

Queue = class(function(a)
  a.stack = {}
end)

function Queue:push(e)
  table.insert(self.stack, e)
end

function Queue:pop()
  local e = self.stack[1]
  table.remove(self.stack, 1)
  return e
end

function Queue:size()
  return #self.stack
end

function Queue:isEmpty()
  return self:size() == 0
end

function padded(x)
  local res = tostring(x)
  if     #res == 1 then return "  " .. res
  elseif #res == 2 then return " " .. res
  else return res
  end
end

Table3D = class(function(a)
  a.body = {}
end)

function Table3D:insert(p, value)
  if self.body[p.mapId] == nil then self.body[p.mapId] = {} end
  if self.body[p.mapId][p.x] == nil then self.body[p.mapId][p.x] = {} end
  self.body[p.mapId][p.x][p.y] = value
end

function Table3D:lookup(p, default)
  if self.body[p.mapId] == nil then return default end
  if self.body[p.mapId][p.x] == nil then return default end
  if self.body[p.mapId][p.x][p.y] == nil then return default end
  return self.body[p.mapId][p.x][p.y]
end

function Table3D:contains(p)
  if self.body[p.mapId] == nil then return false end
  if self.body[p.mapId][p.x] == nil then return false end
  return self.body[p.mapId][p.x][p.y] ~= nil
end

function Table3D:debug(name)
  log.debug("====" .. name .. "====")
  for i,v in pairs(self.body) do
    for j,v2 in pairs(v) do
      for k,v3 in pairs(v2) do
        log.debug(Point(i, j, k), v3)
      end
    end
  end
--   self:iterate(function(p, a) log.debug(p,a) end)
  log.debug("====end " .. name .. "====")
end

function Table3D:iterate(f)
  for i,v in pairs(self.body) do
    for j,v2 in pairs(v) do
      for k,v3 in pairs(v2) do
        f(Point(i, j, k), v3)
      end
    end
  end
end

-- @self :: Table3D a
-- @f :: a -> b
-- @returns Table3D b
function Table3D:map(f)
  local res = Table3D()
  self:iterate(function (p, a) res:insert(p,a) end)
  return res
end

-- @self :: Table3D a
-- @f :: a -> Bool
-- @returns Table3D a
function Table3D:filter(f)
  local res = Table3D()
  self:iterate(function(p, a) if f(a) then res:insert(p,a) end end)
  return res
end

-- @self :: Table3D a
-- @returns [a]
function Table3D:toList()
  local res = {}
  self:iterate(function (_, a) table.insert(res, a) end)
  return res
end

-- @self :: Table3D a
-- @mapId :: Int / MapId (dont' think MapId actually exists, but it would be nice if it did IMO)
-- @returns [a]
function Table3D:allEntriesForMap(mapId)
  local res = {}
  self:iterate(function (p, a) if p.mapId == mapId then table.insert(res, a) end end)
  return res
end

Maybe = class(function(a) end)

function Maybe:map(f)            return maybe.map(self, f)            end
function Maybe:bind(f)           return maybe.bind(self, f)           end
function Maybe:maybe(default, f) return maybe.maybe(self, default, f) end
function Maybe:foreach(f)        return maybe.foreach(self, f)        end
function Maybe:fromMaybe(a)      return maybe.fromMaybe(self, a)      end

Just = class(Maybe, function(a, value)
  Maybe.init(a)
  a.value = value
end)

function Just:__tostring()
  return "<Just " .. tostring(self.value) .. ">"
end

PrivateNothing = class(Maybe, function(a)
  Maybe.init(a)
end)

Nothing = PrivateNothing()

function PrivateNothing:__tostring()
  return "<Nothing>"
end

maybe = {}

-- @a :: a? (possibly nil value of type a)
-- @returns :: Maybe a
function maybe.toMaybe(a)
  if a == nil then return Nothing else return Just(a) end
end

maybe.pure = maybe.toMaybe

-- @m :: Maybe a
-- @f :: a -> b
-- @returns :: Maybe b
function maybe.map(m, f)
  return m == Nothing and Nothing or Just(f(m.value))
end

-- @m :: Maybe a
-- @f :: a -> Maybe b
-- @returns :: Maybe b
function maybe.bind(m, f)
  return m == Nothing and Nothing or f(m.value)
end

-- @m :: Maybe a
-- @default :: b
-- @f :: a -> b
-- @returns :: b
function maybe.maybe(m, default, f)
  return m == Nothing and default or f(m.value)
end

-- @m :: Maybe a
-- @f :: a -> z
-- @returns :: nil
function maybe.foreach(m, f) maybe.maybe(m, nil, f) end

-- @m :: Maybe a
-- @default :: a
-- @returns :: a
function maybe.fromMaybe(m, default)
  return maybe.maybe(m, default, function(v) return v end)
end

-- @listOfMaybes :: [Maybe a]
-- @returns :: [a]
function list.catMaybes(listOfMaybes)
  local res = {}
  list.foreach(listOfMaybes, function(m)
    maybe.maybe(m, nil, function(v) table.insert(res, v) end)
  end)
  return res
end

-- @l :: [a]
-- @returns :: Maybe a
function list.toMaybe(l)
  return maybe.toMaybe(l[1])
end

Heading = enum.new("Direction player is heading", {
  "LEFT",
  "RIGHT",
  "UP",
  "DOWN"
})