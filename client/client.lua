--====================================================================================
-- #Author: Jonathan D @ Gannon
-- Modified by:
-- BTNGaming 
-- Chip
-- DmACK (f.sanllehiromero@uandresbello.edu)
--====================================================================================
 
-- Configuration
local KeyToucheCloseEvent = {
  { code = 172, event = 'ArrowUp' },
  { code = 173, event = 'ArrowDown' },
  { code = 174, event = 'ArrowLeft' },
  { code = 175, event = 'ArrowRight' },
  { code = 176, event = 'Enter' },
  { code = 177, event = 'Backspace' },
}

local menuIsOpen = false
local contacts = {}
local messages = {}
local gpsBlips = {}
local myPhoneNumber = ''
local isDead = false
local USE_RTC = false
local useMouse = false
local ignoreFocus = false
local takePhoto = false
local hasFocus = false
local TokoVoipID = nil

local PhoneInCall = {}
local currentPlaySound = false
local soundDistanceMax = 8.0

ESX = exports["es_extended"]:getSharedObject()



AddEventHandler('esx:onPlayerDeath', function()
  if menuIsOpen then
    menuIsOpen = false
    TriggerEvent('gcPhone:setMenuStatus', false)
    SendNUIMessage({show = false})
    PhonePlayOut()
  end
end)

AddEventHandler('esx:playerLoaded', function()
  TriggerServerEvent('gcPhone:allUpdate')
end)

----
--Item Functions
----
function hasPhone(cb)
  cb(true)
end

function hasPhone(cb)
  if (ESX == nil) then return cb(0) end
  ESX.TriggerServerCallback('gcphone:getItemAmount', function(qtty)
    cb(qtty > 0)
  end, 'phone')
end

function NoPhone() 
  if (ESX == nil) then return end
  ESX.ShowNotification(_U('no_phone'))
end

RegisterCommand('phone', function(source) -- Toggles Phone Via Command. Can coment out.
  TooglePhone()
end, false)

--====================================================================================
--  
--====================================================================================
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    if takePhoto ~= true then
      if IsControlJustPressed(1, 288) then
        hasPhone(function (hasPhone)
          if hasPhone == true then
            TooglePhone()
          else
            ShowNoPhoneWarning()
          end
        end)
      end
      if menuIsOpen == true then
        for _, value in ipairs(KeyToucheCloseEvent) do
          if IsControlJustPressed(1, value.code) then
            SendNUIMessage({keyUp = value.event})
          end
        end
        if useMouse == true and hasFocus == ignoreFocus then
          local nuiFocus = not hasFocus
          SetNuiFocus(nuiFocus, nuiFocus)
          hasFocus = nuiFocus
        elseif useMouse == false and hasFocus == true then
          SetNuiFocus(false, false)
          hasFocus = false
        end
      else
        if hasFocus == true then
          SetNuiFocus(false, false)
          hasFocus = false
        end
      end
    end
  end
end)



RegisterNetEvent("nuo:openphone")
AddEventHandler("nuo:openphone", function()
    ESX.UI.Menu.CloseAll() 
    TooglePhone()
end)

--====================================================================================
-- GPS Blips
--====================================================================================
function styleBlip(blip, type, number, player)
  local blipLabel = '#' .. number
  local blipLabelPrefix = 'Phone GPS Location: '

  -- [[ type 0 ]] --
  if (type == 0) then
    local isContact = false
    for k,contact in pairs(contacts) do
      if contact.number == number then
        blipLabel = contacts[k].display .. ' (' .. blipLabel .. ')'
        isContact = true
        break
      end
    end

    ShowCrewIndicatorOnBlip(blip, true)
    if (isContact == true) then
      SetBlipColour(blip, 2)
    else
      SetBlipColour(blip, 4)
    end
  end

  -- [[ type 1 ]] --
  if (type == 1) then
    blipLabelPrefix = 'Emergency SMS Sender Location: '
    ShowCrewIndicatorOnBlip(blip, true)
    SetBlipColour(blip, 5)
  end

  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString(blipLabelPrefix .. blipLabel)
  EndTextCommandSetBlipName(blip)

  SetBlipSecondaryColour(blip, 255, 0, 0)
  SetBlipScale(blip, 0.9)
