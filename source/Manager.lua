local _,  MWL = ...

local pairs, ipairs, type = pairs, ipairs, type
local Item, GetItemInfoInstant = Item, GetItemInfoInstant
local tinsert, tremove = table.insert, table.remove

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

local function UpdateWishlistedItemMetadata(self, id, add)
    if not self.wishlistedItemMap[id] then
        self.wishlistedItemMap[id] = 0

        -- Slot
        local _, _, _, itemEquipLoc, _, _, _ = GetItemInfoInstant(id)
        local slot = INVTYPE_to_MWL_slot_map[itemEquipLoc] or MWL.InternalSlots.Miscellaneous
        self.wishlistedItemSlotMap[id] = slot
    end
    if add then
        self.wishlistedItemMap[id] = self.wishlistedItemMap[id] + 1
    else
        self.wishlistedItemMap[id] = self.wishlistedItemMap[id] - 1
        if self.wishlistedItemMap[id] < 0 then
            error("Wishlisted item count went below 0", 2)
        end
    end
end

local function BuildWishlistsFromDatabase(self)
    self.wishlists = {}
    self.wishlistedItemMap = {}
    self.wishlistedItemSlotMap = {}
    for slot, _ in pairs(MWL.InternalSlots) do
        self.wishlists[slot] = {}
        self.wishlistedItemMap[slot] = {}
        for _, entry in ipairs(MWL.Core.db.profile.wishlists[slot]) do
            local item = Item:CreateFromItemID(entry.id)
            if not item:IsItemEmpty() then
                UpdateWishlistedItemMetadata(self, entry.id, true)
                self.wishlists[slot][#self.wishlists[slot]+1] = MWL.NewWishlistEntry(item, entry.note)
            end
        end
    end
end

local function Store()
    for slot, _ in pairs(MWL.InternalSlots) do
        MWL.Core.db.profile.wishlists[slot] = {}
        for _, entry in ipairs(Manager.wishlists[slot]) do
            if not entry:IsItemEmpty() then
                MWL.Core.db.profile.wishlists[slot][#MWL.Core.db.profile.wishlists[slot]+1] = {
                    id = tonumber(entry:GetItemID()) or 0,
                    note = tostring(entry:GetNote()) or ""
                }
            end
        end
    end
end

local function RegisterDBCallbacks(self)
    MWL.Core.db.RegisterCallback(self, "OnDatabaseShutdown", Store)
end

function Manager:Initialize()
    BuildWishlistsFromDatabase(self)
    RegisterDBCallbacks(self)
end

local function AddItemInternal(self, itemId, note, position)
    if self:IsLocked() then return end
    local item = Item:CreateFromItemID(itemId)
    if item:IsItemEmpty() then return end

    local _, _, _, itemEquipLoc, _, _, _ = GetItemInfoInstant(itemId)

    local slot = INVTYPE_to_MWL_slot_map[itemEquipLoc] or MWL.InternalSlots.Miscellaneous
    local entry = MWL.NewWishlistEntry(item, note)
    tinsert(self.wishlists[slot], position, entry)
    UpdateWishlistedItemMetadata(self, itemId, true)
end

function Manager:AddItemById(itemId, note, position)
    if self:IsLocked() then return end
    itemId = tonumber(itemId) or 0
    if not GetItemInfoInstant(itemId) then return end
    if type(note) ~= "string" then
        note = ""
    end
    position = tonumber(position) or 1
    AddItemInternal(self, itemId, note, position)
end

function Manager:AddItemByLink(itemLink, note, position)
    if self:IsLocked() then return end
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

function Manager:MoveWishlistItemUp(slot, seqId)
    if self:IsLocked() then return end
    local entry = tremove(self.wishlists[slot], seqId)
    local newSeq = seqId - 1
    tinsert(self.wishlists[slot], newSeq, entry)
end

function Manager:MoveWishlistItemDown(slot, seqId)
    if self:IsLocked() then return end
    local entry = tremove(self.wishlists[slot], seqId)
    tinsert(self.wishlists[slot], seqId + 1, entry)
end

function Manager:RemoveWishlistItem(slot, seqId)
    if self:IsLocked() then return end
    local entry = tremove(self.wishlists[slot], seqId)
    UpdateWishlistedItemMetadata(self, entry:GetItemID(), false)
end

function Manager:IsItemWishlisted(itemId)
    return self.wishlistedItemMap[itemId] and self.wishlistedItemMap[itemId] > 0
end

function Manager:GetWishlistedItemSlot(itemId)
    return self.wishlistedItemSlotMap[itemId]
end

function Manager:GetWishlistedItems(itemId)
    local items = {}
    if not self:IsItemWishlisted(itemId) then return items end
    if not self:GetWishlistedItemSlot(itemId) then return items end

    for _,entry in ipairs(self.wishlists[self:GetWishlistedItemSlot(itemId)]) do
        if entry:GetItemID() == itemId then
            items[#items+1] = entry
        end
    end

    return items
end

function Manager:IsLocked()
    return MWL.Core.db.global.lock
end

function Manager:Lock()
    MWL.Core.db.global.lock = true
end

function Manager:Unlock()
    MWL.Core.db.global.lock = false
end

function Manager:ToggleLock()
    if self:IsLocked() then
        self:Unlock()
    else
        self:Lock()
    end
end

MWL.Manager = Manager