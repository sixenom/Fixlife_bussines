local objects, occupied, inside = {}, {}, {}

local function hasAccess(src, index)
    local player = exports.qbx_core:GetPlayer(src)
    local job = player and player.PlayerData.job
    return job and job.isboss == true
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
    local _, job = getManager(src, index)
    local target = exports.qbx_core:GetPlayerByCitizenId(tostring(citizenid or '')) or exports.qbx_core:GetOfflinePlayer(tostring(citizenid or ''))
    if not job or not target or target.PlayerData.job.name ~= job.name or tostring(plate or '') == '' then return false end
    return MySQL.update.await('UPDATE player_vehicles SET citizenid = ? WHERE plate = ? AND job_personalowned = ?', {
        target.PlayerData.citizenid, plate, job.name
    }) > 0
end)

lib.callback.register('fixlife_facciones:server:vehicleModel', function(src, index, plate, model)
    local _, job = getManager(src, index)
    model = tostring(model or ''):lower()
    if not job or #model < 2 or #model > 50 or not model:match('^[%w_]+$') then return false end
    return MySQL.update.await('UPDATE player_vehicles SET vehicle = ?, hash = ? WHERE plate = ? AND job_personalowned = ?', {
        model, joaat(model), plate, job.name
    }) > 0
end)

lib.callback.register('fixlife_facciones:server:vehicleState', function(src, index, plate, state)
    local _, job = getManager(src, index)
    state = tonumber(state)
    if not job or (state ~= 0 and state ~= 1) then return false end
    return MySQL.update.await('UPDATE player_vehicles SET in_garage = ? WHERE plate = ? AND job_personalowned = ?', {
        state, plate, job.name
    }) > 0
end)

lib.callback.register('fixlife_facciones:server:dashboard', function(src, index)
    local _, job = getManager(src, index)
    if not job then return { ok = false } end
    local vehicleCount = MySQL.scalar.await('SELECT COUNT(*) FROM player_vehicles WHERE job_personalowned = ?', { job.name }) or 0
    local balance = 0
    if GetResourceState('Fixlife_banking') == 'started' then
        exports['Fixlife_banking']:CreateJobAccount(job)
        balance = exports['Fixlife_banking']:getAccountMoney(job.name) or 0
    end
    return { ok = true, members = #getMembers(job.name), vehicles = vehicleCount, balance = balance }
end)

lib.callback.register('fixlife_facciones:server:finance', function(src, index)
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

lib.callback.register('fixlife_facciones:server:financeDeposit', function(src, index, amount)
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

local function releaseComputer(index)
    local entity = NetworkGetEntityFromNetworkId(objects[index].chair)
    if entity ~= 0 then
        SetEntityHeading(entity, Config.Computers[index].chair.heading)
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

RegisterNetEvent('fixlife_facciones:server:useComputer', function(index)
    if type(index) ~= 'number' or not Config.Computers[index] then return end
    if occupied[index] ~= source or not hasAccess(source, index) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'No tienes el rango necesario para usar este computador.'
        })
        return
    end
    TriggerClientEvent('fixlife_facciones:client:useComputer', source, index)
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
