--[[
~/domoticz/scripts/lua/script_device_Alarm_NightnDays.lua

REQUIRE :
devices['Alarm Mode']
devices['Alarm Sound Timer']
devices['Alarm Switch']
devices['Relay 8 - External Siren']
devices['Relay 7 - Internal Siren']
'Motion LivingRoom'
'Motion Veranda'

-- conditions : tous les détecteurs doivent se remettre automatiquement au repos en moins de 5 minutes

]]--


package.path = package.path .. ';' .. '/home/pi/domoticz/scripts/lua/?.lua'
My = require('My_Library')

local time = os.date("*t")
local minutes = time.min + time.hour * 60
local idxAlarmSoundTimer = '113'                    -- Your Alarm Sound Timer Switch Device IDX

commandArray = {}

device = tostring(next(devicechanged))

-- ################# Alarm armed. Warning message
if device == "Alarm Mode" and otherdevices[device] == 'On' then
    My.Speak("Alarme activée. Vous avez 4 minutes pour sortir de la maison !", "normal")
    return commandArray
end

-- #################   Disarm Alarm with physical Switch
if device == "Alarm Switch" and otherdevices[device] == 'On' then
    -- intercept the Alarm
    My.Speak("Alarme désactivée.", "faible")

    commandArray[#commandArray + 1] = { ['Relay 7 - Internal Siren'] = 'Off' }
    commandArray[#commandArray + 1] = { ['Relay 8 - External Siren'] = 'Off' }
    commandArray[#commandArray + 1] = { ['Alarm Mode'] = 'Off' }  -- si la nuit ou sirene, arrete tout.
    commandArray[#commandArray + 1] = { ['Alarm Sound Timer'] = 'Off' }   -- TODO : à tester : est-ce que si le timer est lancé (On after 10), on peut l'arreter par un Off ?
    commandArray[#commandArray + 1] = { ['Alarm Switch'] = 'Off AFTER 5' }   -- secondes
    return commandArray
end

-- #################   Intrusion. Timer 10 secondes atteint. Déclenche Sirène. 1 seule fois toutes les 2 heures.
-- Quand le Timer passe à On , 
-- test une dernière fois le mode Alarm ,  (important car le switch Alarm a pu désactiver l'alarme)
-- sirène auto Off en 240 secondes.

if device == "Alarm Sound Timer" and otherdevices[device] == 'On' and otherdevices['Alarm Mode'] == 'On' then
    -- Check Alarm Mode a last time
    commandArray[#commandArray + 1] = { ['Alarm Sound Timer'] = 'Off' }

    --My.Time_Difference(otherdevices_lastupdate['Relay 8 - Internal Siren']) > 2*60*60
    -- ne pas sonner entre 0 et 240 car la sirene est en cours
    if My.Time_Difference(otherdevices_lastupdate['Relay 7 - External Siren']) > 15 * 60  --   15 min minimal delayed between 2 sounds. no hassle the neighborhood
    -- TODO créer un compteur : Plusieurs fois dans l'heure mais 1 seule détection par jour ? PAs tester la durée mais plutot l'heure ?
    -- ou alors faire incrémental attendre x* le nb de déclenchement
    then
        commandArray[#commandArray + 1] = { ['SendNotification'] = 'Maison/Alarm - Timer reached. Siren SOUNDS !!! # for 4 minutes.' .. time.hour .. 'h' .. time.min .. '#0' }
        commandArray[#commandArray + 1] = { ['Relay 7 - External Siren'] = 'On' }    -- sounds 4 minutes  (off delay set to 240 sec)
        commandArray[#commandArray + 1] = { ['Relay 8 - Internal Siren'] ='On' }    -- sounds 4 minutes  (off delay set to 240 sec)
    else
        commandArray[#commandArray + 1] = { ['SendNotification'] = 'Maison/Alarm - Timer reached but siren already sound. NO Sound.' .. time.hour .. 'h' .. time.min .. '#0' }
    end

    return commandArray
end

-- ################# Detect Intrusion

if (device == 'Motion LivingRoom' or device == 'Motion Veranda') and otherdevices[device] == 'On' -- It s a motion and ON
and My.Time_Difference(otherdevices_lastupdate['Alarm Mode']) > 5 * 60    -- le mode Alarme n'a pas été changé dans les 5 dernières minutes (cela permet de quitter la maison, et que tous les détecteurs repassent au repos) : timer to leave the house when alarm is activated
then
    --[[
        if otherdevices['Alarm Mode'] == 'Auto' then   -- alarm automatic : check presence of beacon;
            beaconHome=0
            for variableName, variableValue in pairs(uservariables) do
                if string.sub(variableName,1,3)=="Tag" and (variableValue ~= "AWAY" or uservariables_lastupdate[variableName]<5*60)   then
                    beaconHome=beaconHome+1
                end
            end
            if beaconHome==0 then ALARME !!!
        end
    ]]--

    if otherdevices['Alarm Mode'] == 'On' then
        -- détection motion toutes les 100 secondes (autoinit du Motion)
        -- arme Timer 10 secondes

        commandArray[#commandArray + 1] = { ['Alarm Sound Timer'] = 'On AFTER 10' }   -- Arme le Timer. Sirene in 10 secondes 			

        if My.Time_Difference(otherdevices_lastupdate['Alarm Sound Timer']) > 20 * 60   --ne sert que pour ne pas répéter la même phrase. Car un test est fait sur la répétition de la sirene
        then
            -- un seul déclenchement toutes les 5 minutes
            commandArray[#commandArray + 1] = { ['SendNotification'] = 'Maison/Alarm - Alarm Mode ON , Intrusion detected. Arm the 10 seconds timer. # Speak qui est là.' .. time.hour .. 'h' .. time.min .. '#0' }
            -- TODO prendre photo !!!
            My.Speak("Qui est là ? Jappelle la police. Alarme dans 5 secondes", "fort")   -- 10secondes en vrai
        else -- il y a déjà eu un déclenchement en moins de 15 minutes
            My.Speak("La police arrive. Allez-vous en.", "fort")
            commandArray[#commandArray + 1] = { ['SendNotification'] = 'Maison/Alarm - Intrusion detected again. Arm the 10 seconds timer. # Speak Go away.' .. time.hour .. 'h' .. time.min .. '#0' }
            -- TODO prendre photo !!!
        end
    end

    -- #####################  Security by night  between 0h30 and 6h00
    if otherdevices['Alarm Mode'] == 'Night' -- check for security by night
    and minutes > 30 and minutes < 6 * 60
    then
        if My.Time_Difference(otherdevices_lastupdate['Motion Upstairs']) > 3 * 60    -- 3 minutes
        then
            -- No move upstairs first
            My.Speak("Qui est là ? Jappelle la police.", "fort", "siren")
            commandArray[#commandArray + 1] = { ['SendNotification'] = 'Maison/Alarm - Intrusion detected by night. # Speak Who s here ? ' .. time.hour .. 'h' .. time.min .. '#0' }
            -- TODO: prendre photo !!!
        else -- Détection + membre de la famille vient de l'étage. => désactive l'alarme pour le reste de la nuit.
            My.Speak("Alarme nocturne désactivée pour le reste de la nuit.", "faible")
            commandArray[#commandArray + 1] = { ['Alarm Mode'] = 'Off' }
            commandArray[#commandArray + 1] = { ['Alarm Mode'] = 'On AFTER 36000' } -- Réactive l'alarme 10h après. (au plus tard c'est à 16h)
            commandArray[#commandArray + 1] = { ['SendNotification'] = 'Maison/Alarm - Authorized Move by night. Disarm Alarm until tomorrow# ' .. time.hour .. 'h' .. time.min .. '#0' }
        end
    end
end

return commandArray
