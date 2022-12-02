
local version="7.0"

local component = require("component")
local computer = require("computer")
local event = require("event")
local term = require("term")
local fs = require("filesystem")
local gpu = component.gpu
local beep = component.computer.beep
local reactor=component.reactor_chamber
local rs = component.redstone

--reactor
Heat=reactor.getMaxHeat
getHeat=reactor.getHeat 
EUOutput=reactor.getReactorEUOutput 
--reactor

--colors
local black = 0x000000
local red = 0xFF0000
local yellow = 0xFFFF00
local white = 0xffffff
--colors

local start_time = computer.uptime()

local modem = component.modem

local w,h = gpu.getResolution()

--maxResolution() 160x50 if 3x2blocks w,h

-- place for config
-------------------
-- end of config


--start_time

--timer
local tickCnt = 0
local running = true
local hours = 0
local mins = 0
--timer

local function centerF(row, msg, ...)
  local mLen = string.len(msg)
  w, h = gpu.getResolution()
  term.setCursor((w - mLen)/2,row)
  print(msg:format(...))
end

--more functions
local function status()
  if EUOutput() == 0 then 
  return "offline" 
  else
  return "online "
  end
end 

local function maxheat()
  return reactor.getMaxHeat()
  end
  
local function getheat()
  if getHeat() == 0 then
  return "0   "
  else
  return reactor.getHeat()
  end
end
  
local function getEU()
  if EUOutput() == 0 then
  return "0   "
  else
  return reactor.getReactorEUOutput()
  end
end
--more functions  

gpu.setForeground(0xffffff)


-----
term.clear()
term.setCursor(1,1)

centerF(5,  "-----------------------------------------")
centerF(6,  "-       IC2 Reactor Controller V1.3     -")
centerF(7,  "-----------------------------------------")
centerF(8, string.format("- Reactor is:             %s       -",status())) 
centerF(9, string.format("- Reactor maxheat:        %s         -",maxheat())) 
centerF(10, string.format("- Reactor heat:           %s          -",  getheat())) 
centerF(11, string.format("- Reactor EU Output:      %s          -",  getEU())) 
centerF(12, "-----------------------------------------")
centerF(13, "-                                       -")   
centerF(14, "-----------------------------------------")
  
while true do 

  
  tickCnt = tickCnt + 1
  if tickCnt == 60 then
    mins = mins + 1
    tickCnt = 0
  end
  
  if mins == 60 then
    hours = hours + 1
    mins = 0
  end
  
  if reactor.getHeat() >= 9980 then
    rs.setOutput(1, 0)
    centerF(13, "-         Heat reactor is 99            -")
	centerF(14, "-            Restart system             -")   
    centerF(15, "-----------------------------------------")
	os.sleep(3)
	computer.shutdown(true)
  else
    rs.setOutput(1, 1)
	rs.setOutput(2, 1)
	rs.setOutput(3, 1)
	rs.setOutput(4, 1)
	rs.setOutput(5, 1)
  end 

  os.sleep(1)
  
  centerF(8, string.format("- Reactor is:             %s       -",status())) 
  centerF(9, string.format("- Reactor maxheat:        %s         -",maxheat())) 
  centerF(10, string.format("- Reactor heat:           %s          -",  getheat())) 
  centerF(11, string.format("- Reactor EU Output:      %s          -",  getEU())) 
  centerF(3, "Data updates every second: %2d", tickCnt)
  centerF(4, "Current up time: %2d hours %2d min", hours, mins)
end