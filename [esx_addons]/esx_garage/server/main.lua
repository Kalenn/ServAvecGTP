ESX = exports['es_extended']:getSharedObject()

-- Ajoutez cet événement pour ajouter la clé lorsque le joueur sort le véhicule du garage
RegisterServerEvent('esx_garage:onVehicleOut')
AddEventHandler('esx_garage:onVehicleOut', function(plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll('SELECT 1 FROM user_key WHERE identifier = @identifier AND plate = @plate', {
        ['@identifier'] = xPlayer.identifier,
        ['@plate'] = plate
    }, function(result)
        if #result == 0 then
            MySQL.Async.execute('INSERT INTO user_key (identifier, plate) VALUES (@identifier, @plate)', {
                ['@identifier'] = xPlayer.identifier,
                ['@plate'] = plate
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    TriggerClientEvent('esx:showNotification', source, 'Vous avez reçu une clé pour le véhicule avec la plaque ' .. plate)
                    -- Ajoute la clé au trousseau de clé dans l'inventaire
                    xPlayer.addInventoryItem('vehicle_key', 1)
                end
            end)
        else
            TriggerClientEvent('esx:showNotification', source, 'Vous possédez déjà une clé pour ce véhicule.')
        end
    end)
end)

RegisterServerEvent('esx_garage:pullOutVehicle')
AddEventHandler('esx_garage:pullOutVehicle', function(vehicleProps)
    local xPlayer = ESX.GetPlayerFromId(source)
    -- Logique pour sortir le véhicule du garage
    -- Assurez-vous que cette partie du code contient la logique nécessaire pour sortir le véhicule du garage

    -- Déclenche l'événement pour ajouter la clé
    TriggerEvent('esx_garage:onVehicleOut', vehicleProps.plate)
end)

-- Vos événements et callbacks existants restent inchangés
RegisterServerEvent('esx_garage:updateOwnedVehicle')
AddEventHandler('esx_garage:updateOwnedVehicle', function(stored, parking, Impound, data, spawn)
    local source = source
    local xPlayer  = ESX.GetPlayerFromId(source)
        MySQL.update('UPDATE owned_vehicles SET `stored` = @stored, `parking` = @parking, `pound` = @Impound, `vehicle` = @vehicle WHERE `plate` = @plate AND `owner` = @identifier',
        {
            ['@identifier'] = xPlayer.identifier,
            ['@vehicle']    = json.encode(data.vehicleProps),
            ['@plate']      = data.vehicleProps.plate,
            ['@stored']     = stored,
            ['@parking']    = parking,
            ['@Impound']    = Impound
        })

        if stored then
            xPlayer.showNotification(TranslateCap('veh_stored'))
        else 
            ESX.OneSync.SpawnVehicle(data.vehicleProps.model, spawn, data.spawnPoint.heading,data.vehicleProps, function(vehicle)
                local vehicle = NetworkGetEntityFromNetworkId(vehicle)
                Wait(300)
                TaskWarpPedIntoVehicle(GetPlayerPed(source), vehicle, -1)
            end)
        end
end)

RegisterServerEvent('esx_garage:setImpound')
AddEventHandler('esx_garage:setImpound', function(Impound, vehicleProps)
    local source = source
    local xPlayer  = ESX.GetPlayerFromId(source)

        MySQL.update('UPDATE owned_vehicles SET `stored` = @stored, `pound` = @Impound, `vehicle` = @vehicle WHERE `plate` = @plate AND `owner` = @identifier',
        {
            ['@identifier'] = xPlayer.identifier,
            ['@vehicle']    = json.encode(vehicleProps),
            ['@plate']      = vehicleProps.plate,
            ['@stored']     = 2,
            ['@Impound']    = Impound
        })

        xPlayer.showNotification(TranslateCap('veh_impounded'))
end)

ESX.RegisterServerCallback('esx_garage:getVehiclesInParking', function(source, cb, parking)
    local xPlayer  = ESX.GetPlayerFromId(source)

    MySQL.query('SELECT * FROM `owned_vehicles` WHERE `owner` = @identifier AND `parking` = @parking AND `stored` = 1',
    {
        ['@identifier']   = xPlayer.identifier,
        ['@parking']      = parking
    }, function(result)

        local vehicles = {}
        for i = 1, #result, 1 do
            table.insert(vehicles, {
                vehicle = json.decode(result[i].vehicle),
                plate = result[i].plate
            })
        end

        cb(vehicles)
    end)
end)

ESX.RegisterServerCallback('esx_garage:getVehiclesToPound', function(source, cb)
    local xPlayer  = ESX.GetPlayerFromId(source)

    MySQL.query('SELECT * FROM `owned_vehicles` WHERE `owner` = @identifier AND `pound` IS NOT NULL',
    {
        ['@identifier']   = xPlayer.identifier
    }, function(result)

        local vehicles = {}
        for i = 1, #result, 1 do
            table.insert(vehicles, {
                vehicle = json.decode(result[i].vehicle),
                plate = result[i].plate,
                pound = result[i].pound
            })
        end

        cb(vehicles)
    end)
end)
