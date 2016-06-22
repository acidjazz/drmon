
-- modifiable variables
local reactorSide = "back"
local fluxgateSide = "right"

local targetStrength = 50
local maxTemperature = 8000

local activateOnCharged = true

-- please leave untouched from here on
os.loadAPI("lib/f")

-- monitor 
local mon, monitor, monX, monY

-- peripherals
local reactor
local fluxgate
local inputfluxgate

-- reactor information
local ri

-- last performed action
local action = "None since reboot"
local emergencyCharge = false
local emergencyTemp = false


monitor = f.periphSearch("monitor")
inputfluxgate = f.periphSearch("flux_gate")
fluxgate = peripheral.wrap(fluxgateSide)
reactor = peripheral.wrap(reactorSide)

if monitor == null then
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

monX, monY = monitor.getSize()
mon = {}
mon.monitor,mon.X, mon.Y = monitor, monX, monY

while true do 

	f.clear(mon)

	ri = reactor.getReactorInfo()

	-- print out all the infos from .getReactorInfo() to term

	for k, v in pairs (ri) do
		print(k.. ": ".. v)
	end
	print("Output Gate: ", fluxgate.getSignalLowFlow())
	print("Input Gate: ", inputfluxgate.getSignalLowFlow())

	-- monitor output

	local statusColor
	statusColor = colors.red

	if ri.status == "online" or ri.status == "charged" then
		statusColor = colors.green
	elseif ri.status == "offline" then
		statusColor = colors.gray
	elseif ri.status == "charging" then
		statusColor = colors.orange
	end

	f.draw_text_lr(mon, 2, 2, 1, "Reactor Status", string.upper(ri.status), colors.white, statusColor, colors.black)

	f.draw_text_lr(mon, 2, 4, 1, "Generation", f.format_int(ri.generationRate) .. " rf/t", colors.white, colors.lime, colors.black)
	f.draw_text_lr(mon, 2, 6, 1, "Temperature", f.format_int(ri.temperature) .. "C", colors.white, colors.white, colors.black)

	f.draw_text_lr(mon, 2, 8, 1, "Output Gate", f.format_int(fluxgate.getSignalLowFlow()) .. " rf/t", colors.white, colors.blue, colors.black)
	f.draw_text_lr(mon, 2, 9, 1, "Input Gate", f.format_int(inputfluxgate.getSignalLowFlow()) .. " rf/t", colors.white, colors.blue, colors.black)

	local satPercent
	satPercent = math.ceil(ri.energySaturation * 0.0000001 * 100)*.01

	f.draw_text_lr(mon, 2, 11, 1, "Energy Saturation", satPercent .. "%", colors.white, colors.white, colors.black)
	f.progress_bar(mon, 2, 12, mon.X-2, satPercent, 100, colors.blue, colors.gray)

	local fieldPercent, fieldColor
	fieldPercent = math.ceil(ri.fieldStrength * 0.000001 * 100)*.01

	fieldColor = colors.red
	if fieldPercent > 70 then fieldColor = colors.red end
	if fieldPercent < 70 and fieldPercent > 30 then fieldColor = colors.orange end

	f.draw_text_lr(mon, 2, 14, 1, "Field Strength", fieldPercent .. "%", colors.white, fieldColor, colors.black)
	f.progress_bar(mon, 2, 15, mon.X-2, fieldPercent, 100, fieldColor, colors.gray)

	local fuelPercent, fuelColor

	fuelPercent = 100 - math.ceil(ri.fuelConversion / ri.maxFuelConversion * 100)*.01

	fuelColor = colors.red

	if fuelPercent > 70 then fuelColor = colors.green end
	if fuelPercent < 70 and fuelPercent > 30 then fuelColor = colors.orange end

	f.draw_text_lr(mon, 2, 17, 1, "Fuel ", fuelPercent .. "%", colors.white, fuelColor, colors.black)
	f.progress_bar(mon, 2, 18, mon.X-2, fuelPercent, 100, fuelColor, colors.gray)

	f.draw_text_lr(mon, 2, 19, 1, "Action ", action, colors.gray, colors.gray, colors.black)

	-- actual reactor interaction
	--
	if emergencyCharge == true then
		reactor.chargeReactor()
	end
	
	-- are we charging? open the floodgates
	if ri.status == "charging" then
		inputfluxgate.setSignalLowFlow(900000)
		emergencyCharge = false
	end

	-- are we stopping from a shutdown and our temp is better? activate
	if emergencyTemp == true and ri.status == "stopping" and ri.temperature < 3000 then
		reactor.startReactor()
		emergencyTemp = false
	end

	-- are we charged? lets activate
	if ri.status == "charged" and activateOnCharged == true then
		reactor.activateReactor()
	end

	-- are we on? regulate the input fludgate to our target field strength
	if ri.status == "online" then
		fluxval = ri.fieldDrainRate / (1 - (targetStrength/100) )
		print("Target Gate: ".. fluxval)
		inputfluxgate.setSignalLowFlow(fluxval)
	end

	-- safeguards
	--
	
	-- out of fuel, kill it
	if fuelPercent <= 10 then
		reactor.stopReactor()
		action = "Fuel below 10%, refuel"
	end

	-- field strength is too dangerous, kill and it try and charge it before it blows
	if fieldPercent <= 15 and ri.status == "online" then
		action = "Field Str < 15%"
		reactor.stopReactor()
		reactor.chargeReactor()
		emergencyCharge = true
	end

	if ri.temperature > maxTemperature then
		reactor.stopReactor()
		action = "Temp > " .. maxTemperature
    emergencyTemp = true
	end

	sleep(0.1)
end