end

local checkRate = 5000 -- every 5 seconds
local gpsActive = false
RegisterNetEvent('gcPhone:receiveLivePosition')
AddEventHandler('gcPhone:receiveLivePosition', function(sourcePlayerServerId, timeoutInMilliseconds, sourceNumber, type)
  if (sourcePlayerServerId ~= nil and sourceNumber ~= nil) then
    if (entityBlip ~= nil) then
      RemoveBlip(entityBlip)
      entityBlip = nil
    end
    local sourcePlayer = GetPlayerFromServerId(sourcePlayerServerId)
    local sourcePed = GetPlayerPed(sourcePlayer)
    entityBlip = AddBlipForEntity(sourcePed)
    styleBlip(entityBlip, type, sourceNumber, sourcePlayer)
    gpsActive = true
    Citizen.SetTimeout(timeoutInMilliseconds, function()
      SetBlipFlashes(entityBlip, true)
      Citizen.Wait(10000)
      RemoveBlip(entityBlip)
      entityBlip = nil
      gpsActive = false
    end)
    Citizen.CreateThread(function()
      while Config.ItemRequired and gpsActive do
        Citizen.Wait(checkRate)
        hasPhone(function (hasPhone)
          if hasPhone == false then
            SetBlipFlashes(entityBlip, true)
            Citizen.Wait(2000) -- 2 Seconds
            RemoveBlip(entityBlip)
            entityBlip = nil
            gpsActive = false
          end
        end)
      end
    end)
  end
end)

--====================================================================================
--  Activate or Deactivate an application (appName => config.json)
--====================================================================================
RegisterNetEvent('gcPhone:setEnableApp')
AddEventHandler('gcPhone:setEnableApp', function(appName, enable)
  SendNUIMessage({event = 'setEnableApp', appName = appName, enable = enable })
end)

--====================================================================================
--  Fixed call management
--====================================================================================
function startFixeCall (fixeNumber)
  local number = ''
  DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "", "", "", "", 10)
  while (UpdateOnscreenKeyboard() == 0) do
    DisableAllControlActions(0);
    Wait(0);
  end
  if (GetOnscreenKeyboardResult()) then
    number =  GetOnscreenKeyboardResult()
  end
  if number ~= '' then
    TriggerEvent('gcphone:autoCall', number, {
      useNumber = fixeNumber
    })
    PhonePlayCall(true)
  end
end

function TakeAppel (infoCall)
  TriggerEvent('gcphone:autoAcceptCall', infoCall)
end

RegisterNetEvent("gcPhone:notifyFixePhoneChange")
AddEventHandler("gcPhone:notifyFixePhoneChange", function(_PhoneInCall)
  PhoneInCall = _PhoneInCall
end)

--[[
  Displays information when the player is near a fixed phone (Static location phone like MRPD Desk Phone)
--]]
function showFixePhoneHelper (coords)
  for number, data in pairs(Config.FixePhone) do
    local dist = GetDistanceBetweenCoords(
      data.coords.x, data.coords.y, data.coords.z,
      coords.x, coords.y, coords.z, 1)
    if dist <= 2.5 then
      SetTextComponentFormat("STRING")
      AddTextComponentString(_U('use_fixed', data.name, number))
      DisplayHelpTextFromStringLabel(0, 0, 0, -1)
      if IsControlJustPressed(1, Config.KeyTakeCall) then
        startFixeCall(number)
      end
      break
    end
  end
end

RegisterNetEvent('gcPhone:register_FixePhone')
AddEventHandler('gcPhone:register_FixePhone', function(phone_number, data)
  Config.FixePhone[phone_number] = data
end)

