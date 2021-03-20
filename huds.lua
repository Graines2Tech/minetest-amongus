local S = minetest.get_translator("amongus")

local POS_CENTER_MIDDLE = {x = 0.5, y = 0.5}
local POS_RIGHT_BOTTOM = {x = 1, y = 1}
local POS_LEFT_BOTTOM = {x = 0, y = 1}
--references if a temporary message is displayed TEMPORARY_LIST[player_name][position]=boolean
local TEMPORARY_LIST = {}

-- display a temporary hud for a player
local function display_temporary_hud(player, timeout, position, message, color, scale)
    local player_name = player:get_player_name()
    if TEMPORARY_LIST[player_name] == nil then
        TEMPORARY_LIST[player_name] = {}
    end
    if TEMPORARY_LIST[player_name][position] ~= nil then
        --wait a second before displaying message for the player
        minetest.after(
            1,
            function()
                display_temporary_hud(player, timeout, position, message, color, scale)
            end
        )
        return
    end
    --reference a displayed message at this position for this player
    TEMPORARY_LIST[player_name][position] = true
    --display the message for the player
    local bg =
        player:hud_add(
        {
            hud_elem_type = "image",
            position = position,
            offset = {x = 0, y = 0},
            text = "amongus_tasks_background.png",
            alignment = {x = 0, y = 0},
            scale = {x = (scale.x + 20) / 10, y = (scale.y + 20) / 10}
        }
    )
    local hud =
        player:hud_add(
        {
            hud_elem_type = "text",
            position = position,
            offset = {x = 0, y = 0},
            text = message,
            alignment = {x = 0, y = 0},
            scale = scale,
            number = color
        }
    )
    minetest.log(
        string.format("[amongus] add huds %s and %s for player %s", dump(hud), dump(bg), player:get_player_name())
    )
    --destroy the display after timeout
    minetest.after(
        timeout,
        function()
            minetest.log(
                string.format(
                    "[amongus] remove huds %s and %s for player %s",
                    dump(hud),
                    dump(bg),
                    player:get_player_name()
                )
            )
            player:hud_remove(hud)
            player:hud_remove(bg)
            --dereference the displayed message for this player at this position
            TEMPORARY_LIST[player_name][position] = nil
        end
    )
end

