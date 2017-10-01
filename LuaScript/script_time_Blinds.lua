--[[######################################################################################
Script : ~/domoticz/scripts/lua/script_time_Blinds.lua

Roller Shutter automation according to :
solar Lux
hour
jour Férié
weekend
away from home
holidays at home

Require: uservariable['mode']	otherdevices['Mode']

Script : ~/domoticz/scripts/lua/script_time_Blinds.lua

Info : Opening the roller shutter. entre 4 sec. et total 17sec

##########################################################################################]]--

package.path = package.path .. ';' .. '/home/pi/domoticz/scripts/lua/?.lua'
My = require('My_Library')
 
commandArray = {}

local weekday = os.date("%w")   -- jour de la semaine : 0=sunday  to 6=saturday
local time= os.date("*t")
local minutes = time.min + time.hour * 60


if (uservariables['mode'] ~= "Away") then  

--####### SALON   27   #######################################################

--	##### 	OUVRIR  à 7h01 ou avant 8h05 si la luminosité est suffisante

	if (time.hour==7) and (time.min==1) and otherdevices['Automatic VR Salon']=='On'
--[[	
	(otherdevices['Volet Salon']=='Closed' or otherdevices['Volet Salon']=='Stopped') 
   		and otherdevices['Automatic VR Salon']=='On'
		and ((minutes == 8*60+5) or (minutes > 7*60+5 and minutes < 8*60+5 and tonumber(otherdevices_svalues['Lux'])>50))  -- <8h05 pour le ne faire qu'1 fois par jour si jamais commande manuelle change "closed"
]]--
	then 
   --string.sub(otherdevices_lastupdate['Volet Salon'], 9, 10) ~= os.date("%d") then -- le volet n' a pas encore bougé aujourd'hui
		commandArray[#commandArray + 1]={['Volet Salon']='Off'}
		
	end

--	##### FERMER  Everyday  : au noir total et après 19h30, et 1 seule fois (si le volet n'a pas bougé après 19h30)

	if (otherdevices['Volet Salon']=='Open' or otherdevices['Volet Salon']=='Stopped') 
		and tonumber(otherdevices_svalues['Lux'])==0 and minutes > (19*60+30)
		and otherdevices['Automatic VR Salon']=='On'
	then
		s=otherdevices_lastupdate['Volet Salon']
		tVolet= os.time{year=string.sub(s, 1, 4), month=string.sub(s, 6, 7), day=string.sub(s, 9, 10), hour=string.sub(s, 12, 13), min=string.sub(s, 15, 16), sec=string.sub(s, 18, 19)}
		t= os.time{year=string.sub(s, 1, 4), month=string.sub(s, 6, 7), day=string.sub(s, 9, 10), hour=19, min=29, sec=50}		
-- TODO : revoir la condition: le volet se ferme si l'heure actuelle , c'est l'heure de passage de Lux à 0.    (proche à 1min pret).
		if tVolet<t  -- condition : le volet ne se ferme qu'une fois. il a bougé en open ou stopped, avant 19h29  (s'il a bougé après, c'est une manip manuelle, donc ne pas refermer).
		then
			commandArray[#commandArray + 1]={['Volet Salon']='On AFTER 30'}
			My.Speak("Je fermerais le volet du salon dans 30 secondes.","normal")
		end
	end

--####### MARION  26   #######################################################

--	##### 	OUVRIR  07:10	Workdays
	if (time.hour==7) and (time.min==10)
		and (uservariables['mode']== "WorkingDay")
		and otherdevices['Automatic VR Justine']=='On'
	then
			commandArray[#commandArray + 1]={['Volet Justine']='Off'} --  open
			
			if tonumber(otherdevices_svalues['Lux'])>800 then
				commandArray[#commandArray + 1]={['Volet Justine']='Stopped AFTER 4'}
				
				commandArray[#commandArray + 1]={['Volet Justine']='Off AFTER 120'} --  open Total
				
				commandArray[#commandArray + 1]={['Volet Justine']='Stopped AFTER 124'}
				
				commandArray[#commandArray + 1]={['Volet Justine']='Off AFTER 300'} --  open Total
				
			elseif tonumber(otherdevices_svalues['Lux'])>300 then
				commandArray[#commandArray + 1]={['Volet Justine']='Stopped AFTER 7'}
				
				commandArray[#commandArray + 1]={['Volet Justine']='Off AFTER 300'} --  open Total
				
			end
	end

--	##### 	FERMER à la nuit si c'est avant 20h10; 
-- sinon à 20h10 s'il fait encore jour.
	if (    
			(tonumber(otherdevices_svalues['Lux'])==0 and My.Time_Difference(otherdevices_lastupdate['Lux'])<60 and minutes < 20*60+10 )  -- dans la minute de passage à Lux 0 si c'est avant 20h10.
			or (minutes == 20*60+10 and tonumber(otherdevices_svalues['Lux'])>0) 
		)
		and otherdevices['Automatic VR Justine']=='On' 
	then
		commandArray[#commandArray + 1]={['Volet Justine']='On'}
		
	end

--####### PARENTS  25   #######################################################

--	##### 	OUVRIR   07:15	Workdays      7:20     7:35   
	if (time.hour==7) and (time.min==15)
		and (uservariables['mode']== "WorkingDay")
		and otherdevices['Automatic VR Parent']=='On'
	then
			commandArray[#commandArray + 1]={['Volet Parents']='Off'} --  open
			
--			if tonumber(otherdevices_svalues['Lux'])>300 then						-- au dela de 1000 
				commandArray[#commandArray + 1]={['Volet Parents']='Stopped AFTER 6'}
				
				commandArray[#commandArray + 1]={['Volet Parents']='Off AFTER 300'} --  open Total
				
				commandArray[#commandArray + 1]={['Volet Parents']='Stopped AFTER 304'}
				
				commandArray[#commandArray + 1]={['Volet Parents']='Off AFTER 1200'} --  open Total
				
--			elseif tonumber(otherdevices_svalues['Lux'])>200 then					-- entre 500 et 1000 
--				commandArray[#commandArray + 1]={['Volet Parents']='Stopped AFTER 3'}
--				
--				commandArray[#commandArray + 1]={['Volet Parents']='Off AFTER 300'} --  open Total
--				
--			end
	end


--	FERMER à la nuit si c'est avant 22h00;
-- sinon à 22h00 s'il fait encore jour.
	if (    
			(tonumber(otherdevices_svalues['Lux'])==0 and My.Time_Difference(otherdevices_lastupdate['Lux'])<60 and minutes < 22*60 )  -- -- dans la minute de passage à Lux 0 si c'est avant 22h.
			or (minutes == 22*60 and tonumber(otherdevices_svalues['Lux'])>0) 
		)
		and otherdevices['Automatic VR Parent']=='On'
	then
		commandArray[#commandArray + 1]={['Volet Parents']='On'}
		     
	end

--[[

--####### LUMIERE  #######################################################
--	Allumer au noir total, après 19h30. Et pas après 20h30 ou 21h30 (pour ne pas rallumer lorsqu'elle s'éteint).
	if otherdevices['Prise Salon']=='Off'
		and tonumber(otherdevices_svalues['Lux'])==0
		and minutes > (19*60+30)
		and ((uservariables['mode']== "WorkingDay" and minutes <20*60+30) or (uservariables['mode']== "DayOff" and minutes < 21*60+30))
	then
		commandArray[#commandArray + 1]={['Prise Salon']='On'}
		
		commandArray[#commandArray + 1]={['Prise TV']='On'}
		
	end
-- Eteindre  20h30 ou 21h30
	if otherdevices['Prise Salon']=='On'
		and ((uservariables['mode']== "WorkingDay" and minutes>20*60+30) or (uservariables['mode']== "DayOff" and minutes > 21*60+30))
	then --
		commandArray[#commandArray + 1]={['Prise Salon']='Off'}
		
		commandArray[#commandArray + 1]={['Prise TV']='Off'}
		
	end
]]--

end


return commandArray
