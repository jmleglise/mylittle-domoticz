--[[  ~/domoticz/scripts/lua/script_time_AlerteMeteo.lua

Meteo France vigilance from domogeek API
 Information from Meteo France is updated everyday at 6AM and 4PM
 This script will check at 6.10AM and 4.10PM
]]--

package.path = package.path .. ';' .. '/home/pi/domoticz/scripts/lua/?.lua'
require('My_Config')

local EMAILTO=MY_CONFIG_EMAIL -- defined in My_Config.lua

function os.capture(cmd, raw)
    local f = assert(io.popen(cmd, 'r'))
    local s = assert(f:read('*a'))
    f:close()
    if raw then
        return s
    end
    s = string.gsub(s, '^%s+', '')
    s = string.gsub(s, '%s+$', '')
    s = string.gsub(s, '[\n\r]+', ' ')
    return s
end

commandArray = {}
time = os.date("*t")

if (time.min == 10 and (time.hour == 6 or time.hour == 16 )) then
    -- Trigger at 6:10 and 16:10

    local curl = '/usr/bin/curl'  -- Path to curl
    local idx = '70'    -- Device ID (Type Alert on virtual hardware)
    local dept = '75'    -- Department (France)

    local cmd = curl .. ' http://domogeek.entropialux.com/vigilance/' .. dept
    local color = os.capture(cmd .. '/color', true);
    local risk = os.capture(cmd .. '/risk', true);

    body = 'Alert Level :' .. color .. 'Risk:' .. risk .. '\n'
    body = body .. '\n Vigilance Crue: http://www.vigicrues.gouv.fr/rss/?codeTron=IF5&CdEntVigiCru=IF5'
    body = body .. '\n Vigilance Meteo :http://vigilance.meteofrance.com/Bulletin_sans.html?a=dept78&b=2&c='

    local sValue = 'Risque : ' .. risk
    local nValue = 0
    if color == "vert" then
        nValue = 1
    elseif color == "jaune" then
        nValue = 2
    elseif color == "orange" then
        nValue = 3
        commandArray['SendEmail']='Alerte Meteo#'..body..'#'..EMAILTO
    elseif color == "rouge" then
        nValue = 4
        commandArray['SendEmail']='Alerte Meteo#'..body..'#'..EMAILTO
        table.insert(commandArray, { ['SendNotification'] = 'Alerte Meteo#' .. body .. '#0' } )
    else nValue = 0    -- TODO une erreur : pas d'alerte meteo
    end
    table.insert(commandArray, { ['UpdateDevice'] = idx .. '|' .. nValue .. '|' .. nValue .. '-' .. sValue } )
end

return commandArray

