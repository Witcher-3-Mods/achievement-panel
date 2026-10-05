param(
    [Parameter(Mandatory=$true)][string]$RedkitPath,
    [switch]$AllowRedkitScratch
)
$ErrorActionPreference = 'Stop'
if (-not $AllowRedkitScratch) { throw 'Explicit -AllowRedkitScratch required: wcc imports temporary files under REDkit/bin/gameplay. No game installation is changed.' }
$Witcher3ModsRoot = Split-Path $PSScriptRoot -Parent
$Witcher3ModsRedkit = (Resolve-Path -LiteralPath $RedkitPath).Path
$Witcher3ModsBin = Join-Path $Witcher3ModsRedkit 'bin'
$Witcher3ModsRun = Join-Path $Witcher3ModsRoot ('.build/package-' + [Guid]::NewGuid().ToString('N'))
$Witcher3ModsFiles = @('gameplay/gui_new/swf/hud/hud_quests.redswf', 'gameplay/gui_new/swf/glossary/panel_glossary_tutorials.redswf')
$Witcher3ModsCreated = @{}
# Refuse to overwrite ANY pre-existing scratch resource, including another mod.
foreach ($Witcher3ModsRelative in $Witcher3ModsFiles) {
    if (Test-Path -LiteralPath (Join-Path $Witcher3ModsBin $Witcher3ModsRelative)) { throw "Scratch target already exists: $Witcher3ModsRelative. Preserve it and resolve the conflict before building." }
    $Witcher3ModsSwf = Join-Path $Witcher3ModsRoot ('.build/flash/' + [IO.Path]::GetFileNameWithoutExtension($Witcher3ModsRelative) + '.swf')
    if (-not (Test-Path -LiteralPath $Witcher3ModsSwf)) { throw "Build Flash first: missing $Witcher3ModsSwf" }
}
New-Item -ItemType Directory -Path $Witcher3ModsRun | Out-Null
function Invoke-Witcher3ModsWcc([string]$Witcher3ModsStep, [string[]]$Witcher3ModsArguments) {
    Write-Output "REDkit: $Witcher3ModsStep"
    & (Join-Path $Witcher3ModsBin 'x64_RedKit/wcc_lite.exe') @Witcher3ModsArguments "-wcclog=$Witcher3ModsRun/$Witcher3ModsStep.log" 2>&1 |
        Out-File -LiteralPath "$Witcher3ModsRun/$Witcher3ModsStep-console.log" -Encoding UTF8
    if ($LASTEXITCODE -ne 0) { throw "REDkit failed: $Witcher3ModsStep. Full diagnostic: $Witcher3ModsRun/$Witcher3ModsStep-console.log" }
}
Push-Location (Join-Path $Witcher3ModsBin 'x64_RedKit')
try {
    foreach ($Witcher3ModsRelative in $Witcher3ModsFiles) {
        $Witcher3ModsName = [IO.Path]::GetFileNameWithoutExtension($Witcher3ModsRelative)
        $Witcher3ModsTarget = Join-Path $Witcher3ModsBin $Witcher3ModsRelative
        Invoke-Witcher3ModsWcc "import-$Witcher3ModsName" @('import', '-depot=local', "-file=$Witcher3ModsRoot/.build/flash/$Witcher3ModsName.swf", "-out=$Witcher3ModsRelative")
        if (-not (Test-Path -LiteralPath $Witcher3ModsTarget)) { throw "Importer did not create the expected file: $Witcher3ModsTarget" }
        $Witcher3ModsCopy = Join-Path "$Witcher3ModsRun/depot" $Witcher3ModsRelative
        New-Item -ItemType Directory -Force (Split-Path $Witcher3ModsCopy -Parent) | Out-Null
        Copy-Item -LiteralPath $Witcher3ModsTarget -Destination $Witcher3ModsCopy
        $Witcher3ModsHash = (Get-FileHash -LiteralPath $Witcher3ModsTarget).Hash
        if ($Witcher3ModsHash -ne (Get-FileHash -LiteralPath $Witcher3ModsCopy).Hash) { throw 'Import backup hash mismatch.' }
        $Witcher3ModsCreated[$Witcher3ModsTarget] = $Witcher3ModsHash
    }
    $Witcher3ModsCookArgs = @('cook', '-platform=pc')
    foreach ($Witcher3ModsFile in $Witcher3ModsFiles) { $Witcher3ModsCookArgs += "-file=$Witcher3ModsFile" }
    $Witcher3ModsCookArgs += "-outdir=$Witcher3ModsRun/cooked/"
    Invoke-Witcher3ModsWcc 'cook' $Witcher3ModsCookArgs
    Invoke-Witcher3ModsWcc 'pack' @('pack', "-dir=$Witcher3ModsRun/cooked/", "-outdir=$Witcher3ModsRun/packed/")
    Invoke-Witcher3ModsWcc 'metadata' @('metadatastore', "-path=$Witcher3ModsRun/packed/")
    Invoke-Witcher3ModsWcc 'unbundle' @('unbundle', "-dir=$Witcher3ModsRun/packed/", "-outdir=$Witcher3ModsRun/unpacked/")
    # Build integrity belongs to packaging, not a separate regression suite.
    $Witcher3ModsUnpackedFiles = @(Get-ChildItem -LiteralPath "$Witcher3ModsRun/unpacked" -Recurse -Force -File)
    if ($Witcher3ModsUnpackedFiles.Count -ne $Witcher3ModsFiles.Count) { throw 'Bundle must contain only the two intended UI resources.' }
    foreach ($Witcher3ModsRelative in $Witcher3ModsFiles) {
        $Witcher3ModsCooked = Join-Path "$Witcher3ModsRun/cooked" $Witcher3ModsRelative
        $Witcher3ModsUnpacked = Join-Path "$Witcher3ModsRun/unpacked" $Witcher3ModsRelative
        if ((Get-FileHash -LiteralPath $Witcher3ModsCooked).Hash -ne (Get-FileHash -LiteralPath $Witcher3ModsUnpacked).Hash) { throw "Bundle roundtrip mismatch: $Witcher3ModsRelative" }
    }
    foreach ($Witcher3ModsOutputName in @('blob0.bundle','metadata.store')) {
        if ((Get-Item -LiteralPath "$Witcher3ModsRun/packed/$Witcher3ModsOutputName").Length -eq 0) { throw "Empty package output: $Witcher3ModsOutputName" }
    }
    $Witcher3ModsPackage = Join-Path $Witcher3ModsRoot 'src/modWitcher3ModsAchivementPanel/content'
    foreach ($Witcher3ModsOutputName in @('blob0.bundle','metadata.store')) {
        $Witcher3ModsOutput = Join-Path $Witcher3ModsPackage $Witcher3ModsOutputName
        if (Test-Path -LiteralPath $Witcher3ModsOutput) {
            New-Item -ItemType Directory -Force "$Witcher3ModsRun/previous-package" | Out-Null
            Copy-Item -LiteralPath $Witcher3ModsOutput -Destination "$Witcher3ModsRun/previous-package/$Witcher3ModsOutputName"
        }
        Copy-Item -LiteralPath "$Witcher3ModsRun/packed/$Witcher3ModsOutputName" -Destination $Witcher3ModsOutput
        if ((Get-FileHash $Witcher3ModsOutput).Hash -ne (Get-FileHash "$Witcher3ModsRun/packed/$Witcher3ModsOutputName").Hash) { throw 'Package copy hash mismatch.' }
    }
    Write-Output "Built package in repository. Not installed into the game. Logs and recoverable scratch copies: $Witcher3ModsRun"
} finally {
    Pop-Location
    foreach ($Witcher3ModsTarget in $Witcher3ModsCreated.Keys) {
        $Witcher3ModsAbsolute = [IO.Path]::GetFullPath($Witcher3ModsTarget)
        $Witcher3ModsAllowed = [IO.Path]::GetFullPath((Join-Path $Witcher3ModsBin 'gameplay')) + [IO.Path]::DirectorySeparatorChar
        if (-not $Witcher3ModsAbsolute.StartsWith($Witcher3ModsAllowed, [StringComparison]::OrdinalIgnoreCase)) { throw 'Refusing cleanup outside authorized scratch directory.' }
        if ((Test-Path -LiteralPath $Witcher3ModsAbsolute) -and (Get-FileHash -LiteralPath $Witcher3ModsAbsolute).Hash -eq $Witcher3ModsCreated[$Witcher3ModsTarget]) {
            Remove-Item -LiteralPath $Witcher3ModsAbsolute
            Write-Output "Removed generated scratch file; copy retained in build directory: $Witcher3ModsAbsolute"
        } else { Write-Warning "Scratch file changed or disappeared; left untouched: $Witcher3ModsAbsolute" }
    }
}
