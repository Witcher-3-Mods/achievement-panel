param(
    [Parameter(Mandatory=$true)][string]$OutputPath,
    # Automatic: the mod folder plus install.exe and uninstall.exe. Manual: the mod folder alone, with no program in it, to be copied into the game's mods folder by hand.
    [ValidateSet('Automatic','Manual')][string]$Variant = 'Automatic',
    # Folder with install.exe and uninstall.exe, built by tools/Build-Witcher3ModsInstallers.ps1 (Automatic only). They are build output, not repository files.
    [string]$InstallerDirectory
)
$ErrorActionPreference = 'Stop'
$Witcher3ModsRoot = Split-Path $PSScriptRoot -Parent
$Witcher3ModsPackage = Join-Path $Witcher3ModsRoot 'src/modWitcher3ModsAchievementPanel'
# Repository files of the package. The installers' sources (Common.cs, Install.cs, Uninstall.cs) stay in the repository: the ZIP carries only the built .exe files.
$Witcher3ModsSourceExpected = @('LICENSE','THIRD-PARTY-NOTICES.txt','README.md','Common.cs','Install.cs','Uninstall.cs','locales/en.json','locales/pl.json','content/blob0.bundle','content/metadata.store')
$Witcher3ModsSourceExpected += @('AchievementCatalog','AchievementPresenter','AchievementReadout','AchievementTracking','GameQueries','Localization','MenuIntegration') | ForEach-Object { 'content/scripts/local/Witcher3Mods' + $_ + '.ws' }
$Witcher3ModsBuiltExpected = @(if ($Variant -eq 'Automatic') { 'install.exe'; 'uninstall.exe' })
$Witcher3ModsRepositoryOnly = @('Common.cs','Install.cs','Uninstall.cs')
$Witcher3ModsExpected = @($Witcher3ModsSourceExpected | Where-Object { $_ -notin $Witcher3ModsRepositoryOnly }) + $Witcher3ModsBuiltExpected
if ((Get-FileHash "$Witcher3ModsRoot/LICENSE").Hash -ne (Get-FileHash "$Witcher3ModsPackage/LICENSE").Hash) { throw 'Root and packaged licenses differ.' }
if ((Get-FileHash "$Witcher3ModsRoot/THIRD-PARTY-NOTICES.txt").Hash -ne (Get-FileHash "$Witcher3ModsPackage/THIRD-PARTY-NOTICES.txt").Hash) { throw 'Root and packaged notices differ.' }
if ((Get-Content "$Witcher3ModsPackage/THIRD-PARTY-NOTICES.txt" -Raw).Length -lt 100) { throw 'Missing third-party notices.' }
$Witcher3ModsFiles = @(Get-ChildItem -LiteralPath $Witcher3ModsPackage -Recurse -Force -File)
foreach ($Witcher3ModsItem in @(Get-Item $Witcher3ModsPackage) + @(Get-ChildItem $Witcher3ModsPackage -Recurse -Force)) {
    if ($Witcher3ModsItem.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Package must not contain symlinks/junctions.' }
}
if ($Witcher3ModsFiles.Count -ne $Witcher3ModsSourceExpected.Count) { throw 'Unexpected or missing package files.' }
foreach ($Witcher3ModsFile in $Witcher3ModsFiles) {
    $Witcher3ModsRelative = $Witcher3ModsFile.FullName.Substring($Witcher3ModsPackage.Length + 1).Replace('\','/')
    if ($Witcher3ModsRelative -notin $Witcher3ModsSourceExpected -or $Witcher3ModsFile.Length -eq 0) { throw "Invalid package member: $Witcher3ModsRelative" }
}
if ($Variant -eq 'Automatic') {
    if (-not $InstallerDirectory) { throw 'The Automatic package needs -InstallerDirectory.' }
    $Witcher3ModsInstallers = [IO.Path]::GetFullPath($InstallerDirectory)
}
foreach ($Witcher3ModsBuilt in $Witcher3ModsBuiltExpected) {
    $Witcher3ModsBuiltPath = Join-Path $Witcher3ModsInstallers $Witcher3ModsBuilt
    if (-not (Test-Path -LiteralPath $Witcher3ModsBuiltPath -PathType Leaf) -or (Get-Item -LiteralPath $Witcher3ModsBuiltPath).Length -eq 0) { throw "Missing built installer: $Witcher3ModsBuiltPath" }
}
$Witcher3ModsOutput = [IO.Path]::GetFullPath($OutputPath)
if ($Witcher3ModsOutput.StartsWith($Witcher3ModsPackage + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Archive output must be outside the package.' }
if (Test-Path -LiteralPath $Witcher3ModsOutput) { throw 'Refusing to overwrite an existing archive.' }
New-Item -ItemType Directory -Force (Split-Path $Witcher3ModsOutput -Parent) | Out-Null

# The archive is made from a staging copy: the repository package without the installers' sources, plus (Automatic only) the installers built for this release.
# Every member is checked against an exact list, so the Manual package cannot contain an .exe.
$Witcher3ModsStagingRoot = Join-Path ([IO.Path]::GetTempPath()) ('w3m-stage-' + [Guid]::NewGuid().ToString('N'))
$Witcher3ModsStage = Join-Path $Witcher3ModsStagingRoot 'modWitcher3ModsAchievementPanel'
$Witcher3ModsZip = $null
try {
    New-Item -ItemType Directory -Force $Witcher3ModsStagingRoot | Out-Null
    Copy-Item -LiteralPath $Witcher3ModsPackage -Destination $Witcher3ModsStage -Recurse
    foreach ($Witcher3ModsOmitted in $Witcher3ModsRepositoryOnly) { Remove-Item -LiteralPath (Join-Path $Witcher3ModsStage $Witcher3ModsOmitted) -Force }
    foreach ($Witcher3ModsBuilt in $Witcher3ModsBuiltExpected) { Copy-Item -LiteralPath (Join-Path $Witcher3ModsInstallers $Witcher3ModsBuilt) -Destination $Witcher3ModsStage }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::CreateFromDirectory($Witcher3ModsStage, $Witcher3ModsOutput, [IO.Compression.CompressionLevel]::Optimal, $true)
    $Witcher3ModsZip = [IO.Compression.ZipFile]::OpenRead($Witcher3ModsOutput)
    $Witcher3ModsMembers = @($Witcher3ModsZip.Entries | Where-Object { $_.Name })
    if ($Witcher3ModsMembers.Count -ne $Witcher3ModsExpected.Count) { throw 'Archive member count mismatch.' }
    foreach ($Witcher3ModsMember in $Witcher3ModsMembers) {
        $Witcher3ModsRelative = $Witcher3ModsMember.FullName.Replace('\','/')
        if (-not $Witcher3ModsRelative.StartsWith('modWitcher3ModsAchievementPanel/')) { throw 'Missing installable top-level folder.' }
        $Witcher3ModsRelative = $Witcher3ModsRelative.Substring('modWitcher3ModsAchievementPanel/'.Length)
        if ($Witcher3ModsRelative -notin $Witcher3ModsExpected) { throw 'Unexpected ZIP path.' }
        $Witcher3ModsStream = $Witcher3ModsMember.Open()
        $Witcher3ModsSha = [Security.Cryptography.SHA256]::Create()
        try { $Witcher3ModsHash = [BitConverter]::ToString($Witcher3ModsSha.ComputeHash($Witcher3ModsStream)).Replace('-','') }
        finally { $Witcher3ModsStream.Dispose(); $Witcher3ModsSha.Dispose() }
        # Sources are compared with the repository; the .exe files with the build output.
        if ($Witcher3ModsRelative -in $Witcher3ModsBuiltExpected) { $Witcher3ModsOriginal = Join-Path $Witcher3ModsInstallers $Witcher3ModsRelative }
        else { $Witcher3ModsOriginal = Join-Path $Witcher3ModsPackage $Witcher3ModsRelative }
        if ($Witcher3ModsHash -ne (Get-FileHash $Witcher3ModsOriginal).Hash) { throw 'ZIP byte verification failed.' }
    }
} finally {
    if ($Witcher3ModsZip) { $Witcher3ModsZip.Dispose() }
    Remove-Item -LiteralPath $Witcher3ModsStagingRoot -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Output "Verified $Variant release ZIP: $Witcher3ModsOutput"
