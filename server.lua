local objects, occupied, inside = {}, {}, {}
local deleteComputer, spawnComputer
local pointFile = json.decode(LoadResourceFile(GetCurrentResourceName(), 'data/points.json') or '{}') or {}
local savedPoints = pointFile.management or (pointFile.purchase and {} or pointFile)
local savedPurchasePoints = pointFile.purchase or json.decode(LoadResourceFile(GetCurrentResourceName(), 'data/purchase_points.json') or '{}') or {}
local needsPointMigration = not pointFile.management or pointFile.purchase == nil

local function savePoints()
    SaveResourceFile(GetCurrentResourceName(), 'data/points.json', json.encode({
        management = savedPoints,
        purchase = savedPurchasePoints
    }), -1)
end

if needsPointMigration then savePoints() end

local function applyManagementPoint(computer, point)
    local heading = point.heading or 0.0
    computer.type = point.type == 'tablet' and 'tablet' or point.type == 'object' and 'object' or 'laptop'
    computer.objectModel = tonumber(point.model)
    local typeConfig = Config.ManagementTypes[computer.type]
    if typeConfig then
        computer.model = typeConfig.model
        computer.entry = typeConfig.entry
        computer.chair = computer.chair or {}
        computer.chair.model = typeConfig.chair and typeConfig.chair.model
    end
    local angle = math.rad(heading)
    local offsetX, offsetY = -0.1908, -1.05
    local chairX = point.x + offsetX * math.cos(angle) - offsetY * math.sin(angle)
    local chairY = point.y + offsetX * math.sin(angle) + offsetY * math.cos(angle)

    computer.coords = vec3(point.x, point.y, point.z)
    computer.heading = heading
    if computer.type == 'laptop' then
        computer.chair.coords = vec3(chairX, chairY, point.z - 0.2)
        computer.chair.heading = heading + 140.0
    end
end

local function getManagementPoint(index)
    local computer = Config.Organizations[index]
    local point = { x = computer.coords.x, y = computer.coords.y, z = computer.coords.z, heading = computer.heading, type = computer.type, model = computer.objectModel }
    if computer.type == 'laptop' then
        point.chair = { x = computer.chair.coords.x, y = computer.chair.coords.y, z = computer.chair.coords.z, heading = computer.chair.heading }
    end
    return point
end

for organization, point in pairs(savedPoints) do
    local pointConfig = Config.Organizations[organization]
    if pointConfig then
        applyManagementPoint(pointConfig, point)
    end
end

local function getComputer(index)
    return type(index) == 'string' and Config.Organizations[index]
end

local function getOrganization(index)
    return getComputer(index)
end

local function hasFeature(index, feature)
    if feature == 'settings' then return getOrganization(index) ~= nil end
    local organization = getOrganization(index)
    return organization and organization.features and organization.features[feature] == true
end

local function isAdmin(src)
    return src == 0 or IsPlayerAceAllowed(src, 'group.admin')
end

local function isInsideZone(index, x, y, z)
    local computer = getComputer(index)
    local zone = computer and computer.zone
    local points = zone and zone.points or {}
    if #points < 3 then return false end

    local inside = false
    local j = #points
    for i = 1, #points do
        local a, b = points[i], points[j]
        if ((a.y > y) ~= (b.y > y)) and x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x then
            inside = not inside
        end
        j = i
    end

    local minZ, maxZ = points[1].z, points[1].z
    for i = 2, #points do
        minZ, maxZ = math.min(minZ, points[i].z), math.max(maxZ, points[i].z)
    end
    local halfThickness = (tonumber(zone.thickness) or 0) / 2
    return inside and z >= minZ - halfThickness and z <= maxZ + halfThickness
end

local function hasAccess(src, index)
    local player = exports.qbx_core:GetPlayer(src)
    local job = player and player.PlayerData.job
    local organization = getOrganization(index)
    return job and organization and job.name == organization.job and job.isboss == true
end

local function getManager(src, index)
    local player = exports.qbx_core:GetPlayer(src)
    local job = player and player.PlayerData.job
    if not job or not job.isboss or not hasAccess(src, index) then return end
    return player, job
end

local function getMembers(jobName)
    local members = {}
    for _, member in ipairs(exports.qbx_core:GetGroupMembers(jobName, 'job') or {}) do
        local player = exports.qbx_core:GetPlayerByCitizenId(member.citizenid) or exports.qbx_core:GetOfflinePlayer(member.citizenid)
        local data = player and player.PlayerData
        if data and data.charinfo and data.job then
            members[#members + 1] = {
                id = member.citizenid,
                name = ('%s %s'):format(data.charinfo.firstname or '', data.charinfo.lastname or ''),
                grade = member.grade,
                gradeName = data.job.grade.name or ('Rango ' .. member.grade),
                online = not player.Offline,
                boss = data.job.isboss == true
            }
        end
    end
    return members
