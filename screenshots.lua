local _, ns = ...
local ScreenShots = ns.ScreenShots

-- Blizzard
local Screenshot = _G.Screenshot
local IsInInstance = _G.IsInInstance
local GetAchievementInfo = _G.GetAchievementInfo
local GetDifficultyInfo = _G.GetDifficultyInfo

-- Mine
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
    [23] = true,            -- Dungeon Mythic
    [33] = true,            -- Timewalking Raid
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

local function TakeScreenshot(delay)
    if type(delay) == "number" and delay > 0 then
        C_Timer.After(delay, function() Screenshot() end)
    else
        Screenshot()
    end
end

local function ChatMessage(message)
    if not message then return end
    DEFAULT_CHAT_FRAME:AddMessage(message, 1.0, 1.0, 0.0)
end

----------------------------------------------------------------
-- Screen Shots
----------------------------------------------------------------
local events = {
    ["BOSS_KILL"] = true,                                                                          -- added in patch 6.1.0 (Fired when an instance or open-world boss is killed)
    ["ENCOUNTER_START"] = true,                                                                    -- added in patch 5.4.7
    ["ENCOUNTER_END"] = true,                                                                      -- added in patch 5.4.7
    ["ACHIEVEMENT_EARNED"] = (LE_EXPANSION_LEVEL_CURRENT >= LE_EXPANSION_WRATH_OF_THE_LICH_KING),  -- added in patch 3.0.2 (WoLK)
    ["CHALLENGE_MODE_COMPLETED"] = (LE_EXPANSION_LEVEL_CURRENT >= LE_EXPANSION_MISTS_OF_PANDARIA), -- added in patch 5.0.4 (MoP)
    ["CHALLENGE_MODE_COMPLETED_REWARDS"] = false,                                                  -- added in patch 11.2.0
    ["PLAYER_LEVEL_UP"] = true,
    ["PLAYER_DEAD"] = true,
    ["SCREENSHOT_FAILED"] = true,
    ["SCREENSHOT_SUCCEEDED"] = true
}

local delays = {
    LEVEL_UP = 2.7,
    DEAD = 0.25,
    DEFAULT = 1
}

local element_proto = {
    options = {
        ["enabled"] = true,             -- enables plugin.
        ["achievements"] = true,        -- enables screenshots of earned achievements.
        ["boss_kills"] = true,          -- enables screenshots of successful boss encounters.
        ["challenge_mode"] = true,      -- enables screenshots of successful challenge modes / mythic keys.
        ["levelup"] = true,             -- enables screenshots when player level up.
        ["dead"] = true,                -- enables screenshots when player dies.
        ["messages"] = {
            ["enabled"] = true,         -- print messages when a screenshot event is triggered.
            ["tracer"] = false
        }
    }
}

function element_proto:SetOptions(options)
    if type(options) ~= "table" then return end

    local function merge(a, b)
        for k, v in next, b do
            if type(v) == "table" and type(a[k]) == "table" then
                merge(a[k], v)
            else
                a[k] = v
            end
        end
    end

    merge(self.options, options)
    if self.__init then
        self:Update()
    end
end

function element_proto:Disable()
    self.options.enabled = false
    self:Update()
end

function element_proto:SendMessage(message)
    local opts = self.options and self.options.messages or {}
    if opts.enabled and type(message) == "string" then
        ChatMessage(message)
    end
end

function element_proto:TakeScreenshot(delay, message)
    self:SendMessage(message)
    TakeScreenshot(delay)
end

function element_proto:HookEvent(event, callback, condition)
    if not events[event] then return end

    local enable = true
    if type(condition) == "boolean" then
        enable = condition
    elseif type(condition) == "string" then
        enable = self.options and self.options[condition] or false
    elseif type(condition) == "function" then
        enable = pcall(condition, self.options or {})
    end

    if enable then
        self[event] = callback
        self:RegisterEvent(event)
    end
end

function element_proto:OnEnteringWorld()
    local inInstance, instanceType = IsInInstance()
    local isRegistered = self:IsEventRegistered("BOSS_KILL")

    if (inInstance and ZoneTypes[instanceType]) then
        if (isRegistered) then
            self:UnregisterEvent("BOSS_KILL")
        end
        self:HookEvent("ENCOUNTER_START", self.OnEncounterStart, "boss_kills")
        self:HookEvent("ENCOUNTER_END", self.OnEncounterEnd, "boss_kills")
    else
        self:HookEvent("BOSS_KILL", self.OnBossKill, "boss_kills")
        self:UnregisterEvent("ENCOUNTER_START")
        self:UnregisterEvent("ENCOUNTER_END")
    end
end

