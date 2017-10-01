--[[   
~/domoticz/scripts/lua/script_time_PrevisionPluie.lua

--- FOR FRENCH CITIES ONLY ---

OBJET :
Annonce dans combien de minutes il va pleuvoir, basé sur l'API de prévision pluie dans l'heure de météofrance :
- sur un device Alert : "Pluie forte dans 15 minutes"
- par mail
- par pushNotification
- par annonce Vocale : Je vous dérange pour vous prévenir qu'une pluie 'forte' est annoncée par météo france dans '35' minutes.

REQUIS :
device type : Alert , Nom :"Alerte Pluie dans l'heure"

ORIGIN :
https://easydomoticz.com/prvision-pluie/
https://easydomoticz.com/forum/viewtopic.php?f=10&t=1991

API :
http://www.meteofrance.com/mf3-rpc-portlet/rest/pluie/920630
http://www.meteofrance.com/mf3-rpc-portlet/rest/lieu/facet/pluie/search/rueil-malmaison

FONCTIONNEMENT :
Toutes les 5 minutes , interroge l'API meteoFrance de prévision de pluie dans l'heure

Parcours les 12 cadrans :
Trouve l'heure de la 1er pluie
Trouve l'intensité la plus forte de l'heure
Avec   jsonPrevision.dataCadran[n].niveauPluie
    1 = Pas de précipitation
    2=faible
    3=modéré
    4=forte

met à jour le device : "Alerte Pluie dans l'heure"
alerte par :  mail, push notif, synthese vocale
Annonce vocale : seulement une annonce vocale , toutes les 3heures.

]]--
---------------------------------------------------------------------------
-- Fonctions
---------------------------------------------------------------------------
package.path = package.path .. ';' .. '/home/pi/domoticz/scripts/lua/?.lua'
My = require('My_Library')
require('My_Config')

--------------------------------------------------------------------------
-- Paramètres à éditer
--------------------------------------------------------------------------
local CITY_CODE = 920630  -- Le code de votre ville est l'ID retourné par cette URL : http://www.meteofrance.com/mf3-rpc-portlet/rest/lieu/facet/pluie/search/nom de votre ville
local RAIN_ALERT_IDX = 137  -- renseigner l'id du device alert associé si souhaité, sinon nil
local NOTIFICATION_PUSH = true
local NOTIFICATION_MAIL = true
local NOTIFICATION_VOCAL = true
local EMAIL = MY_CONFIG_EMAIL  -- adresse mail, séparées par ; si plusieurs

---------------------------------------------------------------------------
commandArray = {}
now = os.date("*t")
if now.min % 5 == 0 then
    print('--- --- --- script_time_meteofrance_pluie.lua ---')
    json = (loadfile "/home/pi/domoticz/scripts/lua/JSON.lua")()

    local config = assert(io.popen('curl http://www.meteofrance.com/mf3-rpc-portlet/rest/pluie/' .. CITY_CODE .. '.json'))
    local fileContent = config:read('*all')
    config:close()
    local jsonPrevision = json:decode(fileContent)

    rainLevel = 0
    when = 0
    data = jsonPrevision.dataCadran
    for i = 1, 12 do
        if data[i].niveauPluie > 1 and when == 0 then
            -- Find the first time that the rain is announced
            when = i
        end
        if data[i].niveauPluie > rainLevel then
            -- Find the maximum level of rain announced
            rainLevel = data[i].niveauPluie
        end
    end

    if rainLevel == 0 then
        commandArray[#commandArray + 1] = { ['SendEmail'] = 'Domoticz Anomalie#' .. os.date("%H:%M") .. ' -- Anomalie dans le script : script_time_PrevisionPluie.lua<br> L\'Api de meteoFrance renvoie un JSON inattendu. niveauPluie n\'est pas correct (devrait être de 1 à 4)<br>Contenu du Json : -------------<br>' .. fileContent .. '#' .. EMAIL }
    elseif rainLevel == 1 then
        if otherdevices_svalues["Alerte Pluie dans l\'heure"] ~= "Pas de pluie dans l\'heure" then
            -- Don't update the device if there is no change. (so that don't change the timestamp of the devie)
            commandArray[#commandArray + 1] = { ['UpdateDevice'] = RAIN_ALERT_IDX .. "|1|Pas de pluie dans l\'heure" }
        end
    else
        if when == 1 then
            whenText = " maintenant"
        else
            whenText = " dans " .. tostring(when * 5) .. " minutes"
        end

        if rainLevel == 2 then
            rainLevelText = "légère"
        elseif rainLevel == 3 then
            rainLevelText = "modérée"
        elseif rainLevel == 4 then
            rainLevelText = "forte"
        end

        commandArray[#commandArray + 1] = { ['UpdateDevice'] = RAIN_ALERT_IDX .. '|' .. rainLevel .. '|Pluie ' .. rainLevelText .. whenText }
        if My.Time_Difference(otherdevices_lastupdate["Alerte Pluie dans l\'heure"]) > 3 * 60 * 60 then
            if NOTIFICATION_VOCAL == true and now.hour > 8 and now.hour <= 20 then
                My.Speak("Je vous dérange pour vous prévenir qu\'une pluie " .. rainLevelText .. " est annoncée par méteo france" .. whenText, "normal")
            end
            if NOTIFICATION_PUSH == true then
                commandArray[#commandArray + 1] = { ['SendNotification'] = 'Alerte Pluie#Pluie ' .. rainLevelText .. whenText }
            end
            if (DEBUG_MODE) then
                commandArray[#commandArray + 1] = { ['SendEmail'] = 'JSON Alerte Pluie#' .. os.date("%H:%M") .. ' -- Api de meteoFrance <br>Contenu du Json : -------------<br>' .. fileContent .. '#' .. EMAIL }
            end
        end
    end
end --if now.min
return commandArray
