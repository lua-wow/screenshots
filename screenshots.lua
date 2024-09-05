local _, ns = ...

-- Blizzard
local Screenshot = _G.Screenshot
local IsInInstance = _G.IsInInstance
local GetAchievementInfo = _G.GetAchievementInfo
local GetDifficultyInfo = _G.GetDifficultyInfo

local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
local isClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
local isTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
local isWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
local isCata = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)

-- Mine
local isInit = false

local EncounterDifficulty = {
    [1] = false,            -- Dungeon Normal
    [2] = false,            -- Dungeon Heroic
    [3] = false,            -- Raid Normal 10-man
    [4] = false,            -- Raid Normal 25-man
    [5] = true,             -- Raid Heroic 10-man
    [6] = true,             -- Raid Heroic 25-man
    [7] = false,            -- Looking For Raid
    [8] = true,             -- Mythic Keystone
    [9] = true,             -- Raid 40-man
    [14] = true,            -- Raid Normal
    [15] = true,            -- Raid Heroic
    [16] = true,            -- Raid Mythic
    [17] = false,           -- Looking For Raid
    [23] = true,            -- Dungeon Muthic
    [172] = true,           -- World Boss
}

local ZoneTypes = {
    ["none"] = false,       -- when outside an instance
    ["pvp"] = false,        -- when in a battleground
    ["arena"] = false,      -- when in an arena
    ["party"]= true,        -- when in a 5-man instance
    ["raid"] = true,        -- when in a raid instance
    ["scenario"] = false,   -- when in a scenario
}

----------------------------------------------------------------
-- Wait Function
-- delay: amount of time to wait (in seconds) before the provided function is triggered.
-- func: function to run once the wait delay is over.
-- param: list of any additional parameters.
-- NOT MY CODE. Got it here: http://www.wowwiki.com/Wait on January 20th, 2019
----------------------------------------------------------------
local tremove = table.remove
local tinsert = table.insert

local waitTable = {}
local waitFrame = nil

-- wait a specified amount of time (in seconds) before triggering another function.
local function Wait(delay, func, ...)
    if (type(delay) ~= "number") or (type(func) ~= "function") then
        return false
    end
    if (waitFrame == nil) then
        waitFrame = CreateFrame("Frame", "WaitFrame", UIParent)
        waitFrame:SetScript("OnUpdate", function(self, elapse)
            local count = #waitTable
            local i = 1
            while (i <= count) do
                local waitRecord = tremove(waitTable, i)
                local d = tremove(waitRecord, 1)
                local f = tremove(waitRecord, 1)
                local p = tremove(waitRecord, 1)
                if (d > elapse) then
                    tinsert(waitTable, i, { d - elapse, f, p })
                    i = i + 1
                else
                    count = count - 1
                    f(unpack(p))
                end
            end
        end);
    end
    tinsert(waitTable, { delay, func, {...} })
    return true
end

----------------------------------------------------------------
-- Screen Shots
----------------------------------------------------------------
local element_proto = {
    cfg = {
        ["enabled"] = true,             -- enables plugin.
        ["achievements"] = true,        -- enables screenshots of earned achievements.
        ["boss_kills"] = false,         -- enables screenshots of successful boss encounters.
        ["challenge_mode"] = true,      -- enables screenshots of successful challenge modes / mythic keys.
        ["levelup"] = true,             -- enables screenshots when player level up.
        ["dead"] = false,               -- enables screenshots when player dies.
        ["messages"] = false,           -- print messages when a screenshot event is triggered.
    }
}

function element_proto:Configure(value)
    self.cfg = Mixin(self.cfg or {}, value or {})
    if isInit then
        self:Update()
    end
end

function element_proto:Update()
    if self.cfg.enabled then
        if self.cfg.boss_kills then
            self:RegisterEvent("PLAYER_ENTERING_WORLD")
        end
    
        if self.cfg.achievements then
            self:RegisterEvent("ACHIEVEMENT_EARNED")
        end
    
        if self.cfg.challenge_mode then
            self:RegisterEvent("CHALLENGE_MODE_COMPLETED")
        end
    
        if self.cfg.levelup then
            self:RegisterEvent("PLAYER_LEVEL_UP")
        end

        if self.cfg.dead then
            self:RegisterEvent("PLAYER_DEAD")
        end
    
        if self.cfg.messages then
            self:RegisterEvent("SCREENSHOT_FAILED")
            self:RegisterEvent("SCREENSHOT_SUCCEEDED")
        end
    
        self:UnregisterEvent("PLAYER_LOGIN")
    else
        self:UnregisterAllEvents()
    end