--display tasks for the selected player
function amongus.display_tasks(player_name)
    local alignment = {x = 1, y = 1}
    local nb_tasks = 0
    if amongus.player_tasks[player_name] ~= nil then
        nb_tasks = #amongus.player_tasks[player_name]
    end
    local p = amongus.players[player_name]
    if p.connected then
        local top = nb_tasks * 20 + 20 + 10
        local length = 220
        table.insert(
            amongus.tasks_huds,
            {
                player_name,
                p.player:hud_add(
                    {
                        hud_elem_type = "image",
                        position = POS_RIGHT_BOTTOM,
                        offset = {x = -length, y = -top},
                        text = "amongus_tasks_background.png",
                        alignment = alignment,
                        scale = {x = 22, y = 2}
                    }
                )
            }
        )
        table.insert(
            amongus.tasks_huds,
            {
                player_name,
                p.player:hud_add(
                    {
                        hud_elem_type = "text",
                        position = POS_RIGHT_BOTTOM,
                        offset = {x = -length, y = -top},
                        text = S("Tasks"),
                        alignment = alignment,
                        scale = {x = 200, y = 20}
                    }
                )
            }
        )
        table.insert(
            amongus.tasks_huds,
            {
                player_name,
                p.player:hud_add(
                    {
                        hud_elem_type = "image",
                        position = POS_RIGHT_BOTTOM,
                        offset = {x = -length, y = -top + 20},
                        text = "amongus_tasks_bar.png",
                        alignment = alignment,
                        scale = {x = (22 * amongus.task_completion), y = 1}
                    }
                )
            }
        )
        if nb_tasks > 0 then
            table.insert(
                amongus.tasks_huds,
                {
                    player_name,
                    p.player:hud_add(
                        {
                            hud_elem_type = "image",
                            position = POS_RIGHT_BOTTOM,
                            offset = {x = -length, y = -top + 30},
                            text = "amongus_tasks_background.png",
                            alignment = alignment,
                            scale = {x = 22, y = 2 * #amongus.player_tasks[player_name]}
                        }
                    )
                }
            )
            for i, task in pairs(amongus.player_tasks[player_name]) do
                table.insert(
                    amongus.tasks_huds,
                    {
                        player_name,
                        p.player:hud_add(
                            {
                                hud_elem_type = "text",
                                position = POS_RIGHT_BOTTOM,
                                offset = {x = -length, y = -top + 10 + 20 * i},
                                text = task.name,
                                alignment = alignment,
                                scale = {x = 200, y = 20},
                                number = 0xFF0000
                            }
                        )
                    }
                )
                table.insert(
                    amongus.tasks_huds,
                    {
                        player_name,
                        p.player:hud_add(
                            {
                                hud_elem_type = "waypoint",
                                text = "m",
                                number = 0xffffff,
                                name = task.name,
                                world_pos = task.pos
                            }
                        )
                    }
                )
            end
        end
    end
end

--hide tasks for the selected player
function amongus.hide_tasks(player_name)
    local p = amongus.players[player_name]
    if p.connected then
        for i, hud in pairs(amongus.tasks_huds) do
            if player_name == hud[1] then
                p.player:hud_remove(hud[2])
            end
        end
    end
end

--update the task bar for all players
function amongus.update_tasks_bar()
    for p_name, p in pairs(amongus.players) do
        if p.connected then
            for i, hud in pairs(amongus.tasks_huds) do
                local hud_def = p.player:hud_get(hud[2])
                if hud_def ~= nil then
                    if hud_def.text == "amongus_tasks_bar.png" then
                        p.player:hud_change(hud[2], "scale", {x = (22 * amongus.task_completion), y = 1})
                    end
                end
            end
        end
    end
end

--update à task for a player
function amongus.update_task(player_name, task_name)
    local p = amongus.players[player_name]
    if p and p.connected then
        for _, hud in pairs(amongus.tasks_huds) do
            if hud[1] == player_name then
                local hud_def = p.player:hud_get(hud[2])
                if hud_def then
                    if hud_def.text == task_name then
                        p.player:hud_change(hud[2], "number", 0x00FF00)
                    end
                    if hud_def.name == task_name then
                        p.player:hud_remove(hud[2])
                    end
                end
            end
        end
    end
end

--display impostors
function amongus.display_impostors()
    local alignment = {x = 0, y = 1}
    local top = 40
    local length = 110
    local impostors_names = {}
    for _, player_name in ipairs(amongus.impostors) do
        table.insert(impostors_names, player_name)
    end
    local impostors_name = table.concat(impostors_names, ",")
    for _, player_name in ipairs(amongus.impostors) do
        local p = amongus.players[player_name]
        if p.connected then
            table.insert(
                amongus.impostors_huds,
                {
                    player_name,
                    p.player:hud_add(
                        {
                            hud_elem_type = "text",
                            position = POS_LEFT_BOTTOM,
                            offset = {x = length, y = -top},
                            text = S("IMPOSTOR"),
                            alignment = alignment,
                            scale = {x = 200, y = 20},
                            number = 0xFF0000
                        }
                    )
                }
            )
            table.insert(
                amongus.impostors_huds,
                {
                    player_name,
                    p.player:hud_add(
                        {
                            hud_elem_type = "text",
                            position = POS_LEFT_BOTTOM,
                            offset = {x = length, y = -top + 20},
                            text = impostors_name,
                            alignment = alignment,
                            scale = {x = 200, y = 20},
                            number = 0xFF0000
                        }
                    )
                }
            )
        end
    end
end

--calcultate kill cooldown message and color
local function get_kill_cooldown_msg()
    local color = 0xFF0000
    local msg = S("Kill available")
    if amongus.kill_current_cooldown == 0 then
        color = 0x00FF00
    else
        msg = msg .. " " .. S("in @1s", dump(amongus.kill_current_cooldown))
    end
    return color, msg
end

--refresh kill cooldown
function amongus.refresh_kill_cooldown()
    local color, msg = get_kill_cooldown_msg()
    for _, hud in ipairs(amongus.impostors_huds_kill_cooldown) do
        local p = amongus.players[hud[1]]
        if p.connected then
            p.player:hud_change(hud[2], "text", msg)
            p.player:hud_change(hud[2], "number", color)
        end
    end
end

--displays kill cooldown
function amongus.display_kill_cooldown()
    local alignment = {x = 0, y = 1}
    local top = 80
    local length = 110
    local color, msg = get_kill_cooldown_msg()
    for _, player_name in ipairs(amongus.impostors) do
        local p = amongus.players[player_name]
        if p.connected then
            table.insert(
                amongus.impostors_huds_kill_cooldown,
                {
                    player_name,
                    p.player:hud_add(
                        {
                            hud_elem_type = "text",
                            position = POS_LEFT_BOTTOM,
                            offset = {x = length, y = -top},
                            text = msg,
                            alignment = alignment,
                            scale = {x = 200, y = 20},
                            number = color
                        }
                    )
                }
            )
        end
    end
end

-- announce a meeting
function amongus.announce_meeting()
    local alignment = {x = 0, y = 0}
    local top = 0
    local length = 300
    local init = S("Use the chat to discuss.") .. "\n" .. S("Right click on the spawn block to vote.") .. "\n"
    for p_name, p in pairs(amongus.players) do
        if p.connected then
            table.insert(
                amongus.meeting_huds,
                {
                    p_name,
                    p.player:hud_add(
                        {
                            hud_elem_type = "image",
                            position = POS_CENTER_MIDDLE,
                            offset = {x = 0, y = 0},
                            text = "amongus_tasks_background.png",
                            alignment = alignment,
                            scale = {x = length / 10, y = 6}
                        }
                    )
                }
            )
            table.insert(
                amongus.meeting_huds,
                {
                    p_name,
                    p.player:hud_add(
                        {
                            hud_elem_type = "text",
                            position = POS_CENTER_MIDDLE,
                            offset = {x = 0, y = 0},
                            text = init .. S("@1s remaining.", tostring(amongus.meeting_delay)),
                            alignment = alignment,
                            scale = {x = length, y = 60},
                            number = 0x0000FF
                        }
                    )
                }
            )
        end
    end
    minetest.after(
        amongus.meeting_delay,
        function()
            if amongus.meeting then
                amongus.check_end_votation(true)
            end
        end
    )
    local check_timer
    check_timer = function(timer_left)
        if amongus.meeting and timer_left > 0 then
            for _, hud in ipairs(amongus.meeting_huds) do
                local p = amongus.players[hud[1]]
                if p.connected then
                    local hud_def = p.player:hud_get(hud[2])
                    if hud_def ~= nil then
                        if hud_def.type == "text" then
                            p.player:hud_change(hud[2], "text", init .. S("@1s remaining.", tostring(timer_left)))
                        end
                    end
                end
            end
            minetest.after(1, check_timer, timer_left - 1)
        end
    end
    minetest.after(1, check_timer, amongus.meeting_delay)
end

--announce the end of a meeting
function amongus.announce_end_meeting(message)
    for p_name, p in pairs(amongus.players) do
        if p.connected then
            amongus.reset_meeting_huds()
            display_temporary_hud(p.player, 5, POS_CENTER_MIDDLE, message, 0xFFFF00, {x = 200, y = 20})
        end
    end
end

--announce impostors
function amongus.announce_impostors()
    local nb = #amongus.impostors
    local announce = ""
    if nb == 0 then
        announce = announce .. S("There are no impostors among us.")
    elseif nb == 1 then
        announce = announce .. S("There is 1 impostor among us.")
    else
        announce = announce .. S("There are @1 impostors among us.", nb)
    end
    for p_name, p in pairs(amongus.players) do
        if p.connected then
            display_temporary_hud(p.player, 5, POS_CENTER_MIDDLE, announce, 0xFFFF00, {x = 300, y = 20})
        end
    end
end

--announce ghost
function amongus.announce_ghost(player_name)
    if amongus.impostors_win() then
        return
    end
    local announce = S("You are now a ghost.") .. "\n" .. S("You can use fly and noclip modes.") .. "\n"
    if not amongus.is_impostor(player_name) and amongus.is_ghost(player_name) then
        announce = announce .. S("Finish your tasks to help your team!")
    end
    local player = nil
    if amongus.players[player_name] == nil then
        --player is a visitor
        player = minetest.get_player_by_name(player_name)
    elseif amongus.players[player_name].connected then
        player = amongus.players[player_name].player
    end
    if player ~= nil then
        display_temporary_hud(player, 5, POS_CENTER_MIDDLE, announce, 0xFFFF00, {x = 300, y = 60})
    end
end

--announce end of the game
function amongus.announce_end_game(message)
    for p_name, p in pairs(amongus.players) do
        if p.connected then
            display_temporary_hud(p.player, 5, POS_CENTER_MIDDLE, message, 0xFFFF00, {x = 260, y = 20})
        end
    end
end

--reset all meeting huds
function amongus.reset_meeting_huds()
    for _, hud in ipairs(amongus.meeting_huds) do
        local p = amongus.players[hud[1]]
        if p.connected then
            p.player:hud_remove(hud[2])
        end
    end
    amongus.meeting_huds = {}
end

--reset all task huds
function amongus.reset_task_huds()
    for _, hud in ipairs(amongus.tasks_huds) do
        local p = amongus.players[hud[1]]
        if p.connected then
            p.player:hud_remove(hud[2])
        end
    end
    amongus.tasks_huds = {}
end

--reset all impostor huds
function amongus.reset_impostor_huds()
    for _, hud in ipairs(amongus.impostors_huds_kill_cooldown) do
        local p = amongus.players[hud[1]]
        if p.connected then
            p.player:hud_remove(hud[2])
        end
    end
    amongus.impostors_huds_kill_cooldown = {}
    for _, hud in ipairs(amongus.impostors_huds) do
        local p = amongus.players[hud[1]]
        if p.connected then
            p.player:hud_remove(hud[2])
        end
    end
    amongus.impostors_huds = {}
end

--reset huds
function amongus.reset_huds()
    amongus.reset_impostor_huds()
    amongus.reset_task_huds()
    amongus.reset_meeting_huds()
end
