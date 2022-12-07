local _,  MWL = ...

local AceGUI = LibStub("AceGUI-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local strsub30 = MWL.Utils.strsub30

local REGISTRY = "mywishlist_gui_registry"

local GUI = {}

local options = {
    type = "group",
    args = {}
}

local function BuildWishlist_EntryIcon(icon, link, order)
    return {
        name = "",
        image = icon,
        type = "execute",
        func = (function() end),
        order = order,
        tooltipHyperlink = link,
        width = 0.25
    }, order + 1
end

local function BuildWishlist_EntryLink(link, order)
    return {
        name = link,
        type = "description",
        order = order,
        width = 1.25
    }, order + 1
end

local function GetEntryNote(entry)
    return entry:GetNote()
end

local function SetEntryNote(entry, note)
    entry:SetNote(note)
end

local function BuildWishlist_EntryNote(entry, order)
    return {
        name = "",
        type = "input",
        get = (function(i) return GetEntryNote(entry) end),
        set = (function(i, v) SetEntryNote(entry, v) end),
        order = order,
        width = 1
    }, order + 1
end

local function BuildWishlist_Up(order)
    return {
        name = "",
        type = "execute",
        -- hidden = (function() return (conditionId > #db) end),
        width = 0.15,
        image = "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up",
        -- disabled = (function() return conditionId == 1 end),
        func = function()
            -- tremove(db, conditionId)
            -- tinsert(db, conditionId - 1, condition)
            -- self:InitializeConfigs()
        end,
        order = order
    }, order + 1
end

local function BuildWishlist_Down(order)
    return {
        name = "",
        type = "execute",
        -- hidden = (function() return (conditionId > #db) end),
        width = 0.15,
        image = "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up",
        -- disabled = (function() return conditionId == #db end),
        func = function()
            -- tremove(db, conditionId)
            -- tinsert(db, conditionId+1, condition)
            -- self:InitializeConfigs()
        end,
        order = order
    }, order + 1
end

local function BuildWishlist_Delete(order)
    return {
        name = "",
        type = "execute",
        -- hidden = (function() return (conditionId > #db) end),
        width = 0.15,
        image = "Interface\\Buttons\\UI-Panel-MinimizeButton-Up",
        func = function()
            -- tremove(db, conditionId)
            -- self:InitializeConfigs()
        end,
        order = order
    }, order + 1
end

local function BuildWishlistLine(entry, seqId, order)
    local itemId, _, _, _, icon, _, _ = GetItemInfoInstant(entry:GetItemID())
    if itemId then
        local link = entry:GetItemLink()
        local rowPrefix = "wlitem" .. tostring(itemId)
        options.args[rowPrefix .. "icon"  ], order = BuildWishlist_EntryIcon(icon, link, order)
        options.args[rowPrefix .. "link"  ], order = BuildWishlist_EntryLink(link, order)
        options.args[rowPrefix .. "note"  ], order = BuildWishlist_EntryNote(entry, order)
        options.args[rowPrefix .. "up"    ], order = BuildWishlist_Up(order)
        options.args[rowPrefix .. "down"  ], order = BuildWishlist_Down(order)
        options.args[rowPrefix .. "delete"], order = BuildWishlist_Delete(order)
    end
    return order + 1
end

local function UpdateOptions(self)
    local itemId, _, _, _, itemIcon, _, _ = GetItemInfoInstant(self.itemToAdd or 0)
    local icon = itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
    local link = itemId and ("item:"..tostring(itemId)) or "item:0"

    options.args = {
        wishlist_slot_select = {
            name = "Slot",
            desc = "Select wishlist slot",
            type = "select",
            values = MWL.InternalSlots,
            sorting = MWL.InternalSlotsOrdered,
            set = function(i, v) MWL.Core.db.profile.selectedGuiSlot = v; self:Refresh() end,
            get = function(i) return MWL.Core.db.profile.selectedGuiSlot end,
            width = 1,
            order = 1
        },
        wishlist_padding_1 = {
            name = "",
            desc = "",
            type = "description",
            width = 2,
            order = 2
        },
        wishlist_input_item_icon = {
            name = "",
            image = icon,
            type = "execute",
            func = (function() end),
            order = 3,
            tooltipHyperlink = link,
            width = 0.25
        },
        wishlist_input_item = {
            name = "",
            desc = "Input item link or item id to add to the wishlist. Item will be added to appropriate slot wishlist.",
            type = "input",
            set = (function(i, v)
                if tonumber(v) then
                    v = "item:" .. tostring(v)
                end
                local itemId = MWL.Utils.GetItemIdFromLink(v)
                if itemId and GetItemInfoInstant(itemId) then
                    local item = Item:CreateFromItemID(itemId)
                    if item:IsItemDataCached() then
                        self.itemToAdd = item:GetItemLink()
                        self:Refresh()
                    else
                        item:ContinueOnItemLoad(function()
                            self.itemToAdd = item:GetItemLink()
                            self:Refresh()
                        end)
                        -- self:Refresh()
                        self.itemToAdd = "item:" .. tostring(itemId)
                    end
                end
            end),
            get = (function(i) return self.itemToAdd end),
            width = 1.25,
            order = 4
        },
        wishlist_input_note = {
            name = "",
            type = "input",
            get = (function(i) return self.note or "" end),
            set = (function(i, v) self.note = strsub30(tostring(v) or "") end),
            order = 5,
            width = 1
        },
        wishlist_add_item = {
            name = "Add",
            type = "execute",
            func = (function(i, v)
                MWL.Manager:AddItemByLink(self.itemToAdd, self.note)
                self.itemToAdd = ""
                self.note = ""
                self:Refresh()
            end),
            width = 0.5,
            order = 6
        },
        wishlist_header = {
            type = "header",
            name = "Wishlist",
            width = "full",
            order = 7
        },
    }
    local order = 8
    for seqId, entry in ipairs(MWL.Manager:GetWishlist(MWL.Core.db.profile.selectedGuiSlot)) do
        order = BuildWishlistLine(entry, seqId, order)
    end
end

local function CreateOptions(self)
    local OptionsGroup = AceGUI:Create("SimpleGroup")
    OptionsGroup:SetLayout("Flow")
    OptionsGroup:SetWidth(535)
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
    f:SetWidth(535)
    f:EnableResize(false)
    f:AddChild(CreateOptions(self))
    
    self.window = f
end

function GUI:Initialize()
    CreateWindow(self)
end

function GUI:Refresh()
    UpdateOptions(self)
    AceConfigRegistry:RegisterOptionsTable(REGISTRY, options)
    AceConfigDialog:Open(REGISTRY, self.OptionsGroup)
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