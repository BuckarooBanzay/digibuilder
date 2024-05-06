
local builder_pos = { x=0, y=100, z=0 }
local build_pos = { x=0, y=101, z=0 }
local neighbor_pos = { x=1, y=100, z=0 }

mtt.emerge_area(builder_pos, builder_pos)

-- debugging
--[[
local old_send = digilines.receptor_send
function digilines.receptor_send(pos, rules, channel, msg)
    print(dump({
        method = "digilines.receptor_send",
        pos = pos,
        channel = channel,
        msg = msg
    }))
    return old_send(pos, rules, channel, msg)
end
--]]

mtt.register("setup", function(callback)
    -- place builder and wire
    minetest.set_node(build_pos, { name="air" })
    minetest.set_node(builder_pos, { name="digibuilder:digibuilder" })
    minetest.set_node(neighbor_pos, { name="digilines:wire_std_11111111" })

    local builder_def = minetest.registered_nodes["digibuilder:digibuilder"]
    assert(builder_def)

    builder_def.on_construct(builder_pos)

    local meta = minetest.get_meta(builder_pos)
    -- verify placement
    assert(meta:get_string("channel") == "digibuilder")
    -- set owner
    meta:set_string("owner", "singleplayer")

    callback()
end)

mtt.register("setnode-test", function(callback)
    -- send command
    digilines.receptor_send(neighbor_pos, digibuilder.digiline_rules, "digibuilder", {
        command = "setnode",
        pos = { x=0, y=1, z=0 },
        name = "default:mese"
    })

    -- nothing was built (empty inv)
    assert(minetest.get_node(build_pos).name ~= "default:mese")

    -- add inventory
    local meta = minetest.get_meta(builder_pos)
    local inv = meta:get_inventory()
    inv:add_item("main", "default:mese 1")

    -- schedule next command a second later to not trigger the "too fast" error
    minetest.after(1, function()
        -- send command
        digilines.receptor_send(neighbor_pos, digibuilder.digiline_rules, "digibuilder", {
            command = "setnode",
            pos = { x=0, y=1, z=0 },
            name = "default:mese"
        })

        -- mese block was built
        assert(minetest.get_node(build_pos).name == "default:mese")

        callback()
    end)
end)

mtt.register("build-invalid-param2", function(callback)
    -- prepare
    minetest.set_node(build_pos, { name="air" })

    -- add inventory
    local meta = minetest.get_meta(builder_pos)
    local inv = meta:get_inventory()
    inv:add_item("main", "default:tree 1")

    -- send invalid command
    digilines.receptor_send(neighbor_pos, digibuilder.digiline_rules, "digibuilder", {
        command = "setnode",
        pos = { x=0, y=1, z=0 },
        param2 = 255,
        name = "default:tree"
    })

    assert(minetest.get_node(build_pos).name == "default:tree")

    callback()
end)

mtt.register("place-crop", function(callback)
    -- TODO
    callback()
end)