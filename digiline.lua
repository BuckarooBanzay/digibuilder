
-- returns a node and loads the area if needed
function digibuilder.get_node(pos)
	local node = minetest.get_node_or_nil(pos)
	if node == nil then
		minetest.get_voxel_manip(pos, pos)
		node = minetest.get_node_or_nil(pos)
	end
	return node
end

-- looks for index of item to pass to fake player
-- while doing so, might as well look for best stack/item
local function best_inventory_index(inv, itemname)
	if not inv:contains_item("main", itemname) then
		return nil
	end

	local best_stack, best_index, stack
	local list = inv:get_list("main")
	local index = #list
	repeat
		stack = list[index]
		if not stack:is_empty() then
			if itemname == stack:get_name() then
				if not best_stack then
					best_stack = stack
					best_index = index
				elseif (best_stack:get_wear() == 0 and stack:get_wear() > 0)
					or (best_stack:get_wear() > stack:get_wear() and stack:get_wear() > 0) then
					best_stack = stack
					best_index = index
				end
			end
		end
		index = index - 1
	until index == 0

	return best_index
end

-- deals with returned stacks
local function return_stack(pos, inv, stack)
	if stack:is_empty() then return end
	local overflow_stack = inv:add_item("main", stack)
	if not overflow_stack:is_empty() then
		-- TODO: discuss if items should be dropped at absolute_pos or pos
		minetest.add_item(pos, overflow_stack)
	end
end

function digibuilder.digiline_effector(pos, _, channel, msg)

	-- only allow table message types
	if type(msg) ~= "table" then
		return
	end

	-- avoid infinitive loops when multiple builders have same channel and are emitting errors
	if msg.error then
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

	elseif msg.command == "setnode" and type(msg.name) == "string" then
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
		local inv_best_index = best_inventory_index(inv, msg.name)

		if not is_creative then
			-- check if node is buildable to
			if not node_def.buildable_to then
				digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
					pos = msg.pos,
					error = true,
					message = "Can't build at that position!"
				})
				return
			end

			-- check if node is in inventory
			-- this check does not work for items like technic:water_can
			-- it may be in inventory but empty. Using an empty can with
			-- digibuilder destroys it!
			if not inv_best_index then
				digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
					pos = msg.pos,
					error = true,
					message = "Item not in inventory: " .. (msg.name and msg.name or "<nil>")
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

		-- only allow param2 setting for "facedir" types
		local param2 = tonumber(msg.param2) or 0
		local enable_param2 = place_node_def.paramtype2 == "facedir" and param2 and param2 >= 0 and param2 <= 255

		local place_node = {
			name = msg.name
		}

		if enable_param2 then
			-- place with param2 info
			place_node.param2 = param2
		else
			-- set default param2
			place_node.param2 = 0
		end

		if place_node_def.place_param2 ~= nil then
			-- use predefined param2
			place_node.param2 = place_node_def.place_param2
		end

		-- place node inworld
		minetest.log("action", "[digibuilder] " .. owner .. " places node '" ..
			place_node.name .. "' at " ..
			minetest.pos_to_string(absolute_pos)
		)

		local dir = minetest.facedir_to_dir(place_node.param2)
		if not dir then
			-- invalid param2 given, use defaults
			dir = vector.new(0, 1, 0)
			place_node.param2 = 0
		end

		-- create fake player for certain function arguments (after_place_node, etc)
		local player = fakelib.create_player({
			name = owner,
			inventory = inv,
			wield_list = "main",
			wield_index = inv_best_index,
			position = absolute_pos,
			direction = vector.multiply(dir, -1),
		})

		-- see:
		-- https://github.com/minetest-mods/digtron/blob/843dbd227658a93ee4df791bfdd3d136ee7adf85/util_item_place_node.lua
		local pointed_thing = {}
		pointed_thing.type = "node"
		pointed_thing.above = {x=absolute_pos.x, y=absolute_pos.y, z=absolute_pos.z}
		pointed_thing.under = {x=absolute_pos.x, y=absolute_pos.y, z=absolute_pos.z}
		-- Note: it is intentional that the default is a
		-- neutral (non-directional) pointed_thing
		if msg.up == true then
			pointed_thing.under.y = absolute_pos.y + 1
		elseif msg.down == true then
			pointed_thing.under.y = absolute_pos.y - 1
		elseif msg.west == true then
			pointed_thing.under.x = absolute_pos.x - 1
		elseif msg.east == true then
			pointed_thing.under.x = absolute_pos.x + 1
		elseif msg.south == true then
			pointed_thing.under.z = absolute_pos.z - 1
		elseif msg.north == true then
			pointed_thing.under.z = absolute_pos.z + 1
		elseif msg.auto == true then
			if place_node_def.paramtype2 == "facedir" then
				pointed_thing.under = vector.add(absolute_pos, minetest.facedir_to_dir(place_node.param2))
			elseif place_node_def.paramtype2 == "wallmounted" then
				pointed_thing.under = vector.add(absolute_pos, minetest.wallmounted_to_dir(place_node.param2))
			else
				pointed_thing.under.y = absolute_pos.y - 1
			end
		end

		if place_node_def.on_place ~= minetest.item_place then
			-- non-default item placement, use custom function (crops, other items)
			-- taking an actual item instead of creating a new stack,
			-- raises the chances that we get something useful
			local itemstack
			if is_creative and inv_best_index == nil then
				itemstack = ItemStack(msg.name .. " 1")
			else
				-- get a copy (with metadata)
				itemstack = inv:get_stack("main", inv_best_index)
				-- delete slot
				inv:set_stack("main", inv_best_index, ItemStack("")) --inv:remove_item("main", msg.name)
			end

			local returnstack, success = place_node_def.on_place(ItemStack(itemstack), player, pointed_thing)
			if returnstack then
				return_stack(pos, inv, returnstack)
				if returnstack:get_wear() ~= itemstack:get_wear()
					or returnstack:get_name() ~= itemstack:get_name()
					or returnstack:get_count() < itemstack:get_count() then
						success = true
				end
			end
			if not success then
				if not returnstack then
					-- some items aren't placed but don't return a stack
					return_stack(pos, inv, itemstack)
				end
				digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
					pos = msg.pos,
					error = true,
					message = "item placement failed: '" .. msg.name .. "'"
				})
				return
			end
		else
			-- default on_place, use `set_node` to avoid side-effects (on-place rotations)
			minetest.set_node(absolute_pos, place_node)
			if not is_creative then
				inv:remove_item("main", msg.name)
			end
		end

		-- check if "after_place_node" is defined
		if place_node_def.after_place_node then
			place_node_def.after_place_node(absolute_pos, player, ItemStack(), pointed_thing)
		end

		-- check if the node is falling
		minetest.check_for_falling(absolute_pos)

		-- checking if param2 actually is what was requested
		if enable_param2 then
			local check_node = digibuilder.get_node(absolute_pos)
			-- it is not always a bad sign when name of placed node does
			-- not match itemname, certain nodes change their name (or fall)
			-- also itemname and nodename don't always match
			if check_node.name == msg.name and check_node.param2 ~= place_node.param2 then
				-- enforce param2
				minetest.swap_node(absolute_pos, place_node)
			end
		end

		digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
			pos = msg.pos,
			name = place_node.name,
			param2 = place_node.param2,
			success = true,
		})
	end
end

