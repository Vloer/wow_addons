Data = {}
local key = ""
local value = ""
local filtertype = "list"
local executeFilter = function()
    FilterFunc.print[filtertype](key, value)
end
local fillTable = function()
    Data = FilterFunc[filtertype](key, value)
    st:Refresh()
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
dropdownBox:AddItem("list", "List")
dropdownBox:AddItem("filter", "Filter")
dropdownBox:AddItem("rate", "Success rate")
dropdownBox:SetCallback("OnValueChanged", function(widget, event, item) filtertype = item end)
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
--button:SetCallback("OnClick", fillTable)
frame:AddChild(button)

_G["KeyCountFrame"] = frame.frame
tinsert(UISpecialFrames, "KeyCountFrame")

local window = frame.frame
local columns = {
    { ["name"] = "Name",    ["width"] = 100 },
    { ["name"] = "Dungeon", ["width"] = 150, },
    { ["name"] = "Level",   ["width"] = 55, },
    { ["name"] = "Result",  ["width"] = 113, },
    { ["name"] = "Deaths",  ["width"] = 55,  ["defaultsort"] = "dsc" },
    { ["name"] = "Affixes", ["width"] = 200, },
};
local data = PrepareData.list(GetStoredDungeons())
local ScrollingTable = LibStub("ScrollingTable");
st = ScrollingTable:CreateST(columns, 12, 16, nil, window);
st.frame:SetPoint("TOP", window, "CENTER", 0, 46);
st.frame:SetPoint("LEFT", window, "LEFT", 15, 0);
st:EnableSelection(true)
st:SetData(data)
st:Refresh()
frame:SetCallback("OnClose", function() st:Hide() end)
