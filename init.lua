local modpath = minetest.get_modpath("amongus")

amongus = {
        --player speed during the game
        player_speed = 2.0,
        --player jump during the game
        player_jump = 0.5,
        --number of tasks distributed at each player
        tasks_number = 3,
        --minimum number of players to start the game
        min_player = 1,
        --maximum distance to perform a kill
        kill_distance = 2,
        --maximum distance to do a task
        task_distance = 2,
        --number of impostors depending on the number of players ; size should be the same as players_pos
        impostors_ratio = {0, 1, 1, 1, 1, 1, 2, 2, 2, 2},
        --spawn position of players {player = <player_name>, pos = <minetest position>} ; size should be the same as impostors_ratio
        players_pos = {
                {player = nil, pos = vector.new(0, 0, -3)},
                {player = nil, pos = vector.new(-2, 0, -2)},
                {player = nil, pos = vector.new(2, 0, -2)},
                {player = nil, pos = vector.new(-3, 0, -1)},
                {player = nil, pos = vector.new(3, 0, -1)},
                {player = nil, pos = vector.new(-3, 0, 1)},
                {player = nil, pos = vector.new(3, 0, 1)},
                {player = nil, pos = vector.new(-2, 0, 2)},
                {player = nil, pos = vector.new(2, 0, 2)},
                {player = nil, pos = vector.new(0, 0, 3)}
        },
        --indicator for game in progress
        game_started = false,
        --indicator for meeting in progress
        meeting = false,
        --maximum duration of a meeting in seconds
        meeting_delay = 45,
        --maximum waiting time in seconds before being allowed to perform a kill
        kill_cooldown = 15,
        --current waiting time in seconds before being allowed to perform a kill
        kill_current_cooldown = 0,
        --maximum waiting time in seconds before being allowed to push emergency button
        emergency_cooldown = 15,
        --current waiting time in seconds before being allowed to push emergency button
        emergency_current_cooldown = 0,
        --indicator of players being freezed
        freeze = false,
        --player_name of the administator of the game
        admin = nil,
        --minetest string position of the spawn block
        spawn = nil,
        --minetest string position of the start block
        start = nil,
        --list of players {<player_name> = {spawn_pos,impostor,ghost,connected,player}}
        players = {},
        --list of impostors {<player_name>}
        impostors = {},
        --list of huds for impostors {{<player_name>,<player_hud_id>}}
        impostors_huds = {},
        --list of specific kill colldown huds for impostors {{<player_name>,<player_hud_id>}}
        impostors_huds_kill_cooldown = {},
        --list of huds for players' tasks {{<player_name>,<player_hud_id>}}
        tasks_huds = {},
        --list of huds for meetings {{<player_name>,<player_hud_id>}}
        meeting_huds = {},
        --list of skins used by players {<skin_name>=<player_name>}
        skins = {},
        --list of available tasks in the map {{name=<task_name>,pos=<minetest_string_task_position>}}
        tasks = {},
        --list of distributed task for each player {<player_name>={{name=<task_name>,pos=<minetest_string_task_position>}}}
        player_tasks = {},
        --list of finished tasks for each player {<player_name>={<minetest_string_task_position>=<task_name>}}
        player_finished_tasks = {},
        --task completion, between 0 (no task finished) and 1 (all distributed tasks finished)
        task_completion = 0,
        --list of positions of the corpses {<minetest_position>}
        corpses = {},
        --name of block for players empty position
        block_empty = "mesecons_lightstone:lightstone_gray_off",
        --default spawn correction
        dft_spawn_corr = minetest.pos_to_string(vector.new(1, 0, 0))
}
amongus.creative_mode = minetest.setting_getbool("creative_mode")
amongus.kill_current_cooldown = amongus.kill_cooldown
amongus.emergency_current_cooldown = amongus.emergency_cooldown

-- load files
dofile(modpath .. "/huds.lua")
dofile(modpath .. "/weapon.lua")
dofile(modpath .. "/skin.lua")
dofile(modpath .. "/players.lua")
dofile(modpath .. "/tasks.lua")
dofile(modpath .. "/meeting.lua")
dofile(modpath .. "/game.lua")
dofile(modpath .. "/doors.lua")

amongus.skins[amongus.get_default_skin_name()] = "Admin"

minetest.register_chatcommand(
        "test",
        {
                params = "",
                description = "Test",
                func = function(name, param)
                        local player = minetest.get_player_by_name(name)
                        if not player then
                                return false, "Player not found"
                        end
                        return true, "Done."
                end
        }
)
