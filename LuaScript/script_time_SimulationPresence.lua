--[[Script : ~/domoticz/scripts/lua/script_time_SimulationPresence.lua

OBJET :
when Away, simulate presence by operating TV, switch, roller shutter

REQUIRE:
uservariable['mode']
otherdevices['Mode']
device['Volet Salon']
device['Prise Salon']
device['Prise TV']
device['Volet Justine']

]]--


commandArray = {}

local weekday = os.date("%w")   -- jour de la semaine : 0=sunday  to 6=saturday
local time = os.date("*t")
local minutes = time.min + time.hour * 60

--####### AWAY ################################################################################################

if (uservariables['mode'] == "Away") then
    -- Away from home, so simulate presence.

    --####### Salon
    -- Salon  éclaire matin pendant 40min et soir entre 21h et 21h40
    -- Chambre Justine éclaire entre 22h15 et 22h55

    --	OUVRIR OFF  After Sunrise	00:00	Everyday
    if minutes == (timeofday['SunriseInMinutes'] - 60) then
        commandArray[#commandArray + 1] = { ['Volet Salon'] = 'Off' }
        commandArray[#commandArray + 1] = { ['Prise Salon'] = 'On' }
    end
    if minutes == (timeofday['SunriseInMinutes'] - 20) then
        commandArray[#commandArray + 1] = { ['Prise Salon'] = 'Off' }
    end

    if (time.hour == 20) and (time.min == 40) then
        commandArray[#commandArray + 1] = { ['Prise TV'] = 'On' }
    end

    if (time.hour == 22) and (time.min == 40) then
        commandArray[#commandArray + 1] = { ['Prise TV'] = 'Off' }
    end


    if minutes == (timeofday['SunsetInMinutes']) then
        commandArray[#commandArray + 1] = { ['Prise Salon'] = 'On' }
    end

    if minutes == (timeofday['SunsetInMinutes'] + 40) then
        commandArray[#commandArray + 1] = { ['Volet Salon'] = 'On' }
        commandArray[#commandArray + 1] = { ['Prise Salon'] = 'Off' }
    end

    --####### Chambre Justine

    if (time.hour == 9) and (time.min == 30) then
        commandArray[#commandArray + 1] = { ['Volet Justine'] = 'Off' }
    end

    if minutes == (timeofday['SunsetInMinutes'] + 44) then
        commandArray[#commandArray + 1] = { ['Prise Justine'] = 'On' }
    end

    if minutes == (timeofday['SunsetInMinutes'] + 120) then
        commandArray[#commandArray + 1] = { ['Volet Justine'] = 'On' }
        commandArray[#commandArray + 1] = { ['Prise Justine'] = 'Off' }
    end
end

return commandArray
