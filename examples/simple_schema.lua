
-- list of setnode commands
local data = {
	{ name = "default:stone", pos = { x=1, y=0, z=1 } },
	{ name = "default:stone", pos = { x=-1, y=0, z=-1 } }
}

-- initial start
if event.type == "program" then
	mem.pos = 1
	interrupt(1)
end

-- timer interrupt
if event.type == "interrupt" then
	local entry = data[mem.pos]
	if not entry then
		-- done
		return
	end

	digiline_send("digibuilder", {
	  command = "setnode",
	  pos = entry.pos,
	  param2 = entry.param2,
	  name = entry.name
	})
end

-- callback from digibuilder node
if event.type == "digiline" and event.channel == "digibuilder" then
	if event.error then
		-- error state
		error(event.message)
	end

	-- next command
	mem.pos = mem.pos + 1
	interrupt(1)
end
