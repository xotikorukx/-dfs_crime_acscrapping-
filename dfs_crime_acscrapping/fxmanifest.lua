fx_version 'cerulean'
games      { 'gta5' }
lua54      'yes'

author 'x otikoruk x#4064'
description 'Adds AC scrapping - that can be done in groups! 06/08/2021'

--
-- Server
--

server_scripts {
    -- '@encore/common/shared.lua',

    'config.lua',

    'server/server.lua',
}

--
-- Client
--

client_scripts {
    -- '@encore/common/shared.lua',

    'config.lua',

    'client/client.lua',
}

--use qbcore export AddItems(table) to add items for this resource