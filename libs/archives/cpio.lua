--local comp = component
local band, bor, lshift, rshift = bit32.band, bit32.bor, bit32.lshift, bit32.rshift
local cpio = {}
local arc = {}

local function read(h, n)
	local d = h:read(n)
	return d
end

local function readint(h, amt, rev, n)
	--[[local tmp = 0
	for i=(rev and amt) or 1, (rev and 1) or amt, (rev and -1) or 1 do
		tmp = tmp | (read(f, h, 1):byte() << ((i-1)*8))
	end]]
	local d = h:read(amt)
	local tmp = string.unpack((rev and "<" or ">").."I"..amt, d)
	return tmp
end

local function bswap(i, size)
	return string.unpack("<I"..size, (string.pack(">I"..size, i)))
end

function cpio.read(stream)
	local h = stream
	local tbl = {}
	while true do
		local dent = {}
		dent.magic = readint(h, 2)
		local rev = false
		if (dent.magic ~= tonumber("070707", 8)) then rev = true end
		dent.dev = readint(h, 2, rev, "dev")
		dent.ino = readint(h, 2, rev, "ino")
		dent.mode = readint(h, 2, rev, "mode")
		dent.uid = readint(h, 2, rev, "uid")
		dent.gid = readint(h, 2, rev, "gid")
		dent.nlink = readint(h, 2, rev, "nlink")
		dent.rdev = readint(h, 2, rev, "rdev")
		dent.mtime = bor(lshift(readint(h, 2, rev, "mtime_hi"), 16), readint(h, 2, rev, "mtime_lo"))
		dent.namesize = readint(h, 2, rev, "namesize")
		dent.filesize = bor(lshift(readint(h, 2, rev, "filesize_hi"), 16), readint(h, 2, rev, "filesize_lo"))
		local name = read(h, dent.namesize):sub(1, dent.namesize-1)
		if (name == "TRAILER!!!") then break end
		dent.name = name
		if (dent.namesize % 2 ~= 0) then
			h:seek("cur", 1)
		end
		if (band(dent.mode, 0xF000) ~= 0x8000) then
			--fwrite()
		end
		dent.pos = h:seek("cur", 0)
		h:seek("cur", dent.filesize)
		if (dent.filesize % 2 ~= 0) then
			h:seek("cur", 1)
		end
		tbl[#tbl+1] = dent
	end
	return setmetatable({
		tbl = tbl,
		handle = h
	}, {__index=arc})
end

function arc:fetch(path)
	for i=1, #self.tbl do
		if (self.tbl[i].name == path and band(self.tbl[i].mode, 0xF000) == 0x8000) then
			self.handle:seek("set", self.tbl[i].pos)
			return self.handle:read(self.tbl[i].filesize)
		end
	end
	return nil, "file not found"
end

function arc:exists(path)
	for i=1, #self.tbl do
		if (self.tbl[i].name == path) then
			return true
		end
	end
	return false
end

function arc:close()
	--self.fs.close(self.handle)
	self.tbl = {}
end

function arc:list_dir(path)
	if path:sub(#path) ~= "/" then path = path .. "/" end
	local ent = {}
	for i=1, #self.tbl do
		if (self.tbl[i].name:sub(1, #path) == path and not self.tbl[i].name:find("/", #path+1, false)) then
			ent[#ent+1] = self.tbl[i].name
		end
	end
	return ent
end

function arc:files()
	local pos = 0
	return function()
		pos += 1
		return self.tbl[pos]
	end
end

function arc:stream(path)
	for i=1, #self.tbl do
		if (self.tbl[i].name == path and band(self.tbl[i].mode, 0xF000) == 0x8000) then
			local pos = 1
			local function read(amt)
				self.handle:seek("set", self.tbl[i].pos-self.seek(0)+pos-1)
				pos = pos + amt
				return self.read(amt)
			end
			local function seek(amt)
				pos = pos + amt
				return pos
			end
			local function close()end
			return read, seek, close
		end
	end
	return nil, "file not found"
end

return cpio