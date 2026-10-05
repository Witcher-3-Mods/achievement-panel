@echo off
rem ===========================================================================
rem  Achievement Panel installer. Double-click this file to run it, or open it in
rem  Notepad to read it. This file is both a batch file and a PowerShell script:
rem  the one line below starts PowerShell, which reads the rest of this file
rem  (everything below the marker line) and runs it.
rem
rem  It finds your Witcher 3 folder and installs this mod from the files you
rem  downloaded: it replaces any previous version in the mods folder.
rem  Run it from the extracted download (keep the folders of the ZIP together).
rem  Optional switches (used by the maintainers for testing):
rem    /yes                 do not ask for confirmation
rem    /game:"C:\path"      use this game folder instead of searching
rem ===========================================================================
set "W3M_SELF=%~f0"
set W3M_ARGS=%*
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText($env:W3M_SELF,[Text.Encoding]::UTF8); Invoke-Expression $s.Substring($s.IndexOf('#'+'POWERSHELL'))" && exit /b 0 || exit /b 1
#POWERSHELL
$ErrorActionPreference = 'Stop'

# ---- What this installer puts where. -----------------------------------------
$ModFolder = 'modWitcher3ModsAchievementPanel'      # copied to <game>\mods\<this folder>
$ModTitle  = 'Achievement Panel'
$ConfigXml = ''      # copied to <game>\bin\config\r4game\user_config_matrix\pc\ (empty: none)
# -----------------------------------------------------------------------------

$argText = [string]$env:W3M_ARGS
$yes     = $argText -match '(?i)(^|\s)/yes(\s|$)'
function Get-Switch([string]$Name) {
    if ($argText -match ('(?i)(^|\s)/' + $Name + ':(?:"([^"]*)"|(\S+))')) {
        if ($Matches[2]) { return $Matches[2] } else { return $Matches[3] }
    }
    return $null
}
function Pause-Exit([int]$Code) {
    if (-not $yes) { [void](Read-Host 'Press Enter to close') }
    exit $Code
}
function Test-GameDir([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path 'bin\config\r4game')) -and (Test-Path -LiteralPath (Join-Path $Path 'content\content0')))
}

