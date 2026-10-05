param([Parameter(Mandatory=$true)][string]$InputXml, [Parameter(Mandatory=$true)][string]$OutputXml)
$ErrorActionPreference = 'Stop'
$Witcher3ModsAssets = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../src/assets/achievement-icons'))
$Witcher3ModsManifest = Get-Content (Join-Path $Witcher3ModsAssets 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$Witcher3ModsXml = New-Object Xml.XmlDocument
$Witcher3ModsXml.Load($InputXml)
$Witcher3ModsPlacements = @($Witcher3ModsXml.SelectNodes('//*[@name="crests" and @characterId]'))
$Witcher3ModsCrestIds = @($Witcher3ModsPlacements | ForEach-Object { $_.characterId } | Select-Object -Unique)
if ($Witcher3ModsCrestIds.Count -ne 1) { throw 'Expected a shared native crest symbol.' }
$Witcher3ModsCrest = $Witcher3ModsXml.SelectSingleNode('//*[@type="DefineSpriteTag" and @spriteId="' + $Witcher3ModsCrestIds[0] + '"]')
if (-not $Witcher3ModsCrest -or $Witcher3ModsManifest.icons.Count -ne 78) { throw 'Missing crest or icons.' }
$Witcher3ModsMaxId = 0
foreach ($Witcher3ModsAttr in $Witcher3ModsXml.SelectNodes('//@spriteId | //@shapeId | //@characterID | //@characterId | //@fontID | //@buttonId | //@soundId')) {
    $Witcher3ModsMaxId = [Math]::Max($Witcher3ModsMaxId, [int]$Witcher3ModsAttr.Value)
}
function New-Witcher3ModsXmlNode([string]$Witcher3ModsMarkup) {
    $Witcher3ModsFragment = $Witcher3ModsXml.CreateDocumentFragment()
    $Witcher3ModsFragment.InnerXml = $Witcher3ModsMarkup
    return $Witcher3ModsFragment
}
foreach ($Witcher3ModsIcon in $Witcher3ModsManifest.icons) {
    if ($Witcher3ModsIcon.key -notmatch '^EA_[A-Za-z0-9_]+$') { throw 'Invalid icon key.' }
    $Witcher3ModsFile = Join-Path $Witcher3ModsAssets $Witcher3ModsIcon.file
    if ((Get-FileHash $Witcher3ModsFile -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Witcher3ModsIcon.sha256) { throw "Icon hash mismatch: $Witcher3ModsFile" }
    $Witcher3ModsImageId = ++$Witcher3ModsMaxId
    $Witcher3ModsShapeId = ++$Witcher3ModsMaxId
    $Witcher3ModsHex = [BitConverter]::ToString([IO.File]::ReadAllBytes($Witcher3ModsFile)).Replace('-', '').ToLowerInvariant()
    $Witcher3ModsBitmap = New-Witcher3ModsXmlNode "<item type='DefineBitsJPEG2Tag' characterID='$Witcher3ModsImageId' forceWriteAsLong='true' imageData='$Witcher3ModsHex' />"
    [void]$Witcher3ModsCrest.ParentNode.InsertBefore($Witcher3ModsBitmap, $Witcher3ModsCrest)
    $Witcher3ModsShape = New-Witcher3ModsXmlNode @"
<item type="DefineShape2Tag" shapeId="$Witcher3ModsShapeId" forceWriteAsLong="true">
 <shapeBounds type="RECT" Xmin="0" Xmax="1280" Ymin="0" Ymax="1280" nbits="12"/>
 <shapes type="SHAPEWITHSTYLE" numFillBits="1" numLineBits="0">
  <fillStyles type="FILLSTYLEARRAY"><fillStyles><item type="FILLSTYLE" fillStyleType="65" bitmapId="$Witcher3ModsImageId"><bitmapMatrix type="MATRIX" hasRotate="false" hasScale="true" nRotateBits="0" nScaleBits="22" nTranslateBits="0" scaleX="20.0" scaleY="20.0" translateX="0" translateY="0"/></item></fillStyles></fillStyles>
  <lineStyles type="LINESTYLEARRAY"><lineStyles/></lineStyles>
  <shapeRecords>
   <item type="StyleChangeRecord" fillStyle1="1" stateFillStyle0="false" stateFillStyle1="true" stateLineStyle="false" stateMoveTo="false" stateNewStyles="false"/>
   <item type="StraightEdgeRecord" deltaX="1280" generalLineFlag="false" numBits="10" vertLineFlag="false"/>
   <item type="StraightEdgeRecord" deltaY="1280" generalLineFlag="false" numBits="10" vertLineFlag="true"/>
   <item type="StraightEdgeRecord" deltaX="-1280" generalLineFlag="false" numBits="10" vertLineFlag="false"/>
   <item type="StraightEdgeRecord" deltaY="-1280" generalLineFlag="false" numBits="10" vertLineFlag="true"/>
   <item type="EndShapeRecord"/>
  </shapeRecords>
 </shapes>
</item>
"@
    [void]$Witcher3ModsCrest.ParentNode.InsertBefore($Witcher3ModsShape, $Witcher3ModsCrest)
    # Native crests occupy approx. 46x50 px. Center a 46x46 icon in that slot.
    $Witcher3ModsFrame = New-Witcher3ModsXmlNode @"
<item type="FrameLabelTag" forceWriteAsLong="true" name="Witcher3Mods_$($Witcher3ModsIcon.key)" namedAnchor="false"/>
<item type="PlaceObject2Tag" characterId="$Witcher3ModsShapeId" depth="1" forceWriteAsLong="true" placeFlagHasCharacter="true" placeFlagHasClipActions="false" placeFlagHasClipDepth="false" placeFlagHasColorTransform="false" placeFlagHasMatrix="true" placeFlagHasName="false" placeFlagHasRatio="false" placeFlagMove="true"><matrix type="MATRIX" hasRotate="false" hasScale="true" nRotateBits="0" nScaleBits="17" nTranslateBits="7" scaleX="0.71875" scaleY="0.71875" translateX="0" translateY="40"/></item>
<item type="ShowFrameTag" forceWriteAsLong="false"/>
"@
    [void]$Witcher3ModsCrest.subTags.AppendChild($Witcher3ModsFrame)
    $Witcher3ModsCrest.frameCount = [string]([int]$Witcher3ModsCrest.frameCount + 1)
}
$Witcher3ModsBlank = New-Witcher3ModsXmlNode '<item type="FrameLabelTag" forceWriteAsLong="true" name="Witcher3ModsNone" namedAnchor="false"/><item type="RemoveObject2Tag" depth="1" forceWriteAsLong="false"/><item type="ShowFrameTag" forceWriteAsLong="false"/>'
[void]$Witcher3ModsCrest.subTags.AppendChild($Witcher3ModsBlank)
$Witcher3ModsCrest.frameCount = [string]([int]$Witcher3ModsCrest.frameCount + 1)
[IO.File]::WriteAllText($OutputXml, $Witcher3ModsXml.OuterXml, (New-Object Text.UTF8Encoding($false)))
Write-Output 'Embedded 78 Steam icons as additional crest frames; native region frames preserved.'
