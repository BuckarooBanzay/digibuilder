
if minetest.get_modpath("mesecons_luacontroller") and minetest.get_modpath("default") then

	local c = "mesecons_luacontroller:luacontroller0000"

	minetest.register_craft({
		output = "digibuilder:digibuilder",
		recipe = {
			{c,c,c},
			{c,"default:diamondblock",c},
			{c,c,c}
		}
	})

end
