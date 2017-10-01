--[[
~/domoticz/scripts/lua/script_device_MailBox.lua

REQUIRE :
device['MailBox']


]]--

package.path = package.path .. ';' .. '/home/pi/domoticz/scripts/lua/?.lua'
My = require('My_Library')


commandArray = {}

local timeNow = os.date("*t")

if devicechanged['MailBox'] and otherdevices['MailBox'] == 'On' then
    s = otherdevices_lastupdate['MailBox']

    if timeNow.hour >= 8 and timeNow.hour < 21 --and uservariables['mode']== "DayOff"
    then
        sentence = "Du courrier vient d\'être déposé dans la boite aux lettres."
        My.Speak(sentence, "normal")
    end
    body = "Du courrier est arrivé à " .. string.sub(s, 12, 13) .. "h" .. string.sub(s, 15, 16)
    table.insert(commandArray, { ['SendNotification'] = 'Maison/Courrier#' .. body .. '#0' } )
end

return commandArray

