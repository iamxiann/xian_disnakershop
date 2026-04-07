local function getPlayer(source)
    return exports.qbx_core:GetPlayer(source)
end

local function isGovManager(source)
    if not Config.ManageStore.enable then return false end
    local player = getPlayer(source)
    if not player then return false end
    local job = player.PlayerData.job
    if not job then return false end
    return job.name == Config.ManageStore.Job and job.grade.level >= Config.ManageStore.Grade
end

local validStashIds = {}
CreateThread(function()
    for _, store in ipairs(Config.Store) do
        validStashIds[store.stashId] = true
    end
end)

---@param stashId string
---@return boolean
local function isValidStashId(stashId)
    return type(stashId) == 'string' and validStashIds[stashId] == true
end

local PROXIMITY_RADIUS = 5.0

---@param source number
---@return boolean
local function isNearStore(source)
    local ped    = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    for _, store in ipairs(Config.Store) do
        if #(coords - store.coords) <= PROXIMITY_RADIUS then
            return true
        end
    end
    return false
end

local MAX_AMOUNT = 10000

---@param amount any
---@return boolean
local function isValidAmount(amount)
    if type(amount) ~= 'number' then return false end
    if amount < 1 then return false end
    if math.floor(amount) ~= amount then return false end
    if amount > MAX_AMOUNT then return false end
    return true
end

---@param itemName any
---@return boolean
local function isValidItemName(itemName)
    return type(itemName) == 'string' and #itemName > 0 and #itemName <= 64
end

local processing = {}

---@param source number
---@return boolean
local function acquireLock(source)
    if processing[source] then return false end
    processing[source] = true
    return true
end

---@param source number
local function releaseLock(source)
    processing[source] = nil
end

local sellableItems = {}
CreateThread(function()
    for _, cat in ipairs(Config.Sells) do
        for _, cfg in ipairs(cat.items) do
            sellableItems[cfg.item] = cfg.price
        end
    end
end)

local registeredStashes = {}

local function ensureStashRegistered(stashId)
    if registeredStashes[stashId] then return end
    registeredStashes[stashId] = true
    exports.ox_inventory:RegisterStash(stashId, 'Disnaker Store Stock', 100, 1000000, false, nil, nil)
end

CreateThread(function()
    for _, store in ipairs(Config.Store) do
        ensureStashRegistered(store.stashId)
    end
end)

local function logTransaction(action, source, itemName, amount, price)
    local player    = getPlayer(source)
    local name      = player and player.PlayerData.charinfo and
                      ('%s %s'):format(player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname)
                      or tostring(source)
    local citizenId = player and player.PlayerData.citizenid or 'unknown'
    print(('[DISNAKER] %s | %s (%s) | Item: %s | Jml: %d | Total: $%d')
          :format(action, name, citizenId, itemName, amount, amount * price))
end

lib.callback.register('xian_disnakershop:getPlayerItems', function(source)
    local items = {}

    local inventoryItems = exports.ox_inventory:GetInventoryItems(source)
    if inventoryItems and type(inventoryItems) == 'table' then
        for _, item in pairs(inventoryItems) do
            if item and item.name and item.count and item.count > 0
            and sellableItems[item.name] then
                items[#items + 1] = {
                    name  = item.name,
                    label = item.label or item.name,
                    count = item.count,
                }
            end
        end
        return items
    end

    local inventory = exports.ox_inventory:GetInventory(source, false)
    if not inventory then return {} end

    for _, item in pairs(inventory.items or {}) do
        if item and item.name and item.count and item.count > 0
        and sellableItems[item.name] then
            items[#items + 1] = {
                name  = item.name,
                label = item.label or item.name,
                count = item.count,
            }
        end
    end
    return items
end)

lib.callback.register('xian_disnakershop:getStoreStock', function(source, stashId)
    if not isValidStashId(stashId) then return {} end

    local stash = exports.ox_inventory:GetInventory(stashId, false)
    if not stash then return {} end

    local stock = {}
    for _, item in pairs(stash.items or {}) do
        if item and item.name and item.count > 0 then
            stock[item.name] = (stock[item.name] or 0) + item.count
        end
    end
    return stock
end)

