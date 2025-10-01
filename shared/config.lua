Config = {}

Config.Debug = false -- Set to true to enable debug prints

Config.Core = 'qbx'  -- qb  or qbx
Config.Inventory = 'ox_inventory'
Config.Target = 'qb-target' -- (qb-target, ox_target)
Config.Notify = 'qb' -- 'qb' or 'ox'

Config.Language = 'en' -- Language file to use from locales folder

Config.SellPercentage = 30 -- Percentage of the shop's value that can be sold back to the server
Config.MaxOwnedShops = 1 -- Maximum shops a player can own

Config.BlacklistedItems = {
    'weapon_pistol',
    'weapon_ceramicpistol',
    'weapon_combatpistol',
    'weapon_appistol',
    'weapon_pistol50',
    'weapon_revolver',
    'weapon_assaultsmg',
    'weapon_assaultrifle',
    'weapon_carbineriflemk2',
    'weapon_advancedrifle',
    'weapon_grenade',
    'weapon_molotov',
    'weapon_machinepistol',
    'weapon_snspistol',
    'weapon_tecpistol',
    'weapon_microsmg',
    'weapon_marksmanrifle',
    'weapon_tacitalrifle',
    'weapon_bullpuprifle',
    'weapon_specialcarbine',
    'weapon_combatpdw',
    'weapon_dbshotgun',
    'weapon_pumpshotgun',
    'weapon_stungun',
    'money',
}

Config.Shops = {
    ['store_1'] = {
        label = 'Store [2]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1249.7787, -1455.1827, 4.3200, 121.2277),
        blip = false, -- No blip for this shop
    },
    ['store_2'] = {
        label = 'Store [2]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1255.3479, -1447.2717, 4.3511, 125.0126),
        blip = false, -- No blip for this shop
    },
    ['store_3'] = {
        label = 'Store [3]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1263.6788, -1435.6654, 4.3513, 124.5727),
        blip = false, -- No blip for this shop
    },
    ['store_4'] = {
        label = 'Store [4]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1271.1761, -1425.0753, 4.3506, 124.6829),
        blip = false, -- No blip for this shop
    },
    ['store_5'] = {
        label = 'Store [5]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1274.0229, -1420.5240, 4.3454, 124.3990),
        blip = false, -- No blip for this shop
    },
    ['store_6'] = {
        label = 'Store [6]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1277.0986, -1416.8977, 4.3449, 124.5174),
        blip = false, -- No blip for this shop
    },
    ['store_7'] = {
        label = 'Store [7]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1279.0920, -1412.8760, 4.3347, 123.3198),
        blip = false, -- No blip for this shop
    },
    ['store_8'] = {
        label = 'Store [8]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1265.6876, -1431.7007, 4.3507, 122.7710),
        blip = false, -- No blip for this shop
    },
    ['store_9'] = {
        label = 'Store [9]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1260.2546, -1439.4166, 4.3506, 127.9091),
        blip = false, -- No blip for this shop
    },
    ['store_10'] = {
        label = 'Store [10]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1257.6122, -1443.0795, 4.3506, 124.4651),
        blip = false, -- No blip for this shop
    },
    ['store_11'] = {
        label = 'Store [11]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1252.3571, -1450.7645, 4.3514, 125.3148),
        blip = false, -- No blip for this shop
    },
    ['store_12'] = {
        label = 'Store [12]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1239.2449, -1452.7708, 4.3142, 218.5015),
        blip = false, -- No blip for this shop
    },
    ['store_13'] = {
        label = 'Store [13]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1235.1150, -1449.6586, 4.3260, 214.2309),
        blip = false, -- No blip for this shop
    },
    ['store_14'] = {
        label = 'Store [14]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1227.7970, -1444.6852, 4.3190, 214.2269),
        blip = false, -- No blip for this shop
    },
    ['store_15'] = {
        label = 'Store [15]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1223.9193, -1441.8987, 4.3255, 220.6904),
        blip = false, -- No blip for this shop
    },
    ['store_16'] = {
        label = 'Store [16]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1220.1780, -1439.4515, 4.3252, 211.9626),
        blip = false, -- No blip for this shop
    },
    ['store_17'] = {
        label = 'Store [17]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1216.7346, -1436.8871, 4.3319, 214.3930),
        blip = false, -- No blip for this shop
    },
    ['store_18'] = {
        label = 'Store [18]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1203.4642, -1455.0739, 4.3682, 35.8166),
        blip = false, -- No blip for this shop
    },
    ['store_19'] = {
        label = 'Store [19]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1207.3582, -1457.9745, 4.3580, 33.9812),
        blip = false, -- No blip for this shop
    },
    ['store_20'] = {
        label = 'Store [20]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1211.1115, -1460.5598, 4.3449, 36.2112),
        blip = false, -- No blip for this shop
    },
    ['store_21'] = {
        label = 'Store [21]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1214.9545, -1463.2412, 4.3390, 34.6128),
        blip = false, -- No blip for this shop
    },
    ['store_22'] = {
        label = 'Store [22]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1219.0032, -1465.8184, 4.3289, 36.6666),
        blip = false, -- No blip for this shop
    },
    ['store_23'] = {
        label = 'Store [23]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1222.3132, -1468.5059, 4.3213, 35.0529),
        blip = false, -- No blip for this shop
    },
    ['store_24'] = {
        label = 'Store [24]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1226.1809, -1471.2992, 4.3186, 33.8369),
        blip = false, -- No blip for this shop
    },
    ['store_25'] = {
        label = 'Store [25]',
        price = 100000,
        ped = 'mp_m_shopkeep_01',
        coords = vector4(-1230.4152, -1474.4578, 4.3091, 34.2760),
        blip = false, -- No blip for this shop
    },
    -- Add more shop locations here
}