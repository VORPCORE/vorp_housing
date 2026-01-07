local Core <const> = exports.vorp_core:GetCore()
local LIB <const> = Import "/config"
local CONFIG <const> = LIB.CONFIG --[[@as vorp_housing_config]]
local Inventory <const> = exports.vorp_inventory


local function registerHouse(source, character)
    local charId <const> = character.charIdentifier
    for index, house in ipairs(CONFIG.HOUSES) do
        local isOwner <const> = house.OWNERS[charId]
        if isOwner then
            SetTimeout(5000, function()
                if isOwner.DOOR then
                    for _, door in ipairs(house.DOORS) do
                        exports.vorp_doorlocks:updateDoorPermission(source, door, true)
                    end
                end

                TriggerClientEvent("vorp_housing:Client:RegisterHouse", source, index, charId)
            end)

            if isOwner.STORAGE then
                for _, storage in ipairs(house.STORAGES) do
                    local prefix <const> = "house_" .. storage.ID
                    local isStorageRegistered <const> = Inventory:isCustomInventoryRegistered(prefix)
                    if not isStorageRegistered then
                        Inventory:registerInventory({
                            id = prefix,
                            name = storage.LABEL,
                            limit = storage.MAX_SLOTS,
                            acceptWeapons = storage.WEAPONS,
                            shared = storage.SHARED, -- inventory is shared with owners of the house or should each have their own ?
                            ignoreItemStackLimit = true,
                            whitelistItems = false,
                            UsePermissions = false,
                            UseBlackList = #storage.BLACKLISTED_ITEMS > 0,
                            whitelistWeapons = false,
                            webhook = "" -- add here a webhook to monitor the houses inventories
                        })

                        if #storage.BLACKLISTED_ITEMS > 0 then
                            for _, item in ipairs(storage.BLACKLISTED_ITEMS) do
                                exports.vorp_inventory:blackListCustomAny(prefix, item)
                            end
                        end
                    end
                end
            end
        end
    end
end

AddEventHandler("vorp:SelectedCharacter", function(source, character)
    if CONFIG.DEV_MODE then return end
    registerHouse(source, character)
end)

-- HERE WE HANDLE OPENING STORAGES FOR THE HOUSE
RegisterServerEvent("vorp_housing:Server:OpenStorage", function(index, storageIndex)
    local _source <const> = source
    local user <const> = Core.getUser(_source)
    if not user then return end

    local character <const> = user.getUsedCharacter
    local charId <const> = character.charIdentifier

    local house <const> = CONFIG.HOUSES[index]
    if not house then return print("House not found") end

    local isOwner <const> = house.OWNERS[charId]
    if not isOwner then return print("Player is not the owner of the house") end

    if not isOwner.STORAGE then return print("Player is not allowed to access storages") end

    local houseCoords <const> = house.POSITION
    local pedCoords <const> = GetEntityCoords(GetPlayerPed(_source))
    if #(pedCoords - houseCoords) > 10.0 then return print("Player is not close to the house") end

    local storage <const> = house.STORAGES[storageIndex]
    if not storage then return print("Storage not found") end

    local location <const> = storage.LOCATION
    local distance <const> = #(pedCoords - location)
    if distance > 3.0 then return print("Player is not close to this storage") end

    local prefix <const> = "house_" .. storage.ID
    local isStorageRegistered <const> = Inventory:isCustomInventoryRegistered(prefix)
    if not isStorageRegistered then return print("Storage is not registered in the inventory") end

    Inventory:openInventory(_source, prefix)
end)


--FOR TESTS
if CONFIG.DEV_MODE then
    RegisterServerEvent("vorp_housing:Server:DevMode", function()
        local _source <const> = source
        local user <const> = Core.getUser(_source)
        if not user then return end
        local character <const> = user.getUsedCharacter
        registerHouse(_source, character)
    end)
end
