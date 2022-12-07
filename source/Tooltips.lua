local _, MWL = ...

local function addWishlistedItemNoteToTooltip(tooltip)
    -- Sanity Check
    if not tooltip then return end
    local _, itemLink = tooltip:GetItem()
    if not itemLink then return end
    local itemId = MWL.Utils.GetItemIdFromLink(itemLink)
    if itemId == 0 then return end
    -- Note
    local items = MWL.Manager:GetWishlistedItems(itemId)
    for _, entry in ipairs(items) do
        tooltip:AddDoubleLine("Wishlist", MWL.Utils.ColorCodeText(entry:GetNote(), "44ee44"))
    end
end

LibStub("AceConfigDialog-3.0").tooltip:HookScript("OnTooltipSetItem", addWishlistedItemNoteToTooltip)
GameTooltip:HookScript("OnTooltipSetItem", addWishlistedItemNoteToTooltip)
ItemRefTooltip:HookScript("OnTooltipSetItem", addWishlistedItemNoteToTooltip)