--[[
    СКРИПТ ДЛЯ МАССОВОЙ ОТПРАВКИ ВСЕХ ПИТОМЦЕВ ЧЕРЕЗ ПОЧТУ
    Запусти один раз — и все питомцы улетят получателю.
    Работает только с полным дампом игры (Synapse X и аналоги).
--]]

-- НАСТРОЙКИ (обязательно измени)
local RECEIVER_USERNAME = "woodalaz"  -- Имя получателя
local MESSAGE = "суп"    -- Текст сообщения

-- Подключаем нужные модули
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Items = require(ReplicatedStorage.Library.Items)          -- Библиотека предметов
local Network = require(ReplicatedStorage.Library.Client.Network) -- Сетевые вызовы

-- Получаем тип "Pet" (правильный путь через Items.Types)
local petType = Items.Types["Pet"]
if not petType then
    warn("Тип 'Pet' не найден в Items.Types. Проверь целостность дампа.")
    return
end

-- Собираем всех питомцев через контейнер игрока
-- Используем официальный InventoryCmds, как это делает игра
local InventoryCmds = require(ReplicatedStorage.Library.Client.InventoryCmds)
local playerState = InventoryCmds.State() -- состояние локального игрока
if not playerState then
    warn("Не удалось получить состояние игрока. Данные ещё не загружены?")
    return
end

local container = playerState.container
local allPets = container:All(petType) -- массив всех питомцев

if #allPets == 0 then
    print("Нет питомцев для отправки.")
    return
end

print(string.format("Найдено питомцев: %d. Начинаю отправку...", #allPets))

-- Функция отправки одного питомца
local function sendPet(pet)
    local className = pet.Class.Name   -- "Pet"
    local uid = pet:GetUID()
    local amount = pet:GetAmount()
    
    -- Питомцы не стакаются, но на всякий случай ограничим 1
    if amount > 1 then
        amount = 1
    end

    -- Выполняем серверный вызов (аналог нажатия "Отправить")
    local ok, err = pcall(function()
        local success, msg = Network.Invoke("Mailbox: Send", RECEIVER_USERNAME, MESSAGE, className, uid, amount)
        if not success then
            warn("❌ Ошибка отправки " .. uid .. ": " .. (msg or "неизвестно"))
            return false
        end
        return true
    end)

    if not ok then
        warn("❌ Критическая ошибка при отправке " .. uid .. ": " .. tostring(err))
        return false
    end
    return true
end

-- Отправляем по одному с паузой, чтобы не сработала защита от спама
local sent, failed = 0, 0
for _, pet in ipairs(allPets) do
    if sendPet(pet) then
        sent = sent + 1
        print(string.format("✅ Отправлен: %s", pet:GetUID()))
    else
        failed = failed + 1
    end
    task.wait(0.6) -- небольшая задержка
end

print(string.format("\nГотово! Отправлено: %d, Не удалось: %d", sent, failed))
