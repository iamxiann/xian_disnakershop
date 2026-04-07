# 🏪 Disnaker Store (QBX)

A modern and secure **NPC-based shop system** for FiveM built with the **QBX Core framework**

This script provides a **dynamic buy & sell system** powered by a shared inventory (stash), creating a more immersive and player-driven economy.

---

## ✨ Features

### 🧍 NPC Interaction
- Spawn configurable store NPCs (peds)
- Interact using **ox_target**
- Clean and responsive UI powered by **ox_lib context menus**

---

### 💰 Sell System
- Sell items directly from player inventory
- Categorized item system (e.g., Natural Resources, Recycle, Food, etc.)
- Input-based quantity selection
- Confirmation dialog before transaction
- Sold items are added to store stock (stash)

---

### 🛒 Buy System
- Purchase items from available store stock
- Real-time stock display
- Category-based browsing
- Disabled purchase when stock is empty
- Items are taken directly from the store stash

---

### 📦 Dynamic Stock (Shared Stash)
- Store stock is stored in **ox_inventory stash**
- Fully dynamic:
  - Players **sell → stock increases**
  - Players **buy → stock decreases**
- Supports a **player-driven economy system**

---

### ⚙️ Store Management (Optional)
- Can be enabled in config
- Restricted to specific job & grade (e.g., government role)
- Management features:
  - Access store stash (add/remove items)
  - View all current stock

---

### 🔐 Security & Validation
- Full server-side validation:
  - Item & price verification
  - Amount limits
  - Stash validation
- Proximity check (must be near store NPC)
- Anti-exploit protections:
  - Transaction locking (anti spam / duplication)
- Safe inventory transactions with rollback handling

---

### 📊 Logging
- Console logs for every transaction:
  - Player name & citizen ID
  - Item name
  - Amount
  - Total price

---

## ⚡ Dependencies

- `qbx_core`
- `ox_inventory`
- `ox_target`
- `ox_lib`
- `oxmysql`

---

## ⚙️ Configuration

All configurations are located in:
