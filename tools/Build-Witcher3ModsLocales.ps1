param([switch]$Check)

# JSON is the editable source; WitcherScript has no verified JSON file reader.
# Run after changing locales: powershell -NoProfile -ExecutionPolicy Bypass -File tools/Build-Witcher3ModsLocales.ps1
# Polish achievement names verified against:
# https://steamcommunity.com/stats/292030/achievements/?l=polish
# Descriptions are project-authored summaries, not copies of Steam descriptions.
$ErrorActionPreference = 'Stop'
$Witcher3ModsPackage = Join-Path $PSScriptRoot '../src/modWitcher3ModsAchivementPanel'
$Witcher3ModsEnglish = Get-Content -LiteralPath (Join-Path $Witcher3ModsPackage 'locales/en.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$Witcher3ModsPolish = Get-Content -LiteralPath (Join-Path $Witcher3ModsPackage 'locales/pl.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$Witcher3ModsKeys = @($Witcher3ModsEnglish.PSObject.Properties.Name | Sort-Object)
if (Compare-Object $Witcher3ModsKeys @($Witcher3ModsPolish.PSObject.Properties.Name | Sort-Object)) {
    throw 'English and Polish translation keys differ.'
}

function Witcher3ModsQuote([string]$Witcher3ModsValue) {
    return '"' + $Witcher3ModsValue.Replace('\', '\\').Replace('"', '\"').Replace("`r", '\r').Replace("`n", '\n').Replace("`t", '\t') + '"'
}

$Witcher3ModsLines = New-Object 'System.Collections.Generic.List[string]'
$Witcher3ModsLines.Add('// Generated from locales/en.json and locales/pl.json by tools/Build-Witcher3ModsLocales.ps1.')
$Witcher3ModsLines.Add('// Edit the JSON files, then run the generator. No runtime file access is required.')
$Witcher3ModsLines.Add('function Witcher3ModsText(Witcher3ModsKey : string, Witcher3ModsPolish : bool) : string')
$Witcher3ModsLines.Add('{')
foreach ($Witcher3ModsKey in $Witcher3ModsKeys) {
    if ($Witcher3ModsKey -notmatch '^(title_EA_|description_EA_|ui_)\w+$') { throw ('Invalid key: ' + $Witcher3ModsKey) }
    foreach ($Witcher3ModsLocale in @($Witcher3ModsEnglish, $Witcher3ModsPolish)) {
        if ($Witcher3ModsLocale.$Witcher3ModsKey -isnot [string] -or [string]::IsNullOrWhiteSpace($Witcher3ModsLocale.$Witcher3ModsKey)) {
            throw ('Empty or invalid translation: ' + $Witcher3ModsKey)
        }
    }
    $Witcher3ModsLines.Add('    if (Witcher3ModsKey == ' + (Witcher3ModsQuote $Witcher3ModsKey) + ')')
    $Witcher3ModsLines.Add('    {')
    $Witcher3ModsLines.Add('        if (Witcher3ModsPolish) return ' + (Witcher3ModsQuote $Witcher3ModsPolish.$Witcher3ModsKey) + ';')
    $Witcher3ModsLines.Add('        return ' + (Witcher3ModsQuote $Witcher3ModsEnglish.$Witcher3ModsKey) + ';')
    $Witcher3ModsLines.Add('    }')
}
$Witcher3ModsLines.Add('    return Witcher3ModsKey;')
$Witcher3ModsLines.Add('}')
$Witcher3ModsOutput = ($Witcher3ModsLines -join "`n") + "`n"
$Witcher3ModsDestination = Join-Path $Witcher3ModsPackage 'content/scripts/local/Witcher3ModsLocalization.ws'
if ($Check) {
    $Witcher3ModsExisting = Get-Content -LiteralPath $Witcher3ModsDestination -Raw -Encoding UTF8
    if ($Witcher3ModsExisting.Replace("`r`n", "`n") -cne $Witcher3ModsOutput) { throw 'Generated localization is stale. Run tools/Build-Witcher3ModsLocales.ps1.' }
    Write-Output ('PASS: generated localization matches both JSON files (' + $Witcher3ModsKeys.Count + ' keys).')
} else {
    [System.IO.File]::WriteAllText($Witcher3ModsDestination, $Witcher3ModsOutput, (New-Object System.Text.UTF8Encoding($false)))
    Write-Output ('Generated localization: ' + $Witcher3ModsKeys.Count + ' keys.')
}
