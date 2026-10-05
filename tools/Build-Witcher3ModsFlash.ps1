param(
    [Parameter(Mandatory=$true)][string]$RedkitPath,
    [Parameter(Mandatory=$true)][string]$JavaPath,
    [Parameter(Mandatory=$true)][string]$FfdecPath,
    [string]$BuildDirectory = ''
)
$ErrorActionPreference = 'Stop'
$Witcher3ModsRoot = Split-Path $PSScriptRoot -Parent
if (-not $BuildDirectory) { $BuildDirectory = Join-Path $Witcher3ModsRoot '.build/flash' }
$BuildDirectory = [IO.Path]::GetFullPath($BuildDirectory)
$Witcher3ModsSource = Join-Path $RedkitPath 'r4data/gameplay/gui_new/swf'
$Witcher3ModsMenuClass = 'red.game.witcher3.menus.journal.'
$Witcher3ModsHudClass = 'red.game.witcher3.hud.modules.HudModuleQuests'
New-Item -ItemType Directory -Force $BuildDirectory | Out-Null

function Invoke-Witcher3ModsFfdec([string[]]$Witcher3ModsArguments) {
    & $JavaPath '-Djava.awt.headless=true' -jar $FfdecPath @Witcher3ModsArguments
    if ($LASTEXITCODE -ne 0) { throw "Flash tool failed: $($Witcher3ModsArguments -join ' ')" }
}
function Write-Witcher3ModsSource([string]$Witcher3ModsPath, [string]$Witcher3ModsText) {
    [IO.File]::WriteAllText($Witcher3ModsPath, $Witcher3ModsText, (New-Object Text.UTF8Encoding($false)))
}
function Replace-Witcher3ModsOnce([string]$Witcher3ModsText, [string]$Witcher3ModsFrom, [string]$Witcher3ModsTo) {
    if ([regex]::Matches($Witcher3ModsText, [regex]::Escape($Witcher3ModsFrom)).Count -ne 1) {
        throw "Unsupported REDkit/Flash source: expected one occurrence of $Witcher3ModsFrom"
    }
    return $Witcher3ModsText.Replace($Witcher3ModsFrom, $Witcher3ModsTo)
}
function Add-Witcher3ModsMethodGuard([string]$Witcher3ModsText, [string]$Witcher3ModsMethod, [string]$Witcher3ModsGuard) {
    $Witcher3ModsPattern = '(?m)(^      (?:override )?(?:public|private|protected) function ' + [regex]::Escape($Witcher3ModsMethod) + '\([^\r\n]*\r?\n      \{)'
    if ([regex]::Matches($Witcher3ModsText, $Witcher3ModsPattern).Count -ne 1) { throw "Missing method: $Witcher3ModsMethod" }
    return [regex]::Replace($Witcher3ModsText, $Witcher3ModsPattern, [Text.RegularExpressions.MatchEvaluator]{param($Witcher3ModsMatch) $Witcher3ModsMatch.Value + "`n" + $Witcher3ModsGuard})
}

# Decompiling the supplied SWFs retains Flash timeline-generated constructors.
# Original CDPR code remains in ignored build output, not copied into our sources.
$Witcher3ModsClasses = @('QuestItemRenderer','QuestListModule','ObjectiveItemRenderer','QuestSubListModule','QuestDropDownList','QuestDropdownMenuListItem')
$Witcher3ModsMenuSwf = Join-Path $Witcher3ModsSource 'journal/panel_journal_quests.swf'
$Witcher3ModsHudSwf = Join-Path $Witcher3ModsSource 'hud/hud_quests.swf'
Invoke-Witcher3ModsFfdec @('-selectclass', (($Witcher3ModsClasses | ForEach-Object { $Witcher3ModsMenuClass + $_ }) -join ','), '-export','script', "$BuildDirectory/menu", $Witcher3ModsMenuSwf)
Invoke-Witcher3ModsFfdec @('-selectclass', 'red.game.witcher3.menus.common.TextAreaModule', '-export','script', "$BuildDirectory/menu", $Witcher3ModsMenuSwf)
Invoke-Witcher3ModsFfdec @('-selectclass', $Witcher3ModsHudClass, '-export','script', "$BuildDirectory/hud", $Witcher3ModsHudSwf)
$Witcher3ModsMenuScripts = "$BuildDirectory/menu/scripts/red/game/witcher3/menus/journal"
$Witcher3ModsPath = "$Witcher3ModsMenuScripts/QuestItemRenderer.as"
$Witcher3ModsText = Get-Content $Witcher3ModsPath -Raw -Encoding UTF8
$Witcher3ModsText = Add-Witcher3ModsMethodGuard $Witcher3ModsText 'handleEntryPress' @'
         if (data && data.Witcher3ModsAchievement)
         {
            if (data.status == 2) return;
            dispatchEvent(new GameEvent(GameEvent.CALL, "OnTrackQuest", [data.tag]));
            return;
         }
