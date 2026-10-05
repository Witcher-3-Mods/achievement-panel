// Presentation consumes a captured readout; it does not query the game or mutate it.
class Witcher3ModsAchievementPresenter extends CObject
{
    var Witcher3ModsReadout : Witcher3ModsAchievementReadout;

    function Witcher3ModsRefreshPresentation()
    {
        if (!Witcher3ModsReadout)
            Witcher3ModsReadout = new Witcher3ModsAchievementReadout in this;
        Witcher3ModsReadout.Witcher3ModsRefreshSnapshot();
    }

    function Witcher3ModsBuildAchievementRowLabel(Witcher3ModsIndex : int, optional Witcher3ModsTracked : bool) : string
    {
        var Witcher3ModsDefinition : Witcher3ModsAchievementDefinition;
        var Witcher3ModsSnapshot : Witcher3ModsAchievementSnapshot;
        var Witcher3ModsLabel : string;
        Witcher3ModsDefinition = Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions[Witcher3ModsIndex];
        Witcher3ModsSnapshot = Witcher3ModsReadout.Witcher3ModsSnapshots[Witcher3ModsIndex];
        Witcher3ModsLabel = Witcher3ModsDefinition.Witcher3ModsAchievementTitle;
        if (Witcher3ModsDefinition.Witcher3ModsRequiredProgress > 0)
        {
            if (Witcher3ModsSnapshot.Witcher3ModsProgress < 0) Witcher3ModsLabel += "  —";
            else Witcher3ModsLabel += "  " + Witcher3ModsSnapshot.Witcher3ModsProgress;
            Witcher3ModsLabel += "/" + Witcher3ModsDefinition.Witcher3ModsRequiredProgress;
        }
        if (Witcher3ModsTracked)
            return "<font color='#FFCC00'>" + Witcher3ModsLabel + "</font>";
        if (Witcher3ModsSnapshot.Witcher3ModsState == Witcher3ModsAchievementEarned)
            return "<font color='#209226'>" + Witcher3ModsLabel + "</font>";
        if (Witcher3ModsSnapshot.Witcher3ModsState == Witcher3ModsAchievementBlocked)
            return "<font color='#D78370'>" + Witcher3ModsLabel + "</font>";
        return Witcher3ModsLabel;
    }

    function Witcher3ModsGetDisplayCategory(Witcher3ModsIndex : int) : int
    {
        var Witcher3ModsGroup : int;
        if (Witcher3ModsReadout.Witcher3ModsSnapshots[Witcher3ModsIndex].Witcher3ModsState == Witcher3ModsAchievementEarned) return 3;
        Witcher3ModsGroup = Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions[Witcher3ModsIndex].Witcher3ModsExpansionGroup;
        if (Witcher3ModsGroup == 1) return 2;
        if (Witcher3ModsGroup == 2) return 1;
        return 0;
    }

    function Witcher3ModsBuildCompactProgress(Witcher3ModsIndex : int) : string
    {
        var Witcher3ModsTarget, Witcher3ModsProgress : int;
        Witcher3ModsTarget = Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions[Witcher3ModsIndex].Witcher3ModsRequiredProgress;
        if (Witcher3ModsTarget <= 0) return "";
        Witcher3ModsProgress = Witcher3ModsReadout.Witcher3ModsSnapshots[Witcher3ModsIndex].Witcher3ModsProgress;
        if (Witcher3ModsProgress < 0) return "—/" + Witcher3ModsTarget;
        return Witcher3ModsProgress + "/" + Witcher3ModsTarget;
    }

