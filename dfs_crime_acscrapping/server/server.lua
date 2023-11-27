local QBCore = exports['qb-core']:GetCoreObject()
local scrapsCompleted  = {}
local scrapsInProgress = {}
local serverJobId      = 0
local playersScrapping = {}
local playerCalloutChances = {}
local playerLastCalledCops = {}

RegisterNetEvent('QBCore:Server:UpdateObject', function()
	if source ~= '' then return false end
	QBCore = exports['qb-core']:GetCoreObject()
end) 

exports["qb-core"]:AddItems(Config.Items)

--
-- Functions
--

function restartJob(jobId)
    for _, serverId in pairs(scrapsInProgress[jobId].attachedPlayers) do
        TriggerClientEvent('dfs:crime:acScrapping:startJob', serverId, (scrapsInProgress[jobId].timeLeft / #scrapsInProgress[jobId].attachedPlayers))
    end
end

function cancelPlayerJob(source)
    local jobId = playersScrapping[source]

    if jobId == nil then
        return
    end

    local lastPlayerList = scrapsInProgress[jobId].attachedPlayers
    local newAttacheds = {}

    for _, serverId in pairs(lastPlayerList) do
        if serverId ~= source then
            newAttacheds[#newAttacheds+1] = serverId
        end
    end

    scrapsInProgress[jobId].attachedPlayers = newAttacheds

    restartJob(jobId)
end

--
-- Threads
--

Citizen.CreateThread(function()
    local lastLoop = GetGameTimer()

    while true do
        Citizen.Wait(1000)

        local thisLoop = GetGameTimer()

        for jobId, scrapData in pairs(scrapsInProgress) do

            local shouldCallPolice      = false
            local totalHeat             = 0
            local didPlayerAttachOrDrop = false

            local newAttacheds = {}
            for _, playerServerId in pairs(scrapData.attachedPlayers) do
                local player       = QBCore.Functions.GetPlayer(playerServerId)

                if player then
                    newAttacheds[#newAttacheds+1] = playerServerId
                else
                    didPlayerAttachOrDrop = true
                end
            end

            if didPlayerAttachOrDrop then
                scrapsInProgress[jobId].attachedPlayers = newAttacheds

                restartJob(jobId)
            end

            for _, playerServerId in pairs(scrapData.attachedPlayers) do
                local player       = QBCore.Functions.GetPlayer(playerServerId)

                local heatIncrease  = Config.Police.ChanceToCallIncreasedPerSecondIncrease * (scrapData.isDiscouraged and Config.Police.DiscouragedHeatMultiplier or 1.0)
                local calloutChance = playerCalloutChances[playerServerId] or 0
                local increasedHeat = (calloutChance + heatIncrease)

                playerCalloutChances[playerServerId] = increasedHeat

                totalHeat = totalHeat + increasedHeat

                if not shouldCallPolice then
                    if scrapData.copLotto * #scrapData.attachedPlayers <= totalHeat then
                        if (playerLastCalledCops[playerServerId] or 0) + Config.Police.CallCooldown <= GetGameTimer() then
                            shouldCallPolice = true
                        end
                    end
                end
            end

            if shouldCallPolice then
                local coords = nil
                local street = nil
                local gender = nil
                local zone = nil
                local count = #scrapData.attachedPlayers
                
                QBCore.Functions.TriggerClientCallback("dfs:crime:acscrapping:getPlayerData", scrapData.parentPlayer, function(_coords, _street, _gender, _zone)
                    coords = _coords
                    street  = _street
                    gender = _gender
                    zone = _zone
                end)

                for _, playerServerId in pairs(scrapData.attachedPlayers) do
                    local player       = QBCore.Functions.GetPlayer(playerServerId)

                    playerCalloutChances[playerServerId] = 0
                    playerLastCalledCops[playerServerId] = GetGameTimer()
                end

                Citizen.CreateThread(function()
                    while not coords do Wait(0) end

                    Config.Police.CalloutLogic(coords, gender, street, zone)
                end)
           end

            scrapsInProgress[jobId].timeLeft = (scrapData.timeLeft - ((thisLoop - lastLoop) * #scrapData.attachedPlayers))

            if scrapData.timeLeft <= 0 then
                scrapsCompleted[#scrapsCompleted+1] = scrapsInProgress[jobId]

                local i = #scrapData.attachedPlayers
                --[[
                    i:  0   lm: 0.333 (impossible)
                    i:  1   lm: 0.75
                    i:  2   lm: 1.159
                    i:  3   lm: 1.548
                    i:  4   lm: 1.905
                    i:  5   lm: 2.218
                    i:  6   lm: 2.475
                    i:  7   lm: 2.664
                    i:  8   lm: 2.773
                    i:  9   lm: 2.79
                    i:  10  lm: 2.703
                    i:  11  lm: 2.5
                    i:  12  lm: 2.169
                    i:  13  lm: 1.698
                    i:  14  lm: 1.075
                    i:  15  lm: 0.288 (impossible)
                ]]

                if i > 14 then
                    i = 14
                end

                local thisLootMultiplier = 0.75 + ((i - 1) * (0.417 - ((i * i) * 0.002)))

                local loot = {}

                for itemName, lootAmount in pairs(scrapData.lootData) do
                    if itemName ~= "model" then
                        loot[itemName] = math.floor(math.random(math.ceil(lootAmount / 2), math.floor(lootAmount * 2)) * thisLootMultiplier)

                        if scrapData.isDiscouraged then
                            loot[itemName] = loot[itemName] * Config.Money.DiscouragedLootMultiplier
                        end

                        loot[itemName] = math.ceil(loot[itemName])
                    end
                end

                for index, serverId in pairs(scrapData.attachedPlayers) do
                    local player      = QBCore.Functions.GetPlayer(serverId)
                    local totalProfit = 0

                    playersScrapping[serverId] = false

                    for lootname, lootcount in pairs(loot) do
                        local quantity = math.ceil(lootcount / (#scrapData.attachedPlayers - index + 1))
                        local totalStole = 0

                        if quantity > 0 then
                            for i=1, quantity do
                                local success = player.Functions.AddItem(lootname, 1)

                                if success then
                                    loot[lootname] = loot[lootname] - 1

                                    totalStole = totalStole + 1
                                    totalProfit = totalProfit + Config.Money.SellPrices[lootname]
                                end
                            end

                            if totalStole > 0 then
                                TriggerClientEvent('QBCore:Notify', serverId, ('You stole %d %s.'):format(totalStole, Config.Items[lootname].label))
                            end

                            if totalStole < quantity then
                                TriggerClientEvent('QBCore:Notify', serverId, string.format('You can\'t carry any more %s right now.', Config.Items[lootname].label))
                            end
                        end
                    end

                    Config.SkillLogic(math.floor(totalProfit / 100))
                end

                scrapsInProgress[jobId] = nil

                TriggerClientEvent('dfs:crime:acScrapping:completedList', -1, scrapsCompleted)
            end
        end

        for serverId, isScrapping in pairs(playersScrapping) do
            local player = QBCore.Functions.GetPlayer(serverId)

            if player then
                local currentChance = playerCalloutChances[serverId] or 0

                if not isScrapping and currentChance > 0.0 then
                    playerCalloutChances[serverId] = playerCalloutChances[serverId] - Config.Police.CalloutHeatDecayPerSecondNotScrapping
                end
            end
        end

        lastLoop = thisLoop
    end
end)

--
-- Exports
--

exports('Dump', function()
    return {
        serverJobId      = serverJobId,
        playersScrapping = playersScrapping,
        scrapsCompleted  = scrapsCompleted,
        scrapsInProgress = scrapsInProgress,
    }
end)

--
-- Server Callbacks
--

QBCore.Functions.CreateCallback('dfs:crime:acScrapping:generateJobId', function(playerId, cb, coords)
    serverJobId = serverJobId + 1

    for jobId, scrapData in pairs(scrapsInProgress) do
        if math.abs(#scrapData.position - #coords) < 1.0 then
            cb(jobId)

            return
        end
    end

    cb(serverJobId)
end)

QBCore.Functions.CreateCallback('dfs:crime:acScrapping:tryStartJob', function(playerId, cb, jobId, hashKey, coordinates)
    local player          = QBCore.Functions.GetPlayer(playerId)

    local playersAttached = scrapsInProgress[jobId] ~= nil and #scrapsInProgress[jobId].attachedPlayers or 0
    local policeRequired  = playersAttached - 1

    if Config.Police.EnableCopRequirement then
        if QBCore.Functions.GetDutyCount('police') < policeRequired then
            if playersAttached > 0 then

                cb(2)

                return
            end

            cb(1)

            return
        end
    end

    local lootTable = Config.Units[hashKey]

    if not scrapsInProgress[jobId] then
        scrapsInProgress[jobId] = {
            parentPlayer    = playerId,
            attachedPlayers = {},
            lootData        = lootTable,
            position        = coordinates,
            timeLeft        = (
                (lootTable.nutsandbolts or 0) * Config.Times.nutsandbolts) +
                ((lootTable.metalscrap or 0) * Config.Times.metalscrap) +
                ((lootTable.electricalscrap or 0) * Config.Times.electricalscrap) +
                ((lootTable.steel or 0) * Config.Times.steel),
            isDiscouraged   = coordinates.y > 900,
            hashKey         = hashKey,
            copLotto        = math.random(20, 100)
        }
    end

    scrapsInProgress[jobId].attachedPlayers[#scrapsInProgress[jobId].attachedPlayers + 1] = playerId

    playersScrapping[playerId] = jobId
    local calloutChance = playerCalloutChances[playerId] or 0

    calloutChance = calloutChance + Config.Police.ChanceToCallPerPlayerAttachedIncrease

    cb(0)

    restartJob(jobId)
end)

--
-- Events
--
AddEventHandler('playerDropped', function()
    cancelPlayerJob(source)
end)

RegisterNetEvent('dfs:crime:acScrapping:turnIn', function()
    local playerId     = source
    local player       = QBCore.Functions.GetPlayer(playerId)
    local totalPay     = 0


    local itemList = player.Functions.GetItemsByName("electricalscrap")

    for index, itemData in pairs(itemList) do
        local payout = Config.Money.SellPrices.electricalscrap * itemData.amount
        local success = player.Functions.RemoveItem("electricalscrap", itemData.amount)

        if success then
            totalPay = (totalPay + payout)
        end
    end

    if totalPay == 0 then
        TriggerClientEvent('QBCore:Notify', playerId, 'You don\'t have any scrap to turn in.')

        return
    else
        player.Functions.AddMoney('bank', totalPay, 'Leroy\'s Electrical', 'Electronics Scrap')
        TriggerClientEvent('QBCore:Notify', playerId, ('Received $%s check for your electronics scrap.'):format(totalPay))
    end
end)

RegisterNetEvent('dfs:crime:acScrapping:getCompletedList')
AddEventHandler('dfs:crime:acScrapping:getCompletedList', function()
    TriggerClientEvent('dfs:crime:acScrapping:completedList', -1, scrapsCompleted)
end)

RegisterNetEvent('dfs:crime:acs:userCancel')
AddEventHandler('dfs:crime:acs:userCancel', function()
    cancelPlayerJob(source)
end)