'@
$Witcher3ModsText = Add-Witcher3ModsMethodGuard $Witcher3ModsText 'handleUntrackItem' '         if (data && data.Witcher3ModsAchievement) return;'
$Witcher3ModsRowMethods = Get-Content (Join-Path $PSScriptRoot 'flash/Witcher3ModsRowLayout.as.inc') -Raw -Encoding UTF8
$Witcher3ModsText = Replace-Witcher3ModsOnce $Witcher3ModsText '      public var tfLevel:TextField;' ("      public var tfLevel:TextField;`n" + $Witcher3ModsRowMethods)
$Witcher3ModsText = Replace-Witcher3ModsOnce $Witcher3ModsText '         super.updateText();' "         Witcher3ModsLayoutRow();`n         super.updateText();"
$Witcher3ModsText = Add-Witcher3ModsMethodGuard $Witcher3ModsText 'UpdateQuestStatusText' @'
         if (data && data.Witcher3ModsAchievement && data.Witcher3ModsRowDescription)
         {
            Witcher3ModsSetRowDescription();
            return;
         }
'@
Write-Witcher3ModsSource $Witcher3ModsPath $Witcher3ModsText

$Witcher3ModsHeaderPath = "$BuildDirectory/menu/scripts/red/game/witcher3/menus/common/TextAreaModule.as"
$Witcher3ModsText = Get-Content $Witcher3ModsHeaderPath -Raw -Encoding UTF8
$Witcher3ModsSummary = @'
      public function Witcher3ModsShowSummary(Witcher3ModsTitle:String, Witcher3ModsSubtitle:String, Witcher3ModsDescription:String):void
      {
         SetTitle(Witcher3ModsTitle);
         SetText(Witcher3ModsDescription);
         setDifficulty("");
         setLocation(Witcher3ModsSubtitle);
         setHeaderColor(2);
         setCrest("Witcher3ModsNone");
         ShowSkullIcon(false);
      }
'@
$Witcher3ModsText = Replace-Witcher3ModsOnce $Witcher3ModsText '      public var tfLocation:TextField;' ("      public var tfLocation:TextField;`n" + $Witcher3ModsSummary)
$Witcher3ModsText = Replace-Witcher3ModsOnce $Witcher3ModsText '      public var tfTitle:TextField;' "      public var tfTitle:TextField;`n      private var Witcher3ModsHeaderDefaults:Object;"
$Witcher3ModsText = Add-Witcher3ModsMethodGuard $Witcher3ModsText 'updateTextPositions' @'
         if (tfTitle && tfLocation && headerColor && crests)
         {
            if (!Witcher3ModsHeaderDefaults)
               Witcher3ModsHeaderDefaults = {titleX:tfTitle.x, titleWidth:tfTitle.width, locationX:tfLocation.x, locationWidth:tfLocation.width};
            tfTitle.x = Witcher3ModsHeaderDefaults.titleX;
            tfTitle.width = Witcher3ModsHeaderDefaults.titleWidth;
            tfLocation.x = Witcher3ModsHeaderDefaults.locationX;
            tfLocation.width = Witcher3ModsHeaderDefaults.locationWidth;
            if (crests.currentLabel == "Witcher3ModsNone")
            {
               var Witcher3ModsBounds:flash.geom.Rectangle = headerColor.getBounds(this);
               var Witcher3ModsInset:Number = Math.max(0, tfTitle.y - Witcher3ModsBounds.top);
               tfTitle.x = Witcher3ModsBounds.left + Witcher3ModsInset;
               tfLocation.x = tfTitle.x;
               tfTitle.width = Witcher3ModsHeaderDefaults.titleX + Witcher3ModsHeaderDefaults.titleWidth - tfTitle.x;
               tfLocation.width = Witcher3ModsHeaderDefaults.locationX + Witcher3ModsHeaderDefaults.locationWidth - tfLocation.x;
            }
            else if (crests.currentLabel && crests.currentLabel.indexOf("Witcher3Mods_EA_") == 0)
            {
               var Witcher3ModsFrame:flash.geom.Rectangle = headerColor.getBounds(this);
               var Witcher3ModsCrest:flash.geom.Rectangle = crests.getBounds(this);
               // Compare the visible inner border, not the outer decorative frame.
               // TextFields also add a two-pixel text gutter of their own.
               var Witcher3ModsGap:Number = Math.max(0, Witcher3ModsCrest.left - Witcher3ModsFrame.left - 8);
               tfTitle.x = Witcher3ModsCrest.right + Witcher3ModsGap;
               tfLocation.x = tfTitle.x;
               tfTitle.width = Witcher3ModsHeaderDefaults.titleX + Witcher3ModsHeaderDefaults.titleWidth - tfTitle.x;
               tfLocation.width = Witcher3ModsHeaderDefaults.locationX + Witcher3ModsHeaderDefaults.locationWidth - tfLocation.x;
            }
         }
