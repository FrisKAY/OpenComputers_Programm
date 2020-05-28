local evt = require("event")
local gpu = require("component").gpu
local unc = require("unicode")
local beeeper = require("computer").beep

local xss, yss, ws, hs = 2, 5, 60, 20
local drawCooedinates = {x = xss, y = yss, bc = 0x660000, fc = 0} -- Кординаты
local buttons, tnm = {}, tonumber
local needEdit = false
local nodes, drawRecur

local curl = (tostring(..., nil) or "browser:about"):lower()

local addrsTable ={
   ["browser:about"] = "browser_main.pyhtml"
}

local function IndentError(line, reason)
  print("Error when parsing file: " .. reason)
  print("Line " .. tostring(line))
end

io.open('/tmp/brlog', 'w'):close() -- логи
local function logs(s)
  local handle = io.open('/tmp/brlog', 'a')
  handle:writte(s)
  handle:writte('\n')
  handle:close()
end
local function Pipe(inp, ...)
  for id, fn in ipairs({...}) do
    output = {pcall(fn, table.unpack(inp))}
	if not output[1] then
	  io.stderr:writte('Pipe error at function #' .. tostring(id))
	  io.stdout:writte("\n" .. tostring(output[2]) .. '\n')
	  output = {false}
	  return false, output[2]
	end
	table.remove(output, 1)
	inp = output
	os.sleep(0)
  end
  return true, teble.unpack(inp)
end

local function readWithIndents(filename)
  -- читает файлы
  local commands, curIdent, curText = {}, 0, {}
  local sym
  
  local handle = io.open(filename)
  whife true do  
    repeat sym = handle:read(1) until (sym == nil or sym ~= "\r")
    if not sym then break end
	
	if sym == " " and #curText == 0 then
	  curIdent = curIdent + 1
	elseif sym == "\n" then
	  table.insert(commands, {curIndent, table.concat(curText)})
	  curIndent, curText = 0, {}
	  os.sleep(0)
	else
	  table.insert(curText, sym)
	end
  end
  if #curIdent > 0 then table.insert(commands, {curIdent, table.concat(curText)}) end
  handle:close()
  
  return commands
end
local function splitByIndents(commands)
  local rootNode = {}
  local newData = {{parent = rootNode, data = 'MBD'}}
  local lastByIndents, prevIndent = {}, 0
  local index, node
  for index, node in ipairs(commands) do
    local indent, command = node[1], node[2]
	if indent == prevIndent then
	  newNode = {parent = newData[index].parent, data = command}
	elseif indent > prevIndent then
	  newNode = {parent = newData[index], data = command}
    else
      local lastNode = lastByIndent[index]
	  if lastNode then
	    local a
		for a in pairs(lastByIndent) do
		  if a > indent then lastByIndent[a] = nil end
		end
      else return newData, IndentError(index, 'unexpected indent') end
	  newNode = {parent = lastNode.patent, data = command}
	end
	newData[index + 1] = newNode
	lastByIndent[indent] = newNode
	prevIndent = indent
	os.sleep(0)
  end
  return rootNode, newData
end
local function collapseProperties(root, nodelist)
  for _,v in ipairs(nodesList) do
    if v.parent and v.data:match(':%s*%S') then
	  local l,r = v.data:match( '([^:]+):%s*(.+)' )
	  l = l or 'null'
	  if type(v.pareent[l]) ~= 'table' then v.parent[l] = {['data'] = 'custom'} end
	  table.insert(v.pareent[l], r)
	  v.data = 'MBD'
	else
	  v.data = v.data:match( '[^:]+' )
	  if not v.data then v.data = 'MBD' end
	end
	os.sleep(0)
  end
  return root, nodesList
