# Invoked by Build-Witcher3ModsFlash.ps1 after the presentation donor is compiled.
$Witcher3ModsTutorialSwf = Join-Path $Witcher3ModsSource 'glossary/panel_glossary_tutorials.swf'
$Witcher3ModsTutorialClass = 'red.game.witcher3.menus.glossary.GlossaryTutorialsMenu'
$Witcher3ModsLibrary = Split-Path ([IO.Path]::GetFullPath($FfdecPath)) -Parent
& $JavaPath '--class-path' "$Witcher3ModsLibrary/ffdec.jar;$Witcher3ModsLibrary/lib/*" (Join-Path $PSScriptRoot 'Merge-Witcher3ModsTutorialView.java') $Witcher3ModsTutorialSwf "$BuildDirectory/panel_journal_quests.swf" "$BuildDirectory/tutorial-merged.swf"
if ($LASTEXITCODE -ne 0) { throw 'Tutorial asset transfer failed.' }
Invoke-Witcher3ModsFfdec @('-selectclass', $Witcher3ModsTutorialClass, '-export', 'script', "$BuildDirectory/tutorial-native", $Witcher3ModsTutorialSwf)
$Witcher3ModsTutorialPath = "$BuildDirectory/tutorial-native/scripts/red/game/witcher3/menus/glossary/GlossaryTutorialsMenu.as"
$Witcher3ModsText = Get-Content $Witcher3ModsTutorialPath -Raw -Encoding UTF8
# JPEXS exports script-level Extensions statements without their import (D24).
$Witcher3ModsText = Replace-Witcher3ModsOnce $Witcher3ModsText 'Extensions.enabled = true;' "import scaleform.gfx.Extensions;`nExtensions.enabled = true;"
$Witcher3ModsText = Replace-Witcher3ModsOnce $Witcher3ModsText '   import flash.events.Event;' @'
   import flash.events.Event;
   import scaleform.clik.events.ListEvent;
'@
$Witcher3ModsMethods = Get-Content (Join-Path $PSScriptRoot 'Witcher3ModsTutorialView.as.inc') -Raw -Encoding UTF8
$Witcher3ModsText = Replace-Witcher3ModsOnce $Witcher3ModsText '      public function GlossaryTutorialsMenu()' ($Witcher3ModsMethods + "`n      public function GlossaryTutorialsMenu()")
$Witcher3ModsText = Add-Witcher3ModsMethodGuard $Witcher3ModsText 'ShowSecondaryModules' @'
         if (Witcher3ModsAchievementsActive)
         {
            Witcher3ModsObjectives.visible = Witcher3ModsObjectives.enabled = param1;
            Witcher3ModsDetails.visible = Witcher3ModsDetails.enabled = param1;
            return;
         }
'@
foreach ($Witcher3ModsMethod in @('setTitle', 'setText', 'setImage', 'setEntryTag')) {
    $Witcher3ModsText = Add-Witcher3ModsMethodGuard $Witcher3ModsText $Witcher3ModsMethod '         if (Witcher3ModsAchievementsActive) return;'
}
$Witcher3ModsText = Add-Witcher3ModsMethodGuard $Witcher3ModsText 'handleControllerUpdate' @'
         // Tutorials swap keyboard/gamepad-specific entries. Achievements do not.
         // InputManager delivers this event on the next frame, after navigation;
         // republishing here rebuilds the list and overwrites that selection.
         // Native input-feedback controls update their own glyphs independently.
         if (Witcher3ModsAchievementsActive) return;
'@
$Witcher3ModsTutorialPatched = "$BuildDirectory/tutorial-host/GlossaryTutorialsMenu.as"
New-Item -ItemType Directory -Force (Split-Path $Witcher3ModsTutorialPatched -Parent) | Out-Null
Write-Witcher3ModsSource $Witcher3ModsTutorialPatched $Witcher3ModsText
Invoke-Witcher3ModsFfdec @('-replace', "$BuildDirectory/tutorial-merged.swf", "$BuildDirectory/panel_glossary_tutorials.swf", $Witcher3ModsTutorialClass, $Witcher3ModsTutorialPatched)
Invoke-Witcher3ModsFfdec @('-selectclass', 'red.core.CoreComponent,red.core.CoreMenu', '-format', 'script:pcode', '-export', 'script', "$BuildDirectory/tutorial-native-core", $Witcher3ModsTutorialSwf)
Invoke-Witcher3ModsFfdec @('-selectclass', 'red.core.CoreComponent,red.core.CoreMenu', '-format', 'script:pcode', '-export', 'script', "$BuildDirectory/tutorial-host-core", "$BuildDirectory/panel_glossary_tutorials.swf")
foreach ($Witcher3ModsClass in @('CoreComponent','CoreMenu')) {
    if ((Get-FileHash "$BuildDirectory/tutorial-native-core/scripts/red/core/$Witcher3ModsClass.pcode").Hash -ne (Get-FileHash "$BuildDirectory/tutorial-host-core/scripts/red/core/$Witcher3ModsClass.pcode").Hash) { throw "Native tutorial startup changed: $Witcher3ModsClass" }
}
Invoke-Witcher3ModsFfdec @('-selectclass', $Witcher3ModsTutorialClass, '-format', 'script:pcode', '-export', 'script', "$BuildDirectory/tutorial-host-code", "$BuildDirectory/panel_glossary_tutorials.swf")
$Witcher3ModsRootCode = Get-Content "$BuildDirectory/tutorial-host-code/scripts/red/game/witcher3/menus/glossary/GlossaryTutorialsMenu.pcode" -Raw -Encoding UTF8
if ($Witcher3ModsRootCode.Contains('getlex Multiname("Extensions"') -or -not $Witcher3ModsRootCode.Contains('getlex QName(PackageNamespace("scaleform.gfx"),"Extensions")')) { throw 'Unresolved Extensions initializer in tutorial host.' }
foreach ($Witcher3ModsSymbol in @('Witcher3ModsMC_MODULE_QuestList','Witcher3ModsMC_MODULE_ObjectiveList','Witcher3ModsMC_MODULE_TextAreaLegend')) {
    if (-not $Witcher3ModsRootCode.Contains('QName(PackageNamespace(""),"' + $Witcher3ModsSymbol + '")')) { throw "Unresolved module constructor: $Witcher3ModsSymbol" }
}
Invoke-Witcher3ModsFfdec @('-selectclass', 'red.game.witcher3.menus.journal.Witcher3ModsQuestItemRenderer,red.game.witcher3.menus.journal.Witcher3ModsObjectiveItemRenderer,red.game.witcher3.menus.common.Witcher3ModsTextAreaModule,red.game.witcher3.menus.common.TextAreaModule,Witcher3ModsDropDownList,Witcher3ModsQuestListItem', '-export', 'script', "$BuildDirectory/tutorial-view", "$BuildDirectory/panel_glossary_tutorials.swf")
