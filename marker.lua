
function digibuilder.show_marker(pos, radius)
	local entity = "digibuilder:marker"

	minetest.add_entity({x=pos.x+radius, y=pos.y+radius, z=pos.z+radius}, entity)
	minetest.add_entity({x=pos.x-radius, y=pos.y+radius, z=pos.z+radius}, entity)
	minetest.add_entity({x=pos.x+radius, y=pos.y+radius, z=pos.z-radius}, entity)
	minetest.add_entity({x=pos.x-radius, y=pos.y+radius, z=pos.z-radius}, entity)
	minetest.add_entity({x=pos.x+radius, y=pos.y-radius, z=pos.z+radius}, entity)
	minetest.add_entity({x=pos.x-radius, y=pos.y-radius, z=pos.z+radius}, entity)
	minetest.add_entity({x=pos.x+radius, y=pos.y-radius, z=pos.z-radius}, entity)
	minetest.add_entity({x=pos.x-radius, y=pos.y-radius, z=pos.z-radius}, entity)
end

local texture = "digibuilder_marker_green.png"

minetest.register_entity("digibuilder:marker", {
	initial_properties = {
		visual = "cube",
		visual_size = {x=1.05, y=1.05},
		static_save = false,
		textures = {
			texture,
			texture,
			texture,
			texture,
			texture,
			texture
		},
		collisionbox = {-0.525, -0.525, -0.525, 0.525, 0.525, 0.525},
		physical = false,
	},

	on_activate = function(self)
		minetest.after(8.0, function() self.object:remove() end)
	end,

	on_rightclick=function(self)
		self.object:remove()
	end,

	on_punch = function(self)
		self.object:remove()
	end,
})