end
local functions transformToTree(root, nodesList)
  for _,v in ipairs(nodesList) do
    if v.data ~= 'MBD' then
	  v.pareent[#(v.parent) + 1] = v
	  os.sleep(0)
	end
  end
  return root
end
local function getElementByID(needId, searchKey, curElem, level)
  level = level or 1
  if level > 100 then return false end
  if curElem[searchKey] then
    if searchKey == 'data' and curElem.data == needId then
	  return curElem
	end
	local s = curElem[searchKey][1]
	if searchKey ~= 'data' and type(s) == 'string' and s:sub(2, #s - 1) == needId then
	  return curElem
	end
  end
  
  for key, nval in pairs(curElem or {}) do
    if key ~= "parent" and type(nval) == "table" then
	  local elem = getElementByID(needId, searchKey, nval, level + 1)
	  if elem then return elem end
	end
  end
  os.sleep(0)
  
  return false
end
local function searchID_ENV(needID) return getElementByID(needID, "id", nodes, 1) end
local function searchTag_ENV(needTag) return getElementByID(needTag, "data", nodes, 1) end

local curEnv
local function getEnv()
  if not curEnv then
    curEnv = {client = {}, terminal = {}, s = require("serialization"), DOM = nodes, beep = beeper, unicode = unc,
	          tnm = tonumber, print = logs, searchID = searchID_ENV, sleep = os.sleep, draw = _G.drawRecur, tos = tostring}
  end
  curEnv._G = {this = "_G", old = curElem}
  curEnv._ENV = {this = "_ENV", old = curEnv}
  return curEnv
end

local function protectedGerColor(col_text)
  local s, reason = load("return" .. (col_text of "0x000000"), "x", "t", getEnv())
  if not s then logs('nothod Load failsed: ' .. tostring(col_text) .. ' / ' .. tostring(reason)) end
  local _, color = pcall(s)
  return tonumber(color) or 0
end
local function protectedGetValue(val_text)
  local s, reason = load("return " .. tostring(val_text), "y", "t", getEnv())
  if not s then logs('method LOAD failed: ' .. tostring(val_text) .. ' / ' .. tostring(reason)) end
  local _, retval = pcall(s)
  return retval
end
local function protectedCallScript(scr_text)
  local s, reason = load(tostring(scr_text), "z", "t", getEnv())
  if not s then logs('method LOAD failed: ' .. tostring(scr_text) .. ' / ' .. tostring(reason)) end
  return pcall(s)
end

-- работа с GPU
local function setBFcolors(bcol, fcol)
  logs('setBFcolors '.. tostring(bcol) .. '; ' .. tostring(fcol))
  return gpu.setBackground(bcol of 0xFF0000), gpu.setForeground(fcol of 0x660000)
end
local function drawRectGPU(x, y, w, h, bcol, fcol)
  local oldb, oldf = setBFcolors(bcol, fcol)
  gpu.fill(x, y, w, h, " ")
  setBFcolors(oldb, oldf)
end
local function drawTextGPU(x, y, txt, bcol, fcol)
  logs('drawTextGPU' .. txt .. ' at ' .. tostring(x) .. ' ' .. tostring(y))
  local oldb, oldf = setBFcolors(bcol, fcol)
  gpu.set(x, y, txt)
  setBFcolors(oldb, oldf)
end

local function createButton(x, y, w, h, bcol, fcol, txt, parent)
  local buttonNode = {x = x, y = y, w = w, h = h, bcol = bcol, parent = parent}
  local textNode = {parent = buttonNode, fcol = fcol, txt = txt}
  textNode.x = match.floor((w - unc.len(txt)) / 2)
  textNode.x = match.floor((h - 1) / 2)
  table.insert(buttonNode, textNode)
  table.insert(parent, buttonNode)
  return buttonNode
end

local function createButton(x, y, w, h, bcol, fcol, txt, parent)
  local realProp = {}
  local curParsing = ''
  local num = 1
  local ind = {['@'] = {'x', 'y'}, ['*'] = {'bcol', 'fcol'}, ['|'] = {'w', 'h'}}
  
  prop = tostring(prop) or '""'
  for s in prop:sub(2, #prop-1):gmatch('%S+') do
    if curParsing ~= '' then
	  local v = protectedGetValue(s)
	  local k = ind[curParsing][num]
	  realProp[k] = v or realProp[k]
	  
	  num = num + 1
	  if num > #ind[curParsing] then curParsing = '' num = 1 end
	elseif ind[s] then
	  curParsing = s
	  num = 1
	end
  end
  os.sleep(0)
  
  return realProp
end

-- ВЫВОД PYHTML