    function Witcher3ModsBuildQuestRowTitle(Witcher3ModsIndex : int, Witcher3ModsTracked : bool) : string
    {
        var Witcher3ModsTitle : string;
        Witcher3ModsTitle = Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions[Witcher3ModsIndex].Witcher3ModsAchievementTitle;
        if (Witcher3ModsTracked) return "<font color='#FFCC00'>" + Witcher3ModsTitle + "</font>";
        if (Witcher3ModsReadout.Witcher3ModsSnapshots[Witcher3ModsIndex].Witcher3ModsState == Witcher3ModsAchievementEarned)
            return "<font color='#209226'>" + Witcher3ModsTitle + "</font>";
        return Witcher3ModsTitle;
    }

    function Witcher3ModsBuildObjectiveText(Witcher3ModsIndex : int) : string
    {
        var Witcher3ModsDefinition : Witcher3ModsAchievementDefinition;
        var Witcher3ModsSnapshot : Witcher3ModsAchievementSnapshot;
        var Witcher3ModsBody : string;
        Witcher3ModsDefinition = Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions[Witcher3ModsIndex];
        Witcher3ModsSnapshot = Witcher3ModsReadout.Witcher3ModsSnapshots[Witcher3ModsIndex];
        Witcher3ModsBody = Witcher3ModsDefinition.Witcher3ModsDescriptionText;
        if (Witcher3ModsDefinition.Witcher3ModsRequiredProgress > 0)
            Witcher3ModsBody += "<br>" + Witcher3ModsFormatProgress(Witcher3ModsDefinition, Witcher3ModsSnapshot);
        if (Witcher3ModsSnapshot.Witcher3ModsState == Witcher3ModsAchievementBlocked)
            Witcher3ModsBody += "<br>" + Witcher3ModsText("ui_blocked_html", Witcher3ModsReadout.Witcher3ModsPolish) + Witcher3ModsSnapshot.Witcher3ModsBlockReason;
        return Witcher3ModsBody;
    }

    function Witcher3ModsBuildTechnicalDetails(Witcher3ModsIndex : int) : string
    {
        var Witcher3ModsDefinition : Witcher3ModsAchievementDefinition;
        var Witcher3ModsBody : string;
        Witcher3ModsDefinition = Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions[Witcher3ModsIndex];
        Witcher3ModsBody = Witcher3ModsText("ui_achievement_key", Witcher3ModsReadout.Witcher3ModsPolish) + NameToString(Witcher3ModsDefinition.Witcher3ModsAchievementKey);
        if (Witcher3ModsDefinition.Witcher3ModsCounterFactKey != "")
            Witcher3ModsBody += Witcher3ModsText("ui_counter_key", Witcher3ModsReadout.Witcher3ModsPolish) + Witcher3ModsDefinition.Witcher3ModsCounterFactKey;
        return Witcher3ModsBody + "</font>";
    }

    function Witcher3ModsFormatSection(Witcher3ModsHeading : string, Witcher3ModsBody : string) : string
    {
        return "<font color='#BEA16A'><b>" + Witcher3ModsHeading + "</b></font><br>" + Witcher3ModsBody;
    }

