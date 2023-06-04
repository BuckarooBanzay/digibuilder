-- places a stone above digibuilder, then surrounds it with
-- cable-plates so that the big flat end lies against the stone

-- list of setnode commands
local s = "technic:hv_cable_plate_1"
local data = {
	{ name = "default:stone", pos = { x = 0, y = 2, z = 0 } },
	{ name = s, up = true, pos = { x = 0, y = 1, z = 0 } },
	{ name = s, down = true, pos = { x = 0, y = 3, z = 0 } },
	{ name = s, north = true, pos = { x = 0, y = 2, z = -1 } },
	{ name = s, south = true, pos = { x = 0, y = 2, z = 1 } },
	{ name = s, west = true, pos = { x = 1, y = 2, z = 0 } },
	{ name = s, east = true, pos = { x = -1, y = 2, z = 0 } }
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

	entry.command = "setnode"
	digiline_send("digibuilder", entry)
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
