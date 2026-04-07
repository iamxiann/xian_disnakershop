local spawnedPeds = {}

local openSellMenu, openBuyMenu, openStockViewMenu

local function isGovManager()
    if not Config.ManageStore.enable then return false end
    local playerData = exports.qbx_core:GetPlayerData()
    if not playerData then return false end
    local job = playerData.job
    if not job then return false end
    return job.name == Config.ManageStore.Job and job.grade.level >= Config.ManageStore.Grade
end

local function isValidStashId(stashId)
    if type(stashId) ~= 'string' then return false end
    for _, store in ipairs(Config.Store) do
        if store.stashId == stashId then return true end
    end
    return false
end

RegisterNetEvent('xian_disnakershop:openStashClient', function(stashId)
    if not isValidStashId(stashId) then return end
    exports.ox_inventory:openInventory('stash', stashId)
end)

local function openSellAmountInput(storeData, itemCfg, maxCount)
    local input = lib.inputDialog('Jual ' .. itemCfg.label, {
        { type = 'number', label = ('Jumlah (maks: %d)'):format(maxCount), required = true, min = 1, max = maxCount },
    })

    if not input or not input[1] then return end

    local amount = math.floor(tonumber(input[1]) or 0)
    if amount < 1 then return end

    local confirm = lib.alertDialog({
        header   = 'Konfirmasi Jual',
        content  = ('Jual **%d** %s seharga **$%d** total?'):format(amount, itemCfg.label, amount * itemCfg.price),
        centered = true,
        cancel   = true,
    })
    if confirm ~= 'confirm' then return end

    lib.callback('xian_disnakershop:sellItem', false, function(success, msg)
        lib.notify({ title = 'Disnaker', description = msg, type = success and 'success' or 'error' })
        if success then openSellMenu(storeData) end
    end, storeData.stashId, itemCfg.item, amount, itemCfg.price)
end

local function openSellCategoryItems(storeData, category, inventoryLookup)
    local menuOptions = {}
    for _, item in ipairs(category.items) do
        local count = inventoryLookup[item.item]
        if count and count > 0 then
            menuOptions[#menuOptions + 1] = {
                title       = item.label,
                description = ('Stok kamu: %d | Harga: $%d / item'):format(count, item.price),
                icon        = 'money-bill',
                metadata    = {
                    { label = 'Item',  value = item.item },
                    { label = 'Stok',  value = count     },
                    { label = 'Harga', value = ('$%d'):format(item.price) },
                },
                onSelect = function()
                    openSellAmountInput(storeData, item, count)
                end,
            }
        end
    end

    if #menuOptions == 0 then
        lib.notify({ title = 'Disnaker', description = 'Tidak ada item dari kategori ini yang kamu miliki.', type = 'error' })
        return
    end

    lib.registerContext({
        id      = 'disnaker_sell_cat',
        title   = ('💰 Jual — %s'):format(category.name),
        menu    = 'disnaker_sell_menu',
        options = menuOptions,
    })
    lib.showContext('disnaker_sell_cat')
end

openSellMenu = function(storeData)
    lib.callback('xian_disnakershop:getPlayerItems', false, function(playerItems)
        playerItems = playerItems or {}

        if #playerItems == 0 then
            lib.notify({ title = 'Disnaker', description = 'Kamu tidak punya item untuk dijual.', type = 'error' })
            return
        end

        local inventoryLookup = {}
        for _, inv in ipairs(playerItems) do
            inventoryLookup[inv.name] = inv.count
        end

        local categoryOptions = {}
        for _, category in ipairs(Config.Sells) do
            local ownedCount = 0
            for _, item in ipairs(category.items) do
                if inventoryLookup[item.item] then
                    ownedCount = ownedCount + 1
                end
            end

            categoryOptions[#categoryOptions + 1] = {
                title       = category.name,
                description = ownedCount > 0
                    and ('Kamu punya %d jenis item dari kategori ini'):format(ownedCount)
                    or  'Tidak ada item dari kategori ini di inventarismu',
                icon        = ownedCount > 0 and 'boxes-stacked' or 'box-open',
                disabled    = ownedCount == 0,
                onSelect    = function()
                    if ownedCount == 0 then return end
                    openSellCategoryItems(storeData, category, inventoryLookup)
                end,
            }
        end

        lib.registerContext({
            id      = 'disnaker_sell_menu',
            title   = '💰 Jual Item — Pilih Kategori',
            menu    = 'disnaker_main_menu',
            options = categoryOptions,
        })
        lib.showContext('disnaker_sell_menu')
    end)
