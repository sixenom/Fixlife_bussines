local computers = {}
local activeComputer
local seated = false
local usingComputer = false
local entering = false
local exiting = false
local variantIndex = 1
local variants = { 'base', 'idle_a', 'idle_b', 'idle_c', 'idle_d', 'idle_e' }

local function loadDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
end

local function playVariant()
    if not seated or usingComputer or exiting then return end

    local computer = computers[activeComputer]
    local clip = variants[variantIndex]
    Chairs.stop()
    Chairs.play(computer, PlayerPedId(), clip, clip .. '_chair', true)
end

local function startComputer()
    if not seated or usingComputer or exiting then return end

    local computer = computers[activeComputer]
    local index = activeComputer
    local entry = computer.entry
    usingComputer = true
    Chairs.stop()
    Chairs.play(computer, PlayerPedId(), entry.computerIdleClip, entry.computerIdleChairClip, true)
    CreateThread(function()
        Wait(2000)
        if usingComputer and activeComputer == index then
            SendNUIMessage({ action = 'openLogin', label = computer.label, login = computer.login or {} })
            SetNuiFocus(true, true)
        end
    end)
end

local function useComputer()
    if not seated or usingComputer or exiting then return end
    TriggerServerEvent('fixlife_facciones:server:useComputer', activeComputer)
end

local function drawText(coords, text)
    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextCentre(true)
    SetTextColour(255, 255, 255, 220)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(coords.x, coords.y)
end

local function leaveChair()
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    Chairs.stop()
    if activeComputer then
        SetEntityCollision(computers[activeComputer].chairObject, true, true)
        TriggerServerEvent('fixlife_facciones:server:release', activeComputer)
    end
    ClearPedTasks(PlayerPedId())
    activeComputer = nil
    seated = false
    usingComputer = false
    entering = false
    exiting = false
end

local function clearComputer(index)
    if activeComputer == index then
        SendNUIMessage({ action = 'close' })
        SetNuiFocus(false, false)
        Chairs.stop()
        ClearPedTasks(PlayerPedId())
        activeComputer = nil
        seated = false
        usingComputer = false
        entering = false
        exiting = false
    end

    local computer = computers[index]
    if computer and computer.targetsAdded then
        exports.ox_target:removeEntity(computer.chairNetId, ('fixlife_facciones:chair:%s'):format(index))
        computer.targetsAdded = nil
    end
    if computer then
        computer.monitorNetId = nil
        computer.chairNetId = nil
        computer.chairObject = nil
    end
end

local function exitComputer()
    if not usingComputer or exiting then return end

    local computer = computers[activeComputer]
    local index = activeComputer
    local entry = computer.entry
    exiting = true
    usingComputer = false
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    Chairs.stop()
    local duration = Chairs.play(computer, PlayerPedId(), entry.computerExitClip, entry.computerExitChairClip)

    CreateThread(function()
        Wait(duration)
        if seated and activeComputer == index then
            exiting = false
            playVariant()
        end
    end)
end

local function exitChair()
    if exiting or not seated then return end

    exiting = true
    local index = activeComputer
    local computer = computers[index]
    local entry = computer.entry
    Chairs.stop()
    ClearPedTasks(PlayerPedId())
    local duration = Chairs.play(computer, PlayerPedId(), entry.exitClip, entry.exitChairClip)

    CreateThread(function()
        Wait(duration)
        Chairs.stop()
        SetEntityCollision(computer.chairObject, true, true)
        FreezeEntityPosition(computer.chairObject, true)
        TriggerServerEvent('fixlife_facciones:server:release', index)
        activeComputer = nil
        seated = false
        usingComputer = false
        exiting = false
    end)
end

RegisterNUICallback('close', function(_, callback)
    exitComputer()
    callback({ ok = true })
end)

RegisterNUICallback('members', function(_, callback)
    callback(lib.callback.await('fixlife_facciones:server:members', false, activeComputer))
end)

RegisterNUICallback('vehicles', function(_, callback)
    callback(lib.callback.await('fixlife_facciones:server:vehicles', false, activeComputer))
end)

RegisterNUICallback('vehicleOwner', function(data, callback)
    callback({ ok = lib.callback.await('fixlife_facciones:server:vehicleOwner', false, activeComputer, data.plate, data.citizenid) })
end)

RegisterNUICallback('vehicleModel', function(data, callback)
    callback({ ok = lib.callback.await('fixlife_facciones:server:vehicleModel', false, activeComputer, data.plate, data.model) })
end)

RegisterNUICallback('vehicleState', function(data, callback)
    callback({ ok = lib.callback.await('fixlife_facciones:server:vehicleState', false, activeComputer, data.plate, data.state) })
end)

RegisterNUICallback('dashboard', function(_, callback)
    callback(lib.callback.await('fixlife_facciones:server:dashboard', false, activeComputer))
end)

