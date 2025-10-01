local function Notify(source, typ, description)
    if Config.Notify == 'qb' then
        TriggerClientEvent('QBCore:Notify', source, description, typ or 'primary')
    else
        TriggerClientEvent('ox_lib:notify', source, { type = typ or 'inform', description = description })
    end
end
local QBX = exports['qb-core']:GetCoreObject()

local function GetPlayerLicenseIdentifier(playerId)
    local license = QBX.Functions.GetIdentifier(playerId, 'license2')
    if not license or license == '' then
        license = QBX.Functions.GetIdentifier(playerId, 'license')
    end
    return license
end

local function GetPlayerNameSafe(playerId)
    local name = GetPlayerName(playerId)
    if not name or name == '' then
        name = ('player_%s'):format(tostring(playerId))
    end
    return name
end

local function SendDiscordLog(key, description, fields)
    if not Config or not Config.Webhooks then return end
    local cfg = Config.Webhooks[key]
    if not cfg or not cfg.url or cfg.url == '' then return end
    local embed = {
        title = cfg.title or key,
        description = description,
        color = cfg.color or 16777215,
        fields = fields,
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    }
    PerformHttpRequest(cfg.url, function() end, 'POST', json.encode({ embeds = { embed } }), { ['Content-Type'] = 'application/json' })
end

local function IsItemBlacklisted(itemName)
    local list = Config.BlacklistedItems
    if not list then return false end
    local name = string.lower(itemName)
    if #list > 0 then
        for _, v in ipairs(list) do
            if type(v) == 'string' and string.lower(v) == name then
                return true
            end
        end
        return false
    else
        for k in pairs(list) do
            if string.lower(k) == name then
                return true
            end
        end
        return false
    end
end

if not Config then
    Config = {}
    Config.Shops = {}
end

local buyHook = nil

function LoadAllShops()
    local shops = MySQL.query.await('SELECT * FROM player_shops')
    if not shops then 
        if Config.Debug then
            print("No shops found in database")
        end
        return 
    end

    if Config.Debug then
        print("Loading " .. #shops .. " shops from database")
    end
    for _, shopData in ipairs(shops) do
        local items = json.decode(shopData.items or '[]')
        RegisterShopWithOxInventory(shopData.shop_id, items)
    end
    
    SetupShopHooks()
end

MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `player_shops` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `shop_id` VARCHAR(50) NOT NULL,
            `owner_license` VARCHAR(50) NOT NULL,
            `money` INT DEFAULT 0,
            `items` JSON DEFAULT '[]',
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_owner` (`owner_license`),
            INDEX `idx_shop` (`shop_id`)
        ) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `shop_transactions` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `shop_id` VARCHAR(50) NOT NULL,
            `item_name` VARCHAR(50) NOT NULL,
            `amount` INT NOT NULL,
            `price` INT NOT NULL,
            `type` ENUM('buy', 'sell') NOT NULL,
            `buyer_license` VARCHAR(50) NOT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_shop_trans` (`shop_id`),
            INDEX `idx_buyer` (`buyer_license`)
        ) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    LoadAllShops()
end)

function RegisterShopWithOxInventory(shopId, items)
    local shop = Config.Shops[shopId]
    if not shop then 
        if Config.Debug then
            print("ERROR: Shop config not found for ID: " .. tostring(shopId))
        end
        return 
    end

    local inventory = {}

    if items and #items > 0 then
        for _, item in ipairs(items) do
            if item.name and item.price and item.amount and item.amount > 0 then
                table.insert(inventory, {
                    name = item.name,
                    price = item.price,
                    count = item.amount
                })
            end
        end
    end

    local success, error = pcall(function()
        exports.ox_inventory:RegisterShop(shopId, {
            name = shop.label,
            inventory = inventory
        })
    end)
    
    if success then
        if Config.Debug then
            print("Successfully registered shop: " .. shopId .. " with " .. #inventory .. " items")
        end
    else
        if Config.Debug then
            print("ERROR registering shop " .. shopId .. ": " .. tostring(error))
        end
    end
end

lib.addCommand('giveshop', {
    help = 'Give shop to player (Admin Only)',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'Player ID'
        },
        {
            name = 'shopid',
            type = 'string',
            help = 'Shop ID from config'
        }
    },
    restricted = 'group.admin'
}, function(source, args)
    local target = args.target
    local shopId = args.shopid
    
    if not Config.Shops[shopId] then
        Notify(source, 'error', 'Invalid shop ID')
        return
    end

    local targetPlayer = QBX.Functions.GetPlayer(target)
    if not targetPlayer then
        Notify(source, 'error', 'Player not found')
        return
    end

    local license = GetPlayerLicenseIdentifier(target)
    
    MySQL.query('SELECT COUNT(*) as c FROM player_shops WHERE owner_license = ?', {license}, function(result)
        local ownedCount = (result and result[1] and result[1].c) or 0
        local maxAllowed = Config.MaxOwnedShops or 1
        if ownedCount >= maxAllowed then
            Notify(source, 'error', 'Player reached maximum owned shops')
            return
        end

        MySQL.insert('INSERT INTO player_shops (shop_id, owner_license) VALUES (?, ?)', {
            shopId, license
        }, function()
            Notify(target, 'success', 'You received ownership of a shop!')
            Notify(source, 'success', 'Shop given to player')
            TriggerClientEvent('rm-ownableshops:client:updateOwnership', target, shopId)
            
            RegisterShopWithOxInventory(shopId, {})
            
            TriggerClientEvent('rm-ownableshops:client:refreshBlips', -1)
            SendDiscordLog('shop_purchase', ('%s gave shop %s to %s'):format(GetPlayerNameSafe(source), shopId, GetPlayerNameSafe(target)), {
                { name = 'Admin', value = GetPlayerNameSafe(source), inline = true },
                { name = 'Target', value = GetPlayerNameSafe(target), inline = true },
                { name = 'Target License', value = license or 'unknown', inline = true },
                { name = 'Shop ID', value = shopId, inline = true }
            })
        end)
    end)