end

local function openBuyAmountInput(storeData, itemCfg, maxStock)
    local input = lib.inputDialog('Beli ' .. itemCfg.label, {
        { type = 'number', label = ('Jumlah (maks stok: %d)'):format(maxStock), required = true, min = 1, max = maxStock },
    })

    if not input or not input[1] then return end

    local amount = math.floor(tonumber(input[1]) or 0)
    if amount < 1 then return end

    local confirm = lib.alertDialog({
        header   = 'Konfirmasi Beli',
        content  = ('Beli **%d** %s seharga **$%d** total?'):format(amount, itemCfg.label, amount * itemCfg.price),
        centered = true,
        cancel   = true,
    })
    if confirm ~= 'confirm' then return end

    lib.callback('xian_disnakershop:buyItem', false, function(success, msg)
        lib.notify({ title = 'Disnaker', description = msg, type = success and 'success' or 'error' })
        if success then openBuyMenu(storeData) end
    end, storeData.stashId, itemCfg.item, amount, itemCfg.price)
end

local function openBuyCategoryItems(storeData, category, stock)
    local menuOptions = {}
    for _, item in ipairs(category.items) do
        local currentStock = stock[item.item] or 0
        menuOptions[#menuOptions + 1] = {
            title       = item.label,
            description = ('Stok: %d | Harga: $%d / item'):format(currentStock, item.price),
            icon        = currentStock > 0 and 'cart-shopping' or 'ban',
            disabled    = currentStock < 1,
            metadata    = {
                { label = 'Item',  value = item.item    },
                { label = 'Stok',  value = currentStock },
                { label = 'Harga', value = ('$%d'):format(item.price) },
            },
            onSelect = function()
                if currentStock < 1 then return end
                openBuyAmountInput(storeData, item, currentStock)
            end,
        }
    end

    if #menuOptions == 0 then
        lib.notify({ title = 'Disnaker', description = 'Tidak ada item di kategori ini.', type = 'error' })
        return
    end

    lib.registerContext({
        id      = 'disnaker_buy_cat',
        title   = ('🛒 Beli — %s'):format(category.name),
        menu    = 'disnaker_buy_menu',
        options = menuOptions,
    })
    lib.showContext('disnaker_buy_cat')
end

openBuyMenu = function(storeData)
    lib.callback('xian_disnakershop:getStoreStock', false, function(stock)
        if not stock then
            lib.notify({ title = 'Disnaker', description = 'Gagal mengambil data stok.', type = 'error' })
            return
        end

        local categoryOptions = {}
        for _, category in ipairs(Config.Buy) do
            local totalStock = 0
            for _, item in ipairs(category.items) do
                totalStock = totalStock + (stock[item.item] or 0)
            end

            categoryOptions[#categoryOptions + 1] = {
                title       = category.name,
                description = totalStock > 0
                    and ('Tersedia %d total stok'):format(totalStock)
                    or  'Stok kosong',
                icon        = totalStock > 0 and 'cart-shopping' or 'ban',
                onSelect    = function()
                    openBuyCategoryItems(storeData, category, stock)
                end,
            }
        end

        if #categoryOptions == 0 then
            lib.notify({ title = 'Disnaker', description = 'Tidak ada item tersedia untuk dibeli.', type = 'error' })
            return
        end

        lib.registerContext({
            id      = 'disnaker_buy_menu',
            title   = '🛒 Beli Item — Pilih Kategori',
            menu    = 'disnaker_main_menu',
            options = categoryOptions,
        })
        lib.showContext('disnaker_buy_menu')
    end, storeData.stashId)
end

