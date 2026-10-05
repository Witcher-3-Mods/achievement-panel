@echo off
rem ===========================================================================
rem  Achievement Panel uninstaller. Double-click this file to run it, or open it in
rem  Notepad to read it. This file is both a batch file and a PowerShell script:
rem  the one line below starts PowerShell, which reads the rest of this file
rem  (everything below the marker line) and runs it.
rem
rem  It finds your Witcher 3 folder, then removes this mod and only this mod.
rem  Optional switches (used by the maintainers for testing):
rem    /yes                 do not ask for confirmation
rem    /game:"C:\path"      use this game folder instead of searching
rem    /docs:"C:\path"      use this folder instead of Documents\The Witcher 3
rem
rem  The (goto) after the PowerShell line leaves this file without reading it again,
rem  so the uninstaller can delete the folder it is running from.
rem ===========================================================================
set "W3M_SELF=%~f0"
set W3M_ARGS=%*
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText($env:W3M_SELF,[Text.Encoding]::UTF8); Invoke-Expression $s.Substring($s.IndexOf('#'+'POWERSHELL'))" & (goto) 2>nul & exit /b 0
#POWERSHELL
$ErrorActionPreference = 'Stop'

# ---- What this uninstaller removes. Everything else is left alone. ----------
$ModFolder = 'modWitcher3ModsAchievementPanel'      # <game>\mods\<this folder>
$ModTitle  = 'Achievement Panel'
$ConfigXml = ''      # <game>\bin\config\r4game\user_config_matrix\pc\<this file>
$Sections  = @('Witcher3ModsAchievementPanel')       # whole sections in the *user.settings files
$Keys      = @()           # single keys in other sections
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

# Settings files are edited as raw bytes (Latin-1 round-trips every byte), so
# nothing but the mod's own lines changes. Returns how many lines belong to the mod.
$Latin1 = [Text.Encoding]::GetEncoding(28591)
function Edit-Settings([string]$File, [bool]$Apply) {
    $lines = [regex]::Split([IO.File]::ReadAllText($File, $Latin1), '(?<=\n)')
    $kept = New-Object 'System.Collections.Generic.List[string]'
    $section = ''
    $removed = 0
    foreach ($line in $lines) {
        if ($line -match '^\s*\[([^\]\r\n]+)\]\s*$') { $section = $Matches[1] }
        $drop = $Sections -contains $section
        if (-not $drop) {
            foreach ($k in $Keys) { if ($section -eq $k.Section -and $line -match ('^\s*' + [regex]::Escape($k.Key) + '\s*=')) { $drop = $true } }
        }
        if ($drop) { $removed++ } else { $kept.Add($line) }
    }
    if ($Apply -and $removed -gt 0) {
        Copy-Item -LiteralPath $File -Destination ($File + '.bak-uninstall-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
        [IO.File]::WriteAllText($File, (-join $kept), $Latin1)
    }
    return $removed
}

try {
    Write-Host "$ModTitle uninstaller"
    Write-Host ''
    $game = Resolve-GameDir
    $docs = Get-Switch 'docs'
    if (-not $docs) { $docs = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'The Witcher 3' }

    $modDir  = Join-Path $game "mods\$ModFolder"
    # Also the copy that earlier releases installed under a misspelled folder name.
    $legacy = @()
    if (Test-Path -LiteralPath (Join-Path $game 'mods')) {
        $legacy = @(Get-ChildItem -LiteralPath (Join-Path $game 'mods') -Directory -Filter 'modWitcher3ModsAch*Panel' | Where-Object { $_.Name -ne $ModFolder })
    }
    $xmlPath = $null
    if ($ConfigXml) { $xmlPath = Join-Path $game "bin\config\r4game\user_config_matrix\pc\$ConfigXml" }
    $settings = @()
    foreach ($name in @('user.settings', 'dx11user.settings', 'dx12user.settings')) {
        $path = Join-Path $docs $name
        if ((Test-Path -LiteralPath $path) -and (Edit-Settings $path $false) -gt 0) { $settings += $path }
    }

    $present = @()
    if (Test-Path -LiteralPath $modDir)  { $present += "Mod folder:        $modDir" }
    foreach ($old in $legacy)            { $present += "Former mod folder: $($old.FullName)" }
    if ($xmlPath -and (Test-Path -LiteralPath $xmlPath)) { $present += "Option definition: $xmlPath" }
    foreach ($path in $settings)         { $present += "Saved option value: $path (the mod's section only)" }
    if ($present.Count -eq 0) {
        Write-Host "$ModTitle is not installed in $game. Nothing to remove."
        Pause-Exit 0
    }
    if (Get-Process -Name 'witcher3' -ErrorAction SilentlyContinue) {
        throw 'The Witcher 3 is running. Close the game and run this again.'
    }
    Write-Host "Game folder: $game"
    Write-Host 'This will remove:'
    foreach ($p in $present) { Write-Host "  $p" }
    Write-Host 'Other mods and the rest of your settings are not touched.'
    if (-not $yes) {
        $answer = Read-Host 'Continue? [Y/n]'
        if ($answer -match '^\s*n') { Write-Host 'Cancelled. Nothing was changed.'; Pause-Exit 0 }
    }

    if (Test-Path -LiteralPath $modDir) {
        Remove-Item -LiteralPath $modDir -Recurse -Force
        Write-Host "Removed $modDir"
    }
    foreach ($old in $legacy) {
        Remove-Item -LiteralPath $old.FullName -Recurse -Force
        Write-Host "Removed $($old.FullName)"
    }
    if ($xmlPath -and (Test-Path -LiteralPath $xmlPath)) {
        Remove-Item -LiteralPath $xmlPath -Force
        Write-Host "Removed $xmlPath"
    }
    foreach ($path in $settings) {
        $n = Edit-Settings $path $true
        Write-Host "Removed $n line(s) from $path (a copy is next to it: *.bak-uninstall-*)"
    }
    Write-Host ''
    Write-Host "$ModTitle was uninstalled."
    Pause-Exit 0
} catch {
    Write-Host ''
    Write-Host "Error: $($_.Exception.Message)"
    Pause-Exit 1
}
