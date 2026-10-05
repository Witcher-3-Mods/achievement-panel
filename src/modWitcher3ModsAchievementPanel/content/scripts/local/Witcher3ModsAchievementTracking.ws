// Persistent, mod-owned UI preferences. Never change real journal/achievement state.
function Witcher3ModsGetAchievementTrackingHud() : CR4HudModuleQuests
{
    var Witcher3ModsHud : CR4ScriptedHud;
    Witcher3ModsHud = (CR4ScriptedHud)theGame.GetHud();
    if (!Witcher3ModsHud) return NULL;
    return (CR4HudModuleQuests)Witcher3ModsHud.GetHudModule("QuestsModule");
}

@addField(CR4HudModuleQuests)
var Witcher3ModsTrackedAchievementKeys : array<name>;

@addField(CR4HudModuleQuests)
var Witcher3ModsTrackingPresenter : Witcher3ModsAchievementPresenter;

@addField(CR4HudModuleQuests)
var Witcher3ModsTrackingRefreshElapsed : float;

@addField(CR4HudModuleQuests)
var Witcher3ModsTrackedHudText : string;

@addField(CR4HudModuleQuests)
var Witcher3ModsTrackingPreferencesLoaded : bool;

// The tracked achievements live inside the native quest objectives module, so they follow the native option
// "Hide quest objectives during exploration" (ObjectiveDuringFocusCombat): with it on, they may only be
// published while the native module itself is shown. Publishing makes Flash dispatch an UPDATE event that
// would pop the hidden module back up, so a change made meanwhile is held until the module is shown again.
@addField(CR4HudModuleQuests)
var Witcher3ModsHudPublishPending : bool;

@addMethod(CR4HudModuleQuests)
function Witcher3ModsTrackedMayShow() : bool
{
    return !GetObjectiveDuringFocusCombat() || GetEnabled();
}

@addMethod(CR4HudModuleQuests)
function Witcher3ModsLoadTrackingPreferences()
{
    var Witcher3ModsConfig : CInGameConfigWrapper;
    var Witcher3ModsSlot, Witcher3ModsCursor : int;
    var Witcher3ModsSavedKey : string;
    var Witcher3ModsKey : name;
    if (Witcher3ModsTrackingPreferencesLoaded) return;
    Witcher3ModsConfig = theGame.GetInGameConfigWrapper();
    if (!Witcher3ModsConfig) return;
    Witcher3ModsTrackingPreferencesLoaded = true;
    if (!Witcher3ModsTrackingPresenter)
        Witcher3ModsTrackingPresenter = new Witcher3ModsAchievementPresenter in this;
    Witcher3ModsTrackingPresenter.Witcher3ModsRefreshPresentation();
    // Raw configuration is also used by native photo-mode presets. Canonical
    // keys, rather than catalogue positions, survive catalogue reordering.
    for (Witcher3ModsSlot = 0; Witcher3ModsSlot < 3; Witcher3ModsSlot += 1)
    {
        Witcher3ModsSavedKey = Witcher3ModsConfig.GetRawConfigValueByStr("Witcher3ModsAchievementPanel", "Witcher3ModsTracked" + IntToString(Witcher3ModsSlot));
        for (Witcher3ModsCursor = 0; Witcher3ModsCursor < Witcher3ModsTrackingPresenter.Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions.Size(); Witcher3ModsCursor += 1)
        {
            Witcher3ModsKey = Witcher3ModsTrackingPresenter.Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions[Witcher3ModsCursor].Witcher3ModsAchievementKey;
            if (NameToString(Witcher3ModsKey) == Witcher3ModsSavedKey && !Witcher3ModsTrackedAchievementKeys.Contains(Witcher3ModsKey))
                Witcher3ModsTrackedAchievementKeys.PushBack(Witcher3ModsKey);
        }
    }
    Witcher3ModsRefreshTrackedHudText();
}

@addMethod(CR4HudModuleQuests)
function Witcher3ModsSaveTrackingPreferences()
{
    var Witcher3ModsConfig : CInGameConfigWrapper;
    var Witcher3ModsSlot : int;
    var Witcher3ModsSavedKey : string;
    Witcher3ModsConfig = theGame.GetInGameConfigWrapper();
    if (!Witcher3ModsConfig) return;
    for (Witcher3ModsSlot = 0; Witcher3ModsSlot < 3; Witcher3ModsSlot += 1)
    {
        Witcher3ModsSavedKey = "";
        if (Witcher3ModsSlot < Witcher3ModsTrackedAchievementKeys.Size())
            Witcher3ModsSavedKey = NameToString(Witcher3ModsTrackedAchievementKeys[Witcher3ModsSlot]);
        Witcher3ModsConfig.SetRawConfigValueByStr("Witcher3ModsAchievementPanel", "Witcher3ModsTracked" + IntToString(Witcher3ModsSlot), Witcher3ModsSavedKey);
    }
    theGame.SaveUserSettings();
}

