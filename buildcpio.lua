local lfs = require("lfs")
os.remove("build")
lfs.mkdir("build")
lfs.mkdir("build/fonts")
local function font(dir)
	for e in lfs.dir(dir) do
		local ext = e:match("%.([^%.]+)$")
		if ext == "hex" or ext == "ase" then
			return e, ext
		end
	end
end
for e in lfs.dir("fonts") do
	if e:sub(1,1) ~= "." then
		local f, ext = font("fonts/"..e)
		if f then
			if ext == "ase" then
				os.execute(string.format("lua tools/make-vix-font.lua %q > /dev/null", "fonts/"..e.."/export"))
				local fname = f:gsub("ase$", "vixfont")
				os.execute(string.format("cp %q %q", "fonts/"..e.."/"..fname, "build/fonts/"..fname))
				print("FONT", fname)
			else
				os.execute(string.format("cp %q %q", "fonts/"..e.."/"..f, "build/fonts/"..f))
				print("FONT", f)
			end
		end
	end
end
os.execute("cd build; find * | cpio -o > fonts.cpio")
os.execute("lua tools/file-to-lua-string.lua build/fonts.cpio > build/fonts.lua")