    function Witcher3ModsFormatProgress(Witcher3ModsDefinition : Witcher3ModsAchievementDefinition, Witcher3ModsSnapshot : Witcher3ModsAchievementSnapshot) : string
    {
        var Witcher3ModsProgressText : string;
        if (Witcher3ModsDefinition.Witcher3ModsRequiredProgress <= 0)
        {
            if (Witcher3ModsSnapshot.Witcher3ModsState == Witcher3ModsAchievementEarned) return "1 / 1";
            return "0 / 1";
        }
        if (Witcher3ModsSnapshot.Witcher3ModsProgress < 0) return Witcher3ModsText("ui_no_progress", Witcher3ModsReadout.Witcher3ModsPolish) + Witcher3ModsDefinition.Witcher3ModsRequiredProgress;
        // Account unlocks never replace the actual save counter, even below or above target.
        Witcher3ModsProgressText = Witcher3ModsSnapshot.Witcher3ModsProgress + " / " + Witcher3ModsDefinition.Witcher3ModsRequiredProgress;
        if (Witcher3ModsDefinition.Witcher3ModsStatistic == ES_CounterattackChain
            || Witcher3ModsDefinition.Witcher3ModsStatistic == ES_FinesseKills
            || Witcher3ModsDefinition.Witcher3ModsStatistic == ES_SlideTime)
            Witcher3ModsProgressText += Witcher3ModsText("ui_attempt", Witcher3ModsReadout.Witcher3ModsPolish);
        else if (Witcher3ModsDefinition.Witcher3ModsStatistic == ES_ActivePotions)
            Witcher3ModsProgressText += Witcher3ModsText("ui_active_effects", Witcher3ModsReadout.Witcher3ModsPolish);
        else if (Witcher3ModsDefinition.Witcher3ModsAchievementKey == 'EA_TrialOfGrasses')
            Witcher3ModsProgressText += Witcher3ModsText("ui_occupied_slots", Witcher3ModsReadout.Witcher3ModsPolish);
        else if (Witcher3ModsDefinition.Witcher3ModsStatistic == ES_ReadBooks)
            Witcher3ModsProgressText += Witcher3ModsText("ui_read_documents", Witcher3ModsReadout.Witcher3ModsPolish);
        else if (Witcher3ModsDefinition.Witcher3ModsStatistic == ES_KnownBombRecipes || Witcher3ModsDefinition.Witcher3ModsStatistic == ES_KnownPotionRecipes)
            Witcher3ModsProgressText += Witcher3ModsText("ui_known_recipes", Witcher3ModsReadout.Witcher3ModsPolish);
        else
            Witcher3ModsProgressText += Witcher3ModsText("ui_current_save", Witcher3ModsReadout.Witcher3ModsPolish);
        return Witcher3ModsProgressText;
    }

    function Witcher3ModsBuildAchievementDetails(Witcher3ModsIndex : int) : string
    {
        var Witcher3ModsDefinition : Witcher3ModsAchievementDefinition;
        var Witcher3ModsSnapshot : Witcher3ModsAchievementSnapshot;
        var Witcher3ModsBody, Witcher3ModsAvailability, Witcher3ModsCounterKey, Witcher3ModsHintsKey, Witcher3ModsHints : string;
        Witcher3ModsDefinition = Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions[Witcher3ModsIndex];
        Witcher3ModsSnapshot = Witcher3ModsReadout.Witcher3ModsSnapshots[Witcher3ModsIndex];
        Witcher3ModsAvailability = Witcher3ModsText("ui_pending", Witcher3ModsReadout.Witcher3ModsPolish);
        if (Witcher3ModsSnapshot.Witcher3ModsState == Witcher3ModsAchievementEarned)
            Witcher3ModsAvailability = Witcher3ModsText("ui_earned_html", Witcher3ModsReadout.Witcher3ModsPolish);
        else if (Witcher3ModsSnapshot.Witcher3ModsState == Witcher3ModsAchievementBlocked)
            Witcher3ModsAvailability = Witcher3ModsText("ui_blocked_html", Witcher3ModsReadout.Witcher3ModsPolish) + Witcher3ModsSnapshot.Witcher3ModsBlockReason;

        Witcher3ModsBody = Witcher3ModsFormatSection(Witcher3ModsText("ui_description", Witcher3ModsReadout.Witcher3ModsPolish), Witcher3ModsDefinition.Witcher3ModsDescriptionText);
        // Optional hints: a description_<achievement key>_hints entry. Witcher3ModsText returns the key itself when there is none.
        Witcher3ModsHintsKey = "description_" + NameToString(Witcher3ModsDefinition.Witcher3ModsAchievementKey) + "_hints";
        Witcher3ModsHints = Witcher3ModsText(Witcher3ModsHintsKey, Witcher3ModsReadout.Witcher3ModsPolish);
        if (Witcher3ModsHints != Witcher3ModsHintsKey)
            Witcher3ModsBody += "<br><br>" + Witcher3ModsFormatSection(Witcher3ModsText("ui_hints", Witcher3ModsReadout.Witcher3ModsPolish), Witcher3ModsHints);
        Witcher3ModsBody += "<br><br>" + Witcher3ModsFormatSection(Witcher3ModsText("ui_progress", Witcher3ModsReadout.Witcher3ModsPolish), Witcher3ModsFormatProgress(Witcher3ModsDefinition, Witcher3ModsSnapshot));
        Witcher3ModsBody += "<br><br>" + Witcher3ModsFormatSection(Witcher3ModsText("ui_availability", Witcher3ModsReadout.Witcher3ModsPolish), Witcher3ModsAvailability);
        Witcher3ModsCounterKey = Witcher3ModsDefinition.Witcher3ModsCounterFactKey;
        if (Witcher3ModsCounterKey == "") Witcher3ModsCounterKey = "—";
        return Witcher3ModsBody + Witcher3ModsText("ui_achievement_key", Witcher3ModsReadout.Witcher3ModsPolish)
            + NameToString(Witcher3ModsDefinition.Witcher3ModsAchievementKey)
            + Witcher3ModsText("ui_counter_key", Witcher3ModsReadout.Witcher3ModsPolish) + Witcher3ModsCounterKey + "</font>";
    }

