fx_version 'cerulean'
games      { 'gta5' }
lua54      'yes'

author 'xotikorukx' --lmao, discord removed delimiters. 'x otikoruk x#4064'
description 'v1: Adds AC scrapping - that can be done in groups! 06/08/2021 for Encore Season 2. RIP Encore! v2: 11/26/2023 for general release.'

--
-- Server
--

server_scripts {
    'config.lua',

    'server/server.lua',
}

--
-- Client
--

client_scripts {
    'config.lua',

    'client/client.lua',
}

dependencies {
    'qb-target',
    'mythic-progbar',
    'qb-core',
}