alogs.conf = alogs.conf or {}

-- usergroups that can open !alogs
alogs.conf.allowed_usergroups = {
    "superadmin",
    "admin"
}
-- command to open alogs menu
alogs.conf.commands = {
    "!alogs"
}
-- commands that will NOT register
alogs.conf.excluded_cmds = {
    "time",
    "motd",
    "menu"
}

alogs.conf.cleanup_days = 30
-- bruh
alogs.conf.use_mysql = false
-- lang
alogs.conf.language = "english"
-- admin mod (only supports ulx and sam)
alogs.conf.adminmod = "ulx"


alogs.conf.credits = {
    author = "@zukma",
    version = "1.0.0",
    name = "ALogs - Admin Command Logger",
    license = "MIT License",
    license_text = "Free to use, modify and distribute."
}

-----------------------------------------------
-- commands that appear in "special commands" 
-----------------------------------------------
-- SAM
alogs.conf.special_cmds = {
    "ban",
    "banid",
    "unban",
    "kick",
    "jail",
    "unjail",
    "mute",
    "unmute",
    "gag",
    "ungag",
    "setrank",
    "setrankid"
}
-- ULX
alogs.conf.ulx_special_cmds = {
    "ban",
    "banid",
    "unban",
    "kick",
    "jail",
    "unjail",
    "mute",
    "unmute",
    "gag",
    "ungag",
    "freeze",
    "unfreeze",
    "god",
    "ungod"
}