end

lib.callback.register('fixlife_facciones:server:vehicles', function(src, index)
    if not hasFeature(index, 'vehicles') then return {} end
    local _, job = getManager(src, index)
    if not job then return {} end

    local rows = MySQL.query.await([[SELECT v.citizenid, v.plate, v.vehicle, v.hash, v.in_garage,
        JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')) AS firstname,
        JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')) AS lastname
        FROM player_vehicles v LEFT JOIN players p ON p.citizenid = v.citizenid
        WHERE v.job_personalowned = ? ORDER BY v.plate]], { job.name }) or {}
    local vehicles = {}
    for _, row in ipairs(rows) do
        local props = type(row.vehicle) == 'string' and (json.decode(row.vehicle) or {}) or row.vehicle or {}
        vehicles[#vehicles + 1] = {
            plate = row.plate or 'SIN PLACA',
            model = props.model or props.hash or row.hash or row.vehicle or 'Modelo desconocido',
            type = 'Vehículo',
            owner = row.firstname and ('%s %s'):format(row.firstname, row.lastname or '') or row.citizenid or 'Desconocido',
            status = tonumber(row.in_garage) == 1 and 'En garaje' or 'Fuera de garaje'
        }
    end
    return vehicles
end)

lib.callback.register('fixlife_facciones:server:vehicleOwner', function(src, index, plate, citizenid)
    if not hasFeature(index, 'vehicles') then return false end
    local _, job = getManager(src, index)
    local target = exports.qbx_core:GetPlayerByCitizenId(tostring(citizenid or '')) or exports.qbx_core:GetOfflinePlayer(tostring(citizenid or ''))
    if not job or not target or target.PlayerData.job.name ~= job.name or tostring(plate or '') == '' then return false end
    return MySQL.update.await('UPDATE player_vehicles SET citizenid = ? WHERE plate = ? AND job_personalowned = ?', {
        target.PlayerData.citizenid, plate, job.name
    }) > 0
end)

lib.callback.register('fixlife_facciones:server:vehicleModel', function(src, index, plate, model)
    if not hasFeature(index, 'vehicles') then return false end
    local _, job = getManager(src, index)
    model = tostring(model or ''):lower()
    if not job or #model < 2 or #model > 50 or not model:match('^[%w_]+$') then return false end
    return MySQL.update.await('UPDATE player_vehicles SET vehicle = ?, hash = ? WHERE plate = ? AND job_personalowned = ?', {
        model, joaat(model), plate, job.name
    }) > 0
end)

lib.callback.register('fixlife_facciones:server:vehicleState', function(src, index, plate, state)
    if not hasFeature(index, 'vehicles') then return false end
    local _, job = getManager(src, index)
    state = tonumber(state)
    if not job or (state ~= 0 and state ~= 1) then return false end
    return MySQL.update.await('UPDATE player_vehicles SET in_garage = ? WHERE plate = ? AND job_personalowned = ?', {
        state, plate, job.name
    }) > 0
end)

