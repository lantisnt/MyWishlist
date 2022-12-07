local _,  MWL = ...

local AceGUI = LibStub("AceGUI-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local strsub20 = MWL.Utils.strsub20

local REGISTRY = "mywishlist_gui_registry"

local _, _, _, isElvUI = GetAddOnInfo("ElvUI")

local BASE_WIDTH_LOCKED    = 285 + (isElvUI and 10 or 0)
local BASE_WIDTH_UNLOCKED  = 535 + (isElvUI and 10 or 0)

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

        options.args[rowPrefix .. "icon"  ], order = BuildWishlist_EntryIcon(order, icon, link)
        options.args[rowPrefix .. "link"  ], order = BuildWishlist_EntryLink(order, link)
        if MWL.Manager:IsLocked() then
            options.args[rowPrefix .. "pad"   ], order = BuildWishlist_EntryPad(order)
            options.args[rowPrefix .. "note"  ], order = BuildWishlist_EntryNoteReadOnly(order, entry)
        else
            options.args[rowPrefix .. "note"  ], order = BuildWishlist_EntryNote(order, entry)
            options.args[rowPrefix .. "up"    ], order = BuildWishlist_Up(order, MWL.Core.db.profile.selectedGuiSlot, seqId, total)
            options.args[rowPrefix .. "down"  ], order = BuildWishlist_Down(order, MWL.Core.db.profile.selectedGuiSlot, seqId, total)
            options.args[rowPrefix .. "delete"], order = BuildWishlist_Delete(order, MWL.Core.db.profile.selectedGuiSlot, seqId, total)
        end
        lineNum = lineNum + 1
    end
    return order + 1
end

local function UpdateOptions(self)
    options.args = {}
    local itemId, _, _, _, itemIcon, _, _ = GetItemInfoInstant(self.itemToAdd or 0)
    local icon = itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
    local link = itemId and ("item:"..tostring(itemId)) or "item:0"

    local padding_width = 1.75
    if MWL.Manager:IsLocked() then
        padding_width = 0.25
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
            width = 0.5,
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
    OptionsGroup:SetWidth(535)
    self.OptionsGroup = OptionsGroup
    UpdateOptions(self)
    AceConfigRegistry:RegisterOptionsTable(REGISTRY, options)
    AceConfigDialog:Open(REGISTRY, OptionsGroup)

    return OptionsGroup
end

local function UpdateSize(self)
    if MWL.Manager:IsLocked() then
        self.window:SetWidth(BASE_WIDTH_LOCKED)
        self.OptionsGroup:SetWidth(BASE_WIDTH_LOCKED)
    else
        self.window:SetWidth(BASE_WIDTH_UNLOCKED)
        self.OptionsGroup:SetWidth(BASE_WIDTH_UNLOCKED)
    end
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
    UpdateSize(self)
end

function GUI:Refresh()
    UpdateOptions(self)
    AceConfigRegistry:RegisterOptionsTable(REGISTRY, options)
    UpdateSize(self)
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
    if self.window.frame:IsVisble() then
        self.window:Hide()
    else
        self.window:Show()
    end
end


MWL.GUI = GUI