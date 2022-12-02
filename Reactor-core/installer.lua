local shell = require("shell")
local fs = require("filesystem")
local prefix = "https://raw.githubusercontent.com/FrisKAY/OpenComputers_Programm/master/Reactor-core/"
local comp = require("computer")
local files = {"/bin/reactor.lua","/reactor-core/rcstart.lua","/reactor-core/rcstart98.lua","/reactor-core/rcstart99.lua","/reactor-core/rcstart-test.lua",}

fs.makeDirectory("/reactor-core/")

for _,v in pairs(files) do
  if not fs.exists(v:match(".*/")) then fs.makeDirectory(v:match(".*/")) end
  shell.execute("wget -f "..prefix..v.." "..v)
end
comp.shutdown("true")
