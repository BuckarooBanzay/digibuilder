
-- pattern, starting at -x/-z
local data = {
	-- x >>
	"sdsdsd",
	"dsds"
	-- z \/
}

local nodes = {
	["s"] = "default:stone",
	["d"] = "default:dirt"
}

-- coordinate offsets
local x_offset = -5
local y_offset = 2
local z_offset = -5

-- initial start
if event.type == "program" then
	mem.line = 1
	mem.pos = 1
	interrupt(1)
end

-- timer interrupt
if event.type == "interrupt" then
 local line = data[mem.line]
 if not line then
		-- done
		return
	end

	local char = line:sub(mem.pos, mem.pos)
	if char == "" then
		-- next line
		mem.line = mem.line + 1
		mem.pos = 1
		interrupt(0.5)
		return
	end

	digiline_send("digibuilder", {
	  command = "setnode",
	  pos = { x=x_offset+mem.pos-1, y=y_offset, z=z_offset+mem.line-1 },
	  name = nodes[char]
	})

end

-- callback from digibuilder node
if event.type == "digiline" and event.channel == "digibuilder" then
 if event.error then
		-- error state
		error(event.message)
		return
	end

	-- next command
  mem.pos = mem.pos + 1
	interrupt(1)
end
