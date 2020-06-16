
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
		local node_def = minetest.registered_items[node.name]
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
		local node_def = minetest.registered_items[node.name]
		if not node_def then
			digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
				pos = msg.pos,
				error = true,
				message = "target node is unknown!"
			})
			return
		end

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
		local inv = meta:get_inventory()
		if not inv:contains_item("main", msg.name) then
			digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
				pos = msg.pos,
				error = true,
				message = "Item not in inventory: " .. msg.name
			})
			return
		end

		-- get and validate place node definition
		local place_node_def = minetest.registered_items[msg.name]
		if not place_node_def then
			digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
				pos = msg.pos,
				error = true,
				message = "place node is unknown: '" .. msg.name .. "'"
			})
			return
		end


		-- remove item
		inv:remove_item("main", msg.name)

		local param2 = tonumber(msg.param2)
		local enable_param2 = place_node_def.paramtype2 == "facedir" and param2 and param2 > 0 and param2 <= 255

		local place_node = {
			name = msg.name
		}

		if enable_param2 then
			-- place with param2 info
			place_node.param2 = param2
		end

		-- place node inworld
		minetest.place_node(absolute_pos, place_node)

		if enable_param2 then
			-- add param2 info
			minetest.swap_node(absolute_pos, place_node)
		end

		digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
			pos = msg.pos,
			name = place_node.name,
			param2 = place_node.param2,
			success = true,
		})
	end
end
