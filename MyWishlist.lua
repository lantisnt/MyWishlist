local name, MWL = ...

local Core = LibStub("AceAddon-3.0"):NewAddon(name, "AceEvent-3.0")

MWL.InternalSlots = {
    ["Head"] = "Head", ["Neck"] = "Neck", ["Shoulders"] = "Shoulders", ["Back"] = "Back", ["Chest"] = "Chest", ["Wrist"] = "Wrist", ["Hands"] = "Hands", ["Waist"] = "Waist", ["Legs"] = "Legs", ["Feet"] = "Feet", ["Finger"] = "Finger",
    ["Trinket"] = "Trinket", ["Weapon"] = "Weapon", ["OffHand"] = "Held In Off-Hand", ["Ranged"] = "Ranged", ["Ammo"] = "Ammo", ["Shirt"] = "Shirt", ["Tabard"] = "Tabard", ["Miscellaneous"] = "Miscellaneous"
}

MWL.InternalSlotsOrdered = {
    "Head", "Neck", "Shoulders", "Back", "Chest", "Wrist", "Hands", "Waist", "Legs", "Feet", "Finger",
    "Trinket", "Weapon", "OffHand", "Ranged", "Ammo", "Shirt", "Tabard", "Miscellaneous"
}



local defaults = {
    global = {
        version = {
            major = 0,
            minor = 0,
            patch = 0,
            changeset = "000000"
        },
        versionString = "v0.0.0-000000",
        lock = false
    },
    profile = {
        wishlists = {},
        minimap = {},
        gui = {
            height = 380
        }
    }
}
do
    local function UpdateDefaults()
        for slot,_ in pairs(MWL.InternalSlots) do
            defaults.profile.wishlists[slot] = {}
        end
    end

    UpdateDefaults()
end

function Core:OnInitialize()
-- do init tasks here, like loading the Saved Variables, 
-- or setting up slash commands.
    self.db = LibStub("AceDB-3.0"):New("MWL_DB", defaults, true)

    local newVersion = MWL.Utils.GetVersion("@project-version@")

    if MWL.Utils.CompareVersions(newVersion, self.db.global.version) then
        -- Handle version change code
    end

    self.db.global.version = newVersion
    self.db.global.versionString = MWL.Utils.GetVersionString(newVersion)

    MWL.ChatCommands:Register()
end

function Core:OnEnable()
-- Do more initialization here, that really enables the use of your addon.
-- Register Events, Hook functions, Create Frames, Get information from 
-- the game that wasn't available in OnInitialize
    MWL.Manager:Initialize()
    -- MWL.Settings:Initialize()
    MWL.GUI:Initialize()
    MWL.Minimap:Initialize()
end

function Core:GetVersion()
    return self.db.global.version
end

function Core:GetVersionString()
    return self.db.global.versionString
end

MWL.Core = Core

MyWishlist = MWL