lib.callback.register('fixlife_facciones:server:dashboard', function(src, index)
    if not getOrganization(index) then return { ok = false } end
    local _, job = getManager(src, index)
    if not job then return { ok = false } end
    local vehicleCount = hasFeature(index, 'vehicles') and MySQL.scalar.await('SELECT COUNT(*) FROM player_vehicles WHERE job_personalowned = ?', { job.name }) or 0
    local balance = 0
    if hasFeature(index, 'finance') and GetResourceState('Fixlife_banking') == 'started' then
        exports['Fixlife_banking']:CreateJobAccount(job)
        balance = exports['Fixlife_banking']:getAccountMoney(job.name) or 0
    end
    return { ok = true, members = hasFeature(index, 'members') and #getMembers(job.name) or 0, vehicles = vehicleCount, balance = balance }
end)

lib.callback.register('fixlife_facciones:server:gymData', function(src, index)
    if not hasFeature(index, 'gymManagement') or not getManager(src, index) then return {} end
    if GetResourceState('Fixlife_gyms') ~= 'started' then return {} end
    local ok, data = pcall(function()
        return exports['Fixlife_gyms']:getManagementData('Gym_1')
    end)
    if not ok then print(('[Fixlife_entity_manager] No se pudieron cargar los datos del gimnasio: %s'):format(data)) end
    return ok and data or {}
end)

lib.callback.register('fixlife_facciones:server:openGymCreator', function(src, index, machineType)
        if not hasFeature(index, 'gymManagement') or not getManager(src, index) then return false end
        if GetResourceState('Fixlife_gyms') ~= 'started' then return false end
        if type(machineType) ~= 'string' or machineType == '' then return false end
        TriggerClientEvent('vms_gym:custom:place', src, machineType)
        return true
    end)

lib.callback.register('fixlife_facciones:server:finance', function(src, index)
    if not hasFeature(index, 'finance') then return { ok = false, balance = 0, provider = 'Funcion no disponible' } end
    local _, job = getManager(src, index)
    if not job then return { ok = false, balance = 0, provider = 'Sin permiso' } end
    if GetResourceState('Fixlife_banking') ~= 'started' then
        return { ok = false, balance = 0, provider = 'Fixlife_banking no está iniciado' }
    end
    exports['Fixlife_banking']:CreateJobAccount(job)
    return {
        ok = true,
        balance = exports['Fixlife_banking']:getAccountMoney(job.name) or 0,
        provider = 'Cuenta ' .. job.name,
        transactions = MySQL.query.await([[SELECT type, amount, description,
            DATE_FORMAT(created_at, '%d/%m/%Y %H:%i') AS date
            FROM fixlife_banking_org_transactions WHERE account_id = ?
            ORDER BY id DESC LIMIT 20]], { job.name }) or {}
    }
end)

lib.callback.register('fixlife_facciones:server:gymMembershipAction', function(src, index, action, identifier, expires)
    if not hasFeature(index, 'gymManagement') or not getManager(src, index) then return false end
    if GetResourceState('Fixlife_gyms') ~= 'started' then return false end
    if action ~= 'revoke' and action ~= 'expiry' then return false end
    return exports['Fixlife_gyms']:updateManagementMembership(identifier, action, expires) == true
end)

lib.callback.register('fixlife_facciones:server:updateGymPlan', function(src, index, durationHours, price)
    if not hasFeature(index, 'gymManagement') or not getManager(src, index) then return false end
    if GetResourceState('Fixlife_gyms') ~= 'started' then return false end
    return exports['Fixlife_gyms']:updateMembershipPlan('Gym_1', durationHours, price) == true
end)

lib.callback.register('fixlife_facciones:server:financeDeposit', function(src, index, amount)
    if not hasFeature(index, 'finance') then return false end
    local player, job = getManager(src, index)
    amount = math.floor(tonumber(amount) or 0)
    if not player or not job or amount < 1 or amount > 100000000 then return false end
    if GetResourceState('Fixlife_banking') ~= 'started' or (player.PlayerData.money.bank or 0) < amount then return false end
    exports['Fixlife_banking']:CreateJobAccount(job)
    if not player.Functions.RemoveMoney('bank', amount, 'society-deposit') then return false end
    if exports['Fixlife_banking']:addAccountMoney(job.name, amount) then
        exports['Fixlife_banking']:handleTransaction(job.name, nil, amount, 'Recarga desde banco personal', nil, nil, 'deposit')
        return true
    end
    player.Functions.AddMoney('bank', amount, 'society-deposit-refund')
    return false
end)

lib.callback.register('fixlife_facciones:server:members', function(src, index)
    if not hasFeature(index, 'members') then return { members = {}, grades = {} } end
    local _, job = getManager(src, index)
    if not job then return { members = {}, grades = {} } end
    local grades = {}
    for level, grade in pairs(exports.qbx_core:GetJobs()[job.name].grades or {}) do
        grades[#grades + 1] = { level = tonumber(level), name = grade.name or ('Rango ' .. level) }
    end
    table.sort(grades, function(a, b) return a.level < b.level end)
    return { members = getMembers(job.name), grades = grades }
end)

lib.callback.register('fixlife_facciones:server:memberAction', function(src, index, action, target, value)
    if not hasFeature(index, 'members') then return false end
    local manager, job = getManager(src, index)
    if not manager then return false end

    if action == 'hire' then
        local targetPlayer = exports.qbx_core:GetPlayer(tonumber(target))
        if not targetPlayer then return false end
        local citizenid = targetPlayer.PlayerData.citizenid
        return exports.qbx_core:AddPlayerToJob(citizenid, job.name, 0)
            and exports.qbx_core:SetPlayerPrimaryJob(citizenid, job.name)
    end

    local targetPlayer = exports.qbx_core:GetPlayerByCitizenId(target)
    local targetData = targetPlayer and targetPlayer.PlayerData
    if not targetData or targetData.job.name ~= job.name or targetData.job.isboss then return false end

    if action == 'fire' then
        return exports.qbx_core:RemovePlayerFromJob(target, job.name)
    elseif action == 'grade' then
        local grade = tonumber(value)
        local maxGrade = manager.PlayerData.job.grade.level
        if not grade or grade < 0 or grade >= maxGrade then return false end
        return exports.qbx_core:AddPlayerToJob(target, job.name, grade)
    elseif action == 'bonus' then
        local amount = math.floor(tonumber(value) or 0)
        if amount < 1 or amount > 100000 or not targetPlayer.Functions or GetResourceState('Fixlife_banking') ~= 'started' then return false end
        exports['Fixlife_banking']:CreateJobAccount(job)
        if (exports['Fixlife_banking']:getAccountMoney(job.name) or 0) < amount then return false end
        if not exports['Fixlife_banking']:removeAccountMoney(job.name, amount) then return false end
        if targetPlayer.Functions.AddMoney('bank', amount, 'facciones-bonus') then
            local charinfo = targetData.charinfo or {}
            local targetName = ('%s %s'):format(charinfo.firstname or target, charinfo.lastname or '')
            exports['Fixlife_banking']:handleTransaction(job.name, nil, amount, ('Bono a %s'):format(targetName), nil, nil, 'withdraw')
            return true
        end
        exports['Fixlife_banking']:addAccountMoney(job.name, amount)
        return false
    end

    return false
end)

lib.callback.register('fixlife_facciones:server:saveManagementPoint', function(src, index, point)
    if not hasFeature(index, 'settings') or (not hasAccess(src, index) and not isAdmin(src)) or type(point) ~= 'table' then return false end
    local x, y, z = tonumber(point.x), tonumber(point.y), tonumber(point.z)
    local heading = tonumber(point.heading) or 0
    local pointType = point.type == 'tablet' and 'tablet' or point.type == 'object' and 'object' or 'laptop'
    if not x or not y or not z or math.abs(x) > 10000 or math.abs(y) > 10000 or z < -100 or z > 2000 then return false end
    if not isInsideZone(index, x, y, z) then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'La laptop debe colocarse dentro de la zona del negocio.'
        })
        return false
    end

    local computer = getComputer(index)
    local organization = index
    local previousType = computer.type or 'laptop'
    if pointType == 'object' and not tonumber(point.model) then return false end
    savedPoints[organization] = { x = x, y = y, z = z, heading = heading, type = pointType, model = tonumber(point.model) }
    applyManagementPoint(computer, { x = x, y = y, z = z, heading = heading, type = pointType, model = point.model })
    local pointData = getManagementPoint(index)
    pointData.zone = computer.zone.points
    local hadObjects = objects[index] ~= nil
    if previousType ~= pointType and objects[index] then
        deleteComputer(index)
    end
    local spawned = spawnComputer(index)
    savePoints()
    TriggerClientEvent('fixlife_facciones:client:managementPointUpdated', -1, index, pointData)
    if not hadObjects or previousType ~= pointType then
        for player in pairs(inside[index] or {}) do
            TriggerClientEvent('fixlife_facciones:client:objects', player, { [index] = spawned })
        end
    end
    return true
end)

