local TASK_NAME = "counter"
local FORM_NAME = "amongus_task_" .. TASK_NAME
local KEY = FORM_NAME .. "_key"
local KEY_TYPE = KEY .. "_type"
local KEY_NAME = KEY .. "_name"

local function showForm(player, pos)
    local playerName = player:get_player_name()
    if not playerName or playerName == "" then
        return
    end

    local posstr = minetest.pos_to_string(pos)
    local player_meta = player:get_meta()
    local current = player_meta:get_int(KEY .. posstr)

    local node_meta = minetest.get_meta(pos)
    local keyType = node_meta:get_int(KEY_TYPE)

    local formspec = {
        "formspec_version[4]",
        "size[10,6]",
        "style_type[button;bgcolor=red;font_size=24]"
    }
    if current > 0 then
        for i = 1, current do
            table.insert(formspec, "style[" .. i .. ";bgcolor=orange]")
        end
    end

    if keyType == 2 then
        table.insert(formspec, "button[0,0;2,3;1;1]")
        table.insert(formspec, "button[2,0;2,3;7;7]")
        table.insert(formspec, "button[4,0;2,3;3;3]")
        table.insert(formspec, "button[6,0;2,3;9;9]")
        table.insert(formspec, "button[8,0;2,3;5;5]")
        table.insert(formspec, "button[0,3;2,3;6;6]")
        table.insert(formspec, "button[2,3;2,3;2;2]")
        table.insert(formspec, "button[4,3;2,3;8;8]")
        table.insert(formspec, "button[6,3;2,3;4;4]")
        table.insert(formspec, "button[8,3;2,3;10;10]")
    elseif keyType == 3 then
        table.insert(formspec, "button[0,0;2,3;7;7]")
        table.insert(formspec, "button[2,0;2,3;3;3]")
        table.insert(formspec, "button[4,0;2,3;9;9]")
        table.insert(formspec, "button[6,0;2,3;8;8]")
        table.insert(formspec, "button[8,0;2,3;5;5]")
        table.insert(formspec, "button[0,3;2,3;10;10]")
        table.insert(formspec, "button[2,3;2,3;6;6]")
        table.insert(formspec, "button[4,3;2,3;1;1]")
        table.insert(formspec, "button[6,3;2,3;4;4]")
        table.insert(formspec, "button[8,3;2,3;2;2]")
    elseif keyType == 4 then
        table.insert(formspec, "button[0,0;2,3;3;3]")
        table.insert(formspec, "button[2,0;2,3;10;10]")
        table.insert(formspec, "button[4,0;2,3;7;7]")
        table.insert(formspec, "button[6,0;2,3;4;4]")
        table.insert(formspec, "button[8,0;2,3;5;5]")
        table.insert(formspec, "button[0,3;2,3;9;9]")
        table.insert(formspec, "button[2,3;2,3;6;6]")
        table.insert(formspec, "button[4,3;2,3;8;8]")
        table.insert(formspec, "button[6,3;2,3;1;1]")
        table.insert(formspec, "button[8,3;2,3;2;2]")
    else
        table.insert(formspec, "button[0,0;2,3;2;2]")
        table.insert(formspec, "button[2,0;2,3;1;1]")
        table.insert(formspec, "button[4,0;2,3;8;8]")
        table.insert(formspec, "button[6,0;2,3;6;6]")
        table.insert(formspec, "button[8,0;2,3;9;9]")
        table.insert(formspec, "button[0,3;2,3;5;5]")
        table.insert(formspec, "button[2,3;2,3;4;4]")
        table.insert(formspec, "button[4,3;2,3;7;7]")
        table.insert(formspec, "button[6,3;2,3;10;10]")
        table.insert(formspec, "button[8,3;2,3;3;3]")
    end

    return table.concat(formspec, "")
end

local function initForm(player, pos)
end

local function closeForm(pos, player, fields)
    local playerName = player:get_player_name()
    if not playerName or playerName == "" then
        return
    end

    local posstr = minetest.pos_to_string(pos)
    local player_meta = player:get_meta()
    local current = player_meta:get_int(KEY .. posstr)

    for fieldName in pairs(fields) do
        if fieldName == "quit" then
            return
        end
        local fieldint = tonumber(fieldName)
        if fieldint == current + 1 then
            player_meta:set_int(KEY .. posstr, fieldint)
            if fieldint < 10 then
                local formspec = showForm(player, pos)
                minetest.update_form(playerName, formspec)
            else
                local node_meta = minetest.get_meta(pos)
                amongus.finish_task(playerName, node_meta:get_string(KEY_NAME))
                player_meta:set_int(KEY .. posstr, 0)
                minetest.destroy_form(playerName)
            end
        else
            player_meta:set_int(KEY .. posstr, 0)
            local formspec = showForm(player, pos)
            minetest.update_form(playerName, formspec)
        end
    end
end

local function onPlace(pos, name)
    local node_meta = minetest.get_meta(pos)
    node_meta:set_string(KEY_NAME, name)
    node_meta:set_int(KEY_TYPE, math.random(2, 5))
end

amongus.register_task_node(TASK_NAME, {"amongus_task_" .. TASK_NAME .. ".png"}, initForm, showForm, closeForm, onPlace)