end)

lib.callback.register('rm-ownableshops:server:buyShop', function(source, shopId)
    local Player = QBX.Functions.GetPlayer(source)
    if not Player then return false end

    local license = GetPlayerLicenseIdentifier(source)
    
    local ownedRow = MySQL.query.await('SELECT COUNT(*) as c FROM player_shops WHERE owner_license = ?', {license})
    local ownedCount = (ownedRow and ownedRow[1] and ownedRow[1].c) or 0
    local maxAllowed = Config.MaxOwnedShops or 1
    if ownedCount >= maxAllowed then
        Notify(source, 'error', 'You reached maximum owned shops')
        return false
    end
    
    local shop = Config.Shops[shopId]
    if not shop then
        Notify(source, 'error', 'Invalid shop')
        return false
    end
    
    local shopData = MySQL.query.await('SELECT id FROM player_shops WHERE shop_id = ?', {shopId})
    if shopData and #shopData > 0 then
        Notify(source, 'error', 'This shop is already owned')
        return false
    end
    
    if Player.PlayerData.money.cash < shop.price then
        Notify(source, 'error', 'Not enough cash')
        return false
    end
    
    Player.Functions.RemoveMoney('cash', shop.price)
    MySQL.insert('INSERT INTO player_shops (shop_id, owner_license) VALUES (?, ?)', {
        shopId, license
    })

    exports.ox_inventory:RegisterShop(shopId, {
        name = shop.label,
        inventory = {}
    })
    
    SetupShopHooks()
    
    TriggerClientEvent('rm-ownableshops:client:refreshBlips', -1)
    
    SendDiscordLog('shop_purchase', ('%s purchased shop %s for $%s'):format(GetPlayerNameSafe(source), shopId, shop.price), {
        { name = 'Player', value = GetPlayerNameSafe(source), inline = true },
        { name = 'License', value = license or 'unknown', inline = true },
        { name = 'Shop ID', value = shopId, inline = true },
        { name = 'Price', value = tostring(shop.price), inline = true }
    })

    return true
end)

lib.callback.register('rm-ownableshops:server:getShopData', function(source, shopId)
    if shopId then
        local result = MySQL.query.await('SELECT * FROM player_shops WHERE shop_id = ?', {shopId})
        return result and result[1] or nil
    else
        local license = GetPlayerLicenseIdentifier(source)
        local result = MySQL.query.await('SELECT * FROM player_shops WHERE owner_license = ?', {license})
        return result and result[1] or nil
    end
end)

lib.callback.register('rm-ownableshops:server:getAllShopOwnership', function(source)
    local result = MySQL.query.await('SELECT shop_id, owner_license FROM player_shops')
    local ownership = {}
    
    if result then
        for _, shop in ipairs(result) do
            ownership[shop.shop_id] = shop.owner_license
        end
    end
    
    return ownership
end)

lib.callback.register('rm-ownableshops:server:getShopItems', function(source, shopId)
    local result = MySQL.query.await('SELECT * FROM player_shops WHERE shop_id = ?', {shopId})
    return result and result[1] or nil
end)

