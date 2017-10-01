--[[  ~/domoticz/scripts/lua/script_time_BeaconPresence.lua

Every minutes, update the switch "Beacon."  according of all the beacon UserVariable.

REQUIRE :
devices['Beacon']
uservariables Tag

]]--



commandArray = {}
--beaconAway=0
beaconHome=0

for variableName, variableValue in pairs(uservariables) do
    if string.sub(variableName,1,3)=="Tag" and variableValue ~= "AWAY" then
		beaconHome=beaconHome+1
	--else
	--	beaconAway=beaconAway+1
    end
end

if otherdevices['Beacon'] == 'On' and beaconHome==0 then   -- switch Off Alarm because 1 beacon come back Home
    table.insert (commandArray, { ['Beacon'] ='Off' } )
--	print("switch Off")
elseif otherdevices['Beacon'] == 'Off' and beaconHome>=1 then  -- switch On Alarm because all beacon are away
    table.insert (commandArray, { ['Beacon'] ='On' } )
--	print("switch On")	
end

return commandArray
