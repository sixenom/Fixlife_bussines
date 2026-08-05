local computers = {}
local activeComputer
local seated = false
local usingComputer = false
local entering = false
local exiting = false
local controlsActive = false
local variantIndex = 1
local variants = { 'base', 'idle_a', 'idle_b', 'idle_c', 'idle_d', 'idle_e' }
local managementPreview
local zones = {}
local addTargets

local function applyManagementType(computer, pointType)
    local typeConfig = Config.ManagementTypes[pointType]
    computer.type = pointType
    computer.model = typeConfig and typeConfig.model
    computer.entry = typeConfig and typeConfig.entry
    computer.chair = computer.chair or {}
    if typeConfig and typeConfig.chair then computer.chair.model = typeConfig.chair.model end
end

local function deleteManagementPreview()
    if managementPreview and DoesEntityExist(managementPreview) then DeleteEntity(managementPreview) end
    managementPreview = nil
end

local function selectManagementObject(index)
    local selectedEntity
    local hit, entity, coords
    lib.showTextUI('[Enter] Seleccionar objeto  |  [Backspace] Cancelar')

    CreateThread(function()
        while selectedEntity ~= false do
            hit, entity, coords = lib.raycast.fromCamera(511, 4, 30.0)
            Wait(1)
        end
    end)

    selectedEntity = nil
    while selectedEntity ~= false do
        Wait(0)
        SetPauseMenuActive(false)
        if hit and entity and entity ~= 0 and GetEntityType(entity) == 3 then
            if selectedEntity and selectedEntity ~= entity then SetEntityDrawOutline(selectedEntity, false) end
            selectedEntity = entity
            SetEntityDrawOutline(entity, true)
            if IsControlJustPressed(0, 191) then
                local objectCoords = GetEntityCoords(entity)
                local point = {
                    x = objectCoords.x, y = objectCoords.y, z = objectCoords.z,
                    heading = GetEntityHeading(entity), model = GetEntityModel(entity), type = 'object'
                }
                SetEntityDrawOutline(entity, false)
                selectedEntity = false
                lib.hideTextUI()
                return lib.callback.await('fixlife_facciones:server:saveManagementPoint', false, index, point) == true
            end
        elseif selectedEntity then
            SetEntityDrawOutline(selectedEntity, false)
            selectedEntity = nil
        end

        if IsControlJustPressed(0, 177) then
            if selectedEntity then SetEntityDrawOutline(selectedEntity, false) end
            selectedEntity = false
            lib.hideTextUI()
            return false
        end
    end
end

local function placeManagementPoint(index, pointType)
    local computer = computers[index]
    if not computer then return end

    if pointType == 'object' then return selectManagementObject(index) end

    local model = Config.ManagementTypes[pointType].model
    local hash = joaat(model)
    lib.requestModel(hash)
    local heading = GetEntityHeading(PlayerPedId())
    local hit, coords
    managementPreview = true

    CreateThread(function()
        while managementPreview do
            hit, _, coords = lib.raycast.fromCamera(511, 4, 30.0)
            Wait(1)
        end
    end)

    lib.showTextUI('[Rueda] Rotar  |  [Enter] Colocar  |  [Backspace] Cancelar')
    while managementPreview do
        Wait(0)
        SetPauseMenuActive(false)
        DisableControlAction(0, 14, true)
        DisableControlAction(0, 15, true)

        if hit and coords then
            if type(managementPreview) == 'boolean' then
                managementPreview = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, false)
                SetEntityAlpha(managementPreview, 150, false)
                FreezeEntityPosition(managementPreview, true)
                SetEntityCollision(managementPreview, false, true)
                SetEntityDrawOutline(managementPreview, true)
            else
                SetEntityCoordsNoOffset(managementPreview, coords.x, coords.y, coords.z, false, false, false)
            end

            SetEntityHeading(managementPreview, heading)
            if pointType == 'laptop' then PlaceObjectOnGroundProperly(managementPreview) end

            if IsDisabledControlPressed(0, 15) then
                heading = heading + 5.0
            elseif IsDisabledControlPressed(0, 14) then
                heading = heading - 5.0
            elseif IsControlJustPressed(0, 191) then
                local finalCoords = GetEntityCoords(managementPreview)
                local result = lib.callback.await('fixlife_facciones:server:saveManagementPoint', false, index, {
                    x = finalCoords.x, y = finalCoords.y, z = finalCoords.z, heading = GetEntityHeading(managementPreview), type = pointType
                })
                deleteManagementPreview()
                lib.hideTextUI()
                SetModelAsNoLongerNeeded(hash)
                return result == true
            elseif IsControlJustPressed(0, 177) then
                deleteManagementPreview()
                lib.hideTextUI()
                SetModelAsNoLongerNeeded(hash)
                return false
            end
        end
    end

    lib.hideTextUI()
    SetModelAsNoLongerNeeded(hash)
    return false