# Looks in the places a Witcher 3 install usually is: Steam libraries, GOG, Epic
# and the usual folders on every fixed drive.
function Find-GameDirs {
    $found = New-Object 'System.Collections.Generic.List[string]'
    $steamRoots = @()
    foreach ($reg in @('HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam')) {
        $item = Get-ItemProperty -Path $reg -ErrorAction SilentlyContinue
        if ($item) { $steamRoots += @($item.SteamPath, $item.InstallPath) }
    }
    $folders = @('The Witcher 3', 'The Witcher 3 Wild Hunt')
    foreach ($root in ($steamRoots | Where-Object { $_ } | Select-Object -Unique)) {
        $libs = @($root)
        $vdf = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) { $libs += $m.Groups[1].Value.Replace('\\', '\') }
        }
        foreach ($lib in $libs) { foreach ($f in $folders) { $found.Add((Join-Path $lib "steamapps\common\$f")) } }
    }
    foreach ($id in @('1495134320', '1207664643')) {
        $gog = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games\$id" -ErrorAction SilentlyContinue
        if ($gog -and $gog.path) { $found.Add([string]$gog.path) }
    }
    foreach ($drive in [IO.DriveInfo]::GetDrives()) {
        if ($drive.DriveType -ne 'Fixed' -or -not $drive.IsReady) { continue }
        $r = $drive.RootDirectory.FullName
        foreach ($rel in @(
            'Program Files (x86)\Steam\steamapps\common\The Witcher 3', 'SteamLibrary\steamapps\common\The Witcher 3',
            'Steam\steamapps\common\The Witcher 3', 'Games\Steam\steamapps\common\The Witcher 3',
            'GOG Games\The Witcher 3 Wild Hunt GOTY', 'GOG Games\The Witcher 3 Wild Hunt',
            'Program Files (x86)\GOG Galaxy\Games\The Witcher 3 Wild Hunt GOTY', 'Program Files (x86)\GOG Galaxy\Games\The Witcher 3 Wild Hunt',
            'Program Files\Epic Games\TheWitcher3', 'Epic Games\TheWitcher3', 'Games\The Witcher 3')) {
            $found.Add((Join-Path $r $rel))
        }
    }
    return @($found | Where-Object { Test-GameDir $_ } | ForEach-Object { [IO.Path]::GetFullPath($_).TrimEnd('\') } | Select-Object -Unique)
}

function Resolve-GameDir {
    $given = Get-Switch 'game'
    if ($given) {
        if (-not (Test-GameDir $given)) { throw "Not a Witcher 3 folder: $given" }
        return [IO.Path]::GetFullPath($given).TrimEnd('\')
    }
    # Run from <game>\mods\<mod>: that game is the one to use, no searching needed.
    $modsDir = Split-Path (Split-Path $env:W3M_SELF -Parent) -Parent
    if ((Split-Path $modsDir -Leaf) -eq 'mods' -and (Test-GameDir (Split-Path $modsDir -Parent))) {
        $here = [IO.Path]::GetFullPath((Split-Path $modsDir -Parent)).TrimEnd('\')
        Write-Host "Using the game folder this mod is in: $here"
        return $here
    }
    $candidates = @(Find-GameDirs)
    if ($candidates.Count -eq 1) { Write-Host "Found The Witcher 3: $($candidates[0])"; return $candidates[0] }
    if ($yes) { throw 'Could not decide which game folder to use. Pass /game:"C:\path\to\The Witcher 3".' }
    while ($true) {
        if ($candidates.Count -gt 1) {
            Write-Host 'Found several Witcher 3 folders:'
            for ($i = 0; $i -lt $candidates.Count; $i++) { Write-Host ('  {0}) {1}' -f ($i + 1), $candidates[$i]) }
            $answer = Read-Host 'Type a number, or paste the full path of the game folder'
        } else {
            Write-Host 'Could not find The Witcher 3 in the usual places.'
            $answer = Read-Host 'Paste the full path of the game folder (the one that contains bin, content and mods)'
        }
        $answer = ([string]$answer).Trim().Trim('"')
        if ($answer -match '^\d+$' -and [int]$answer -ge 1 -and [int]$answer -le $candidates.Count) { return $candidates[[int]$answer - 1] }
        if (Test-GameDir $answer) { return [IO.Path]::GetFullPath($answer).TrimEnd('\') }
        Write-Host "That is not a Witcher 3 folder: $answer"
    }
}

try {
    Write-Host "$ModTitle installer"
    Write-Host ''
    $source = Split-Path $env:W3M_SELF -Parent
    if (-not (Test-Path -LiteralPath (Join-Path $source 'content'))) {
        throw "This is not the complete $ModTitle folder: no 'content' folder next to this file. Extract the whole ZIP first, then run this from the extracted folder."
    }
    $game = Resolve-GameDir
    $dest = Join-Path $game "mods\$ModFolder"
    $sameFolder = ([IO.Path]::GetFullPath($source).TrimEnd('\') -ieq [IO.Path]::GetFullPath($dest).TrimEnd('\'))
    # Earlier releases used a misspelled folder name. Two copies of the scripts would clash, so a copy under that name is removed.
    $legacy = @()
    if (Test-Path -LiteralPath (Join-Path $game 'mods')) {
        $legacy = @(Get-ChildItem -LiteralPath (Join-Path $game 'mods') -Directory -Filter 'modWitcher3ModsAch*Panel' | Where-Object { $_.Name -ne $ModFolder -and $_.FullName.TrimEnd('\') -ne [IO.Path]::GetFullPath($source).TrimEnd('\') })
    }

    # The config XML is next to the mod folder inside the repository layout and two folders up inside the release ZIP.
    $xmlTarget = $null
    $xmlSource = $null
    if ($ConfigXml) {
        $xmlTarget = Join-Path $game "bin\config\r4game\user_config_matrix\pc\$ConfigXml"
        foreach ($c in @((Join-Path $source "bin\config\r4game\user_config_matrix\pc\$ConfigXml"),
                         (Join-Path $source "..\..\bin\config\r4game\user_config_matrix\pc\$ConfigXml"))) {
            if (-not $xmlSource -and (Test-Path -LiteralPath $c)) { $xmlSource = (Resolve-Path -LiteralPath $c).Path }
        }
        if (-not $xmlSource -and -not (Test-Path -LiteralPath $xmlTarget)) {
            throw "Could not find $ConfigXml next to the mod. Extract the whole ZIP, keeping its 'bin' folder, and run this again."
        }
    }

    if (Get-Process -Name 'witcher3' -ErrorAction SilentlyContinue) {
        throw 'The Witcher 3 is running. Close the game and run this again.'
    }
    Write-Host "Game folder: $game"
    Write-Host 'This will:'
    if ($sameFolder) { Write-Host "  - keep the mod where it already is: $dest" }
    elseif (Test-Path -LiteralPath $dest) { Write-Host "  - replace the installed mod: $dest" }
    else { Write-Host "  - install the mod to: $dest" }
    if ($xmlSource) { Write-Host "  - copy the option definition to: $xmlTarget" }
    foreach ($old in $legacy) { Write-Host "  - remove the former copy under its old folder name: $($old.FullName)" }
    if (-not $yes) {
        $answer = Read-Host 'Continue? [Y/n]'
        if ($answer -match '^\s*n') { Write-Host 'Cancelled. Nothing was changed.'; Pause-Exit 0 }
    }

    if (-not $sameFolder) {
        if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
        New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
        Copy-Item -LiteralPath $source -Destination $dest -Recurse -Force
        Write-Host "Installed $dest"
    }
    foreach ($old in $legacy) { Remove-Item -LiteralPath $old.FullName -Recurse -Force; Write-Host "Removed $($old.FullName)" }
    if ($xmlSource) {
        New-Item -ItemType Directory -Force -Path (Split-Path $xmlTarget -Parent) | Out-Null
        Copy-Item -LiteralPath $xmlSource -Destination $xmlTarget -Force
        Write-Host "Installed $xmlTarget"
    }
    # The engine reads the config only from <game>\bin\config and ignores a bin folder inside the mod folder.
    $strayBin = Join-Path $dest 'bin'
    if ($ConfigXml -and (Test-Path -LiteralPath $strayBin)) { Remove-Item -LiteralPath $strayBin -Recurse -Force }

    if (-not (Test-Path -LiteralPath (Join-Path $dest 'content'))) { throw "Installation failed: $dest has no content folder." }
    if ($ConfigXml -and -not (Test-Path -LiteralPath $xmlTarget)) { throw "Installation failed: $xmlTarget is missing." }
    Write-Host ''
    Write-Host "$ModTitle was installed."
    Write-Host 'Start the game and let the scripts compile. Open Glossary > Achievements (after Crafting).'
    Pause-Exit 0
} catch {
    Write-Host ''
    Write-Host "Error: $($_.Exception.Message)"
    Pause-Exit 1
}
