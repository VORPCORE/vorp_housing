# vorp_housing

`vorp_housing` is a simple housing access resource for VORP.

This script does not handle buying or selling houses in-game. Houses are configured manually in [config.lua](./config.lua), and access is given to specific characters using their `charIdentifier`.

What it does:

- gives selected characters access to specific houses
- gives selected characters access to specific storages
- gives selected characters access to specific doors
- shows a private house blip if you enable it

> [!NOTE]
> This version is config-based. If you want to give a house to someone, you edit the config and add their `charIdentifier`.

## Installation

1. Put `vorp_housing` in your resources folder.
2. Make sure these resources are running before it:
   - `vorp_core`
   - `vorp_lib`
   - `vorp_inventory`
   - `vorp_doorlocks`
   - `oxmysql`
3. Add this to your server config:

```cfg
ensure vorp_housing
```

4. Restart the server or restart the resource.

## How It Works

Each house is defined in [config.lua](./config.lua).

Each house can contain:

- a house position
- a blip
- one or more owners
- one or more storages
- one or more door IDs

When a player selects their character, the script checks if that character `charIdentifier` exists in one of the house owner lists.

If it does:

- the script gives door permission through `vorp_doorlocks`
- the script registers the storages for that house
- the player gets the matching prompts and house blip

## How To Configure A House

Everything is configured in [config.lua](./config.lua).

Minimal example:

```lua
{
    POSITION = vector3(1118.06, -1987.89, 55.34),

    BLIP = {
        ENABLE = true,
        SPRITE = `blip_mp_base`,
        STYLE = `BLIP_STYLE_PROPERTY_OWNER`,
        NAME = "My House",
    },

    OWNERS = {
        [12] = {
            DOOR = true,
            STORAGE = true,
            BLIP_VISIBLE = true,
        },
    },

    STORAGES = {
        {
            ID = 99,
            MAX_SLOTS = 100,
            LOCATION = vector3(1119.03, -1985.67, 55.35),
            LABEL = "Storage",
            WEAPONS = true,
            SHARED = true,
            BLACKLISTED_ITEMS = {},
        }
    },

    DOORS = {
        3921310299
    }
}
```

Main fields:

- `POSITION`: center of the house, also used for the blip
- `BLIP`: house blip settings
- `OWNERS`: which characters can use the house
- `STORAGES`: storage list for that house
- `DOORS`: door IDs that belong to that house

## How To Add Doors

This script does not create doors by itself.

Doors must already exist in `vorp_doorlocks`.

So the correct setup is:

1. Open your `vorp_doorlocks` config.
2. Add the door there first.
3. Get the correct door ID.
4. Put that same door ID inside the house `DOORS` table in `vorp_housing`.

Example:

```lua
DOORS = {
    3921310299,
    640077562
}
```

> [!IMPORTANT]
> If the door is not configured in `vorp_doorlocks`, `vorp_housing` cannot manage permission for it.

`vorp_doorlocks` also mentions that house-style unique permissions use `charidentifier` values from the `characters` table. In this housing script, the permission is applied automatically when the character is listed in the house `OWNERS` table.

If you need help finding door IDs, the doorlocks config points to this reference:

- `https://github.com/femga/rdr3_discoveries/blob/master/doorHashes/doorhashes.lua`

## How To Add Character IDs

This is the part most people need.

You need the character `charIdentifier`, not the player source.

You can get it from your database in the `characters` table.

Example query:

```sql
SELECT charidentifier, firstname, lastname
FROM characters
ORDER BY charidentifier ASC;
```

That will give you the list of character IDs with names.

Then you add the wanted `charidentifier` inside the house `OWNERS` table.

Example:

```lua
OWNERS = {
    [34] = {
        DOOR = true,
        STORAGE = true,
        BLIP_VISIBLE = true,
    },
    [52] = {
        DOOR = true,
        STORAGE = false,
        BLIP_VISIBLE = true,
    },
}
```

In this example:

- character `34` can use doors, storage, and see the blip
- character `52` can use doors and see the blip, but cannot access storage

> [!WARNING]
> `charIdentifier` is not the same as steam, license, or server id. If you use the wrong value, the player will not get access.

## How Storage Works

Each storage entry has:

- `ID`: must stay unique
- `MAX_SLOTS`: inventory size
- `LOCATION`: where the prompt appears
- `LABEL`: storage name
- `WEAPONS`: allow weapons or not
- `SHARED`: shared between owners or personal per owner
- `BLACKLISTED_ITEMS`: items blocked from that storage

Example:

```lua
STORAGES = {
    {
        ID = 1,
        MAX_SLOTS = 100,
        LOCATION = vector3(-391.28, 1728.72, 216.44),
        LABEL = "Food Storage",
        WEAPONS = true,
        SHARED = true,
        BLACKLISTED_ITEMS = {
            "water",
            "bread",
        },
    }
}
```

## Things To Watch

- Storage `ID` values must be unique.
- Door IDs must exist in `vorp_doorlocks`.
- Owner IDs must be real `charidentifier` values from the `characters` table.
- After changing the config, restart `vorp_housing`.

> [!NOTE]
> This script is best for staff housing, faction housing, gang housing, or manually assigned private homes.

## Credits

- VORP Core team
- Original repository: [VORPCORE/vorp_housing](https://github.com/VORPCORE/vorp_housing)
