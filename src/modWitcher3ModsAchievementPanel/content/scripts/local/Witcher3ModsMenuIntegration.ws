// Engine integration only. Keep native wrapper names and isolate synthetic rows.
class Witcher3ModsAchievementMenuContext extends W3MenuInitData
{
}

// Add one tab without replacing the original Glossary structure.
@wrapMethod(CR4GlossaryMainMenu)
function DefineMenuStructure() : void
{
    wrappedMethod();
    DefineMenuItem('Witcher3ModsAchievementsTab', "witcher3_achievements", '');
}

@wrapMethod(CR4GlossaryMainMenu)
function GetGFxMenuItem(Witcher3ModsMenuTabData : SMenuTab, out Witcher3ModsFlashMenuTab : CScriptedFlashObject) : void
{
    wrappedMethod(Witcher3ModsMenuTabData, Witcher3ModsFlashMenuTab);
    if (Witcher3ModsMenuTabData.MenuName == 'Witcher3ModsAchievementsTab')
    {
        Witcher3ModsFlashMenuTab.SetMemberFlashString("label", Witcher3ModsText("ui_tab", Witcher3ModsUsePolish()));
        Witcher3ModsFlashMenuTab.SetMemberFlashString("tabDesc", Witcher3ModsText("ui_tab_description", Witcher3ModsUsePolish()));
    }
}

@wrapMethod(CR4GlossaryMainMenu)
function OnRequestMenu(Witcher3ModsRequestedMenuName : name, Witcher3ModsRequestedMenuState : string)
{
    var Witcher3ModsMenuInitialization : Witcher3ModsAchievementMenuContext;
    var Witcher3ModsCurrentMenu : CR4MenuBase;
    var Witcher3ModsCurrentMenuContext : Witcher3ModsAchievementMenuContext;
    if (Witcher3ModsRequestedMenuName == 'Witcher3ModsAchievementsTab')
    {
        // Never store our tab in the game's saved state: the last glossary page (player) and the UI data (GUI manager)
        // are saved in the save file. A save that remembers a tab this mod defines would open an empty glossary once
        // the mod is removed. The glossary reopens on the last native page instead.
        SendTopBarTabSelected(Witcher3ModsRequestedMenuName, Witcher3ModsRequestedMenuState);
        Witcher3ModsCurrentMenu = (CR4MenuBase)GetSubMenu();
        if (Witcher3ModsCurrentMenu) OnPlaySoundEvent("gui_global_submenu_whoosh");
        else OnPlaySoundEvent("gui_global_panel_open");
        Witcher3ModsMenuInitialization = new Witcher3ModsAchievementMenuContext in this;
        Witcher3ModsMenuInitialization.ignoreSaveSystem = true;
        RequestSubMenu('GlossaryTutorialsMenu', Witcher3ModsMenuInitialization);
        m_fxSetHasMenu.InvokeSelfOneArg(FlashArgBool(true));
    }
    else
    {
        Witcher3ModsCurrentMenu = (CR4MenuBase)GetSubMenu();
        if (Witcher3ModsCurrentMenu)
        {
            Witcher3ModsCurrentMenuContext = (Witcher3ModsAchievementMenuContext)Witcher3ModsCurrentMenu.GetMenuInitData();
            if (Witcher3ModsCurrentMenuContext && Witcher3ModsRequestedMenuName == 'GlossaryTutorialsMenu')
                Witcher3ModsCurrentMenu.CloseMenu();
        }
        wrappedMethod(Witcher3ModsRequestedMenuName, Witcher3ModsRequestedMenuState);
    }
}

// Reuse the game's own list + description screen only for our marked instance.
// No journal entries are created or activated.
@addField(CR4GlossaryTutorialsMenu)
var Witcher3ModsPresenter : Witcher3ModsAchievementPresenter;

@addField(CR4GlossaryTutorialsMenu)
var Witcher3ModsOpeningFocus : bool;

@addField(CR4GlossaryTutorialsMenu)
var Witcher3ModsCategoryStates : array<bool>;

function Witcher3ModsCategoryPreferenceIndex(Witcher3ModsCategory : name) : int
{
    switch (Witcher3ModsCategory)
    {
        case 'Witcher3ModsBaseGameCategory': return 0;
        case 'Witcher3ModsBloodAndWineCategory': return 1;
        case 'Witcher3ModsHeartsOfStoneCategory': return 2;
        case 'Witcher3ModsCompletedCategory': return 3;
        case 'Witcher3ModsAvailabilityCategory': return 4;
    }
    return -1;
}

