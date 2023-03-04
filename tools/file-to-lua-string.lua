local f = io.open(arg[1], "rb")
io.stdout:write("return {\"")
while true do
	local d = f:read(1024*1024)
	if d == "" or not d then break end
	local outd = d:gsub("\\", "\\\\")
	              :gsub("\r", "\\r")
	              :gsub("\n", "\\n")
	              :gsub("\"", "\\\"")
	              :gsub("\0", "\\x00")
	              :gsub("\t", "\\t")
	              :gsub("[\127-\255]", function(m)
					return string.format("\\x%.2x", string.byte(m))
	              end)
	io.stdout:write(outd)
end
io.stdout:write("\"}\n")
