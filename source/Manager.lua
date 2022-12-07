local _,  MWL = ...

local pairs, ipairs, type = pairs, ipairs, type
local Item, GetItemInfoInstant = Item, GetItemInfoInstant
local tinsert = table.insert

local Manager = {}

local INVTYPE_to_MWL_slot_map = {
    ["INVTYPE_HEAD"]            = MWL.InternalSlots.Head,
    ["INVTYPE_NECK"]            = MWL.InternalSlots.Neck,
    ["INVTYPE_SHOULDER"]        = MWL.InternalSlots.Shoulders,
    ["INVTYPE_BODY"]            = MWL.InternalSlots.Chest,
    ["INVTYPE_CHEST"]           = MWL.InternalSlots.Chest,
    ["INVTYPE_WAIST"]           = MWL.InternalSlots.Waist,
    ["INVTYPE_LEGS"]            = MWL.InternalSlots.Legs,
    ["INVTYPE_FEET"]            = MWL.InternalSlots.Feet,
    ["INVTYPE_WRIST"]           = MWL.InternalSlots.Wrist,
    ["INVTYPE_HAND"]            = MWL.InternalSlots.Hand,
    ["INVTYPE_FINGER"]          = MWL.InternalSlots.Finger,
    ["INVTYPE_TRINKET"]         = MWL.InternalSlots.Trinket,
    ["INVTYPE_WEAPON"]          = MWL.InternalSlots.Weapon,
    ["INVTYPE_SHIELD"]          = MWL.InternalSlots.OffHand,
    ["INVTYPE_RANGED"]          = MWL.InternalSlots.Ranged,
    ["INVTYPE_CLOAK"]           = MWL.InternalSlots.Back,
    ["INVTYPE_2HWEAPON"]        = MWL.InternalSlots.Weapon,
    ["INVTYPE_TABARD"]          = MWL.InternalSlots.Tabard,
    ["INVTYPE_ROBE"]            = MWL.InternalSlots.Chest,
    ["INVTYPE_WEAPONMAINHAND"]  = MWL.InternalSlots.Weapon,
    ["INVTYPE_WEAPONOFFHAND"]   = MWL.InternalSlots.Weapon,
    ["INVTYPE_HOLDABLE"]        = MWL.InternalSlots.OffHand,
    ["INVTYPE_THROWN"]          = MWL.InternalSlots.Ranged,
    ["INVTYPE_RANGEDRIGHT"]     = MWL.InternalSlots.Ranged,
    ["INVTYPE_RELIC"]           = MWL.InternalSlots.Ranged,
}

-- local INVSLOT_REDUCTION = {
--     [INVSLOT_FINGER2] = INVSLOT_FINGER1,
--     [INVSLOT_TRINKET2] = INVSLOT_TRINKET1
-- }

local function BuildWishlistsFromDatabase(self)
    self.wishlists = {}
    for slot, data in pairs(MWL.InternalSlots) do
        self.wishlists[slot] = {}
        for _, entry in ipairs(MWL.Core.db.profile.wishlists[slot]) do
            local item = Item:CreateFromItemID(entry.id)
            if not item:IsItemEmpty() then
                self.wishlists[slot][#self.wishlists[slot]+1] = MWL.NewWishlistEntry(item, entry.note)
            end
        end
    end
end

local function Store()
    Manager:Store()
end

local function RegisterDBCallbacks(self)
    MWL.Core.db.RegisterCallback(self, "OnDatabaseShutdown", Store)
end

function Manager:Initialize()
    BuildWishlistsFromDatabase(self)
    RegisterDBCallbacks(self)
end

local function AddItemInternal(self, itemId, note, position)
    print("AddItemInternal")
    local item = Item:CreateFromItemID(itemId)
    if item:IsItemEmpty() then return end

    local _, _, _, itemEquipLoc, _, _, _ = GetItemInfoInstant(itemId)

    local slot = INVTYPE_to_MWL_slot_map[itemEquipLoc] or MWL.InternalSlots.Miscellaneous
    local entry = MWL.NewWishlistEntry(item, note)
    print(itemId, item, slot, entry, position)
    tinsert(self.wishlists[slot], position, entry)
    print("tinsert")
end

function Manager:AddItemById(itemId, note, position)
    print("AddItemById")
    itemId = tonumber(itemId) or 0
    if not GetItemInfoInstant(itemId) then return end
    if type(note) ~= "string" then
        note = ""
    end
    position = tonumber(position) or 1
    AddItemInternal(self, itemId, note, position)
end

function Manager:AddItemByLink(itemLink, note, position)
    local itemId = MWL.Utils.GetItemIdFromLink(itemLink)
    if not itemId then return end
    if not GetItemInfoInstant(itemId) then return end
    if type(note) ~= "string" then
        note = ""
    end
    position = tonumber(position) or 1
    AddItemInternal(self, itemId, note, position)
end

function Manager:GetWishlist(slot)
    return self.wishlists[slot] or {}
end

function Manager:Store()
    for slot, _ in pairs(MWL.InternalSlots) do
        MWL.Core.db.profile.wishlists[slot] = {}
        for _, entry in ipairs(self.wishlists[slot]) do
            if not entry:IsItemEmpty() then
                MWL.Core.db.profile.wishlists[slot][#MWL.Core.db.profile.wishlists[slot]+1] = {
                    id = tonumber(entry:GetItemID()) or 0,
                    note = tostring(entry:GetNote()) or ""
                }
            end
        end
    end
end

MWL.Manager = Manager