local component = require("component")
local computer = require("computer")
local event = require("event")
local term = require("term")
local fs = require("filesystem")
local beep = component.computer.beep
local reactor=component.reactor_chamber
local rs = component.redstone
local args, options = require("shell").parse(...)


if options.help then
  io.write([[
`reactor`     Контроллер прогрева АЭС на топливе MOX
  --start98   Запуск начального прогрева до 98%
  --start99   Запуск финального прогрева до 99%
  --start     Запуск реактора
  --test      Запуск тестированного прогрева до 10%
  --help      Просмотр этой меню и выход
]])
  return
end

if options.start98 then
  io.write([[Запуск начального прогрева до 98% через 5 секунд]])
  os.sleep(5)
  loadfile("/reactor-core/rcstart98.lua")(loadfile)
end

if options.start99 then
  io.write([[Запуск финального прогрева до 99% через 5 секунд]])
  os.sleep(5)
  loadfile("/reactor-core/rcstart99.lua")(loadfile)
end

if options.start then
  io.write([[Запуск реактора через 5 секунд]])
  os.sleep(5)
  loadfile("/reactor-core/rcstart.lua")(loadfile)
end

if options.test then
  io.write([[Запуск тестированного прогрева до 10% через 5 секунд]])
  os.sleep(5)
  loadfile("/reactor-core/rcstart-test.lua")(loadfile)
end