lib.callback.register('fixlife_facciones:server:purchasePoints', function()
    return savedPurchasePoints
end)

lib.callback.register('fixlife_facciones:server:saveMembershipPurchasePoint', function(src, index, point)
    if not hasFeature(index, 'gymManagement') or (not hasAccess(src, index) and not isAdmin(src)) or type(point) ~= 'table' then return false end
    local x, y, z = tonumber(point.x), tonumber(point.y), tonumber(point.z)
    if not x or not y or not z or math.abs(x) > 10000 or math.abs(y) > 10000 or z < -100 or z > 2000 then return false end
    if not isInsideZone(index, x, y, z) then return false end
    savedPurchasePoints[index] = { x = x, y = y, z = z, heading = tonumber(point.heading) or 0 }
    savePoints()
    TriggerClientEvent('fixlife_facciones:client:membershipPurchasePointUpdated', -1, index, savedPurchasePoints[index])
    return true
end)

lib.addCommand('facciones', {
    help = 'Crear o cambiar el punto de gestion de una organizacion',
    restricted = 'group.admin',
    params = {
        { name = 'organizacion', help = 'Identificador de la organizacion', type = 'string' },
        { name = 'tipo', help = 'laptop, tablet u object', type = 'string' }
    }
}, function(src, args)
    if src == 0 then return end
    local organization = Config.Organizations[args.organizacion]
    local pointType = args.tipo == 'tablet' and 'tablet' or args.tipo == 'object' and 'object' or args.tipo == 'laptop' and 'laptop'
    if not organization or not pointType then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Organizacion o tipo no valido.' })
        return
    end
    TriggerClientEvent('fixlife_facciones:client:adminCreatePoint', src, args.organizacion, pointType)
end)