local registeredPhones = {}
Citizen.CreateThread(function()
  if not Config.AutoFindFixePhones then return end
  while not ESX do Citizen.Wait(0) end
  while true do
    local playerPed = GetPlayerPed(-1)
    local coords = GetEntityCoords(playerPed)
    for _, key in pairs({'p_phonebox_01b_s', 'p_phonebox_02_s', 'prop_phonebox_01a', 'prop_phonebox_01b', 'prop_phonebox_01c', 'prop_phonebox_02', 'prop_phonebox_03', 'prop_phonebox_04'}) do
      local closestPhone = GetClosestObjectOfType(coords.x, coords.y, coords.z, 25.0, key, false)
      if closestPhone ~= 0 and not registeredPhones[closestPhone] then
        local phoneCoords = GetEntityCoords(closestPhone)
        number = ('0%.2s-%.2s%.2s'):format(math.abs(phoneCoords.x*100), math.abs(phoneCoords.y * 100), math.abs(phoneCoords.z *100))
        if not Config.FixePhone[number] then
          TriggerServerEvent('gcPhone:register_FixePhone', number, phoneCoords)
        end
        registeredPhones[closestPhone] = true
      end
    end
    Citizen.Wait(1000)
  end
end)

Citizen.CreateThread(function ()
  local mod = 0
  while true do
     
    local playerPed   = PlayerPedId()
    local coords      = GetEntityCoords(playerPed)
    local inRangeToActivePhone = false
    local inRangedist = 0
    for i, _ in pairs(PhoneInCall) do 
        local dist = GetDistanceBetweenCoords(
          PhoneInCall[i].coords.x, PhoneInCall[i].coords.y, PhoneInCall[i].coords.z,
          coords.x, coords.y, coords.z, 1)
        if (dist <= soundDistanceMax) then
          DrawMarker(1, PhoneInCall[i].coords.x, PhoneInCall[i].coords.y, PhoneInCall[i].coords.z,
              0,0,0, 0,0,0, 0.1,0.1,0.1, 0,255,0,255, 0,0,0,0,0,0,0)
          inRangeToActivePhone = true
          inRangedist = dist
          if (dist <= 1.5) then 
            SetTextComponentFormat("STRING")
            AddTextComponentString(_U('key_answer'))
            DisplayHelpTextFromStringLabel(0, 0, 1, -1)
            if IsControlJustPressed(1, Config.KeyTakeCall) then
              PhonePlayCall(true)
              TakeAppel(PhoneInCall[i])
              PhoneInCall = {}
              StopSoundJS('ring2.ogg')
            end
          end
          break
        end
    end
    if inRangeToActivePhone == false then
      showFixePhoneHelper(coords)
    end
    if inRangeToActivePhone == true and currentPlaySound == false then
      PlaySoundJS('ring2.ogg', 0.2 + (inRangedist - soundDistanceMax) / -soundDistanceMax * 0.8 )
      currentPlaySound = true
    elseif inRangeToActivePhone == true then
      mod = mod + 1
      if (mod == 15) then
        mod = 0
        SetSoundVolumeJS('ring2.ogg', 0.2 + (inRangedist - soundDistanceMax) / -soundDistanceMax * 0.8 )
      end
    elseif inRangeToActivePhone == false and currentPlaySound == true then
      currentPlaySound = false
      StopSoundJS('ring2.ogg')
    end
    Citizen.Wait(0)
  end
end)

function PlaySoundJS (sound, volume)
  print("playSound")
  SendNUIMessage({ event = 'playSound', sound = sound, volume = volume })
end

function SetSoundVolumeJS (sound, volume)
  SendNUIMessage({ event = 'setSoundVolume', sound = sound, volume = volume})
end

function StopSoundJS (sound)
  SendNUIMessage({ event = 'stopSound', sound = sound})
end

RegisterNetEvent("gcPhone:forceOpenPhone")
AddEventHandler("gcPhone:forcePhone", function(_myPhoneNumber)
  if menuIsOpen == false then
    TooglePhone()
  end
end)
 
