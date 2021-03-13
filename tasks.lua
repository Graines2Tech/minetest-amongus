local MOD_NAME = minetest.get_current_modname()
local MOD_PATH = minetest.get_modpath(MOD_NAME)
local WORLD_PATH = minetest.get_worldpath()
local TASKS_FILE = WORLD_PATH .. "/tasks.txt"

--check if the player has been assigned the task
local function has_task(player_name, pos)
    if amongus.player_tasks[player_name] then
        for key, task in ipairs(amongus.player_tasks[player_name]) do
            if vector.equals(task.pos, pos) then
                return true
            end
        end
    end
    return false
end

--save tasks in file
local function save_tasks()
    local file = io.open(TASKS_FILE, "w")
    if not file then
        error("Couldn't write file '" .. TASKS_FILE .. "'")
    end
    for i, task in pairs(amongus.tasks) do
        file:write(task["name"], "|", minetest.pos_to_string(task["pos"]), "\n")
    end
    file:close()
end

--load tasks from file
local function read_tasks()
    local file = io.open(TASKS_FILE, "r")
    if file then
        for line in file:lines() do
            if line ~= "" then
                local pos = string.find(line, "|")
                table.insert(
                    amongus.tasks,
                    {
                        name = string.sub(line, 0, pos - 1),
                        pos = minetest.string_to_pos(string.sub(line, pos + 1))
                    }
                )
            end
        end
        file:close()
    end
end

read_tasks()

--dispatch tasks to players
function amongus.dispatch_tasks()
    local nb_tasks = amongus.tasks_number
    if nb_tasks > #amongus.tasks then
        nb_tasks = #amongus.tasks
    end
    for p_name, p in pairs(amongus.players) do
        if p.connected then
            local tmp_tasks = {}
            local selected = {}
            for i = 1, nb_tasks do
                local tmp = math.random(1, #amongus.tasks)
                while selected[tmp] ~= nil do
                    tmp = math.random(1, #amongus.tasks)
                end
                selected[tmp] = tmp
                table.insert(tmp_tasks, amongus.tasks[tmp])
            end
            amongus.player_tasks[p_name] = tmp_tasks
            amongus.display_tasks(p_name)
        end
    end
    amongus.update_tasks_bar()
end

--reset tasks for all players
function amongus.reset_tasks()
    for p_name, p in pairs(amongus.players) do
        amongus.hide_tasks(p_name)
        amongus.player_tasks[p_name] = nil
        amongus.player_finished_tasks[p_name] = nil
    end
end

--calculate tasks completion
function amongus.calculate_task_completion()
    local nb_tasks = 0
    local nb_comp = 0
    for player, tasks in pairs(amongus.player_tasks) do
        nb_tasks = nb_tasks + #tasks
    end
    for player, tasks in pairs(amongus.player_finished_tasks) do
        for _ in pairs(tasks) do
            nb_comp = nb_comp + 1
        end
    end
    amongus.task_completion = nb_comp / nb_tasks
end

--remove all tasks for the player
function amongus.remove_tasks(player_name)
    amongus.player_tasks[player_name] = nil
    amongus.player_finished_tasks[player_name] = {}
    amongus.calculate_task_completion()
    amongus.update_tasks_bar()
end

--register a task
function amongus.register_task(task_name, task_pos)
    task_name = task_name:gsub("|", "-")
    local existing = {}
    for key, task in ipairs(amongus.tasks) do
        existing[task.name] = task.pos
    end
    --check for duplicate name
    local i = 1
    local task_name2 = task_name
    while existing[task_name2] ~= nil do
        i = i + 1
        task_name2 = task_name .. " " .. tostring(i)
    end
    table.insert(
        amongus.tasks,
        {
            name = task_name2,
            pos = task_pos
        }
    )
    save_tasks()
    return task_name2
end

--unregister a task
function amongus.unregister_task(task_pos)
    local tmp_tasks = {}
    for i, task in pairs(amongus.tasks) do
        if not vector.equals(task["pos"], task_pos) then
            table.insert(tmp_tasks, task)
        end
    end
    amongus.tasks = tmp_tasks
    save_tasks()
end

--register a task node
function amongus.register_task_node(name, tiles, initForm, showForm, closeForm, onPlace)
    minetest.register_node(
        "amongus:task_" .. name,
        {
            description = "AmongUS " .. name .. " task",
            paramtype2 = "facedir",
            tiles = tiles,
            inventory_image = tiles[#tiles],
            groups = {choppy = 3, oddly_breakable_by_hand = 2, flammable = 3},
            on_open = function(pos, player, fields)
                local playerpos = player:get_pos()
                local distance = vector.distance(pos, playerpos)
                local player_name = player:get_player_name()
                if not amongus.game_started then
                    minetest.chat_send_player(player_name, "Game has not started yet…")
                    return nil
                end
                if amongus.meeting then
                    minetest.chat_send_player(player_name, "You cannot do tasks during meetings.")
                    return nil
                end
                if not has_task(player_name, pos) then
                    return nil
                end
                if distance > amongus.task_distance then
                    minetest.chat_send_player(player_name, "You are too far from the task.")
                    return nil
                end
                if amongus.is_impostor(player_name) then
                    minetest.chat_send_player(player_name, "Just fake it!")
                    return nil
                end
                local str_pos = minetest.pos_to_string(pos)
                if
                    amongus.player_finished_tasks[player_name] == nil or
                        amongus.player_finished_tasks[player_name][str_pos] == nil
                 then
                    initForm(player, pos)
                    return showForm(player, pos)
                end
                return nil
            end,
            on_close = closeForm,
            after_place_node = function(pos, placer, itemstack, pointed_thing)
                local real_name = amongus.register_task(name, pos)
                onPlace(pos, real_name)
            end,
            after_destruct = function(pos, oldnode)
                amongus.unregister_task(pos)
            end
        }
    )
end

--finish a task for a player
function amongus.finish_task(player_name, task_name)
    if amongus.player_finished_tasks[player_name] == nil then
        amongus.player_finished_tasks[player_name] = {}
    end
    for _, task in ipairs(amongus.tasks) do
        if task.name == task_name then
            amongus.player_finished_tasks[player_name][task.pos] = task_name
        end
    end
    amongus.update_task(player_name, task_name)
    amongus.calculate_task_completion()
    amongus.update_tasks_bar()
    amongus.check_end_game()
end

-- load tasks files
dofile(MOD_PATH .. "/tasks/counter.lua")
dofile(MOD_PATH .. "/tasks/artifacts.lua")
dofile(MOD_PATH .. "/tasks/questions.lua")
dofile(MOD_PATH .. "/tasks/download.lua")
dofile(MOD_PATH .. "/tasks/temperature.lua")
