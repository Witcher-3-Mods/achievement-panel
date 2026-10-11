param(
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [string]$Version = '0.0.0'
)
# Compiles install.exe (Install.cs) and uninstall.exe (Uninstall.cs) from the sources in the package folder, each together
# with Common.cs. They are ordinary C# programs: they do not run PowerShell or any script. Uses the C# compiler that ships
# with Windows (.NET Framework 4), so no SDK has to be installed. The .exe files are build output: they are not stored in the
# repository.
$ErrorActionPreference = 'Stop'
if ($Version -notmatch '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$') { throw "Invalid version: $Version" }
$Witcher3ModsRoot = Split-Path $PSScriptRoot -Parent
$Witcher3ModsPackage = Join-Path $Witcher3ModsRoot 'src/modWitcher3ModsAchievementPanel'
$Witcher3ModsCompiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $Witcher3ModsCompiler)) { throw "C# compiler not found: $Witcher3ModsCompiler" }
$Witcher3ModsOutput = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Force $Witcher3ModsOutput | Out-Null

$Witcher3ModsWork = Join-Path ([IO.Path]::GetTempPath()) ('w3m-build-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $Witcher3ModsWork | Out-Null
try {
    $Witcher3ModsInfo = Join-Path $Witcher3ModsWork 'AssemblyInfo.cs'
    [IO.File]::WriteAllText($Witcher3ModsInfo, @"
using System.Reflection;
[assembly: AssemblyCompany("Witcher-3-Mods")]
[assembly: AssemblyProduct("Witcher3ModsAchievementPanel")]
[assembly: AssemblyVersion("$Version.0")]
[assembly: AssemblyFileVersion("$Version.0")]
"@, (New-Object Text.UTF8Encoding($false)))

    # Run as the user who starts it, never elevated: without a manifest Windows may treat a program named "install" as a setup
    # program and ask for administrator rights.
    $Witcher3ModsManifest = Join-Path $Witcher3ModsWork 'app.manifest'
    [IO.File]::WriteAllText($Witcher3ModsManifest, @'
<?xml version="1.0" encoding="utf-8"?>
<assembly manifestVersion="1.0" xmlns="urn:schemas-microsoft-com:asm.v1">
  <trustInfo xmlns="urn:schemas-microsoft-com:asm.v2">
    <security><requestedPrivileges xmlns="urn:schemas-microsoft-com:asm.v3"><requestedExecutionLevel level="asInvoker" uiAccess="false" /></requestedPrivileges></security>
  </trustInfo>
  <compatibility xmlns="urn:schemas-microsoft-com:compatibility.v1">
    <application>
      <supportedOS Id="{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}" />
      <supportedOS Id="{1f676c76-80e1-4239-95bb-83d0f6d0da78}" />
    </application>
  </compatibility>
</assembly>
'@, (New-Object Text.UTF8Encoding($false)))

    foreach ($Witcher3ModsName in @('install', 'uninstall')) {
        $Witcher3ModsMain = Join-Path $Witcher3ModsPackage ($Witcher3ModsName.Substring(0, 1).ToUpperInvariant() + $Witcher3ModsName.Substring(1) + '.cs')
        $Witcher3ModsExe = Join-Path $Witcher3ModsOutput "$Witcher3ModsName.exe"
        if (Test-Path -LiteralPath $Witcher3ModsExe) { Remove-Item -LiteralPath $Witcher3ModsExe -Force }
        $Witcher3ModsTitle = "Achievement Panel $Witcher3ModsName"
        $Witcher3ModsTitleInfo = Join-Path $Witcher3ModsWork "$Witcher3ModsName.info.cs"
        [IO.File]::WriteAllText($Witcher3ModsTitleInfo, "using System.Reflection;`n[assembly: AssemblyTitle(`"$Witcher3ModsTitle`")]`n[assembly: AssemblyDescription(`"$Witcher3ModsTitle`")]`n", (New-Object Text.UTF8Encoding($false)))
        & $Witcher3ModsCompiler /nologo /target:exe /optimize+ /warnaserror+ "/out:$Witcher3ModsExe" "/win32manifest:$Witcher3ModsManifest" $Witcher3ModsMain (Join-Path $Witcher3ModsPackage 'Common.cs') $Witcher3ModsInfo $Witcher3ModsTitleInfo
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $Witcher3ModsExe)) { throw "Could not compile $Witcher3ModsName.exe." }

        # Smoke test: a folder that is not a Witcher 3 folder must be rejected before anything is changed.
        # The installer insists on a 'content' folder next to itself, so the test copy gets an empty one.
        $Witcher3ModsSmoke = Join-Path $Witcher3ModsWork "smoke-$Witcher3ModsName"
        New-Item -ItemType Directory -Force (Join-Path $Witcher3ModsSmoke 'content') | Out-Null
        Copy-Item -LiteralPath $Witcher3ModsExe -Destination $Witcher3ModsSmoke
        $Witcher3ModsBogus = Join-Path $Witcher3ModsWork 'not-a-game'
        $Witcher3ModsText = (& (Join-Path $Witcher3ModsSmoke "$Witcher3ModsName.exe") /yes "/game:$Witcher3ModsBogus" 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 1 -or $Witcher3ModsText -notmatch 'Not a Witcher 3 folder') {
            throw "$Witcher3ModsName.exe smoke test failed (exit $LASTEXITCODE): $Witcher3ModsText"
        }
        # The smoke test expects exit code 1. GitHub runs a step as ". script" and fails it on a leftover non-zero $LASTEXITCODE.
        $global:LASTEXITCODE = 0
        Write-Output "Built $Witcher3ModsExe"
    }
} finally {
    Remove-Item -LiteralPath $Witcher3ModsWork -Recurse -Force -ErrorAction SilentlyContinue
}