@addMethod(CR4GlossaryTutorialsMenu)
function Witcher3ModsLoadCategoryPreferences()
{
    var Witcher3ModsConfig : CInGameConfigWrapper;
    var Witcher3ModsIndex : int;
    var Witcher3ModsValue : string;
    Witcher3ModsConfig = theGame.GetInGameConfigWrapper();
    Witcher3ModsCategoryStates.Clear();
    for (Witcher3ModsIndex = 0; Witcher3ModsIndex < 5; Witcher3ModsIndex += 1)
    {
        Witcher3ModsValue = "";
        if (Witcher3ModsConfig)
            Witcher3ModsValue = Witcher3ModsConfig.GetRawConfigValueByStr("Witcher3ModsAchievementPanel", "Witcher3ModsCategory" + IntToString(Witcher3ModsIndex));
        Witcher3ModsCategoryStates.PushBack(Witcher3ModsValue == "1" || (Witcher3ModsValue != "0" && Witcher3ModsIndex == 0));
    }
}

@addMethod(CR4GlossaryTutorialsMenu)
function Witcher3ModsSaveCategoryPreference(Witcher3ModsCategory : name, Witcher3ModsExpanded : bool)
{
    var Witcher3ModsConfig : CInGameConfigWrapper;
    var Witcher3ModsIndex : int;
    var Witcher3ModsValue : string;
    Witcher3ModsIndex = Witcher3ModsCategoryPreferenceIndex(Witcher3ModsCategory);
    if (Witcher3ModsIndex < 0 || Witcher3ModsCategoryStates.Size() != 5) return;
    if (Witcher3ModsCategoryStates[Witcher3ModsIndex] == Witcher3ModsExpanded) return;
    Witcher3ModsConfig = theGame.GetInGameConfigWrapper();
    if (!Witcher3ModsConfig) return;
    Witcher3ModsCategoryStates[Witcher3ModsIndex] = Witcher3ModsExpanded;
    Witcher3ModsValue = "0";
    if (Witcher3ModsExpanded) Witcher3ModsValue = "1";
    Witcher3ModsConfig.SetRawConfigValueByStr("Witcher3ModsAchievementPanel", "Witcher3ModsCategory" + IntToString(Witcher3ModsIndex), Witcher3ModsValue);
    theGame.SaveUserSettings();
}

@wrapMethod(CR4ListBaseMenu)
function OnCategoryOpened(Witcher3ModsCategory : name, Witcher3ModsExpanded : bool)
{
    var Witcher3ModsMenu : CR4GlossaryTutorialsMenu;
    Witcher3ModsMenu = (CR4GlossaryTutorialsMenu)this;
    if (Witcher3ModsMenu && Witcher3ModsMenu.Witcher3ModsIsAchievementMenuContext())
        Witcher3ModsMenu.Witcher3ModsSaveCategoryPreference(Witcher3ModsCategory, Witcher3ModsExpanded);
    else wrappedMethod(Witcher3ModsCategory, Witcher3ModsExpanded);
}

@addMethod(CR4GlossaryTutorialsMenu)
function Witcher3ModsIsAchievementMenuContext() : bool
{
    var Witcher3ModsMenuInitialization : Witcher3ModsAchievementMenuContext;
    Witcher3ModsMenuInitialization = (Witcher3ModsAchievementMenuContext)GetMenuInitData();
    if (Witcher3ModsMenuInitialization)
    {
        return true;
    }
    return false;
}