--====================================================================================
--  Events
--====================================================================================
RegisterNetEvent("gcPhone:myPhoneNumber")
AddEventHandler("gcPhone:myPhoneNumber", function(_myPhoneNumber)
  myPhoneNumber = _myPhoneNumber
  SendNUIMessage({event = 'updateMyPhoneNumber', myPhoneNumber = myPhoneNumber})
end)

RegisterNetEvent("gcPhone:contactList")
AddEventHandler("gcPhone:contactList", function(_contacts)
  SendNUIMessage({event = 'updateContacts', contacts = _contacts})
  contacts = _contacts
end)

RegisterNetEvent("gcPhone:allMessage")
AddEventHandler("gcPhone:allMessage", function(allmessages)
  SendNUIMessage({event = 'updateMessages', messages = allmessages})
  messages = allmessages
end)

RegisterNetEvent("gcPhone:getBourse")
AddEventHandler("gcPhone:getBourse", function(bourse)
  SendNUIMessage({event = 'updateBourse', bourse = bourse})
end)

RegisterNetEvent("gcPhone:receiveMessage")
AddEventHandler("gcPhone:receiveMessage", function(message)
  -- SendNUIMessage({event = 'updateMessages', messages = messages})
  SendNUIMessage({event = 'newMessage', message = message})
  table.insert(messages, message)
  if message.owner == 0 then
    local text = _U('new_message')
    if Config.ShowNumberNotification == true then
      text = _U('new_message_from', message.transmitter)
      for _,contact in pairs(contacts) do
        if contact.number == message.transmitter then
          text = _U('new_message_transmitter', contact.display)
          break
        end
      end
    end
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, false)
    PlaySound(-1, "Menu_Accept", "Phone_SoundSet_Default", 0, 0, 1)
    Citizen.Wait(300)
    PlaySound(-1, "Menu_Accept", "Phone_SoundSet_Default", 0, 0, 1)
    Citizen.Wait(300)
    PlaySound(-1, "Menu_Accept", "Phone_SoundSet_Default", 0, 0, 1)
  end
end)

--====================================================================================
--  Function client | Contacts
--====================================================================================
function addContact(display, num) 
    TriggerServerEvent('gcPhone:addContact', display, num)
end

function deleteContact(num) 
    TriggerServerEvent('gcPhone:deleteContact', num)
end
--====================================================================================
--  Function client | Messages
--====================================================================================
function sendMessage(num, message)
  TriggerServerEvent('gcPhone:sendMessage', num, message)
end

function deleteMessage(msgId)
  TriggerServerEvent('gcPhone:deleteMessage', msgId)
  for k, v in ipairs(messages) do 
    if v.id == msgId then
      table.remove(messages, k)
      SendNUIMessage({event = 'updateMessages', messages = messages})
      return
    end
  end
end

function deleteMessageContact(num)
  TriggerServerEvent('gcPhone:deleteMessageNumber', num)
end

function deleteAllMessage()
  TriggerServerEvent('gcPhone:deleteAllMessage')
end

function setReadMessageNumber(num)
  TriggerServerEvent('gcPhone:setReadMessageNumber', num)
  for k, v in ipairs(messages) do 
    if v.transmitter == num then
      v.isRead = 1
    end
  end
end

function requestAllMessages()
  TriggerServerEvent('gcPhone:requestAllMessages')
end

function requestAllContact()
  TriggerServerEvent('gcPhone:requestAllContact')
end



--====================================================================================
--  Function client | Appels
--====================================================================================
local aminCall = false
local inCall = false

RegisterNetEvent("gcPhone:waitingCall")
AddEventHandler("gcPhone:waitingCall", function(infoCall, initiator)
  SendNUIMessage({event = 'waitingCall', infoCall = infoCall, initiator = initiator})
  if initiator == true then
    PhonePlayCall()
    if menuIsOpen == false then
      TooglePhone()
    end
  end
end)

