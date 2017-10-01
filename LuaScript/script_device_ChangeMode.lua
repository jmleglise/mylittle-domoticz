--[[
Script : ~/domoticz/scripts/lua/script_device_ChangeMode.lua

Au changement manuel du switch mode => set de la UserVariable "mode"
Si passage en Auto : calcul auto des jours fériés, samedi, dimanche ...
Dans les autres cas, forcer la uservariable.

REQUIRE :
Variable:mode
    uservariables['mode']== "DayOff"
    uservariables['mode']== "WorkingDay"
    uservariables['mode']== "Away"
otherdevices['Mode']


]]--
commandArray = {}

if devicechanged['Mode'] then
    if otherdevices['Mode'] == "Auto" then
        require "scripts/lua/lib_jourFerie"

        JourFerieTab = {}
        local weekday = os.date("%w")   -- jour de la semaine : 0=sunday  to 6=saturday
        -- important : dans tous les cas, on set le switch Ferie car le test d'execution du script est sur la date de lastchange de Ferie (1 seule fois par jour)
        if JourFerie() == true or weekday == "0" or weekday == "6" then
            table.insert(commandArray, { ['Variable:mode'] = 'DayOff' } )
        else --  =nil
            table.insert(commandArray, { ['Variable:mode'] = 'WorkingDay' } )
        end
    elseif otherdevices['Mode'] == "Man. DayOff" then
        table.insert(commandArray, { ['Variable:mode'] = 'DayOff' } )
    elseif otherdevices['Mode'] == "Man. WorkDay" then
        table.insert(commandArray, { ['Variable:mode'] = 'WorkingDay' } )
    else
        table.insert(commandArray, { ['Variable:mode'] = 'Away' } )
    end
end
return commandArray
