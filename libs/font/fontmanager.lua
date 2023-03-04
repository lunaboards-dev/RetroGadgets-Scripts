-- includes
local hexfont = require("hexfont.lua")
local vixfont = require("vixfont.lua")
local stringstream = require("stringstream.lua")
local cpio = require("cpio.lua")
-- library starts here
local fontmgr = {}

-- TODO

return function(libraryname)
	local arc = cpio.read(stringstream(require(libraryname)[1]))
	return setmetatable({arc=arc}, {__index=fontmgr})
end