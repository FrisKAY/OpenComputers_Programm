local module = {}
local GUI = require("GUI")
local uuid = require("uuid")

local userTable

local workspace, window, loc, database, style = table.unpack({...})

module.name = "Sectors"
module.table = {"sectors"}
module.debug = false
module.version = "3.0.1"
module.id = 1112

module.init = function(usTable)
  userTable = usTable
end

module.onTouch = function()
  local sectorList, sectorNameInput, newSectorButton, delSectorButton, sectorPassNew, sectorPassRemove, sectorPassEdit, sectorPassList, userPassSelfSelector, userPassDataSelector, userPassTypeSelector, userPassPrioritySelector
  local sectorListNum, sectorListUp, sectorListDown, sectorPassListNum, sectorPassListUp, sectorPassListDown

  local canPerm

  local pageMult = 10
  local listPageNumber = 0
  local previousPage = 0

  local pageMultPass = 5
  local listPageNumberPass = 0
  local previousPagePass = 0
  local prevPass = "string"

  --Sector functions

  local function uuidtopass(uuid)
    if uuid == "checkstaff" then
      return true, 0
    end
    for i=1,#userTable.passSettings.calls,1 do
      if userTable.passSettings.calls[i] == uuid then
        return true, i
      end
    end
    return false
  end

  local function refreshInput()
    local uuid = userPassSelfSelector.selectedItem - 1
    if uuid ~= 0 then
      if userTable.passSettings.type[uuid] == "string" or userTable.passSettings.type[uuid] == "-string" or userTable.passSettings.type[uuid] == "int" then
        if prevPass == "-int" then
          userPassDataSelector:remove()
          userPassDataSelector = window:addChild(GUI.input(100,22,16,1, style.containerInputBack,style.containerInputText,style.containerInputPlaceholder,style.containerInputFocusBack,style.containerInputFocusText, "", loc.inputtext))
        end
        userPassDataSelector.text = ""
        userPassDataSelector.disabled = canPerm
      elseif userTable.passSettings.type[uuid] == "-int" then
        if prevPass ~= "-int" then
          userPassDataSelector:remove()
          userPassDataSelector = window:addChild(GUI.comboBox(100,21,30,3, style.sectorComboBack,style.sectorComboText,style.sectorComboArrowBack,style.sectorComboArrowText))
        else
          userPassDataSelector:clear()
        end
        for _,value in pairs(userTable.passSettings.data[uuid]) do
          userPassDataSelector:addItem(value)
        end
        userPassDataSelector.selectedItem = 1
      else
        if prevPass == "-int" then
          userPassDataSelector:remove()
          userPassDataSelector = window:addChild(GUI.input(100,22,16,1, style.containerInputBack,style.containerInputText,style.containerInputPlaceholder,style.containerInputFocusBack,style.containerInputFocusText, "", loc.inputtext))
        end
        userPassDataSelector.text = ""
        userPassDataSelector.disabled = true
      end
    else
      if prevPass == "-int" then
        userPassDataSelector:remove()
        userPassDataSelector = window:addChild(GUI.input(100,22,16,1, style.containerInputBack,style.containerInputText,style.containerInputPlaceholder,style.containerInputFocusBack,style.containerInputFocusText, "", loc.inputtext))
      end
      userPassDataSelector.text = ""
      userPassDataSelector.disabled = true
    end
    prevPass = uuid ~= 0 and userTable.passSettings.type[uuid] or "bool"
  end

  --[[local function sectorPassCallback() Commented out because not planning on making it possible to add sectors for simplicity for meeeee
    local selectedId = pageMultPass * listPageNumberPass + sectorPassList.selectedItem
    local secSelect = pageMult * listPageNumber + sectorList.selectedItem
    local sectorpass = userTable.sectors[secSelect].pass[selectedId]
    local uuid = uuidtopass(sectorpass.uuid)
    userPassSelfSelector.selectedItem = uuid + 1
    userPassTypeSelector.selectedItem = sectorpass.lock
    refreshInput(uuid)
  end]]

  local function sectorListCallback()
    local selectedId = pageMult * listPageNumber + sectorList.selectedItem
    sectorNameInput.text = userTable.sectors[selectedId].name
    sectorPassList:removeChildren()
    if pageMultPass * listPageNumberPass <= #userTable.sectors[selectedId].pass and listPageNumberPass ~= 0 then
      listPageNumberPass = listPageNumberPass - 1
    end
    local temp = pageMultPass * listPageNumberPass
    if previousPagePass ~= listPageNumberPass then
      sectorPassList.selectedItem = 1
      previousPagePass = listPageNumberPass
    end
    sectorPassListDown.disabled = listPageNumberPass == 0
    sectorPassListUp.disabled = #userTable.sectors[selectedId].pass <= temp + pageMultPass
    sectorPassListNum.text = tostring(listPageNumberPass + 1)
    sectorPassNew.disabled = canPerm
    sectorPassRemove.disabled = canPerm
    sectorPassEdit.disabled = canPerm
    for i = temp + 1, temp + pageMultPass, 1 do
      if (userTable.sectors[selectedId].pass[i] == nil) then
        if i == temp + 1 then
          sectorPassRemove.disabled = true
          sectorPassEdit.disabled = true
        end
      else
        local work, pass = uuidtopass(userTable.sectors[selectedId].pass[i].uuid)
        local lockType = {loc.sectoropen,loc.sectordislock}
        if pass ~= 0 then
          local disdata = userTable.sectors[selectedId].pass[i].data ~= nil and userTable.sectors[selectedId].pass[i].data or "0"
          if userTable.passSettings.type[pass] == "-int" then
            disdata = userTable.passSettings.data[pass][disdata]
          end
          sectorPassList:addItem(userTable.passSettings.label[pass] .. " : " .. tostring(disdata) .. " : p" .. tostring(userTable.sectors[selectedId].pass[i].priority) .. " : " .. lockType[userTable.sectors[selectedId].pass[i].lock])
        else
          sectorPassList:addItem("Staff : 0 : p" .. tostring(userTable.sectors[selectedId].pass[i].priority) .. " : " .. lockType[userTable.sectors[selectedId].pass[i].lock])
        end
      end
    end
    workspace:draw()
  end

  local function updateSecList()
    local selectedId = sectorList.selectedItem
    sectorList:removeChildren()
    if pageMult * listPageNumber <= #userTable.sectors and listPageNumber ~= 0 then
      listPageNumber = listPageNumber - 1
    end
    local temp = pageMult * listPageNumber
    sectorListNum.text = tostring(listPageNumber + 1)
    for i = temp + 1, temp + pageMult, 1 do
      if (userTable.sectors[i] == nil) then

      else
        sectorList:addItem(userTable.sectors[i].name).onTouch = sectorListCallback
      end
    end
    database.save()
    if (previousPage == listPageNumber) then
      sectorList.selectedItem = selectedId
    else
      sectorList.selectedItem = 1
      listPageNumberPass = 0
      sectorListCallback()
      previousPage = listPageNumber
    end
    sectorListDown.disabled = listPageNumber == 0
    sectorListUp.disabled = #userTable.sectors <= temp + pageMult
    database.update()
    workspace:draw()
  end

  local function pageCallback(workspace,button)
    local function canFresh()
      updateSecList()
      sectorListCallback()
    end
    if button.isPos then
      if button.isListNum == 1 then
        if listPageNumber < #userTable.sectors/pageMult - 1 then
          listPageNumber = listPageNumber + 1
          canFresh()
        end
      else
        if listPageNumberPass < #userTable.sectors[pageMult * listPageNumber + sectorList.selectedItem].pass/pageMultPass - 1 then
          listPageNumberPass = listPageNumberPass + 1
          canFresh()
        end
      end
    else
      if button.isListNum == 1 then
        if listPageNumber > 0 then
          listPageNumber = listPageNumber - 1
          canFresh()
        end
      else
        if listPageNumberPass > 0 then
          listPageNumberPass = listPageNumberPass - 1
          canFresh()
        end
      end
    end
  end

  local function createSector()
    local addVarArray = {["name"]="new sector",["uuid"]=uuid.next(),["pass"]={}}
    table.insert(userTable.sectors,addVarArray)
    addVarArray = nil
    database.save()
    database.update()
    updateSecList()
  end
  local function deleteSector()
    local selected = pageMult * listPageNumber + sectorList.selectedItem
    table.remove(userTable.sectors,selected)
    if #userTable.sectors < pageMult * listPageNumber + 1 and listPageNumber ~= 0 then
      listPageNumber = listPageNumber - 1
    end
    database.save()
    database.update()
    updateSecList()
  end

  local function createSectorPass()
    local selected = userPassSelfSelector.selectedItem - 1
    local data = selected == 0 and nil or userTable.passSettings.type[selected] == "-int" and userPassDataSelector.selectedItem or userTable.passSettings.type[selected] == "bool" and nil or userTable.passSettings.type[selected] == "int" and tonumber(userPassDataSelector.text) or userPassDataSelector.text
    local uuid = selected == 0 and "checkstaff" or userTable.passSettings.calls[selected]
    table.insert(userTable.sectors[pageMult * listPageNumber + sectorList.selectedItem].pass,{["uuid"]=uuid,["data"]=data,["lock"]=userPassTypeSelector.selectedItem,["priority"]=userPassPrioritySelector.selectedItem})
    database.save()
    database.update()
    sectorListCallback()
  end
  local function deleteSectorPass()
    local selected = pageMultPass * listPageNumberPass + sectorPassList.selectedItem
    table.remove(userTable.sectors[pageMult * listPageNumber + sectorList.selectedItem].pass,selected)
    if #userTable.sectors[pageMult * listPageNumber + sectorList.selectedItem].pass < pageMultPass * listPageNumberPass + 1 and listPageNumberPass ~= 0 then
      listPageNumberPass = listPageNumberPass - 1
    end
    database.save()
    database.update()
    sectorListCallback()
  end
  local function editSectorPass()
    local selected = pageMultPass * listPageNumberPass + sectorPassList.selectedItem
    local apples = userTable.sectors[pageMult * listPageNumber + sectorList.selectedItem].pass[selected]
    table.remove(userTable.sectors[pageMult * listPageNumber + sectorList.selectedItem].pass,selected)
    sectorListCallback()
    userPassPrioritySelector.selectedItem = apples.priority
    userPassTypeSelector.selectedItem = apples.lock
    _, apples.uuid = uuidtopass(apples.uuid)
    userPassSelfSelector.selectedItem = apples.uuid + 1 --issue
    refreshInput()
    if apples.uuid == 0 or userTable.passSettings.type[apples.uuid] == "bool" then

    elseif userTable.passSettings.type[apples.uuid] == "-int" then
      userPassDataSelector.selectedItem = apples.data
    else
      userPassDataSelector.text = userTable.passSettings.type[apples.uuid] == "int" and tostring(apples.data) or apples.data
    end
  end

  canPerm = database.checkPerms("security",{"sector"},true)

  --GUI Setup
  window:addChild(GUI.panel(1,1,37,33,style.listPanel))
  sectorList = window:addChild(GUI.list(2, 2, 35, 31, 3, 0, style.listBackground, style.listText, style.listAltBack, style.listAltText, style.listSelectedBack, style.listSelectedText, false))
  sectorList:addItem("HELLO")
  listPageNumber = 0


  --Sector infos newSectorButton, delSectorButton
  window:addChild(GUI.label(40,12,1,1,style.passNameLabel,"Sector name: "))
  sectorNameInput = window:addChild(GUI.input(64,12,16,1, style.passInputBack,style.passInputText,style.passInputPlaceholder,style.passInputFocusBack,style.passInputFocusText, "", loc.inputname))
  sectorNameInput.onInputFinished = function()
    local selected = pageMult * listPageNumber + sectorList.selectedItem
    userTable.sectors[selected].name = sectorNameInput.text
    updateSecList()
    sectorListCallback()
  end
  sectorNameInput.disabled = canPerm

  newSectorButton = window:addChild(GUI.button(85,12,16,1, style.sectorButton,style.sectorText,style.sectorSelectButton,style.sectorSelectText, loc.addvar))
  newSectorButton.onTouch = createSector
  newSectorButton.disabled = canPerm
  delSectorButton = window:addChild(GUI.button(100,12,16,1, style.sectorButton,style.sectorText,style.sectorSelectButton,style.sectorSelectText, loc.delvar))
  delSectorButton.onTouch = deleteSector
  delSectorButton.disabled = canPerm

  window:addChild(GUI.panel(40,14,96,1,style.bottomDivider))
  window:addChild(GUI.panel(40,15,1,18,style.bottomDivider))

  window:addChild(GUI.panel(42,17,37,17,style.listPanel))
  sectorPassList = window:addChild(GUI.list(43, 18, 35, 15, 3, 0, style.listBackground, style.listText, style.listAltBack, style.listAltText, style.listSelectedBack, style.listSelectedText, false))

  window:addChild(GUI.label(85,18,1,1,style.passNameLabel,"Select Pass : "))
  userPassSelfSelector = window:addChild(GUI.comboBox(100,17,30,3, style.sectorComboBack,style.sectorComboText,style.sectorComboArrowBack,style.sectorComboArrowText))
  userPassSelfSelector:addItem("staff").onTouch = refreshInput
  for i=1,#userTable.passSettings.var,1 do
    userPassSelfSelector:addItem(userTable.passSettings.label[i]).onTouch = refreshInput
  end
  userPassSelfSelector.disabled = canPerm
  window:addChild(GUI.label(85,22,1,1,style.passNameLabel,"Change Input: "))
  userPassDataSelector = window:addChild(GUI.input(100,22,30,1, style.passInputBack,style.passInputText,style.passInputPlaceholder,style.passInputFocusBack,style.passInputFocusText, "", loc.inputtext))
  userPassDataSelector.disabled = true
  refreshInput()
  window:addChild(GUI.label(85,26,1,1,style.passNameLabel,"Bypass Type : "))
  userPassTypeSelector = window:addChild(GUI.comboBox(100,25,30,3, style.sectorComboBack,style.sectorComboText,style.sectorComboArrowBack,style.sectorComboArrowText))
  userPassTypeSelector.disabled = canPerm
  userPassTypeSelector:addItem(loc.sectoropen)
  userPassTypeSelector:addItem(loc.sectordislock)
  window:addChild(GUI.label(85,30,1,1,style.passNameLabel,"Priority    : "))
  userPassPrioritySelector = window:addChild(GUI.comboBox(100,29,30,3, style.sectorComboBack,style.sectorComboText,style.sectorComboArrowBack,style.sectorComboArrowText))
  userPassPrioritySelector.disabled = canPerm
  for i=1,5,1 do
    userPassPrioritySelector:addItem(tostring(i))
  end
  sectorPassNew = window:addChild(GUI.button(85,33,14,1, style.sectorButton,style.sectorText,style.sectorSelectButton,style.sectorSelectText, loc.addvar))
  sectorPassNew.onTouch = createSectorPass
  sectorPassNew.disabled = true
  sectorPassRemove = window:addChild(GUI.button(100,33,14,1, style.sectorButton,style.sectorText,style.sectorSelectButton,style.sectorSelectText, loc.delvar))
  sectorPassRemove.onTouch = deleteSectorPass
  sectorPassRemove.disabled = true
  sectorPassEdit = window:addChild(GUI.button(115,33,14,1, style.sectorButton,style.sectorText,style.sectorSelectButton,style.sectorSelectText, loc.editvar))
  sectorPassEdit.onTouch = editSectorPass
  sectorPassEdit.disabled = true
  --List Buttons Setup
  sectorListNum = window:addChild(GUI.label(2,33,3,3,style.listPageLabel,tostring(listPageNumber + 1)))
  sectorListUp = window:addChild(GUI.button(8,33,3,1, style.listPageButton, style.listPageText, style.listPageSelectButton, style.listPageSelectText, "+"))
  sectorListUp.onTouch, sectorListUp.isPos, sectorListUp.isListNum = pageCallback,true,1
  sectorListDown = window:addChild(GUI.button(12,33,3,1, style.listPageButton, style.listPageText, style.listPageSelectButton, style.listPageSelectText, "-"))
  sectorListDown.onTouch, sectorListDown.isPos, sectorListDown.isListNum = pageCallback,false,1

  sectorPassListNum = window:addChild(GUI.label(43,33,3,3,style.listPageLabel,tostring(listPageNumberPass + 1)))
  sectorPassListUp = window:addChild(GUI.button(51,33,3,1, style.listPageButton, style.listPageText, style.listPageSelectButton, style.listPageSelectText, "+"))
  sectorPassListUp.onTouch, sectorPassListUp.isPos, sectorPassListUp.isListNum = pageCallback,true,2
  sectorPassListDown = window:addChild(GUI.button(55,33,3,1, style.listPageButton, style.listPageText, style.listPageSelectButton, style.listPageSelectText, "-"))
  sectorPassListDown.onTouch, sectorPassListDown.isPos, sectorPassListDown.isListNum = pageCallback,false,2

  updateSecList()
end

module.close = function()
  return {["sectors"]={}}
end

return module