local _, MWL = ...

local smatch, sformat, sfind = string.match, string.format, string.find
local tonumber = tonumber

local Utils = {}

function Utils.ParseVersionString(versionString)
    local major, minor, patch, changeset = smatch(versionString, "^v(%d+).(%d+).(%d+)-?(.*)")
    return {
        major = tonumber(major) or 0,
        minor = tonumber(minor) or 0,
        patch = tonumber(patch) or 0,
        changeset = changeset or ""
    }
end

function Utils.GetVersionString(version)
    local changeset = ""
    if version.changeset and version.changeset ~= "" then
        changeset = "-" .. changeset
    end
    return sformat(
        "v%s.%s.%s%s",
        version.major or 0,
        version.minor or 0,
        version.patch or 0,
        changeset)
end

local function VersionToNumber(v)
    return v.major*10000 + v.minor*100 + v.patch
end

function Utils.CompareVersions(v1, v2)
    return VersionToNumber(v1) > VersionToNumber(v2)
end

function Utils.GetItemIdFromLink(itemLink)
    -- local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name = sfind(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
    itemLink = itemLink or ""
    local _, _, _, _, itemId = sfind(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+).*")
    return tonumber(itemId)
end

MWL.Utils = Utils