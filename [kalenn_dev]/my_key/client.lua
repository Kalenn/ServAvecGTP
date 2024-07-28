ESX = nil
local playerKeys = {}

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    ESX.TriggerServerCallback('esx_vehicleshop:getPlayerKeys', function(keys)
        playerKeys = keys
    end)
end)

RegisterNetEvent('esx_vehicleshop:addKey')
AddEventHandler('esx_vehicleshop:addKey', function(plate)
    table.insert(playerKeys, plate)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, GetKeyFromConfig(Config.LockKey)) then
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 3.0, 0, 71)

            if DoesEntityExist(vehicle) then
                local plate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle))
                if hasKey(plate) then
                    lockVehicle(vehicle)
                else
                    ESX.ShowNotification('Vous n\'avez pas la clé de ce véhicule.')
                end
            end
        end
    end
end)

function GetKeyFromConfig(key)
    if key == '*' then
        return 171 -- Key code for '*'
    else
        -- Ajoutez d'autres correspondances de touches si nécessaire
        return -1
    end
end

function hasKey(plate)
    for i=1, #playerKeys, 1 do
        if playerKeys[i] == plate then
            return true
        end
    end
    return false
end

function lockVehicle(vehicle)
    local locked = GetVehicleDoorLockStatus(vehicle)

    if locked == 1 then -- Unlocked
        SetVehicleDoorsLocked(vehicle, 2)
        ESX.ShowNotification('Véhicule verrouillé.')
    else
        SetVehicleDoorsLocked(vehicle, 1)
        ESX.ShowNotification('Véhicule déverrouillé.')
    end
end
