-- drmon installation script
--
--

local hastebin = "http://www.hastebin.com/raw/"

local libURL = "coxibesone.lua"
local startupURL = "guxuhuvuju.lua"
local lib, startup
local libFile, startupFile

fs.makeDir("lib")

lib = http.get(hastebin .. libURL)
libFile = lib.readAll()

local file1 = fs.open("lib/f", "w")
file1.write(libFile)
file1.close()

startup = http.get(hastebin .. startupURL)
startupFile = startup.readAll()


local file2 = fs.open("startup", "w")
file2.write(startupFile)
file2.close()

