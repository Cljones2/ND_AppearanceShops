-- For support join my discord: https://discord.gg/Z9Mxu72zZ6

author "Andyyy#7666"
description "Clothing store for ND framework with blocked items support"
version "2.1.0"

fx_version "cerulean"
game "gta5"
lua54 "yes"

-- Shared scripts
shared_scripts {
    "@ND_Core/init.lua",
    "@ox_lib/init.lua",
    "config.lua"
}

-- Server scripts
server_scripts {
    "source/server.lua"
}

-- Client scripts
client_scripts {
    "source/blockedItems.lua",  -- Added blocked items script
    "source/client.lua"
}

-- Dependencies
dependencies {
    "ND_Core",
    "fivem-appearance",
    "ox_lib"
}
