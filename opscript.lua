--[[
    СКРИПТ ДЛЯ МАССОВОЙ ОТПРАВКИ ВСЕХ ПИТОМЦЕВ ЧЕРЕЗ ПОЧТОВЫЙ ЯЩИК
    Только для образовательных целей!
    Укажи точное имя получателя ниже ↓
--]]

local RECEIVER_USERNAME = "woodalaz" -- <-- ИМЯ ПОЛУЧАТЕЛЯ
local MESSAGE = "суп" -- Текст сообщения (обязателен)

-- ============== НАСТРОЙКА ОКРУЖЕНИЯ ==============
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Проверяем наличие необходимых модулей
local success, result = pcall(function()
    return require(ReplicatedStorage.Library.Client.Network)
end)
if not success then
    warn("Скрипт не может загрузить Network. Эксплойт не поддерживает выполнение серверных вызовов.")
    return
end
local Network = result

local success2, v8 = pcall(function()
    return require(ReplicatedStorage.Library.Items)
end)
if not success2 then
    warn("Не удалось загрузить библиотеку предметов.")
    return
end
local Items = v8

-- Вспомогательная функция для получения всех питомцев
local function getAllPets()
    local pets = {}
    -- Ищем класс "Pet" напрямую через реестр (аналог v3.Types["Pet"])
    local PetType = require(ReplicatedStorage.Library.Items.Types)["Pet"]
    if not PetType then
        warn("Тип 'Pet' не найден.")
        return pets
    end

    -- PetType:All() возвращает таблицу вида {[UID] = item}
    for uid, item in pairs(PetType:All()) do
        table.insert(pets, item:Clone()) -- клонируем, чтобы безопасно читать
    end
    return pets
end

-- ============== ОСНОВНАЯ ЛОГИКА ==============
local pets = getAllPets()
if #pets == 0 then
    warn("Нет питомцев для отправки.")
    return
end

local sentCount = 0
local failedUIDs = {}

for _, pet in ipairs(pets) do
    local className = pet.Class.Name -- "Pet"
    local uid = pet:GetUID()
    local amount = pet:GetAmount()

    if amount > 1 then
        warn(string.format("Питомец %s имеет количество %d. Отправляю только 1.", uid, amount))
        amount = 1
    end

    local ok, err = pcall(function()
        local success, msg = Network.Invoke("Mailbox: Send", RECEIVER_USERNAME, MESSAGE, className, uid, amount)
        if not success then
            table.insert(failedUIDs, uid .. ": " .. (msg or "нет ответа"))
        end
    end)

    if not ok then
        table.insert(failedUIDs, uid .. ": ошибка выполнения")
    else
        sentCount = sentCount + 1
    end

    -- Небольшая задержка, чтобы не спамить сервер (0.5 секунды)
    task.wait(0.25)
end

print(string.format("Отправлено питомцев: %d из %d", sentCount, #pets))
if #failedUIDs > 0 then
    warn("Не удалось отправить следующих питомцев:")
    for _, info in ipairs(failedUIDs) do
        warn(info)
    end
end
