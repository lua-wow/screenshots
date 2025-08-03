local addon, ns = ...
ns.ScreenShots = {}

-- https://warcraft.wiki.gg/wiki/WOW_PROJECT_ID
ns.ScreenShots.isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
ns.ScreenShots.isClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
ns.ScreenShots.isTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
ns.ScreenShots.isWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
ns.ScreenShots.isCata = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)
ns.ScreenShots.isMoP = (WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC)
