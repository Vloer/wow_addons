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

local window = frame.frame
local columns = {
   { ["name"] = "Name", ["width"] = 113 }, 
   { ["name"] = "Dungeon", ["width"] = 113, }, 
   { ["name"] = "Level", ["width"] = 55,   },
   { ["name"] = "Result", ["width"] = 55,  }, 
   { ["name"] = "Deaths", ["width"] = 55,  },
};
local row =
{
   ["cols"] = {
      {
         ["value"] = "Bafke",
      }, -- [1] Column 1
      {
         ["value"] = "Ruby Life Pools",
         ["color"] = {
            ["r"] = 1.0,
            ["g"] = 1.0,
            ["b"] = 1.0,
            ["a"] = 1.0,
         },  -- Cell color
      }, -- [2] Column 2
      {
         ["value"] = 15,
         ["color"] = {
            ["r"] = 1.0,
            ["g"] = 0.0,
            ["b"] = 1.0,
            ["a"] = 1.0,
         },  -- Cell color
      }, -- [2] Column 2
      {
         ["value"] = "Timed",
         
      }, -- [2] Column 2
      {
         ["value"] = 15,
         
      }, 
   },
   ["color"] = {
      ["r"] = 1.0,
      ["g"] = 1.0,
      ["b"] = 1.0,
      ["a"] = 1.0,
   },
}
local data = {
   row
}
local ScrollingTable = LibStub("ScrollingTable");
st = ScrollingTable:CreateST(columns, 12, 16, nil, window);
st.frame:SetPoint("TOP", window, "CENTER", 0, 46);
st.frame:SetPoint("LEFT", window, "LEFT", 15, 0);
st:EnableSelection(true)
st:SetData(data)
st:Refresh()
frame:SetCallback("OnClose", function() st:Hide() end)