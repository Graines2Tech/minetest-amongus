-- Load support for MT game translation.
local S = minetest.get_translator("amongus")

local function toggle(pos, node, clicker)
	--TODO
	--la porte ne peut être ouverte que par un imposteur si la partie est lancée
	--la porte peut être ouverte en mode créative par tout le monde
	--la porte doit se refermer après 1 seconde
	local player_name = clicker:get_player_name()

	if not (amongus.creative_mode or (amongus.start and amongus.is_impostor(player_name))) then
		local ndef = minetest.registered_nodes[node.name]
		minetest.sound_play(ndef.sound_locked, {pos = pos, gain = 0.3, max_hear_distance = 10})
		return false
	end
	doors.toggle_door(pos, node, clicker)
end

doors.register_door(
	"amongus:door_impostor",
	{
		tiles = {{name = "amongus_door.png", backface_culling = true}},
		description = S("Impostor Door"),
		inventory_image = "amongus_item.png",
		groups = {cracky = 1, level = 2},
		sounds = default.node_sound_metal_defaults(),
		sound_open = "doors_steel_door_open",
		sound_close = "doors_steel_door_close",
		is_closable = true,
		can_center = true,
		can_toggle_door = function(pos, node, clicker, itemstack, pointed_thing)
			local player_name = clicker:get_player_name()

			if not (amongus.creative_mode or (amongus.start and amongus.is_impostor(player_name))) then
				return false
			end
			
			return true
		end
	}
)

doors.register_trapdoor(
	"amongus:trapdoor_impostor",
	{
		description = S("Impostor Trapdoor"),
		inventory_image = "amongus_trapdoor.png",
		wield_image = "amongus_trapdoor.png",
		tile_front = "amongus_trapdoor.png",
		tile_side = "amongus_trapdoor_side.png",
		sounds = default.node_sound_metal_defaults(),
		sound_open = "doors_steel_door_open",
		sound_close = "doors_steel_door_close",
		groups = {cracky = 1, level = 2, door = 1},
		is_closable = true,
		can_toggle_door = function(pos, node, clicker, itemstack, pointed_thing)
			local player_name = clicker:get_player_name()

			if not (amongus.creative_mode or (amongus.start and amongus.is_impostor(player_name))) then
				return false
			end

			return true
		end
	}
)
