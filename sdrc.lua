-- kevin olson (asidjazz/256.io/etc)

-- heavily modified alteration of EterniaLogic modified SDRC script

-----------
-- The Field input value should be 30% of the power provied
-- Capacitors are used to help guage when the power storage is full
-- The inflow flux gate can also be modem networked together with the computer
--
-----------

-- ReS - Reactor Stabilizer
-- "+" - Cryo-stabilized fluxduct
-- CPU - Computer
-- FxG - Flux Gate
-- ___ - Air
-- CAP - Basic Capacitor (The smaller the total value, the better)

-- ==Level 1==
-- ReS +
-- CPU FxG
-- ___ +

-- ==Level 2==
-- ___ CAP
-- CAP CAP
-- ___ CAP

wantedField=50000000 					-- Force the field value to this approximate value


ValueChange = 10000 -- Change on the Flux Gate over time (Not exact, temperature and saturation divide this)
MinEnergySat = 1000000 -- Minimum energy saturation level
WantedRFt = 1200000
totalFuel = 10368   -- Fully upgraded reactor

CapacitorNum = 5 							-- 5 Capacitors on top of computer
CapacitorVal = 1000000 					-- Power holding capacity of the capacitors


FIRavg = {} 	-- last FIR to go     [Flux Input Rate]
FIRLen = 20 	-- length of averages
FIRi = 0 		-- location to do running average
FIRVal = 200000 -- initial value for FIR
FIRChg = false  -- has an up-down happened?
FIRLow = 0
FIRHigh = 0
FIRLastDelta = 999999
reactorState = "..."

for i=0, FIRLen-1 do
	FIRavg[i] = FIRVal
end

local mon
local monX
local monY

local inputfluxgate

function periphSearch(type)
   local names = peripheral.getNames()
   local i, name
   for i, name in pairs(names) do
      if peripheral.getType(name) == type then
         return peripheral.wrap(name)
      end
   end
   return null
end

function periphSearchName(type)
   local names = peripheral.getNames()
   local i, name
   for i, name in pairs(names) do
      if peripheral.getType(name) == type then
         return name
      end
   end
   return null
end

-------------------FORMATTING-------------------------------

-- 5000 becomes 5,000
function format_int(number)

  local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
  -- reverse the int-string and append a comma to all blocks of 3 digits
  int = int:reverse():gsub("(%d%d%d)", "%1,")

  -- reverse the int-string back remove an optional comma and put the 
  -- optional minus and fractional part back
  return minus .. int:reverse():gsub("^,", "") .. fraction
end

function clear()
  term.clear()
  term.setCursorPos(1,1)
  mon.setBackgroundColor(colors.black)
  mon.clear()
  mon.setCursorPos(1,1)
end
 
--display text text on monitor, "mon" peripheral
function draw_text(x, y, text, text_color, bg_color)
  mon.setBackgroundColor(bg_color)
  mon.setTextColor(text_color)
  mon.setCursorPos(x,y)
  mon.write(text)
end

function draw_text_right(offset, y, text, text_color, bg_color)
	mon.setBackgroundColor(bg_color)
	mon.setTextColor(text_color)
	mon.setCursorPos(monX-string.len(text)-offset,y)
	mon.write(text)
end
 
--draw line on computer terminal
function draw_line(x, y, length, color)
    mon.setBackgroundColor(color)
    mon.setCursorPos(x,y)
    mon.write(string.rep(" ", length))
end
 
--create progress bar
--draws two overlapping lines
--background line of bg_color
--main line of bar_color as a percentage of minVal/maxVal
function progress_bar(x, y, length, minVal, maxVal, bar_color, bg_color)
  draw_line(x, y, length, bg_color) --backgoround bar
  local barSize = math.floor((minVal/maxVal) * length)
  draw_line(x, y, barSize, bar_color) --progress so far
end
 
mon = periphSearch("monitor")
inputfluxgate = periphSearchName("flux_gate")

if mon == null then
	error("No valid monitor was found")
end

if inputfluxgate == null then
	error("No valid flux gate was found")
end

monX, monY = mon.getSize()