RegisterNetEvent("gcPhone:acceptCall")
AddEventHandler("gcPhone:acceptCall", function(infoCall, initiator)
  if inCall == false and USE_RTC == false then
    inCall = true
    if Config.UseMumbleVoIP then
      exports["mumble-voip"]:SetCallChannel(infoCall.id+1)
    elseif Config.UseTokoVoIP then
      exports.tokovoip_script:addPlayerToRadio(infoCall.id + 120)
      TokoVoipID = infoCall.id + 120
    else
    NetworkSetVoiceChannel(infoCall.id + 1)
    NetworkSetTalkerProximity(0.0)
  end
end
  if menuIsOpen == false then 
    TooglePhone()
  end
  PhonePlayCall()
  SendNUIMessage({event = 'acceptCall', infoCall = infoCall, initiator = initiator})
end)

RegisterNetEvent("gcPhone:rejectCall")
AddEventHandler("gcPhone:rejectCall", function(infoCall)
  if inCall == true then
    inCall = false
    if Config.UseMumbleVoIP then
      exports["mumble-voip"]:SetCallChannel(0)
    elseif Config.UseTokoVoIP then
      exports.tokovoip_script:removePlayerFromRadio(TokoVoipID)
      TokoVoipID = nil
    else
      Citizen.InvokeNative(0xE036A705F989E049)
      NetworkSetTalkerProximity(2.5)
    end
  end
  local calling = isDoingCall()
  if calling == true then
    PhonePlayText()
  end
  SendNUIMessage({event = 'rejectCall', infoCall = infoCall})
end)


RegisterNetEvent("gcPhone:historiqueCall")
AddEventHandler("gcPhone:historiqueCall", function(historique)
  SendNUIMessage({event = 'historiqueCall', historique = historique})
end)


function startCall (phone_number, rtcOffer, extraData)
  if rtcOffer == nil then
    rtcOffer = ''
  end
  TriggerServerEvent('gcPhone:startCall', phone_number, rtcOffer, extraData)
end

function acceptCall (infoCall, rtcAnswer)
  TriggerServerEvent('gcPhone:acceptCall', infoCall, rtcAnswer)
end

function rejectCall(infoCall)
  TriggerServerEvent('gcPhone:rejectCall', infoCall)
end

function ignoreCall(infoCall)
  TriggerServerEvent('gcPhone:ignoreCall', infoCall)
end

function requestHistoriqueCall() 
  TriggerServerEvent('gcPhone:getHistoriqueCall')
end

function appelsDeleteHistorique (num)
  TriggerServerEvent('gcPhone:appelsDeleteHistorique', num)
end

function appelsDeleteAllHistorique ()
  TriggerServerEvent('gcPhone:appelsDeleteAllHistorique')
end
  

--====================================================================================
--  Event NUI - Appels
--====================================================================================

RegisterNUICallback('startCall', function (data, cb)
  startCall(data.numero, data.rtcOffer, data.extraData)
  cb()
end)

RegisterNUICallback('acceptCall', function (data, cb)
  acceptCall(data.infoCall, data.rtcAnswer)
  cb()
end)
RegisterNUICallback('rejectCall', function (data, cb)
  rejectCall(data.infoCall)
  cb()
end)

RegisterNUICallback('ignoreCall', function (data, cb)
  ignoreCall(data.infoCall)
  cb()
end)

RegisterNUICallback('notififyUseRTC', function (use, cb)
  USE_RTC = use
  if USE_RTC == true and inCall == true then
    inCall = false
    Citizen.InvokeNative(0xE036A705F989E049)
    if Config.UseTokoVoIP then
      exports.tokovoip_script:removePlayerFromRadio(TokoVoipID)
      TokoVoipID = nil
    else
      NetworkSetTalkerProximity(2.5)
    end
  end
  cb()
end)


RegisterNUICallback('onCandidates', function (data, cb)
  TriggerServerEvent('gcPhone:candidates', data.id, data.candidates)
  cb()
end)

