local evt = require("event")
local gpu = require("component").gpu
local unc = require("unicode")
local beeper = require("computer").beep

local xss, yss, ws, hs = 2, 5, 60, 20
local drawCoordinates = {x = xss, y = yss, bc = 0x660000, fc = 0} -- coordinates where draw starts
local buttons, tnm = {}, tonumber
local needExit = false
local nodes, drawRecur

local curl = (tostring(..., nil) or "browser:about"):lower()

local addrsTable = {
  ["browser:about"] = "browser_main.pyhtml",
  ["http://192.168.0.180/grandprix/lua.xml"] = "grandprix.pyhtml",
  ["https://online.bank.atomicwars.ru/login/"] = "bank_login.pyhtml"
}

local function IndentError(line, reason)
  print("Error when parsing file: " .. reason)
  print("Line " .. tostring(line))
end

io.open('/tmp/brlog', 'w'):close() -- truncate the browser log
local function logs(s)
  local handle = io.open('/tmp/brlog', 'a')
  handle:write(s) -- append new message (from browser / script)
  handle:write('\n')
  handle:close()
end
local function Pipe(inp, ...)
  for id, fn in ipairs({...}) do
    output = {pcall(fn, table.unpack(inp))}
    if not output[1] then
      io.stderr:write('Pipe error at function #' .. tostring(id))
      io.stdout:write('\n' .. tostring(output[2]) .. '\n')
      output = {false}
      return false, output[2]
    end
    table.remove(output, 1)
    inp = output
    os.sleep(0)
  end
  return true, table.unpack(inp)
end

local function readWithIndents(filename)
  -- reads the file, converting first spaces in each line into the indent value (number)
  local commands, curIndent, curText = {}, 0, {}
  local sym
  
  local handle = io.open(filename)
  while true do
    repeat sym = handle:read(1) until (sym == nil or sym ~= "\r")
    if not sym then break end
    
    if sym == " " and #curText == 0 then
      curIndent = curIndent + 1
    elseif sym == "\n" then
      table.insert(commands, {curIndent, table.concat(curText)})
      curIndent, curText = 0, {}
      os.sleep(0)
    else
      table.insert(curText, sym)
    end
  end
  if #curText > 0 then table.insert(commands, {curIndent, table.concat(curText)}) end
  handle:close()
  
  return commands
end
local function splitByIndents(commands)
  -- creates the ierarchy of nodes by their indents
  local rootNode = {}
  local newData = {{parent = rootNode, data = 'MBD'}}
  local lastByIndent, prevIndent = {}, 0
  local index, node
  for index, node in ipairs(commands) do
    local indent, command = node[1], node[2]
    if indent == prevIndent then
      -- parent of this node is the parent of previous node, no problem
      newNode = {parent = newData[index].parent, data = command}
    elseif indent > prevIndent then
      -- parent is the previous node
      newNode = {parent = newData[index], data = command}
    else
      -- parent of this node is the PARENT of the last node with THIS indent
      local lastNode = lastByIndent[indent]
      if lastNode then
        local a
        for a in pairs(lastByIndent) do
          if a > indent then lastByIndent[a] = nil end
        end
      else return newData, IndentError(index, 'unexpected indent') end
      newNode = {parent = lastNode.parent, data = command}
    end
    newData[index + 1] = newNode
    lastByIndent[indent] = newNode
    prevIndent = indent
    os.sleep(0)
  end
  return rootNode, newData
end
local function collapseProperties(root, nodesList)
  -- moves properties to their parents (nodes)
  for _,v in ipairs(nodesList) do
    if v.parent and v.data:match(':%s*%S') then
      local l,r = v.data:match( '([^:]+):%s*(.+)' )
      l = l or 'null'
      if type(v.parent[l]) ~= 'table' then v.parent[l] = {['data'] = 'custom'} end
      table.insert(v.parent[l], r)
      v.data = 'MBD'
    else
      v.data = v.data:match( '[^:]+' )
      if not v.data then v.data = 'MBD' end
    end
    os.sleep(0)
  end
  return root, nodesList
