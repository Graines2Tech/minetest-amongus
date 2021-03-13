local WORLD_PATH = minetest.get_worldpath()
local SPAWN_FILE = WORLD_PATH .. "/spawn.txt"
local START_FILE = WORLD_PATH .. "/start.txt"

local function save_spawn()
    local file = io.open(SPAWN_FILE, "w")
    if not file then
        error("Couldn't write file '" .. SPAWN_FILE .. "'")
    end
    if amongus.spawn ~= nil then
        file:write(amongus.spawn)
    end
    file:close()
end

local function save_start()
    local file = io.open(START_FILE, "w")
    if not file then
        error("Couldn't write file '" .. START_FILE .. "'")
    end
    if amongus.start ~= nil then
        file:write(amongus.start)
    end
    file:close()
end

local function read_spawn()
    local file = io.open(SPAWN_FILE, "r")
    if file then
        for line in file:lines() do
            amongus.spawn = line
        end
        file:close()
    end
end

local function read_start()
    local file = io.open(START_FILE, "r")
    if file then
        for line in file:lines() do
            amongus.start = line
        end
        file:close()
    end
end

read_spawn()
read_start()

--return true if impostors wins
function amongus.impostors_win()
    local nb_imp = 0
    local nb_crew = 0
    for p_name, p in pairs(amongus.players) do
        if not amongus.is_ghost(p_name) then
            if amongus.is_impostor(p_name) then
                nb_imp = nb_imp + 1
            elseif amongus.is_crew(p_name) then
                nb_crew = nb_crew + 1
            end
        end
    end
    return nb_imp >= nb_crew
end

--return true if crew wins
function amongus.crew_win()
    local nb_impostors = 0
    if amongus.task_completion == 1 then
        --all tasks finished
        return true
    end
    for _, impostor in ipairs(amongus.impostors) do
        if not amongus.players[impostor].ghost then
            --one impostor is still alive
            return false
        end
    end
    --tasks not finished but no impostors alive
    return true
end

--world initialisation
function amongus.init()
    minetest.chat_send_all("Game has not started yet, please wait")
    minetest.set_timeofday(0)
    amongus.init_players()
    amongus.close_spawn_doors()
    amongus.teleport_players_to_spawn()
    amongus.reset_players()
end

--check if game is finished
function amongus.check_end_game()
    local message = ""
    if amongus.impostors_win() then
        message = "Impostors win."
    end
    if amongus.crew_win() then
        message = "Crewmates win."
    end
    if message ~= "" then
        amongus.terminate_game(message)
    end
end

--check spawn doors
function amongus.check_spawn_doors()
    if not amongus.game_started or amongus.meeting then
        amongus.close_spawn_doors()
    else
        amongus.open_spawn_doors()
    end
end

--close spawn doors
function amongus.close_spawn_doors()
    local pos = minetest.string_to_pos(amongus.start)
    if pos ~= nil then
        local node = minetest.get_node(pos)
        if node.name == "ignore" then
            minetest.get_voxel_manip():read_from_map(pos, pos)
            node = minetest.get_node(pos)
        end
        if node.name == "amongus:start_on" then
            if mesecon.flipstate(pos, node) == "off" then
                mesecon.receptor_off(pos, mesecon.rules.buttonlike_get(node))
            end
        elseif node.name ~= "amongus:start_off" then
            amongus.start = nil
            save_start()
        end
    end
end

--open spawn doors
function amongus.open_spawn_doors()
    local pos = minetest.string_to_pos(amongus.start)
    if pos ~= nil then
        local node = minetest.get_node(pos)
        if node.name == "ignore" then
            minetest.get_voxel_manip():read_from_map(pos, pos)
            node = minetest.get_node(pos)
        end
        if node.name == "amongus:start_off" then
            if mesecon.flipstate(pos, node) == "on" then
                mesecon.receptor_on(pos, mesecon.rules.buttonlike_get(node))
            end
        elseif node.name ~= "amongus:start_on" then
            amongus.start = nil
            save_start()
        end
    end
end

--start amongus game
function amongus.start_game()
    amongus.set_freeze(true)
    amongus.set_players()
    amongus.teleport_players_to_spawn()
    amongus.build_teams()
    amongus.dispatch_tasks()
    amongus.open_spawn_doors()
    amongus.game_started = true
    minetest.after(
        5,
        function()
            amongus.set_freeze(false)
            amongus.start_kill_cooldown()
            amongus.start_emergency_cooldown()
        end
    )
end

--terminate amongus game
function amongus.terminate_game(message)
    amongus.set_freeze(true)
    amongus.game_started = false
    amongus.teleport_players_to_spawn()
    amongus.close_spawn_doors()
    amongus.reset_tasks()
    amongus.announce_end_game(message)
    amongus.reset_players()
    minetest.after(
        5,
        function()
            amongus.set_freeze(false)
        end
    )
