--test if kill is authorized
local function can_kill(impostor_name, target)
    if type(target) ~= "userdata" then
        return false
    end
    if amongus.kill_current_cooldown > 0 then
        return false
    end
    if not amongus.is_impostor(impostor_name) then
        minetest.chat_send_player(impostor_name, "How do you get this weapon? Only impostors are skilled to use it…")
        return false
    end
    if amongus.is_ghost(impostor_name) then
        minetest.chat_send_player(impostor_name, "You're dead, you cannot kill people any more…")
        return false
    end
    if amongus.meeting then
        minetest.chat_send_player(impostor_name, "Seriously? During a meeting?")
        return false
    end
    if amongus.is_impostor(target) then
        minetest.chat_send_player(impostor_name, "Seriously? You wanna kill your partner?")
        return false
    end
    local imp_pos = amongus.players[impostor_name].player:get_pos()
    local target_pos = target:get_pos()
    local distance = vector.distance(target_pos, imp_pos)
    if distance > amongus.kill_distance then
        minetest.chat_send_player(impostor_name, "You must be closer…")
        return false
    end
    if not amongus.game_started then
        --this case should not occur as impostors are only selected when the game starts
        minetest.chat_send_player(impostor_name, "Game has not started yet…")
        return false
    end
    return true
end

--decrement kill cooldown
function amongus.decrement_kill_cooldown()
    if amongus.kill_current_cooldown < 0 then
        amongus.kill_current_cooldown = 0
    end
    --do not decrement if game is not started or if meeting is launched or if cooldown already passed
    if not amongus.game_started or amongus.meeting or amongus.kill_current_cooldown == 0 then
        return
    end
    minetest.after(
        1,
        function()
            amongus.kill_current_cooldown = amongus.kill_current_cooldown - 1
            amongus.refresh_kill_cooldown()
            amongus.decrement_kill_cooldown()
        end
    )
end

--starts the kill cooldown
function amongus.start_kill_cooldown()
    if amongus.kill_current_cooldown == 0 then
        amongus.kill_current_cooldown = amongus.kill_cooldown
    end
    amongus.decrement_kill_cooldown()
end

minetest.register_tool(
    "amongus:amongus_sword",
    {
        description = "Among us Sword",
        inventory_image = "amongus_sword.png",
        groups = {not_in_creative_inventory = 1},
        tool_capabilities = {
            full_punch_interval = 30,
            damage_groups = {fleshy = -1}
        },
        on_use = function(itemstack, user, pointedthing)
            if pointedthing == nil then
                return
            end
            local pointedobj = pointedthing.ref
            if pointedobj == nil then
                return
            end

            if not can_kill(user:get_player_name(), pointedobj) then
                return
            end

            local target_name = pointedobj:get_player_name()

            amongus.kill_player(target_name)
        end
    }
)
