local key = ""
local value = ""
local filtertype = "list"
local executeFilter = function()
   FilterFunc[filtertype](key, value) 
end

AceGUI = LibStub("AceGUI-3.0")
local frame = AceGUI:Create("Frame")
frame:SetTitle("KeyCount")
frame:SetStatusText("Retrieve some data on your mythic+ runs!")
frame:SetWidth(750)
frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
frame:SetLayout("Flow")


local dropdownBox = AceGUI:Create("Dropdown")
dropdownBox:SetLabel("Filter type")
dropdownBox:SetWidth(100)
dropdownBox:AddItem("list","List")
dropdownBox:AddItem("filter","Filter")
dropdownBox:AddItem("rate","Success rate")
dropdownBox:SetCallback("OnValueChanged", function(widget, event, item) filtertype=item end)
dropdownBox:SetValue("list")
frame:AddChild(dropdownBox)

local editbox = AceGUI:Create("EditBox")
editbox:SetLabel("Filter key")
editbox:SetWidth(200)
editbox:SetCallback("OnEnterPressed", function(widget, event, text) key = text end)
frame:AddChild(editbox)

local editbox = AceGUI:Create("EditBox")
editbox:SetLabel("Filter value")
editbox:SetWidth(200)
editbox:SetCallback("OnEnterPressed", function(widget, event, text) value = text end)
frame:AddChild(editbox)

local button = AceGUI:Create("Button")
button:SetText("Show data")
button:SetWidth(200)
button:SetCallback("OnClick", executeFilter)
frame:AddChild(button)

_G["KeyCountFrame"] = frame.frame
tinsert(UISpecialFrames, "KeyCountFrame")

local function getLevelColor(level)
   local idx = math.floor(level / 5) + 1
   local r, g, b, hex = GetItemQualityColor(idx)
   local color = { r = r, g = g, b = b, a = 1 }
   return { color = color, hex = hex }
end

local function getResultString(dungeon)
   if dungeon.completedInTime then
      return { result = "Timed", color = ConvertRgb(Defaults.colors.rating[5]) }
   elseif dungeon.completed then
      return { result = "Failed to time", color = ConvertRgb(Defaults.colors.rating[3]) }
   else
      return { result = "Abandoned", color = ConvertRgb(Defaults.colors.rating[1]) }
   end
end

local function getDeathsColor(deaths)
   if deaths == 0 then return ConvertRgb(Defaults.colors.rating[5]) end
   local idx = math.floor(6 - deaths / 4)
   if idx == 0 then idx = 1 end
   return ConvertRgb(Defaults.colors.rating[idx])
end

local function prepareRow(dungeon)
   local row = {}
   local player = dungeon.player
   local name = dungeon.name
   local level = dungeon.keyDetails.level
   local result = getResultString(dungeon)
   local deaths = dungeon.totalDeaths or 0
   table.insert(row, { value = player })
   table.insert(row, { value = name })
   table.insert(row, { value = level, color = getLevelColor(level).color })
   table.insert(row, { value = result.result, color = result.color })
   table.insert(row, { value = deaths, color = getDeathsColor(deaths) })
   return { cols = row }
end

local function prepareList()
   local data = {}
   local _dungeons = GetStoredDungeons()
   if _dungeons then
      local dl = OrderListByPlayer(_dungeons)
      for _, dungeons in pairs(dl) do
         for _, dungeon in ipairs(dungeons) do
            local row = prepareRow(dungeon)
            table.insert(data, row)
         end
      end
   end
   return data
end


local window = frame.frame
local columns = {
   { ["name"] = "Name", ["width"] = 100 }, 
   { ["name"] = "Dungeon", ["width"] = 150, }, 
   { ["name"] = "Level", ["width"] = 55,   },
   { ["name"] = "Result", ["width"] = 113,  }, 
   { ["name"] = "Deaths", ["width"] = 55, ["defaultsort"]="dsc" },
};
local data = prepareList()
local ScrollingTable = LibStub("ScrollingTable");
st = ScrollingTable:CreateST(columns, 12, 16, nil, window);
st.frame:SetPoint("TOP", window, "CENTER", 0, 46);
st.frame:SetPoint("LEFT", window, "LEFT", 15, 0);
st:EnableSelection(true)
st:SetData(data)
st:Refresh()
frame:SetCallback("OnClose", function() st:Hide() end)


