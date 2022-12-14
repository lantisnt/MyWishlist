local _, MWL = ...

local tostring = tostring

local WishlistEntry = {} -- WishlistEntry
WishlistEntry.__index = WishlistEntry

local strsub20 = MWL.Utils.strsub20

local function LimitNote(note)
    return strsub20(tostring(note or ""))
end

function WishlistEntry:New(item, note)
    local o = {}
    setmetatable(o, self)

    o.item = item
    o.note = LimitNote(note)

    return o
end

local function NewWishlistEntry(item, note)
    return WishlistEntry:New(item, note)
end

function WishlistEntry:GetItemID()
    return self.item:GetItemID()
end

function WishlistEntry:GetItemLink()
    return self.item:GetItemLink()
end

function WishlistEntry:GetNote()
    return self.note
end

function WishlistEntry:SetNote(note)
    self.note = LimitNote(note)
end

function WishlistEntry:IsItemEmpty()
    return self.item:IsItemEmpty()
end

MWL.NewWishlistEntry = NewWishlistEntry