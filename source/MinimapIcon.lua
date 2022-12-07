local _, MWL = ...

local addonName = "My Wishlist" -- same as the UI name for config

local ldb = LibStub:GetLibrary("LibDataBroker-1.1", true)
if not ldb then return end

local icon = LibStub("LibDBIcon-1.0", true)
if not icon then return end

local function getIcon()
    local iconPath = "interface/addons/mywishlist/media/unlocked_3"
    if MWL.Manager:IsLocked() then
        iconPath = "interface/addons/mywishlist/media/locked_3"
    end
    return iconPath
end

local function CreateMinimapDBI(self, dropdown)
    MWL.MinimapDBI = ldb:NewDataObject(addonName, {
        type = "data source",
        text = "0",
        icon = getIcon()
    })

    MWL.MinimapDBI.OnClick = function(s, button)
        if button == "RightButton" then
            MWL.Manager:ToggleLock()
            MWL.GUI:Refresh()
            icon.objects[addonName]:GetScript("OnLeave")(icon.objects[addonName])
            icon.objects[addonName]:GetScript("OnEnter")(icon.objects[addonName])
        else
            MWL.GUI:Toggle()
        end
    end

    MWL.MinimapDBI.OnTooltipShow = function(tooltip)
        tooltip:AddDoubleLine(addonName, MWL.Core:GetVersionString())

        if MWL.Manager:IsLocked() then
            tooltip:AddDoubleLine(" ", MWL.Utils.ColorCodeText("Locked", "ee4444"))
        else
            tooltip:AddDoubleLine(" ", MWL.Utils.ColorCodeText("Unlocked", "44ee44"))
        end

        tooltip:AddDoubleLine("Left Click",            MWL.Utils.ColorCodeText("Toggle window", "bbbbbb"))
        tooltip:AddDoubleLine("Right Click",           MWL.Utils.ColorCodeText("Toggle lock", "bbbbbb"))
        tooltip:AddDoubleLine("Shift + Left Click",    MWL.Utils.ColorCodeText("Toggle options", "bbbbbb"))
    end

    icon:Register(addonName, MWL.MinimapDBI, MWL.Core.db.profile.minimap)
end

local dropdown
local Minimap = {}

function Minimap:Initialize()
    -- Create Minimap Icon
    CreateMinimapDBI(self, dropdown)

    -- Hook Minimap Icon
    hooksecurefunc(MWL.Manager, "Lock", function()
        MWL.MinimapDBI.icon = getIcon()
    end)

    hooksecurefunc(MWL.Manager, "Unlock", function()
        MWL.MinimapDBI.icon = getIcon()
    end)

    hooksecurefunc(MWL.Manager, "ToggleLock", function()
        MWL.MinimapDBI.icon = getIcon()
    end)

    -- if CLM2_MinimapIcon.disable then icon:Hide(addonName) end

end


function Minimap:Enable()
    -- CLM2_MinimapIcon.disable = false
    icon:Show(addonName)
end

function Minimap:Disable()
    -- CLM2_MinimapIcon.disable = true
    icon:Hide(addonName)
end

function Minimap:IsEnabled()
    -- return not CLM2_MinimapIcon.disable
end

MWL.Minimap = Minimap