end

local function loadDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
end

local purchasePoints = {}
local purchaseTextPoints = {}

local function addMembershipPurchaseTarget(index, point)
    if purchaseTextPoints[index] then
        TriggerEvent('Fix_3dTextUi:eliminar', purchaseTextPoints[index])
        purchaseTextPoints[index] = nil
    end
    purchasePoints[index] = type(point) == 'table' and point or nil
    if not purchasePoints[index] then return end
    local organization = computers[index]
    local gymId = organization and organization.purchaseGymId
    if not gymId then return end
    local pointId = ('fixlife_gym:purchase:%s'):format(index)
    TriggerEvent('Fix_3dTextUi:crear', pointId, vec3(point.x, point.y, point.z+0.8), 5.0, 1.0, 1.0, '#00D3FC', {
        {key = 'E', text = 'Comprar membresia', event = 'fixlife_gym:openPurchaseMenu', args = {gymId}}
    }, nil, 'image', 'bicep.svg')
    purchaseTextPoints[index] = pointId
end

local function placeMembershipPurchasePoint(index)
    local hit, coords
    local placing = true
    CreateThread(function()
        while placing do
            hit, _, coords = lib.raycast.fromCamera(511, 4, 30.0)
            Wait(1)
        end
    end)
    lib.showTextUI('[Enter] Colocar punto de compra  |  [Backspace] Cancelar')
    while placing do
        Wait(0)
        SetPauseMenuActive(false)
        if hit and coords then
            DrawMarker(2, coords.x, coords.y, coords.z + 0.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 0.25, 87, 60, 250, 180, false, true, 2, false, nil, nil, false)
            if IsControlJustReleased(0, 191) then
                placing = false
                lib.hideTextUI()
                return lib.callback.await('fixlife_facciones:server:saveMembershipPurchasePoint', false, index, {
                    x = coords.x, y = coords.y, z = coords.z, heading = GetEntityHeading(PlayerPedId())
                }) == true
            end
        end
        if IsControlJustReleased(0, 177) then
            placing = false
            lib.hideTextUI()
            return false
        end
    end
    lib.hideTextUI()
    return false
end

local function playVariant()
    if not seated or usingComputer or exiting then return end

    local computer = computers[activeComputer]
    local clip = variants[variantIndex]
    Chairs.stop()
    Chairs.play(computer, PlayerPedId(), clip, clip .. '_chair', true)
end