-----------
function init()
	inflowFluxGate = peripheral.wrap("bottom")
	if inflowFluxGate ~= nil then
		inflowFluxGate.open(1)
		print("|# Reactor State:  ["..reactorState.."]")
		
		draw_text(2, 2, "Reactor State", colors.white, colors.black)

		if reactorState == "online" then
			draw_text_right(1, 2, string.upper(reactorState), colors.lime, colors.black)
		elseif reactorState == "offline" then
			draw_text_right(1, 2, string.upper(reactorState), colors.gray, colors.black)
		elseif reactorState == "charging" then
			draw_text_right(1, 2, string.upper(reactorState), colors.orange, colors.black)
		else
			draw_text_right(1, 2, string.upper(reactorState), colors.red, colors.black)
		end

		local inputFlow = inflowFluxGate.callRemote(inputfluxgate,"getSignalLowFlow")
		
		print("|# Input fluxgate:      "..inputFlow)
		draw_text(2, 7, "Input Gate", colors.white, colors.black)
		draw_text_right(1, 7, format_int(inputFlow) .. " rf/t", colors.white, colors.black)
	end


	
	maxFieldCharge = totalFuel * 96.45061728395062 * 100
	maxEnergySaturation = (totalFuel * 96.45061728395062 * 1000)

	-- Capacitor on top
	CapacitorMax = CapacitorVal*CapacitorNum 	-- Power holding capacity of the capacitors



	capacitor_1 = peripheral.wrap("top")
	tbl = peripheral.call("back","getReactorInfo")
	FluxGateStatus = peripheral.call("right", "getSignalLowFlow")

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
		if k == "status" then
			reactorState = v
	    end
	end
	energieladung = energysat * 0.0000001
	fieldstr = feldst * 0.000001
	kRFpt = RFpt / 1000
	fuel = RestKraftstoff / 10368
	FuelConv = fuel * 100
	--------------------------------------------------
	print("|# Reactor temperature: "..math.ceil(temperatur))
	print("|# Energy saturation: "..math.ceil(energieladung).."%")
	print("|# Field strength:    "..math.ceil(fieldstr).."%")
	print("|# Refuel level:      "..math.ceil(FuelConv).."%")
	--print("|# ConvesionRate:     "..math.ceil(Kraftstoffverbrauch))
	print("|# Energyproduction:    "..math.ceil(kRFpt).." kRF/t")

	-- 2 = reactor state, 4 = production, 6 = temperature, 7 = input gate, 8 = output gate
	-- 10/11 = saturation
	-- 13/14 = field strength
	-- 16/17 = refuel level

	local energySatPerc = math.ceil(energieladung)
	local fieldStrPerc = math.ceil(fieldstr)
	local fuelLevel = math.ceil(FuelConv)
	local energyProd = math.ceil(kRFpt)

	draw_text(2, 4, "Production", colors.white, colors.black)
	draw_text_right(1, 4, format_int(energyProd) .. "kRF/t", colors.blue, colors.black)

	draw_text(2, 6, "Temperature", colors.white, colors.black)
	draw_text_right(1, 6, format_int(math.ceil(temperatur)) .. "C", colors.white, colors.black)

	draw_text(2, 10, "Energy Saturation", colors.white, colors.black)
	draw_text_right(1, 10, format_int(energySatPerc) .. "%", colors.white, colors.black)

	if energySatPerc > 70 then 
		progress_bar(2, 11, monX-2, energySatPerc, 100, colors.red, colors.gray)
	elseif energySatPerc < 70 and energySatPerc > 40 then 
		progress_bar(2, 11, monX-2, energySatPerc, 100, colors.orange, colors.gray)
	else 
		progress_bar(2, 11, monX-2, energySatPerc, 100, colors.green, colors.gray)
	end

	draw_text(2, 13, "Field Strength", colors.white, colors.black)
	draw_text_right(1, 13, format_int(fieldStrPerc) .. "%", colors.white, colors.black)

	if fieldStrPerc > 70 then 
		progress_bar(2, 14, monX-2, fieldStrPerc, 100, colors.red, colors.gray)
	elseif fieldStrPerc < 70 and fieldStrPerc > 40 then 
		progress_bar(2, 14, monX-2, fieldStrPerc, 100, colors.green, colors.gray)
	else 
		progress_bar(2, 14, monX-2, fieldStrPerc, 100, colors.orange, colors.gray)
	end

	draw_text(2, 16, "Refuel Level", colors.white, colors.black)
	draw_text_right(1, 16, format_int(fuelLevel) .. "%", colors.white, colors.black)

	if fuelLevel > 70 then 
		progress_bar(2, 17, monX-2, fuelLevel, 100, colors.red, colors.gray)
	elseif fuelLevel < 70 and fuelLevel > 40 then 
		progress_bar(2, 17, monX-2, fuelLevel, 100, colors.orange, colors.gray)
	else 
		progress_bar(2, 17, monX-2, fuelLevel, 100, colors.green, colors.gray)
	end




	-------------------------------------------------
end

function doFIRavg()
	local val=0
	for i=0, FIRLen-1 do
		val = val+FIRavg[i]
	end
	return val/FIRLen
end

