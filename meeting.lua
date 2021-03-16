local FORM_NAME = "amongus_meeting"
local KEY = FORM_NAME .. "_key"
local KEY_HOST = KEY .. "_host"
local KEY_REASON = KEY .. "_reason"

--show voting form for meeting
local showForm = function(player_name)
    local node_meta = minetest.get_meta(minetest.string_to_pos(amongus.spawn))
    local hostName = node_meta:get_string(KEY_HOST)
    local reason = node_meta:get_string(KEY_REASON)

    local formspec = {
        "formspec_version[4]",
        "size[8.5,8]",
        "label[2,0.5;Meeting by " .. hostName .. " (" .. reason .. ")]"
    }

    local ghost = amongus.is_ghost(player_name)

    local p = amongus.players[player_name]
    local target = ""
    if p ~= nil and p.connected then
        local player_meta = p.player:get_meta()
        target = player_meta:get_string(KEY)
    end

    local l = 0
    local c = 0
    local spacer = 0.5
    local top = 1.5
    local length = 3
    local length2 = length + spacer
    local height = 1
    local height2 = height + spacer
    local size = dump(length) .. "," .. dump(height)
    for p_name, p in pairs(amongus.players) do
        local pos = dump(spacer + c * length2) .. "," .. dump(top + l * height2)
        if ghost or p.ghost then
            table.insert(formspec, "label[" .. pos .. ";" .. p_name .. "]")
        else
            if p_name == target then
                table.insert(formspec, "style_type[button;bgcolor=green]")
            else
                table.insert(formspec, "style_type[button;bgcolor=red]")
            end
            table.insert(formspec, "button[" .. pos .. ";" .. size .. ";target;" .. p_name .. "]")
            local pmeta = p.player:get_meta()
            if pmeta:get_string(KEY) ~= "" then
                local pos = dump(length2 + c * length2) .. "," .. dump(height2 + l * height2)
                table.insert(formspec, "label[" .. pos .. ";*]")
            end
        end
        if c % 2 == 0 then
            c = c + 1
        else
            l = l + 1
            c = 0
        end
    end

    return table.concat(formspec, "")
end

--perform voting form action
local closeForm = function(state, player, fields)
    local player_name = player:get_player_name()
    if not player_name or player_name == "" then
        return
    end

    local player_meta = player:get_meta()

    if fields.quit == minetest.FORMSPEC_SIGEXIT then
        return
    elseif fields.quit == minetest.FORMSPEC_SIGPROC then
        return
    elseif fields.target ~= nil then
        local current = player_meta:get_string(KEY)
        if fields.target == current then
            player_meta:set_string(KEY, "")
        else
            player_meta:set_string(KEY, fields.target)
        end
        minetest.update_form(player_name, showForm(player_name))
        amongus.check_end_votation()
    end
end

--reinitialize the voting block
function amongus.reinit_meeting_node(host_name, reason)
    local node_meta = minetest.get_meta(minetest.string_to_pos(amongus.spawn))
    node_meta:set_string(KEY_HOST, host_name)
    node_meta:set_string(KEY_REASON, reason)
end

--reinitialize meeting for the player
function amongus.reinit_meeting(player)
    local player_meta = player:get_meta()
    player_meta:set_string(KEY, "")
end

--display voting form for a player
function amongus.display_meeting_form(player_name)
    minetest.create_form(nil, player_name, showForm(player_name), closeForm)
end

--check if the votation is finished
function amongus.check_end_votation(force)
    force = force or false
    local players = amongus.players
    local nb_voters = 0
    local nb_vote = 0
    local votes = {}
    for p_name, p in pairs(players) do
        if not p.ghost then
            nb_voters = nb_voters + 1
            local player_meta = p.player:get_meta()
            local target = player_meta:get_string(KEY)
            if votes[target] == nil then
                votes[target] = 1
            else
                votes[target] = votes[target] + 1
            end
            if target ~= "" then
                nb_vote = nb_vote + 1
            end
        end
    end
    if force or nb_voters == nb_vote then
        for p_name, p in pairs(players) do
            amongus.reinit_meeting(p.player)
            minetest.destroy_form(p_name)
        end
        local winner = ""
        local winner_nb = 0
        local equals = false
        for name, nb in pairs(votes) do
            if nb > winner_nb then
                winner = name
                winner_nb = nb
                equals = false
            elseif nb == winner_nb then
                equals = true
            end
        end
        local message = ""
        if equals then
            message = "No one was ejected (tie)."
            winner = ""
        elseif winner == "" then
            message = "No one was ejected (skipped)."
        else
            message = winner .. " has been ejected."
            amongus.kill_player(winner, true)
        end
        amongus.end_meeting()
        amongus.announce_end_meeting(message)
        minetest.after(
            5,
            function()
                amongus.set_freeze(false)
            end
        )
    end
end

--start a meeting
function amongus.start_meeting(host_name, reason)
    amongus.meeting = true
    amongus.set_freeze(true)
    amongus.close_spawn_doors()
    amongus.teleport_players_to_spawn()
    amongus.remove_corpses()
    amongus.reinit_meeting_node(host_name, reason)
    for p_name, p in pairs(amongus.players) do
        --close current opened form
        minetest.destroy_form(p_name)
        amongus.reinit_meeting(p.player)
    end
    amongus.announce_meeting()
end

--end a meeting
function amongus.end_meeting()
    amongus.meeting = false
    amongus.open_spawn_doors()
    amongus.start_kill_cooldown()
    amongus.start_emergency_cooldown()
    amongus.check_end_game()
end
