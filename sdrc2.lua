-- Computer set up
reactorSide  = "bottom"
fluxgateSide = "back"

tempIsOkFlag = false

monitorChanel = 0

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
  RTab = peripheral.call(reactorSide, "getReactorInfo")

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
  fluxgateLowFlow = peripheral.call(fluxgateSide, "getSignalLowFlow")



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
  if (status == "offline") 
     and (fuelConversion <= criticalValueFuel) 
  then
    --print("charge reactor")
    peripheral.call(reactorSide, "chargeReactor")
    peripheral.call(fluxgateSide, "setSignalLowFlow", reactorStartupFluxgateFlow)
  end

  if (status == "charged") 
     and (fuelConversion <= criticalValueFuel) 
  then
    --print("activate reactor")
    peripheral.call(reactorSide, "activateReactor")
    peripheral.call(fluxgateSide, "setSignalLowFlow", reactorStartupFluxgateFlow)
  end

  if (status == "stopping")
     and (temperature    <= criticalValueTemp_LowerLimit)
     and (fieldStrength  >= criticalValueField) 
     and (fuelConversion <= criticalValueFuel) 
  then
    --print("charge stopping reactor")
    peripheral.call(reactorSide, "chargeReactor")
    peripheral.call(fluxgateSide, "setSignalLowFlow", reactorStartupFluxgateFlow)
  end

  if (status == "online") 
     and (fluxgateLowFlow < reactorStartupFluxgateFlow) 
  then
     peripheral.call(fluxgateSide, "setSignalLowFlow", reactorStartupFluxgateFlow)
  end



-- Emergency shutdown  
  if (status == "online") 
     and (fieldStrength <= criticalValueField)
  then
    --print("field shut down")
    peripheral.call(fluxgateSide, "setSignalLowFlow", 0)
    peripheral.call(reactorSide, "stopReactor")
    tempIsOkFlag = false
  end

  if (status == "online") 
     and (fuelConversion >= criticalValueFuel) 
 then 
    --print("fuel shut down")
    peripheral.call(fluxgateSide, "setSignalLowFlow", 0)
    peripheral.call(reactorSide, "stopReactor")
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
    peripheral.call(fluxgateSide, "setSignalLowFlow", math.ceil(generationRate) * 1000)
           
  elseif (status == "online")
         and (temperature > criticalValueTemp_UpperLimit)
  then
    --print("decrease flux flow")
    tempIsOkFlag = false
    fluxgateLowFlow = fluxgateLowFlow - RFDecreaseStep
    peripheral.call(fluxgateSide, "setSignalLowFlow", fluxgateLowFlow)

  elseif (status == "online")
         and (temperature < criticalValueTemp_LowerLimit)
  then
    --print("increase flux flow")
    tempIsOkFlag = false
    fluxgateLowFlow = fluxgateLowFlow + RFIncreaseStep
    peripheral.call(fluxgateSide, "setSignalLowFlow", fluxgateLowFlow)
end
  
  
  
-- computer display
  term.clear()
  term.setCursorPos(1,1)
  
  
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
  
  sleep(sleepValue)
end