--[[    ~/domoticz/scripts/lua/script_time_FireAlarm.lua
auteur : papoo
version : 1.10
MAJ : 16/08/2016
version 1.1 : ajout fonctionnalité envoi par mail uniquement
création : 15/08/2016
Principe : ce script vérifie toutes les deux minutes si il n'y a pas une augmentation de température anormale dans une des pièces référencées dans le tableau les_températures. le nom de chaque sonde doit être encadrer de " et suivi d'une virgule.  exemple  :"nom sonde 1", "nom sonde2",
il compare chaque température au seuil fixé par la variable  seuil_notification (en °). Si une ou plusieurs températures sont supérieures à ce seuil, envoie d'une notification pour chacune d'elle.
/!\ si le seuil est fixé trop bas, cela risque de générer beaucoup de notifications et d'éventuellement bloquer les services de type pushbullet.
URL post : http://easydomoticz.com/forum/viewtopic.php?f=17&t=2319
]]--

package.path = package.path .. ';' .. '/home/pi/domoticz/scripts/lua/?.lua'
require('My_Config')

--------------------------------------------
------------ Variables à éditer ------------
--------------------------------------------

local debugging = true     -- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local seuil_notification = 42       -- seuil température au delà duquel les notifications d'alarme seront envoyées
local les_temperatures = { "Sonde Veranda", "Sonde Parent", "Sonde Justine", "Thermostat", "Sonde THGN500", "Sonde Marion" };
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
local message = ""
local alarmes = 0

commandArray = {}

now = os.date("*t")

if now.min % 2 == 0 then
    voir_les_logs("--- --- --- script_time_AlarmeIncendie.lua --- Seuil à " .. seuil_notification .. "°C", debugging)

    for i, d in ipairs(les_temperatures) do
        local v = otherdevices[d]
        --        voir_les_logs("--- --- --- device value " .. d .. " = " .. (v or "nil"), debugging)

        if v ~= nil then
            if string.match(v, ';') then
                v = v:match('^(.-);')
                --              voir_les_logs("--- --- --- svalue " .. d .. " = " .. (v or "nil"), debugging)
            end

            if tonumber(v) > tonumber(seuil_notification) then
                alarmes = alarmes + 1
                messageVocal = messageVocal .. d .. v
                messageText = messageText .. "sonde :" .. d .. "Temp:" .. v
            end
        end
        --        else
        --			voir_les_logs("bug ",debugging)
    end


    if alarmes > 1 then
        if notif_speak == 1 then
            messageVocal = "Alerte incendie. La température dépasse le seuil d'alerte sur" .. messageVocal
            My.Speak(messageVocal, "fort")
        end

        if alarmes > 1 and notif_email == 1 then
            commandArray['SendEmail'] = 'Alerte incendie#'..os.date("%H:%M")..' -- La température dépasse le seuil fixé à ' .. seuil_notification .. '°C<br>' .. messageText .. '#' .. EmailTo
        end

        if alarmes > 1 and notif_push == 1 then
            commandArray[#commandArray + 1] = { ['SendNotification'] = 'Alerte incendie#'..os.date("%H:%M").. ' -- La température dépasse le seuil fixé à ' .. seuil_notification .. '°C<br>' .. messageText }
        end

        voir_les_logs("--- --- --- " .. objet, debugging)
        voir_les_logs("--- --- --- " .. message, debugging)
    end

end -- if now

return commandArray
