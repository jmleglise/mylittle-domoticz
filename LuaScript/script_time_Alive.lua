--[[  ~/domoticz/scripts/lua/script_time_Alive.lua

- Output "Alive" every 3 minutes in the log of Domoticz. This is necessery for new system that do nothing yet to prevent unwanted reboot by watchdog system.
- Check the life Time of somes sensors. May be a clue of low battery. Send this alert by email.

https://www.domoticz.com/wiki/Setting_up_the_raspberry_pi_watchdog
]]--

package.path = package.path .. ';' .. '/home/pi/domoticz/scripts/lua/?.lua'
require('My_Config')

commandArray = {}

time = os.date("*t")
frequency = 3
destEmail = MY_CONFIG_EMAIL  -- From My_Config.lua file :  Where messages should be sent.
bodyMail = ""

if ((time.min % frequency) == 0) then
    print('Domoticz alive !')   -- mandatory , without it, (watchdog ?) will reboot domoticz

    -- Checks if some sensors have been received recently, and
    -- otherwise sends an e-mail to tell us to go check the lost one.
    now = os.time()

    local tableDeviceToCheck = {
        MailBox = 259200, -- 3 days  3*24*60*60,
        ["Motion Veranda"] = 86400, -- 1 days   1*24*60*60,
        ["Motion LivingRoom"] = 86400, -- 1 days   1*24*60*60,
        ["Alerte Gel"] = 28800, -- 8 hours  8*60*60,
        ["Trajet Home=>PMU"] = 28800,
        ["Lux"] = 24 * 60 * 60, -- KO !!!
        ["Alerte Meteo"] = 24 * 60 * 60,
        ["CPU"] = 3600,
        ["WU Barometre"] = 28800,
        --["Sonde Justine"]=3600,
        ["Sonde THGN500"] = 3600,
        ["Sonde Perron"] = 3600,
        ["Sonde Veranda"] = 3600
    }

    for deviceName, deviceTimeOut in pairs(tableDeviceToCheck) do
        --print(deviceName .." delay"..deviceTimeOut)
        s = otherdevices_lastupdate[deviceName]
        year = string.sub(s, 1, 4)
        month = string.sub(s, 6, 7)
        day = string.sub(s, 9, 10)
        hour = string.sub(s, 12, 13)
        minutes = string.sub(s, 15, 16)
        seconds = string.sub(s, 18, 19)
        lastAlive = os.time { year = year, month = month, day = day, hour = hour, min = minutes, sec = seconds }

        -- Alert only once in the period that follows the timeout
        if (now > lastAlive + deviceTimeOut)
        and now < (lastAlive + deviceTimeOut + frequency * 60)
        then
            bodyMail = bodyMail .. deviceName .. " has not been seen since " .. s .. ".<br>\n"
        end
    end

    if bodyMail ~= "" then
        subject = 'Maison - Device lost !'
        table.insert(commandArray, { ['SendEmail'] = subject .. '#' .. bodyMail .. '#' .. destEmail } )
    end
end

return commandArray
