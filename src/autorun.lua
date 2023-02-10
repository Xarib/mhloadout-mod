-- -- mhl.callback(function(a) log.debug(tostring(a)) end)

--- Generates an enum from the given type
local function generate_enum(typename)
    local t = sdk.find_type_definition(typename)
    if not t then return {} end

    local fields = t:get_fields()
    local enum = {}

    for i, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)

            log.debug(name .. " = " .. tostring(raw_value))

            enum[name] = raw_value
        end
    end

    return enum
end

-- Weapon = 0, Head = 1, Chest = 2, Arm = 3, Waist = 4, Leg = 5
-- LvBuffCage = 6, Talisman = 7, Max = 8, Error = 9
local equip_types = generate_enum("snow.equip.PlEquipTypes")
local equip_manager = sdk.get_managed_singleton("snow.data.EquipDataManager")
local all_loadouts = equip_manager._PlEquipMySetList

--- Reads the decorations of the equipment and maps them
local function map_decorations(loadout, equip_type)
    local decos = {}

    for i, deco in ipairs(loadout:getDecoList(equip_type):get_elements()) do
        decos[i] = deco.value__
    end

    return decos
end

--- Reads the equipment that is not an armor and maps them
local function map_ingame_loadout_equipment(loadout, equip_type, get_id_function)
    local mapped_armor_piece = {
        id = get_id_function:call(loadout)
    }
    
    if equip_type == equip_types["Weapon"] or equip_type == equip_types["Talisman"] then
        mapped_armor_piece["decos"] = map_decorations(loadout)

        if equip_type == equip_types["Weapon"] then
            mapped_armor_piece["rampage_deco_id"] = loadout:getHyakuryuDecoId(equip_types["Weapon"])
        end
    end
    
    return mapped_armor_piece
end

--- Reads the armors and maps them
local function map_ingame_loadout_armor(loadout, equip_type, get_id_function)
    return {
        id = get_id_function:call(loadout, equip_type),
        decos = map_decorations(loadout)
    }
end

--- Reads all equipment from the given loadout and maps them
local function map_ingame_loadout(loadout)
    return {
        -- Armor
        armor_head = map_ingame_loadout_armor(loadout, equip_types["Head"], loadout.getArmorId),
        armor_chest = map_ingame_loadout_armor(loadout, equip_types["Chest"], loadout.getArmorId),
        armor_arm = map_ingame_loadout_armor(loadout, equip_types["Arm"], loadout.getArmorId),
        armor_waist = map_ingame_loadout_armor(loadout, equip_types["Waist"], loadout.getArmorId),
        armor_leg = map_ingame_loadout_armor(loadout, equip_types["Leg"], loadout.getArmorId),

        -- Rest
        weapon = map_ingame_loadout_equipment(loadout, equip_types["Weapon"], loadout.getWeaponId),
        weapon_kinsect = map_ingame_loadout_equipment(loadout, nil, loadout.getInsectId),
        talisman = map_ingame_loadout_equipment(loadout, equip_types["Talisman"], loadout.getTalismanId),
        petalace = map_ingame_loadout_equipment(loadout, equip_types["LvBuffCage"], loadout.getLvBuffCageId)
    }
end

local mapped_loadouts = {}
for i = 0, 111, 1 do
    local current_loadout = all_loadouts[i]
    if current_loadout._IsUsing then
        local mapped_loadout = map_ingame_loadout(current_loadout)
        mapped_loadout.name = current_loadout:get_Name()

        -- Current index + 1, to make a table an array (also reflects as an array when dumped as a JSON)
        mapped_loadouts[i+1] = mapped_loadout
    end
end

log.debug(json.dump_string(mapped_loadouts, 2))