'@
$Witcher3ModsText = Replace-Witcher3ModsOnce $Witcher3ModsText '            this.crests.gotoAndStop(param1);' @'
            this.crests.gotoAndStop(param1);
            if (param1.indexOf("Witcher3Mods_") == 0) updateTextPositions();
'@
# Run after native sizing, including title wrapping and subtitle changes.
$Witcher3ModsPattern = '(?ms)(      public function updateTextPositions\([^\r\n]*\r?\n      \{.*?)(^      })'
if ([regex]::Matches($Witcher3ModsText, $Witcher3ModsPattern).Count -ne 1) { throw 'Missing header layout method.' }
$Witcher3ModsHeaderLayout = @'
         if (crests && headerColor && crests.currentLabel && crests.currentLabel.indexOf("Witcher3Mods_EA_") == 0)
         {
            var Witcher3ModsHeader:flash.geom.Rectangle = headerColor.getBounds(this);
            var Witcher3ModsIcon:flash.geom.Rectangle = crests.getBounds(this);
            crests.y += Witcher3ModsHeader.top + (Witcher3ModsHeader.height - Witcher3ModsIcon.height) / 2 - Witcher3ModsIcon.top;
         }
'@
$Witcher3ModsText = [regex]::Replace($Witcher3ModsText, $Witcher3ModsPattern, [Text.RegularExpressions.MatchEvaluator]{param($Witcher3ModsMatch) $Witcher3ModsMatch.Groups[1].Value + $Witcher3ModsHeaderLayout + "`n" + $Witcher3ModsMatch.Groups[2].Value})
Write-Witcher3ModsSource $Witcher3ModsHeaderPath $Witcher3ModsText

$Witcher3ModsPath = "$Witcher3ModsMenuScripts/QuestDropDownList.as"
$Witcher3ModsText = Get-Content $Witcher3ModsPath -Raw -Encoding UTF8
$Witcher3ModsCategoryInput = Get-Content (Join-Path $PSScriptRoot 'flash/Witcher3ModsCategoryInput.as.inc') -Raw -Encoding UTF8
$Witcher3ModsText = Replace-Witcher3ModsOnce $Witcher3ModsText '      public function QuestDropDownList()' ($Witcher3ModsCategoryInput + "`n      public function QuestDropDownList()")
$Witcher3ModsText = Add-Witcher3ModsMethodGuard $Witcher3ModsText 'SetInitialSelection' '         if (Witcher3ModsModList) { Witcher3ModsRestoreCategoryState(); return; }'
Write-Witcher3ModsSource $Witcher3ModsPath $Witcher3ModsText

$Witcher3ModsPath = "$Witcher3ModsMenuScripts/QuestDropdownMenuListItem.as"
$Witcher3ModsText = Get-Content $Witcher3ModsPath -Raw -Encoding UTF8
$Witcher3ModsPinnedCategories = Get-Content (Join-Path $PSScriptRoot 'flash/Witcher3ModsPinnedCategories.as.inc') -Raw -Encoding UTF8
$Witcher3ModsText = Replace-Witcher3ModsOnce $Witcher3ModsText '      public function QuestDropdownMenuListItem()' ($Witcher3ModsPinnedCategories + "`n      public function QuestDropdownMenuListItem()")
$Witcher3ModsText = Add-Witcher3ModsMethodGuard $Witcher3ModsText 'setDropdownData' '         Witcher3ModsSetCategoryRows(param1 as Array);'
$Witcher3ModsText = Add-Witcher3ModsMethodGuard $Witcher3ModsText 'setColorCoding' @'
         headerColor.transform.colorTransform = new flash.geom.ColorTransform();
         if (param1 && (param1.Witcher3ModsAchievement || param1.Witcher3ModsSummary))
         {
            if (param1.Witcher3ModsSummary || param1.status == 2 || param1.status == 3)
               headerColor.gotoAndStop(1);
            else
            {
               headerColor.gotoAndStop("main");
               // Warm gold; preserve the native stripe's shading and alpha.
               headerColor.transform.colorTransform = new flash.geom.ColorTransform(0.35, 0.35, 0.12, 1, 155, 140, 35, 0);
            }
            return;
         }