@addMethod(CR4GlossaryTutorialsMenu)
function Witcher3ModsAppendAchievementListRow(Witcher3ModsFlashAchievementRows : CScriptedFlashArray, Witcher3ModsRowTag : name, Witcher3ModsRowLabel : string, Witcher3ModsCategoryTag : name, Witcher3ModsCategoryLabel : string)
{
    var Witcher3ModsFlashAchievementRow : CScriptedFlashObject;
    var Witcher3ModsRowAchievementIndex : int;
    var Witcher3ModsRowState : Witcher3ModsAchievementState;
    var Witcher3ModsTrackingHud : CR4HudModuleQuests;
    var Witcher3ModsRowTracked : bool;
    var Witcher3ModsDefinition : Witcher3ModsAchievementDefinition;
    Witcher3ModsFlashAchievementRow = m_flashValueStorage.CreateTempFlashObject();
    Witcher3ModsFlashAchievementRow.SetMemberFlashUInt("tag", NameToFlashUInt(Witcher3ModsRowTag));
    Witcher3ModsFlashAchievementRow.SetMemberFlashString("dropDownLabel", Witcher3ModsCategoryLabel);
    Witcher3ModsFlashAchievementRow.SetMemberFlashUInt("dropDownTag", NameToFlashUInt(Witcher3ModsCategoryTag));
    Witcher3ModsFlashAchievementRow.SetMemberFlashBool("dropDownOpened", Witcher3ModsCategoryStates[Witcher3ModsCategoryPreferenceIndex(Witcher3ModsCategoryTag)]);
    Witcher3ModsFlashAchievementRow.SetMemberFlashInt("originalId", Witcher3ModsFlashAchievementRows.GetLength());
    Witcher3ModsFlashAchievementRow.SetMemberFlashInt("originalCat", 4);
    Witcher3ModsFlashAchievementRow.SetMemberFlashInt("isStory", 2);
    Witcher3ModsFlashAchievementRow.SetMemberFlashInt("epIndex", 0);
    Witcher3ModsFlashAchievementRow.SetMemberFlashBool("isdeadlydifficulty", false);
    Witcher3ModsFlashAchievementRow.SetMemberFlashString("reqdifficulty", "");
    Witcher3ModsFlashAchievementRow.SetMemberFlashString("area", "");
    Witcher3ModsFlashAchievementRow.SetMemberFlashString("questArea", "Witcher3ModsNone");
    Witcher3ModsFlashAchievementRow.SetMemberFlashString("title", Witcher3ModsRowLabel);
    Witcher3ModsFlashAchievementRow.SetMemberFlashString("description", "");
    Witcher3ModsFlashAchievementRow.SetMemberFlashString("secondLabel", "");
    Witcher3ModsFlashAchievementRow.SetMemberFlashBool("isNew", false);
    Witcher3ModsFlashAchievementRow.SetMemberFlashBool("Witcher3ModsOpeningFocus", Witcher3ModsOpeningFocus);
    Witcher3ModsFlashAchievementRow.SetMemberFlashBool("selected", Witcher3ModsRowTag == currentTag);
    Witcher3ModsFlashAchievementRow.SetMemberFlashString("label", Witcher3ModsRowLabel);
    Witcher3ModsRowAchievementIndex = Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsFindAchievementIndex(Witcher3ModsRowTag);
    if (Witcher3ModsRowAchievementIndex >= 0)
    {
        Witcher3ModsTrackingHud = Witcher3ModsGetAchievementTrackingHud();
        if (Witcher3ModsTrackingHud)
            Witcher3ModsRowTracked = Witcher3ModsTrackingHud.Witcher3ModsIsAchievementTracked(Witcher3ModsRowTag);
        Witcher3ModsFlashAchievementRow.SetMemberFlashString("label", Witcher3ModsPresenter.Witcher3ModsBuildQuestRowTitle(Witcher3ModsRowAchievementIndex, Witcher3ModsRowTracked));
        Witcher3ModsRowState = Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsSnapshots[Witcher3ModsRowAchievementIndex].Witcher3ModsState;
        Witcher3ModsDefinition = Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions[Witcher3ModsRowAchievementIndex];
        Witcher3ModsFlashAchievementRow.SetMemberFlashString("title", Witcher3ModsDefinition.Witcher3ModsAchievementTitle);
        Witcher3ModsFlashAchievementRow.SetMemberFlashString("Witcher3ModsRowDescription", Witcher3ModsDefinition.Witcher3ModsDescriptionText);
        // Flash reuses secondLabel for its auto-sized center header. Keep it
        // compact; the complete description belongs in objectives and details.
        Witcher3ModsFlashAchievementRow.SetMemberFlashString("secondLabel", Witcher3ModsPresenter.Witcher3ModsBuildHeaderSubtitle(Witcher3ModsRowAchievementIndex));
        Witcher3ModsFlashAchievementRow.SetMemberFlashString("description", Witcher3ModsPresenter.Witcher3ModsBuildAchievementDetails(Witcher3ModsRowAchievementIndex));
        Witcher3ModsFlashAchievementRow.SetMemberFlashInt("originalCat", Witcher3ModsPresenter.Witcher3ModsGetDisplayCategory(Witcher3ModsRowAchievementIndex));
        // Patched Flash toggles mod pins without the native UNTRACK broadcast.
        Witcher3ModsFlashAchievementRow.SetMemberFlashBool("Witcher3ModsAchievement", true);
        Witcher3ModsFlashAchievementRow.SetMemberFlashBool("tracked", Witcher3ModsRowTracked);
        Witcher3ModsFlashAchievementRow.SetMemberFlashString("questArea", "Witcher3Mods_" + NameToString(Witcher3ModsRowTag));
        // Existing quest renderer owns status artwork; do not invent Flash color fields.
        if (Witcher3ModsRowState == Witcher3ModsAchievementEarned) Witcher3ModsFlashAchievementRow.SetMemberFlashInt("status", JS_Success);
        else Witcher3ModsFlashAchievementRow.SetMemberFlashInt("status", JS_Active);
    }
    else
    {
        // Summary is not an active quest. Reuse the completed category's
        // stripe-free presentation; this does not change any achievement state.
        Witcher3ModsFlashAchievementRow.SetMemberFlashInt("status", JS_Success);
        Witcher3ModsFlashAchievementRow.SetMemberFlashBool("tracked", false);
        Witcher3ModsFlashAchievementRow.SetMemberFlashBool("Witcher3ModsSummary", true);
        Witcher3ModsFlashAchievementRow.SetMemberFlashString("description", Witcher3ModsPresenter.Witcher3ModsBuildAvailabilitySummary());
        Witcher3ModsFlashAchievementRow.SetMemberFlashString("secondLabel", Witcher3ModsText("ui_state", Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsPolish));
    }
    Witcher3ModsFlashAchievementRow.SetMemberFlashString("iconPath", "");
    Witcher3ModsFlashAchievementRows.PushBackFlashObject(Witcher3ModsFlashAchievementRow);
}

