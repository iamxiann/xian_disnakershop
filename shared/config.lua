Config = {}

Config.Target    = 'ox_target'
Config.Inventory = 'ox_inventory'

Config.ManageStore = {
    enable = false, -- Aktifkan manajemen toko
    Job   = 'gov',
    Grade = 9, 
}

-- Daftar toko / ped lokasi
Config.Store = {
    {
        name    = 'Disnaker',
        coords  = vector3(-428.82, 1100.15, 327.7),
        ped     = 'cs_solomon',
        heading = 342.59,
        stashId = 'disnaker_store_stock',
    },
}

Config.Sells = {
    {
        name  = 'Hasil Alam',
        items = {
            { label = 'Besi',    item = 'iron_ingot',    price = 40 },
            { label = 'Tembaga', item = 'copper_ingot', price = 40 },
            { label = 'Emas',    item = 'gold_ingot',    price = 80 },
            { label = 'Kristal', item = 'crystal_ingot', price = 80 },
            { label = 'Berlian', item = 'diamond_ingot', price = 80 },
            { label = 'Papan Kayu', item = 'wooden_plank', price = 40 },
            { label = 'Serbuk Kayu', item = 'wooden_dust', price = 30 },
        },
    },
    {
        name  = 'Produk Daging',
        items = {
            { label = 'Kemasan Ayam',    item = 'kemasan_ayam',    price = 40 },
            { label = 'Kemasan Daging',  item = 'kemasan_daging',  price = 60 },
        },
    },
    {
        name  = 'Hasil Recycle',
        items = {
            { label = 'Karet',    item = 'karet',    price = 80 },
            { label = 'Kaca',     item = 'kaca',     price = 80 },
            { label = 'Aluminium',item = 'aluminium',price = 80 },
            { label = 'Baja',     item = 'baja',     price = 80 },
            { label = 'Besi Tua', item = 'besi_tua', price = 80 },
        },
    },
    {
        name  = 'Hasil Penjahit',
        items = {
            { label = 'Clothing',item = 'clothing', price = 400 },
        },
    },
}

Config.Buy = {
    {
        name  = 'Hasil Alam',
        items = {
            { label = 'Besi',    item = 'besi',    price = 60 },
            { label = 'Tembaga', item = 'tembaga', price = 60 },
            { label = 'Emas',    item = 'emas',    price = 100 },
            { label = 'Kristal', item = 'kristal', price = 100 },
            { label = 'Berlian', item = 'berlian', price = 100 },
        },
    },
    {
        name  = 'Produk Daging',
        items = {
            { label = 'Kemasan Ayam',    item = 'kemasan_ayam',    price = 60 },
            { label = 'Kemasan Daging',  item = 'kemasan_daging',  price = 80 },
        },
    },
    {
        name  = 'Hasil Recycle',
        items = {
            { label = 'Karet',    item = 'karet',    price = 100 },
            { label = 'Kaca',     item = 'kaca',     price = 100 },
            { label = 'Aluminium',item = 'aluminium',price = 100 },
            { label = 'Baja',     item = 'baja',     price = 100 },
            { label = 'Besi Tua', item = 'besi_tua', price = 100 },
        },
    },
    {
        name  = 'Hasil Penjahit',
        items = {
            { label = 'Clothing',item = 'clothing', price = 450 },
        },
    },
}