RegisterNetEvent("gcPhone:candidates")
AddEventHandler("gcPhone:candidates", function(candidates)
  SendNUIMessage({event = 'candidatesAvailable', candidates = candidates})
end)



RegisterNetEvent('gcphone:autoCall')
AddEventHandler('gcphone:autoCall', function(number, extraData)
  if number ~= nil then
    SendNUIMessage({ event = "autoStartCall", number = number, extraData = extraData})
  end
end)

RegisterNetEvent('gcphone:autoCallNumber')
AddEventHandler('gcphone:autoCallNumber', function(data)
  TriggerEvent('gcphone:autoCall', data.number)
end)

RegisterNetEvent('gcphone:autoAcceptCall')
AddEventHandler('gcphone:autoAcceptCall', function(infoCall)
  SendNUIMessage({ event = "autoAcceptCall", infoCall = infoCall})
end)

--====================================================================================
--  Management of NUI events
--==================================================================================== 
RegisterNUICallback('log', function(data, cb)
  print(data)
  cb()
end)
RegisterNUICallback('focus', function(data, cb)
  cb()
end)
RegisterNUICallback('blur', function(data, cb)
  cb()
end)
RegisterNUICallback('reponseText', function(data, cb)
  local limit = data.limit or 255
  local text = data.text or ''

  ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'menuDiag',{
    title = 'Messages'
    },
    function(data, menu)
    local text = data.value
    menu.close()
    cb(json.encode({text = tostring(text)}))
    end,
  function(data, menu)
    menu.close()
  end)
end)
--====================================================================================
--  Event - Messages
--====================================================================================
RegisterNUICallback('getMessages', function(data, cb)
  cb(json.encode(messages))
end)
RegisterNUICallback('sendMessage', function(data, cb)
  if data.message == '%pos%' then
    local myPos = GetEntityCoords(PlayerPedId())
    data.message = 'GPS: ' .. myPos.x .. ', ' .. myPos.y
    data.message = '[ID'..GetPlayerServerId(PlayerId())..'] GPS: ' .. myPos.x.. ', ' ..myPos.y
    data.gpsData = GetEntityCoords(PlayerPedId())
  end
  TriggerServerEvent('gcPhone:sendMessage', data.phoneNumber, data.message, data.gpsData)
end)
RegisterNUICallback('deleteMessage', function(data, cb)
  deleteMessage(data.id)
  cb()
end)
RegisterNUICallback('deleteMessageNumber', function (data, cb)
  deleteMessageContact(data.number)
  cb()
end)
RegisterNUICallback('deleteAllMessage', function (data, cb)
  deleteAllMessage()
  cb()
end)
RegisterNUICallback('setReadMessageNumber', function (data, cb)
  setReadMessageNumber(data.number)
  cb()
end)
--====================================================================================
--  Event - Contacts
--====================================================================================
RegisterNUICallback('addContact', function(data, cb) 
  TriggerServerEvent('gcPhone:addContact', data.display, data.phoneNumber)
end)
RegisterNUICallback('updateContact', function(data, cb)
  TriggerServerEvent('gcPhone:updateContact', data.id, data.display, data.phoneNumber)
end)
RegisterNUICallback('deleteContact', function(data, cb)
  TriggerServerEvent('gcPhone:deleteContact', data.id)
end)
RegisterNUICallback('getContacts', function(data, cb)
  cb(json.encode(contacts))
end)
RegisterNUICallback('setGPS', function(data, cb)
  SetNewWaypoint(tonumber(data.x), tonumber(data.y))
  cb()
end)