@wrapMethod(CR4GlossaryTutorialsMenu)
function PopulateData()
{
    var Witcher3ModsFlashAchievementRows : CScriptedFlashArray;
    var Witcher3ModsAchievementCursor : int;
    var Witcher3ModsCategoryOrder, Witcher3ModsRowCategory : int;
    var Witcher3ModsCategoryTag : name;
    var Witcher3ModsCategoryLabel : string;
    var Witcher3ModsEnableView : CScriptedFlashFunction;
    if (Witcher3ModsIsAchievementMenuContext())
    {
        // The native tutorial root has already registered and bound to this WS menu.
        Witcher3ModsEnableView = m_flashModule.GetMemberFlashFunction("Witcher3ModsEnableAchievements");
        Witcher3ModsEnableView.InvokeSelf();
        m_initialSelectionsToIgnore = 0;
        Witcher3ModsLoadCategoryPreferences();
        if (!Witcher3ModsPresenter)
            Witcher3ModsPresenter = new Witcher3ModsAchievementPresenter in this;
        Witcher3ModsPresenter.Witcher3ModsRefreshPresentation();
        if (!Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsStatusReady || Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsFindAchievementIndex(currentTag) < 0)
            currentTag = 'Witcher3ModsAvailabilitySummary';
        Witcher3ModsFlashAchievementRows = m_flashValueStorage.CreateTempFlashArray();
        // Display order is independent of catalogue order; earned entries occur only once.
        for (Witcher3ModsCategoryOrder = 0; Witcher3ModsCategoryOrder < 4; Witcher3ModsCategoryOrder += 1)
        {
        for (Witcher3ModsAchievementCursor = 0; Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsStatusReady && Witcher3ModsAchievementCursor < Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions.Size(); Witcher3ModsAchievementCursor += 1)
        {
            Witcher3ModsRowCategory = Witcher3ModsPresenter.Witcher3ModsGetDisplayCategory(Witcher3ModsAchievementCursor);
            if (Witcher3ModsRowCategory != Witcher3ModsCategoryOrder) continue;
            if (Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions[Witcher3ModsAchievementCursor].Witcher3ModsExpansionGroup == 0)
            {
                Witcher3ModsCategoryTag = 'Witcher3ModsBaseGameCategory';
                Witcher3ModsCategoryLabel = Witcher3ModsText("ui_base_game", Witcher3ModsUsePolish());
            }
            else if (Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions[Witcher3ModsAchievementCursor].Witcher3ModsExpansionGroup == 1)
            {
                Witcher3ModsCategoryTag = 'Witcher3ModsHeartsOfStoneCategory';
                Witcher3ModsCategoryLabel = Witcher3ModsText("ui_hos", Witcher3ModsUsePolish());
            }
            else
            {
                Witcher3ModsCategoryTag = 'Witcher3ModsBloodAndWineCategory';
                Witcher3ModsCategoryLabel = Witcher3ModsText("ui_baw", Witcher3ModsUsePolish());
            }
            if (Witcher3ModsRowCategory == 3)
            {
                Witcher3ModsCategoryTag = 'Witcher3ModsCompletedCategory';
                Witcher3ModsCategoryLabel = Witcher3ModsText("ui_completed", Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsPolish);
            }
            Witcher3ModsAppendAchievementListRow(Witcher3ModsFlashAchievementRows, Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions[Witcher3ModsAchievementCursor].Witcher3ModsAchievementKey, Witcher3ModsPresenter.Witcher3ModsBuildAchievementRowLabel(Witcher3ModsAchievementCursor), Witcher3ModsCategoryTag, Witcher3ModsCategoryLabel);
        }
        }
        Witcher3ModsAppendAchievementListRow(Witcher3ModsFlashAchievementRows, 'Witcher3ModsAvailabilitySummary', Witcher3ModsText("ui_summary", Witcher3ModsUsePolish()), 'Witcher3ModsAvailabilityCategory', Witcher3ModsText("ui_state", Witcher3ModsUsePolish()));
        m_flashValueStorage.SetFlashArray("Witcher3Mods.achievement.list", Witcher3ModsFlashAchievementRows);
        // Reveal the embedded view after publishing its isolated data.
        m_fxShowSecondaryModulesSFF.InvokeSelfOneArg(FlashArgBool(true));
        Witcher3ModsUpdateObjectives(currentTag);
        UpdateDescription(currentTag);
    }
    else wrappedMethod();
}

