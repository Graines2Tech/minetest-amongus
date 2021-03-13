local TASK_NAME = "artifacts"
local FORM_NAME = "amongus_task_" .. TASK_NAME
local KEY = FORM_NAME .. "_key"
local KEY_SELECTED = KEY .. "_selected"
local KEY_TOTAL = KEY .. "_total"
local KEY_OBJ = {
    "red1",
    "red2",
    "white1",
    "white2",
    "blue1",
    "blue2"
}
local KEY_NAME = KEY .. "_name"

local function showForm(player, pos)
    local playerName = player:get_player_name()
    if not playerName or playerName == "" then
        return
    end

    local posstr = minetest.pos_to_string(pos)
    local player_meta = player:get_meta()
    local selected = player_meta:get_string(KEY_SELECTED .. posstr)

    local formspec = {
        "formspec_version[4]",
        "size[9,6]",
        "style[box_blue;bgcolor=blue]",
        "style[box_white;bgcolor=white]",
        "style[box_red;bgcolor=red]",
        "button[0,0;3,3;box_blue;]",
        "button[3,0;3,3;box_white;]",
        "button[6,0;3,3;box_red;]"
    }
    for i, name in pairs(KEY_OBJ) do
        if name == selected then
            table.insert(formspec, "style[obj_" .. name .. ";bgcolor=yellow]")
        else
            table.insert(formspec, "style[obj_" .. name .. ";bgcolor=" .. name:sub(0, -2) .. "]")
        end
        local table_btn =
            table.concat(
            {
                "button[",
                player_meta:get_string(KEY .. name .. posstr),
                ";1,1;obj_",
                name,
                ";",
                name,
                "]"
            }
        )
        table.insert(formspec, table_btn)
    end
    return table.concat(formspec, "")
end

local initForm = function(player, pos)
    local posstr = minetest.pos_to_string(pos)
    local player_meta = player:get_meta()
    player_meta:set_int(KEY_TOTAL .. posstr, 0)
    for i, name in pairs(KEY_OBJ) do
        player_meta:set_string(
            KEY .. name .. posstr,
            table.concat(
                {
                    (math.random(1, 16)) / 2,
                    ",",
                    (math.random(7, 10)) / 2
                }
            )
        )
    end
end

local closeForm = function(pos, player, fields)
    local playerName = player:get_player_name()
    if not playerName or playerName == "" then
        return
    end

    local posstr = minetest.pos_to_string(pos)
    local player_meta = player:get_meta()
    local selected = player_meta:get_string(KEY_SELECTED .. posstr)

    if fields.box_red ~= nil then
        if selected == "red1" then
            player_meta:set_string(KEY .. selected .. posstr, "6.5,0.5")
            player_meta:set_int(KEY_TOTAL .. posstr, player_meta:get_int(KEY_TOTAL .. posstr) + 1)
        elseif selected == "red2" then
            player_meta:set_string(KEY .. selected .. posstr, "7.5,1.5")
            player_meta:set_int(KEY_TOTAL .. posstr, player_meta:get_int(KEY_TOTAL .. posstr) + 1)
        end
        player_meta:set_string(KEY_SELECTED .. posstr, "")
        minetest.update_form(playerName, showForm(player, pos))
    elseif fields.box_blue ~= nil then
        if selected == "blue1" then
            player_meta:set_string(KEY .. selected .. posstr, "0.5,0.5")
            player_meta:set_int(KEY_TOTAL .. posstr, player_meta:get_int(KEY_TOTAL .. posstr) + 1)
        elseif selected == "blue2" then
            player_meta:set_string(KEY .. selected .. posstr, "1.5,1.5")
            player_meta:set_int(KEY_TOTAL .. posstr, player_meta:get_int(KEY_TOTAL .. posstr) + 1)
        end
        player_meta:set_string(KEY_SELECTED .. posstr, "")
        minetest.update_form(playerName, showForm(player, pos))
    elseif fields.box_white ~= nil then
        if selected == "white1" then
            player_meta:set_string(KEY .. selected .. posstr, "3.5,0.5")
            player_meta:set_int(KEY_TOTAL .. posstr, player_meta:get_int(KEY_TOTAL .. posstr) + 1)
        elseif selected == "white2" then
            player_meta:set_string(KEY .. selected .. posstr, "4.5,1.5")
            player_meta:set_int(KEY_TOTAL .. posstr, player_meta:get_int(KEY_TOTAL .. posstr) + 1)
        end
        player_meta:set_string(KEY_SELECTED .. posstr, "")
        minetest.update_form(playerName, showForm(player, pos))
    elseif fields.quit == nil then
        for i, obj in pairs(fields) do
            player_meta:set_string(KEY_SELECTED .. posstr, obj)
        end
        minetest.update_form(playerName, showForm(player, pos))
    elseif fields.quit == minetest.FORMSPEC_SIGPROC then
        return
    end

    if player_meta:get_int(KEY_TOTAL .. posstr) == #KEY_OBJ then
        local node_meta = minetest.get_meta(pos)
        amongus.finish_task(playerName, node_meta:get_string(KEY_NAME))
        minetest.destroy_form(player)
    end
end

local onPlace = function(pos, name)
    local node_meta = minetest.get_meta(pos)
    node_meta:set_string(KEY_NAME, name)
end

amongus.register_task_node(TASK_NAME, {"amongus_task_" .. TASK_NAME .. ".png"}, initForm, showForm, closeForm, onPlace)
