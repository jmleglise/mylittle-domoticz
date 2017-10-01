--[[ Script : ~/domoticz/scripts/lua/script_time_Announce.lua

Morning and Evening Vocal Announcement

REQUIRE :
uservariable['mode']	otherdevices['Mode']
uservariable['goodMorning']
otherdevices_svalues['Sonde Perron']
otherdevices_svalues['Alerte Givre']
otherdevices_svalues['Alerte Meteo']
otherdevices['Alarm Mode']
otherdevices_lastupdate['MailBox']



##########################################################################################]]--
package.path = package.path .. ';' .. '/home/pi/domoticz/scripts/lua/?.lua'
My = require('My_Library')
require('My_Config')

local city = "Paris"
local wuAPIkey = WU_API_KEY -- From My_Config.lua file. Your Weather Underground API Key

local eventTable = {
    ["l'anniversaire de jean-claude"] = "24/11/1940",
    ["l'anniversaire de marthe"] = "02/08/1939",
    ["l'anniversaire de la soeur de jean-marc"] = "16/04/1970",
    ["l'anniversaire d'isabelle"] = "01/06/1972",
    ["l'anniversaire de marion"] = "28/11/2016",
    ["l'anniversaire de justine"] = "25/09/2011"
    --["l'anniversaire de lara"]="/04/",
    --          ["l'anniversaire de mathis"]="/04/",
}

function morning()
    local sentence = "Bonjour, nous sommes le " .. tonumber(os.date("%d")) .. "."  -- Good morning, today we are the ..
    liaison = " C'est "
    for event, date in pairs(eventTable) do
        if os.date("%d/%m") == date:sub(1, 5)
        then
            sentence = sentence .. liaison .. event .. ". "
            liaison = "et "
        end
    end

    ------------------  Alert méteo france ------------------

    if tonumber(string.sub(otherdevices_svalues['Alerte Meteo'], 1, 1)) == 3 then
        -- Only for FRANCE. Weather Vigilance  http://domogeek.entropialux.com/static/doc/index.html#api-Domogeek-GetVigilance
        sentence = sentence .. " Attention, Météofrance annonce une vigilance orange de type :" .. string.sub(otherdevices_svalues['Alerte Meteo'], 11) .. "."
    elseif tonumber(string.sub(otherdevices_svalues['Alerte Meteo'], 1, 1)) == 4 then
        sentence = sentence .. " Votre attention sil vous plait. Cest important. Météofrance annonce une alerte rouge de type :" .. string.sub(otherdevices_svalues['Alerte Meteo'], 11) .. "."
    end

    ------------------ TEMPERATURE & WEATHER FORECAST ------------------
    str = otherdevices_svalues['Sonde Perron']
    sentence = sentence .. "La température extérieure est de " .. tostring(My.Round(str, 0)) .. " degré." -- outdoor temperature

    json = (loadfile "/home/pi/domoticz/scripts/lua/json.lua")()
    local file = assert(io.popen('curl http://api.wunderground.com/api/' .. wuAPIkey .. '/forecast/lang:FR/q/France/' .. city .. '.json'))
    local raw = file:read('*all')
    file:close()

    local jsonForecast = json:decode(raw)
    prevision = jsonForecast.forecast.txt_forecast.forecastday[1].fcttext_metric  -- complete prevision
    --prevision=jsonForecast.forecast.simpleforecast.forecastday[1].conditions  -- small forecast

    local t = { -- Attention, le tableau est parcouru en ordre aléatoire.
        ["ºC"] = "degré",
        [" ENE "] = " ",
        [" ESE "] = " ",
        [" NNE "] = " ",
        [" NE "] = " ",
        [" N "] = " ",
        [" NNO "] = " ",
        [" NO "] = " ",
        [" SSE "] = " ",
        [" SE "] = " ",
        [" S "] = " ",
        [" SSO "] = " ",
        [" SO "] = " ",
        [" O "] = " ",
        [" ONO "] = " ",
        [" E "] = " ",

        --[[
                [" ENE "] = " Est Nord Est ",
                [" NNE "] = " Nord Nord Est ",
                [" NE "] = " Nord Est ",
                [" N "] = " Nord ",
                [" NNO "] = " Nord Nord Ouest ",
                [" NO "] = " Nord Ouest ",

                [" SSE "] = " Sud Sud Est ",
                [" SE "] = " Sud Est ",
                [" S "] = " Sud ",
                [" SSO "] = " Sud Sud Ouest ",
                [" SO "] = " Sud Ouest ",

                [" O "] = " Ouest ",
                [" ONO "] = " Ouest Nord Ouest ",
                [" E "] = " Est ",
        ]]--

        [",0"] = "",
        ["vents soufflant de 15 à 25 km/h."] = "Vent faible",
        ["vents soufflant de 10 à 25 km/h."] = "Vent faible",
        ["vents soufflant de 10 à 15 km/h."] = "Vent faible",
        ["km/h"] = "kilomètre heure",
        ["vents et variables."] = "" }

    for k, v in pairs(t) do
        prevision = string.gsub(prevision, k, v)
        --print(k.." / "..v.." / "..prevision)
    end

    sentence = sentence .. " Le temps de la journée sera " .. string.lower(prevision)

    ------------------  TRASH DAY MORNING ------------------
    -- Trash day : Mardi vegetaux & ordure / jeudi recyclage &  encombrant (pair) ou  verre (impair) / samedi ordure
    month = tonumber(os.date("%m"))
    day = tonumber(os.date("%d"))
    numOfWeek = tonumber(os.date("%V"))
    numOfDay = os.date("%w")

    if numOfDay == '2' or numOfDay == '4' or numOfDay == '6'
    then
        sentenceTrash = "Je vous rappelle également que "
        if (numOfDay == '4') then
            -- thursday
            if (numOfWeek % 2 == 0) then
                sentenceTrash = sentenceTrash .. " les encombrants et"  --pair
            else
                sentenceTrash = sentenceTrash .. " le verre et"  --impair
            end
            sentenceTrash = sentenceTrash .. " la poubelle jaune sont rammassés ce matin."
        elseif (numOfDay == '2') then
            -- Tuesday
            if (month == 3 and day >= 15) or -- Vegetables trash between the 15 March and the 15 december
            (month == 12 and day <= 15) or
            (month > 3 and month < 12)
            then
                sentenceTrash = sentenceTrash .. " les vegetaux et"
            end
            sentenceTrash = sentenceTrash .. " les poubelles sont ramassées ce matin."
        elseif (numOfDay == '6') then
            -- Saturday
            sentenceTrash = sentenceTrash .. " les poubelles sont ramassées ce matin."
        end
        sentence = sentence .. sentenceTrash
    end

    if (numOfDay % 2 == 0) then
        sentence = sentence .. " Je vous souhaite une agréable journée."
    else
        sentence = sentence .. " Passez une bonne journée."
    end
    My.Speak(sentence, "normal")
    commandArray[#commandArray + 1] = { ['SendNotification'] = 'Annonce du matin#' .. sentence .. '#0' }
end

function evening()
    sentence = ""

    ------------------ Alerte Givre  ------------------
    if tonumber(string.sub(otherdevices_svalues['Alerte Givre'], 1, 1)) > 1 then
        sentence = sentence .. " Il y aura du givre demain matin. Pensez à protéger le parebrise des voitures et les plantes."
    end

    ------------------ Alerte méteo  ------------------
    if tonumber(string.sub(otherdevices_svalues['Alerte Meteo'], 1, 1)) == 3 then
        -- Only for FRANCE. Weather Vigilance  http://domogeek.entropialux.com/static/doc/index.html#api-Domogeek-GetVigilance
        sentence = sentence .. " Météofrance annonce une vigilance orange de type :" .. string.sub(otherdevices_svalues['Alerte Meteo'], 11) .. "."
    elseif tonumber(string.sub(otherdevices_svalues['Alerte Meteo'], 1, 1)) == 4 then
        sentence = sentence .. " Météofrance annonce une alerte rouge de type :" .. string.sub(otherdevices_svalues['Alerte Meteo'], 11) .. ". Je répète, c est une alerte rouge. "
    end

    ------------------ Check special Event
    liaison = " Demain c'est "
    for event, date in pairs(eventTable) do
        if tostring(os.date("%d/%m", os.time() + 24 * 60 * 60)) == date:sub(1, 5) -- tomorrow=tostring(os.date("%d:%m",os.time()+24*60*60))
        then
            sentence = sentence .. liaison .. event .. ". "
            liaison = "et "
        end
    end

    ------------------ Alarme : en mode On, pas d'alarme nocturne. C'est l'alarme classique en continue.
    if otherdevices['Alarm Mode'] == 'Night' then
        -- check for security by night
        sentence = sentence .. "L'alarme nocturne est activée à minuit trente."
    elseif otherdevices['Alarm Mode'] == 'Off' then
        -- check for security by night
        sentence = sentence .. "L'alarme nocturne n'est actuellement pas activée."
    end

    ------------------ Check MAIL BOX ------------------
    if uservariables['mode'] == "DayOff" then
        -- Uniquement le samedi, férié , vacance ...
        s = otherdevices_lastupdate['MailBox']
        --tMail= os.time{year=string.sub(s, 1, 4), month=string.sub(s, 6, 7), day=string.sub(s, 9, 10), hour=string.sub(s, 12, 13), min=string.sub(s, 15, 16), sec=string.sub(s, 18, 19)}
        if string.sub(s, 9, 10) == os.date("%d") -- il y a eu du courrier aujourd'hui
        then
            sentence = sentence .. "vous avez reçu du courrier la dernière fois à " .. tonumber(string.sub(s, 12, 13)) .. " heure " .. tonumber(string.sub(s, 15, 16)) .. "."
        end
    end

    ------------------ TRASH DAY EVENING ------------------
    -- TRash day : Mardi vegetaux & ordure / jeudi recyclage &  encombrant (pair) ou  verre (impair) / samedi ordure
    numOfDay = os.date("%w") + 1  -- on teste pour le lendemain

    if numOfDay == '2' or numOfDay == '4' or numOfDay == '6'
    then
        month = tonumber(os.date("%m"))
        day = tonumber(os.date("%d"))
        numOfWeek = tonumber(os.date("%V"))

        sentenceTrash = "Je vous rappelle également que "
        if (numOfDay == '4') then
            -- thursday
            if (numOfWeek % 2 == 0) then
                sentenceTrash = sentenceTrash .. " les encombrants et"  --pair
            else
                sentenceTrash = sentenceTrash .. " le verre et"  --impair
            end
            sentenceTrash = sentenceTrash .. " la poubelle jaune sont rammassés ce matin."
        elseif (numOfDay == '2') then
            -- Tuesday
            if (month == 3 and day >= 15) or -- Vegetables trash between the 15 March and the 15 december
            (month == 12 and day <= 15) or
            (month > 3 and month < 12)
            then
                sentenceTrash = sentenceTrash .. " les vegetaux et"
            end
            sentenceTrash = sentenceTrash .. " les poubelles sont ramassées ce matin."
        elseif (numOfDay == '6') then
            -- Saturday
            sentenceTrash = sentenceTrash .. " les poubelles sont ramassées ce matin."
        end
        sentence = sentence .. sentenceTrash
    end

    if sentence ~= "" then
        sentence = "Bonsoir, je vous informe que, " .. sentence
        My.Speak(sentence, "normal")
        commandArray[#commandArray + 1] = { ['SendNotification'] = 'Annonce du soir#' .. sentence .. '#0' }
    end
end

commandArray = {}

local weekday = os.date("%w")   -- jour de la semaine : 0=sunday  to 6=saturday
local time = os.date("*t")
local minutes = time.min + time.hour * 60

--#######  VOCAL ANNOUNCEMENT - MORNING  #######################################################
-- en semaine : 8h14 précise  -- Pour marquer le départ de la maison
-- en DayOff : Entre 1 et 2 minutes après une détection de mouvement sous la véranda (1 seule fois)
if (uservariables['mode'] == "WorkingDay" and time.hour == 8 and time.min == 14)
or (uservariables['mode'] == "DayOff"
and My.Time_Difference(otherdevices_lastupdate['Motion Veranda']) > 60
and My.Time_Difference(otherdevices_lastupdate['Motion Veranda']) < 120
and string.sub(uservariables_lastupdate['goodMorning'], 9, 10) ~= os.date("%d")  -- Check Only one time per day
)
then
    commandArray[#commandArray + 1] = { ['Variable:goodMorning'] = "morning" }  -- something to update "lastupdate"
    morning()
end

-- #############  VOCAL ANNOUNCEMENT - EVENING #################
s = uservariables_lastupdate['goodMorning']
tAnnonce = os.time { year = string.sub(s, 1, 4), month = string.sub(s, 6, 7), day = string.sub(s, 9, 10), hour = string.sub(s, 12, 13), min = string.sub(s, 15, 16), sec = string.sub(s, 18, 19) }
t = os.time { year = string.sub(s, 1, 4), month = string.sub(s, 6, 7), day = string.sub(s, 9, 10), hour = 19, min = 03, sec = 50 }
if tAnnonce < t -- Si date de goodmorning est avant 19h03
and minutes > 19 * 60 + 40 -- et qu'il est plus tard que 19h40
and (My.Time_Difference(otherdevices_lastupdate['Motion Veranda']) < 60 or minutes == 20 * 60 + 5) -- lors d'un mouvement	ou 20h05.
-- TODO  revoir cette condition
then
    commandArray[#commandArray + 1] = { ['Variable:goodMorning'] = "evening" }  -- something to update "lastupdate"
    evening()
end

return commandArray