openStockViewMenu = function(storeData, stock)
    local allItems  = {}
    local seenItems = {}

    for _, category in ipairs(Config.Sells) do
        for _, cfg in ipairs(category.items) do
            if not seenItems[cfg.item] then
                seenItems[cfg.item] = true
                allItems[#allItems + 1] = { label = cfg.label, item = cfg.item }
            end
        end
    end
    for _, category in ipairs(Config.Buy) do
        for _, cfg in ipairs(category.items) do
            if not seenItems[cfg.item] then
                seenItems[cfg.item] = true
                allItems[#allItems + 1] = { label = cfg.label, item = cfg.item }
            end
        end
    end

    local menuOptions = {}
    for _, v in ipairs(allItems) do
        local qty = stock[v.item] or 0
        menuOptions[#menuOptions + 1] = {
            title       = v.label,
            description = ('Stok: **%d**'):format(qty),
            icon        = qty > 0 and 'boxes-stacked' or 'box-open',
            readOnly    = true,
            metadata    = {
                { label = 'Item Name', value = v.item },
                { label = 'Stok',      value = qty    },
            },
        }
    end

    lib.registerContext({
        id      = 'disnaker_stock_view',
        title   = '📊 Stok Disnaker',
        menu    = 'disnaker_manage_menu',
        options = menuOptions,
    })
    lib.showContext('disnaker_stock_view')
end

local function openManageMenu(storeData)
    lib.callback('xian_disnakershop:getStoreStock', false, function(stock)
        if not stock then
            lib.notify({ title = 'Disnaker', description = 'Gagal mengambil data stok.', type = 'error' })
            return
        end

        lib.registerContext({
            id      = 'disnaker_manage_menu',
            title   = '⚙️ Manage Disnaker Store',
            menu    = 'disnaker_main_menu',
            options = {
                {
                    title       = '📦 Lihat & Kelola Stash',
                    description = 'Buka stash toko untuk tambah/ambil stok',
                    icon        = 'box-open',
                    onSelect    = function()
                        TriggerServerEvent('xian_disnakershop:openStash', storeData.stashId)
                    end,
                },
                {
                    title       = '📊 Lihat Stok Saat Ini',
                    description = 'Tampilkan semua stok item di toko',
                    icon        = 'chart-bar',
                    onSelect    = function()
                        openStockViewMenu(storeData, stock)
                    end,
                },
            },
        })
        lib.showContext('disnaker_manage_menu')
    end, storeData.stashId)
end

local function openMainMenu(storeData)
    local options = {
        {
            title       = '💰 Jual Item',
            description = 'Jual item dari inventarismu ke toko',
            icon        = 'hand-holding-dollar',
            onSelect    = function() openSellMenu(storeData) end,
        },
        {
            title       = '🛒 Beli Item',
            description = 'Beli item dari stok toko yang tersedia',
            icon        = 'cart-shopping',
            onSelect    = function() openBuyMenu(storeData) end,
        },
    }

    if isGovManager() then
        options[#options + 1] = {
            title       = '⚙️ Manage Store (GOV)',
            description = 'Kelola stok toko — lihat, tambah, atau ambil item',
            icon        = 'screwdriver-wrench',
            onSelect    = function() openManageMenu(storeData) end,
        }
    end

    lib.registerContext({
        id      = 'disnaker_main_menu',
        title   = ('🏪 %s — Disnaker'):format(storeData.name),
        options = options,
    })
    lib.showContext('disnaker_main_menu')
end

local function spawnPed(storeData)
    local model = GetHashKey(storeData.ped)
    RequestModel(model)

    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end

    if not HasModelLoaded(model) then
        print('[xian_disnakershop] Gagal load model ped: ' .. storeData.ped)
        return
    end

    local ped = CreatePed(4, model, storeData.coords.x, storeData.coords.y, storeData.coords.z - 1.0, storeData.heading, false, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetModelAsNoLongerNeeded(model)

    spawnedPeds[#spawnedPeds + 1] = ped

    exports.ox_target:addLocalEntity(ped, {
        {
            name     = 'xian_disnakershop',
            label    = 'Disnaker Store',
            icon     = 'fa-solid fa-store',
            distance = 2.5,
            onSelect = function()
                openMainMenu(storeData)
            end,
        },
    })
end

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, store in ipairs(Config.Store) do
        spawnPed(store)
    end
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
end)