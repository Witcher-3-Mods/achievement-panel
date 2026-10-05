// Read-only boundary to installed game APIs. No menu or persistence logic.
function Witcher3ModsIsPolishTextLanguage(Witcher3ModsTextLanguage : string) : bool
{
    return Witcher3ModsTextLanguage == "PL" || Witcher3ModsTextLanguage == "pl";
}

function Witcher3ModsUsePolish() : bool
{
    var Witcher3ModsAudioLanguage, Witcher3ModsTextLanguage : string;
    theGame.GetGameLanguageName(Witcher3ModsAudioLanguage, Witcher3ModsTextLanguage);
    return Witcher3ModsIsPolishTextLanguage(Witcher3ModsTextLanguage);
}

class Witcher3ModsGameQueries extends CObject
{
    var Witcher3ModsPolish : bool;

    function Witcher3ModsReadCounter(Witcher3ModsDefinition : Witcher3ModsAchievementDefinition) : int
    {
        var Witcher3ModsPlayer : W3PlayerWitcher;
        var Witcher3ModsTravelPoints : array<SAvailableFastTravelMapPin>;
        var Witcher3ModsMutagenCount : int;

        if (Witcher3ModsDefinition.Witcher3ModsStatistic != ES_Undefined)
            return theGame.GetGamerProfile().GetStatValue(Witcher3ModsDefinition.Witcher3ModsStatistic);

        if (Witcher3ModsDefinition.Witcher3ModsAchievementKey == 'EA_Explorer')
        {
            Witcher3ModsTravelPoints = theGame.GetCommonMapManager().GetFastTravelPoints(true, false, false, true, true);
            return Witcher3ModsTravelPoints.Size();
        }

        Witcher3ModsPlayer = GetWitcherPlayer();
        if (!Witcher3ModsPlayer) return -1;
        if (Witcher3ModsDefinition.Witcher3ModsAchievementKey == 'EA_Immortal')
            return Witcher3ModsPlayer.GetLevel();
        if (Witcher3ModsDefinition.Witcher3ModsAchievementKey == 'EA_TrialOfGrasses')
        {
            Witcher3ModsMutagenCount = 0;
            if (Witcher3ModsPlayer.IsAnyItemEquippedOnSlot(EES_SkillMutagen1)) Witcher3ModsMutagenCount += 1;
            if (Witcher3ModsPlayer.IsAnyItemEquippedOnSlot(EES_SkillMutagen2)) Witcher3ModsMutagenCount += 1;
            if (Witcher3ModsPlayer.IsAnyItemEquippedOnSlot(EES_SkillMutagen3)) Witcher3ModsMutagenCount += 1;
            if (Witcher3ModsPlayer.IsAnyItemEquippedOnSlot(EES_SkillMutagen4)) Witcher3ModsMutagenCount += 1;
            return Witcher3ModsMutagenCount;
        }
        return -1;
    }

    function Witcher3ModsReadBlockReason(Witcher3ModsDefinition : Witcher3ModsAchievementDefinition, Witcher3ModsGloballyDisabled : bool) : string
    {
        var Witcher3ModsReasons : string;
        Witcher3ModsReasons = "";
        if (Witcher3ModsGloballyDisabled)
            Witcher3ModsReasons = Witcher3ModsText("ui_disabled_reason", Witcher3ModsPolish);
        if ((Witcher3ModsDefinition.Witcher3ModsExpansionGroup == 1 && !theGame.GetDLCManager().IsDLCEnabled('ep1'))
            || (Witcher3ModsDefinition.Witcher3ModsExpansionGroup == 2 && !theGame.GetDLCManager().IsDLCEnabled('abob_001_001')))
        {
            if (Witcher3ModsReasons != "") Witcher3ModsReasons += "<br>";
            Witcher3ModsReasons += Witcher3ModsText("ui_dlc_reason", Witcher3ModsPolish);
        }
        if (Witcher3ModsCheckDifficultyRestriction(Witcher3ModsDefinition.Witcher3ModsAchievementKey) == 1)
        {
            if (Witcher3ModsReasons != "") Witcher3ModsReasons += "<br>";
            Witcher3ModsReasons += Witcher3ModsText("ui_difficulty_reason", Witcher3ModsPolish);
        }
        return Witcher3ModsReasons;
    }

    function Witcher3ModsCheckDifficultyRestriction(Witcher3ModsAchievementKey : name) : int
    {
        var Witcher3ModsLowestDifficultyUsed : EDifficultyMode;
        if (Witcher3ModsAchievementKey != 'EA_FinishTheGameNormal' && Witcher3ModsAchievementKey != 'EA_FinishTheGameHard') return 0;
        if (!FactsDoesExist("lowest_difficulty_used")) return -1;
        Witcher3ModsLowestDifficultyUsed = theGame.GetLowestDifficultyUsed();
        if (Witcher3ModsLowestDifficultyUsed < EDM_Easy || Witcher3ModsLowestDifficultyUsed > EDM_Hardcore) return -1;
        if (Witcher3ModsAchievementKey == 'EA_FinishTheGameNormal' && Witcher3ModsLowestDifficultyUsed < EDM_Hard) return 1;
        if (Witcher3ModsAchievementKey == 'EA_FinishTheGameHard' && Witcher3ModsLowestDifficultyUsed < EDM_Hardcore) return 1;
        return 0;
    }

    function Witcher3ModsDescribeDifficultyLevel(Witcher3ModsNumericValue : int) : string
    {
        if (Witcher3ModsNumericValue == EDM_Easy) return Witcher3ModsText("ui_easy", Witcher3ModsPolish);
        if (Witcher3ModsNumericValue == EDM_Medium) return Witcher3ModsText("ui_medium", Witcher3ModsPolish);
        if (Witcher3ModsNumericValue == EDM_Hard) return Witcher3ModsText("ui_hard", Witcher3ModsPolish);
        if (Witcher3ModsNumericValue == EDM_Hardcore) return Witcher3ModsText("ui_hardcore", Witcher3ModsPolish);
        return Witcher3ModsText("ui_unknown_reading", Witcher3ModsPolish);
    }
}
