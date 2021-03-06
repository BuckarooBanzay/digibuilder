
-- returns a node and loads the area if needed
function digibuilder.get_node(pos)
	local node = minetest.get_node_or_nil(pos)
	if node == nil then
		minetest.get_voxel_manip(pos, pos)
		node = minetest.get_node_or_nil(pos)
	end
	return node
end

function digibuilder.digiline_effector(pos, _, channel, msg)

	local msgt = type(msg)
	if msgt ~= "table" then
		return
	end

	local meta = minetest.get_meta(pos)

	local set_channel = meta:get_string("channel")
	if channel ~= set_channel then
		return
	end

	-- validate position
	local owner = meta:get_string("owner")
	if not digibuilder.digiline_validate_pos(pos, owner, set_channel, msg) then
		return
	end

	if msg.command == "getnode" then
		-- calculate absolute position
		local absolute_pos = vector.add(pos, msg.pos)
		local node = digibuilder.get_node(absolute_pos)

		-- get and validate node definition
		local node_def = minetest.registered_nodes[node.name]
		if not node_def then
			digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
				pos = msg.pos,
				error = true,
				message = "target node is unknown!"
			})
			return
		end

		-- assemble result
		local result = {
			pos = msg.pos,
			name = node.name
		}

		if node_def.paramtype2 == "facedir" then
			-- add param2 info
			result.param2 = node.param2
		end
		digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, result)

	elseif msg.command == "setnode" then
		-- set last call time of the command
		local now = minetest.get_us_time()
		local previous_time = meta:get_int("lastsetcommand")

		local diff_micros = now - previous_time
		if diff_micros < (digibuilder.setnode_delay * 1000 * 1000) then
			-- less than half a second elapsed
			digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
				pos = msg.pos,
				error = true,
				message = "setnode called too fast!"
			})
			return
		end

		-- set new lastcommand time
		meta:set_int("lastsetcommand", now)

		-- calculate absolute position
		local absolute_pos = vector.add(pos, msg.pos)
		local node = digibuilder.get_node(absolute_pos)

		-- get and validate node definition
		local node_def = minetest.registered_nodes[node.name]
		if not node_def then
			digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
				pos = msg.pos,
				error = true,
				message = "target node is unknown!"
			})
			return
		end

		local is_creative = minetest.check_player_privs(owner, "creative")
		local inv = meta:get_inventory()


		if not is_creative then
			-- check if node is buildable to
			if not node_def.buildable_to then
				digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
					pos = msg.pos,
					error = true,
					message = "Can't build on that position!"
				})
				return
			end

			-- check if node is in inventory
			if not inv:contains_item("main", msg.name) then
				digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
					pos = msg.pos,
					error = true,
					message = "Item not in inventory: " .. msg.name
				})
				return
			end
		end

		-- get and validate place node definition
		local place_node_def = minetest.registered_items[msg.name]
		if not place_node_def then
			digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
				pos = msg.pos,
				error = true,
				message = "place node is unknown: '" .. (msg.name or "<empty>") .. "'"
			})
			return
		end

		if not place_node_def.on_place then
			-- can't place node
			digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
				pos = msg.pos,
				error = true,
				message = "node can't be placed: '" .. msg.name .. "'"
			})
			return
		end

		if not is_creative then
			-- remove item
			inv:remove_item("main", msg.name)
		end

		-- only allow param2 setting for "facedir" types
		local param2 = tonumber(msg.param2) or 0
		local enable_param2 = place_node_def.paramtype2 == "facedir" and param2 and param2 > 0 and param2 <= 255

		local place_node = {
			name = msg.name
		}

		if enable_param2 then
			-- place with param2 info
			place_node.param2 = param2
		end

		-- place node inworld
		minetest.log("action", "[digibuilder] " .. owner .. " places node '" ..
			place_node.name .. "' at " ..
			minetest.pos_to_string(absolute_pos)
		)

		-- create fake player for certain function arguments (after_place_node, etc)
		local player = digibuilder.create_fake_player({
			name = owner
		})

		-- see:
		-- https://github.com/minetest-mods/digtron/blob/843dbd227658a93ee4df791bfdd3d136ee7adf85/util_item_place_node.lua
		local pointed_thing = {}
		pointed_thing.type = "node"
		pointed_thing.above = {x=absolute_pos.x, y=absolute_pos.y, z=absolute_pos.z}
		pointed_thing.under = {x=absolute_pos.x, y=absolute_pos.y, z=absolute_pos.z}

		if place_node_def.paramtype2 == "facedir" then
			pointed_thing.under = vector.add(absolute_pos, minetest.facedir_to_dir(param2))
		elseif place_node_def.paramtype2 == "wallmounted" then
			pointed_thing.under = vector.add(absolute_pos, minetest.wallmounted_to_dir(param2))
		end

		local itemstack = ItemStack(msg.name .. " 1")
		local returnstack, success = place_node_def.on_place(ItemStack(itemstack), player, pointed_thing)
		if returnstack and returnstack:get_count() < itemstack:get_count() then success = true end

		if success then
			local placed_node = minetest.get_node(absolute_pos)
			placed_node.param2 = param2
			minetest.set_node(absolute_pos, placed_node)
		end

		-- check if "after_place_node" is defined
		if place_node_def.after_place_node then
			place_node_def.after_place_node(absolute_pos, player, ItemStack(), pointed_thing)
		end

		-- check if the node is falling
		minetest.check_for_falling(absolute_pos)

		digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
			pos = msg.pos,
			name = place_node.name,
			param2 = place_node.param2,
			success = true,
		})
	end
end
