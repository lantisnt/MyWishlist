local _,  MWL = ...

local AceGUI = LibStub("AceGUI-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local REGISTRY = "mywishlist_gui_registry"

local GUI = {}

local options = {

}

local function UpdateOptions(self)

end

local function CreateOptions(self)
    local OptionsGroup = AceGUI:Create("SimpleGroup")
    OptionsGroup:SetLayout("Flow")
    self.OptionsGroup = OptionsGroup
    UpdateOptions(self)
    AceConfigRegistry:RegisterOptionsTable(REGISTRY, options)
    AceConfigDialog:Open(REGISTRY, OptionsGroup)

    return OptionsGroup
end

local function CreateWindow(self)
    local f = AceGUI:Create("Window")

    f:SetTitle("My Wishlist")
    f:SetStatusText("")
    f:SetLayout("flow")

    f:AddChild(CreateOptions(self))
    
    self.window = f
end

function GUI:Initialize()
    CreateWindow(self)
end

function GUI:Refresh()

end

function GUI:Show()
    self:Refresh()
    self.window:Show()
end

function GUI:Hide()
    self.window:Hide()
end

function GUI:Toggle()
    if self.window:IsVisble() then
        self.window:Hide()
    else
        self.window:Show()
    end
end


MWL.GUI = GUI