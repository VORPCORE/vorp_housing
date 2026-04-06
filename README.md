# vorp_housing

`vorp_housing` is a lightweight housing access system for RedM servers running VORP.

This version is not a real estate market script. It does not let players buy or sell houses in-game. Instead, houses are defined directly in [config.lua](./config.lua), and access is granted to specific characters through their `charIdentifier`.

If what you want is a clean way to:

- assign houses to characters
- give selected characters door access
- give selected characters storage access
- show private house blips only to the right owners

then this resource is exactly that.

The default config currently ships with:

- 14 configured houses
- 15 configured storages
- door permissions handled through `vorp_doorlocks`
- storage handled through `vorp_inventory`

> [!NOTE]
> This repo is closer to a permission-based housing layer than a full economy housing system. Ownership is configured by hand in the config file.

## What The Script Does

At a high level, the script works like this:

1. Houses are defined in [config.lua](./config.lua).
2. Each house contains:
   - a main world position
   - optional blip settings
   - an `OWNERS` table keyed by `charIdentifier`
   - one or more storages
   - one or more door IDs
3. When a player selects a character, the server checks whether that character appears in any house `OWNERS` table.
4. If a match is found, the script:
   - grants door permissions through `vorp_doorlocks`
   - registers the house storages in `vorp_inventory` if needed
   - notifies the client so prompts and the optional house blip can be created

There is no SQL ownership table in this version. The source of truth is the config itself.

## Dependencies

This resource expects these dependencies to be available:

- `vorp_core`
- `vorp_lib`
- `vorp_inventory`
- `vorp_doorlocks`
- `oxmysql`

> [!IMPORTANT]
> Even though this version does not use a housing SQL table, `oxmysql` is still listed in the manifest and should remain available in your VORP stack.

## File Structure

- [fxmanifest.lua](./fxmanifest.lua) loads the resource.
- [config.lua](./config.lua) contains the full housing setup.
- [client/client.lua](./client/client.lua) handles prompts and client blips.
- [server/server.lua](./server/server.lua) handles owner checks, storage registration, storage opening, and permissions.

## Installation

1. Place `vorp_housing` in your server resources folder.
2. Make sure all required dependencies are already started.
3. Add `ensure vorp_housing` to your server config.
4. Open [config.lua](./config.lua) and configure your houses.
5. Restart the resource.

## How Ownership Works

Ownership is manual and config-based.

Each house has an `OWNERS` table that looks like this:

```lua
OWNERS = {
    [1] = {
        DOOR = true,
        STORAGE = true,
        BLIP_VISIBLE = true,
    },
}
```

The key in that table is the character ID.

That means:

- `1` is a `charIdentifier`
- not a player source
- not a Steam identifier
- not a Rockstar license

Each owner entry controls three permission types:

- `DOOR`
- `STORAGE`
- `BLIP_VISIBLE`

This lets you decide exactly what a specific character can do inside that house.

Example:

- one character can open doors but not use storage
- another character can use storage and see the blip
- another character can have full access

> [!NOTE]
> Since ownership is defined directly in config, changing owners means editing the file and restarting the resource.

## How Doors Work

Doors are not handled internally by a custom lock system in this script.

This resource delegates door permissions to `vorp_doorlocks`.

When a valid owner loads in, [server/server.lua](./server/server.lua) gives that player permission on every door ID listed under the house if `DOOR = true`.

Each house uses:

```lua
DOORS = {
    4070066247,
    3444471262
}
```

Those values must match valid door IDs already managed by `vorp_doorlocks`.

If the door does not exist in your doorlock setup, this script cannot magically manage it for you.

> [!WARNING]
> A wrong door ID will not give the player access to the correct door. Always verify your door IDs in `vorp_doorlocks` first.

## How Storage Works

Each house can have one or more storage entries under `STORAGES`.

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

What each field means:

- `ID`: unique storage ID across the full config
- `MAX_SLOTS`: storage size
- `LOCATION`: world position used for the interaction prompt
- `LABEL`: inventory name shown to the player
- `WEAPONS`: whether weapons are accepted
- `SHARED`: whether owners share the same inventory or each get their own
- `BLACKLISTED_ITEMS`: items or weapons blocked from that storage

The server registers each storage as a custom inventory using the internal prefix:

```lua
house_<ID>
```

So storage `ID = 15` becomes inventory id `house_15`.

## Shared vs Personal Storage

The `SHARED` field matters a lot:

- `SHARED = true` means all allowed owners of that house use the same stash
- `SHARED = false` means each owner gets their own separate inventory

This gives you a simple way to build:

- family houses
- staff houses
- gang-safe style shared buildings
- private single-character homes