lib.callback.register('xian_disnakershop:sellItem', function(source, stashId, itemName, amount, pricePerItem)
    -- [SEC] Validasi input dasar
    if not isValidAmount(amount)    then return false, 'Jumlah tidak valid.'  end
    if not isValidItemName(itemName) then return false, 'Item tidak valid.'   end
    if not isValidStashId(stashId)  then return false, 'Toko tidak valid.'   end

    -- [SEC] Cek proximity: player harus dekat NPC toko
    if not isNearStore(source) then
        return false, 'Kamu tidak berada di dekat toko.'
    end

    -- [SEC] Mutex: cegah race condition
    if not acquireLock(source) then
        return false, 'Transaksi sedang diproses, coba lagi.'
    end

    local player = getPlayer(source)
    if not player then
        releaseLock(source)
        return false, 'Player tidak ditemukan.'
    end

    -- Validasi item & harga dari config
    local validItem = false
    for _, cat in ipairs(Config.Sells) do
        for _, cfg in ipairs(cat.items) do
            if cfg.item == itemName and cfg.price == pricePerItem then
                validItem = true
                break
            end
        end
        if validItem then break end
    end
    if not validItem then
        releaseLock(source)
        return false, 'Item tidak valid untuk dijual.'
    end

    local playerCount = exports.ox_inventory:GetItemCount(source, itemName)
    if playerCount < amount then
        releaseLock(source)
        return false, ('Kamu hanya punya %d %s.'):format(playerCount, itemName)
    end

    local removed = exports.ox_inventory:RemoveItem(source, itemName, amount)
    if not removed then
        releaseLock(source)
        return false, 'Gagal mengambil item dari inventarismu.'
    end

    local added = exports.ox_inventory:AddItem(stashId, itemName, amount)
    if not added then
        exports.ox_inventory:AddItem(source, itemName, amount)
        releaseLock(source)
        return false, 'Gagal memasukkan item ke stok toko. Coba lagi.'
    end

    local totalPrice = amount * pricePerItem
    player.Functions.AddMoney('cash', totalPrice, 'disnaker-sell-' .. itemName)

    logTransaction('SELL', source, itemName, amount, pricePerItem)

    releaseLock(source)
    return true, ('Berhasil jual %d %s seharga $%d!'):format(amount, itemName, totalPrice)
end)

lib.callback.register('xian_disnakershop:buyItem', function(source, stashId, itemName, amount, pricePerItem)
    -- [SEC] Validasi input dasar
    if not isValidAmount(amount)    then return false, 'Jumlah tidak valid.'  end
    if not isValidItemName(itemName) then return false, 'Item tidak valid.'   end
    if not isValidStashId(stashId)  then return false, 'Toko tidak valid.'   end

    if not isNearStore(source) then
        return false, 'Kamu tidak berada di dekat toko.'
    end

    if not acquireLock(source) then
        return false, 'Transaksi sedang diproses, coba lagi.'
    end

    local player = getPlayer(source)
    if not player then
        releaseLock(source)
        return false, 'Player tidak ditemukan.'
    end

    local validItem = false
    for _, cat in ipairs(Config.Buy) do
        for _, cfg in ipairs(cat.items) do
            if cfg.item == itemName and cfg.price == pricePerItem then
                validItem = true
                break
            end
        end
        if validItem then break end
    end
    if not validItem then
        releaseLock(source)
        return false, 'Item tidak valid untuk dibeli.'
    end

    local stashCount = exports.ox_inventory:GetItemCount(stashId, itemName)
    if stashCount < amount then
        releaseLock(source)
        return false, ('Stok tidak cukup. Stok tersedia: %d'):format(stashCount)
    end

    local totalPrice = amount * pricePerItem
    local playerCash = player.PlayerData.money['cash'] or 0
    if playerCash < totalPrice then
        releaseLock(source)
        return false, ('Uang tidak cukup. Kamu punya $%d, butuh $%d.'):format(playerCash, totalPrice)
    end

    local moneyRemoved = player.Functions.RemoveMoney('cash', totalPrice, 'disnaker-buy-' .. itemName)
    if not moneyRemoved then
        releaseLock(source)
        return false, 'Gagal memotong uang.'
    end

    local removed = exports.ox_inventory:RemoveItem(stashId, itemName, amount)
    if not removed then
        player.Functions.AddMoney('cash', totalPrice, 'disnaker-refund-' .. itemName)
        releaseLock(source)
        return false, 'Gagal mengambil item dari stok toko. Coba lagi.'
    end

    local added = exports.ox_inventory:AddItem(source, itemName, amount)
    if not added then
        player.Functions.AddMoney('cash', totalPrice, 'disnaker-refund-' .. itemName)
        exports.ox_inventory:AddItem(stashId, itemName, amount)
        releaseLock(source)
        return false, 'Inventarismu penuh atau gagal menambahkan item.'
    end

    logTransaction('BUY', source, itemName, amount, pricePerItem)

    releaseLock(source)
    return true, ('Berhasil beli %d %s seharga $%d!'):format(amount, itemName, totalPrice)
end)

RegisterNetEvent('xian_disnakershop:openStash', function(stashId)
    local source = source

    if not isGovManager(source) then
        lib.notify(source, { title = 'Disnaker', description = 'Kamu tidak punya akses ke stash ini.', type = 'error' })
        return
    end

    if not isValidStashId(stashId) then
        lib.notify(source, { title = 'Disnaker', description = 'Stash tidak valid.', type = 'error' })
        return
    end

    ensureStashRegistered(stashId)
    TriggerClientEvent('xian_disnakershop:openStashClient', source, stashId)
end)