    function Witcher3ModsBuildHeaderSubtitle(Witcher3ModsIndex : int) : string
    {
        var Witcher3ModsGroup : int;
        Witcher3ModsGroup = Witcher3ModsReadout.Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions[Witcher3ModsIndex].Witcher3ModsExpansionGroup;
        if (Witcher3ModsGroup == 1) return Witcher3ModsText("ui_hos", Witcher3ModsReadout.Witcher3ModsPolish);
        if (Witcher3ModsGroup == 2) return Witcher3ModsText("ui_baw", Witcher3ModsReadout.Witcher3ModsPolish);
        return Witcher3ModsText("ui_base_game", Witcher3ModsReadout.Witcher3ModsPolish);
    }

    function Witcher3ModsBuildSummaryObjective(Witcher3ModsSection : int) : string
    {
        var Witcher3ModsIndex, Witcher3ModsEarned, Witcher3ModsBlocked, Witcher3ModsTotal : int;
        if (!Witcher3ModsReadout.Witcher3ModsStatusReady)
            return Witcher3ModsText("ui_read_error", Witcher3ModsReadout.Witcher3ModsPolish);
        if (Witcher3ModsSection == 0)
        {
            if (Witcher3ModsReadout.Witcher3ModsAchievementsDisabled) return Witcher3ModsText("ui_disabled", Witcher3ModsReadout.Witcher3ModsPolish);
            return Witcher3ModsText("ui_enabled", Witcher3ModsReadout.Witcher3ModsPolish);
        }
        if (Witcher3ModsSection == 2)
            return Witcher3ModsText("ui_current", Witcher3ModsReadout.Witcher3ModsPolish) + Witcher3ModsReadout.Witcher3ModsCurrentDifficulty
                + Witcher3ModsText("ui_lowest", Witcher3ModsReadout.Witcher3ModsPolish) + Witcher3ModsReadout.Witcher3ModsLowestDifficulty;
        Witcher3ModsEarned = 0;
        Witcher3ModsBlocked = 0;
        Witcher3ModsTotal = Witcher3ModsReadout.Witcher3ModsSnapshots.Size();
        for (Witcher3ModsIndex = 0; Witcher3ModsIndex < Witcher3ModsTotal; Witcher3ModsIndex += 1)
        {
            if (Witcher3ModsReadout.Witcher3ModsSnapshots[Witcher3ModsIndex].Witcher3ModsState == Witcher3ModsAchievementEarned) Witcher3ModsEarned += 1;
            if (Witcher3ModsReadout.Witcher3ModsSnapshots[Witcher3ModsIndex].Witcher3ModsState == Witcher3ModsAchievementBlocked) Witcher3ModsBlocked += 1;
        }
        return Witcher3ModsText("ui_progress", Witcher3ModsReadout.Witcher3ModsPolish)
            + Witcher3ModsText("ui_earned_count", Witcher3ModsReadout.Witcher3ModsPolish) + Witcher3ModsEarned + " / " + Witcher3ModsTotal
            + Witcher3ModsText("ui_pending_count", Witcher3ModsReadout.Witcher3ModsPolish) + (Witcher3ModsTotal - Witcher3ModsEarned - Witcher3ModsBlocked)
            + Witcher3ModsText("ui_blocked_count", Witcher3ModsReadout.Witcher3ModsPolish) + Witcher3ModsBlocked;
    }