@wrapMethod(CR4GlossaryTutorialsMenu)
function UpdateDescription(Witcher3ModsSelectedAchievementKey : name)
{
    var Witcher3ModsAchievementIndex : int;
    var Witcher3ModsAchievementTitle, Witcher3ModsDescriptionText : string;
    var Witcher3ModsListModule : CScriptedFlashObject;
    var Witcher3ModsUpdateTrackingButton : CScriptedFlashFunction;
    var Witcher3ModsSummaryView : CScriptedFlashFunction;
    var Witcher3ModsDetailsModule : CScriptedFlashObject;
    if (Witcher3ModsIsAchievementMenuContext())
    {
        if (Witcher3ModsPresenter)
        {
            Witcher3ModsSelectedAchievementKey = Witcher3ModsResolveDetailSelection(Witcher3ModsSelectedAchievementKey);
            Witcher3ModsAchievementIndex = Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsFindAchievementIndex(Witcher3ModsSelectedAchievementKey);
            if (Witcher3ModsAchievementIndex >= 0)
            {
                Witcher3ModsAchievementTitle = Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions[Witcher3ModsAchievementIndex].Witcher3ModsAchievementTitle;
                Witcher3ModsDescriptionText = Witcher3ModsPresenter.Witcher3ModsBuildAchievementDetails(Witcher3ModsAchievementIndex);
            }
            else
            {
                Witcher3ModsAchievementTitle = Witcher3ModsText("ui_summary_title", Witcher3ModsUsePolish());
                Witcher3ModsDescriptionText = Witcher3ModsPresenter.Witcher3ModsBuildAvailabilitySummary();
                // Native Flash setTitle/setText are no-ops for category focus.
                // Refresh title, subtitle, empty crest and details together.
                Witcher3ModsDetailsModule = m_flashModule.GetMemberFlashObject("Witcher3ModsDetails");
                if (Witcher3ModsDetailsModule)
                    Witcher3ModsSummaryView = Witcher3ModsDetailsModule.GetMemberFlashFunction("Witcher3ModsShowSummary");
                if (Witcher3ModsSummaryView)
                    Witcher3ModsSummaryView.InvokeSelfThreeArgs(FlashArgString(Witcher3ModsAchievementTitle), FlashArgString(Witcher3ModsText("ui_state", Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsPolish)), FlashArgString(Witcher3ModsDescriptionText));
            }
            m_fxSetTitle.InvokeSelfOneArg(FlashArgString(Witcher3ModsAchievementTitle));
            m_fxSetText.InvokeSelfOneArg(FlashArgString(Witcher3ModsDescriptionText));
            Witcher3ModsListModule = m_flashModule.GetMemberFlashObject("Witcher3ModsList");
            if (Witcher3ModsListModule)
            {
                Witcher3ModsUpdateTrackingButton = Witcher3ModsListModule.GetMemberFlashFunction("updateItemInputFeedback");
                Witcher3ModsListModule.SetMemberFlashString("itemInputFeedbackLabel", "");
                if (Witcher3ModsUpdateTrackingButton) Witcher3ModsUpdateTrackingButton.InvokeSelf();
                if (Witcher3ModsAchievementIndex >= 0 && Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsSnapshots[Witcher3ModsAchievementIndex].Witcher3ModsState != Witcher3ModsAchievementEarned)
                    Witcher3ModsListModule.SetMemberFlashString("itemInputFeedbackLabel", "Witcher3ModsToggleTracking");
                if (Witcher3ModsUpdateTrackingButton) Witcher3ModsUpdateTrackingButton.InvokeSelf();
            }
        }
    }
    else wrappedMethod(Witcher3ModsSelectedAchievementKey);
}

