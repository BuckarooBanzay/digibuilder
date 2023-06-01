-- places a box of slabs and places water inside it

local s = "moreblocks:slab_super_glow_glass_1"
local w = "bucket:bucket_river_water"
-- list of setnode commands
local data = {
	{ name = s, param2 = 21, pos = { x = 0, y = 1, z = 0 } },
	{ name = s, param2 = 3, pos = { x = 0, y = 3, z = 0 } },
	{ name = s, param2 = 11, pos = { x = 0, y = 2, z = -1 } },
	{ name = s, param2 = 5, pos = { x = 0, y = 2, z = 1 } },
	{ name = s, param2 = 12, pos = { x = 1, y = 2, z = 0 } },
	{ name = s, param2 = 18, pos = { x = -1, y = 2, z = 0 } },
	{ name = w, pos = { x = 0, y = 2, z = 0 }
	}
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
