
if minetest.get_modpath("mesecons_luacontroller") then

	local c = "mesecons_luacontroller:luacontroller0000"

	minetest.register_craft({
		output = "digibuilder:digibuilder",
		recipe = {
			{c,c,c},
			{c,c,c},
			{c,c,c}
		}
	})

end
