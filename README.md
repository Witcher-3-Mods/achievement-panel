# Witcher3ModsAchievementPanel

Witcher3ModsAchievementPanel is an unofficial fan-made mod that adds an in-game achievement panel to The Witcher 3. Open **Glossary → Achievements**, located after **Crafting**. Select an achievement and use the on-screen tracking action to pin or unpin it.

## Features

### Achievement list and details

Browse all 78 achievements from the base game and expansions by category, and inspect each one's description, progress and availability.

![Achievement list with the selected achievement's description and progress](img/achievement-list-and-details.png)

### Tracking, status and restrictions

Pin up to three achievements, keep them visible in collapsed categories (pinned ones sort first), and check your achievement status, difficulty and known restrictions.

![Tracked achievements and the status and restrictions overview](img/tracking-status-and-restrictions.png)

### Live HUD progress

Pinned achievements and their updating progress counters show during gameplay, below your quest objectives.

![Tracked achievement and its progress counter below the active quest on the HUD](img/live-hud-progress.png)

### Also

- Keyboard, mouse and controller navigation.
- Polish text when the game's text language is Polish, English otherwise.
- Pins and category choices are saved in your user settings and shared across saves. Persistence across game restarts still needs in-game verification.
- Read-only display: the mod never unlocks achievements or changes your tracked quest.

Compatibility: the unlock interpretation was checked against Steam on the development setup, not on every platform or build. A response in which all 78 achievements are earned currently produces a readout error, and story-block detection is incomplete.

## Download

Each release has two ZIPs with the same mod:

- **Automatic**: includes `install.cmd` and `uninstall.cmd`. The easy way on Windows.
- **Manual**: no script files at all (nothing for an antivirus or a file host to flag). You copy the folder yourself, see [below](#install-or-update-by-hand).

## Install automatically (Windows)

1. Close the game. Download the **Automatic** ZIP from the **Releases** page and extract it anywhere.
2. In the extracted `modWitcher3ModsAchievementPanel` folder, double-click **`install.cmd`**. It finds your Witcher 3 folder (Steam, GOG, Epic or the usual folders on every drive; it asks for the path if needed) and replaces any previous version, including one installed under an old misspelled folder name.

To remove the mod, double-click **`uninstall.cmd`** (in the extracted folder or in `mods\modWitcher3ModsAchievementPanel`). It removes the mod folder and your saved pins (only the mod's section in the `*user.settings` files in `Documents\The Witcher 3`, after making a copy of each file it edits) and nothing else.

Both files are plain text, so you can open them in Notepad and read exactly what they do. Windows SmartScreen may warn about a downloaded script: choose **More info, Run anyway** if you trust it, or use the Manual package.

## Install or update by hand

Requires the PC next-gen version of The Witcher 3. REDkit is not required to play. Back up your saves and mod installation before updating.

1. Close the game and open its `mods` folder (create it if missing). On Steam: right-click the game → **Manage → Browse local files**; typically `C:\Program Files (x86)\Steam\steamapps\common\The Witcher 3\mods\`.
2. For an update, first move the previous mod folder **outside `mods`**, including one from an earlier release with a slightly different (misspelled) name. Do not merge this modular version with the old single-file version.
3. Copy the `modWitcher3ModsAchievementPanel` folder from the **Manual** ZIP into `mods`; its `.ws` files must end up in `mods\modWitcher3ModsAchievementPanel\content\scripts\local\`. Start the game, allow script compilation and load your save.

Instead of a ZIP you can copy this repository's `src/modWitcher3ModsAchievementPanel` folder; it also holds the installers' sources, which the game ignores.

To uninstall by hand, close the game and move the panel folder outside `mods`. Keep backups outside that folder too.

## License

Original project material uses the [Personal Noncommercial Use License](LICENSE): source inspection, local builds and modifications for private, noncommercial use with a lawful copy of The Witcher 3. Redistribution requires separate permission, except for rights preserved in LICENSE (including earlier grants and CDPR/platform rights). This is source-available, not MIT or OSI open source; third-party licenses remain separate.

CDPR supplies Flash UI sources for modding in the [REDkit FAQ](https://www.thewitcher.com/us/en/redkit/modding). Use of this mod is limited to noncommercial play within The Witcher 3, subject to the [REDkit EULA](https://store.steampowered.com/eula/2889630_eula_0), [Fan Content Guidelines](https://www.cdprojektred.com/en/fan-content) and applicable game terms. These do not make third-party middleware freely redistributable as a standalone SDK. See [THIRD-PARTY-NOTICES.txt](THIRD-PARTY-NOTICES.txt); both notices and LICENSE accompany the installable mod.

This is an unofficial fan work and is not approved or endorsed by CD PROJEKT RED. Provided **as is, without warranty**, subject to LICENSE and applicable law.
