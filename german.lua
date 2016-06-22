------------------------------------------
-- Small Draconic Reactor Control	--
-- https://youtu.be/Ud5JXVacnwY		--
-- !!! Save this file as SDRC !!!	--
-- pastebin run nrA4gNxb		--
------------------------------------------

local Schrittweite = 10000 -- Variation des Flux-Gate-Status um diesen Wert
local Schwelle = 300000000 -- Interaktionsgrenze x00.000.000 ist x00 Mio !!!

print("|#==  https://youtu.be/Ud5JXVacnwY   ==#|")
print("|#============#| S D R C |#============#|")
--print("ReactorInfo getReactorInfo") -- lese die einzelnen Parameter des Reaktor
tbl = peripheral.call("back","getReactorInfo")
for k, v in pairs (tbl) do
	--print(k,v)
	if k == "temperature" then -- Weise bestimmte programmrelevante Parameter einzelnen Variablen zu
		temperatur = v
	end
	if k == "energySaturation" then
		energysat = v
	end
	if k == "fieldStrength" then
		feldst = v
	end
	if k == "generationRate" then
		RFpt = v
	end
	if k == "fuelConversion" then
		RestKraftstoff = v
	end
	if k == "fuelConversionRate" then
		Kraftstoffverbrauch = v
	end
end
energieladung = energysat * 0.0000001
fieldstr = feldst * 0.000001
kRFpt = RFpt / 1000
fuel = RestKraftstoff / 10368
FuelConv = fuel * 100
--------------------------------------------------
print("|# Reactor temperature = "..temperatur)
print("|# Energy saturation % = "..energieladung)
print("|# Field strength % = "..fieldstr)
print("|# Refuel level % = "..FuelConv)
--print("|# ConvesionRate = "..Kraftstoffverbrauch)
print("|# Energyproduction RF/t = "..kRFpt)
print("|#============#| S D R C |#============#|")
--------------------------------------------------
FluxGateStatus = peripheral.call("right", "getSignalLowFlow")
-- Frage aktuellen Status der High-Rate im FluxGate ab - NICHT den tatsaechlichen Durchfluss

if energysat > Schwelle then -- wenn die Energy-Saturation den Schwellwert unterschreitet ...
	-- ist platz fuer Erhoehung des RF-Outputs
	if FluxGateStatus >= 690000 then -- Maximalwert abregelung 700k
		FluxGateStatus = 690000
		print("|#==      !Safemode!  all okay!      ==#|")
		print("|#==    Reactor maximum 700k RF/t    ==#|")
		print("|#============#| S D R C |#============#|")		
	end
	FluxGateStatus = FluxGateStatus + Schrittweite -- anpassen der Flux-Gate_Variablen an den neuen Wert
	print("|#== FluxGate set to = ", FluxGateStatus)
	peripheral.call("right", "setSignalLowFlow", FluxGateStatus) -- Einstellen des Flux-Gate auf einen neuen Wert
end
if energysat < Schwelle then
	if FluxGateStatus <= 10000 then -- Minimalwert abregelung auf 0
		FluxGateStatus = 10000
	end
	FluxGateStatus = FluxGateStatus - Schrittweite -- anpassen der Flux-Gate_Variablen an den neuen Wert
	print("|#== FluxGate set to = ", FluxGateStatus)
	peripheral.call("right", "setSignalLowFlow", FluxGateStatus)
end
---------- Notabschaltung bei unterschreiten der Grenzwerte und wieder aktivierung
if temperatur > 7777 then -- Temperatur check wenn mehr als 7777 Grad
	peripheral.call("back", "stopReactor")

	print("|#==      Reactor to hot stop !      ==#|")
	print("|#============#| S D R C |#============#|")
	sleep(60)
end
if FuelConv >= 75 then -- Abschaltung wenn mehr als 75% Reststoffe bis max 90% einstellbar
	peripheral.call("back", "stopReactor")

	print("|#==      Reactor refuel stop !      ==#|")
	print("|#============#| S D R C |#============#|")
	sleep(300)
end
if temperatur <= 2000 then -- Starttest zum aufladen des Reaktors
	peripheral.call("back", "chargeReactor")
		print("|#==        Reactor charge !!        ==#|")
		print("|#============#| S D R C |#============#|")
	if feldst >= 50000000 then
		peripheral.call("back", "activateReactor")
			print("|#==        Reactor activate !       ==#|")
			print("|#============#| S D R C |#============#|")
	end
else
	if feldst <= 15000000 then -- Notabschaltung bei zu niedrigen Schutzschild
		peripheral.call("back", "stopReactor")
		print("|#==     Reactor Emergency stop !    ==#|")
		print("|#==     Field strength to low !     ==#|")
		print("|#============#| S D R C |#============#|")
	else
		if feldst >= 20000000 then
			peripheral.call("back", "activateReactor") -- Neuaktivierung nach Notabschaltung
			--print("|#==         Reactor active !        ==#|")
			--print("|#============#| S D R C |#============#|")
		end
	end
	if energysat <= 15000000 then -- Notabschaltung bei zu niedriger Energiesaetigung
		peripheral.call("back", "stopReactor")
		print("|#==    Reactor Emergency stop !!    ==#|")
		print("|#==    Energy saturation to low!    ==#|")
		print("|#============#| S D R C |#============#|")
	else
		if energysat >= 20000000 then
			peripheral.call("back", "activateReactor") -- Neuaktivierung nach Notabschaltung
			--print("|#==        Reactor activate !       ==#|")
			--print("|#============#| S D R C |#============#|")
		end
	end
end
sleep(2)
os.reboot()