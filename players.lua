local BLOCK_GHOST = "mesecons_lightstone:lightstone_red_on"
local BLOCK_PLAYER = "mesecons_lightstone:lightstone_green_on"

--reset inventory of the user
local function reset_inventory(player)
    local inv = player:get_inventory()
    local tmain = {}
    for i = 1, 32 do
        tmain[i] = ItemStack("")
    end
    local tcraftpreview = {ItemStack("")}
    local tcraft = {}
    for i = 1, 9 do
        tcraft[i] = ItemStack("")
    end
    local tcraftresult = {ItemStack("")}
    inv:set_list("main", tmain)
    inv:set_list("craftpreview", tcraftpreview)
    inv:set_list("craft", tcraft)
    inv:set_list("craftresult", tcraftresult)
end

--define type of block for the player spawn pos
local function define_player_pos_block(player_name, pos)
    local block = BLOCK_PLAYER
    if player_name == nil then
        block = amongus.block_empty
    elseif amongus.is_ghost(player_name) or not amongus.players[player_name].connected then
        block = BLOCK_GHOST
    end
    minetest.set_node(vector.add(vector.add(amongus.get_spawn_pos(), pos), vector.new(0, -1, 0)), {name = block})
end

local function teleport_player_to_spawn(player, pos_corr)
    pos_corr = pos_corr or minetest.string_to_pos(amongus.dft_spawn_corr)
    player:set_pos(vector.add(amongus.get_spawn_pos(), pos_corr))
end

--define players
function amongus.set_players()
    for _, player in pairs(minetest.get_connected_players()) do
        amongus.add_player(player)
    end
end

--define privileges for the player
function amongus.set_privileges(player_name)
    local privs = minetest.get_player_privs(player_name)
    local priv = false
    if amongus.creative_mode then
        priv = true
    end
    privs.shout = true
    privs.interact = true
    privs.fly = priv
    privs.worldedit = priv
    privs.teleport = priv
    privs.noclip = priv
    privs.fast = priv
    privs.give = priv
    privs.home = priv
    minetest.set_player_privs(player_name, privs)
end

--define settings for player
function amongus.init_player(player)
    local player_name = player:get_player_name()
    --define privileges
    amongus.set_privileges(player_name)
    --teleport player so spawn
    local visitor = false
    if amongus.game_started then
        --player was registered into the game (reconnection)
        if amongus.players[player_name] ~= nil then
            amongus.players[player_name].connected = true
            amongus.players[player_name].player = player
            teleport_player_to_spawn(player, amongus.players[player_name].spawn_pos)
        else
            visitor = true
            teleport_player_to_spawn(player)
        end
    else
        teleport_player_to_spawn(player)
    end
    --change physics
    amongus.set_player_physics(player)
    --define admin
    amongus.check_first_player(player_name)
    --define random skin
    amongus.define_random_skin(player_name)
    --define inventory
    if amongus.creative_mode then
        player:hud_set_hotbar_image("gui_hotbar.png")
        player:hud_set_hotbar_itemcount(8)
    else
        player:hud_set_hotbar_image("gui_hotbar_1.png")
        player:hud_set_hotbar_itemcount(1)
        --empty inventory
        reset_inventory(player)
    end
    --check doors
    amongus.check_spawn_doors()
    --define as visitor
    if visitor then
        amongus.create_visitor(player_name)
    end
end

