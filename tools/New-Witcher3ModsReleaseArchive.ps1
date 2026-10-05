param([Parameter(Mandatory=$true)][string]$OutputPath)
$ErrorActionPreference = 'Stop'
$Witcher3ModsRoot = Split-Path $PSScriptRoot -Parent
$Witcher3ModsPackage = Join-Path $Witcher3ModsRoot 'src/modWitcher3ModsAchievementPanel'
$Witcher3ModsExpected = @('LICENSE','THIRD-PARTY-NOTICES.txt','README.md','install.cmd','uninstall.cmd','locales/en.json','locales/pl.json','content/blob0.bundle','content/metadata.store')
$Witcher3ModsExpected += @('AchievementCatalog','AchievementPresenter','AchievementReadout','AchievementTracking','GameQueries','Localization','MenuIntegration') | ForEach-Object { 'content/scripts/local/Witcher3Mods' + $_ + '.ws' }
if ((Get-FileHash "$Witcher3ModsRoot/LICENSE").Hash -ne (Get-FileHash "$Witcher3ModsPackage/LICENSE").Hash) { throw 'Root and packaged licenses differ.' }
if ((Get-FileHash "$Witcher3ModsRoot/THIRD-PARTY-NOTICES.txt").Hash -ne (Get-FileHash "$Witcher3ModsPackage/THIRD-PARTY-NOTICES.txt").Hash) { throw 'Root and packaged notices differ.' }
if ((Get-Content "$Witcher3ModsPackage/THIRD-PARTY-NOTICES.txt" -Raw).Length -lt 100) { throw 'Missing third-party notices.' }
$Witcher3ModsFiles = @(Get-ChildItem -LiteralPath $Witcher3ModsPackage -Recurse -Force -File)
foreach ($Witcher3ModsItem in @(Get-Item $Witcher3ModsPackage) + @(Get-ChildItem $Witcher3ModsPackage -Recurse -Force)) {
    if ($Witcher3ModsItem.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Package must not contain symlinks/junctions.' }
}
if ($Witcher3ModsFiles.Count -ne $Witcher3ModsExpected.Count) { throw 'Unexpected or missing package files.' }
foreach ($Witcher3ModsFile in $Witcher3ModsFiles) {
    $Witcher3ModsRelative = $Witcher3ModsFile.FullName.Substring($Witcher3ModsPackage.Length + 1).Replace('\','/')
    if ($Witcher3ModsRelative -notin $Witcher3ModsExpected -or $Witcher3ModsFile.Length -eq 0) { throw "Invalid package member: $Witcher3ModsRelative" }
}
$Witcher3ModsOutput = [IO.Path]::GetFullPath($OutputPath)
if ($Witcher3ModsOutput.StartsWith($Witcher3ModsPackage + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Archive output must be outside the package.' }
if (Test-Path -LiteralPath $Witcher3ModsOutput) { throw 'Refusing to overwrite an existing archive.' }
New-Item -ItemType Directory -Force (Split-Path $Witcher3ModsOutput -Parent) | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($Witcher3ModsPackage, $Witcher3ModsOutput, [IO.Compression.CompressionLevel]::Optimal, $true)
$Witcher3ModsZip = [IO.Compression.ZipFile]::OpenRead($Witcher3ModsOutput)
try {
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
        if ($Witcher3ModsHash -ne (Get-FileHash (Join-Path $Witcher3ModsPackage $Witcher3ModsRelative)).Hash) { throw 'ZIP byte verification failed.' }
    }
} finally { $Witcher3ModsZip.Dispose() }
Write-Output "Verified release ZIP: $Witcher3ModsOutput"
