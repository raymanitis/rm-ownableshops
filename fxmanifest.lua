fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'raymans'
description 'Player Ownable Shops System'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'shared/sv_config.lua',
    'server.lua'
}

client_scripts {
    '@qb-core/client/functions.lua',
    'client.lua'
}

files {
    'locales/*.json'
}