amongus = {}
local saved_huds = {}

local function hud_update(player)
    local player_name = player:get_player_name()

    local ids = saved_huds[player_name]
    if ids then
    else
        ids = {}
        saved_huds[player_name] = ids

        -- create HUD elements and set ids into `ids`
        local idx = player:hud_add({
            hud_elem_type = "text",
            position      = {x = 0, y = 0.1},
            offset        = {x = 50,   y = 0},
            text          = "Tasks",
            alignment     = {x = 0, y = 0},  -- center aligned
            scale         = {x = 100, y = 100}, -- covered later
       })
    end
end

minetest.register_on_joinplayer(hud_update)

minetest.register_on_leaveplayer(function(player)
    saved_huds[player:get_player_name()] = nil
end)