    function Witcher3ModsBuildAvailabilitySummary() : string
    {
        var Witcher3ModsIndex, Witcher3ModsEarned, Witcher3ModsBlocked, Witcher3ModsTotal : int;
        var Witcher3ModsSummary : string;
        if (!Witcher3ModsReadout.Witcher3ModsStatusReady)
            return Witcher3ModsText("ui_read_error", Witcher3ModsReadout.Witcher3ModsPolish) + Witcher3ModsText("ui_unofficial", Witcher3ModsReadout.Witcher3ModsPolish);
        Witcher3ModsEarned = 0;
        Witcher3ModsBlocked = 0;
        Witcher3ModsTotal = Witcher3ModsReadout.Witcher3ModsSnapshots.Size();
        for (Witcher3ModsIndex = 0; Witcher3ModsIndex < Witcher3ModsTotal; Witcher3ModsIndex += 1)
        {
            if (Witcher3ModsReadout.Witcher3ModsSnapshots[Witcher3ModsIndex].Witcher3ModsState == Witcher3ModsAchievementEarned) Witcher3ModsEarned += 1;
            if (Witcher3ModsReadout.Witcher3ModsSnapshots[Witcher3ModsIndex].Witcher3ModsState == Witcher3ModsAchievementBlocked) Witcher3ModsBlocked += 1;
        }
        Witcher3ModsSummary = Witcher3ModsText("ui_enabled", Witcher3ModsReadout.Witcher3ModsPolish);
        if (Witcher3ModsReadout.Witcher3ModsAchievementsDisabled)
            Witcher3ModsSummary = Witcher3ModsText("ui_disabled", Witcher3ModsReadout.Witcher3ModsPolish);
        Witcher3ModsSummary += Witcher3ModsText("ui_earned_count", Witcher3ModsReadout.Witcher3ModsPolish) + Witcher3ModsEarned + " / " + Witcher3ModsTotal
            + Witcher3ModsText("ui_pending_count", Witcher3ModsReadout.Witcher3ModsPolish) + (Witcher3ModsTotal - Witcher3ModsEarned - Witcher3ModsBlocked)
            + Witcher3ModsText("ui_blocked_count", Witcher3ModsReadout.Witcher3ModsPolish) + Witcher3ModsBlocked;
        Witcher3ModsSummary += "<br><br>" + Witcher3ModsFormatSection(Witcher3ModsText("ui_difficulty", Witcher3ModsReadout.Witcher3ModsPolish),
            Witcher3ModsText("ui_current", Witcher3ModsReadout.Witcher3ModsPolish) + Witcher3ModsReadout.Witcher3ModsCurrentDifficulty
            + Witcher3ModsText("ui_lowest", Witcher3ModsReadout.Witcher3ModsPolish) + Witcher3ModsReadout.Witcher3ModsLowestDifficulty);
        return Witcher3ModsSummary + Witcher3ModsText("ui_block_coverage", Witcher3ModsReadout.Witcher3ModsPolish) + Witcher3ModsText("ui_unofficial", Witcher3ModsReadout.Witcher3ModsPolish);
    }
}
