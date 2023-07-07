local getTimestamp = getTimestamp
local querySteamWorkshopItemDetails = querySteamWorkshopItemDetails
local getSteamWorkshopItemIDs = getSteamWorkshopItemIDs
local getCore = getCore

if not getCore():isDedicated() then
    print("[ModzCheck] Refusing to load, not a dedicated server")
    return
end

local serverStarted = getTimestamp()
local pendingReboot = false

local pollWorkshop do
    local fakeTable = {}
    function pollWorkshop()
        if pendingReboot then return end
        print("[ModzCheck] Checking for outdated Workshop items")
        querySteamWorkshopItemDetails(getSteamWorkshopItemIDs(), function(_, status, info)
            if status ~= "Completed" then return end
            for i = 0, info:size() - 1 do
                local details = info:get(i)
                local updated = details:getTimeUpdated()
                if updated >= serverStarted then
                    pendingReboot = true
                    print("[ModzCheck] Mod update required")
                    return
                end
            end
        end, fakeTable)
    end
end

local nextPoll = getTimestamp() + 1800
Events.OnTickEvenPaused.Add(function()
    if pendingReboot then return end
    local timestamp = getTimestamp()
    if timestamp >= nextPoll then
        nextPoll = timestamp + 1800
        return pollWorkshop()
    end
end)
