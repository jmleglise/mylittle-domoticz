--[[######################################################################################
Script : ~/domoticz/scripts/lua/script_time_setTodayMode.lua

Les scripts utilisent la uservariable mode

Changement du switch Mode:
manuel, away  => fixe la uservariable
auto => execute férie

à  minuit : si en auto , execute férié, calcule la uservariable


Calcule le type de journée :
si férié ou Week End => DayOff
Si Away : pas de modification

Require: otherdevices['Mode']

##########################################################################################]]--


	
--	######################################################################################


commandArray = {}

dateLastUpdateMode = string.sub(uservariables_lastupdate['mode'], 1, 10)   -- Get "Y-m-d" from lastupdate
--dateLastUpdateMode = "" -- DEBUG : Force l'execution pour test

if (os.date("%Y-%m-%d") ~= dateLastUpdateMode) then -- Une seule execution par jour : compare date du jour avec date de mise � jour du switch Mode 
	print("Check the Mode of the day")
	json = (loadfile "/home/pi/domoticz/scripts/lua/lib_jourFerie.lua")()  -- For Linux
    JourFerieTab = {}
	local weekday = os.date("%w")   -- jour de la semaine : 0=sunday  to 6=saturday

	if otherdevices['Mode']	=="Auto" then
		if JourFerie()==true or weekday == "0" or weekday == "6" then 
            table.insert (commandArray, { ['Variable:mode'] ='DayOff' } )                
		else
            table.insert (commandArray, { ['Variable:mode'] ='WorkingDay' } ) 
		end
	else  -- manuel & away
		-- important : dans tous les cas, on set la uservariable car le test d'execution du script est sur la date de lastchange (1 seule fois par jour)
        table.insert (commandArray, { ['Variable:mode'] =uservariables['mode'] } )        
	end
end

return commandArray
