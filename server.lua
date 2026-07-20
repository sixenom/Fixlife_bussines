local objects, occupied, inside = {}, {}, {}

local function releaseComputer(index)
    local entity = NetworkGetEntityFromNetworkId(objects[index].chair)
    if entity ~= 0 then
        FreezeEntityPosition(entity, true)
    end
    occupied[index] = nil
end

local function deleteComputer(index)
    local computer = objects[index]
    if not computer then return end

    DeleteEntity(NetworkGetEntityFromNetworkId(computer.monitor))
    DeleteEntity(NetworkGetEntityFromNetworkId(computer.chair))
    objects[index] = nil
end

local function isEmpty(index)
    return not inside[index] or not next(inside[index])
end

local function leaveZone(source, index)
    if inside[index] then inside[index][source] = nil end
    if occupied[index] == source then releaseComputer(index) end
    if isEmpty(index) then deleteComputer(index) end
end

local function spawnComputer(index)
    if objects[index] then return objects[index] end
    local computer = Config.Computers[index]
    local monitor = CreateObjectNoOffset(joaat(computer.model), computer.coords.x, computer.coords.y, computer.coords.z, true, true, false)
    local chair = CreateObjectNoOffset(joaat(computer.chair.model), computer.chair.coords.x, computer.chair.coords.y, computer.chair.coords.z, true, true, false)

    SetEntityHeading(monitor, computer.heading)
    SetEntityHeading(chair, computer.chair.heading)
    FreezeEntityPosition(monitor, true)
    FreezeEntityPosition(chair, true)
    SetEntityOrphanMode(monitor, 2)
    SetEntityOrphanMode(chair, 2)

    objects[index] = { monitor = NetworkGetNetworkIdFromEntity(monitor), chair = NetworkGetNetworkIdFromEntity(chair) }
    return objects[index]
end

RegisterNetEvent('fixlife_facciones:server:enterZone', function(index)
    if type(index) ~= 'number' or not Config.Computers[index] then return end
    inside[index] = inside[index] or {}
    inside[index][source] = true
    TriggerClientEvent('fixlife_facciones:client:objects', source, { [index] = spawnComputer(index) })
end)

RegisterNetEvent('fixlife_facciones:server:exitZone', function(index)
    if type(index) ~= 'number' or not Config.Computers[index] then return end
    leaveZone(source, index)
end)

RegisterNetEvent('fixlife_facciones:server:use', function(index)
    if type(index) ~= 'number' or not Config.Computers[index] then return end
    if not inside[index] or not inside[index][source] or not objects[index] then return end
    if occupied[index] then
        TriggerClientEvent('fixlife_facciones:client:denied', source)
        return
    end
    FreezeEntityPosition(NetworkGetEntityFromNetworkId(objects[index].chair), false)
    occupied[index] = source
    TriggerClientEvent('fixlife_facciones:client:start', source, index)
end)

RegisterNetEvent('fixlife_facciones:server:release', function(index)
    if occupied[index] ~= source then return end
    releaseComputer(index)
end)

AddEventHandler('playerDropped', function()
    for index in pairs(Config.Computers) do
        leaveZone(source, index)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for index = 1, #Config.Computers do deleteComputer(index) end
end)