lib.callback.register('rm-ownableshops:server:addItemToShop', function(source, data)
    if Config.Debug then
        print("=== ADD ITEM TO SHOP DEBUG ===")
        print("Item name: " .. tostring(data.item))
        print("Item amount: " .. tostring(data.amount))
        print("Item price: " .. tostring(data.price))
        print("Blacklisted items table:")
        for item, value in pairs(Config.BlacklistedItems) do
            print("  - " .. item .. " = " .. tostring(value))
        end
    end
    
    local Player = QBX.Functions.GetPlayer(source)
    local license = GetPlayerLicenseIdentifier(source)
    
    local shop = MySQL.query.await('SELECT * FROM player_shops WHERE owner_license = ?', {license})
    if not shop or not shop[1] then return false end
    
    local isBlacklisted = IsItemBlacklisted(data.item)
    
    if isBlacklisted then
        if Config.Debug then
            print("Blacklisted item blocked: " .. data.item)
        end
        Notify(source, 'error', 'This item cannot be sold in shops')
        return false
    end
    
    if Config.Debug then
        print("Item passed blacklist check: " .. data.item)
    end
    
    local items = json.decode(shop[1].items or '[]')
    
    local itemInstances = exports.ox_inventory:Search(source, 'slots', data.item)
    local totalCount = 0
    if itemInstances then
        for _, instance in ipairs(itemInstances) do
            totalCount = totalCount + (instance.count or 1)
        end
    end
    if totalCount < data.amount then
        Notify(source, 'error', 'You don\'t have enough items')
        return false
    end
    
    local function isWeapon(itemName)
        return string.sub(itemName, 1, 7) == "weapon_"
    end
    local isWeaponItem = isWeapon(data.item)
    local toRemove = data.amount
    local stackableCount = 0
    local stackablePrice = data.price
    for i = 1, #itemInstances do
        local instance = itemInstances[i]
        local removeCount = math.min(toRemove, instance.count or 1)
        local removed = exports.ox_inventory:RemoveItem(source, data.item, removeCount, instance.metadata)
        if removed then
            if isWeaponItem then
                for j = 1, removeCount do
                    table.insert(items, {
                        name = data.item,
                        amount = 1,
                        price = data.price,
                        metadata = instance.metadata
                    })
                end
            else
                stackableCount = stackableCount + removeCount
            end
            toRemove = toRemove - removeCount
        end
        if toRemove <= 0 then break end
    end
    if stackableCount > 0 then
        local found = false
        for _, shopItem in ipairs(items) do
            if shopItem.name == data.item and shopItem.metadata == nil then
                shopItem.amount = (shopItem.amount or 0) + stackableCount
                shopItem.price = stackablePrice
                found = true
                break
            end
        end
        if not found then
            table.insert(items, {
                name = data.item,
                amount = stackableCount,
                price = stackablePrice
            })
        end
    end
    
    MySQL.update('UPDATE player_shops SET items = ? WHERE owner_license = ?', {
        json.encode(items), license
    })

    RegisterShopWithOxInventory(shop[1].shop_id, items)
    
    SetupShopHooks()
    SendDiscordLog('item_transaction', ('%s added %sx %s to shop %s for $%s each'):format(GetPlayerNameSafe(source), tostring(data.amount), tostring(data.item), shop[1].shop_id, tostring(data.price)), {
        { name = 'Player', value = GetPlayerNameSafe(source), inline = true },
        { name = 'License', value = license or 'unknown', inline = true },
        { name = 'Shop ID', value = shop[1].shop_id or 'unknown', inline = true },
        { name = 'Item', value = tostring(data.item), inline = true },
        { name = 'Amount', value = tostring(data.amount), inline = true },
        { name = 'Price', value = tostring(data.price), inline = true }
    })
    
    return true
end)

lib.callback.register('rm-ownableshops:server:checkShopHasItems', function(source, shopId)
    local shop = MySQL.query.await('SELECT * FROM player_shops WHERE shop_id = ?', {shopId})
    if not shop or not shop[1] then return false end
    
    local items = json.decode(shop[1].items or '[]')
    return #items > 0
end)

lib.callback.register('rm-ownableshops:server:collectMoney', function(source, shopId)
    local Player = QBX.Functions.GetPlayer(source)
    if not Player then return false end

    local license = GetPlayerLicenseIdentifier(source)
    
    local shop = MySQL.query.await('SELECT * FROM player_shops WHERE shop_id = ? AND owner_license = ?', {shopId, license})
    if not shop or not shop[1] then return false end
    
    local money = shop[1].money
    if money <= 0 then return false end
    
    Player.Functions.AddMoney('cash', money)
    MySQL.update('UPDATE player_shops SET money = 0 WHERE shop_id = ?', {shopId})
    
    return true, money
end)

