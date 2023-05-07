local key = ""
local value = ""
local filtertype = "list"
local fillTable = function()
    local dungs = FilterFunc[filtertype](key, value)
    if not dungs then return end
    local data = PrepareData.list(dungs)
    st:SetData(data)
    st:Refresh()
end

local function disableWidgets(setting, widgets)
    for _, w in ipairs(widgets) do
        w:SetDisabled(setting)
    end
end

AceGUI = LibStub("AceGUI-3.0")
local frame = AceGUI:Create("Frame")
frame:SetTitle("KeyCount")
frame:SetStatusText("Retrieve some data for your mythic+ runs!")
frame:SetWidth(750)
frame:SetHeight(420)
frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
frame:SetLayout("Flow")


local dropdownBox = AceGUI:Create("Dropdown")
dropdownBox:SetLabel("Filter type")
dropdownBox:SetWidth(100)
dropdownBox:AddItem("list", "All data")
dropdownBox:AddItem("filter", "Filter")
dropdownBox:AddItem("rate", "Success rate")
dropdownBox:SetCallback("OnValueChanged", function(widget, event, item)
    filtertype = item
    if item == "list" then
        disableWidgets(true, FilterWidgets)
    else
        disableWidgets(false, FilterWidgets)
    end
end)
dropdownBox:SetValue("list")
frame:AddChild(dropdownBox)

local editboxKey = AceGUI:Create("EditBox")
editboxKey:SetLabel("Filter key")
editboxKey:SetWidth(200)
editboxKey:SetCallback("OnEnterPressed", function(widget, event, text) key = text end)
editboxKey:SetDisabled(true)
frame:AddChild(editboxKey)

local editboxVal = AceGUI:Create("EditBox")
editboxVal:SetLabel("Filter value")
editboxVal:SetWidth(200)
editboxVal:SetCallback("OnEnterPressed", function(widget, event, text) value = text end)
editboxVal:SetDisabled(true)
frame:AddChild(editboxVal)

FilterWidgets = { editboxKey, editboxVal }

local button = AceGUI:Create("Button")
button:SetText("Show data")
button:SetWidth(200)
button:SetCallback("OnClick", fillTable)
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

local ScrollingTable = LibStub("ScrollingTable");
st = ScrollingTable:CreateST(columns, 16, 16, nil, window);
st.frame:SetPoint("TOP", window, "TOP", 0, -100);
st.frame:SetPoint("LEFT", window, "LEFT", 15, 0);
st:EnableSelection(true)
frame:SetCallback("OnClose", function() st:Hide() end)