RegisterNUICallback('finance', function(_, callback)
    callback(lib.callback.await('fixlife_facciones:server:finance', false, activeComputer))
end)

RegisterNUICallback('financeDeposit', function(data, callback)
    callback({ ok = lib.callback.await('fixlife_facciones:server:financeDeposit', false, activeComputer, data.amount) })
end)

RegisterNUICallback('memberAction', function(data, callback)
    callback({ ok = lib.callback.await('fixlife_facciones:server:memberAction', false, activeComputer, data.action, data.target, data.value) })
end)

local function sitInChair(index)
    local computer = computers[index]
    entering = true
    computer.chairObject = NetToObj(computer.chairNetId)
    if computer.chairObject == 0 then
        entering = false
        activeComputer = nil
        TriggerServerEvent('fixlife_facciones:server:release', index)
        return
    end

    local timeout = GetGameTimer() + 500
    NetworkRequestControlOfEntity(computer.chairObject)
    while not NetworkHasControlOfEntity(computer.chairObject) and GetGameTimer() < timeout do Wait(0) end
    if not NetworkHasControlOfEntity(computer.chairObject) then
        entering = false
        activeComputer = nil
        TriggerServerEvent('fixlife_facciones:server:release', index)
        return
    end

    local ped = PlayerPedId()
    local entry = computer.entry
    loadDict(entry.dict)
    Chairs.prepareEntry(computer, ped)
    FreezeEntityPosition(computer.chairObject, false)
    SetEntityCollision(computer.chairObject, false, false)
    local duration = Chairs.play(computer, ped, entry.pedClip, entry.chairClip)

    Wait(math.max(1000, duration))
    seated = true
    entering = false
    variantIndex = 1
    playVariant()
end

local function addTargets(index, ids)
    local computer = computers[index]
    if computer.targetsAdded then return end

    CreateThread(function()
        local timeout = GetGameTimer() + 5000
        while not NetworkDoesEntityExistWithNetworkId(ids.chair) and GetGameTimer() < timeout do Wait(0) end
        if computer.targetsAdded or computer.chairNetId ~= ids.chair or not NetworkDoesEntityExistWithNetworkId(ids.chair) then return end

        computer.targetsAdded = true
        exports.ox_target:addEntity(ids.chair, {
            {
                name = ('fixlife_facciones:chair:%s'):format(index),
                icon = 'fa-solid fa-chair',
                label = 'Sentarse',
                distance = 1.5,
                canInteract = function()
                    return not seated and not entering and not exiting
                end,
                onSelect = function()
                    TriggerServerEvent('fixlife_facciones:server:use', index)
                end
            }
        })
    end)
end

RegisterNetEvent('fixlife_facciones:client:objects', function(networkObjects)
    for index, ids in pairs(networkObjects) do
        if computers[index] then
            computers[index].monitorNetId = ids.monitor
            computers[index].chairNetId = ids.chair
            addTargets(index, ids)
        end
    end
end)

RegisterNetEvent('fixlife_facciones:client:start', function(index)
    activeComputer = index
    sitInChair(index)
end)

RegisterNetEvent('fixlife_facciones:client:useComputer', function(index)
    if activeComputer == index then startComputer() end
end)

RegisterNetEvent('fixlife_facciones:client:denied', function()
    activeComputer = nil
    entering = false
end)

CreateThread(function()
    while true do
        if seated then
            DisableControlAction(0, 73, true)

            if IsDisabledControlJustReleased(0, 73) then
                if usingComputer then exitComputer() else exitChair() end
            elseif not usingComputer and not exiting then
                local computer = computers[activeComputer]
                local monitor = NetToObj(computer.monitorNetId)
                if monitor ~= 0 then
                    local coords = GetEntityCoords(monitor)
                    local onScreen, x, y = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z + 0.15)
                    if onScreen then drawText(vec2(x, y), '[E] Usar computador') end
                    if IsControlJustReleased(0, 38) then useComputer() end
                end
                if IsControlJustReleased(0, 174) then
                    variantIndex = variantIndex == 1 and #variants or variantIndex - 1
                    playVariant()
                elseif IsControlJustReleased(0, 175) then
                    variantIndex = variantIndex == #variants and 1 or variantIndex + 1
                    playVariant()
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    for i, computer in ipairs(Config.Computers) do
        computers[i] = computer
        local zone = computer.zone
        if zone then
            local index = i
            lib.zones.poly({
                name = zone.name,
                points = zone.points,
                thickness = zone.thickness,
                onEnter = function()
                    TriggerServerEvent('fixlife_facciones:server:enterZone', index)
                end,
                onExit = function()
                    clearComputer(index)
                    TriggerServerEvent('fixlife_facciones:server:exitZone', index)
                end
            })
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    leaveChair()
end)
