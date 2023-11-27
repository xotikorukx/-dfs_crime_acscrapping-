local shouldEndThread   = false
local isScrapping       = false
local scrapsCompleted   = {}
local onJobId           = -1
local lastJobCompleted  = 0
local atEntity          = nil
local QBCore = exports['qb-core']:GetCoreObject()
local awaiting = false

RegisterNetEvent('QBCore:Server:UpdateObject', function()
	if source ~= '' then return false end
	QBCore = exports['qb-core']:GetCoreObject()
end)

--
-- Threads
--

Citizen.CreateThread(function()
    exports['qb-target']:AddTargetModel(Config.Units, {
        options = {
            {
                targeticon = "fa-solid fa-screwdriver-wrench",
                label = "Dismantle AC",
                item = "WEAPON_WRENCH",
                canInteract = function()
                    if isScrapping or awaiting then return false end
                end,
                action = function()
                    if lastJobCompleted + Config.Cooldowns.Global > GetGameTimer() then
                        return
                    end
    
                    local awaiting = true
                    QBCore.Functions.TriggerCallback('dfs:crime:acScrapping:generateJobId', function(jobId)
                        onJobId = jobId
    
                        QBCore.Functions.TriggerCallback('dfs:crime:acScrapping:tryStartJob', function(status)
                            if status == 1 then
                                QBCore.Functions.Notify('This thing is bolted down tight.', 'error', 1500)
                            end
    
                            if status == 2 then
                                QBCore.Functions.Notify('You think your time might be better used elsewhere.', 'error', 3500)
                            end
    
                            awaiting = false
                        end, onJobId, modelHash, acUnitCoordinates)
                    end, acUnitCoordinates)
                end
            },
        },
        distance = 1.5
    })

    exports['qb-target']:AddBoxZone("leroys-sell", Config.Money.ElectricSellLocation, 1.5, 0.5, {
        minZ = Config.Money.ElectricSellLocation.z -1.0,
        maxZ = Config.Money.ElectricSellLocation.z +1.0,
    }, {
        options = {
            icon = "fa-solid fa-dollar-sign",
            label = "Sell Electrical Scrap",
            event = "dfs:crime:acScrapping:turnIn",
            type = "server",
        }
    })

    TriggerServerEvent('dfs:crime:acScrapping:getCompletedList')

    while true do
        Citizen.Wait(5000)
 
        deleteAreaACs()
    end
end)

--
-- Functions
--

function deleteAreaACs()
    local playerId          = PlayerPedId()
    local playerCoordinates = GetEntityCoords(playerId)

    for jobId, jobData in pairs(scrapsCompleted) do
        local distance = #(playerCoordinates - jobData.position)

        if distance < 200.0 then --I would do 400, but at a certain point the game just respawns them repeatedly
            local deletable = GetClosestObjectOfType(jobData.position, 0.1, jobData.hashKey, false, false, false)

            SetEntityAsMissionEntity(deletable, true, true)
            DeleteEntity(deletable)
        end
    end
end

--
-- Events
--

AddEventHandler('dfs:crime:acScrapping:enteredTurnInArea', function()
    inTurnInArea = true

    startTurnInAreaThread()
end)

AddEventHandler('dfs:crime:acScrapping:exitedTurnInArea', function()
    inTurnInArea = false
end)

