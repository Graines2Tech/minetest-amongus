local SKIN_DEFAULT = "invisible"
local MOD_NAME = minetest.get_current_modname()
local MOD_PATH = minetest.get_modpath(MOD_NAME)
local SKIN_PATH = MOD_PATH .. "/textures/"
local SKIN_FILE = "skins.txt"
local SKIN_PREFIX = "amongus_skin_"
local SKIN_SUFFIX = ".png"

local function loadSkinsFromFiles()
    local normKeys, negKeys, values = {}, {}, {}

    --TODO filePath est un folderPath, il faut lister les fichiers dans le répertoire, et pas les lignes d'un fichier

    local skinList = {}
    local skinFiles = {}
    skinFiles[SKIN_DEFAULT] = SKIN_PREFIX .. SKIN_DEFAULT .. SKIN_SUFFIX
    local file = io.open(MOD_PATH .. "/" .. SKIN_FILE, "r")
    if file then
        for line in file:lines() do
            local skin_fname = SKIN_PREFIX .. line .. SKIN_SUFFIX
            local fskin = io.open(SKIN_PATH .. skin_fname, "r")
            if fskin ~= nil then
                io.close(fskin)
                table.insert(skinList, line)
                skinFiles[line] = skin_fname
            end
        end
        file:close()
    end

    return skinList, skinFiles
end

local skins, skin_files = loadSkinsFromFiles()

--show voting form for kin
local showForm = function(player_name)
    local nb = #skins - 1
    if nb < 0 then
        nb = 0
    end
    local l = 0
    local c = 0
    local spacer = 0.5
    local top = 1
    local length = 2
    local length2 = length + spacer
    local height = 1
    local height2 = height + spacer
    local size = dump(length) .. "," .. dump(height)

    local formspec = {
        "formspec_version[4]",
        "size[5.5,",
        math.ceil(nb / 2) * height2 + top,
        "]",
        "label[2,0.5;",
        minetest.formspec_escape("Choose your skin"),
        "]",
        "style_type[button;bgcolor=green]"
    }

    if nb > 0 then
        for _, skin in ipairs(skins) do
            if skin ~= SKIN_DEFAULT then
                local pos = dump(spacer + c * length2) .. "," .. dump(top + l * height2)
                if amongus.skins[skin] then
                    table.insert(formspec, "label[" .. pos .. ";" .. skin .. "]")
                else
                    table.insert(formspec, "button[" .. pos .. ";" .. size .. ";target;" .. skin .. "]")
                end
                if c % 2 == 0 then
                    c = c + 1
                else
                    l = l + 1
                    c = 0
                end
            end
        end
    end

    return table.concat(formspec, "")
end

--perform voting form action
local closeForm = function(state, player, fields)
    local player_name = player:get_player_name()
    if not player_name or player_name == "" then
        return
    end

    local player_meta = player:get_meta()

    if fields.quit == minetest.FORMSPEC_SIGEXIT then
        return
    elseif fields.quit == minetest.FORMSPEC_SIGPROC then
        return
    elseif fields.target ~= nil then
        amongus.change_player_skin(player_name, fields.target)
        minetest.update_form(player_name, showForm(player_name))
    end
end

function amongus.get_default_skin_name()
    return SKIN_DEFAULT
end

function amongus.change_player_skin(player_name, skin)
    local player = minetest.get_player_by_name(player_name)
    if not player then
        return
    end
    if player_name == "Admin" and skin ~= SKIN_DEFAULT then
        return
    end
    if not (amongus.skins[skin] == nil or amongus.skins[skin] == player_name) then
        return
    end
    player:set_properties(
        {
            visual = "mesh",
            visual_size = {x = 1, y = 1},
            mesh = "character.b3d",
            textures = {skin_files[skin]}
        }
    )
    for sk, pname in pairs(amongus.skins) do
        if pname == player_name then
            if sk ~= SKIN_DEFAULT then
                amongus.skins[sk] = nil
            end
        end
    end
    amongus.skins[skin] = player_name
end

--define a random skin for the player
function amongus.define_random_skin(player_name)
    local skin = SKIN_DEFAULT
    local n = 0
    for sk, pname in pairs(amongus.skins) do
        if pname == player_name then
            --in case of reconnection
            amongus.change_player_skin(player_name, sk)
            return
        end
    end
    while amongus.skins[skin] ~= nil do
        skin = skins[math.random(#skins)]
    end
    amongus.skins[skin] = player_name
    amongus.change_player_skin(player_name, skin)
end

--display skin form for a player
function amongus.display_skin_form(player_name)
    minetest.create_form(nil, player_name, showForm(player_name), closeForm)
end
