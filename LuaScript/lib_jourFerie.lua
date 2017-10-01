-- ~/domoticz/scripts/lua/lib_jourFerie.lua

function JourFerie()
    local today=os.date("%m-%d")
	--today='01-01'    -- DEBUG : test pour forcer un jour férié
    local annee=tonumber(os.date("%Y"))
		-- Dates fixes
		JourFerieTab["01-01"] = true -- 1er janvier
		JourFerieTab["05-01"] = true -- Fête du travail   1er Mai
		JourFerieTab["05-08"] = true -- Victoire des alliés   8 Mai
		JourFerieTab["07-14"] = true -- Fête nationale 	14 Juillet
		JourFerieTab["08-15"] = true -- Assomption	15 Aout
		JourFerieTab["11-01"] = true -- Toussaint	1er Nov
		JourFerieTab["11-11"] = true -- Armistice	11 Nov
		JourFerieTab["12-25"] = true -- Noël
		-- Dates variables
		local epochPaques=GetJourPaques(annee)
		JourFerieTab[os.date("%m-%d",epochPaques)] = true -- Pâques
		JourFerieTab[os.date("%m-%d",epochPaques+24*60*60)] = true -- Lundi de Pâques = Pâques + 1 jour
		JourFerieTab[os.date("%m-%d",epochPaques+24*60*60*39)] = true -- Ascension = Pâques + 39 jours
		JourFerieTab[os.date("%m-%d",epochPaques+24*60*60*49)] = true -- Pentecôte = Ascension + 49 jours
	return JourFerieTab[today] -- (nldr : Both nil and false make a condition false)
end

	
function GetJourPaques(annee)
    -- Retourne le jour de Pâques au format epoch
    -- annee : année (Integer) dont on désire connaître le jour de Pâques (ex : 2014)
    -- La fonction n'effectue le calcul que si l'année a changée depuis son dernier appel
	
    local a=math.floor(annee/100)
    local b=math.fmod(annee,100)
    local c=math.floor((3*(a+25))/4)
    local d=math.fmod((3*(a+25)),4)
    local e=math.floor((8*(a+11))/25)
    local f=math.fmod((5*a+b),19)
    local g=math.fmod((19*f+c-e),30)
    local h=math.floor((f+11*g)/319)
    local j=math.floor((60*(5-d)+b)/4)
    local k=math.fmod((60*(5-d)+b),4)
    local m=math.fmod((2*j-k-g+h),7)
    local n=math.floor((g-h+m+114)/31)
    local p=math.fmod((g-h+m+114),31)
    local jour=p+1
    local mois=n
        
    return os.time{year=annee,month=mois,day=jour,hour=12,min=0}
end	
