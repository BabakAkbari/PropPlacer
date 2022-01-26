Zone = {}
ObjDictionary = {}
InvObjDictionary = {}
ZoneNumber = 0
PlayerId = PlayerId()
PlayerServerId = GetPlayerServerId(PlayerId)
math.randomseed(GetGameTimer())

RegisterCommand('place', function(source, args)
    local model = args[1]
    local player = PlayerPedId()
    local playercord = GetEntityCoords(player)
    if not IsModelInCdimage(model) then
        TriggerEvent('chat:addMessage', {
            args = {'[Error]: No Such Model'}
        })
        return
    end
    RequestModel(model)
    Citizen.CreateThread(function()
        while not HasModelLoaded(model) do
            Citizen.Wait(0)
        end
    end)
    local entity = CreateObject(model, coords, false, false, false)
    ObjDictionary[entity] = entity
    InvObjDictionary[entity] = entity
    SetObjectPhysicsParams(entity, 1.0, 1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0)
    ActivatePhysics(entity)
    SetEntityHasGravity(entity, true)
    local EntityPos = GetEntityCoords(entity)
    local EntityRot = GetEntityRotation(entity)
    local EntityModel = GetEntityModel(entity)
    TriggerServerEvent("newprop", entity, EntityModel, EntityPos.x, EntityPos.y, EntityPos.z, EntityRot.x,
        EntityRot.y, EntityRot.z);
end, false)

RegisterCommand('remove', function(source, args)
    if IsAnEntity(entity) then
        DeleteEntity(entity)
        TriggerServerEvent("RemoveProp", InvObjDictionary[entity]);
    end
end, false)

local function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

local function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local a, b, c, d, e = GetShapeTestResult(StartExpensiveSynchronousShapeTestLosProbe(cameraCoord.x, cameraCoord.y,
        cameraCoord.z, destination.x, destination.y, destination.z, -1, -1, 1))
    return cameraCoord, b, c, e
end


RegisterNetEvent("UpdateClusters")
AddEventHandler("UpdateClusters", function(centers, radius)
    for i, z in pairs(Zone) do
        if z ~= nil then
            z:destroy()
        end
    end
    if centers[1] == nil then
        TriggerServerEvent("RequestRemove", PlayerServerId);
    end
    for k, v in pairs(centers) do
        Zone[k] = CircleZone:Create(vector3(v[1], v[2], v[3]), radius[k] + 50, {
            name = "circle_zone",
            debugPoly = true,
            useZ = true,
        })
        Zone[k]:onPlayerInOut(function(isPointInside, point)
            if isPointInside then
                TriggerServerEvent("RequestRemove", PlayerServerId);
                TriggerServerEvent("RequestObjects", PlayerServerId);
                ZoneNumber = k
            else
            end
        end)
    end
end)

RegisterNetEvent("RemoveObjects")
AddEventHandler("RemoveObjects", function(remove)
    for k, v in pairs(remove) do
        if ObjDictionary[v] ~= nil then
            DeleteEntity(ObjDictionary[v])
            InvObjDictionary[ObjDictionary[v]] = nil
            ObjDictionary[v] = nil
        end
    end
end)

RegisterNetEvent("CreateObjects")
AddEventHandler("CreateObjects", function(db)
    for k, v in pairs(db[ZoneNumber]) do
        local position = vector3(tonumber(v[1]), tonumber(v[2]), tonumber(v[3]))
        local NetID = tonumber(v[4])
        local model = tonumber(v[5])
        if not DoesEntityExist(ObjDictionary[NetID]) then
            ObjDictionary[NetID] = CreateObject(model, position, false, false, false) 
            InvObjDictionary[ObjDictionary[NetID]] = NetID  
        end
    end
end)

TriggerServerEvent("InitClusters", PlayerServerId)

Citizen.CreateThread(function()
    while not NetworkIsPlayerActive do
        Citizen.Wait(0)
    end
    while true do
        Citizen.Wait(10)
        cameraCoord, hit, coords, entity = RayCastGamePlayCamera(1000.0)
        if hit then
            local position = GetEntityCoords(GetPlayerPed(-1))
            DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, 0, 255, 0, 255)
        end
    end
end)