function element_proto:OnAchievementEarned(achievementID, alreadyEarned)
    local _, name, points, completed, _, _, _, _, _, _, _, isGuild, wasEarnedByMe, _, _ = GetAchievementInfo(achievementID)
    if not isGuild and not alreadyEarned then
        print("ScreenShots", "alreadyEarned:", alreadyEarned, "wasEarnedByMe:", wasEarnedByMe)
        self:TakeScreenshot(delays.DEFAULT, "Achievement [" .. name .. "] earned (" .. points .. " points)")
    end
end

function element_proto:OnChallengeMode()
    self:TakeScreenshot(delays.DEFAULT, "Challenge completed")
end

function element_proto:OnBossKill(encounterID, encounterName)
    local message = encounterName and ("Boss killed: " .. encounterName) or nil
    self:TakeScreenshot(delays.DEFAULT, message)
end

function element_proto:OnEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    -- record encounter start time
    self.encounter = table.wipe(self.encounter or {})
    self.encounter.id = encounterID
    self.encounter.name = encounterName
    self.encounter.difficultyId = difficultyID
    self.encounter.start = time()
end

function element_proto:OnEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    -- calculate total time until encounter wipe/success
    local elapsed = self.encounter and (time() - (self.encounter.start or 0)) or nil
    local encounterTime = self:GetEncounterTime(elapsed)

    -- check if encounter was a wipe
    local isWipe = (success == 0)
    if isWipe then 
        local message = "Encounter " .. encounterName .. " wiped"
        if (encounterTime) then
            message = message .. " in " .. encounterTime
        end
        self:TakeScreenshot(delays.DEFAULT, message)
    elseif EncounterDifficulty[difficultyID] then
        -- display encounter info
        local difficulty, _, isHeroic, isChallengeMode, displayHeroic, displayMythic, _ = GetDifficultyInfo(difficultyID)
        self:SendMessage("Encounter defeated " .. encounterName .. " on " .. difficulty .. " (" .. groupSize .. "-man)")
        self:SendMessage("Date: " .. date("%m/%d/%y %H:%M:%S"))
        self:SendMessage("Time: " .. encounterTime)

        self:TakeScreenshot(delays.DEFAULT, "Encounter " .. encounterName .. " ended")
    end
end

function element_proto:OnPlayerLevelUp(level, healthDelta, powerDelta, numNewTalents, numNewPvpTalentSlots, strengthDelta, agilityDelta, staminaDelta, intellectDelta)
    -- delay enough for the golden glow ends.
    self:TakeScreenshot(delays.LEVEL_UP, "Player level up to " .. level)
end

function element_proto:OnPlayerDead()
    self:TakeScreenshot(delays.DEAD, "Player died")
end

function element_proto:OnScreenshotFailed(...)
    self:SendMessage("Screenshot Failed")
end

function element_proto:OnScreenshotSucceeded(...)
    self:SendMessage("Screenshot Taken")
end

function element_proto:Update()
    self:UnregisterAllEvents()

    local opts = self.options or {}
    if not opts.enabled then return end

    -- self:UnregisterEvent("PLAYER_LOGIN")
    self:HookEvent("PLAYER_ENTERING_WORLD", self.OnEnteringWorld, true)
    self:HookEvent("ACHIEVEMENT_EARNED", self.OnAchievementEarned, "achievements")
    self:HookEvent("CHALLENGE_MODE_COMPLETED", self.OnChallengeMode, "challenge_mode")
    self:HookEvent("CHALLENGE_MODE_COMPLETED_REWARDS", self.OnChallengeMode, "challenge_mode")
    self:HookEvent("PLAYER_LEVEL_UP", self.OnPlayerLevelUp, "levelup")
    self:HookEvent("PLAYER_DEAD", self.OnPlayerDead, "dead")
    self:HookEvent("SCREENSHOT_FAILED", self.OnScreenshotFailed, function (o) return o.messages and o.messages.tracer end)
    self:HookEvent("SCREENSHOT_SUCCEEDED", self.OnScreenshotSucceeded, function (o) return o.messages and o.messages.tracer end)
end

function element_proto:OnEvent(event, ...)
    if type(self[event]) == "function" then
        self[event](self, ...)
    end
end

function element_proto:PLAYER_LOGIN()
    if not self.__init then
        self:Update()
        self.__init = true
    end
end

function element_proto:GetEncounterTime(elapsed)
    if type(elapsed) ~= "number" then
        return nil
    end

    local minutes = math.ceil(elapsed / 60)
    local seconds = math.ceil(elapsed % 60)
    return string.format("%d minutes %d seconds", minutes, seconds)
end

local frame = Mixin(CreateFrame("Frame"), element_proto)
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", frame.OnEvent)

ScreenShots.Frame = frame