## Blacklisted Items

Each storage can optionally block specific items or weapons through `BLACKLISTED_ITEMS`.

If the table is empty, blacklist mode stays disabled for that storage.

If the table contains values, the script enables blacklist mode and registers every listed entry through `vorp_inventory`.

This is useful if you want to:

- keep food separate from weapons
- block valuables from utility storage
- create themed storage spots inside the same house

## Blips

Each house supports its own blip block:

```lua
BLIP = {
    ENABLE = true,
    SPRITE = `blip_mp_base`,
    STYLE = `BLIP_STYLE_PROPERTY_OWNER`,
    NAME = "My House",
}
```

The client only creates the blip if:

- `BLIP.ENABLE = true`
- the current character is listed as an owner
- that owner has `BLIP_VISIBLE = true`

So blips are private by design. Players do not see house blips unless the config says they should.

## Client Flow

The client is intentionally small.

Once the server tells the client which house belongs to the current character:

- the owned house index is saved locally
- the current `charIdentifier` is saved locally
- the blip is created if allowed
- storage prompt locations are registered through the `prompts` module from `vorp_lib`

When the player interacts with a storage prompt:

- the client checks nothing locally beyond the registered context
- it sends the house index and storage index to the server
- the server performs the real access validation

That part is good. The important checks stay server-side.

## Server Flow

The main server logic is:

- detect the selected character
- scan configured houses
- find matching owner entries
- apply door permissions
- register house storages if they are not already registered
- open the correct stash when a valid request comes in

Before opening storage, the server checks:

- the player exists
- the selected character exists
- the house index is valid
- the character is an owner of that house
- the owner entry has `STORAGE = true`
- the player is close enough to the house
- the player is close enough to the storage point
- the custom inventory is registered

That means the actual storage access flow is fairly strict and not just trust-based on the client.

## Configuration Guide

Most of the script is configured in [config.lua](./config.lua).

Main top-level options:

- `CONFIG.DEV_MODE`
- `CONFIG.COMMAND`
- `CONFIG.TRANSLATION`
- `CONFIG.HOUSES`

### `CONFIG.DEV_MODE`

Enables the internal testing mode used by the resource.

For normal production use, this should stay disabled.

### `CONFIG.COMMAND`

Command used by the internal testing mode.

Default:

```lua
showHouses
```

### `CONFIG.TRANSLATION`

Small inline translation table for common UI text:

- `not_owner`
- `not_admin`
- `press`

This version does not use a separate locale file. Text is configured directly inside [config.lua](./config.lua).

### `CONFIG.HOUSES`

This is the core of the script.

Every house entry defines:

- where the house is in the world
- how its blip behaves
- which characters own it
- which storages belong to it
- which door IDs belong to it

## Minimal House Example

```lua
{
    POSITION = vector3(0.0, 0.0, 0.0),

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
            LOCATION = vector3(0.0, 0.0, 0.0),
            LABEL = "Storage",
            WEAPONS = true,
            SHARED = true,
            BLACKLISTED_ITEMS = {},
        }
    },

    DOORS = {
        1234567890
    }
}
```

## Things You Must Keep Unique

There are two values you should never duplicate carelessly:

- storage `ID`
- door IDs inside the wrong house config

Storage `ID` must be unique globally, because the script builds inventory ids from it.

If two storages reuse the same `ID`, they will point to the same custom inventory identifier and you will get messy behavior fast.

## What This Script Does Not Do

This version does not:

- create ownership automatically
- save ownership in SQL
- provide a buy menu
- provide a rent system
- provide taxes
- provide furniture placement
- provide shell or routing bucket interiors
- manage doors without `vorp_doorlocks`

That is not a flaw by itself. It is just a different scope.

## Good Use Cases

This version is a good fit if you want:

- staff housing
- lore-owned houses
- whitelist-based faction housing
- gang or family shared storage
- manually assigned private homes

It is not the right fit if you need:

- player-driven house purchases
- a housing market
- mortgage or rental systems
- dynamic property acquisition without config edits

## Common Setup Mistakes

The most common issues are usually these:

- using the wrong `charIdentifier`
- forgetting to add the correct door IDs in `vorp_doorlocks`
- reusing a storage `ID`
- putting the wrong storage `LOCATION`
- expecting players to buy houses in-game when this version does not support that
- leaving `CONFIG.DEV_MODE = true` on production

> [!IMPORTANT]
> If a player can see the house but cannot open doors or storage, check the owner entry first. In most cases, the issue is either a wrong `charIdentifier` or a permission flag set to `false`.

## Credits

- VORP Core team
- Original repository: [VORPCORE/vorp_housing](https://github.com/VORPCORE/vorp_housing)
