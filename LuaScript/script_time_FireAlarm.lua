--[[    ~/domoticz/scripts/lua/script_time_FireAlarm.lua
Original Author : papoo / URL post : http://easydomoticz.com/forum/viewtopic.php?f=17&t=2319
version 1.1 : ajout fonctionnalité envoi par mail uniquement

Check Every Minute the temperature of all temperature sensor and Send Alert if at least one of them
exceed the predefined threshold.

The alert is send by :
- RealTime Voice TextToSpeak
- notification
- email

]]--

package.path = package.path .. ';' .. '/home/pi/domoticz/scripts/lua/?.lua'
My = require('My_Library')
require('My_Config')
--------------------------------------------
------------ Variables à éditer ------------
--------------------------------------------

local debugging = true     -- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local seuil_temp_alarm = 42       -- seuil température au delà duquel les notifications d'alarme seront envoyées
local les_temperatures = { "Sonde Veranda", "Sonde Parent", "Sonde Justine", "Thermostat", "Sonde Marion" };
local notif_push = 1
local notif_email = 1
local notif_speak = 1
local EmailTo = MY_CONFIG_EMAIL  --  Defined in My_Config.lua file : adresse mail, séparées par ; si plusieurs

--------------------------------------------
---------------- Fonctions -----------------
--------------------------------------------
function voir_les_logs (s, debugging)
    if (debugging) then
        if s ~= nil then
            print("<font color='#f3031d'>" .. s .. "</font>")
        else
            print("<font color='#f3031d'>aucune valeur affichable</font>")
        end
    end
end

--------------------------------------------
-------------- Fin Fonctions ---------------
--------------------------------------------
local messageVocal = ""
local messageText = ""
local alarmes = 0

commandArray = {}

now = os.date("*t")

if now.min % 1 == 0 then
    voir_les_logs("--- --- --- script_time_FireAlarm.lua --- Test toutes les sondes. Seuil à " .. seuil_temp_alarm .. "°C", debugging)

    for i, d in ipairs(les_temperatures) do
        local v = otherdevices[d]
        --        voir_les_logs("--- --- --- device value " .. d .. " = " .. (v or "nil"), debugging)

        if v ~= nil then
            if string.match(v, ';') then
                v = v:match('^(.-);')
                --              voir_les_logs("--- --- --- svalue " .. d .. " = " .. (v or "nil"), debugging)
            end

            if tonumber(v) > tonumber(seuil_temp_alarm) then
                alarmes = alarmes + 1
                messageVocal = messageVocal .. d .. " "
                messageText = messageText .. "<br>Sonde :" .. d .. " Temp:" .. v
            end
        end
        --        else
        --			voir_les_logs("bug ",debugging)
    end


    if alarmes > 1 then
        if notif_speak == 1 then
            messageVocal = "Alerte incendie. Seuil de température dépassé sur " .. messageVocal
            My.Speak(messageVocal, "fort")
        end

        if alarmes > 1 and notif_email == 1 then
            commandArray['SendEmail'] = 'Alerte incendie#'..os.date("%H:%M")..' -- La température dépasse le seuil fixé à ' .. seuil_temp_alarm .. '°C<br>' .. messageText .. '#' .. EmailTo
        end

        if alarmes > 1 and notif_push == 1 then
            commandArray[#commandArray + 1] = { ['SendNotification'] = 'Alerte incendie#'..os.date("%H:%M").. ' -- La température dépasse le seuil fixé à ' .. seuil_temp_alarm .. '°C<br>' .. messageText }
        end

        voir_les_logs("--- --- --- " .. messageVocal, debugging)
    end

end -- if now

return commandArray
