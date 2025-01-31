local housePlants = {}
local insideHouse = false
local currentHouse = nil
local plantsSpawned = false
local closestTarget = 0

local function spawnPlants()
    if plantsSpawned then return end
    for _, v in pairs(housePlants[currentHouse]) do
        local plantProp = CreateObject(joaat(QBWeed.Plants[v.sort].stages[v.stage]), v.coords.x, v.coords.y, v.coords.z, false, false, false)
        while not plantProp do Wait(0) end

        PlaceObjectOnGroundProperly(plantProp)
        Wait(10)
        FreezeEntityPosition(plantProp, true)
        SetEntityAsMissionEntity(plantProp, false, false)
    end
    plantsSpawned = true
end

local function deleteClosestPlant(plantStage, plantData)
    local closestPlant = GetClosestObjectOfType(plantData.coords.x, plantData.coords.y, plantData.coords.z, 3.5, joaat(plantStage), false, false, false)
    if closestPlant == 0 then return end

    DeleteObject(closestPlant)
end

local function despawnPlants()
    if not (plantsSpawned or currentHouse) then return end

    for _, v in pairs(housePlants[currentHouse]) do
        for _, stage in pairs(QBWeed.Plants[v.sort].stages) do
            deleteClosestPlant(stage, v)
            v = nil
        end
    end
    plantsSpawned = false
end

local function updatePlantStats()
    if not (insideHouse or plantsSpawned) then return end
    for k, v in pairs(housePlants[currentHouse]) do
        local gender = "M"
        if v.gender == "woman" then gender = "F" end

        local plyDistance = #(GetEntityCoords(cache.ped) - v.coords)

        if plyDistance < 0.8 then
            closestTarget = k
            if v.health > 0 then
                if v.stage ~= QBWeed.Plants[v.sort].highestStage then
                    DrawText3D(('%s%s~w~ [%s] | %s ~b~%s% ~w~ | %s ~b~%s%'):format(Lang:t('text.sort'), QBWeed.Plants[v.sort].label, gender, Lang:t('text.nutrition'), v.food, Lang:t('text.health'), v.health), v.coords)
                else
                    DrawText3D(Lang:t('text.harvest_plant'), v.coords.x, v.coords.y, v.coords.z + 0.2)
                    DrawText3D(('%s ~g~%s~w~ [%s] | %s ~b~%s% ~w~ | %s ~b~%s%'):format(Lang:t('text.sort'), QBWeed.Plants[v.sort].label, gender, Lang:t('text.nutrition'), v.food, Lang:t('text.health'), v.health), v.coords)
                    if IsControlJustPressed(0, 38) then
                        if lib.progressCircle({
                                duration = 8000,
                                position = 'bottom',
                                label = Lang:t('text.harvesting_plant'),
                                useWhileDead = false,
                                canCancel = true,
                                disable = {
                                    move = true,
                                    car = true,
                                    mouse = false,
                                    combat = true,
                                },
                                anim = {
                                    dict = "amb@world_human_gardener_plant@male@base",
                                    clip = "base",
                                },
                            })
                        then
                            ClearPedTasks(cache.ped)
                            local amount = math.random(1, 6)
                            if gender == "M" then
                                amount = math.random(1, 2)
                            end
                            TriggerServerEvent('qb-weed:server:harvestPlant', currentHouse, amount, v.sort, v.plantid)
                        else
                            ClearPedTasks(cache.ped)
                            exports.qbx_core:Notify(Lang:t('error.process_canceled'), 'error')
                        end
                    end
                end
            elseif v.health == 0 then
                DrawText3D(Lang:t('error.plant_has_died'), v.coords)
                if IsControlJustPressed(0, 38) then
                    if lib.progressCircle({
                            duration = 8000,
                            position = 'bottom',
                            label = Lang:t('text.removing_the_plant'),
                            useWhileDead = false,
                            canCancel = true,
                            disable = {
                                move = true,
                                car = true,
                                mouse = false,
                                combat = true,
                            },
                            anim = {
                                dict = "amb@world_human_gardener_plant@male@base",
                                clip = "base",
                            },
                        })
                    then
                        ClearPedTasks(cache.ped)
                        TriggerServerEvent('qb-weed:server:removeDeathPlant', currentHouse, v.plantid)
                    else
                        ClearPedTasks(cache.ped)
                        exports.qbx_core:Notify(Lang:t('error.process_canceled'), 'error')
                    end
                end
            end
        end
    end
end