lib.callback.register('rm-ownableshops:server:removeItemFromShop', function(source, data)
    local Player = QBX.Functions.GetPlayer(source)
    local license = GetPlayerLicenseIdentifier(source)
    
    local shop = MySQL.query.await('SELECT * FROM player_shops WHERE owner_license = ?', {license})
    if not shop or not shop[1] then return false end
    
    local items = json.decode(shop[1].items or '[]')
    local found = false
    local itemIndex = nil
    
    for i, item in ipairs(items) do
        if item.name == data.item then
            if item.amount < data.amount then
                Notify(source, 'error', 'Not enough items in shop')
                return false
            end
            found = true
            itemIndex = i
            break
        end
    end
    
    if not found then
        Notify(source, 'error', 'Item not found in shop')
        return false
    end
    
    if exports.ox_inventory:AddItem(source, data.item, data.amount) then
        items[itemIndex].amount = items[itemIndex].amount - data.amount
        if items[itemIndex].amount <= 0 then
            table.remove(items, itemIndex)
        end
        
        MySQL.update('UPDATE player_shops SET items = ? WHERE owner_license = ?', {
            json.encode(items), license
        })

        RegisterShopWithOxInventory(shop[1].shop_id, items)
        SendDiscordLog('item_transaction', ('%s removed %sx %s from shop %s'):format(GetPlayerNameSafe(source), tostring(data.amount), tostring(data.item), shop[1].shop_id), {
            { name = 'Player', value = GetPlayerNameSafe(source), inline = true },
            { name = 'License', value = license or 'unknown', inline = true },
            { name = 'Shop ID', value = shop[1].shop_id or 'unknown', inline = true },
            { name = 'Item', value = tostring(data.item), inline = true },
            { name = 'Amount', value = tostring(data.amount), inline = true }
        })
        
        return true
    end
    
    Notify(source, 'error', 'Could not add items to your inventory')
    return false
end)

