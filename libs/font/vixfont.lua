local band, lshift, bor, floor, ceil, rshift = bit32.band, bit32.lshift, bit32.bor, math.floor, math.ceil, bit32.rshift
local vixfont = {}
local fnt = {}
--[[
	struct vixfont_hdr {
		char magic[4];
		uint8_t file_version;
		uint8_t widths; // Space width, horizontal and vertical padding.
		uint8_t namelen;
		uint8_t char_count;
	}
]]
local hdr = "<c4BBBB"

function fnt:width(str)
	local width = 0
	for c in str:gmatch(".") do
		if c == " " then
			width = width + self.space_width
		elseif not self.data[c] then
			width = width + #self.data["?"]
		else
			width = width + #self.data[c]
		end
	end
	width = width + (math.max(#str-1, 0)*self.char_padding)
	return width
end

function fnt:max_width(str, width)

end

function fnt:line_height()
	return 8+self.line_padding
end

function fnt:allocate_buffer(str)
	local width = self:width(str)
	return PixelData.new(width, 8, color.clear)
end

function fnt:render(buffer, color, str)
	local xoff = 0
	for c in str:gmatch(".") do
		if c == " " then
			xoff = xoff + self.space_width
		else
			if not self.data[c] and self.data[c:upper()] then c = c:upper()
			elseif not self.data[c] then c = "?" end
			local dat = self.data[c]
			for i=1, #dat do
				local byte = dat:byte(i)
				for j=0, 7 do
					if band(byte, lshift(1, j)) > 0 then
						buffer:SetPixel(xoff+i, 8-j, color)
					end
				end
			end
			xoff = xoff + #dat
		end
		xoff = xoff + self.char_padding
	end
end

function vixfont.load(data)
	local magic, ver, widths, namelen, char_count, offset = hdr:unpack(data)
	if magic ~= "vixf" or ver ~= 1 then error("not a version 1 vixfont!") end
	local space_width = rshift(widths, 4)
	local char_padding = band(rshift(widths, 2), 3)
	local line_padding = band(widths, 3)
	local name = data:sub(offset, offset+namelen-1)
	offset = offset+namelen
	local chars = data:sub(offset, offset+char_count-1)
	offset = offset+char_count
	local width_length = ceil(char_count/2)
	local char_widths = data:sub(offset, offset+width_length-1)
	offset = offset+width_length
	local cdata = {}
	for i=1, #chars do
		local byte, shift = ceil(i/2), (1-(i % 2)) * 4
		local width = band(rshift(char_widths:byte(byte), shift), 0xF)
		cdata[chars:sub(i,i)] = data:sub(offset, offset+width-1)
		offset = offset+width
		print(chars:sub(i,i), "width", width)
	end
	local vix = setmetatable({
		name = name,
		chars = chars,
		data = cdata,
		line_padding = line_padding,
		space_width = space_width,
		char_padding = char_padding
	}, {__index=fnt})
	return vix
end

return vixfont