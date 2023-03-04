local band, lshift, bor, floor = bit32.band, bit32.lshift, bit32.bor, math.floor
local hexfont = {}
local fnt = {}

function fnt:load_char(...)
	local chars = table.pack(...)
	table.sort(chars)
	local widths = {}
	local lastpos = 1
	for i=1, chars.n do
		local codepoint = string.format("%.4X:", chars[i])
		local st, en = self.data:find(codepoint, lastpos, true)
		if st then
			local data, den = self.data:match("%x+", en)
			lastpos = den
			local left, right = data:sub(1, 32), data:sub(33)
			local fontdata = ""
			local wide = #right > 0
			for j=1, 16 do
				local lc = tonumber(left:sub((j*2)-1, j*2), 16)
				local rc = wide and tonumber(right:sub((j*2)-1, j*2), 16) or 0
				local leftbyte = string.char(lc)
				local rightbyte = wide and string.char(rc) or ""
				fontdata = fontdata .. leftbyte .. rightbyte
			end
			self.chars[chars[i]] = fontdata
			table.insert(widths, wide and 16 or 8)
		else
			table.insert(widths, self:is_wide(0xFFFD) and 16 or 8)
		end
	end
	return widths
end

function fnt:is_wide(codepoint)
	return #self.chars[codepoint] == 32
end

function fnt:width(str)
	local unloaded_chars = {
		counts = {}
	}
	local width = 0
	for _, codepoint in utf8.codes(str) do
		if self.chars[codepoint] then
			width = width + (self:is_wide(codepoint) and 16 or 8)
		else
			if not unloaded_chars[codepoint] then
				table.insert(unloaded_chars, codepoint)
				unloaded_chars.counts[codepoint] = 0
			end
			unloaded_chars.counts[codepoint] = unloaded_chars.counts[codepoint] + 1
		end
	end
	local widths = self:load_char(table.unpack(unloaded_chars))
	for i=1, #unloaded_chars do
		local cwidth = widths[i]
		local count = unloaded_chars.counts[unloaded_chars[i]]
		width = width + (cwidth*count)
	end
	return width
end

function fnt:max_width(str, width)

end

function fnt:allocate_buffer(str)
	local width = self:width(str)
	return PixelData.new(width, 16, color.clear)
end

function fnt:render(buffer, color, str)
	local xpos = 0
	for _, codepoint in utf8.codes(str) do
		if not self.chars[codepoint] then
			codepoint = 0xFFFD
		end
		local width = self:is_wide(codepoint) and 16 or 8
		local pixels = width*16
		local data = self.chars[codepoint]
		for i=0, pixels-1 do
			local x, y = (i % width)+1, floor(i/width)+1
			local byte, bit = floor(i/8)+1, 7-(i % 8)
			if band(data:byte(byte), lshift(1, bit)) > 0 then
				buffer:SetPixel(xpos+x, y, color)
			end
		end
		xpos = xpos + width
	end
end

function hexfont.load(data)
	local hex = setmetatable({
		data = data,
		chars = {}
	}, {__index=fnt})
	hex:load_char(0xFFFD)
	return hex
end

return hexfont