'@
Write-Witcher3ModsSource $Witcher3ModsPath $Witcher3ModsText

$Witcher3ModsPath = "$Witcher3ModsMenuScripts/QuestListModule.as"
$Witcher3ModsText = Get-Content $Witcher3ModsPath -Raw -Encoding UTF8
$Witcher3ModsSorting = Get-Content (Join-Path $PSScriptRoot 'flash/Witcher3ModsSorting.as.inc') -Raw -Encoding UTF8
$Witcher3ModsInitialization = Get-Content (Join-Path $PSScriptRoot 'flash/Witcher3ModsListInitialization.as.inc') -Raw -Encoding UTF8
$Witcher3ModsSorting += "`n" + $Witcher3ModsInitialization
$Witcher3ModsText = Replace-Witcher3ModsOnce $Witcher3ModsText '      public function QuestListModule()' ($Witcher3ModsSorting + "`n      public function QuestListModule()")
$Witcher3ModsText = Replace-Witcher3ModsOnce $Witcher3ModsText '         stage.addEventListener(QuestItemRenderer.UNTRACK,this.handleUntrackItem,false,0,true);' @'
         stage.addEventListener(QuestItemRenderer.UNTRACK,this.handleUntrackItem,false,0,true);
         Witcher3ModsListReady = true;
         if (Witcher3ModsPendingRows)
            Witcher3ModsQueueInitialRows();
'@
$Witcher3ModsText = Add-Witcher3ModsMethodGuard $Witcher3ModsText 'sortData' @'
         if (param1 && param1.length && (param1[0].Witcher3ModsAchievement || param1[0].Witcher3ModsSummary))
         {
            param1.sort(Witcher3ModsCompareRows);
            return;
         }
'@
$Witcher3ModsText = Add-Witcher3ModsMethodGuard $Witcher3ModsText 'canShowSubItemInputFeedback' @'
         var Witcher3ModsRenderer:QuestItemRenderer = param1.GetSubSelectedRenderer(true) as QuestItemRenderer;
         if (Witcher3ModsRenderer && Witcher3ModsRenderer.data && Witcher3ModsRenderer.data.Witcher3ModsAchievement) return Witcher3ModsRenderer.data.status != 2;
'@
$Witcher3ModsText = Replace-Witcher3ModsOnce $Witcher3ModsText 'if(Boolean(_loc2_) && _loc2_.hasOwnProperty("tracked"))' 'if(Boolean(_loc2_) && !_loc2_.Witcher3ModsAchievement && _loc2_.hasOwnProperty("tracked"))'
Write-Witcher3ModsSource $Witcher3ModsPath $Witcher3ModsText

$Witcher3ModsPath = "$Witcher3ModsMenuScripts/ObjectiveItemRenderer.as"
$Witcher3ModsText = Get-Content $Witcher3ModsPath -Raw -Encoding UTF8
$Witcher3ModsText = Add-Witcher3ModsMethodGuard $Witcher3ModsText 'handleButtonPress' @'
         if (data && data.Witcher3ModsAchievement)
         {
            if (data.status == 2) return;
            dispatchEvent(new GameEvent(GameEvent.CALL, "OnHighlightObjective", [data.tag]));
            return;
         }
'@
Write-Witcher3ModsSource $Witcher3ModsPath $Witcher3ModsText

