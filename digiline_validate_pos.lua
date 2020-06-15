
function digibuilder.digiline_validate_pos(pos, owner, set_channel, msg)

	if not msg.pos then
		digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
			error = true,
			message = "'pos' is not set!"
		})
		return
	end

	local x = tonumber(msg.pos.x)
	local y = tonumber(msg.pos.y)
	local z = tonumber(msg.pos.z)

	if not x or not y or not z then
		digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
			error = true,
			message = "'pos' is has invalid x/y/z fields!"
		})
		return false
	end

	if math.abs(x) > digibuilder.max_radius then
		digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
			error = true,
			message = "'pos.x' is out of the area!"
		})
		return false
	end

	if math.abs(y) > digibuilder.max_radius then
		digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
			error = true,
			message = "'pos.y' is out of the area!"
		})
		return false
	end

	if math.abs(z) > digibuilder.max_radius then
		digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
			error = true,
			message = "'pos.z' is out of the area!"
		})
		return false
	end

  if x == 0 and y == 0 and z == 0 then
    digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
			error = true,
			message = "can't work on myself!"
		})
		return false
  end

	if minetest.is_protected(pos, owner) then
		digilines.receptor_send(pos, digibuilder.digiline_rules, set_channel, {
			pos = msg.pos,
			error = true,
			message = "position is protected!"
		})
		return false
	end

  return true
end
