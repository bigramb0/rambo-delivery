local QBCore = exports["qb-core"]:GetCoreObject()
local DoingRoute = false
local HasBox = false
local BoxObject = nil
local pickupLocation = vector3(0.0, 0.0, 0.0)
local Truck = nil
local inRange = false

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()

    local deliveryBlip = AddBlipForCoord(Config.NPC)
    SetBlipSprite(deliveryBlip, 477)
    SetBlipDisplay(deliveryBlip, 4)
    SetBlipScale(deliveryBlip, 0.8)
    SetBlipAsShortRange(deliveryBlip, true)
    SetBlipColour(deliveryBlip, 54)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("GoPostal Depot")
    EndTextCommandSetBlipName(deliveryBlip)

end)

RegisterNetEvent("delivery:attemptStart", function()
    if exports["ps-playergroups"]:IsGroupLeader() then 
        if exports["ps-playergroups"]:GetJobStage() == "WAITING" then
            local groupID = exports["ps-playergroups"]:GetGroupID()
            
            

            local model = GetHashKey("boxville2")
            RequestModel(model)
            while not HasModelLoaded(model) do
                Wait(0)
            end

            TriggerServerEvent("delivery:createGroupJob", groupID)
            DoingRoute = true
        else 
            QBCore.Functions.Notify("Your group is already doing something!", "error")
        end
    else 
        QBCore.Functions.Notify("You are not the group leader!", "error")
    end
end)

RegisterNetEvent("delivery:attemptStop", function()
    if exports["ps-playergroups"]:IsGroupLeader() then 
        if exports["ps-playergroups"]:GetJobStage() == "DELIVERY RUN" then
            local groupID = exports["ps-playergroups"]:GetGroupID()
            TriggerServerEvent("delivery:stopGroupJob", groupID)
            DoingRoute = false
        else 
            QBCore.Functions.Notify("Your group isn't doing a run!", "error")
        end
    else 
        QBCore.Functions.Notify("You are not the group leader!", "error")
    end
end)


RegisterNetEvent("delivery:startRoute", function(truckID)
    Truck = NetworkGetEntityFromNetworkId(truckID)

    
    exports['qb-target']:AddGlobalVehicle({
        options = { 
        {
            icon = 'fas fa-box',
            label = 'Take Box',
            action = function(entity) 
                takeBox()
            end,   
            canInteract = function(entity, distance, data)
                if entity == Truck and not HasBox then return true end 
                return false
            end,
            },
            {
                type = "client",
                icon = "fas fa-sign-in-alt",
                label = "Return Box",
                action = function(entity) 
                    DeliverAnim()
                end,   
                canInteract = function()
                    if HasBox then return true end 
                    return false
                end,
            },
        },
        distance = 3.5,
    })
end)

RegisterNetEvent("delivery:endRoute", function()
    exports['qb-target']:RemoveGlobalVehicle("Take Box")
    DoingRoute = false
    HasBox = false
    BoxObject = nil
    Truck = nil
    pickupLocation = vector3(0.0, 0.0, 0.0)
    DetachEntity(BoxObject, 1, false)
    DeleteObject(BoxObject)
    BoxObject = nil
end)

RegisterNetEvent("Z:pickupClean", function()
    DetachEntity(BoxObject, 1, false)
    DeleteObject(BoxObject)
    BoxObject = nil
end)

RegisterNetEvent("delivery:updatePickup", function(coords)
    pickupLocation = coords

    exports['qb-target']:AddCircleZone("deliverBox", vector3(pickupLocation.x, pickupLocation.y-1, pickupLocation.z), 2,{
        name = "deliverbox",
        useZ = true,
        debugPoly = false
        }, {
            options = {
                {
                    type = "client",
                    icon = "fas fa-sign-in-alt",
                    label = "Deliver Box",
                    action = function(entity) 
                        deliverBox()
                    end,   
                    canInteract = function()
                        if HasBox then return true end 
                        return false
                    end,
                },
            },
            distance = 2.5
    })
end)


function LoadAnimation(dict)
    RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do Wait(10) end
end

function AnimCheck()
    CreateThread(function()
        while HasBox do
            local ped = PlayerPedId()
            if not IsEntityPlayingAnim(ped, 'anim@heists@box_carry@', 'idle', 3) then  --change
                ClearPedTasksImmediately(ped)
                LoadAnimation('anim@heists@box_carry@')
                TaskPlayAnim(ped, 'anim@heists@box_carry@', 'idle', 6.0, -6.0, -1, 49, 0, 0, 0, 0)
            end
            Wait(2000)
        end
    end)
end

function takeBox()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local dist = #(pos - vector3(pickupLocation.x, pickupLocation.y, pickupLocation.z))
        if dist < 20 then
            LoadAnimation('anim@heists@box_carry@')
            TaskPlayAnim(ped, 'anim@heists@box_carry@', 'idle', 6.0, -6.0, -1, 49, 0, 0, 0, 0)
            BoxObject = CreateObject(`hei_prop_heist_box`, 0, 0, 0, true, true, true) --change
            AttachEntityToEntity(BoxObject, ped, GetPedBoneIndex(ped, 60309), 0.025, 0.08, 0.255, -145.0, 290.0, 0.0, true, true, false, true, 1, true)
            HasBox = true
            AnimCheck()
        else 
            QBCore.Functions.Notify('You are not near a shop!', 'error')
        end
end

function DeliverAnim()
    local ped = PlayerPedId()
    DetachEntity(BoxObject, 1, false)
    DeleteObject(BoxObject)
    HasBox = false
    StopAnimTask(PlayerPedId(), "anim@heists@box_carry@", "idle", 1.0) 
    BoxObject = nil
end

function deliverBox()
    local groupID = exports["ps-playergroups"]:GetGroupID()
    QBCore.Functions.Progressbar("deliverbox", "Delivering Package", 1000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        DeliverAnim()
        Wait(100)
        TriggerServerEvent("delivery:updateBoxes", groupID)
    end, function() -- Cancel
       
    end)
end

Citizen.CreateThread(function()
    local hash = GetHashKey('s_m_m_postal_01') 

    -- Loads model
    RequestModel(hash)
    while not HasModelLoaded(hash) do
      Wait(1)
    end
    -- Creates ped when everything is loaded
    ped = CreatePed(0, hash, Config.NPC.x, Config.NPC.y, Config.NPC.z, true, false)
    SetEntityHeading(ped, Config.Heading)
    Wait(1000)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    local ped = {
        `s_m_m_postal_01`,
    }
end)

exports['qb-target']:AddBoxZone("deliverped1", vector3(Config.NPC.x, Config.NPC.y, Config.NPC.z), 1, 1, { --change all
    name="deliverped1",
    heading=Config.Heading,
    debugPoly=false,
    minZ=Config.NPC.z-2,
    maxZ=Config.NPC.z+2
  },{
    options = {
        {
            type = "client",
            event = "delivery:attemptStart",
            label = 'Start Delivery Run',
            icon = 'fa-solid fa-circle',
            canInteract = function()
                if DoingRoute then return false end
                return true
            end,
        },
        {
            type = "client",
            event = "delivery:attemptStop",
            label = 'Complete Delivery Run',
            icon = 'fa-solid fa-circle',
            canInteract = function()
                return DoingRoute
            end,
        },
        },
    distance = 3.0
}) 