end
local function transformToTree(root, nodesList)
  -- transforms nodes list into the tree
  for _,v in ipairs(nodesList) do
    if v.data ~= 'MBD' then
      v.parent[#(v.parent) + 1] = v
      os.sleep(0)
    end
  end
  return root
end
local function getElementByID(needId, searchKey, curElem, level)
  -- searches element in DOM tree
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
local function searchID_ENV(needId)   return getElementByID(needId, "id", nodes, 1)    end
local function searchTag_ENV(needTag) return getElementByID(needTag, "data", nodes, 1) end

-- working with environment
local curEnv
local function getEnv()
  -- creating new environment if needed
  if not curEnv then
    curEnv = {client = {},    terminal = {}, s = require("serialization"), DOM = nodes, beep = beeper,    unicode = unc,
              tnm = tonumber, print = logs,  searchID = searchID_ENV, sleep = os.sleep, draw = _G.drawRecur, tos = tostring}
  end
  curEnv._G = {this = "_G", old = curEnv}
  curEnv._ENV = {this = "_ENV", old = curEnv}
  return curEnv
end

-- calling scripts in custom environment
local function protectedGetColor(col_text)
  local s, reason = load("return " .. (col_text or "0x000000"), "x", "t", getEnv())
  if not s then logs('method LOAD failed: ' .. tostring(col_text) .. ' / ' .. tostring(reason)) end
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

-- working with GPU
local function setBFcolors(bcol, fcol)
  logs('setBFcolors ' .. tostring(bcol) .. '; ' .. tostring(fcol))
  return gpu.setBackground(bcol or 0xFF0000), gpu.setForeground(fcol or 0x660000)
end
local function drawRectGPU(x, y, w, h, bcol, fcol)
  local oldb, oldf = setBFcolors(bcol, fcol)
  gpu.fill(x, y, w, h, " ")
  setBFcolors(oldb, oldf)
end
local function drawTextGPU(x, y, txt, bcol, fcol)
  logs('drawTextGPU ' .. txt .. ' at ' .. tostring(x) .. ' ' .. tostring(y))
  local oldb, oldf = setBFcolors(bcol, fcol)
  gpu.set(x, y, txt)
  setBFcolors(oldb, oldf)
end

-- create button with text in DOM tree
local function createButton(x, y, w, h, bcol, fcol, txt, parent)
  local buttonNode = {x = x, y = y, w = w, h = h, bcol = bcol, parent = parent}
  local textNode = {parent = buttonNode, fcol = fcol, txt = txt}
  textNode.x = math.floor((w - unc.len(txt)) / 2)
  textNode.y = math.floor((h - 1) / 2)
  table.insert(buttonNode, textNode)
  table.insert(parent, buttonNode)
  return buttonNode
end

local function processProperties(prop)
  -- properties example: '"@ 0 0  | 60 20  * 0x333333 nil"'
  -- result: {x = 0, y = 0, w = 60, h = 20, bcol = 0x333333, fcol = nil}
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

-- drawing PYHTML
function drawRecur(val, lvl, cparam)
  -- this function can process a node in the DOM tree
  lvl = lvl or 0
  if lvl > 20 then return end
  if type(val) ~= "table" then return end
  
  local ox, oy, ob, of = cparam.x, cparam.y, cparam.bc, cparam.fc
  local typeTag = val.data or ""
  
  if typeTag == 'custom' then return end
  
  local prop = {}
  if val.properties then prop = processProperties(val.properties[1]) end
  for k,v in pairs(prop) do val[k] = v end
  
  -- set object's parameters
  if prop.x and prop.y then ox, oy = ox + prop.x, oy + prop.y end
  if prop.bcol then ob = prop.bcol end
  if prop.fcol then of = prop.fcol end
  
  -- draw object
  if typeTag == "rect" and prop.w and prop.h then
    drawRectGPU(ox, oy, prop.w, prop.h, ob, of)
  elseif typeTag == "button" and prop.w and prop.h then
    drawRectGPU(ox, oy, prop.w, prop.h, ob, of)
    
    for _,v in ipairs(val) do if type(v) == 'table' and v.data == 'onpress' then val.onpress = v end end
    table.insert(buttons, {x = ox, y = oy, w = prop.w, h = prop.h, url = val.url, action = val.onpress})
  elseif typeTag == "text" then
    local txt = (val.txt or {})[1] or '""'
    drawTextGPU(ox, oy, txt:sub(2, #txt - 1), ob, of)
  elseif typeTag == "sval" and val.txt then
    local expr = (val.txt or {})[1] or '"nil"'
    drawTextGPU(ox, oy, tostring(protectedGetValue(expr:sub(2, #expr - 1))) or "", ob, of)
  elseif typeTag == "script" and val.command then
    for _,v in ipairs(val.command) do
      local s,r = protectedCallScript(v:sub(2, #v-1))
      logs(('  '):rep(lvl) .. 'script executing: command ' .. v .. ' - result ' .. tostring(s) .. ' - reason ' .. tostring(r))
    end
  end
  
  -- draw children of object
  local key = 1
  while val[key] do
    local nval = val[key]
    if type(nval) == "table" then drawRecur(nval, lvl + 1, {x = ox, y = oy, bc = ob, fc = of}) end
    key = key + 1
  end
  os.sleep(0)
end


local function drawPage(filename)
  drawRectGPU(1, 1, 80, 25, 0, 0) -- clear screen
  drawRectGPU(xss, yss, ws, hs, 0x333333, 0) -- draw dark-grey rectangle
  
  curEnv = nil -- clear environment for the new page
  buttons = {} -- clear buttons list too
  
  -- load file, parse it, move properties to its parents, transform nodes list into DOM tree
  success, nodes = Pipe({filename}, readWithIndents, splitByIndents, collapseProperties, transformToTree)
  if not success then return end
  drawRecur(nodes, 1, drawCoordinates) -- draw parsed PYHTML
  
  -- print browser name, page description and URL
  local tagPage = searchTag_ENV("page") or {}
  local descList = tagPage.desc or {}
  local desc = tostring(descList[1] or '"Неизвестная страница"')
  local addrList = tagPage.addr or {}
  local addr = tostring(addrList[#addrList] or '""')
  
  drawTextGPU(3, 1, desc:sub(2, #desc - 1) .. " - TigerFox", 0, 0xAAAAAA)
  drawTextGPU(64 - #addr, 3, addr:sub(2, #addr - 1), 0, 0xAAAAAA)
  drawTextGPU(3, 3, curl .. '  ', 0, 0xAAAAAA)
  drawTextGPU(60, 1, unc.char(0xFF58), 0xFFAEC9, 0xFF0000)
end

local function touchHandler(_, _, x, y)
  if y == 1 and (x >= 60 and x <= 61) then needExit = true end
  for _, button in ipairs(buttons) do
    if x >= button.x and x < button.x + button.w and y >= button.y and y < button.y + button.h then
      if button.action then
        for _,cmd in ipairs(button.action.command) do protectedCallScript(cmd:sub(2, #cmd-1)) end
      end
      if button.url then
        curl = button.url[1]
        curl = curl:sub(2, #curl - 1)
        drawPage(addrsTable[curl] or "browser_main.pyhtml")
      end
      break
    end
  end
  os.sleep(0.1)
end

-- main loop
drawPage(addrsTable[curl] or "browser_main.pyhtml")
evt.listen("touch", touchHandler)
repeat os.sleep(0.05) until needExit
evt.ignore("touch", touchHandler)

drawRectGPU(1, 1, 80, 25, 0, 0xFFFFFF)