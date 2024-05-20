globals = {
	"digibuilder"
}

read_globals = {
	-- Minetest
	"minetest",
	"vector", "ItemStack",

	-- Mods
	"digilines",
	"pipeworks",
	"mesecons",
	"default",
	"mtt",
	"vizlib",
	"fakelib",
}

files["examples/"] = {
	globals = {
		"mem"
	},
	read_globals = {
		"event",
		"interrupt",
		"digiline_send"
	}
}
