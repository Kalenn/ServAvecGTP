fx_version 'adamant'
game 'gta5'

author 'VotreNom'
description 'Système de verrouillage de véhicule avec clés pour esx_vehicleshop'
version '1.0.0'

shared_scripts {
    '@es_extended/locale.lua',
    'config.lua'
}

client_scripts {
    '@es_extended/locale.lua',
    'client.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'es_extended',
    'esx_vehicleshop',
    'esx_garage',
    'mysql-async'
}
