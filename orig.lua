
-----------
-- The Field input value should be 30% of the power provied
-- The inflow flux gate can also be modem networked together with the computer
--
-----------

-- ReS - Reactor Stabilizer
-- "+" - Cryo-stabilized fluxduct
-- CPU - Computer
-- FxG - Flux Gate
-- ___ - Air

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

local mon, monX, monY
local reactor
local fluxgate
local inputfluxgate

local reactorSide = "back"
local fluxgateSide = "right"

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
inputfluxgate = periphSearch('flux_gate')
fluxgate = peripheral.wrap(fluxgateSide)
reactor = peripheral.wrap(reactorSide)

if mon == null then
	error("No valid monitor was found")
end

if fluxgate == null then
	error("No valid fluxgate was found")
end

if reactor == null then
	error("No valid reactor was found")
end

if inputfluxgate == null then
	error("No valid flux gate was found")
end

monX, monY = mon.getSize()

-----------
function init()

	tbl = reactor.getReactorInfo()
	FluxGateStatus = fluxgate.getSignalLowFlow()

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
		if k == "fieldDrainRate" then
			fieldDrainRate = v
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
	
	print("|# Input fluxgate:      "..inputfluxgate.getSignalLowFlow())

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
	
	draw_text(2, 7, "Input Gate", colors.white, colors.black)
	draw_text_right(1, 7, format_int(inputfluxgate.getSignalLowFlow()) .. " rf/t", colors.white, colors.black)	
	
	maxFieldCharge = totalFuel * 96.45061728395062 * 100
	maxEnergySaturation = (totalFuel * 96.45061728395062 * 1000)


	energieladung = energysat * 0.0000001
	fieldstr = feldst * 0.000001
	kRFpt = RFpt / 1000
	fuel = RestKraftstoff / 10368
	FuelConv = fuel * 100
	--------------------------------------------------
	print("|# Reactor temperature: "..math.ceil(temperatur))
	print("|# Energy saturation %: "..math.ceil(energieladung))
	print("|# Field strength %:    "..math.ceil(fieldstr))
	print("|# Refuel level %:      "..math.ceil(FuelConv))
	--print("|# ConvesionRate:     "..math.ceil(Kraftstoffverbrauch))
	print("|# Energyproduction:    "..math.ceil(kRFpt).." kRF/t")
	-------------------------------------------------

	local energySatPerc = math.ceil(energieladung*100)*.01
	local fieldStrPerc = math.ceil(fieldstr*100)*.01
	local fuelLevel = math.ceil(FuelConv*100)*.01
	local energyProd = math.ceil(kRFpt)

	draw_text(2, 4, "Production", colors.white, colors.black)
	draw_text_right(1, 4, format_int(RFpt) .. " rf/t", colors.blue, colors.black)

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

end

-- Set the shield input level
function setLowLevel()
	
	if (reactorState == "charging") then 
		fluxval = 900000
	else
		fluxval = fieldDrainRate / (1 - (targetStrength/100))
	end
	
	inputfluxgate.setSignalLowFlow(fluxval)

	print("|#== Flux1nputRate:     "..math.floor(fluxval).." kRF/t")

end

function setLevel(level)
	print("|#== FluxGate set to:   "..math.ceil(FluxGateStatus).." kRF/t")
	fluxgate.setSignalLowFlow(FluxGateStatus)

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
	reactor.chargeReactor()
	print("|#==        Reactor charge !!        ==#|")
	if feldst >= 50000000 then
		reactor.activateReactor()
		print("|#==        Reactor activate !       ==#|")
	end
end


function testFieldStrength()
	if feldst <= 15000000 then
		reactor.stopReactor()
		print("|#==     Reactor Emergency stop !    ==#|")
		print("|#==     Field strength too low !     ==#|")
	else
		if feldst >= 20000000 then
			reactor.activateReactor()
			--print("|#==         Reactor active !        ==#|")
		end
	end
end


function calcNewValueChange()
	local chg = ValueChange
	local saturationchg = (energieladung/100)-0.25 -- was 0.3
	local reactorTempx = 1-((temperatur-3000)/10000+0.2) -- reactor temperature accounting for +3000 heat
	
	print("|# Temperature Factor:  "..reactorTempx)
	print("|# Saturation Factor:   "..saturationchg)
	chg = chg*math.min(saturationchg,reactorTempx) -- Account for saturation and Temperature
	
	draw_text(2, 19, math.ceil(saturationchg*100)*.01, colors.white, colors.black)
	draw_text_right(1, 19, math.ceil(reactorTempx*100)*.01, colors.white, colors.black)
	return chg
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
		reactor.stopReactor()

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
end

while true do
	clear()
	init()
	doRun()
	sleep(0.06)
end
