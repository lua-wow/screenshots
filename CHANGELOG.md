# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

-   Interface for every client: Retail, Classic Forever, Classic Era, TBC, WotLK and MoP
-   Options are flat fields on `ns.ScreenShots`, read once at `PLAYER_LOGIN`; `SetOptions`, `Disable` and `enabled` removed
-   Removed client flags and a debug `print`; added `.luacheckrc` and `make check`

### Fixed

-   `tracer = false` now hides "Screenshot Taken/Failed"
-   No error when an encounter ends after a `/reload` mid-fight (time is omitted)
-   Encounter time rounds minutes and seconds down

## [1.2.0] - 2025-08-03

### Changed

-   Replace custom delay method 'Wait' with 'C_Timer.After'

## [1.1.0] - 2024-09-05

### Added

-   New event `PLAYER_DEAD`

### Changed

-   Code refactor
-   Removed `init.lua` and `settings.lua`

## [1.0.0] - 2024-01-02

### Added

- `CHANGELOG.mf' initialized.
