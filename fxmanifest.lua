fx_version 'cerulean'
game 'gta5'

author 'Fixlife'
description 'Base de gestion de facciones y negocios'
version '0.1.0'

ui_page 'web/index.html'

shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_scripts { 'chairs.lua', 'client.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server.lua' }

dependencies { 'ox_lib', 'oxmysql', 'ox_target', 'qbx_core' }

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/logos/lspd.webp'
}
