local ERP              = nil
local ERPInventory     = nil
local scrapsCompleted  = {}
local scrapsInProgress = {}
local serverJobId      = 0
local playersScrapping = {}

TriggerEvent('erp:getSharedObject',    function(object) ERP          = object end)
TriggerEvent('erp:getInventoryObject', function(object) ERPInventory = object end)

--
-- Functions
--

function restartJob(jobId)
    for _, serverId in pairs(scrapsInProgress[jobId].attachedPlayers) do
        TriggerClientEvent('erp:crime:acScrapping:startJob', serverId, (scrapsInProgress[jobId].timeLeft / #scrapsInProgress[jobId].attachedPlayers))
    end
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
                local player       = ERP.GetPlayerFromId(playerServerId)

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
                local player       = ERP.GetPlayerFromId(playerServerId)

                local heatIncrease  = Config.Police.ChanceToCallIncreasedPerSecondIncrease * (scrapData.isDiscouraged and Config.Police.DiscouragedHeatMultiplier or 1.0)
                local calloutChance = player.Get('acScrappingCalloutChance') or 0
                local increasedHeat = (calloutChance + heatIncrease)


                player.Set('acScrappingCalloutChance', increasedHeat)

                totalHeat = totalHeat + increasedHeat

                if not shouldCallPolice then
                    if scrapData.copLotto * #scrapData.attachedPlayers <= totalHeat then
                        if (player.Get('acScrappingLastCalledPolice') or -999999999) + Config.Police.CallCooldown <= GetGameTimer() then
                            shouldCallPolice = true
                        end
                    end
                end
            end

            if shouldCallPolice then
                for _, playerServerId in pairs(scrapData.attachedPlayers) do
                    local player       = ERP.GetPlayerFromId(playerServerId)

                    player.Set('acScrappingCalloutChance', 0)
                    player.Set('acScrappingLastCalledPolice', GetGameTimer())
                end

                TriggerClientEvent('erp:crimeAlert', scrapData.attachedPlayers[1], 'AC_SCRAPPING', scrapData.position)

                TriggerEvent('erp:log', 'INFO', 'Cops Called', { calloutChance = scrapData.copLotto, }, playerServerId)
            end

            scrapsInProgress[jobId].timeLeft = (scrapData.timeLeft - ((thisLoop - lastLoop) * #scrapData.attachedPlayers))

            if scrapData.timeLeft <= 0 then
                scrapsCompleted[#scrapsCompleted+1] = scrapsInProgress[jobId]

                local i = #scrapData.attachedPlayers
                --[[
                    i:  0   lm: 0.333
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
                    i:  15  lm: 0.288
                    i:  16  lm: -0.675
                ]]

                if i > 14 then
                    i = 14
                end

                local thisLootMultiplier = 0.75 + ((i - 1) * (0.417 - ((i * i) * 0.002)))

                local loot = {}

                for itemName, lootAmount in pairs(scrapData.lootData) do
                    loot[itemName] = math.floor(math.random(math.ceil(lootAmount / 2), math.floor(lootAmount * 2)) * thisLootMultiplier)

                    if scrapData.isDiscouraged then
                        loot[itemName] = loot[itemName] * Config.Money.DiscouragedLootMultiplier
                    end

                    loot[itemName] = math.ceil(loot[itemName])
                end

                for index, serverId in pairs(scrapData.attachedPlayers) do
                    local player      = ERP.GetPlayerFromId(serverId)
                    local profitToday = player.Get('acScrappingProfitToday') or 0

                    playersScrapping[serverId] = false

                    if profitToday >= Config.Money.Limit then
                        player.ShowNotification('You\'ve reached your scrap limit for today.')
                    elseif profitToday > Config.Money.Limit * 0.75 then
                        player.ShowNotification('You\'re nearing your scrap limit for today.')
                    end

                    if profitToday < Config.Money.Limit then
                        for lootname, lootcount in pairs(loot) do
                            local quantity = math.ceil(lootcount / (#scrapData.attachedPlayers - index + 1))
                            local totalStole = 0

                            if quantity > 0 then
                                for i=1, quantity do
                                    local success = false

                                    if profitToday < Config.Money.Limit then
                                        success = ERPInventory.AddItem('player', player.GetIdentifier(), lootname, 1)
                                    end

                                    if success then
                                        loot[lootname] = loot[lootname] - 1

                                        totalStole = totalStole + 1

                                        profitToday = player.Get('acScrappingProfitToday') or 0
                                    end

                                    if not success then
                                        break
                                    end
                                end

                                if totalStole > 0 then
                                    player.Set('acScrappingProfitToday', (profitToday + Config.Money.SellPrices[lootname] * totalStole))

                                    player.ShowNotification(('You stole %d %s.'):format(totalStole, ERPInventory.GetItemLabel(lootname)))
                                end

                                if totalStole < quantity then
                                    player.ShowNotification(string.format('You can\'t carry any more %s right now.', ERPInventory.GetItemLabel(lootname)))
                                end
                            end
                        end

                        TriggerEvent('erp:gangs:rep:credit', player.GetServerId(), 'acUnit')
                    end

                    TriggerEvent('erp:log', 'INFO', 'Profit Metrics', { profitToday = profitToday, }, serverId)
                end

                scrapsInProgress[jobId] = nil

                TriggerClientEvent('erp:crime:acScrapping:completedList', -1, scrapsCompleted)
            end
        end

        for serverId, isScrapping in pairs(playersScrapping) do
            local player = ERP.GetPlayerFromId(serverId)

            if player then
                local currentChance = player.Get('acScrappingCalloutChance') or 0

                if not isScrapping and currentChance > 0.0 then
                    player.Set('acScrappingCalloutChance', currentChance - Config.Police.CalloutHeatDecayPerSecondNotScrapping)
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

ERP.RegisterServerCallback('erp:crime:acScrapping:generateJobId', function(playerId, cb, coords)
    serverJobId = serverJobId + 1

    for jobId, scrapData in pairs(scrapsInProgress) do
        if math.abs(#scrapData.position - #coords) < 1.0 then
            cb(jobId)

            TriggerEvent('erp:log', 'INFO', 'Generated JobID', serverJobId, playerId)

            return
        end
    end

    TriggerEvent('erp:log', 'INFO', 'Generated JobID', serverJobId, playerId)

    cb(serverJobId)
end)

ERP.RegisterServerCallback('erp:crime:acScrapping:tryStartJob', function(playerId, cb, jobId, hashKey, coordinates)
    local player          = ERP.GetPlayerFromId(playerId)

    local playersAttached = scrapsInProgress[jobId] ~= nil and #scrapsInProgress[jobId].attachedPlayers or 0
    local policeRequired  = playersAttached - 1

    if ERP.GetOnlinePoliceCount() < policeRequired then
        if playersAttached > 0 then

            TriggerEvent('erp:log', 'INFO', 'Denied player AC job; too many people on it, not enough cops.', scrapsInProgress[jobId], playerId)

            cb(2)

            return
        end

        cb(1)

        return
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
                ((lootTable.smallsalvage or 0) * Config.Times.smallsalvage) +
                ((lootTable.electricalscrap or 0) * Config.Times.electricalscrap) +
                ((lootTable.salvage or 0) * Config.Times.salvage),
            isDiscouraged   = coordinates.y > 900,
            hashKey         = hashKey,
            copLotto        = math.random(20, 100)
        }
    end

    scrapsInProgress[jobId].attachedPlayers[#scrapsInProgress[jobId].attachedPlayers + 1] = playerId

    playersScrapping[playerId] = jobId

    local calloutChance = player.Get('acScrappingCalloutChance') or 0

    player.Set('acScrappingCalloutChance', (calloutChance + Config.Police.ChanceToCallPerPlayerAttachedIncrease))

    TriggerEvent('erp:log', 'INFO', 'Scrapping AC', scrapsInProgress[jobId], playerId)

    cb(0)

    restartJob(jobId)
end)

--
-- Events
--

RegisterNetEvent('erp:crime:acScrapping:turnIn', function()
    local playerId     = source
    local player       = ERP.GetPlayerFromId(playerId)
    local _, inventory = ERPInventory.GetInventory('player', player.GetIdentifier())
    local salvageIds   = ERPInventory.GetAllItemIdsOfType('player', player.GetIdentifier(), 'electricalscrap')
    local totalPay     = 0

    for _, itemId in pairs(salvageIds) do
        local quantity = inventory.items[itemId].quantity
        local payout   = (quantity * Config.Money.SellPrices.electricalscrap)

        if ERPInventory.RemoveItem('player', player.GetIdentifier(), itemId, quantity) then
            totalPay = (totalPay + payout)
        end
    end

    if totalPay <= 0 then
        player.ShowNotification('You don\'t have any scrap to turn in.')

        return
    end

    player.AddBank(totalPay, 'Leroy\'s Electrical', 'Electronics Scrap')
    player.ShowNotification(('Received $%s check for your electronics scrap.'):format(totalPay))
end)

AddEventHandler('erp:newServerEpochDay', function()
    for _, serverId in pairs(ERP.GetPlayers()) do
        local player = ERP.GetPlayerFromId(serverId)

        player.Set('acScrappingProfitToday', 0)
        player.Set('acScrappingCalloutChance', 0)
    end
end)

RegisterNetEvent('erp:crime:acScrapping:getCompletedList')
AddEventHandler('erp:crime:acScrapping:getCompletedList', function()
    TriggerClientEvent('erp:crime:acScrapping:completedList', -1, scrapsCompleted)
end)

RegisterNetEvent('erp:crime:acs:userCancel')
AddEventHandler('erp:crime:acs:userCancel', function()
    local jobId = playersScrapping[source]

    local lastPlayerList = scrapsInProgress[jobId].attachedPlayers
    local newAttacheds = {}

    for _, serverId in pairs(lastPlayerList) do
        if serverId ~= source then
            newAttacheds[#newAttacheds+1] = serverId
        end
    end

    scrapsInProgress[jobId].attachedPlayers = newAttacheds

    restartJob(jobId)
end)