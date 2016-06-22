
-- modifiable variables
local reactorSide = "back"
local fluxgateSide = "right"

local targetStrength = 50

-- please leave untouched from here own
require "lib/funcs.lua"

local mon, monX, monY
local reactor
local fluxgate
local inputfluxgate

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


