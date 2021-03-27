local S = minetest.get_translator("amongus")

local TASK_NAME = "download"
local FORM_NAME = "amongus_task_" .. TASK_NAME
local KEY = FORM_NAME .. "_key"
local KEY_NAME = KEY .. "_name"

local function showForm(player, pos)
    local playerName = player:get_player_name()
    if not playerName or playerName == "" then
        return
    end

    local posstr = minetest.pos_to_string(pos)
    local player_meta = player:get_meta()
    local current = player_meta:get_int(KEY .. posstr)

    local formspec = {
        "formspec_version[4]",
        "size[10,6]",
        "style_type[button;bgcolor=red;font_size=24]"
    }

    if current == 0 then
        table.insert(formspec, "button[3,2;4,2;push_now;" .. S("PUSH!!!!!!! NOW!!!!!!!") .. "]")
    else
        table.insert(formspec, "box[3,2;4,2;gray]")
        table.insert(formspec, "box[3,2;" .. tostring(4 / 10 * current) .. ",2;blue]")
    end

    return table.concat(formspec, "")
end

local initForm = function(player, pos)
end

local closeForm = function(pos, player, fields)
    local playerName = player:get_player_name()
    if not playerName or playerName == "" then
        return
    end

    local posstr = minetest.pos_to_string(pos)
    local player_meta = player:get_meta()
    local current = player_meta:get_int(KEY .. posstr)

    if fields.push_now ~= nil then
        minetest.get_form_timer(playerName).start(1)
        player_meta:set_int(KEY .. posstr, 1)
        minetest.update_form(playerName, showForm(player, pos))
    elseif fields.quit == minetest.FORMSPEC_SIGTIME then
        if current == 10 then
            local node_meta = minetest.get_meta(pos)
            amongus.finish_task(playerName, node_meta:get_string(KEY_NAME))
            player_meta:set_int(KEY .. posstr, 0)
            minetest.destroy_form(playerName)
        else
            current = current + 1
            player_meta:set_int(KEY .. posstr, current)
            minetest.update_form(playerName, showForm(player, pos))
        end
    elseif fields.quit == minetest.FORMSPEC_SIGEXIT then
        player_meta:set_int(KEY .. posstr, 0)
    end
end

local onPlace = function(pos, name)
    local node_meta = minetest.get_meta(pos)
    node_meta:set_string(KEY_NAME, name)
end

amongus.register_task_node(TASK_NAME, {"amongus_task_" .. TASK_NAME .. ".png"}, initForm, showForm, closeForm, onPlace)
