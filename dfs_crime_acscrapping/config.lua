--Electric sell store 
Config = {}

Config.Cooldowns = {
    Global = 4000
}

Config.SkillLogic = function(AddRep) 
    --1% of value generated from that AC. Average shoul dbe roughly $7200/hr uncustomized.
    --Called from the server.
    --exports["wild-skills"]:UpdateSkill("Street Reputation", AddRep)
end

Config.Police = {
    ChanceToCallIncreasedPerSecondIncrease = 0.05, -- MassiveAC will be 7.5 at peak per second solo, or 1.875 per player with 4. This is checked every second they're popping property. This resets every night at midnight.
    ChanceToCallPerPlayerAttachedIncrease  = 2.0,
    CallCooldown                           = 15 * 60 * 1000,
    CalloutHeatDecayPerSecondNotScrapping  = 0.2,
    DiscouragedHeatMultiplier = 0.5,
    EnableCopRequirement = false,
    CalloutLogic = function(coords, gender, street, zone)
        --Called from the server
        local blipTypes = {
            range_zero = {
                displayCode = "NONE",
                sprite = 436,
                color = 1,
                scale = 0.5,
                length = 2, --Blip duration
                sound = "Lose_1st",
                sound2 = "GTAO_FM_Events_Soundset",
                offset = "false",
                flash = "false"
            },
            range_small = {
                displayCode = "NONE",
                sprite = 161,
                color = 1,
                scale = 1.5,
                length = 5, --Blip duration
                sound = "Lose_1st",
                sound2 = "GTAO_FM_Events_Soundset",
                offset = "true",
                flash = "false"
            },
            range_moderate = {
                displayCode = "NONE",
                sprite = 161,
                color = 1,
                scale = 2.5,
                length = 5, --Blip duration
                sound = "Lose_1st",
                sound2 = "GTAO_FM_Events_Soundset",
                offset = "true",
                flash = "false"
            },
        }

        local CallMessages = {
            --Used Codes: 10-60 Unknown Trouble. 10-83: noise complaint. 10-12: trespassing. 10-87: Destruction of Property
            {label="Noise Complaint", code="10-83", icon="fa fa-volume-high", blipData=blipTypes.range_small},
            {label="Unknown Trouble", code="10-60", icon="fa fa-circle-question", blipData=blipTypes.range_moderate},
            {label="Tresspassing", code="10-12", icon="fa fa-ban", blipData=blipTypes.range_moderate},
            {label="Destruction of Property", code="10-87", icon="fa fa-explosion", blipData=blipTypes.range_zero},
        }

        local selectedMessage = CallMessages[math.random(1, #CallMessages)]

        TriggerEvent('ps-dispatch:server:notify', {
            message = selectedMessage.label,
            codeName = "NONE",
            code = selectedMessage.code,
            icon = selectedMessage.icon,
            priority = 2,
            coords = coords,
            gender = gender,
            street = street..", "..zone,
            camId = nil,
            color = nil,
            callsign = nil,
            name = nil,
            vehicle = nil,
            plate = nil,
            doorCount = nil,
            automaticGunfire = false,
            alert = {
                displayCode = "NONE",
                description = selectedMessage.label,
                radius = 0,
                sprite = selectedMessage.blipData.sprite or 1,
                color = 1,
                scale = selectedMessage.blipData.scale,
                length = selectedMessage.blipData.length,
                sound = selectedMessage.blipData.sound,
                sound2 = selectedMessage.blipData.sound2,
                offset = selectedMessage.blipData.offset,
                flash = "false"
            },
            jobs = { 'leo', 'police' },
        })
    end,
}

Config.Money = {
    DiscouragedLootMultiplier = 0.5,
    SellPrices = {
        nutsandbolts    = 2,
        metalscrap    = 20,
        electricalscrap = 75,
        steel         = 200,
    },
    ElectricSellLocation = vector3(1113.15, -325.87, 66.09),
}

Config.Times = { --Values for standard scrap are calculated as $1/0.5 seconds of scrapping
    nutsandbolts    = Config.Money.SellPrices.nutsandbolts      * 500,
    metalscrap    = Config.Money.SellPrices.metalscrap      * 500,
    electricalscrap = Config.Money.SellPrices.electricalscrap   * 500,
    steel         = Config.Money.SellPrices.steel           * 500,
}

Config.Items = {
    ["nutsandbolts"] = {
        name = "nutsandbolts",
        label = "Nuts and Bolts",
        weight = 50,
        type = 'item',
        image = 'nutsandbolts.png',
        unique = false,
        useable = false,
        shouldClose = false,
        combinable = nil,
        description = "A few, small, nuts and bolts. Common, but critical.",
    },
    ["metalscrap"] = {
        name = "metalscrap",
        label = "Metal Scrap",
        weight = 450,
        type = 'item',
        image = 'metalscrap.png',
        unique = false,
        useable = false,
        shouldClose = false,
        combinable = nil,
        description = "A small hunk of potentially reusable metal.",
    },
    ["electricalscrap"] = {
        name = "electricalscrap",
        label = "Spare Circuit Boards",
        weight = 10,
        type = 'item',
        image = 'electricalscrap.png',
        unique = false,
        useable = false,
        shouldClose = false,
        combinable = nil,
        description = "The guts of a now dead computer.",
    },
    ["steel"] = {
        name = "steel",
        label = "Steel",
        weight = 1813,
        type = 'item',
        image = 'steel.png',
        unique = false,
        useable = false,
        shouldClose = false,
        combinable = nil,
        description = "A sizable chunk of reusable metal. Good for crafting or selling!",
    },
}

Config.Units = {
    [1131941737] = { --Medium AC
        metalscrap = 5,
        nutsandbolts = 5,
        model = 'prop_aircon_m_02',
    },
    [1457658556] = { --Light Fixture - Industrial Small
        electricalscrap = 3,
        metalscrap    = 2,
        nutsandbolts    = 11,
        model = 'prop_wall_light_03a',
    },
    [1214250852] = { --Commercial Spinning Vent
        metalscrap = 2,
        nutsandbolts = 8,
        model = 'prop_roofvent_06a',
    },
    [-727843691] = { --Commercial Satellite Dish, might also be 3567123605
        metalscrap = 1,
        nutsandbolts = 11,
        model = 'prop_satdish_s_01',
    },
    [-1625667924] = { --Micro roof AC. Might also be 2669299372
        metalscrap = 1,
        nutsandbolts = 12,
        model = 'prop_aircon_m_06',
    },
    [1709954128] = { --Small commercial AC
        metalscrap = 2,
        nutsandbolts = 11,
        model = 'prop_aircon_m_04',
    },
    [1426534598] = { --Large commercial AC
        steel      = 8,
        metalscrap = 9,
        nutsandbolts = 4,
        model = 'prop_aircon_l_03',
    },
    [1369811908] = { --Medium commercial AC with covered vent
        metalscrap = 6,
        nutsandbolts = 8,
        model = 'prop_aircon_m_01',
    },
    [1195939145] = { --Massive AC Vented
        steel      = 4,
        metalscrap = 9,
        nutsandbolts = 6,
        model = 'prop_aircon_l_04',
    },
    [-1188479578] = { --Medium commercial satellite, also could be 3106487718
        metalscrap = 3,
        nutsandbolts = 9,
        model = 'prop_satdish_l_02',
    },
    [605277920] = { --Massive AC With Ladder
        steel      = 5,
        metalscrap = 12,
        nutsandbolts = 9,
        model = 'prop_aircon_l_02',
    },
    [541723713] = { --Micro roof sattelite.
        metalscrap = 1,
        nutsandbolts = 10,
        model = 'prop_satdish_s_04b',
    },
    [1366469466] = { --Micro roof AC sideways.
        metalscrap = 1,
        nutsandbolts = 12,
        model = 'prop_aircon_m_07',
    },
    [-1025550056] = { --Micro roof sattelite with tripod. Might also be 3269417240
        metalscrap = 1,
        nutsandbolts = 10,
        model = 'prop_satdish_s_02',
    },
    [1948414141] = { --Small roof HVAC unit
        metalscrap = 3,
        nutsandbolts = 8,
        model = 'prop_aircon_m_03',
    },
    [-1895279849] = { --Fancy commercial light fixture, small
        electricalscrap = 2,
        nutsandbolts    = 4,
        model = 'prop_oldlight_01b',
    },
    [-1169356008] = { --Small city cell repeater
        electricalscrap = 1,
        metalscrap    = 2,
        nutsandbolts    = 16,
        model = 'h4_prop_h4_ante_on_01a',
    },
    [959280723] = { --Medium commercial street light overhand
        electricalscrap = 1,
        metalscrap    = 1,
        nutsandbolts    = 4,
        model = 'prop_wall_light_09a',
    },
    [1518466392] = { --Small commercial breakerbox
        electricalscrap = 2,
        metalscrap = 2,
        nutsandbolts = 1,
        model = 'prop_elecbox_11',
    },
    [-153364983] = { --fancy small residentail light fixture
        electricalscrap = 1,
        metalscrap = 1,
        nutsandbolts = 4,
        model = 'prop_wall_light_07a',
    },
    [548760764] = { --CCTV camera; industrial
        metalscrap = 1,
        model = 'prop_cctv_cam_01a',
    },
    [827943275] = { --massive 2-fan AC unit, industrial
        steel = 10,
        electricalscrap = 10,
        metalscrap = 30,
        nutsandbolts = 100,
        model = 'prop_aircon_l_01',
    },
    [1733804211] = { --Medium commercial AC
        steel = 1,
        electricalscrap = 5,
        metalscrap = 4,
        nutsandbolts = 10,
        model = 'vw_prop_vw_aircon_m_01',
    },
    [-686494084] = { --Large industrial electircal box
        steel = 1,
        electricalscrap = 30,
        metalscrap = 5,
        nutsandbolts = 10,
        model = 'prop_elecbox_10',
    },
    [1402414826] = { --small commercial square light
        electricalscrap = 1,
        metalscrap = 1,
        nutsandbolts = 4,
        model = 'prop_wall_light_04a',
    },
    [493845300] = { --large industrial electric blackbox
        steel = 3,
        electricalscrap = 30,
        nutsandbolts = 5,
        model = 'prop_elecbox_16',
    },
    [-2007495856] = {--medium industrial electrical box
        electricalscrap = 10,
        metalscrap = 5,
        nutsandbolts = 4,
        model = 'prop_elecbox_05a',
    },
    [1923262137] = {--small indusrtial electical blackbox
        electricalscrap = 5,
        metalscrap = 5,
        nutsandbolts = 5,
        model = 'prop_elecbox_09',
    },
    [305924745] = {--medium industrial flourescent bulb
        electricalscrap = 2,
        metalscrap = 2,
        nutsandbolts = 8,
        model = 'prop_wall_light_05c',
    }
}