-- drmon installation script
--
--

local lib = "https://raw.githubusercontent.com/acidjazz/drmon/master/lib/f.lua"
local startup = "https://raw.githubusercontent.com/acidjazz/drmon/master/drmon.lua"
local libFile
local startupFile

http.get(lib)
libFile = http.readAll()

http.get(startup)
startupFile = http.readAll()

local file = fs.open("f", "w")
file.write(libFile)

local file = fs.open("startup", "w")
file.write(startupFile)
