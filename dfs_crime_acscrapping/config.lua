--Electric sell store 
Config = {}

Config.Cooldowns = {
    Global = 4000
}

Config.SkillLogic = function(AddRep) --1% of value generated from that AC. Average shoul dbe roughly $7200/hr uncustomized
    exports["wild-skills"]:UpdateSkill("Street Reputation", AddRep)
end

Config.Police = {
    ChanceToCallIncreasedPerSecondIncrease = 0.05, -- MassiveAC will be 7.5 at peak per second solo, or 1.875 per player with 4. This is checked every second they're popping property. This resets every night at midnight.
    ChanceToCallPerPlayerAttachedIncrease  = 2.0,
    CallCooldown                           = 15 * 60 * 1000,
    CalloutHeatDecayPerSecondNotScrapping  = 0.2,
    DiscouragedHeatMultiplier = 0.5,
    EnableCopRequirement = false,
    CalloutLogic = function(coords, gender, street, zone)
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

        local selectedMessage = math.random(1, #CallMessages)

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
        smallsalvage    = 20,
        electricalscrap = 75,
        salvage         = 200,
    },
    ElectricSellLocation = vector3(1113.15, -325.87, 66.09),
}

Config.Times = { --Values for standard scrap are calculated as $1/0.5 seconds of scrapping
    nutsandbolts    = Config.Money.SellPrices.nutsandbolts      * 500,
    smallsalvage    = Config.Money.SellPrices.smallsalvage      * 500,
    electricalscrap = Config.Money.SellPrices.electricalscrap   * 500,
    salvage         = Config.Money.SellPrices.salvage           * 500,
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
    ["smallsalvage"] = {
        name = "smallsalvage",
        label = "Metal Scrap [Small]",
        weight = 450,
        type = 'item',
        image = 'smallsalvage.png',
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
    ["salvage"] = {
        name = "salvage",
        label = "Metal Scrap",
        weight = 1813,
        type = 'item',
        image = 'salvage.png',
        unique = false,
        useable = false,
        shouldClose = false,
        combinable = nil,
        description = "A sizable chunk of reusable metal. Good for crafting or selling!",
    },
}

Config.Units = {
    [1131941737] = { --Medium AC
        smallsalvage = 5,
        nutsandbolts = 5,
    },
    [1457658556] = { --Light Fixture - Industrial Small
        electricalscrap = 3,
        smallsalvage    = 2,
        nutsandbolts    = 11,
    },
    [1214250852] = { --Commercial Spinning Vent
        smallsalvage = 2,
        nutsandbolts = 8,
    },
    [-727843691] = { --Commercial Satellite Dish, might also be 3567123605
        smallsalvage = 1,
        nutsandbolts = 11,
    },
    [-1625667924] = { --Micro roof AC. Might also be 2669299372
        smallsalvage = 1,
        nutsandbolts = 12,
    },
    [1709954128] = { --Small commercial AC
        smallsalvage = 2,
        nutsandbolts = 11,
    },
    [1426534598] = { --Large commercial AC
        salvage      = 8,
        smallsalvage = 9,
        nutsandbolts = 4,
    },
    [1369811908] = { --Medium commercial AC with covered vent
        smallsalvage = 6,
        nutsandbolts = 8,
    },
    [1195939145] = { --Massive AC Vented
        salvage      = 4,
        smallsalvage = 9,
        nutsandbolts = 6,
    },
    [-1188479578] = { --Medium commercial satellite, also could be 3106487718
        smallsalvage = 3,
        nutsandbolts = 9,
    },
    [605277920] = { --Massive AC With Ladder
        salvage      = 5,
        smallsalvage = 12,
        nutsandbolts = 9,
    },
    [541723713] = { --Micro roof sattelite.
        smallsalvage = 1,
        nutsandbolts = 10,
    },
    [1366469466] = { --Micro roof AC sideways.
        smallsalvage = 1,
        nutsandbolts = 12,
    },
    [-1025550056] = { --Micro roof sattelite with tripod. Might also be 3269417240
        smallsalvage = 1,
        nutsandbolts = 10,
    },
    [1948414141] = { --Small roof HVAC unit
        smallsalvage = 3,
        nutsandbolts = 8,
    },
    [-1895279849] = { --Fancy commercial light fixture, small
        electricalscrap = 2,
        nutsandbolts    = 4,
    },
    [-1169356008] = { --Small city cell repeater
        electricalscrap = 1,
        smallsalvage    = 2,
        nutsandbolts    = 16,
    },
    [959280723] = { --Medium commercial street light overhand
        electricalscrap = 1,
        smallsalvage    = 1,
        nutsandbolts    = 4,
    },
    [1518466392] = { --Small commercial breakerbox
        electricalscrap = 2,
        smallsalvage = 2,
        nutsandbolts = 1,
    },
    [-153364983] = { --fancy small residentail light fixture
        electricalscrap = 1,
        smallsalvage = 1,
        nutsandbolts = 4,
    },
    [548760764] = { --CCTV camera; industrial
        smallsalvage = 1,
    },
    [827943275] = { --massive 2-fan AC unit, industrial
        salvage = 10,
        electricalscrap = 10,
        smallsalvage = 30,
        nutsandbolts = 100,
    },
    [1733804211] = { --Medium commercial AC
        salvage = 1,
        electricalscrap = 5,
        smallsalvage = 4,
        nutsandbolts = 10,
    },
    [-686494084] = { --Large industrial electircal box
        salvage = 1,
        electricalscrap = 30,
        smallsalvage = 5,
        nutsandbolts = 10,
    },
    [1402414826] = { --small commercial square light
        electricalscrap = 1,
        smallsalvage = 1,
        nutsandbolts = 4,
    },
    [493845300] = { --large industrial electric blackbox
        salvage = 3,
        electricalscrap = 30,
        nutsandbolts = 5,
    },
    [-2007495856] = {--medium industrial electrical box
        electricalscrap = 10,
        smallsalvage = 5,
        nutsandbolts = 4,
    },
    [1923262137] = {--small indusrtial electical blackbox
        electricalscrap = 5,
        smallsalvage = 5,
        nutsandbolts = 5,
    },
    [305924745] = {--medium industrial flourescent bulb
        electricalscrap = 2,
        smallsalvage = 2,
        nutsandbolts = 8,
    }
}