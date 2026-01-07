---@class vorp_housing_config
local CONFIG = {}

CONFIG.DEV_MODE = true -- set to true when you need to restart script to do your tests

-- HOUSES CANNOT BE BOUGHT IN GAME HANDLE THAT IN YOUR DISCORD TICKETS
-- DOORS ARE HANDLED IN VORP DOORLOCKS
CONFIG.HOUSES = {
    -- WIDOW ROCK HOUSE
    {
        POSITION = vector3(-397.7, 1727.66, 216.49), -- POSITION OF THE CENTER OF THE HOUSE and for blip
        BLIP = {
            ENABLE = true,                           -- Will display the blip of this house if player owns it
            SPRITE = `blip_mp_base`,
            STYLE = `BLIP_STYLE_PROPERTY_OWNER`,
            NAME = "My House",
        },

        OWNERS = {
            [1] = {
                DOOR = true,         -- CAN OPEN AND CLOSE DOORS?
                STORAGE = true,      -- CAN ACCESS STORAGES?
                BLIP_VISIBLE = true, -- CAN SEE THE BLIP OF THE HOUSE?
            },                       --CHARACTER ID'S for the owners this player can only own one house
        },

        -- ONE HOUSE CAN HAVE MORE THAN ONE STORAGE
        STORAGES = {
            {
                ID = 1,                                       -- STORAGE ID MUST BE UNIQUE FOR EACH STORAGE
                MAX_SLOTS = 100,                              -- MAX SLOTS FOR THE STORAGE
                LOCATION = vector3(-391.28, 1728.72, 216.44), -- LOCATION OF THE STORAGE
                LABEL = "Food Storage",
                WEAPONS = true,
                SHARED = true,        -- IF FALSE EACH OWNER WILL HAVE THEIR OWN INVENTORY
                BLACKLISTED_ITEMS = { -- BLACKLIST ITEMS OR WEAPONS , TO DISABLE JUST LEAVE AN EMPTY TABLE
                    "water",
                    "bread",
                },
            },
            {
                ID = 2,
                MAX_SLOTS = 100,
                LOCATION = vector3(-396.38, 1732.76, 216.43),
                LABEL = "Tools Storage",
                WEAPONS = true,
                SHARED = true,
                BLACKLISTED_ITEMS = {},
            }
        },
        DOORS = {       -- DOOR IDS, MUST BE IN VORP DOORLOCKS TO BE DETECTED THESE DOORS DONT NEED PERMISSIONS IN VORP DOORLOCKS SCRIPT
            4070066247, -- front door
            3444471262  -- side door
        }
    }

}


return {
    CONFIG = CONFIG,
}