@addMethod(CR4HudModuleQuests)
function Witcher3ModsIsAchievementTracked(Witcher3ModsAchievementKey : name) : bool
{
    Witcher3ModsLoadTrackingPreferences();
    return Witcher3ModsTrackedAchievementKeys.Contains(Witcher3ModsAchievementKey);
}

@addMethod(CR4HudModuleQuests)
function Witcher3ModsToggleAchievementTracking(Witcher3ModsAchievementKey : name)
{
    var Witcher3ModsCursor, Witcher3ModsAchievementIndex : int;
    Witcher3ModsLoadTrackingPreferences();
    if (!Witcher3ModsTrackingPresenter)
        Witcher3ModsTrackingPresenter = new Witcher3ModsAchievementPresenter in this;
    Witcher3ModsTrackingPresenter.Witcher3ModsRefreshPresentation();
    Witcher3ModsAchievementIndex = Witcher3ModsTrackingPresenter.Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsFindAchievementIndex(Witcher3ModsAchievementKey);
    if (Witcher3ModsAchievementIndex < 0) return;
    for (Witcher3ModsCursor = 0; Witcher3ModsCursor < Witcher3ModsTrackedAchievementKeys.Size(); Witcher3ModsCursor += 1)
    {
        if (Witcher3ModsTrackedAchievementKeys[Witcher3ModsCursor] == Witcher3ModsAchievementKey)
        {
            Witcher3ModsTrackedAchievementKeys.Erase(Witcher3ModsCursor);
            Witcher3ModsSaveTrackingPreferences();
            Witcher3ModsRefreshTrackedHudText();
            Witcher3ModsPublishTrackedAchievementHud();
            return;
        }
    }
    if (!Witcher3ModsTrackingPresenter.Witcher3ModsReadout.Witcher3ModsStatusReady || Witcher3ModsTrackingPresenter.Witcher3ModsReadout.Witcher3ModsSnapshots[Witcher3ModsAchievementIndex].Witcher3ModsState == Witcher3ModsAchievementEarned) return;
    if (Witcher3ModsTrackedAchievementKeys.Size() >= 3)
    {
        theGame.GetGuiManager().ShowNotification(Witcher3ModsText("ui_pin_limit", Witcher3ModsUsePolish()));
        return;
    }
    Witcher3ModsTrackedAchievementKeys.PushBack(Witcher3ModsAchievementKey);
    Witcher3ModsSaveTrackingPreferences();
    Witcher3ModsRefreshTrackedHudText();
    Witcher3ModsPublishTrackedAchievementHud();
}

@addMethod(CR4HudModuleQuests)
function Witcher3ModsBuildTrackedDescription(Witcher3ModsAchievementIndex : int) : string
{
    var Witcher3ModsDescription : string;
    if (!Witcher3ModsTrackingPresenter.Witcher3ModsReadout.Witcher3ModsStatusReady)
        return Witcher3ModsText("ui_hud_error", Witcher3ModsTrackingPresenter.Witcher3ModsReadout.Witcher3ModsPolish);
    Witcher3ModsDescription = Witcher3ModsTrackingPresenter.Witcher3ModsBuildObjectiveText(Witcher3ModsAchievementIndex);
    if (Witcher3ModsTrackingPresenter.Witcher3ModsReadout.Witcher3ModsSnapshots[Witcher3ModsAchievementIndex].Witcher3ModsState == Witcher3ModsAchievementEarned)
        Witcher3ModsDescription += Witcher3ModsText("ui_hud_earned", Witcher3ModsTrackingPresenter.Witcher3ModsReadout.Witcher3ModsPolish);
    else if (Witcher3ModsTrackingPresenter.Witcher3ModsReadout.Witcher3ModsSnapshots[Witcher3ModsAchievementIndex].Witcher3ModsState == Witcher3ModsAchievementBlocked)
        Witcher3ModsDescription += Witcher3ModsText("ui_hud_blocked", Witcher3ModsTrackingPresenter.Witcher3ModsReadout.Witcher3ModsPolish);
    return Witcher3ModsDescription;
}

