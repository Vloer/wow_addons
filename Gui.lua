local key = ""
local value = ""
local filtertype = "list"
local fillTable = function()
    local dungs = FilterFunc[filtertype](key, value)
    if not dungs then return end
    local data = PrepareData[filtertype](dungs)
    if filtertype == "rate" then
        stL:Hide()
        stR:Show()
        stR:SetData(data)
        stR:Refresh()
    else
        stR:Hide()
        stL:Show()
        stL:SetData(data)
        stL:Refresh()
    end
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
        stL:Show()
        stR:Hide()
    else
        disableWidgets(false, FilterWidgets)
        if item == "filter" then
            stL:Show()
            stR:Hide()
        elseif item == "rate" then
            stL:Hide()
            stR:Show()
        end
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
button:SetWidth(185)
button:SetCallback("OnClick", fillTable)
frame:AddChild(button)

_G["KeyCountFrame"] = frame.frame
tinsert(UISpecialFrames, "KeyCountFrame")

local window = frame.frame
local ScrollingTable = LibStub("ScrollingTable");
local columnsList = {
    { ["name"] = "Name",    ["width"] = 100 },
    { ["name"] = "Dungeon", ["width"] = 150, },
    { ["name"] = "Level",   ["width"] = 55, },
    { ["name"] = "Result",  ["width"] = 90, },
    { ["name"] = "Deaths",  ["width"] = 55,  ["defaultsort"] = "dsc" },
    { ["name"] = "Affixes", ["width"] = 200, },
}
local columnsRate = {
    { ["name"] = "Dungeon",      ["width"] = 150, },
    { ["name"] = "Success rate", ["width"] = 75, },
    { ["name"] = "In time",      ["width"] = 55,  color = ConvertRgb(Defaults.colors.rating[5]) },
    { ["name"] = "Out of time",  ["width"] = 75,  color = ConvertRgb(Defaults.colors.rating[3]) },
    { ["name"] = "Abandoned",    ["width"] = 60,  color = ConvertRgb(Defaults.colors.rating[1]) },
    { ["name"] = "Best",         ["width"] = 55, },
}

stL = ScrollingTable:CreateST(columnsList, 16, 16, nil, window);
stL.frame:SetPoint("TOP", window, "TOP", 0, -100);
stL.frame:SetPoint("LEFT", window, "LEFT", 15, 0);
stL:EnableSelection(true)

stR = ScrollingTable:CreateST(columnsRate, 8, 16, nil, window);
stR.frame:SetPoint("TOP", window, "TOP", 0, -100);
stR.frame:SetPoint("LEFT", window, "LEFT", 15, 0);
stR:EnableSelection(true)
stR:Hide()

frame:SetCallback("OnClose", function()
    stL:Hide()
    stR:Hide()
end)
