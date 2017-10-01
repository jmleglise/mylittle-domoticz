--[[######################################################################################
Script : ~/domoticz/scripts/lua/script_time_ControlHeating.lua

Alert if temperature is rising by night when the Heating shall be stopped

En semaine à 20h30
Le wk à 23h30

relevé de la temperature du salon en variable 
1h30 après si la temperature a augmenter => alerter.


##########################################################################################]]--

commandArray = {}

	numOfDay=os.date("%w")
	local time= os.date("*t")
	tempSalon=tonumber(otherdevices_svalues['Sonde Veranda'])

	if 	((numOfDay == '1' or numOfDay == '2' or numOfDay == '3' or numOfDay == '4' or numOfDay == '5') and time.hour==20 and time.min==30)
		or ((numOfDay == '0' or numOfDay == '6') and time.hour==23 and time.min==30)
	then
		commandArray[#commandArray + 1]={['Variable:controlHeating']=tostring(tempSalon)}  
	end
	
	if ((numOfDay == '1' or numOfDay == '2' or numOfDay == '3' or numOfDay == '4' or numOfDay == '5') and time.hour==22 and time.min==0) 
	or ((numOfDay == '0' or numOfDay == '1') and time.hour==1 and time.min==0)
	then
		if tempSalon>uservariables['controlHeating']
		then
			str=string.gsub(tempSalon, "%.", ",")
			sentence="Excusez moi de vous déranger. Je détecte une augmentation anormale de la température du salon. La température augmente depuis 1 heure alors que le chauffage aurait dû s'arréter. Il fait "..str.." degré." 

			if (uservariables['mode']=="Away") then 
				commandArray[#commandArray + 1]={['SendNotification']='Maison#'..sentence..'#0'}
			else
				--os.execute("izsynth \""..sentence.."\" &")
				commandArray[#commandArray + 1]={['SendNotification']='Maison#'..sentence..'#0'}
			end
		end
	end
return commandArray
