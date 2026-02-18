fx_version 'cerulean'
game 'gta5'

name 'free-mining'
description 'Hardcore realistic mining system for QBX'
version '1.0.0'
author 'Creator'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'config.lua',
}

client_scripts {
    'client/zones.lua',
    'client/mining.lua',
    'client/processing.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/processing.lua',
}

ui_page 'html/minigame.html'

files {
    'html/minigame.html',
    'html/minigame.css',
    'html/minigame.js',
}

lua54 'yes'

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'oxmysql',
}
