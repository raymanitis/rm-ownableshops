local QBX = exports['qb-core']:GetCoreObject()
local myShop = nil
local shopPeds = {}
local shopBlips = {}

lib.locale()

local function ShowNotify(typ, description, title)
    if Config.Notify == 'qb' then
        TriggerEvent('QBCore:Notify', description, typ or 'primary')
    else
        lib.notify({ title = title, description = description, type = typ or 'inform' })
    end
end

local function RemoveEntityTarget(entity)
    if Config.Target == 'qb-target' then
        exports['qb-target']:RemoveTargetEntity(entity)
    else
        exports.ox_target:removeLocalEntity(entity)
    end
end

local function AddEntityTarget(entity, opts)
    if Config.Target == 'qb-target' then
        local qbOptions = {}
        for _, o in ipairs(opts) do
            qbOptions[#qbOptions+1] = {
                icon = o.icon,
                label = o.label,
                action = o.onSelect
            }
        end
        exports['qb-target']:AddTargetEntity(entity, { options = qbOptions, distance = 2.0 })
    else
        exports.ox_target:addLocalEntity(entity, opts)
    end
end

local function CreateShopPed(coords, model)
    model = model or `s_m_m_doctor_01`
    lib.requestModel(model)

    local ped = CreatePed(0, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    return ped
end

local function SetupShopTarget(ped, shopId, isOwner, isOwned)
    local shop = Config.Shops[shopId]
    if not shop then return end

    RemoveEntityTarget(ped)

    local options = {}

    if isOwner then
        options = {
            {
                name = 'manage_shop',
                icon = 'fas fa-store-alt',
                label = locale('menu.manage_shop'),
                onSelect = function()
                    OpenManagementMenu(shopId)
                end
            },
            {
                name = 'browse_shop',
                icon = 'fas fa-shopping-cart',
                label = locale('menu.browse_shop'),
                onSelect = function()
                    OpenShopMenu(shopId)
                end
            }
        }
    elseif isOwned then
        options = {
            {
                name = 'browse_shop',
                icon = 'fas fa-shopping-cart',
                label = locale('menu.browse_shop'),
                onSelect = function()
                    OpenShopMenu(shopId)
                end
            }
        }
    else
        options = {
            {
                name = 'buy_shop',
                icon = 'fas fa-store',
                label = locale('menu.buy_shop', shop.price),
                onSelect = function()
                    local alert = lib.alertDialog({
                        header = locale('menu.confirm_purchase'),
                        content = locale('descriptions.buy_shop_confirm', shop.price),
                        centered = true,
                        cancel = true
                    })

                    if alert == 'confirm' then
                        local success = lib.callback.await('rm-ownableshops:server:buyShop', false, shopId)
                        if success then
                            ShowNotify('success', locale('notifications.shop_purchased'), locale('notifications.success'))
                            myShop = shopId
                            TriggerServerEvent('rm-ownableshops:server:shopPurchased', shopId)
                        end
                    end
                end
            }
        }
    end

    AddEntityTarget(ped, options)
end

function OpenShopMenu(shopId)
    if Config.Debug then
        print("Attempting to open shop: " .. tostring(shopId))
    end

    local hasItems = lib.callback.await('rm-ownableshops:server:checkShopHasItems', false, shopId)
    if Config.Debug then
        print("Shop has items: " .. tostring(hasItems))
    end

    if not hasItems then
        ShowNotify('error', 'No items available in this shop')
        return
    end

    local success = pcall(function()
        exports.ox_inventory:openInventory('shop', { type = shopId, id = 1 })
    end)

    if not success then
        if Config.Debug then
            print("Failed to open ox_inventory shop: " .. tostring(shopId))
        end
        ShowNotify('error', 'Failed to open shop inventory')
    else
        if Config.Debug then
            print("Successfully opened shop: " .. tostring(shopId))
        end
    end
end

function OpenManageItemsMenu()
    lib.registerContext({
        id = 'shop_management',
        title = 'Shop Management',
        options = {
            {
                title = 'Add Items',
                description = 'Add items from your inventory to the shop',
                icon = 'fas fa-plus',
                onSelect = function()
                    AddItemToShop()
                end
            },
            {
                title = 'Remove Items',
                description = 'Remove items from your shop',
                icon = 'fas fa-minus',
                onSelect = function()
                    RemoveItemFromShop()
                end
            }
        }
    })

    lib.showContext('shop_management')
end

function AddItemToShop()
    local items = GetInventoryItemsWithCount()
    if #items == 0 then
        ShowNotify('error', 'You have no items to add')
        return
    end

    local input1 = lib.inputDialog('Add Item to Shop - Step 1', {
        {
            type = 'select',
            label = 'Select Item',
            description = 'Choose which item to add to your shop',
            options = items,
            required = true
        }
    })

    if not input1 then return end

    local selectedItem = input1[1]
    local itemCount = 0
    local itemLabel = selectedItem

    for _, item in ipairs(items) do
        if item.value == selectedItem then
            itemCount = item.count
            itemLabel = item.label
            break
        end
    end

    if itemCount == 0 then
        ShowNotify('error', 'Item not found in inventory')
        return
    end

    local input2 = lib.inputDialog('Add Item to Shop - Step 2', {
        {
            type = 'slider',
            label = 'Amount',
            description = 'How many ' .. itemLabel .. ' to add? (Available: ' .. itemCount .. ')',
            min = 1,
            max = itemCount,
            default = math.min(itemCount, 1),
            required = true
        },
        {
            type = 'number',
            label = 'Price per Item',
            description = 'Price per individual item',
            min = 1,
            required = true
        }
    })

    if input2 then
        local success = lib.callback.await('rm-ownableshops:server:addItemToShop', false, {
            item = selectedItem,
            amount = input2[1],
            price = input2[2]
        })

        if success then
            ShowNotify('success', 'Item added to shop!')
        end
    end
end

function RemoveItemFromShop()
    local shop = lib.callback.await('rm-ownableshops:server:getShopData', false)
    if not shop or not shop.items then
        ShowNotify('error', 'No items in shop')
        return
    end

    local items = json.decode(shop.items)
    if #items == 0 then
        ShowNotify('error', 'No items in shop')
        return
    end

    local options = {}
    for _, item in ipairs(items) do
        local itemData = exports.ox_inventory:Items(item.name)
        local itemLabel = itemData and itemData.label or item.name

        table.insert(options, {
            label = ('%s (Stock: %d)'):format(itemLabel, item.amount),
            value = item.name
        })
    end

    local input = lib.inputDialog('Remove Item from Shop', {
        {
            type = 'select',
            label = 'Item',
            options = options,
            required = true
        },
        {
            type = 'number',
            label = 'Amount',
            description = 'How many to remove?',
            min = 1,
            required = true
        }
    })

    if input then
        local success = lib.callback.await('rm-ownableshops:server:removeItemFromShop', false, {
            item = input[1],
            amount = input[2]
        })

        if success then
            ShowNotify('success', 'Item removed from shop!')
        end
    end
end

function OpenManagementMenu(shopId)
    local shopData = lib.callback.await('rm-ownableshops:server:getShopData', false, shopId)
    local moneyToCollect = shopData and shopData.money or 0
    local shopConfig = Config.Shops[shopId]
    local sellPercentage = Config.SellPercentage or 30
    local sellAmount = shopConfig and math.floor(shopConfig.price * (sellPercentage / 100)) or 0

    lib.registerContext({
        id = 'shop_management',
        title = locale('menu.manage_shop'),
        options = {
            {
                title = locale('menu.manage_items'),
                description = locale('descriptions.add_items_desc'),
                icon = 'fas fa-boxes',
                onSelect = function()
                    OpenManageItemsMenu()
                end
            },
            {
                title = locale('menu.collect_money'),
                description = locale('descriptions.money_to_collect', moneyToCollect),
                icon = 'fas fa-money-bill',
                onSelect = function()
                    CollectShopMoney(shopId)
                end
            },
            {
                title = 'Sell Shop',
                description = ('Sell your shop for $%d (%d%% of original price)'):format(sellAmount, sellPercentage),
                icon = 'fas fa-store-slash',
                onSelect = function()
                    local alert = lib.alertDialog({
                        header = 'Sell Shop',
                        content = ('Are you sure you want to sell your shop for $%d? This action cannot be undone.'):format(sellAmount),
                        centered = true,
                        cancel = true
                    })
                    if alert == 'confirm' then
                        local success = lib.callback.await('rm-ownableshops:server:sellShop', false, shopId)
                        if success then
                            ShowNotify('success', ('You sold your shop for $%d!'):format(sellAmount), 'Shop Sold')
                        else
                            ShowNotify('error', 'Failed to sell shop.', 'Error')
                        end
                    end
                end
            }
        }
    })

    lib.showContext('shop_management')
end

function CollectShopMoney(shopId)
    local success, amount = lib.callback.await('rm-ownableshops:server:collectMoney', false, shopId)
    if success then
        ShowNotify('success', locale('notifications.money_collected', amount), locale('notifications.success'))
    end
end

function GetInventoryItemsWithCount()
    local items = {}
    local inventory = exports.ox_inventory:GetPlayerItems()

    if inventory then
        for _, item in pairs(inventory) do
            if type(item) == 'table' and item.name then
                local function isBL(name)
                    local list = Config.BlacklistedItems
                    if not list then return false end
                    local nm = string.lower(name)
                    if #list > 0 then
                        for _, v in ipairs(list) do
                            if type(v) == 'string' and string.lower(v) == nm then
                                return true
                            end
                        end
                        return false
                    else
                        for k in pairs(list) do
                            if string.lower(k) == nm then
                                return true
                            end
                        end
                        return false
                    end
                end

                if not isBL(item.name) then
                    local count = item.count or item.amount or 1
                    table.insert(items, {
                        label = (item.label or item.name) .. ' (x' .. count .. ')',
                        value = item.name,
                        count = count
                    })
                end
            end
        end
    end

    return items
end

function GetInventoryItems()
    local items = {}
    local inventory = exports.ox_inventory:GetPlayerItems()

    if inventory then
        for _, item in pairs(inventory) do
            if type(item) == 'table' and item.name then
                table.insert(items, {
                    label = item.label or item.name,
                    value = item.name
                })
            end
        end
    end

    return items
end

function RefreshAllTargets()
    CreateThread(function()
        local allShopData = lib.callback.await('rm-ownableshops:server:getAllShopOwnership', false)

        for shopId, ped in pairs(shopPeds) do
            if DoesEntityExist(ped) then
                local isOwner = myShop == shopId
                local isOwned = allShopData[shopId] ~= nil
                SetupShopTarget(ped, shopId, isOwner, isOwned)
            end
        end

        UpdateAllBlips()
    end)
end

local function CreateShopBlip(shopId, shop, isOwned)
    if not shop.blip then return end

    if shopBlips[shopId] then
        RemoveBlip(shopBlips[shopId])
        shopBlips[shopId] = nil
    end

    local blip = AddBlipForCoord(shop.blip.coords.x, shop.blip.coords.y, shop.blip.coords.z)

    SetBlipSprite(blip, shop.blip.sprite or 59)
    SetBlipScale(blip, shop.blip.scale or 0.8)
    SetBlipAsShortRange(blip, true)
    SetBlipDisplay(blip, 4)

    if isOwned then
        SetBlipColour(blip, 3)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(shop.blip.name .. ' (Owned)')
        EndTextCommandSetBlipName(blip)
    else
        SetBlipColour(blip, shop.blip.color or 2)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(shop.blip.name or shop.label)
        EndTextCommandSetBlipName(blip)
    end

    shopBlips[shopId] = blip
end

function UpdateAllBlips()
    for shopId, shop in pairs(Config.Shops) do
        local isOwned = myShop == shopId
        CreateShopBlip(shopId, shop, isOwned)
    end
end

local function RemoveAllBlips()
    for shopId, blip in pairs(shopBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
        shopBlips[shopId] = nil
    end
end

CreateThread(function()
    while not QBX do
        Wait(100)
    end

    Wait(2000)

    local playerShopData = lib.callback.await('rm-ownableshops:server:getShopData', false)
    local allShopData = lib.callback.await('rm-ownableshops:server:getAllShopOwnership', false)

    if playerShopData then
        myShop = playerShopData.shop_id
    end

    for shopId, shop in pairs(Config.Shops) do
        local ped = CreateShopPed(shop.coords, shop.ped and joaat(shop.ped))
        shopPeds[shopId] = ped

        local isOwner = myShop == shopId
        local isOwned = allShopData[shopId] ~= nil

        SetupShopTarget(ped, shopId, isOwner, isOwned)

        CreateShopBlip(shopId, shop, isOwner)
    end
end)

RegisterNetEvent('rm-ownableshops:client:updateOwnership', function(shopId)
    myShop = shopId
    Wait(1000)
    RefreshAllTargets()
end)

RegisterNetEvent('rm-ownableshops:client:refreshBlips', function()
    CreateThread(function()
        Wait(1000)

        local playerShopData = lib.callback.await('rm-ownableshops:server:getShopData', false)
        local allShopData = lib.callback.await('rm-ownableshops:server:getAllShopOwnership', false)

        myShop = playerShopData and playerShopData.shop_id or nil

        for shopId, shop in pairs(Config.Shops) do
            local isOwner = myShop == shopId
            CreateShopBlip(shopId, shop, isOwner)
        end

        RefreshAllTargets()
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        RemoveAllBlips()
    end
end)
