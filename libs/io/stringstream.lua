local str = {}

function str:read(amt)
	local d = self.str:sub(self.ptr, self.ptr+amt-1)
	self.ptr = self.ptr+amt
	return d
end

function str:seek(whence, amt)
	if whence == "cur" then
		self.ptr = self.ptr + amt
	elseif whence == "set" then
		self.ptr = amt
	elseif whence == "end" then
		self.ptr = self.size + amt
	else
		error("unknown position '"..whence.."'")
	end
	if self.ptr > self.size then
		self.ptr = self.size
	elseif self.ptr < 1 then
		self.ptr = 1
	end
	return self.ptr
end

return function(s)
	return setmetatable({
		ptr = 1,
		size = #s,
		str = s
	}, {__index = str})
end