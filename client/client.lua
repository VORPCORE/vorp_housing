local LIB <const>     = Import({ "/config", 'blips', 'prompts' })
local CONFIG <const>  = LIB.CONFIG --[[@as vorp_housing_config]]
local Blips <const>   = LIB.Blips --[[@as MAP]]
local Prompts <const> = LIB.Prompts --[[@as PROMPTS]]
local CHARID          = 0
local OWNED_INDEX     = 0
local running         = false
local Core <const>    = exports.vorp_core:GetCore()



local function registerLocations()
    local values <const> = CONFIG.HOUSES[OWNED_INDEX]
    local locations <const> = {}
    for _, storage in ipairs(values.STORAGES) do
        table.insert(locations, {
            coords = storage.LOCATION,
            label = storage.LABEL,
            distance = 2.0,
        })
    end

    local data = {
        sleep = 800,
        locations = locations,
        prompts = {
            {
                type = "Press",
                key = `INPUT_SHOP_SELL`, -- R
                label = 'press',
                mode = 'Standard',
            },
        }
    }

    Prompts:Register(data, function(_, index, _)
        local location <const> = CONFIG.HOUSES[OWNED_INDEX]
        if not location then return end

        if not location.OWNERS[CHARID] then
            return Core.NotifyObjective("You are not the owner of this house", 5000)
        end

        local storage <const> = location.STORAGES[index]
        if not storage then return end

        TriggerServerEvent("vorp_housing:Server:OpenStorage", OWNED_INDEX, index)
    end, true) -- auto start on register
end

RegisterNetEvent("vorp_housing:Client:RegisterHouse", function(index, charId)
    OWNED_INDEX = index
    CHARID = charId

    local value <const> = CONFIG.HOUSES[OWNED_INDEX]
    if not value then return end

    if not value.BLIP.ENABLE then return end

    if not value.OWNERS[CHARID] then return end

    if running then return end
    running = true

    if value.BLIP.ENABLE and value.OWNERS[CHARID].BLIP_VISIBLE then
        Blips:Create('coords', {
            Pos = value.POSITION,
            Blip = value.BLIP.STYLE,
            Options = {
                sprite = value.BLIP.SPRITE,
                name = value.BLIP.NAME,
            },
        })
    end

    if not value.OWNERS[CHARID].STORAGE then return end
    Wait(5000)
    registerLocations()
end)


--FOR TESTS
if CONFIG.DEV_MODE then
    -- on resource start
    AddEventHandler("onResourceStart", function(resource)
        if resource ~= GetCurrentResourceName() then return end
        TriggerServerEvent("vorp_housing:Server:DevMode")
    end)
end