function SetupShopHooks()
    if buyHook then 
        exports.ox_inventory:removeHooks(buyHook) 
    end

    local ownedShops = MySQL.query.await('SELECT shop_id FROM player_shops')
    local inventoryFilter = {}
    
    if ownedShops then
        for _, shop in ipairs(ownedShops) do
            table.insert(inventoryFilter, shop.shop_id)
        end
    end

    if #inventoryFilter > 0 then
        buyHook = exports.ox_inventory:registerHook('buyItem', function(payload)
            if Config.Debug then
                print("Shop purchase hook triggered:", json.encode(payload))
            end
            
            local shopId = payload.shopType
            local itemName = payload.itemName
            local count = payload.count
            local totalPrice = payload.totalPrice
            local buyerSource = payload.source

            local Player = QBX.Functions.GetPlayer(buyerSource)
            if not Player then
                if Config.Debug then
                    print("Player not found for source: " .. buyerSource)
                end
                return false
            end

            local playerMoney = Player.Functions.GetMoney('cash')
            if playerMoney < totalPrice then
                if Config.Debug then
                    print("Player doesn't have enough money. Has: " .. playerMoney .. ", Needs: " .. totalPrice)
                end
                Notify(buyerSource, 'error', 'You don\'t have enough money in your hands!')
                return false
            end

            local shop = MySQL.query.await('SELECT * FROM player_shops WHERE shop_id = ?', {shopId})
            if shop and shop[1] then
                local items = json.decode(shop[1].items or '[]')
                local updated = false
                local given = 0
                
                local itemExists = false
                local availableStock = 0
                
                for _, item in ipairs(items) do
                    if item.name == itemName then
                        itemExists = true
                        if itemName:sub(1,7) == "weapon_" then
                            availableStock = availableStock + 1
                        else
                            availableStock = availableStock + (item.amount or 1)
                        end
                    end
                end
                
                if not itemExists then
                    Notify(buyerSource, 'error', 'Item not available in this shop!')
                    return false
                end
                
                if availableStock < count then
                    Notify(buyerSource, 'error', 'Not enough stock available! Available: ' .. availableStock)
                    return false
                end

                Player.Functions.RemoveMoney('cash', totalPrice, 'shop-purchase')

                if itemName:sub(1,7) == "weapon_" then
                    for i = #items, 1, -1 do
                        local item = items[i]
                        if item.name == itemName and item.metadata and given < count then
                            exports.ox_inventory:AddItem(buyerSource, item.name, 1, item.metadata)
                            table.remove(items, i)
                            given = given + 1
                            updated = true
                        end
                        if given >= count then break end
                    end
                else
                    for i = #items, 1, -1 do
                        local item = items[i];
                        if item.name == itemName and item.metadata == nil then
                            local removeCount = math.min(count - given, item.amount or 1)
                            exports.ox_inventory:AddItem(buyerSource, item.name, removeCount)
                            item.amount = (item.amount or 1) - removeCount
                            given = given + removeCount
                            updated = true
                            if item.amount <= 0 then
                                table.remove(items, i)
                            end
                            if given >= count then break end
                        end
                    end
                end
                
                if updated then
                    MySQL.update('UPDATE player_shops SET items = ?, money = money + ? WHERE shop_id = ?', {
                        json.encode(items), totalPrice, shopId
                    })
                    
                    RegisterShopWithOxInventory(shopId, items)
                    
                    local license = GetPlayerLicenseIdentifier(buyerSource)
                    MySQL.insert('INSERT INTO shop_transactions (shop_id, item_name, amount, price, type, buyer_license) VALUES (?, ?, ?, ?, ?, ?)', {
                        shopId, itemName, count, totalPrice, 'buy', license
                    })
                    SendDiscordLog('item_transaction', ('%s bought %sx %s from shop %s for $%s'):format(GetPlayerNameSafe(buyerSource), count, itemName, shopId, totalPrice), {
                        { name = 'Player', value = GetPlayerNameSafe(buyerSource), inline = true },
                        { name = 'License', value = license or 'unknown', inline = true },
                        { name = 'Shop ID', value = shopId, inline = true },
                        { name = 'Item', value = itemName, inline = true },
                        { name = 'Amount', value = tostring(count), inline = true },
                        { name = 'Total Price', value = tostring(totalPrice), inline = true }
                    })
                    
                    Notify(buyerSource, 'success', 'Successfully purchased ' .. count .. 'x ' .. itemName .. ' for $' .. totalPrice)
                    
                    if Config.Debug then
                        print("Shop purchase processed: " .. itemName .. " x" .. count .. " from shop " .. shopId .. " for $" .. totalPrice)
                    end
                else
                    Player.Functions.AddMoney('cash', totalPrice, 'shop-purchase-refund')
                    Notify(buyerSource, 'error', 'Failed to process purchase. Money refunded.')
                    if Config.Debug then
                        print("Failed to process purchase, refunded $" .. totalPrice .. " to player")
                    end
                end
            else
                Player.Functions.AddMoney('cash', totalPrice, 'shop-purchase-refund')
                Notify(buyerSource, 'error', 'Shop not found. Money refunded.')
                if Config.Debug then
                    print("Shop not found, refunded $" .. totalPrice .. " to player")
                end
            end
            return false
        end, { inventoryFilter = inventoryFilter })
    end
end

RegisterNetEvent('rm-ownableshops:server:shopPurchased', function(shopId)
    local source = source
    TriggerClientEvent('rm-ownableshops:client:updateOwnership', source, shopId)
    TriggerClientEvent('rm-ownableshops:client:refreshBlips', -1)
end)

lib.callback.register('rm-ownableshops:server:sellShop', function(source, shopId)
    local Player = QBX.Functions.GetPlayer(source)
    if not Player then return false end
    local license = GetPlayerLicenseIdentifier(source)
    local shop = Config.Shops[shopId]
    if not shop then return false end
    local result = MySQL.query.await('SELECT * FROM player_shops WHERE shop_id = ? AND owner_license = ?', {shopId, license})
    if not result or not result[1] then return false end
    local sellPercentage = Config.SellPercentage or 30
    local sellAmount = math.floor(shop.price * (sellPercentage / 100))
    MySQL.query.await('DELETE FROM player_shops WHERE shop_id = ? AND owner_license = ?', {shopId, license})
    Player.Functions.AddMoney('cash', sellAmount)
    TriggerClientEvent('rm-ownableshops:client:updateOwnership', source, nil)
    TriggerClientEvent('rm-ownableshops:client:refreshBlips', -1)
    SendDiscordLog('shop_sale', ('%s sold shop %s for $%s'):format(GetPlayerNameSafe(source), shopId, sellAmount), {
        { name = 'Player', value = GetPlayerNameSafe(source), inline = true },
        { name = 'License', value = license or 'unknown', inline = true },
        { name = 'Shop ID', value = shopId, inline = true },
        { name = 'Amount', value = tostring(sellAmount), inline = true }
    })
    return true
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if buyHook then
            exports.ox_inventory:removeHooks(buyHook)
            if Config.Debug then
                print("Removed shop purchase hooks")
            end
        end
    end
end)
