param(
    # Folder with install.exe and uninstall.exe, built by tools/Build-Witcher3ModsInstallers.ps1.
    [Parameter(Mandatory=$true)][string]$InstallerDirectory
)
# End-to-end test of the two .exe files against a fake game folder: install, uninstall from inside the installed mod folder (the
# way users run it, with that folder as the working directory), and uninstall from the extracted download.
$ErrorActionPreference = 'Stop'
$Witcher3ModsInstallers = [IO.Path]::GetFullPath($InstallerDirectory)
$Witcher3ModsModName = 'modWitcher3ModsAchievementPanel'
# The work folder is kept short: the C# runtime and Windows PowerShell 5.1 reject long paths.
$Witcher3ModsWork = Join-Path ([IO.Path]::GetTempPath()) ('w3m-test-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))

function Assert-Witcher3Mods([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "Test failed: $Message" }
    Write-Output "ok: $Message"
}
function Invoke-Witcher3Mods([string]$Exe, [string[]]$Arguments, [string]$WorkingDirectory) {
    $process = Start-Process -FilePath $Exe -ArgumentList $Arguments -WorkingDirectory $WorkingDirectory -Wait -PassThru -WindowStyle Hidden
    return $process.ExitCode
}

# Runs a program with the given lines typed on its keyboard; returns its exit code and everything it printed.
function Invoke-Witcher3ModsInteractive([string]$Exe, [string[]]$Arguments, [string]$WorkingDirectory, [string]$Typed) {
    $start = New-Object Diagnostics.ProcessStartInfo $Exe
    $start.Arguments = $Arguments -join ' '
    $start.WorkingDirectory = $WorkingDirectory
    $start.UseShellExecute = $false
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.CreateNoWindow = $true
    $process = [Diagnostics.Process]::Start($start)
    $process.StandardInput.Write($Typed)
    $process.StandardInput.Close()
    $output = $process.StandardOutput.ReadToEnd()
    $process.WaitForExit()
    return [pscustomobject]@{ ExitCode = $process.ExitCode; Output = $output }
}

try {
    $game = Join-Path $Witcher3ModsWork 'game'
    $docs = Join-Path $Witcher3ModsWork 'docs'
    $download = Join-Path $Witcher3ModsWork "download\$Witcher3ModsModName"
    foreach ($dir in @("$game\bin\config\r4game", "$game\content\content0", "$game\mods\modOtherMod", $docs, "$download\content")) { New-Item -ItemType Directory -Force $dir | Out-Null }
    Set-Content -LiteralPath "$game\mods\modOtherMod\keep.txt" -Value 'other mod'
    Set-Content -LiteralPath "$download\content\blob0.bundle" -Value 'bundle'
    Copy-Item "$Witcher3ModsInstallers\install.exe", "$Witcher3ModsInstallers\uninstall.exe" $download
    $settings = "$docs\user.settings"
    [IO.File]::WriteAllText($settings, "[Video]`r`nBrightness=1`r`n[Witcher3ModsAchievementPanel]`r`nPinned=3`r`n[Audio]`r`nVolume=7`r`n", [Text.Encoding]::GetEncoding(28591))
    $mod = "$game\mods\$Witcher3ModsModName"

    # Install into the fake game, once as a clean install and once over an existing copy.
    Assert-Witcher3Mods ((Invoke-Witcher3Mods "$download\install.exe" @('/yes', "`"/game:$game`"") $download) -eq 0) 'install.exe exits with 0'
    Assert-Witcher3Mods (Test-Path -LiteralPath "$mod\content\blob0.bundle") 'install.exe copied the mod'
    Assert-Witcher3Mods ((Test-Path -LiteralPath "$mod\uninstall.exe") -and (Test-Path -LiteralPath "$mod\install.exe")) 'the installed mod carries both programs'
    Assert-Witcher3Mods ((Invoke-Witcher3Mods "$download\install.exe" @('/yes', "`"/game:$game`"") $download) -eq 0) 'installing over an existing copy exits with 0'

    # A junction inside the mod folder must be removed as a link, never followed.
    $outside = Join-Path $Witcher3ModsWork 'outside'
    New-Item -ItemType Directory -Force $outside | Out-Null
    Set-Content -LiteralPath "$outside\canary.txt" -Value 'must survive'
    New-Item -ItemType Junction -Path "$mod\link" -Target $outside | Out-Null

    # Uninstall the way a user does: double-click uninstall.exe inside the mod folder (that folder is the working directory).
    Assert-Witcher3Mods ((Invoke-Witcher3Mods "$mod\uninstall.exe" @('/yes', "`"/docs:$docs`"") $mod) -eq 0) 'uninstall.exe run from the mod folder exits with 0'
    Assert-Witcher3Mods (-not (Test-Path -LiteralPath "$mod\content")) 'the mod folder content is gone'
    Assert-Witcher3Mods (-not (Test-Path -LiteralPath "$mod\link")) 'the junction is gone'
    Assert-Witcher3Mods (Test-Path -LiteralPath "$outside\canary.txt") 'the junction target was not touched'
    Assert-Witcher3Mods (@(Get-ChildItem -LiteralPath $mod -Force).Name -join ',' -eq 'uninstall.exe') 'only the running uninstall.exe is left behind'
    Assert-Witcher3Mods (Test-Path -LiteralPath "$game\mods\modOtherMod\keep.txt") 'another mod was not touched'
    $text = [IO.File]::ReadAllText($settings, [Text.Encoding]::GetEncoding(28591))
    Assert-Witcher3Mods (($text -notmatch 'Witcher3ModsAchievementPanel') -and ($text -match 'Brightness=1') -and ($text -match 'Volume=7')) 'only the mod section left user.settings'
    Assert-Witcher3Mods (@(Get-ChildItem $docs -Filter 'user.settings.bak-uninstall-*').Count -eq 1) 'a backup of user.settings was made'

    # Interactive uninstall from the mod folder. Answers: confirm, two invalid choices, then option 1 (the user deletes the folder).
    Remove-Item -LiteralPath $mod -Recurse -Force
    Assert-Witcher3Mods ((Invoke-Witcher3Mods "$download\install.exe" @('/yes', "`"/game:$game`"") $download) -eq 0) 'installing again exits with 0'
    $run = Invoke-Witcher3ModsInteractive "$mod\uninstall.exe" @("`"/docs:$docs`"") $mod "y`r`nx`r`n3`r`n1`r`n`r`n"
    Assert-Witcher3Mods ($run.ExitCode -eq 0) 'interactive uninstall exits with 0'
    Assert-Witcher3Mods (([regex]::Matches($run.Output, 'Please type 1 or 2\.')).Count -eq 2) 'anything but 1 or 2 asks again'
    Assert-Witcher3Mods (@(Get-ChildItem -LiteralPath $mod -Force).Name -join ',' -eq 'uninstall.exe') 'option 1 leaves the folder to the user'

    # Interactive uninstall, option 2: everything including uninstall.exe and its folder goes, a moment after the window closes.
    Remove-Item -LiteralPath $mod -Recurse -Force
    Assert-Witcher3Mods ((Invoke-Witcher3Mods "$download\install.exe" @('/yes', "`"/game:$game`"") $download) -eq 0) 'installing once more exits with 0'
    $run = Invoke-Witcher3ModsInteractive "$mod\uninstall.exe" @("`"/docs:$docs`"") $mod "y`r`n2`r`n"
    Assert-Witcher3Mods ($run.ExitCode -eq 0) 'uninstall with option 2 exits with 0'
    $deadline = (Get-Date).AddSeconds(20)
    while ((Test-Path -LiteralPath $mod) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 300 }
    Assert-Witcher3Mods (-not (Test-Path -LiteralPath $mod)) 'option 2 removed uninstall.exe and the mod folder'

    # Uninstall from the extracted download: finds the game by itself when told where it is, and removes the folder completely.
    Assert-Witcher3Mods ((Invoke-Witcher3Mods "$download\install.exe" @('/yes', "`"/game:$game`"") $download) -eq 0) 'installing again exits with 0'
    Assert-Witcher3Mods ((Invoke-Witcher3Mods "$download\uninstall.exe" @('/yes', "`"/game:$game`"", "`"/docs:$docs`"") $download) -eq 0) 'uninstall.exe run from the download exits with 0'
    Assert-Witcher3Mods (-not (Test-Path -LiteralPath $mod)) 'the mod folder was removed completely'
    Assert-Witcher3Mods ((Invoke-Witcher3Mods "$download\uninstall.exe" @('/yes', "`"/game:$game`"", "`"/docs:$docs`"") $download) -eq 0) 'uninstalling when nothing is installed exits with 0'

    # A folder that is not a game is rejected with exit code 1.
    Assert-Witcher3Mods ((Invoke-Witcher3Mods "$download\uninstall.exe" @('/yes', "`"/game:$Witcher3ModsWork`"") $download) -eq 1) 'a folder that is not a game exits with 1'
    Write-Output 'Installer end-to-end test passed.'
} finally {
    Remove-Item -LiteralPath $Witcher3ModsWork -Recurse -Force -ErrorAction SilentlyContinue
}