--define a random skin for the player
function amongus.define_random_skin(player_name)
    local SKIN_DEFAULT = "skin_AmongUs_invisible.png"
    local skin = SKIN_DEFAULT
    local keyset = {}
    local n = 0
    for k, v in pairs(wardrobe.skinNames) do
        n = n + 1
        keyset[n] = k
    end
    for sk, pname in pairs(amongus.skins) do
        if pname == player_name then
            --in case of reconnection
            wardrobe.changePlayerSkin(player_name, sk)
            return
        end
    end
    while amongus.skins[skin] ~= nil do
        skin = keyset[math.random(#keyset)]
    end
    amongus.skins[skin] = player_name
    wardrobe.changePlayerSkin(player_name, skin)
end

--teleport all players to spawn
function amongus.teleport_players_to_spawn()
    for _, player in ipairs(minetest.get_connected_players()) do
        if amongus.players[player:get_player_name()] ~= nil then
            teleport_player_to_spawn(player, amongus.players[player:get_player_name()].spawn_pos)
        else
            teleport_player_to_spawn(player)
        end
    end
end

--add a player to the game
function amongus.add_player(player)
    local player_name = player:get_player_name()
    for key, player_pos in ipairs(amongus.players_pos) do
        if player_pos.player == nil then
            --first empty position assigned to new user
            amongus.players_pos[key].player = player_name
            amongus.players[player_name] = {
                spawn_pos = player_pos.pos,
                impostor = false,
                ghost = false,
                connected = true,
                player = player
            }
            define_player_pos_block(player_name, player_pos.pos)
            teleport_player_to_spawn(player, player_pos.pos)
            return
        end
    end
    --no position left = more than maximum players
    amongus.create_visitor(player_name)
    teleport_player_to_spawn(player)
end

--define game admin
function amongus.check_first_player(player_name)
    if amongus.admin == nil then
        amongus.admin = player_name
        minetest.chat_send_all(player_name .. " is the game master")
    end
end

--create a new impostor
function amongus.create_impostor(player_name)
    local inv = amongus.players[player_name].player:get_inventory()
    inv:add_item("main", ItemStack("amongus:amongus_sword"))
    amongus.players[player_name].impostor = true
end

--reset impostors
function amongus.reset_impostors()
    --reset inventories for impostors
    for _, player_name in ipairs(amongus.impostors) do
        if amongus.players[player_name].connected then
            reset_inventory(amongus.players[player_name].player)
        end
    end
    --reset kill cooldown
    amongus.kill_current_cooldown = 0
end

--empty team lists
function amongus.reset_players()
    --reset huds
    amongus.reset_huds()
    --reset impostors
    amongus.reset_impostors()
    --remove corpses
    amongus.remove_corpses(true)
    --revive ghost
    for _, player_name in pairs(amongus.ghosts) do
        amongus.revive_ghost(player_name)
    end
    --reset player positions
    for _, player_pos in ipairs(amongus.players_pos) do
        player_pos.player = nil
        define_player_pos_block(player_pos.player, player_pos.pos)
    end
    --reset visitor skins
    for _, player in ipairs(minetest.get_connected_players()) do
        local player_name = player:get_player_name()
        if amongus.players[player_name] == nil then
            amongus.define_random_skin(player_name)
        end
    end
    --empty teams
    amongus.impostors = {}
    amongus.crew = {}
    amongus.players = {}
end

--dispatch players in teams
function amongus.build_teams()
    --get connected players
    local connected_players = {}
    for p_name, p in pairs(amongus.players) do
        if p.connected then
            table.insert(connected_players, p_name)
        end
    end
    local nb_players = #connected_players
    --define impostors
    local nb_impostors = amongus.impostors_ratio[nb_players - amongus.min_player + 1]
    local impostors = {}
    for i = 1, nb_impostors do
        local num = math.random(1, nb_players)
        while (#impostors == 1 and impostors[1] == connected_players[num]) do
            num = math.random(1, nb_players)
        end
        table.insert(impostors, connected_players[num])
        amongus.create_impostor(connected_players[num])
    end
    --define crew
    local crew = {}
    for p_name, p in pairs(amongus.players) do
        if p.connected and not amongus.is_impostor(p_name) then
            table.insert(crew, p_name)
        end
    end
    amongus.impostors = impostors
    amongus.crew = crew
    amongus.display_impostors()
    amongus.display_kill_cooldown()
    amongus.announce_impostors()
end

--remove corpses
function amongus.remove_corpses(force)
    force = force or false
    local list = amongus.corpses
    if force and #list == 0 then
        list = minetest.find_nodes_in_area(vector.new(-50, -50, -50), vector.new(50, 50, 50), "amongus:corpse")
    end
    for _, pos in ipairs(list) do
        minetest.set_node(pos, {name = "air"})
    end
end

--kill a player
function amongus.kill_player(player_name, no_bones)
    no_bones = no_bones or false
    amongus.create_ghost(player_name)
    if not no_bones then
        local pos = amongus.players[player_name].player:get_pos()
        minetest.set_node(pos, {name = "amongus:corpse"})
        table.insert(amongus.corpses, pos)
        local bone_meta = minetest.get_meta(pos)
        bone_meta:set_string("infotext", player_name)
    end
    amongus.check_end_game()
    amongus.start_kill_cooldown()
end

--create a ghost
function amongus.create_ghost(player_name)
    amongus.create_visitor(player_name)
    amongus.players[player_name].ghost = true
    table.insert(amongus.ghosts, player_name)
    define_player_pos_block(player_name, amongus.players[player_name].spawn_pos)
end

--create a visitor
function amongus.create_visitor(player_name)
    wardrobe.changePlayerSkin(player_name, "skin_AmongUs_invisible.png")
    local privs = minetest.get_player_privs(player_name)
    privs.fly = true
    privs.noclip = true
    minetest.set_player_privs(player_name, privs)
    amongus.announce_ghost(player_name)
end

--remove a ghost
function amongus.revive_ghost(player_name)
    amongus.define_random_skin(player_name)
    local privs = minetest.get_player_privs(player_name)
    privs.fly = nil
    privs.noclip = nil
    minetest.set_player_privs(player_name, privs)
    for key, name in ipairs(amongus.ghosts) do
        if player_name == name then
            amongus.ghosts[key] = nil
            amongus.players[player_name].ghost = false
        end
    end
    define_player_pos_block(player_name, amongus.players[player_name].spawn_pos)
end

--test if player is a ghost
function amongus.is_ghost(player_name)
    if amongus.players[player_name] == nil then
        --player is a visitor
        return true
    end
    return amongus.players[player_name].ghost
end

--return true if player is impostor
function amongus.is_impostor(player_name)
    if amongus.players[player_name] == nil then
        --player is a visitor
        return false
    end
    return amongus.players[player_name].impostor
end

--freeze or unfreeze all players
function amongus.set_freeze(freeze)
    amongus.freeze = freeze
    amongus.set_players_physics()
end

--define physics for all players
function amongus.set_players_physics()
    for _, player in ipairs(minetest.get_connected_players()) do
        amongus.set_player_physics(player)
    end
end

--set physics for the player
function amongus.set_player_physics(player)
    local speed = amongus.player_speed
    local jump = amongus.player_jump
    if amongus.freeze then
        speed = 0
        jump = 0
    end
    player:set_physics_override(
        {
            speed = speed,
            jump = jump,
            gravity = 1.0,
            sneak = false,
            new_move = false
        }
    )
end

--initialise all players
function amongus.init_players()
    --reinit players and pos
    amongus.players = {}
    for key, player_pos in ipairs(amongus.players_pos) do
        amongus.players_pos[key].player = nil
        define_player_pos_block(nil, player_pos.pos)
    end
    for _, player in ipairs(minetest.get_connected_players()) do
        teleport_player_to_spawn(player)
    end
end

--return true if a player is a crewmate
function amongus.is_crew(player_name)
    if amongus.players[player_name] == nil then
        --player is a visitor
        return false
    end
    return amongus.players[player_name].connected and not amongus.is_impostor(player_name)
end

--unregister a player (disconnection)
function amongus.leave_player(player_name)
    if amongus.players[player_name] ~= nil then
        amongus.create_ghost(player_name)
        amongus.remove_tasks(player_name)
        amongus.players[player_name].connected = false
        amongus.check_end_game()
    end
    if amongus.admin == player_name then
        --admin disconnected
        amongus.admin = ""
        if amongus.game_started then
            --game has started => first connected player
            for p_name, p in pairs(amongus.players) do
                if p.connected then
                    amongus.admin = p_name
                    break
                end
            end
        else
            --game not started => first connected player
            for _, p in ipairs(minetest.get_connected_players()) do
                local p_name = p:get_player_name()
                if p_name ~= player_name then
                    amongus.check_first_player(p_name)
                    break
                end
            end
        end
    end
end

minetest.register_node(
    "amongus:corpse",
    {
        description = "AmongUS corpse",
        paramtype2 = "facedir",
        tiles = {
            "amongus_corpse_top.png",
            "amongus_corpse.png"
        },
        inventory_image = "amongus_corpse.png",
        groups = {},
        on_rightclick = function(pos, node, player, itemstack)
            amongus.start_meeting(player:get_player_name(), "Corpse found")
        end
    }
)

--register player
minetest.register_on_joinplayer(
    function(player)
        amongus.init_player(player)
    end
)

--unregister player
minetest.register_on_leaveplayer(
    function(player)
        amongus.leave_player(player:get_player_name())
    end
)

--ghosts can only talk to ghosts
minetest.register_on_chat_message(
    function(name, message)
        if amongus.is_ghost(name) then
            for _, player_name in ipairs(amongus.ghosts) do
                minetest.chat_send_player(player_name, "[Ghost] " .. message)
            end
            return true
        end
    end
)