@wrapMethod(CR4GlossaryTutorialsMenu)
function UpdateImage(Witcher3ModsRowTag : name)
{
    if (!Witcher3ModsIsAchievementMenuContext()) wrappedMethod(Witcher3ModsRowTag);
}

// Synthetic achievement rows must not be marked as read journal entries.
@wrapMethod(CR4MenuBase)
function GetSavedDataMenuName() : name
{
    var Witcher3ModsMenuInitialization : Witcher3ModsAchievementMenuContext;
    Witcher3ModsMenuInitialization = (Witcher3ModsAchievementMenuContext)GetMenuInitData();
    if (Witcher3ModsMenuInitialization) return 'Witcher3ModsAchievementsTab';
    return wrappedMethod();
}

@wrapMethod(CR4ListBaseMenu)
function OnEntryRead(Witcher3ModsRowTag : name)
{
    var Witcher3ModsMenuInitialization : Witcher3ModsAchievementMenuContext;
    Witcher3ModsMenuInitialization = (Witcher3ModsAchievementMenuContext)GetMenuInitData();
    if (!Witcher3ModsMenuInitialization) wrappedMethod(Witcher3ModsRowTag);
}

@wrapMethod(CR4ListBaseMenu)
function SaveStateData()
{
    var Witcher3ModsMenuInitialization : Witcher3ModsAchievementMenuContext;
    Witcher3ModsMenuInitialization = (Witcher3ModsAchievementMenuContext)GetMenuInitData();
    if (!Witcher3ModsMenuInitialization) wrappedMethod();
}

@addMethod(CR4GlossaryTutorialsMenu)
function Witcher3ModsToggleSelectedAchievement(Witcher3ModsAchievementKey : name)
{
    var Witcher3ModsTrackingHud : CR4HudModuleQuests;
    Witcher3ModsTrackingHud = Witcher3ModsGetAchievementTrackingHud();
    if (Witcher3ModsTrackingHud && Witcher3ModsPresenter)
    {
        if (Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsFindAchievementIndex(Witcher3ModsAchievementKey) >= 0)
        {
            Witcher3ModsTrackingHud.Witcher3ModsToggleAchievementTracking(Witcher3ModsAchievementKey);
            currentTag = Witcher3ModsAchievementKey;
            PopulateData();
        }
    }
}

@wrapMethod(CR4ListBaseMenu)
function OnEntryPress(Witcher3ModsPressedTag : name)
{
    var Witcher3ModsAchievementMenu : CR4GlossaryTutorialsMenu;
    Witcher3ModsAchievementMenu = (CR4GlossaryTutorialsMenu)this;
    if (Witcher3ModsAchievementMenu && Witcher3ModsAchievementMenu.Witcher3ModsIsAchievementMenuContext())
        Witcher3ModsAchievementMenu.Witcher3ModsToggleSelectedAchievement(Witcher3ModsPressedTag);
    else wrappedMethod(Witcher3ModsPressedTag);
}

// Native button binding, with an explicitly localized label instead of a fake loc key.
@wrapMethod(CR4MenuBase)
function OnAppendGFxButton(Witcher3ModsActionId : int, Witcher3ModsGamepadCode : string, Witcher3ModsKeyboardCode : int, Witcher3ModsButtonLabel : string, Witcher3ModsHoldPrefix : bool, optional Witcher3ModsHoldDuration : float)
{
    var Witcher3ModsAchievementMenu : CR4GlossaryTutorialsMenu;
    var Witcher3ModsTrackingHud : CR4HudModuleQuests;
    var Witcher3ModsBindingCursor : int;
    var Witcher3ModsTrackingButtonText : string;
    wrappedMethod(Witcher3ModsActionId, Witcher3ModsGamepadCode, Witcher3ModsKeyboardCode, Witcher3ModsButtonLabel, Witcher3ModsHoldPrefix, Witcher3ModsHoldDuration);
    Witcher3ModsAchievementMenu = (CR4GlossaryTutorialsMenu)this;
    if (Witcher3ModsAchievementMenu && Witcher3ModsAchievementMenu.Witcher3ModsIsAchievementMenuContext() && Witcher3ModsButtonLabel == "Witcher3ModsToggleTracking")
    {
        Witcher3ModsTrackingButtonText = Witcher3ModsText("ui_track", Witcher3ModsUsePolish());
        Witcher3ModsTrackingHud = Witcher3ModsGetAchievementTrackingHud();
        if (Witcher3ModsTrackingHud && Witcher3ModsTrackingHud.Witcher3ModsIsAchievementTracked(Witcher3ModsAchievementMenu.currentTag))
            Witcher3ModsTrackingButtonText = Witcher3ModsText("ui_untrack", Witcher3ModsUsePolish());
        for (Witcher3ModsBindingCursor = 0; Witcher3ModsBindingCursor < m_GFxInputBindings.Size(); Witcher3ModsBindingCursor += 1)
        {
            if (m_GFxInputBindings[Witcher3ModsBindingCursor].ActionID == Witcher3ModsActionId)
            {
                m_GFxInputBindings[Witcher3ModsBindingCursor].LocalizationKey = Witcher3ModsTrackingButtonText;
                m_GFxInputBindings[Witcher3ModsBindingCursor].IsLocalized = true;
            }
        }
    }
}

