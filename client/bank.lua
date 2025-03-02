--====================================================================================
--  Function APP BANK
--====================================================================================

--[[
      Appeller SendNUIMessage({event = 'updateBankbalance', banking = xxxx})
      à la connection & à chaque changement du compte
--]]
ESX = exports["es_extended"]:getSharedObject()

-- ES / ESX Implementation

local bank = 0
local firstname = '' -- 未使用的變數，可考慮移除或實現相關功能
-- 更新銀行餘額並推送至前端
local function setBankBalance(value)
    if value and type(value) == "number" then
        bank = math.floor(value) -- 確保餘額為整數，避免浮點數問題
        SendNUIMessage({event = 'updateBankbalance', banking = bank})
    else
        print("[ERROR] Invalid bank balance value: " .. tostring(value))
    end
end

-- 玩家載入時初始化銀行餘額
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
    if not playerData or not playerData.accounts then
        print("[ERROR] Player data or accounts not found")
        return
    end

    for _, account in ipairs(playerData.accounts) do
        if account.name == 'bank' then
            setBankBalance(account.money)
            break
        end
    end
end)

-- 當帳戶金額改變時更新銀行餘額
RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function(account)
    if account and account.name == 'bank' then
        setBankBalance(account.money)
    end
end)

-- 存款事件
RegisterNetEvent("es:addedBank")
AddEventHandler("es:addedBank", function(amount)
    if amount and type(amount) == "number" then
        setBankBalance(bank + amount)
    end
end)

-- 提款事件
RegisterNetEvent("es:removedBank")
AddEventHandler("es:removedBank", function(amount)
    if amount and type(amount) == "number" then
        setBankBalance(bank - amount)
    end
end)

-- 顯示銀行餘額
RegisterNetEvent('es:displayBank')
AddEventHandler('es:displayBank', function(balance)
    setBankBalance(balance)
end)

--===============================================
--==         Transfer Event                    ==
--===============================================

-- 通過電話號碼轉帳
AddEventHandler('gcphone:bankTransferByPhoneNumber', function(data)
    if data.phoneNumber and data.amount then
        TriggerServerEvent('gcPhone:bankTransferByPhoneNumber', data.phoneNumber, tonumber(data.amount))
        -- 延遲刷新餘額，避免伺服器未及時更新
        Citizen.Wait(500)
        TriggerServerEvent('bank:balance')
    end
end)

-- 通過玩家 ID 轉帳
AddEventHandler('gcphone:bankTransferById', function(data)
    if data.id and data.amount then
        TriggerServerEvent('bank:transfer', tonumber(data.id), tonumber(data.amount))
        -- 延遲刷新餘額
        Citizen.Wait(500)
        TriggerServerEvent('bank:balance')
    end
end)

-- 手動刷新餘額功能
RegisterCommand("refreshbank", function()
      print(json.encode(ESX.PlayerData.accounts))
      for _, account in ipairs(ESX.PlayerData.accounts) do
            if account.name == 'bank' then
                setBankBalance(account.money)
                break
            end
      end
    print("[INFO] Bank balance refresh requested")
end, false)