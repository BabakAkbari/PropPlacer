fx_version 'cerulean'
game 'gta5'

author 'Babak'
description 'Prop Placer'
version '1.0.0'

resource_type 'gametype' { name = 'My awesome game type!' }

client_scripts {
    'modules/PolyZone/client.lua',
    'modules/PolyZone/BoxZone.lua',
    'modules/PolyZone/EntityZone.lua',
    'modules/PolyZone/CircleZone.lua',
    'modules/PolyZone/ComboZone.lua',
    'resources/PropPlacer.lua',
}

server_scripts {
    'resources/server.js',
}