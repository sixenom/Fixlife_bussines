Chairs = {}

local activeScene

function Chairs.stop()
    if activeScene then NetworkStopSynchronisedScene(activeScene) end
    activeScene = nil
end

function Chairs.prepareEntry(computer, ped)
    local entry = computer.entry
    local coords = GetEntityCoords(computer.chairObject)
    local heading = GetEntityHeading(computer.chairObject)
    local pedStart = GetAnimInitialOffsetPosition(entry.dict, entry.pedClip, coords.x, coords.y, coords.z, 0.0, 0.0, heading, 0.0, 2)
    local rotation = GetAnimInitialOffsetRotation(entry.dict, entry.pedClip, coords.x, coords.y, coords.z, 0.0, 0.0, heading, 0.0, 2)

    SetEntityCoordsNoOffset(ped, pedStart.x, pedStart.y, pedStart.z, false, false, false)
    SetEntityHeading(ped, rotation.z)
end

function Chairs.play(computer, ped, pedClip, chairClip, looped)
    local entry = computer.entry
    local coords = GetEntityCoords(computer.chairObject)
    local heading = GetEntityHeading(computer.chairObject)
    local scene = NetworkCreateSynchronisedScene(coords.x, coords.y, coords.z, 0.0, 0.0, heading, 2, not looped, looped or false, 1065353216, 0.0, 1.0)

    NetworkAddPedToSynchronisedScene(ped, scene, entry.dict, pedClip, 4.0, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(computer.chairObject, scene, entry.dict, chairClip, 4.0, -8.0, 1)
    NetworkStartSynchronisedScene(scene)
    activeScene = scene

    return math.max(1, math.ceil(GetAnimDuration(entry.dict, pedClip) * 1000))
end
