globals = {
	"digibuilder"
}

read_globals = {
	-- Stdlib
	string = {fields = {"split"}},
	table = {fields = {"copy", "getn"}},
	"VoxelManip",

	-- Minetest
	"minetest",
	"vector", "ItemStack",
	"dump", "VoxelArea",

	-- Deps
	"digilines",
	"pipeworks",
	"mesecons",
	"default",
	"mtt"
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
