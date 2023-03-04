local lfs = require("lfs")
local dir = arg[1]
local fontinfo = loadfile(arg[1].."/fontinfo.lua")()
fontinfo.minwidth = fontinfo.minwidth or 1

local function makestrips(imgdat)
	local bytes = ""
	for x=0, 7 do
		local byte = 0
		for y=0, 7 do
			byte = byte | (((imgdat:byte(x+((y)*8)+1) == 255) and 1 or 0) << y)
		end
		bytes = bytes .. string.char(byte)
	end
	bytes = bytes:gsub("\0+$", "")
	if #bytes < fontinfo.minwidth then
		bytes = bytes .. string.rep("\0", fontinfo.minwidth-#bytes)
	end
	return bytes
end

local fontdat = {}

for ent in lfs.dir(arg[1]) do
	if (ent:sub(1, #fontinfo.name) == fontinfo.name) then
		local index = ent:match("(%d+)%.tga$")
		local f = io.open(arg[1].."/"..ent, "rb")
		f:seek("set", 18)
		local dat = ""
		local lines = {}
		for i=1, 8 do
			local d = f:read(8)
			lines[#lines+1] = d:gsub("\255", "#"):gsub("\0", " ")
			dat = dat .. d
		end
		for i=8, 1, -1 do
			print(lines[i])
		end
		f:close()
		local c = tonumber(index, 10)
		fontdat[c] = makestrips(dat)
		print(fontinfo.chars:sub(c, c), "width", #fontdat[c])
	end
end
local f = io.open(fontinfo.name..".vixfont", "wb")
local header = "<c4BBBB"
f:write(header:pack("vixf", 1, (fontinfo.space << 4) |
	                           (fontinfo.pad << 2) |
	                            fontinfo.linepad,
                                #fontinfo.name, #fontinfo.chars))
f:write(fontinfo.name, fontinfo.chars)
local curinfo = 0
local dat = ""
for i=1, #fontinfo.chars do
	curinfo = curinfo >> 4
	curinfo = curinfo | (#fontdat[i] << 4)
	if curinfo & 0xF > 0 then
		dat = dat .. string.char(curinfo)
		curinfo = 0
	end
end
if (curinfo ~= 0) then
	dat = dat .. string.char(curinfo)
end
f:write(dat)
f:write(table.concat(fontdat, "", 1, #fontinfo.chars))
f:close()