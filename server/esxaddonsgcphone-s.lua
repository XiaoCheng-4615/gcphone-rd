local PhoneNumbers        = {}

ESX = exports["es_extended"]:getSharedObject()
if not ESX then
    print("錯誤：無法獲取 ESX 共享物件")
end

for k,v in pairs(Config.JobNotify) do
  TriggerEvent('esx_phone:registerNumber', v.job, v.label, true, true)
end


function notifyAlertSMS (number, alert, listSrc)
  
  if PhoneNumbers[number] ~= nil then
    local messText = alert.message
    if (messText == '%posrealtime%') then
      messText = '全球定位系統即時位置'
    end
    local mess = '來自 #' .. alert.numero  .. ' : ' .. messText
    if alert.coords ~= nil then
      mess = mess .. ' ' .. alert.coords.x .. ', ' .. alert.coords.y 
    end
    for k, _ in pairs(listSrc) do
      local targetPlayer = tonumber(k)
      if targetPlayer then
        getPhoneNumber(targetPlayer, function (n)
          print(targetPlayer,'notifyAlertSMS')
          if n ~= nil then
            TriggerEvent('gcPhone:_internalAddMessage', number, n, mess, 0, function (smsMess)
              TriggerClientEvent('gcPhone:receiveMessage', targetPlayer, smsMess)
              if alert.source then
                if messText == 'GPS Live Position' then
                  local duration = Config.ShareRealtimeGPSJobTimer * 60000 --Config Time (Default = 10 minutes)
                  TriggerClientEvent('gcPhone:receiveLivePosition', targetPlayer, alert.source, duration, alert.numero, 1)
                end
              end
            end)
          end
        end)
      else
        print("錯誤：無效的目標玩家 ID")
      end
    end
  end
end

AddEventHandler('esx_phone:registerNumber', function(number, type, sharePos, hasDispatch, hideNumber, hidePosIfAnon)
    -- print('註冊電話號碼：', json.encode({
    --     number = number,
    --     type = type,
    --     sharePos = sharePos,
    --     hasDispatch = hasDispatch
    -- }))
	local hideNumber    = hideNumber    or false
	local hidePosIfAnon = hidePosIfAnon or false

	PhoneNumbers[number] = {
		type          = type,
    sources       = {},
    alerts        = {}
	}
end)


AddEventHandler('esx:setJob', function(source, job, lastJob)
    local src = tonumber(source)
    if not src then return end

    -- 移除舊職業的電話來源
    if PhoneNumbers[lastJob.name] then
        RemovePhoneSource(lastJob.name, src)
    end

    -- 添加新職業的電話來源
    if PhoneNumbers[job.name] then
        AddPhoneSource(job.name, src)
    end
end)

-- 添加電話來源的函數
function AddPhoneSource(number, source)
    if not PhoneNumbers[number] then return end
    PhoneNumbers[number].sources[tostring(source)] = true
    TriggerEvent('esx_addons_gcphone:sourceUpdated', number, source, true)
end

-- 移除電話來源的函數
function RemovePhoneSource(number, source)
    if not PhoneNumbers[number] then return end
    PhoneNumbers[number].sources[tostring(source)] = nil
    TriggerEvent('esx_addons_gcphone:sourceUpdated', number, source, false)
end

-- 保持這些事件處理程序用於向後兼容
AddEventHandler('esx_addons_gcphone:addSource', function(number, source)
    AddPhoneSource(number, source)
end)

AddEventHandler('esx_addons_gcphone:removeSource', function(number, source)
    RemovePhoneSource(number, source)
end)

RegisterServerEvent('gcPhone:sendMessage')
AddEventHandler('gcPhone:sendMessage', function(number, message)
    print('發送消息：', json.encode({
        number = number,
        message = message,
        source = source
    }))
    local sourcePlayer = tonumber(source)
    if PhoneNumbers[number] ~= nil then
      getPhoneNumber(source, function (phone) 
        print('gcPhone:sendMessage',phone)
        notifyAlertSMS(number, {
          message = message,
          numero = phone,
          source = sourcePlayer
        }, PhoneNumbers[number].sources)
      end)
    end
end)

RegisterServerEvent('esx_addons_gcphone:startCall')
AddEventHandler('esx_addons_gcphone:startCall', function (number, message, coords)
  local sourcePlayer = tonumber(source)
  if PhoneNumbers[number] ~= nil then
    getPhoneNumber(source, function (phone) 
      print('esx_addons_gcphone:startCall')
      notifyAlertSMS(number, {
        message = message,
        coords = coords,
        numero = phone,
        source = sourcePlayer
      }, PhoneNumbers[number].sources)
    end)
  else
    print('= WARNING = Trying to call an unregistered service => numero : ' .. number)
  end
end)


AddEventHandler('esx:playerLoaded', function(source)

  local xPlayer = ESX.GetPlayerFromId(source)

  MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @identifier',{
    ['@identifier'] = xPlayer.identifier
  }, function(result)

    local phoneNumber = result[1].phone_number
    xPlayer.set('phoneNumber', phoneNumber)

    if PhoneNumbers[xPlayer.job.name] ~= nil then
      TriggerEvent('esx_addons_gcphone:addSource', xPlayer.job.name, source)
    end
  end)

end)


AddEventHandler('esx:playerDropped', function(source)
  local source = source
  local xPlayer = ESX.GetPlayerFromId(source)
  if PhoneNumbers[xPlayer.job.name] ~= nil then
    TriggerEvent('esx_addons_gcphone:removeSource', xPlayer.job.name, source)
  end
end)


function getPhoneNumber(source, callback) 
    local xPlayer = ESX.GetPlayerFromId(source)
    print('獲取電話號碼：', json.encode({
        source = source,
        hasPlayer = xPlayer ~= nil
    }))
    if xPlayer == nil then
      callback(nil)
      return
    end
  
  MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @identifier',{
    ['@identifier'] = xPlayer.identifier
  }, function(result)
    if result and result[1] then
      callback(result[1].phone_number)
    else
      callback(nil)
    end
  end)
end



RegisterServerEvent('esx_phone:send')
AddEventHandler('esx_phone:send', function(number, message, _, coords)
  local source = source
  if PhoneNumbers[number] ~= nil then
    getPhoneNumber(source, function (phone) 
      print('esx_phone:send')
      notifyAlertSMS(number, {
        message = message,
        coords = coords,
        numero = phone,
      }, PhoneNumbers[number].sources)
    end)
    print(number)
  else
    -- print('esx_phone:send | Appels sur un service non enregistre => numero : ' .. number)
  end
end)