// Change signature only. Flash receives title/description separately, not HTML
// appended to the last real objective. Include titles to detect language changes.
@addMethod(CR4HudModuleQuests)
function Witcher3ModsRefreshTrackedHudText()
{
    var Witcher3ModsCursor, Witcher3ModsAchievementIndex : int;
    var Witcher3ModsRemovedCompleted : bool;
    Witcher3ModsTrackedHudText = "";
    if (!Witcher3ModsTrackingPresenter) return;
    if (Witcher3ModsTrackingPresenter.Witcher3ModsReadout.Witcher3ModsStatusReady)
    {
        for (Witcher3ModsCursor = Witcher3ModsTrackedAchievementKeys.Size() - 1; Witcher3ModsCursor >= 0; Witcher3ModsCursor -= 1)
        {
            Witcher3ModsAchievementIndex = Witcher3ModsTrackingPresenter.Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsFindAchievementIndex(Witcher3ModsTrackedAchievementKeys[Witcher3ModsCursor]);
            if (Witcher3ModsAchievementIndex >= 0 && Witcher3ModsTrackingPresenter.Witcher3ModsReadout.Witcher3ModsSnapshots[Witcher3ModsAchievementIndex].Witcher3ModsState == Witcher3ModsAchievementEarned)
            {
                Witcher3ModsTrackedAchievementKeys.Erase(Witcher3ModsCursor);
                Witcher3ModsRemovedCompleted = true;
            }
        }
        if (Witcher3ModsRemovedCompleted) Witcher3ModsSaveTrackingPreferences();
    }
    for (Witcher3ModsCursor = 0; Witcher3ModsCursor < Witcher3ModsTrackedAchievementKeys.Size(); Witcher3ModsCursor += 1)
    {
        Witcher3ModsAchievementIndex = Witcher3ModsTrackingPresenter.Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsFindAchievementIndex(Witcher3ModsTrackedAchievementKeys[Witcher3ModsCursor]);
        if (Witcher3ModsAchievementIndex >= 0)
            Witcher3ModsTrackedHudText += Witcher3ModsTrackingPresenter.Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions[Witcher3ModsAchievementIndex].Witcher3ModsAchievementTitle + "\n" + Witcher3ModsBuildTrackedDescription(Witcher3ModsAchievementIndex) + "\n";
    }
}

@addMethod(CR4HudModuleQuests)
function Witcher3ModsPublishTrackedAchievementHud()
{
    var Witcher3ModsFlashRows : CScriptedFlashArray;
    var Witcher3ModsFlashRow : CScriptedFlashObject;
    var Witcher3ModsCursor, Witcher3ModsAchievementIndex : int;
    if (!Witcher3ModsTrackedMayShow())
    {
        Witcher3ModsHudPublishPending = true;
        return;
    }
    Witcher3ModsHudPublishPending = false;
    Witcher3ModsFlashRows = GetModuleFlashValueStorage().CreateTempFlashArray();
    for (Witcher3ModsCursor = 0; Witcher3ModsTrackingPresenter && Witcher3ModsCursor < Witcher3ModsTrackedAchievementKeys.Size(); Witcher3ModsCursor += 1)
    {
        Witcher3ModsAchievementIndex = Witcher3ModsTrackingPresenter.Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsFindAchievementIndex(Witcher3ModsTrackedAchievementKeys[Witcher3ModsCursor]);
        if (Witcher3ModsAchievementIndex < 0) continue;
        Witcher3ModsFlashRow = GetModuleFlashValueStorage().CreateTempFlashObject();
        Witcher3ModsFlashRow.SetMemberFlashString("title", Witcher3ModsTrackingPresenter.Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions[Witcher3ModsAchievementIndex].Witcher3ModsAchievementTitle);
        Witcher3ModsFlashRow.SetMemberFlashString("description", Witcher3ModsBuildTrackedDescription(Witcher3ModsAchievementIndex));
        Witcher3ModsFlashRows.PushBackFlashObject(Witcher3ModsFlashRow);
    }
    // Publish empty arrays too: removing the final pin must remove its container.
    GetModuleFlashValueStorage().SetFlashArray("Witcher3Mods.achievements", Witcher3ModsFlashRows);
}

@wrapMethod(CR4HudModuleQuests)
function OnConfigUI()
{
    wrappedMethod();
    Witcher3ModsLoadTrackingPreferences();
    Witcher3ModsPublishTrackedAchievementHud();
}

@wrapMethod(CR4HudModuleQuests)
function OnTick(Witcher3ModsTimeDelta : float)
{
    var Witcher3ModsPreviousHudText : string;
    wrappedMethod(Witcher3ModsTimeDelta);
    if (Witcher3ModsHudPublishPending && Witcher3ModsTrackedMayShow())
        Witcher3ModsPublishTrackedAchievementHud();
    if (Witcher3ModsTrackingPresenter && Witcher3ModsTrackedAchievementKeys.Size() > 0)
    {
        Witcher3ModsTrackingRefreshElapsed += Witcher3ModsTimeDelta;
        if (Witcher3ModsTrackingRefreshElapsed >= 2.0 && CheckIfUpdateIsAllowed())
        {
            Witcher3ModsTrackingRefreshElapsed = 0.0;
            Witcher3ModsPreviousHudText = Witcher3ModsTrackedHudText;
            Witcher3ModsTrackingPresenter.Witcher3ModsRefreshPresentation();
            Witcher3ModsRefreshTrackedHudText();
            if (Witcher3ModsPreviousHudText != Witcher3ModsTrackedHudText)
                Witcher3ModsPublishTrackedAchievementHud();
        }
    }
}