end

local function set_spawn_floor(pos, level, create)
    create = create or false
    local top_block = "air"
    local floor_block = "air"
    local floor_player = "air"
    if create then
        if level == 1 then
            top_block = "amongus:emergency_btn"
        elseif level == -1 then
            floor_block = "default:silver_sandstone_block"
            floor_player = amongus.block_empty
        end
    end
    minetest.set_node(vector.add(pos, vector.new(-1, level, -3)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(0, level, -3)), {name = floor_player})
    minetest.set_node(vector.add(pos, vector.new(1, level, -3)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(-2, level, -2)), {name = floor_player})
    minetest.set_node(vector.add(pos, vector.new(-1, level, -2)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(0, level, -2)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(1, level, -2)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(2, level, -2)), {name = floor_player})
    minetest.set_node(vector.add(pos, vector.new(-3, level, -1)), {name = floor_player})
    minetest.set_node(vector.add(pos, vector.new(-2, level, -1)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(-1, level, -1)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(0, level, -1)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(1, level, -1)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(2, level, -1)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(3, level, -1)), {name = floor_player})
    minetest.set_node(vector.add(pos, vector.new(-3, level, 0)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(-2, level, 0)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(-1, level, 0)), {name = floor_block})
    --spawn block here
    if level == 1 then
        --just above spawn block
        minetest.set_node(vector.add(pos, vector.new(0, level, 0)), {name = top_block})
    elseif level ~= 0 then
        minetest.set_node(vector.add(pos, vector.new(0, level, 0)), {name = floor_block})
    end
    minetest.set_node(vector.add(pos, vector.new(1, level, 0)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(2, level, 0)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(3, level, 0)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(-3, level, 1)), {name = floor_player})
    minetest.set_node(vector.add(pos, vector.new(-2, level, 1)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(-1, level, 1)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(0, level, 1)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(1, level, 1)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(2, level, 1)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(3, level, 1)), {name = floor_player})
    minetest.set_node(vector.add(pos, vector.new(-2, level, 2)), {name = floor_player})
    minetest.set_node(vector.add(pos, vector.new(-1, level, 2)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(0, level, 2)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(1, level, 2)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(2, level, 2)), {name = floor_player})
    minetest.set_node(vector.add(pos, vector.new(-1, level, 3)), {name = floor_block})
    minetest.set_node(vector.add(pos, vector.new(0, level, 3)), {name = floor_player})
    minetest.set_node(vector.add(pos, vector.new(1, level, 3)), {name = floor_block})
end

function amongus.get_spawn_pos()
    if amongus.spawn == nil then
        return vector.new(0, 0, 0)
    else
        return minetest.string_to_pos(amongus.spawn)
    end
end

--decrement emergency cooldown
function amongus.decrement_emergency_cooldown()
    --do not decrement if game is not started or if meeting is launched or if cooldown already passed
    if not amongus.game_started or amongus.meeting or amongus.emergency_current_cooldown == 0 then
        return
    end
    minetest.after(
        1,
        function()
            amongus.emergency_current_cooldown = amongus.emergency_current_cooldown - 1
            amongus.decrement_emergency_cooldown()
        end
    )
end

--starts the emergency cooldown
function amongus.start_emergency_cooldown()
    if amongus.emergency_current_cooldown == 0 then
        amongus.emergency_current_cooldown = amongus.emergency_cooldown
    end
    amongus.decrement_emergency_cooldown()
end

--action when right-clicking on emergency button or spawn block
local function spawn_action(pos, node, player)
    local player_name = player:get_player_name()
    if amongus.meeting then
        --meeting launched => open meeting form
        amongus.display_meeting_form(player_name)
    elseif amongus.game_started and not amongus.is_ghost(player_name) then
        --game started
        if amongus.emergency_current_cooldown > 0 then
            --emergency delay not over
            minetest.chat_send_player(player_name, "Emergency button will be available in "..amongus.emergency_current_cooldown.."s.")
            return
        end
        amongus.emergency_current_cooldown = 0
        amongus.start_meeting(player_name, "Emergency")
    end
end

