AceGUI = LibStub("AceGUI-3.0")
local key = ""
local value = ""
local filtertype = "list"

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
button:SetText("Execute")
button:SetWidth(200)
button:SetCallback("OnClick", function()
    FilterFunc[filtertype](key, value)
end)
frame:AddChild(button)