local function releaseComputer(index)
    if not objects[index] or not objects[index].chair then
        occupied[index] = nil
        return
    end
    local entity = NetworkGetEntityFromNetworkId(objects[index].chair)
    if entity ~= 0 then
        SetEntityHeading(entity, Config.Organizations[index].chair.heading)
        FreezeEntityPosition(entity, true)
    end
    occupied[index] = nil
end

deleteComputer = function(index)
    local computer = objects[index]
    if not computer then return end

    if computer.monitor then DeleteEntity(NetworkGetEntityFromNetworkId(computer.monitor)) end
    if computer.chair then DeleteEntity(NetworkGetEntityFromNetworkId(computer.chair)) end
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

spawnComputer = function(index)
    if objects[index] then return objects[index] end
    local computer = Config.Organizations[index]
    if not computer.coords or not computer.type then return end
    local typeConfig = Config.ManagementTypes[computer.type]
    local model = computer.model or typeConfig and typeConfig.model
    if computer.type ~= 'object' and type(model) ~= 'string' then
        print(('[Fixlife_facciones] Punto de gestion invalido para %s: falta el modelo de %s.'):format(index, computer.type))
        return
    end
    local monitor
    if computer.type ~= 'object' then
        monitor = CreateObjectNoOffset(joaat(model), computer.coords.x, computer.coords.y, computer.coords.z, true, true, false)
    end
    local chair
    if computer.type == 'laptop' and computer.chair and type(computer.chair.model) == 'string' and computer.chair.coords then
        chair = CreateObjectNoOffset(joaat(computer.chair.model), computer.chair.coords.x, computer.chair.coords.y, computer.chair.coords.z, true, true, false)
    end

    if monitor then SetEntityHeading(monitor, computer.heading) end
    if chair then SetEntityHeading(chair, computer.chair.heading) end
    if monitor then FreezeEntityPosition(monitor, true) end
    if chair then FreezeEntityPosition(chair, true) end
    if monitor then SetEntityOrphanMode(monitor, 2) end
    if chair then SetEntityOrphanMode(chair, 2) end

    objects[index] = { monitor = monitor and NetworkGetNetworkIdFromEntity(monitor) or nil, chair = chair and NetworkGetNetworkIdFromEntity(chair) or nil, point = getManagementPoint(index) }
    return objects[index]
end

RegisterNetEvent('fixlife_facciones:server:enterZone', function(index)
    if not getComputer(index) then return end
    inside[index] = inside[index] or {}
    inside[index][source] = true
    local spawned = spawnComputer(index)
    if spawned then TriggerClientEvent('fixlife_facciones:client:objects', source, { [index] = spawned }) end
end)

RegisterNetEvent('fixlife_facciones:server:exitZone', function(index)
    if not getComputer(index) then return end
    leaveZone(source, index)
end)

RegisterNetEvent('fixlife_facciones:server:use', function(index)
    if not getComputer(index) then return end
    if not inside[index] or not inside[index][source] or not objects[index] then return end
    if occupied[index] then
        TriggerClientEvent('fixlife_facciones:client:denied', source)
        return
    end
    if objects[index].chair then
        FreezeEntityPosition(NetworkGetEntityFromNetworkId(objects[index].chair), false)
    end
    occupied[index] = source
    TriggerClientEvent('fixlife_facciones:client:start', source, index)
end)

RegisterNetEvent('fixlife_facciones:server:useComputer', function(index)
    if not getComputer(index) then return end
    if occupied[index] ~= source or not hasAccess(source, index) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'No tienes el rango necesario para usar este computador.'
        })
        return
    end
    local organization = getOrganization(index)
    organization.features.settings = true
    TriggerClientEvent('fixlife_facciones:client:useComputer', source, index, organization.features)
end)

RegisterNetEvent('fixlife_facciones:server:release', function(index)
    if occupied[index] ~= source then return end
    releaseComputer(index)
end)

AddEventHandler('playerDropped', function()
    for index in pairs(Config.Organizations) do
        leaveZone(source, index)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for index in pairs(Config.Organizations) do deleteComputer(index) end
end)
