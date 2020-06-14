
function digibuilder.update_formspec(meta)
  local message = meta:get_string("message")

  local formspec =
    "size[8,9.2;]" ..

    -- main inventory
    "list[context;main;0,0.25;8,4;]" ..

    -- player inventory
    "list[current_player;main;0,4.5;8,4;]" ..

    -- message
    "label[0,8.7;" .. message .. "]" ..

    -- digiline channel
    "field[4.3,9;3.2,1;digiline_channel;Digiline channel;" .. (meta:get_string("channel") or "") .. "]" ..
    "button_exit[7,8.7;1,1;set_digiline_channel;Set]" ..

    -- listring stuff
    "listring[context;main]" ..
    "listring[current_player;main]"

  meta:set_string("formspec", formspec)
  meta:set_string("infotext", "Digibuilder: " .. message)
end