-- Add security for event (leuit#0100)
RegisterNUICallback('callEvent', function(data, cb)
  local eventName = data.eventName or ''
  if string.match(eventName, 'gcphone') then
    if data.data ~= nil then 
      TriggerEvent(data.eventName, data.data)
    else
      TriggerEvent(data.eventName)
    end
  else
    print('Event not allowed')
  end
  cb()
end)
RegisterNUICallback('useMouse', function(um, cb)
  useMouse = um
end)
RegisterNUICallback('deleteALL', function(data, cb)
  TriggerServerEvent('gcPhone:deleteALL')
  cb()
end)

function TooglePhone()
  if Config.ItemRequired == true then
    hasPhone(function (hasPhone)
      if hasPhone == true then
        menuIsOpen = not menuIsOpen
        SendNUIMessage({show = menuIsOpen})
        if menuIsOpen == true then 
          PhonePlayIn()
          TriggerEvent('gcPhone:setMenuStatus', true)
        else
          PhonePlayOut()
          TriggerEvent('gcPhone:setMenuStatus', false)
        end
      elseif hasPhone == false and Config.NoPhoneWarning == true then
        NoPhone()
      end
    end)
  elseif Config.ItemRequired == false then
    menuIsOpen = not menuIsOpen
    SendNUIMessage({show = menuIsOpen})
    if menuIsOpen == true then 
      PhonePlayIn()
      TriggerEvent('gcPhone:setMenuStatus', true)
    else
      PhonePlayOut()
      TriggerEvent('gcPhone:setMenuStatus', false)
    end
  end
end

RegisterNUICallback('faketakePhoto', function(data, cb)
  menuIsOpen = false
  TriggerEvent('gcPhone:setMenuStatus', false)
  SendNUIMessage({show = false})
  cb()
  TriggerEvent('camera:open')
end)

RegisterNUICallback('closePhone', function(data, cb)
  menuIsOpen = false
  TriggerEvent('gcPhone:setMenuStatus', false)
  SendNUIMessage({show = false})
  PhonePlayOut()
  cb()
end)

----------------------------------
---------- GESTION APPEL ---------
----------------------------------
RegisterNUICallback('appelsDeleteHistorique', function (data, cb)
  appelsDeleteHistorique(data.numero)
  cb()
end)
RegisterNUICallback('appelsDeleteAllHistorique', function (data, cb)
  appelsDeleteAllHistorique(data.infoCall)
  cb()
end)

----------------------------------
---------- GESTION VIA WEBRTC ----
----------------------------------
AddEventHandler('onClientResourceStart', function(res)
  DoScreenFadeIn(300)
  if res == "gcphone" then
      TriggerServerEvent('gcPhone:allUpdate')
      -- Try again in 2 minutes (Recovers bugged phone numbers)
      Citizen.Wait(120000)
      TriggerServerEvent('gcPhone:allUpdate')
  end
end)

RegisterNUICallback('setIgnoreFocus', function (data, cb)
  ignoreFocus = data.ignoreFocus
  cb()
end)

RegisterNUICallback('takePhoto', function(data, cb)
	CreateMobilePhone(1)
  CellCamActivate(true, true)
  takePhoto = true
  Citizen.Wait(0)
  if hasFocus == true then
    SetNuiFocus(false, false)
    hasFocus = false
  end
	while takePhoto do
    Citizen.Wait(0)

		if IsControlJustPressed(1, 27) then -- Toogle Mode
			frontCam = not frontCam
			CellFrontCamActivate(frontCam)
    elseif IsControlJustPressed(1, 177) then -- CANCEL
      DestroyMobilePhone()
      CellCamActivate(false, false)
      cb(json.encode({ url = nil }))
      takePhoto = false
      break
    elseif IsControlJustPressed(1, 176) then -- TAKE.. PIC
			exports['screenshot-basic']:requestScreenshotUpload(data.url, data.field, function(data)
        local resp = json.decode(data)
        DestroyMobilePhone()
        CellCamActivate(false, false)
        --cb(json.encode({ url = resp.files[1].url }))   
        cb(json.encode({ url = resp.url }))
      end)
      takePhoto = false
		end
		HideHudComponentThisFrame(7)
		HideHudComponentThisFrame(8)
		HideHudComponentThisFrame(9)
		HideHudComponentThisFrame(6)
		HideHudComponentThisFrame(19)
    HideHudAndRadarThisFrame()
  end
  Citizen.Wait(1000)
  PhonePlayAnim('text', false, true)
end)
