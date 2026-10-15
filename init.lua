local _, ns = ...

-- options; a host addon may change them before PLAYER_LOGIN
ns.ScreenShots = {
    achievements = true,        -- earned achievements
    boss_kills = true,          -- successful boss encounters
    challenge_mode = true,      -- completed challenge modes / mythic keys
    levelup = true,             -- player level up
    dead = true,                -- player death
    messages = true,            -- print a chat message for each screenshot event
    tracer = false              -- print "Screenshot Taken/Failed"
}