function calcFieldDrain()
		if FIRi >= FIRLen then
			FIRi = 0
		else
			FIRi = FIRi+1
		end
		
		FIRavg[FIRi]=feldst
		local avg = doFIRavg()
		--print(avg.." "..wantedField)
		local difference = math.abs(avg-wantedField)
		
		--local valuedelta = math.pow(avg-wantedField, 2)/(300*avg)
		
		local height = 40000
		
		local Offset = 78540000
		local valuedelta = math.sin((avg-(wantedField+Offset))/(50000000))*height+height
		if(valuedelta < 0) then 
			valuedelta = 1
			--print("Neg at: "..avg)
		end
		
		--print("TTT: "..valuedelta)
		
		
		if (avg > wantedField) then
			if FIRVal-valuedelta < 10000 then
				FIRVal = 10000
			else
				FIRVal = FIRVal-valuedelta
			end
			if(FIRChg) then
				FIRChg = false
				FIRHigh = FIRVal
				
				-- Predict middle
				--FIRVal = (FIRHigh+FIRLow)/2
			end
		else 
			if (avg < wantedField) then
				if FIRVal+valuedelta > (900000-valuedelta) then
					FIRVal = 900000
					--FIRVal = 200000
					-- dont know what im doing but this stops shutdowns (-asidjazz)
				else
					FIRVal = FIRVal+valuedelta
				end
			end
			if(not FIRChg) then
				FIRChg = true
				FIRLow = FIRVal
				
				-- Predict middle
				--FIRVal = (FIRHigh+FIRLow)/2
			end
			
		end
		
		--print("Low: "..FIRLow)
		--print("High: "..FIRHigh)
		--print("Delta: "..math.abs(FIRHigh-FIRLow))

		if (FIRVal > 222000) and (reactorState == "online") then
			FIRVal = 222000
		end
		
		fluxval = FIRVal
		print("|#== FluxInputRate:     "..math.floor(fluxval).." kRF/t")		
end
	

-- Set the shield input level
function setLowLevel()
	if inflowFluxGate ~= nil then
		calcFieldDrain()
		inflowFluxGate.callRemote(inputfluxgate,"setSignalLowFlow",fluxval)
	end
end


function setLevel(level)
	print("|#== FluxGate set to:   "..math.ceil(FluxGateStatus).." kRF/t")
	peripheral.call("right", "setSignalLowFlow", FluxGateStatus)
	draw_text(2, 8, "Output Gate", colors.white, colors.black)
	draw_text_right(1, 8, format_int(math.ceil(FluxGateStatus)) .. " rf/t", colors.white, colors.black)
	
end


function limitLevel(FluxStatus)
	-- Set the maximum value
	if FluxGateStatus >= (WantedRFt*0.9-FluxGateStatus*0.3) then 
		FluxGateStatus = (WantedRFt*0.9-FluxGateStatus*0.3)
	end
end

-- Start the reactor
function startReactor()
	peripheral.call("back", "chargeReactor")
		print("|#==        Reactor charge !!        ==#|")
	if feldst >= 50000000 then
		peripheral.call("back", "activateReactor")
		print("|#==        Reactor activate !       ==#|")
	end
end

function testFieldStrength()
	if feldst <= 15000000 then
		peripheral.call("back", "stopReactor")
		print("|#==     Reactor Emergency stop !    ==#|")
		print("|#==     Field strength too low !     ==#|")
	else
		if feldst >= 20000000 then
			peripheral.call("back", "activateReactor")
			--print("|#==         Reactor active !        ==#|")
		end
	end
end

function calcNewValueChange()
	local chg = ValueChange
	local saturationchg = (energieladung/100)-0.3
	local reactorTempx = 1-((temperatur-3000)/10000+0.2) -- reactor temperature accounting for +3000 heat
	
	print("|# Temperature Factor:  "..reactorTempx)
	print("|# Saturation Factor:   "..saturationchg)
	chg = chg*math.min(saturationchg,reactorTempx) -- Account for saturation and Temperature
	
	return chg
end


function testCapacitor()
	-- Slow down the reactor to 1/8 of the requested power level
	-- This is so that a slow-start is not required for later use
	if capacitor_1 ~= nil then
		local energyStored = capacitor_1.getEnergyStored()
		if energyStored >= CapacitorMax then
			FluxGateStatus = WantedRFt/8
			setLevel(FluxGateStatus)
		end
	end
end


-- Run this program!
function doRun()
	if temperatur > 7777 then -- Temperatur check wenn mehr als 7777 Grad
		FluxGateStatus = 200000
	end


	-- Set the energy level to be produced
	if energysat > MinEnergySat then 
		limitLevel(FluxGateStatus)
		FluxGateStatus = RFpt + calcNewValueChange() -- anpassen der Flux-Gate_Variablen an den neuen Wert
		setLevel(FluxGateStatus)
	end

	-- Energy Saturation settings
	--if energysat < MinEnergySat then
	--	if FluxGateStatus <= 10000 then -- Minimalwert abregelung auf 0
	--		FluxGateStatus = 10000
	--	end
	--	FluxGateStatus = FluxGateStatus - ValueChange -- anpassen der Flux-Gate_Variablen an den neuen Wert
	--  setLevel(FluxGateStatus)
	--end



	-- Stop the reactor when 90% of the fuel is gone
	if FuelConv >= 90 then 
		peripheral.call("back", "stopReactor")

		print("|#==      Reactor refuel stop !      ==#|")
		print("|#============#| S D R C |#============#|")
		sleep(300)
	end

	if temperatur <= 2000 then -- Starttest zum aufladen des Reaktors
		startReactor()
	else
		testFieldStrength()
	end

	setLowLevel(level)
	testCapacitor()
end

while true do
	clear()
    init()
    doRun()
	sleep(0.1)
end