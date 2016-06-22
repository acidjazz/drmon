local mon
local monX
local monY

local fluxgate

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

function clear()
  mon.setBackgroundColor(colors.black)
  mon.clear()
  mon.setCursorPos(1,1)
end
-------------------FORMATTING-------------------------------
function clear()
  mon.setBackgroundColor(colors.black)
  mon.clear()
  mon.setCursorPos(1,1)
end
 
--display text on computer's terminal screen
function draw_text_term(x, y, text, text_color, bg_color)
  term.setTextColor(text_color)
  term.setBackgroundColor(bg_color)
  term.setCursorPos(x,y)
  write(text)
end
 
--display text text on monitor, "mon" peripheral
function draw_text(x, y, text, text_color, bg_color)
  mon.setBackgroundColor(bg_color)
  mon.setTextColor(text_color)
  mon.setCursorPos(x,y)
  mon.write(text)
end
 
--draw line on computer terminal
function draw_line(x, y, length, color)
    mon.setBackgroundColor(color)
    mon.setCursorPos(x,y)
    mon.write(string.rep(" ", length))
end
 
--draw line on computer terminal
function draw_line_term(x, y, length, color)
    term.setBackgroundColor(color)
    term.setCursorPos(x,y)
    term.write(string.rep(" ", length))
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
 
--same as above but on the computer terminal
function progress_bar_term(x, y, length, minVal, maxVal, bar_color, bg_color)
  draw_line_term(x, y, length, bg_color) --backgoround bar
  local barSize = math.floor((minVal/maxVal) * length)
  draw_line_term(x, y, barSize, bar_color)  --progress so far
end
 
--create button on monitor
function button(x, y, length, text, txt_color, bg_color)
  draw_line(x, y, length, bg_color)
  draw_text((x+2), y, text, txt_color, bg_color)
end


mon = periphSearch("monitor")
fluxgate = periphSearch("flux_gate")

if mon == null then
	error("No valid monitor was found")
end

if fluxgate == null then
	error("No valid flux gate was found")
end

monX, monY = mon.getSize()

progress_bar(0, 0, monX-2, 10, 50, colors.blue, colors.grey)
