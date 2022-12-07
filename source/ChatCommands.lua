local _,  MWL = ...

local ChatCommands = {}

local AceConsole = LibStub("AceConsole-3.0")


local function HandlePrio(itemLink)
    print("HandlePrio")
    local itemId = MWL.Utils.GetItemIdFromLink(itemLink)
    if not itemId then
        -- TODO HANDLE ERROR
        return
    end

    MWL.Manager:AddItemById(itemId, "Slash CMD")
end

local function HandleDeprio(itemLink)
    local itemId = MWL.Utils.GetItemIdFromLink(itemLink)
    if not itemId then
        -- TODO HANDLE ERROR
        return
    end
end

function ChatCommands:Register()
    AceConsole:RegisterChatCommand("prio", HandlePrio)
    AceConsole:RegisterChatCommand("deprio", HandleDeprio)
end

MWL.ChatCommands = ChatCommands