minetest.register_node(
    "amongus:spawn",
    {
        description = "AmongUS spawn",
        paramtype2 = "facedir",
        tiles = {
            "amongus_spawn.png"
        },
        inventory_image = "amongus_spawn.png",
        paramtype = "light",
        light_source = minetest.LIGHT_MAX,
        groups = {choppy = 3, oddly_breakable_by_hand = 2, flammable = 3},
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            --remove old spawn
            if amongus.spawn ~= nil then
                minetest.set_node(minetest.string_to_pos(amongus.spawn), {name = "air"})
            end
            --define spot as spawn point
            amongus.spawn = minetest.pos_to_string(pos)
            save_spawn()
            --remove all blocks around
            set_spawn_floor(pos, 0)
            --remove all blocks up
            set_spawn_floor(pos, 1, true)
            --place floor
            set_spawn_floor(pos, -1, true)
            amongus.init_players()
        end,
        after_destruct = function(pos, oldnode)
            --remove all blocks around
            set_spawn_floor(pos, 0)
            --remove all blocks up
            set_spawn_floor(pos, 1)
            --remove floor
            set_spawn_floor(pos, -1)
            amongus.spawn = nil
            save_spawn()
        end,
        on_rightclick = spawn_action
    }
)

mesecon.register_node(
    "amongus:start",
    {
        description = "AmongUS start block",
        inventory_image = "amongus_start_face_on.png",
        paramtype2 = "facedir",
        is_ground_content = false,
        sunlight_propagates = true,
        groups = {choppy = 3, oddly_breakable_by_hand = 2, flammable = 3},
        after_place_node = function(pos)
            --remove old start
            if amongus.start ~= nil then
                minetest.set_node(minetest.string_to_pos(amongus.start), {name = "air"})
            end
            --define spot as spawn point
            amongus.start = minetest.pos_to_string(pos)
            save_start()
            minetest.get_node_timer(pos):start(mesecon.setting("pplate_interval", 0.1))
        end,
        after_destruct = function(pos, oldnode)
            amongus.start = nil
            save_start()
        end,
        on_blast = mesecon.on_blastnode,
        on_rightclick = function(pos, node, player, itemstack)
            local player_name = player:get_player_name()
            if player_name ~= amongus.admin then
                minetest.chat_send_all("Only " .. amongus.admin .. " can start the game.")
                return
            end
            if not amongus.game_started then
                amongus.start_game()
            else
                if amongus.creative_mode then
                    amongus.terminate_game(amongus.admin .. " ends the game.")
                end
            end
            return itemstack
        end
    },
    {
        tiles = {
            "amongus_start_other.png",
            "amongus_start_other.png",
            "amongus_start_other.png",
            "amongus_start_other.png",
            "amongus_start_other.png",
            "amongus_start_face_off.png"
        },
        on_rotate = mesecon.buttonlike_onrotate,
        mesecons = {
            receptor = {
                rules = mesecon.rules.buttonlike_get,
                state = mesecon.state.off
            }
        },
        groups = {dig_immediate = 2, mesecon_needs_receiver = 1}
    },
    {
        tiles = {
            "amongus_start_other.png",
            "amongus_start_other.png",
            "amongus_start_other.png",
            "amongus_start_other.png",
            "amongus_start_other.png",
            "amongus_start_face_on.png"
        },
        on_rotate = false,
        mesecons = {
            receptor = {
                rules = mesecon.rules.buttonlike_get,
                state = mesecon.state.on
            }
        },
        groups = {dig_immediate = 2, mesecon_needs_receiver = 1, not_in_creative_inventory = 1}
    }
)

minetest.register_node(
    "amongus:emergency_btn",
    {
        description = "AmongUS emergency button",
        tiles = {
            "amongus_emergency-btn_up.png",
            "amongus_emergency-btn_down.png",
            "amongus_emergency-btn_side.png",
            "amongus_emergency-btn_side.png",
            "amongus_emergency-btn_side.png",
            "amongus_emergency-btn_side.png"
        },
        inventory_image = "amongus_emergency-btn_up.png",
        paramtype = "light",
        light_source = minetest.LIGHT_MAX,
        groups = {dig_immediate = 2, not_in_creative_inventory = 1},
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {
                {-0.5000, -0.5000, -0.5000, 0.5000, -0.4375, 0.5000},
                {-0.1250, -0.4375, -0.2500, 0.1250, -0.3125, 0.2500},
                {-0.2500, -0.4375, -0.1250, 0.2500, -0.3125, 0.1250},
                {-0.1875, -0.4375, -0.1875, 0.1875, -0.3125, 0.1875},
                {-0.1875, -0.3125, -0.06250, 0.1875, -0.2500, 0.06250},
                {-0.06250, -0.3125, -0.1875, 0.06250, -0.2500, 0.1875},
                {-0.1250, -0.3125, -0.1250, 0.1250, -0.2500, 0.1250},
                {-0.06250, -0.2500, -0.06250, 0.06250, -0.1875, 0.06250}
            }
        },
        on_rightclick = spawn_action
    }
)

--init game at launch
minetest.after(
    0,
    function()
        amongus.init()
    end
)
