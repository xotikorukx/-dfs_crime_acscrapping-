local ERP               = nil
local ERPInventory      = nil
local shouldEndThread   = false
local isScrapping       = false
local scrapsCompleted   = {}
local onJobId           = -1
local lastJobCompleted  = 0
local atEntity          = nil

TriggerEvent('erp:getSharedObject',    function(object) ERP          = object end)
TriggerEvent('erp:getInventoryObject', function(object) ERPInventory = object end)

--
-- Threads
--

Citizen.CreateThread(function()
    for hashKey, _ in pairs(Config.Units) do
        TriggerEvent('erp_raycast:registerInterest', hashKey, 'erp:crime:acScrapping:raycastEntered', 'erp:crime:acScrapping:raycastExited')
    end

    TriggerEvent(
        'erp_events:registerAreaOfInterest',
        'salvageTurnIn',
        Config.Money.ElectricSellLocation,
        100.0,
        false,
        'erp:crime:acScrapping:enteredTurnInArea',
        'erp:crime:acScrapping:exitedTurnInArea'
    )

    TriggerServerEvent('erp:crime:acScrapping:getCompletedList')

    while true do
        Citizen.Wait(5000)
 
        deleteAreaACs()
    end
end)

function startTurnInAreaThread()
    if turnInAreaThreadRunning then
        return
    end

    turnInAreaThreadRunning = true

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)

            if not inTurnInArea then
                turnInAreaThreadRunning = false

                break
            end

            local playerId          = PlayerPedId()
            local playerCoordinates = GetEntityCoords(playerId)
            local distance          = #(playerCoordinates - Config.Money.ElectricSellLocation)

            ERP.GUI.ShowStandardMarker(Config.Money.ElectricSellLocation)

            if distance < 1.5 then
                ERP.GUI.ShowAlert('Press ~INPUT_PICKUP~ to turn in electronics scrap.', true)

                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent('erp:crime:acScrapping:turnIn')
                end
            end
        end
    end)
end

--
-- Functions
--

function deleteAreaACs()
    local playerId          = PlayerPedId()
    local playerCoordinates = GetEntityCoords(playerId)

    for jobId, jobData in pairs(scrapsCompleted) do
        local distance = #(playerCoordinates - jobData.position)

        if distance < 200.0 then
            local deletable = GetClosestObjectOfType(jobData.position, 0.1, jobData.hashKey, false, false, false)

            SetEntityAsMissionEntity(deletable, true, true)
            DeleteEntity(deletable)
        end
    end
end

--
-- Events
--

AddEventHandler('erp:crime:acScrapping:enteredTurnInArea', function()
    inTurnInArea = true

    startTurnInAreaThread()
end)

AddEventHandler('erp:crime:acScrapping:exitedTurnInArea', function()
    inTurnInArea = false
end)

AddEventHandler('erp:crime:acScrapping:raycastEntered', function(entityId, modelHash)
    local modelHash         = GetEntityModel(entityId)
    local acUnitCoordinates = GetEntityCoords(entityId)
    local acUnitMaxDimension, acUnitMinDimension = GetModelDimensions(modelHash)
    local acUnitDimensions  = (acUnitMaxDimension - acUnitMinDimension)
    local activationRadius  = math.abs(acUnitMaxDimension.y) + 1.5

    shouldEndThread = false

    if lastJobCompleted + Config.Cooldowns.Global > GetGameTimer() then
        return
    end

    if not ERPInventory.GetFirstItemIdOfType('WEAPON_WRENCH') then
        return
    end

    while not shouldEndThread do
        ::continue::
        Citizen.Wait(0)

        local playerId            = PlayerPedId()
        local playerCoordinates   = GetEntityCoords(playerId)
        local isArmed, weaponHash = GetCurrentPedWeapon(playerId, true)

        if 
            not isScrapping 
            and #(playerCoordinates - acUnitCoordinates) < activationRadius
            and (isArmed and weaponHash == `WEAPON_WRENCH`)
        then
            ERP.GUI.ShowAlert('Press ~INPUT_PICKUP~ dismantle.', true)

            if IsControlJustReleased(0, 38) then
 
                if not isArmed or weaponHash ~= `WEAPON_WRENCH` then
                    ERP.GUI.ShowNotification("You must equip your wrench to do that!")

                    goto continue
                end

                local processing = true

                atEntity = entityId

                ERP.TriggerServerCallback('erp:crime:acScrapping:generateJobId', function(jobId)
                    onJobId = jobId

                    ERP.TriggerServerCallback('erp:crime:acScrapping:tryStartJob', function(status)
                        if status == 1 then
                            ERP.GUI.ShowNotification('This thing is bolted down tight.')
                        end

                        if status == 2 then
                            ERP.GUI.ShowNotification('You think your time might be better used elsewhere.')
                        end

                        processing = false
                    end, onJobId, modelHash, acUnitCoordinates)
                end, acUnitCoordinates)

                while processing do
                    Citizen.Wait(100)
                end
            end
        end
    end
end)

AddEventHandler('erp:crime:acScrapping:raycastExited', function(entityId, modelHash)
    shouldEndThread = true
end)

RegisterNetEvent('erp:crime:acScrapping:completedList')
AddEventHandler('erp:crime:acScrapping:completedList', function(list)
    scrapsCompleted = list

    deleteAreaACs()
end)

RegisterNetEvent('erp:crime:acScrapping:startJob')
AddEventHandler('erp:crime:acScrapping:startJob', function(timeForEvent, isRestart)
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
        name         = 'erp:crime:acScrapping:scrapping',
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

            TriggerServerEvent('erp:crime:acs:userCancel')

            Citizen.Wait(1000)

            TriggerEvent('mythic_progressbar:client:progress', {
                name         = 'erp:crime:acScrapping:cancelling',
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