$Witcher3ModsPath = "$Witcher3ModsMenuScripts/QuestSubListModule.as"
$Witcher3ModsText = Get-Content $Witcher3ModsPath -Raw -Encoding UTF8
$Witcher3ModsText = Add-Witcher3ModsMethodGuard $Witcher3ModsText 'configureInputFeedbackButtons' @'
         var Witcher3ModsRenderer:ObjectiveItemRenderer = this.mcList.getSelectedRenderer() as ObjectiveItemRenderer;
         if (Witcher3ModsRenderer && Witcher3ModsRenderer.data && Witcher3ModsRenderer.data.Witcher3ModsAchievement)
         {
            if (this._trackInputFeedback >= 0)
               InputFeedbackManager.removeButton(this, this._trackInputFeedback);
            this._trackInputFeedback = -1;
            if (hasFocus && Witcher3ModsRenderer.data.status != 2)
               this._trackInputFeedback = InputFeedbackManager.appendButton(this, NavigationCode.GAMEPAD_A, KeyCode.ENTER, "Witcher3ModsToggleTracking");
            InputFeedbackManager.updateButtons(this);
            return;
         }
'@
Write-Witcher3ModsSource $Witcher3ModsPath $Witcher3ModsText

$Witcher3ModsPath = "$BuildDirectory/hud/scripts/red/game/witcher3/hud/modules/HudModuleQuests.as"
$Witcher3ModsText = Get-Content $Witcher3ModsPath -Raw -Encoding UTF8
$Witcher3ModsText = Replace-Witcher3ModsOnce $Witcher3ModsText 'registerDataBinding("hud.quest.system.objectives",this.onSystemObjectiveDataSet);' 'registerDataBinding("hud.quest.system.objectives",this.onSystemObjectiveDataSet); registerDataBinding("Witcher3Mods.achievements", Witcher3ModsSetAchievements);'
$Witcher3ModsHudMethods = Get-Content (Join-Path $PSScriptRoot 'flash/Witcher3ModsHud.as.inc') -Raw -Encoding UTF8
$Witcher3ModsText = Replace-Witcher3ModsOnce $Witcher3ModsText '      public var mcSystemQuestContainer:HudQuestContainer;' ("      public var mcSystemQuestContainer:HudQuestContainer;`n" + $Witcher3ModsHudMethods)
Write-Witcher3ModsSource $Witcher3ModsPath $Witcher3ModsText

# Add icon frames without removing or renumbering any native region-crest frame.
# Preserve the native journal root, constructors and registration.
Invoke-Witcher3ModsFfdec @('-selectclass', ($Witcher3ModsMenuClass + 'QuestJournalMenu'), '-export', 'script', "$BuildDirectory/root-native", $Witcher3ModsMenuSwf)
Invoke-Witcher3ModsFfdec @('-swf2xml', $Witcher3ModsMenuSwf, "$BuildDirectory/menu.xml")
& (Join-Path $PSScriptRoot 'flash/Add-Witcher3ModsIconFrames.ps1') -InputXml "$BuildDirectory/menu.xml" -OutputXml "$BuildDirectory/menu-icons.xml"
Invoke-Witcher3ModsFfdec @('-xml2swf', "$BuildDirectory/menu-icons.xml", "$BuildDirectory/menu-icons.swf")
$Witcher3ModsReplace = @('-replace', "$BuildDirectory/menu-icons.swf", "$BuildDirectory/panel_journal_quests.swf")
foreach ($Witcher3ModsClass in $Witcher3ModsClasses) {
    $Witcher3ModsReplace += @(($Witcher3ModsMenuClass + $Witcher3ModsClass), "$Witcher3ModsMenuScripts/$Witcher3ModsClass.as")
}
$Witcher3ModsReplace += @('red.game.witcher3.menus.common.TextAreaModule', $Witcher3ModsHeaderPath)
Invoke-Witcher3ModsFfdec $Witcher3ModsReplace
Invoke-Witcher3ModsFfdec @('-selectclass', ($Witcher3ModsMenuClass + 'QuestJournalMenu'), '-export', 'script', "$BuildDirectory/root-restored", "$BuildDirectory/panel_journal_quests.swf")
if ((Get-FileHash "$BuildDirectory/root-native/scripts/red/game/witcher3/menus/journal/QuestJournalMenu.as").Hash -ne (Get-FileHash "$BuildDirectory/root-restored/scripts/red/game/witcher3/menus/journal/QuestJournalMenu.as").Hash) { throw 'Built journal root differs from native root.' }
Invoke-Witcher3ModsFfdec @('-replace', $Witcher3ModsHudSwf, "$BuildDirectory/hud_quests.swf", $Witcher3ModsHudClass, $Witcher3ModsPath)
. (Join-Path $PSScriptRoot 'flash/Build-Witcher3ModsTutorialHost.ps1')
Write-Output "Compiled Flash sources: $BuildDirectory. SWFs still require REDkit import and cooking; this does not install the mod."
