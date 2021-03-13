local TASK_NAME = "questions"
local FORM_NAME = "amongus_task_" .. TASK_NAME
local KEY = FORM_NAME .. "_key"
local KEY_ERROR = KEY .. "_error"
local KEY_NAME = KEY .. "_name"

local function showForm(player, pos)
    local playerName = player:get_player_name()
    if not playerName or playerName == "" then
        return
    end

    local posstr = minetest.pos_to_string(pos)
    local player_meta = player:get_meta()
    local current = player_meta:get_int(KEY .. posstr)
    local error = player_meta:get_string(KEY_ERROR .. posstr)

    local formspec = {
        "formspec_version[4]",
        "size[10,6]"
    }

    if error == "o" then
        table.insert(formspec, "box[0,0;10,6;red]")
        table.insert(formspec, "label[3,2;You fail dude, be more lucky next time !]")
    else
        table.insert(formspec, "style_type[button;bgcolor=blue;font_size=24]")
        if current == 0 then
            table.insert(formspec, "label[3,2;Who can went ???]")
            table.insert(formspec, "button[1.5,4;3,1.5;ok;Only impostors]")
            table.insert(formspec, "button[5.5,4;3,1.5;nok;everyone]")
        elseif current == 1 then
            table.insert(formspec, "label[3,2;does a pink skin exist on among us ??]")
            table.insert(formspec, "button[1.5,4;3,1.5;ok;yes]")
            table.insert(formspec, "button[5.5,4;3,1.5;nok;no]")
        elseif current == 2 then
            table.insert(formspec, "label[3,2;is Among us paid on smartphone ???]")
            table.insert(formspec, "button[1.5,4;3,1.5;nok;yes]")
            table.insert(formspec, "button[5.5,4;3,1.5;ok;no]")
        elseif current == 3 then
            table.insert(formspec, "label[3,2;Can we download among us on steam ???]")
            table.insert(formspec, "button[1.5,4;3,1.5;ok;yes]")
            table.insert(formspec, "button[5.5,4;3,1.5;nok;no]")
        elseif current == 4 then
            table.insert(formspec, "label[3,2;What is the price of among us on pc ???]")
            table.insert(formspec, "button[1.5,4;3,1.5;nok;400€]")
            table.insert(formspec, "button[5.5,4;3,1.5;ok;4€]")
        end
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
    local number = player_meta:get_int(KEY .. posstr)

    if fields.quit == minetest.FORMSPEC_SIGPROC then
        return
    elseif fields.quit == minetest.FORMSPEC_SIGEXIT then
        player_meta:set_string(KEY_ERROR .. posstr, "n")
    elseif not (fields.ok == nil) then
        if number == 4 then
            local node_meta = minetest.get_meta(pos)
            amongus.finish_task(playerName, node_meta:get_string(KEY_NAME))
            player_meta:set_int(KEY .. posstr, 0)
            minetest.destroy_form(playerName)
            return
        end
        player_meta:set_int(KEY .. posstr, number + 1)
        minetest.update_form(playerName, showForm(player, pos))
    else
        player_meta:set_int(KEY .. posstr, 0)
        player_meta:set_string(KEY_ERROR .. posstr, "o")
        minetest.update_form(playerName, showForm(player, pos))
    end
end

local onPlace = function(pos, name)
    local node_meta = minetest.get_meta(pos)
    node_meta:set_string(KEY_NAME, name)
end

amongus.register_task_node(
    TASK_NAME,
    {
        "amongus_task_" .. TASK_NAME .. "_other.png",
        "amongus_task_" .. TASK_NAME .. "_other.png",
        "amongus_task_" .. TASK_NAME .. "_other.png",
        "amongus_task_" .. TASK_NAME .. "_other.png",
        "amongus_task_" .. TASK_NAME .. "_other.png",
        "amongus_task_" .. TASK_NAME .. "_face.png"
    },
    initForm,
    showForm,
    closeForm,
    onPlace
)