local function startComputer()
    local computer = computers[activeComputer]
    if not computer or usingComputer or exiting then return end
    local index = activeComputer
    if computer.type ~= 'laptop' then
        usingComputer = true
        SendNUIMessage({ action = 'openLogin', label = computer.label, login = computer.login or {}, features = computer.features or {} })
        SetNuiFocus(true, true)
        return
    end
    if not seated then return end
    local entry = computer.entry
    usingComputer = true
    Chairs.stop()
    Chairs.play(computer, PlayerPedId(), entry.computerIdleClip, entry.computerIdleChairClip, true)
    CreateThread(function()
        Wait(2000)
        if usingComputer and activeComputer == index then
            SendNUIMessage({ action = 'openLogin', label = computer.label, login = computer.login or {}, features = computer.features or {} })
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
    controlsActive = false
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    Chairs.stop()
    if activeComputer then
        local computer = computers[activeComputer]
        if computer.chairObject and computer.chair.coords then
            SetEntityCoordsNoOffset(computer.chairObject, computer.chair.coords.x, computer.chair.coords.y, computer.chair.coords.z, false, false, false)
            SetEntityHeading(computer.chairObject, computer.chair.heading)
            FreezeEntityPosition(computer.chairObject, true)
            SetEntityCollision(computer.chairObject, true, true)
        end
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
        controlsActive = false
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
        if computer.targetZoneId then
            exports.ox_target:removeZone(computer.targetZoneId)
        else
            exports.ox_target:removeEntity(computer.targetNetId, ('fixlife_facciones:chair:%s'):format(index))
        end
        computer.targetsAdded = nil
    end
    if computer then
        computer.monitorNetId = nil
        computer.chairNetId = nil
        computer.targetNetId = nil
        computer.targetZoneId = nil
        computer.chairObject = nil
    end
end

local function exitComputer()
    if not usingComputer or exiting then return end

    local computer = computers[activeComputer]
    local index = activeComputer
    if computer.type ~= 'laptop' then
        SendNUIMessage({ action = 'close' })
        SetNuiFocus(false, false)
        usingComputer = false
        TriggerServerEvent('fixlife_facciones:server:release', index)
        activeComputer = nil
        return
    end
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

    controlsActive = false
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

local function startControls()
    if controlsActive then return end
    controlsActive = true

    CreateThread(function()
        while controlsActive do
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
        end
    end)
end

RegisterNUICallback('close', function(_, callback)
    exitComputer()
    callback({ ok = true })
end)

RegisterNUICallback('gymData', function(_, callback)
    callback(lib.callback.await('fixlife_facciones:server:gymData', false, activeComputer))
end)

RegisterNUICallback('gymMembershipAction', function(data, callback)
    callback({ ok = lib.callback.await('fixlife_facciones:server:gymMembershipAction', false, activeComputer, data.action, data.identifier, data.expires) == true })
end)

RegisterNUICallback('updateGymPlan', function(data, callback)
    callback({ ok = lib.callback.await('fixlife_facciones:server:updateGymPlan', false, activeComputer, data.durationHours, data.price) == true })
end)

RegisterNUICallback('addGymMachine', function(data, callback)
        local ok = lib.callback.await('fixlife_facciones:server:openGymCreator', false, activeComputer, data.type) == true
    if ok then
        exitComputer()
        SendNUIMessage({ action = 'hidePanel' })
        SetNuiFocus(false, false)
    end
    callback({ ok = ok })
end)

RegisterNUICallback('removeGymMachine', function(data, callback)
    callback({ ok = lib.callback.await('fixlife_facciones:server:removeGymMachine', false, activeComputer, data.id) == true })
end)

RegisterNUICallback('editGymMachine', function(data, callback)
    local ok = lib.callback.await('fixlife_facciones:server:editGymMachine', false, activeComputer, data.id) == true
    if ok then
        exitComputer()
        SendNUIMessage({ action = 'hidePanel' })
        SetNuiFocus(false, false)
    end
    callback({ ok = ok })
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

RegisterNUICallback('saveManagementPoint', function(data, callback)
    local index = activeComputer
    leaveChair()
    SendNUIMessage({ action = 'hidePanel' })
    SetNuiFocus(false, false)
    local pointType = data.type == 'tablet' and 'tablet' or data.type == 'object' and 'object' or 'laptop'
    local ok = placeManagementPoint(index, pointType)
    SetNuiFocus(false, false)
    callback({ ok = ok })
end)

RegisterNUICallback('saveMembershipPurchasePoint', function(_, callback)
    local index = activeComputer
    leaveChair()
    SendNUIMessage({ action = 'hidePanel' })
    SetNuiFocus(false, false)
    callback({ ok = placeMembershipPurchasePoint(index) })
end)

local function createManagementZone(index)
    local computer = computers[index]
    local zone = computer and computer.zone
    if not zone then return end
    if zones[index] then zones[index]:remove() end
    zones[index] = lib.zones.poly({
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

RegisterNetEvent('fixlife_facciones:client:managementPointUpdated', function(index, point)
    local computer = computers[index]
    if not computer or type(point) ~= 'table' then return end
    local nextType = point.type or 'laptop'
    if computer.type ~= nextType and computer.targetsAdded then
        if computer.targetZoneId then
            exports.ox_target:removeZone(computer.targetZoneId)
        else
            exports.ox_target:removeEntity(computer.targetNetId, ('fixlife_facciones:chair:%s'):format(index))
        end
        computer.targetsAdded = nil
        computer.targetNetId = nil
        computer.targetZoneId = nil
    end
    if nextType == 'object' and computer.targetZoneId then
        exports.ox_target:removeZone(computer.targetZoneId)
        computer.targetsAdded = nil
        computer.targetZoneId = nil
    end

    local objectsToMove = { {netId = computer.monitorNetId, coords = point, heading = point.heading} }
    if point.chair then objectsToMove[#objectsToMove + 1] = {netId = computer.chairNetId, coords = point.chair, heading = point.chair.heading} end
    for _, objectData in ipairs(objectsToMove) do
        local entity = objectData.netId and NetToObj(objectData.netId)
        if entity and entity ~= 0 then
            NetworkRequestControlOfEntity(entity)
            SetEntityCoordsNoOffset(entity, objectData.coords.x, objectData.coords.y, objectData.coords.z, false, false, false)
            SetEntityHeading(entity, objectData.heading)
            FreezeEntityPosition(entity, true)
        end
    end

    computer.coords = vec3(point.x, point.y, point.z)
    computer.heading = point.heading
    applyManagementType(computer, nextType)
    computer.objectModel = point.model
    if point.chair then
        computer.chair.coords = vec3(point.chair.x, point.chair.y, point.chair.z)
        computer.chair.heading = point.chair.heading
    end
    computer.zone.points = point.zone
    createManagementZone(index)
    if nextType == 'object' then addTargets(index, {}) end
end)

RegisterNetEvent('fixlife_facciones:client:membershipPurchasePointUpdated', function(index, point)
    addMembershipPurchaseTarget(index, point)
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
    startControls()
    entering = false
    variantIndex = 1
    playVariant()
end

addTargets = function(index, ids)
    local computer = computers[index]
    if computer.targetsAdded then return end
    if computer.type == 'object' then
        computer.targetsAdded = true
        computer.targetZoneId = exports.ox_target:addSphereZone({
            coords = computer.coords,
            radius = 1.25,
            options = {
                {
                    name = ('fixlife_facciones:chair:%s'):format(index),
                    icon = 'fa-solid fa-hand-pointer',
                    label = 'Gestionar',
                    onSelect = function() TriggerServerEvent('fixlife_facciones:server:use', index) end
                }
            }
        })
        return
    end
    local targetId = computer.type == 'tablet' and ids.monitor or ids.chair
    if not targetId then return end

    CreateThread(function()
        local timeout = GetGameTimer() + 5000
        while not NetworkDoesEntityExistWithNetworkId(targetId) and GetGameTimer() < timeout do Wait(0) end
        if computer.targetsAdded or computer.targetNetId ~= targetId or not NetworkDoesEntityExistWithNetworkId(targetId) then return end

        computer.targetsAdded = true
        computer.targetNetId = targetId
        exports.ox_target:addEntity(targetId, {
            {
                name = ('fixlife_facciones:chair:%s'):format(index),
                icon = computer.type == 'tablet' and 'fa-solid fa-tablet-screen-button' or 'fa-solid fa-chair',
                label = computer.type == 'tablet' and 'Gestionar' or 'Sentarse',
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
            if ids.point then
                computers[index].coords = vec3(ids.point.x, ids.point.y, ids.point.z)
                computers[index].heading = ids.point.heading
                applyManagementType(computers[index], ids.point.type or 'laptop')
                computers[index].objectModel = ids.point.model
                if ids.point.chair then
                    computers[index].chair.coords = vec3(ids.point.chair.x, ids.point.chair.y, ids.point.chair.z)
                    computers[index].chair.heading = ids.point.chair.heading
                end
            end
            computers[index].monitorNetId = ids.monitor
            computers[index].chairNetId = ids.chair
            computers[index].targetNetId = computers[index].type == 'tablet' and ids.monitor or ids.chair
            addTargets(index, ids)
        end
    end
end)

RegisterNetEvent('fixlife_facciones:client:adminCreatePoint', function(index, pointType)
    computers[index] = computers[index] or Config.Organizations[index]
    if not computers[index] then return end
    applyManagementType(computers[index], pointType)
    local ok = placeManagementPoint(index, pointType)
    lib.notify({ type = ok and 'success' or 'error', description = ok and 'Punto de gestion guardado.' or 'Creacion cancelada o no valida.' })
end)

RegisterNetEvent('fixlife_facciones:client:start', function(index)
    activeComputer = index
    if computers[index] and computers[index].type ~= 'laptop' then
        TriggerServerEvent('fixlife_facciones:server:useComputer', index)
    else
        sitInChair(index)
    end
end)

RegisterNetEvent('fixlife_facciones:client:useComputer', function(index, features)
    if computers[index] then computers[index].features = features or {} end
    if activeComputer == index then startComputer() end
end)


RegisterNetEvent('fixlife_facciones:client:denied', function()
    activeComputer = nil
    entering = false
end)

CreateThread(function()
    for organization, computer in pairs(Config.Organizations) do
        computers[organization] = computer
        local zone = computer.zone
        if zone then
            local index = organization
            createManagementZone(index)
        end
    end
    local purchasePoints = lib.callback.await('fixlife_facciones:server:purchasePoints', false) or {}
    for index, point in pairs(purchasePoints) do addMembershipPurchaseTarget(index, point) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    deleteManagementPreview()
    leaveChair()
end)
