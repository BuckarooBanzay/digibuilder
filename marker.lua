
local function add_particle_line(pos1, pos2, player)
	local dist = vector.distance(pos1, pos2)
	minetest.add_particlespawner({
		playername = player:get_player_name(),
		amount = dist * 80,  -- About 4 particles per node at any given time
		time = 10,
		minpos = pos1,
		maxpos = pos2,
		minsize = 0.8,
		maxsize = 0.8,
		minexptime = 0.5,
		maxexptime = 0.5,
		texture = "digibuilder_marker_particle.png",
		glow = 14,
	})
end

local function create_particle_cube(pos, radius, player)
	-- Positions
	local offset = radius + 0.5  -- Offset to edges of blocks
	local p1 = vector.add(pos, vector.new(-offset,  offset, -offset))
	local p2 = vector.add(pos, vector.new( offset,  offset, -offset))
	local p3 = vector.add(pos, vector.new( offset,  offset,  offset))
	local p4 = vector.add(pos, vector.new(-offset,  offset,  offset))
	local p5 = vector.add(pos, vector.new(-offset, -offset, -offset))
	local p6 = vector.add(pos, vector.new( offset, -offset, -offset))
	local p7 = vector.add(pos, vector.new( offset, -offset,  offset))
	local p8 = vector.add(pos, vector.new(-offset, -offset,  offset))
	-- Top
	add_particle_line(p1, p2, player)
	add_particle_line(p2, p3, player)
	add_particle_line(p3, p4, player)
	add_particle_line(p4, p1, player)
	-- Bottom
	add_particle_line(p5, p6, player)
	add_particle_line(p6, p7, player)
	add_particle_line(p7, p8, player)
	add_particle_line(p8, p5, player)
	-- Sides
	add_particle_line(p1, p5, player)
	add_particle_line(p2, p6, player)
	add_particle_line(p3, p7, player)
	add_particle_line(p4, p8, player)
end

function digibuilder.show_marker(pos, _, player)
	if not player or player:get_wielded_item():get_name() ~= "" then
		-- Only spawn particles when using an empty hand
		return
	end
	create_particle_cube(pos, digibuilder.max_radius, player)
end
