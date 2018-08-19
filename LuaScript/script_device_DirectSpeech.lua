--[[ Script : ~/domoticz/scripts/lua/script_device_DirectSpeech.lua

Text To Speak the text of A device Text. => Change the text of the device and the TTS system will speak.

REQUIRE :
A Virtual device of type "Text" and of name 'Direct Speech'

]]--

package.path = package.path .. ';' .. '/home/pi/domoticz/scripts/lua/?.lua'
My = require('My_Library')


commandArray = {}
if devicechanged['Direct Speech']  then
    sentence = tostring(otherdevices_svalues['Direct Speech'])
   -- print(" other:"..otherdevices['Direct Speech'].." svalue:"..otherdevices_svalues['Direct Speech'])

    if sentence ~= nil and sentence ~= "" then
        My.Speak(sentence, "normal")
    else
        commandArray['UpdateDevice'] = "152|_|_"     -- 152 is the idx of my text device "Direct Speech"
    end
    end

return commandArray

