ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('esx_vehicleshop:addKey')
AddEventHandler('esx_vehicleshop:addKey', function(plate)
    local xPlayer = ESX.GetPlayerFromId(source)
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
end)
