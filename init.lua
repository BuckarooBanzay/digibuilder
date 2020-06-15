
digibuilder = {
  max_radius = tonumber(minetest.settings:get("digibuilder.max_radius")) or 15,
}

local MP = minetest.get_modpath("digibuilder")

-- common functions
dofile(MP.."/common.lua")
dofile(MP.."/formspec.lua")
dofile(MP.."/digiline_rules.lua")
dofile(MP.."/digiline_validate_pos.lua")
dofile(MP.."/digiline.lua")
dofile(MP.."/node.lua")
