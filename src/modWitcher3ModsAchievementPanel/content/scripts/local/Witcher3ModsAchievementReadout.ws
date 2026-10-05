// Captures one coherent menu snapshot. Mutable state belongs to this object,
// never to the const engine global theGame. No achievement is granted here.
enum Witcher3ModsAchievementState
{
    Witcher3ModsAchievementEarned,
    Witcher3ModsAchievementPending,
    Witcher3ModsAchievementBlocked
}

struct Witcher3ModsAchievementSnapshot
{
    var Witcher3ModsEngine : bool;
    var Witcher3ModsProgress : int;
    var Witcher3ModsState : Witcher3ModsAchievementState;
    var Witcher3ModsBlockReason : string;
}

class Witcher3ModsAchievementReadout extends CObject
{
    var Witcher3ModsCatalog : Witcher3ModsAchievementCatalog;
    var Witcher3ModsQueries : Witcher3ModsGameQueries;
    var Witcher3ModsSnapshots : array<Witcher3ModsAchievementSnapshot>;
    var Witcher3ModsStatusReady, Witcher3ModsAchievementsDisabled : bool;
    var Witcher3ModsPolish : bool;
    var Witcher3ModsCurrentDifficulty, Witcher3ModsLowestDifficulty : string;

    function Witcher3ModsRefreshSnapshot()
    {
        var Witcher3ModsDefinition : Witcher3ModsAchievementDefinition;
        var Witcher3ModsSnapshot : Witcher3ModsAchievementSnapshot;
        var Witcher3ModsCursor : int;

        Witcher3ModsPolish = Witcher3ModsUsePolish();
        if (!Witcher3ModsCatalog)
        {
            Witcher3ModsCatalog = new Witcher3ModsAchievementCatalog in this;
            Witcher3ModsQueries = new Witcher3ModsGameQueries in this;
        }
        if (Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions.Size() == 0 || Witcher3ModsCatalog.Witcher3ModsPolish != Witcher3ModsPolish)
        {
            Witcher3ModsCatalog.Witcher3ModsPolish = Witcher3ModsPolish;
            Witcher3ModsCatalog.Witcher3ModsBuildCatalog();
        }
        Witcher3ModsQueries.Witcher3ModsPolish = Witcher3ModsPolish;
        Witcher3ModsSnapshots.Clear();
        Witcher3ModsAchievementsDisabled = theGame.GetAchievementsDisabled();
        Witcher3ModsCurrentDifficulty = Witcher3ModsQueries.Witcher3ModsDescribeDifficultyLevel(theGame.GetDifficultyLevel());
        Witcher3ModsLowestDifficulty = Witcher3ModsText("ui_no_reading", Witcher3ModsPolish);
        if (FactsDoesExist("lowest_difficulty_used"))
            Witcher3ModsLowestDifficulty = Witcher3ModsQueries.Witcher3ModsDescribeDifficultyLevel(theGame.GetLowestDifficultyUsed());
        for (Witcher3ModsCursor = 0; Witcher3ModsCursor < Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions.Size(); Witcher3ModsCursor += 1)
        {
            Witcher3ModsDefinition = Witcher3ModsCatalog.Witcher3ModsAchievementDefinitions[Witcher3ModsCursor];
            Witcher3ModsSnapshot.Witcher3ModsEngine = theGame.IsAchievementUnlocked(Witcher3ModsDefinition.Witcher3ModsAchievementKey);
            Witcher3ModsSnapshot.Witcher3ModsProgress = Witcher3ModsQueries.Witcher3ModsReadCounter(Witcher3ModsDefinition);
            Witcher3ModsSnapshot.Witcher3ModsBlockReason = Witcher3ModsQueries.Witcher3ModsReadBlockReason(Witcher3ModsDefinition, Witcher3ModsAchievementsDisabled);
            Witcher3ModsSnapshot.Witcher3ModsState = Witcher3ModsAchievementPending;
            Witcher3ModsSnapshots.PushBack(Witcher3ModsSnapshot);
        }
        // Use the EA_ keys passed by vanilla W3GamerProfile.AddAchievement.
        // Temporary user-approved interpretation for the observed Steam build:
        // raw false means earned. This is not a verified cross-platform reader.
        Witcher3ModsStatusReady = Witcher3ModsValidateStatusReadout();
        if (!Witcher3ModsStatusReady)
        {
            return;
        }
        for (Witcher3ModsCursor = 0; Witcher3ModsCursor < Witcher3ModsSnapshots.Size(); Witcher3ModsCursor += 1)
        {
            Witcher3ModsSnapshots[Witcher3ModsCursor].Witcher3ModsState = Witcher3ModsResolveAchievementState(Witcher3ModsSnapshots[Witcher3ModsCursor]);
        }
    }

    function Witcher3ModsResolveAchievementState(Witcher3ModsSnapshot : Witcher3ModsAchievementSnapshot) : Witcher3ModsAchievementState
    {
        if (!Witcher3ModsSnapshot.Witcher3ModsEngine) return Witcher3ModsAchievementEarned;
        if (Witcher3ModsSnapshot.Witcher3ModsBlockReason != "") return Witcher3ModsAchievementBlocked;
        return Witcher3ModsAchievementPending;
    }

    function Witcher3ModsValidateStatusReadout() : bool
    {
        var Witcher3ModsIndex, Witcher3ModsEarnedCount : int;

        Witcher3ModsEarnedCount = 0;
        for (Witcher3ModsIndex = 0; Witcher3ModsIndex < Witcher3ModsSnapshots.Size(); Witcher3ModsIndex += 1)
        {
            // Fixed temporary interpretation; no account reference or mode selection.
            if (!Witcher3ModsSnapshots[Witcher3ModsIndex].Witcher3ModsEngine) Witcher3ModsEarnedCount += 1;
        }
        // Neither native API exposes read success. Zero/all unlocked cannot yet be
        // distinguished from a constant failed response, so keep the panel error.
        return Witcher3ModsEarnedCount > 0 && Witcher3ModsEarnedCount < Witcher3ModsSnapshots.Size();
    }
}
