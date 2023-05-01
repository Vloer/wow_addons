local colors = {
    red = "|cffff0000",
    green = "|cff00ff00",
    yellow = "|cffffff00",
    blue = "|cff0000ff",
    magenta = "|cffff00ff",
    cyan = "|cff00ffff",
    orange = "|cffffa700",
    yellow2 = "|cfffff400",
    lightgreen = "|cffa3ff00",
    darkgreen = "|cff2cba00",
    reset = "|r"
}
Defaults = {
    dungeonNamesShort = {
        AV = "The Azure Vault",
        RLP = "Ruby Life Pools",
        HOV = "Halls of Valor",
        NO = "The Nokhud Offensive",
        SBG = "Shadowmoon Burial Grounds",
        COS = "Court of Stars",
        TJS = "Temple of the Jade Serpent",
        AA = "Algeth'ar Academy"
    },
    dungeonDefault = {
        player = "",
        name = "",
        party = {},
        startedTimestamp = 0,
        completed = false,
        completedTimestamp = 0,
        completedInTime = false,
        timeToComplete = "",
        time = 0,
        deaths = {},
        total_deaths = 0,
        keyDetails = {
            level = 0,
            affixes = {}
        },
        timeLimit = 0,
        date = ""
    },
    colors = {
        chatAnnounce = colors.cyan,
        chatWarning = colors.yellow,
        chatError = colors.red,
        chatSuccess = colors.green,
        rating = { 
            colors.red,
            colors.orange,
            colors.yellow2,
            colors.lightgreen,
            colors.darkgreen
        }
    },
    dateFormat = "%Y-%m-%d",
    dateTimeFormat = "%Y-%m-%d %H:%M:%S"
}