// Native OnConfigUI publishes the initial rows; Flash buffers them until ready.
// Do not republish/reset focus in OnMenuShown: it runs after the entrance
// animation, when the player may already have navigated away from the header.
@wrapMethod(CR4GlossaryTutorialsMenu)
function OnConfigUI()
{
    if (Witcher3ModsIsAchievementMenuContext())
    {
        dontAutoCallOnOpeningMenuInOnConfigUIHaxxor = true;
        currentTag = 'Witcher3ModsAvailabilitySummary';
        Witcher3ModsOpeningFocus = true;
    }
    wrappedMethod();
    Witcher3ModsOpeningFocus = false;
}

@wrapMethod(CR4ListBaseMenu)
function OnClosingMenu()
{
    var Witcher3ModsMenuInitialization : Witcher3ModsAchievementMenuContext;
    Witcher3ModsMenuInitialization = (Witcher3ModsAchievementMenuContext)GetMenuInitData();
    // Do not replace the last normal menu with GlossaryTutorialsMenu on closing our tab.
    if (Witcher3ModsMenuInitialization) super.OnClosingMenu();
    else wrappedMethod();
}

@wrapMethod(CR4ListBaseMenu)
function OnEntrySelected(Witcher3ModsSelectedTag : name)
{
    var Witcher3ModsMenu : CR4GlossaryTutorialsMenu;
    Witcher3ModsMenu = (CR4GlossaryTutorialsMenu)this;
    if (Witcher3ModsMenu && Witcher3ModsMenu.Witcher3ModsIsAchievementMenuContext())
        Witcher3ModsMenu.Witcher3ModsSelectAchievement(Witcher3ModsSelectedTag);
    else wrappedMethod(Witcher3ModsSelectedTag);
}

@addMethod(CR4GlossaryTutorialsMenu)
function Witcher3ModsSelectAchievement(Witcher3ModsSelectedTag : name)
{
    currentTag = Witcher3ModsResolveDetailSelection(Witcher3ModsSelectedTag);
    UpdateDescription(currentTag);
    Witcher3ModsUpdateObjectives(currentTag);
    m_fxShowSecondaryModulesSFF.InvokeSelfOneArg(FlashArgBool(true));
}

// Category headers and an empty focus are not achievements. Keep the detail
// selection on the summary without moving keyboard focus or rebuilding the list.
@addMethod(CR4GlossaryTutorialsMenu)
function Witcher3ModsResolveDetailSelection(Witcher3ModsFocusedTag : name) : name
{
    if (Witcher3ModsPresenter)
    {
        if (Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsStatusReady && Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsFindAchievementIndex(Witcher3ModsFocusedTag) >= 0)
            return Witcher3ModsFocusedTag;
    }
    return 'Witcher3ModsAvailabilitySummary';
}

@wrapMethod(CR4GlossaryTutorialsMenu)
function UpdateItems(Witcher3ModsSelectedTag : name)
{
    if (!Witcher3ModsIsAchievementMenuContext()) wrappedMethod(Witcher3ModsSelectedTag);
}

@wrapMethod(CR4ListBaseMenu)
function OnGetItemData(Witcher3ModsItem : int, Witcher3ModsCompareItemType : int)
{
    var Witcher3ModsMenuInitialization : Witcher3ModsAchievementMenuContext;
    Witcher3ModsMenuInitialization = (Witcher3ModsAchievementMenuContext)GetMenuInitData();
    if (!Witcher3ModsMenuInitialization) wrappedMethod(Witcher3ModsItem, Witcher3ModsCompareItemType);
}