--Not deleting this because this is a work of ancient ingenuity on my part LOL
--AddEventHandler('dfs:crime:acScrapping:raycastEntered', function(entityId, modelHash)
--    local modelHash         = GetEntityModel(entityId)
--    local acUnitCoordinates = GetEntityCoords(entityId)
--    local acUnitMaxDimension, acUnitMinDimension = GetModelDimensions(modelHash)
--    local acUnitDimensions  = (acUnitMaxDimension - acUnitMinDimension)
--    local activationRadius  = math.abs(acUnitMaxDimension.y) + 1.5
--
--    shouldEndThread = false
--
--    if lastJobCompleted + Config.Cooldowns.Global > GetGameTimer() then
--        return
--    end
--
--    if not ERPInventory.GetFirstItemIdOfType('WEAPON_WRENCH') then
--        return
--    end
--
--    while not shouldEndThread do
--        ::continue::
--        Citizen.Wait(0)
--
--        local playerId            = PlayerPedId()
--        local playerCoordinates   = GetEntityCoords(playerId)
--        local isArmed, weaponHash = GetCurrentPedWeapon(playerId, true)
--
--        if 
--            not isScrapping 
--            and #(playerCoordinates - acUnitCoordinates) < activationRadius
--            and (isArmed and weaponHash == `WEAPON_WRENCH`)
--        then
--            ERP.GUI.ShowAlert('Press ~INPUT_PICKUP~ dismantle.', true)
--
--            if IsControlJustReleased(0, 38) then
-- 
--                if not isArmed or weaponHash ~= `WEAPON_WRENCH` then
--                    ERP.GUI.ShowNotification("You must equip your wrench to do that!")
--
--                    goto continue
--                end
--
--                local processing = true
--
--                atEntity = entityId
--
--                QBCore.Functions.TriggerCallback('dfs:crime:acScrapping:generateJobId', function(jobId)
--                    onJobId = jobId
--
--                    QBCore.Functions.TriggerCallback('dfs:crime:acScrapping:tryStartJob', function(status)
--                        if status == 1 then
--                            ERP.GUI.ShowNotification('This thing is bolted down tight.')
--                        end
--
--                        if status == 2 then
--                            ERP.GUI.ShowNotification('You think your time might be better used elsewhere.')
--                        end
--
--                        processing = false
--                    end, onJobId, modelHash, acUnitCoordinates)
--                end, acUnitCoordinates)
--
--                while processing do
--                    Citizen.Wait(100)
--                end
--            end
--        end
--    end
--end)

RegisterNetEvent('dfs:crime:acScrapping:completedList')
AddEventHandler('dfs:crime:acScrapping:completedList', function(list)
    scrapsCompleted = list

    deleteAreaACs()
end)

RegisterNetEvent('dfs:crime:acScrapping:startJob')
AddEventHandler('dfs:crime:acScrapping:startJob', function(timeForEvent, isRestart)
    local timeForEvent = math.floor(timeForEvent)
    local timeToStopJob = 0

    if isScrapping then
        TriggerEvent('mythic_progressbar:client:updateDuration', timeForEvent)
    else
        TaskTurnPedToFaceEntity(PlayerPedId(), atEntity, 500)

        Citizen.Wait(500)

        timeToStopJob = 500
        isScrapping = true
    end


    TriggerEvent('mythic_progressbar:client:progress', {
        name         = 'dfs:crime:acScrapping:scrapping',
        duration     = timeForEvent - timeToStopJob,
        label        = 'Dismantling',
        useWhileDead = false,
        canCancel    = true,
        controlDisables = {
            disableMovement    = true,
            disableCarMovement = true,
            disableMouse       = false,
            disableCombat      = true,
        },
        animation = {
            animDict = 'anim@gangops@facility@servers@',
            anim     = 'hotwire',
        },
    }, function(cancelled)
        if cancelled then

            TriggerServerEvent('dfs:crime:acs:userCancel')

            Citizen.Wait(1000)

            TriggerEvent('mythic_progressbar:client:progress', {
                name         = 'dfs:crime:acScrapping:cancelling',
                duration     = timeForEvent * 0.05,
                label        = 'Cancelling',
                useWhileDead = false,
                canCancel    = false,
                controlDisables = {
                    disableMovement    = true,
                    disableCarMovement = true,
                    disableMouse       = false,
                    disableCombat      = true,
                },
                animation = {
                    animDict = 'anim@gangops@facility@servers@',
                    anim     = 'hotwire',
                },
            }, function(cancelled) isScrapping = false end)

        else
            lastJobCompleted = GetGameTimer()

            isScrapping = false
        end

    end)
end)