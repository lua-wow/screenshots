# ScreenShots

World of warcraft addon to take screenshots automatically when some events occure.

## Events

-   `ACHIEVEMENT_EARNED`: Triggered when player earn a achievement.
-   `CHALLENGE_MODE_COMPLETED`: Triggers when `Challenge Mode` (Mists of Pandaria) or `Mythic Keys` is completed.
-   `PLAYER_LEVEL_UP`: Triggered when player level up.

## Usage

### Embedded

```bash
# add this repository as submodule inside your addon
git submodule add --branch master https://github.com/lua-wow/screenshots.git ./libs/screenshots

# initialize submodule and download it
git submodule init --update
```

> Now you can add it to you `.toc` file

### Configuration

```lua
local _, ns = ...
local frame = ns.ScreenShots

frame:Configure({
    enabled = true,
    achievements = true,    -- enables screenshots of earned achievements.
    boss_kills = false,     -- enables screenshots of successful boss encounters.
    challenge_mode = true,  -- enables screenshots of successful challenge modes / mythic keys.
    levelup = true,         -- enables screenshots when player level up.
    dead = false,           -- enables screenshots when player dies.
})
```

## License

Please, see [LICENSE](./LICENSE) file.