local function updatePlants()
    local sleep = 0
    while true do
        Wait(sleep)
        sleep = 0
        updatePlantStats()
        if not insideHouse then
            sleep = 5000
        end
    end
end

CreateThread(updatePlants)

RegisterNetEvent('qb-weed:client:getHousePlants', function(house)
    local plants = lib.callback.await('qb-weed:server:getBuildingPlants', false, house)
    currentHouse = house
    housePlants[currentHouse] = plants
    insideHouse = true
    spawnPlants()
end)

RegisterNetEvent('qb-weed:client:leaveHouse', function()
    despawnPlants()
    Wait(1000)
    if not currentHouse then return end
    insideHouse = false
    housePlants[currentHouse] = nil
    currentHouse = nil
end)

RegisterNetEvent('qb-weed:client:refreshHousePlants', function(house)
    if not currentHouse or currentHouse ~= house then return end
    despawnPlants()
    Wait(1000)
    local plants = lib.callback.await('qb-weed:server:getBuildingPlants', false, house)
    currentHouse = house
    housePlants[currentHouse] = plants
    spawnPlants()
end)

RegisterNetEvent('qb-weed:client:refreshPlantStats', function()
    if not insideHouse then return end
    despawnPlants()
    Wait(1000)
    local plants = lib.callback.await('qb-weed:server:getBuildingPlants', false, house)
    housePlants[currentHouse] = plants
    spawnPlants()
end)

RegisterNetEvent('qb-weed:client:placePlant', function(type, item)
    local plyCoords = GetOffsetFromEntityInWorldCoords(cache.ped, 0, 0.75, 0)
    local closestPlant = 0
    for _, v in pairs(QBWeed.Props) do
        if closestPlant == 0 then
            closestPlant = GetClosestObjectOfType(plyCoords.x, plyCoords.y, plyCoords.z, 0.8, joaat(v), false, false, false)
        end
    end

    if currentHouse then
        if closestPlant == 0 then
            LocalPlayer.state:set("invBusy", true, true)
            if lib.progressCircle({
                duration = 8000,
                position = 'bottom',
                label = Lang:t('text.planting'),
                useWhileDead = false,
                canCancel = true,
                disable = {
                    move = true,
                    car = true,
                    mouse = false,
                    combat = true,
                },
                anim = {
                    dict = "amb@world_human_gardener_plant@male@base",
                    clip = "base",
                },
            })
            then
                ClearPedTasks(cache.ped)
                TriggerServerEvent('qb-weed:server:placePlant', json.encode(plyCoords), type, currentHouse)
                TriggerServerEvent('qb-weed:server:removeSeed', item.slot, type)
            else
                ClearPedTasks(cache.ped)
                exports.qbx_core:Notify(Lang:t('error.process_canceled'), 'error')
                LocalPlayer.state:set("invBusy", false, true)
            end
        else
            exports.qbx_core:Notify(Lang:t('error.cant_place_here'), 'error')
        end
    else
        exports.qbx_core:Notify(Lang:t('error.not_safe_here'), 'error')
    end
end)

RegisterNetEvent('qb-weed:client:foodPlant', function()
    if not currentHouse then return end

    if closestTarget ~= 0 then
        exports.qbx_core:Notify(Lang:t('error.not_safe_here'), 'error')
        return
    end

    local data = housePlants[currentHouse][closestTarget]
    local plyDistance = #(GetEntityCoords(cache.ped) - data.coords)

    if plyDistance >= 1.0 then
        exports.qbx_core:Notify(Lang:t('error.cant_place_here'), 'error')
        return
    end

    if data.food == 100 then
        exports.qbx_core:Notify(Lang:t('error.not_need_nutrition'), 'error')
        return
    end

    LocalPlayer.state:set("invBusy", true, true)
    if lib.progressCircle({
            duration = math.random(4000, 8000),
            position = 'bottom',
            label = Lang:t('text.feeding_plant'),
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                mouse = false,
                combat = true,
            },
            anim = {
                dict = "timetable@gardener@filling_can",
                clip = "gar_ig_5_filling_can",
            },
        })
    then
        ClearPedTasks(cache.ped)
        local newFood = math.random(40, 60)
        TriggerServerEvent('qb-weed:server:foodPlant', currentHouse, newFood, data.sort, data.plantid)
    else
        ClearPedTasks(cache.ped)
        LocalPlayer.state:set("invBusy", false, true)
        exports.qbx_core:Notify(Lang:t('error.process_canceled'), 'error')
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    despawnPlants()
end)