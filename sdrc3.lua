
-- feel free to change this based on how things are touching your computer
local reactorSide = "back"
local fluxgateSide = "right"

local mon, monX, monY
local reactor
local fluxgate
local inputfluxgate

mon = periphSearch("monitor")
fluxgate = peripheral.wrap(fluxgateSide)
reactor = peripheral.wrap(reactorSide)
inputfluxgate = periphSearch("flux_gate")

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
print ("monitor and input fluxgate connected")

----------GENERAL---------------
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

----------FORMATTING-------------

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
 
--create progress bar, draws two overlapping lines, background line of bg_color
--main line of bar_color as a percentage of minVal/maxVal
function progress_bar(x, y, length, minVal, maxVal, bar_color, bg_color)
  draw_line(x, y, length, bg_color) --backgoround bar
  local barSize = math.floor((minVal/maxVal) * length)
  draw_line(x, y, barSize, bar_color) --progress so far
end

tempIsOkFlag = false


RFIncreaseStep = 500
RFDecreaseStep = 500

criticalValueField = 30
criticalValueFuel  = 90
criticalValueTemp_UpperLimit = 9505
criticalValueTemp_LowerLimit = 9495

highestGenerationRate = 0

reactorStartupFluxgateFlow0 = 300000
reactorStartupFluxgateFlow = reactorStartupFluxgateFlow0

sleepValue = 0.01

while true do 
-- Reactor info
  RTab = reactor.getReactorInfo()

  for k, v in pairs (RTab) do
    if k == "status" then
      status = v
    end

    if k == "temperature" then
      temperature = v
    end
  
    if k == "fieldStrength" then
      fieldStrength = v
    end

    if k == "fieldDrainRate" then
      fieldDrainRate = v
    end

    if k == "generationRate" then
      generationRate = v
    end

    if k == "fuelConversionRateN" then
      fuelConversionRate = v
    end

    if k == "energySaturation" then
      energySaturation = v
    end
  
    if k == "maxFuelConversion" then
      maxFuelConversion = v
    end

    if k == "fuelConversion" then
      fuelConversion = v
    end

    if k == "maxFieldStrength" then
      maxFieldStrength = v
    end

    if k == "maxEnergySaturation" then
      maxEnergySaturation= v
    end
  end

  energySaturation = energySaturation / maxEnergySaturation * 100
  fieldStrength    = fieldStrength    / maxFieldStrength * 100
  fieldDrainRate   = fieldDrainRate   / 1000
  generationRate   = generationRate   / 1000
  fuelConversion   = fuelConversion   / maxFuelConversion * 100


-- Fluxgate info
  fluxgateLowFlow = fluxgate.getSignalLowFlow()



--Reactor startup fluxgate Flow
  if (status == "online")
     and (generationRate > highestGenerationRate)
  then 
     highestGenerationRate = generationRate
  end

  if (status == "online")
     and (highestGenerationRate * 1000 > reactorStartupFluxgateFlow)
  then
     local temp = math.ceil(3/4 * highestGenerationRate * 1000 / 100)* 100

     if temp > reactorStartupFluxgateFlow0 then
       reactorStartupFluxgateFlow = temp
     else
       reactorStartupFluxgateFlow = reactorStartupFluxgateFlow0
     end
  end

-- Reactor start up
  if (status == "offline") and (fuelConversion <= criticalValueFuel) then
    reactor.chargeReactor()
    fluxgate.setSignalLowFlow(reactorStartupFluxgateFlow)
  end

  if (status == "charged") and (fuelConversion <= criticalValueFuel) then
    reactor.activateReactor()
    fluxgate.setSignalLowFlow(reactorStartupFluxgateFlow)
  end

  if (status == "stopping")
     and (temperature    <= criticalValueTemp_LowerLimit)
     and (fieldStrength  >= criticalValueField) 
     and (fuelConversion <= criticalValueFuel) 
  then
    reactor.chargeReactor()
    fluxgate.setSignalLowFlow(reactorStartupFluxgateFlow)
  end

  if (status == "online") 
     and (fluxgateLowFlow < reactorStartupFluxgateFlow) 
  then
     fluxgate.setSignalLowFlow(reactorStartupFluxgateFlow)
  end

-- Emergency shutdown  
  if (status == "online") 
     and (fieldStrength <= criticalValueField)
  then    
    fluxgate.setSignalLowFlow(0)
    reactor.stopReactor()
    tempIsOkFlag = false
  end

  if (status == "online") 
     and (fuelConversion >= criticalValueFuel) 
  then 
    --print("fuel shut down")
    fluxgate.setSignalLowFlow(0)
    reactor.stopReactor()
    tempIsOkFlag = false

    -- when reactor shutdown bc of fuel
    -- then its startup flux flow should be reseted too
    reactorStartupFluxgateFlow = reactorStartupFluxgateFlow0
  end


-- RF production
  if (status == "online") 
     and (temperature <= criticalValueTemp_UpperLimit) 
     and (temperature >= criticalValueTemp_LowerLimit) 
  then
    --print("temp is ok")
    tempIsOkFlag = true
    fluxgate.setSignalLowFlow(math.ceil(generationRate) * 1000)
           
  elseif (status == "online")
         and (temperature > criticalValueTemp_UpperLimit)
  then
    --print("decrease flux flow")
    tempIsOkFlag = false
    fluxgateLowFlow = fluxgateLowFlow - RFDecreaseStep
    fluxgate.setSignalLowFlow(fluxgateLowFlow)

  elseif (status == "online")
         and (temperature < criticalValueTemp_LowerLimit)
  then
    --print("increase flux flow")
    tempIsOkFlag = false
    fluxgateLowFlow = fluxgateLowFlow + RFIncreaseStep
    fluxgate.setSignalLowFlow(fluxgateLowFlow)
end
    
-- computer display
  clear()
  
  print(" Reactor status: "..status)

  if (tempIsOkFlag) then
    print(" Temperature        = "..(math.ceil(temperature)).." K")
    print(" Temperature is OK!")
  else 
    print(" Temperature        = "..(math.ceil(temperature)).." K")
  end

  print(" Field strength     = "..(math.ceil(fieldStrength*100)/100).." %")
  print(" Refuel level       = "..(math.ceil(fuelConversion*100)/100).." %")
  print(" Energy saturation  = "..(math.ceil(energySaturation*100)/100).." %")

  print(" ")
  print(" Energy production  = "..(math.ceil(generationRate)).." kRF/t")
  --print(" Highest production = "..(math.ceil(highestGenerationRate)).." kRF/t")
  --print("                    = "..(math.ceil(reactorStartupFluxgateFlow)))
  print(" Field drain rate   = "..(math.ceil(fieldDrainRate)).." kRF/t")
  print(" Fluxgate Status    = "..(math.ceil(fluxgateLowFlow/1000)).." kRF/t")
  
	draw_text(2, 2, "Reactor State", colors.white, colors.black)

	if reactorState == "online" then
		draw_text_right(1, 2, string.upper(status), colors.lime, colors.black)
	elseif reactorState == "offline" then
		draw_text_right(1, 2, string.upper(status), colors.gray, colors.black)
	elseif reactorState == "charging" then
		draw_text_right(1, 2, string.upper(status), colors.blue, colors.black)
	else
		draw_text_right(1, 2, string.upper(status), colors.red, colors.black)
	end

	sleep(sleepValue)

end