@addMethod(CR4GlossaryTutorialsMenu)
function Witcher3ModsUpdateObjectives(Witcher3ModsSelectedTag : name)
{
    var Witcher3ModsRows : CScriptedFlashArray;
    var Witcher3ModsRow : CScriptedFlashObject;
    var Witcher3ModsIndex : int;
    var Witcher3ModsTitle, Witcher3ModsTextValue : string;
    var Witcher3ModsTrackingHud : CR4HudModuleQuests;
    if (Witcher3ModsIsAchievementMenuContext())
    {
        if (Witcher3ModsPresenter)
        {
            // Flash may clear objectives for a header independently of entry
            // selection. Resolve this path too so it cannot publish an empty list.
            if (Witcher3ModsSelectedTag != Witcher3ModsResolveDetailSelection(Witcher3ModsSelectedTag))
            {
                Witcher3ModsSelectedTag = Witcher3ModsResolveDetailSelection(Witcher3ModsSelectedTag);
                currentTag = Witcher3ModsSelectedTag;
                UpdateDescription(currentTag);
            }
            Witcher3ModsRows = m_flashValueStorage.CreateTempFlashArray();
            Witcher3ModsIndex = Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsFindAchievementIndex(Witcher3ModsSelectedTag);
            Witcher3ModsTitle = Witcher3ModsText("ui_summary_title", Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsPolish);
            if (Witcher3ModsIndex >= 0)
            {
                Witcher3ModsTitle = Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions[Witcher3ModsIndex].Witcher3ModsAchievementTitle;
                Witcher3ModsTextValue = Witcher3ModsPresenter.Witcher3ModsBuildObjectiveText(Witcher3ModsIndex);
                Witcher3ModsRow = m_flashValueStorage.CreateTempFlashObject();
                Witcher3ModsRow.SetMemberFlashUInt("tag", NameToFlashUInt(Witcher3ModsSelectedTag));
                Witcher3ModsRow.SetMemberFlashString("label", Witcher3ModsTextValue);
                Witcher3ModsRow.SetMemberFlashInt("phaseIndex", 1);
                Witcher3ModsRow.SetMemberFlashInt("objectiveIndex", 0);
                Witcher3ModsRow.SetMemberFlashBool("isNew", false);
                Witcher3ModsRow.SetMemberFlashBool("isLegend", false);
                Witcher3ModsRow.SetMemberFlashBool("isMutuallyExclusive", false);
                Witcher3ModsTrackingHud = Witcher3ModsGetAchievementTrackingHud();
                Witcher3ModsRow.SetMemberFlashBool("Witcher3ModsAchievement", true);
                Witcher3ModsRow.SetMemberFlashBool("tracked", false);
                if (Witcher3ModsTrackingHud)
                    Witcher3ModsRow.SetMemberFlashBool("tracked", Witcher3ModsTrackingHud.Witcher3ModsIsAchievementTracked(Witcher3ModsSelectedTag));
                if (Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsSnapshots[Witcher3ModsIndex].Witcher3ModsState == Witcher3ModsAchievementEarned)
                    Witcher3ModsRow.SetMemberFlashInt("status", JS_Success);
                else Witcher3ModsRow.SetMemberFlashInt("status", JS_Active);
                Witcher3ModsRows.PushBackFlashObject(Witcher3ModsRow);
            }
            else if (Witcher3ModsSelectedTag == 'Witcher3ModsAvailabilitySummary')
            {
                    Witcher3ModsRow = m_flashValueStorage.CreateTempFlashObject();
                    Witcher3ModsRow.SetMemberFlashUInt("tag", NameToFlashUInt('Witcher3ModsSummaryOverview'));
                    Witcher3ModsRow.SetMemberFlashString("label", Witcher3ModsPresenter.Witcher3ModsBuildSummaryObjective(0));
                    Witcher3ModsRow.SetMemberFlashInt("phaseIndex", 1);
                    Witcher3ModsRow.SetMemberFlashInt("objectiveIndex", 0);
                    Witcher3ModsRow.SetMemberFlashInt("status", JS_Active);
                    if (Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsStatusReady && !Witcher3ModsPresenter.Witcher3ModsReadout.Witcher3ModsAchievementsDisabled)
                        Witcher3ModsRow.SetMemberFlashInt("status", JS_Success);
                    Witcher3ModsRow.SetMemberFlashBool("isNew", false);
                    Witcher3ModsRow.SetMemberFlashBool("tracked", false);
                    Witcher3ModsRow.SetMemberFlashBool("isLegend", false);
                    Witcher3ModsRow.SetMemberFlashBool("isMutuallyExclusive", false);
                    Witcher3ModsRows.PushBackFlashObject(Witcher3ModsRow);
            }
            m_flashValueStorage.SetFlashArray("Witcher3Mods.achievement.objectives", Witcher3ModsRows);
            m_flashValueStorage.SetFlashString("Witcher3Mods.achievement.objectives" + ".questname", Witcher3ModsTitle);
        }
    }
}
