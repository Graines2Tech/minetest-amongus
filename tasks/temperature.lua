local TASK_NAME = "temperature"
local FORM_NAME = "amongus_task_" .. TASK_NAME
local KEY = FORM_NAME .. "_key"
local KEY_TARGET = KEY .. "_target"
local KEY_NAME = KEY .. "_name"

local function showForm(player, pos)
    local playerName = player:get_player_name()
    if not playerName or playerName == "" then
        return
    end

    local posstr = minetest.pos_to_string(pos)
    local player_meta = player:get_meta()
    local current = player_meta:get_int(KEY .. posstr)
    local target = player_meta:get_int(KEY_TARGET .. posstr)

    local formspec = {
        "formspec_version[4]",
        "size[10,6]",
        "box[0.5,0.5;9,5;orange]",
        "style_type[button;bgcolor=grey;font_size=24]",
        "style_type[label;font_size=*2]",
        "button[4,2.5;2,1;down;" .. minetest.formspec_escape("\\/") .. "]",
        "button[1,3.5;2,1;up;" .. minetest.formspec_escape("/\\") .. "]",
        "label[3,2.5;" .. current .. "°C]",
        "label[8,2.5;" .. target .. "°C]"
    }

    return table.concat(formspec, "")
end

local initForm = function(player, pos)
    local playerName = player:get_player_name()
    if not playerName or playerName == "" then
        return
    end

    local posstr = minetest.pos_to_string(pos)
    local player_meta = player:get_meta()
    if player_meta:get_int(KEY_TARGET .. posstr) == 0 then
        local tgt = math.random(-50, 50)
        local distance = math.random(20, 30)
        if math.random(0, 1) == 0 then
            distance = distance * -1
        end
        player_meta:set_int(KEY_TARGET .. posstr, tgt)
        player_meta:set_int(KEY .. posstr, tgt + distance)
    end
end

local closeForm = function(pos, player, fields)
    local playerName = player:get_player_name()
    if not playerName or playerName == "" then
        return
    end

    local posstr = minetest.pos_to_string(pos)
    local player_meta = player:get_meta()
    local current = player_meta:get_int(KEY .. posstr)
    local target = player_meta:get_int(KEY_TARGET .. posstr)

    local test_value = function(val1, val2)
        if val1 == val2 then
            player_meta:set_int(KEY .. posstr, 0)
            player_meta:set_int(KEY_TARGET .. posstr, 0)
            local node_meta = minetest.get_meta(pos)
            amongus.finish_task(playerName, node_meta:get_string(KEY_NAME))
            minetest.destroy_form(playerName)
        else
            player_meta:set_int(KEY .. posstr, val1)
            minetest.update_form(playerName, showForm(player, pos))
        end
    end

    if fields.up == "/\\" then
        test_value(current + 1, target)
    elseif fields.down == "\\/" then
        test_value(current - 1, target)
    elseif fields.quit == minetest.FORMSPEC_SIGEXIT then
        return
    end
end

local onPlace = function(pos, name)
    local node_meta = minetest.get_meta(pos)
    node_meta:set_string(KEY_NAME, name)
end

amongus.register_task_node(TASK_NAME, {"amongus_task_" .. TASK_NAME .. ".png"}, initForm, showForm, closeForm, onPlace)
