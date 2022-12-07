local _,  MWL = ...

local AceGUI = LibStub("AceGUI-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local strsub20 = MWL.Utils.strsub20

local REGISTRY = "mywishlist_gui_registry"
local WISHLIST_REGISTRY = "mywishlist_gui_wishlist_registry"

local _, _, _, isElvUI = GetAddOnInfo("ElvUI")

local BASE_WIDTH_LOCKED    = 285 + (isElvUI and 10 or 0)
local BASE_WIDTH_UNLOCKED  = 535 + (isElvUI and 10 or 0)

local BASE_HEIGHT = 380

local GUI = {}

local options = {
    type = "group",
    args = {}
}
local wishlistOptions = {
    type = "group",
    args = {}
}

local function BuildWishlist_EntryIcon(order, icon, link)
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

local function BuildWishlist_EntryLink(order, link)
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
    if MWL.Manager:IsLocked() then return end
    entry:SetNote(note)
end

local function BuildWishlist_EntryNote(order, entry)
    return {
        name = "",
        type = "input",
        get = (function(i) return GetEntryNote(entry) end),
        set = (function(i, v) SetEntryNote(entry, v) end),
        order = order,
        width = 1
    }, order + 1
end

local function BuildWishlist_Up(order, slot, seqId, total)
    return {
        name = "",
        type = "execute",
        width = 0.15,
        image = "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up",
        hidden = (function() return (seqId > total) end),
        disabled = (function() return seqId == 1 end),
        func = function()
            MWL.Manager:MoveWishlistItemUp(slot, seqId)
            GUI:Refresh()
        end,
        order = order
    }, order + 1
end

local function BuildWishlist_Down(order, slot, seqId, total)
    return {
        name = "",
        type = "execute",
        hidden = (function() return (seqId > total) end),
        width = 0.15,
        image = "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up",
        disabled = (function() return seqId == total end),
        func = function()
            MWL.Manager:MoveWishlistItemDown(slot, seqId)
            GUI:Refresh()
        end,
        order = order
    }, order + 1
end

local function BuildWishlist_Delete(order, slot, seqId, total)
    return {
        name = "",
        type = "execute",
        hidden = (function() return (seqId > total) end),
        width = 0.15,
        image = "Interface\\Buttons\\UI-Panel-MinimizeButton-Up",
        func = function()
            MWL.Manager:RemoveWishlistItem(slot, seqId)
            GUI:Refresh()
        end,
        confirm = (function() return "Are you sure you want to remove item from wishlist?" end),
        order = order
    }, order + 1
end

local function BuildWishlist_EntryNoteReadOnly(order, entry)
    return {
        type = "description",
        name = (function(i) return MWL.Utils.ColorCodeText(GetEntryNote(entry),"44ee44") end),
        fontSize = "medium",
        order = order,
        width = 1.25
    }, order + 1
end

local function BuildWishlist_EntryPad(order)
    return {
        name = "",
        type = "description",
        width = 0.25,
        order = order
    }, order + 1
end


local lineNum = 0
local function BuildWishlistLine(order, entry, seqId, total)
    local itemId, _, _, _, icon, _, _ = GetItemInfoInstant(entry:GetItemID())
    if itemId then
        local link = entry:GetItemLink()
        local rowPrefix = "wlit" .. tostring(itemId) .. "ln" .. tostring(lineNum)

        wishlistOptions.args[rowPrefix .. "icon"  ], order = BuildWishlist_EntryIcon(order, icon, link)
        wishlistOptions.args[rowPrefix .. "link"  ], order = BuildWishlist_EntryLink(order, link)
        if MWL.Manager:IsLocked() then
            wishlistOptions.args[rowPrefix .. "pad"   ], order = BuildWishlist_EntryPad(order)
            wishlistOptions.args[rowPrefix .. "note"  ], order = BuildWishlist_EntryNoteReadOnly(order, entry)
        else
            wishlistOptions.args[rowPrefix .. "note"  ], order = BuildWishlist_EntryNote(order, entry)
            wishlistOptions.args[rowPrefix .. "up"    ], order = BuildWishlist_Up(order, MWL.Core.db.profile.selectedGuiSlot, seqId, total)
            wishlistOptions.args[rowPrefix .. "down"  ], order = BuildWishlist_Down(order, MWL.Core.db.profile.selectedGuiSlot, seqId, total)
            wishlistOptions.args[rowPrefix .. "delete"], order = BuildWishlist_Delete(order, MWL.Core.db.profile.selectedGuiSlot, seqId, total)
        end
        lineNum = lineNum + 1
    end
    return order + 1
end

local function UpdateOptions(self)
    options.args = {}
    wishlistOptions.args = {}
    local itemId, _, _, _, itemIcon, _, _ = GetItemInfoInstant(self.itemToAdd or 0)
    local icon = itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
    local link = itemId and ("item:"..tostring(itemId)) or "item:0"

    local padding_width = 1.85
    if MWL.Manager:IsLocked() then
        padding_width = 0.35
    end

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
        wishlist_lock = {
            -- name = (function(i) return MWL.Manager:IsLocked() and "Unlock" or "Lock" end),
            name = "",
            image = (function(i)
                if MWL.Manager:IsLocked() then
                    return "interface/addons/mywishlist/media/locked_3"
                else
                    return "interface/addons/mywishlist/media/unlocked_3"
                end
            end),
            type = "execute",
            func = (function(i)
                if MWL.Manager:IsLocked() then
                    MWL.Manager:Unlock()
                else
                    MWL.Manager:Lock()
                end
                self:Refresh()
            end),
            width = 0.25,
            order = 3
        },
        wishlist_padding_1 = {
            name = "",
            desc = "",
            type = "description",
            -- width = 1.75,
            width = padding_width,
            order = 2
        },
        add_header = {
            type = "header",
            name = "Add Item",
            width = "full",
            hidden = (function(i) return MWL.Manager:IsLocked() end),
            order = 4
        },
        wishlist_input_item_icon = {
            name = "",
            image = icon,
            type = "execute",
            func = (function() end),
            hidden = (function(i) return MWL.Manager:IsLocked() end),
            order = 5,
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
            hidden = (function(i) return MWL.Manager:IsLocked() end),
            width = 1.25,
            order = 6
        },
        wishlist_input_note = {
            name = "",
            type = "input",
            get = (function(i) return self.note or "" end),
            set = (function(i, v) self.note = strsub20(tostring(v) or "") end),
            hidden = (function(i) return MWL.Manager:IsLocked() end),
            order = 7,
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
            hidden = (function(i) return MWL.Manager:IsLocked() end),
            width = 0.6,
            order = 8
        },
        wishlist_header = {
            type = "header",
            name = "Wishlist",
            width = "full",
            order = 9
        },
    }
    local order = 50
    local wishlist = MWL.Manager:GetWishlist(MWL.Core.db.profile.selectedGuiSlot)
    for seqId, entry in ipairs(wishlist) do
        order = BuildWishlistLine(order, entry, seqId, #wishlist)
    end
end

local function CreateOptions(self)
    local OptionsGroup = AceGUI:Create("SimpleGroup")
    OptionsGroup:SetLayout("Flow")
    -- OptionsGroup:SetWidth(535)
    

    local WishlistOptionsScrollGroup = AceGUI:Create("ScrollFrame")
    -- OptionsGroup:SetWidth(535)
    -- WishlistOptionsScrollGroup:SetHeight(BASE_HEIGHT - 250)

    local WishlistOptionsGroup = AceGUI:Create("SimpleGroup")
    WishlistOptionsGroup:SetLayout("Flow")

    WishlistOptionsScrollGroup:AddChild(WishlistOptionsGroup)

    UpdateOptions(self)
    AceConfigRegistry:RegisterOptionsTable(REGISTRY, options)
    AceConfigDialog:Open(REGISTRY, OptionsGroup)

    AceConfigRegistry:RegisterOptionsTable(WISHLIST_REGISTRY, wishlistOptions)
    AceConfigDialog:Open(WISHLIST_REGISTRY, WishlistOptionsGroup)

    self.OptionsGroup = OptionsGroup
    self.WishlistOptionsGroup = WishlistOptionsGroup
    self.WishlistOptionsScrollGroup = WishlistOptionsScrollGroup

    return OptionsGroup, WishlistOptionsScrollGroup
end

local function UpdateSize(self)
    if MWL.Manager:IsLocked() then
        self.window:SetWidth(BASE_WIDTH_LOCKED + 17)
        self.OptionsGroup:SetWidth(BASE_WIDTH_LOCKED + 17)
        self.WishlistOptionsGroup:SetWidth(BASE_WIDTH_LOCKED)
        self.WishlistOptionsScrollGroup:SetWidth(BASE_WIDTH_LOCKED + 17)
        -- self.WishlistOptionsScrollGroup:SetHeight(BASE_HEIGHT - 125)
        self.WishlistOptionsScrollGroup:SetHeight(self.window.content.height + 57 - 125 - 15)
    else
        self.window:SetWidth(BASE_WIDTH_UNLOCKED + 17)
        self.OptionsGroup:SetWidth(BASE_WIDTH_UNLOCKED + 17)
        self.WishlistOptionsGroup:SetWidth(BASE_WIDTH_UNLOCKED)
        self.WishlistOptionsScrollGroup:SetWidth(BASE_WIDTH_UNLOCKED + 17)

        -- self.WishlistOptionsScrollGroup:SetHeight(BASE_HEIGHT - 190)
        self.WishlistOptionsScrollGroup:SetHeight(self.window.content.height + 57 - 190 - 15)
    end
    self.OptionsGroup:DoLayout()
    self.WishlistOptionsGroup:DoLayout()
    self.WishlistOptionsScrollGroup:DoLayout()
end

local function CreateWindow(self)
    local f = AceGUI:Create("Window")

    f:SetTitle("My Wishlist")
    f:SetStatusText("")
    f:SetLayout("flow")
    f:SetHeight(BASE_HEIGHT)
    -- f:EnableResize(false)
    local originalOnHeightSet = f.OnHeightSet
    f.OnHeightSet = function (...)
        originalOnHeightSet(...)
        UpdateSize(self)
    end
    local op, sc = CreateOptions(self)
    f:AddChild(op)
    f:AddChild(sc)
    self.window = f
end

function GUI:Initialize()
    CreateWindow(self)
    UpdateSize(self)
end

function GUI:Refresh()
    UpdateOptions(self)
    AceConfigRegistry:RegisterOptionsTable(REGISTRY, options)
    AceConfigDialog:Open(REGISTRY, self.OptionsGroup)
    AceConfigRegistry:RegisterOptionsTable(WISHLIST_REGISTRY, wishlistOptions)
    AceConfigDialog:Open(WISHLIST_REGISTRY, self.WishlistOptionsGroup)
    UpdateSize(self)
end

function GUI:Show()
    self:Refresh()
    self.window:Show()
end

function GUI:Hide()
    self.window:Hide()
end

function GUI:Toggle()
    if self.window:IsVisible() then
        self.window:Hide()
    else
        self.window:Show()
    end
end


MWL.GUI = GUI