end

function element_proto:OnEvent(event, ...)
    -- call an event handler
    self[event](self, ...)
end

function element_proto:PLAYER_LOGIN()
    if not isInit then
        self:Update()
        isInit = true
    end
end

function element_proto:PLAYER_ENTERING_WORLD()
    local inInstance, instanceType = IsInInstance()
    local isRegistered = self:IsEventRegistered("BOSS_KILL")

    if (inInstance and ZoneTypes[instanceType]) then
        if (isRegistered) then
            self:UnregisterEvent("BOSS_KILL")
        end
        self:RegisterEvent("ENCOUNTER_START")
        self:RegisterEvent("ENCOUNTER_END")
    else
        self:RegisterEvent("BOSS_KILL")
        self:UnregisterEvent("ENCOUNTER_START")
        self:UnregisterEvent("ENCOUNTER_END")
    end
end

function element_proto:ACHIEVEMENT_EARNED(achievementID, alreadyEarned)
    local id, name, points, completed, month, day, year, description, flags,
    icon, rewardText, isGuild, wasEarnedByMe, earnedBy, isStatistic = GetAchievementInfo(achievementID)

    -- delay 1 sec to wait achievement warning to show.
    Wait(1, Screenshot)
end

function element_proto:BOSS_KILL(encounterID, encounterName)
    if encounterName then
        self:Message(string.format("Boss killed: %s", encounterName))
    end

    -- delay 1 sec before take screenshot.
    Wait(1, Screenshot)
end

function element_proto:CHALLENGE_MODE_COMPLETED()
    -- delay 1 sec to wait the right moment.
    Wait(1, Screenshot)
end

function element_proto:ENCOUNTER_START(encounterID, encounterName, difficultyID, groupSize)
    -- record encounter start time
    self.encounterStartTimer = time()
end

function element_proto:ENCOUNTER_END(encounterID, encounterName, difficultyID, groupSize, success)
    -- calculate total time until encounter wipe/success
    local elapsed = time() - self.encounterStartTimer
    local encounterTime = self:GetEncounterTime(elapsed)

    -- check if encounter was a wipe
    local isWipe = (success == 0)
    if isWipe then 
        self:Message(string.format("%s encounter wiped in %s", encounterName, encounterTime))
    elseif EncounterDifficulty[difficultyID] then
        -- display encounter info
        self:Message(string.format("Encounter defeated %s on %s (%d-man)", encounterName, difficulty, groupSize))
        self:Message(string.format("Date: %s", date("%m/%d/%y %H:%M:%S")))
        self:Message(string.format("Time: %s", encounterTime))

        -- take screenshot
        Wait(1, Screenshot)
    end
end

function element_proto:PLAYER_LEVEL_UP()
    -- delay enough for the golden glow ends.
    Wait(2.7, Screenshot)
end

function element_proto:PLAYER_DEAD()
    Wait(0.25, Screenshot)
end

function element_proto:SCREENSHOT_FAILED(...)
    self:Print("ScreenShot failed")
end

function element_proto:SCREENSHOT_SUCCEEDED(...)
    self:Print("ScreenShot taken")
end

function element_proto:GetEncounterTime(elapsed)
    local minutes = math.ceil(elapsed / 60)
    local seconds = math.ceil(elapsed % 60)
    return string.format("%d minutes %d seconds", minutes, seconds)
end

function element_proto:Message(msg)
    if self.cfg.messages then
        DEFAULT_CHAT_FRAME:AddMessage(msg, 1.00, 1.00, 0.00)
    end
end

function element_proto:Print(...)
    print("|cffff8000ScreenShots|r", ...)
end

local frame = Mixin(CreateFrame("Frame"), element_proto)
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", frame.OnEvent)

ns.ScreenShots = frame
-- _G.ScreenShots = frame
