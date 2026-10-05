// Witcher3ModsAchivementPanel: catalogue data, no UI or account mutations.
struct Witcher3ModsAchievementDefinition
{
    var Witcher3ModsAchievementKey, Witcher3ModsSteamAchievementKey, Witcher3ModsShortAchievementKey : name;
    var Witcher3ModsAchievementTitle, Witcher3ModsDescriptionText, Witcher3ModsCounterFactKey : string;
    var Witcher3ModsRequiredProgress, Witcher3ModsExpansionGroup : int;
    var Witcher3ModsStatistic : EStatistic;
}

class Witcher3ModsAchievementCatalog extends CObject
{
    var Witcher3ModsPolish : bool;
    var Witcher3ModsAchievementDefinitions : array<Witcher3ModsAchievementDefinition>;

    function Witcher3ModsBuildCatalog()
    {
        Witcher3ModsAchievementDefinitions.Clear();
        Witcher3ModsBuildBaseGameCatalog();
        Witcher3ModsBuildHeartsOfStoneCatalog();
        Witcher3ModsBuildBloodAndWineCatalog();
        Witcher3ModsLoadConfiguredAchievementTargets();
    }

    function Witcher3ModsRegisterDefinition(
        Witcher3ModsAchievementKey : name, Witcher3ModsAchievementTitle : string,
        Witcher3ModsDescriptionText : string, Witcher3ModsExpansionGroup : int,
        Witcher3ModsSteamAchievementKey : name, Witcher3ModsShortAchievementKey : name,
        Witcher3ModsCounterFactKey : string,
        Witcher3ModsRequiredProgress : int, Witcher3ModsStatistic : EStatistic)
    {
        var Witcher3ModsDefinition : Witcher3ModsAchievementDefinition;
        Witcher3ModsDefinition.Witcher3ModsAchievementKey = Witcher3ModsAchievementKey;
        Witcher3ModsDefinition.Witcher3ModsAchievementTitle = Witcher3ModsText(Witcher3ModsAchievementTitle, Witcher3ModsPolish);
        Witcher3ModsDefinition.Witcher3ModsDescriptionText = Witcher3ModsText(Witcher3ModsDescriptionText, Witcher3ModsPolish);
        Witcher3ModsDefinition.Witcher3ModsExpansionGroup = Witcher3ModsExpansionGroup;
        Witcher3ModsDefinition.Witcher3ModsSteamAchievementKey = Witcher3ModsSteamAchievementKey;
        Witcher3ModsDefinition.Witcher3ModsShortAchievementKey = Witcher3ModsShortAchievementKey;
        Witcher3ModsDefinition.Witcher3ModsCounterFactKey = Witcher3ModsCounterFactKey;
        Witcher3ModsDefinition.Witcher3ModsRequiredProgress = Witcher3ModsRequiredProgress;
        Witcher3ModsDefinition.Witcher3ModsStatistic = Witcher3ModsStatistic;
        Witcher3ModsAchievementDefinitions.PushBack(Witcher3ModsDefinition);
    }

    function Witcher3ModsBuildBaseGameCatalog()
    {
        Witcher3ModsRegisterDefinition('EA_FreedDandelion', "title_EA_FreedDandelion", "description_EA_FreedDandelion", 0,
            'FRIEND_IN_NEED', 'FreedDandelion', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_Allin', "title_EA_Allin", "description_EA_Allin", 0,
            'ALL_IN', 'Allin', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_FullyArmed', "title_EA_FullyArmed", "description_EA_FullyArmed", 0,
            'ARMED_AND_DANGEROUS', 'FullyArmed', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_MonsterHuntDao', "title_EA_MonsterHuntDao", "description_EA_MonsterHuntDao", 0,
            'ASHES_TO_ASHES', 'MonsterHuntDao', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_CompleteWar', "title_EA_CompleteWar", "description_EA_CompleteWar", 0,
            'ASSASSIN', 'CompleteWar', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_Bombardier', "title_EA_Bombardier", "description_EA_Bombardier", 0,
            'BOMBARDIER', 'Bombardier', "statistic_known_bombs", 6, ES_KnownBombRecipes);
        Witcher3ModsRegisterDefinition('EA_Bookworm', "title_EA_Bookworm", "description_EA_Bookworm", 0,
            'BOOKWORM', 'Bookworm', "statistic_read_books", 30, ES_ReadBooks);
        Witcher3ModsRegisterDefinition('EA_BrawlMaster', "title_EA_BrawlMaster", "description_EA_BrawlMaster", 0,
            'BRAWL_MASTER', 'BrawlMaster', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_Brawler', "title_EA_Brawler", "description_EA_Brawler", 0,
            'BRAWLER', 'Brawler', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_Swank', "title_EA_Swank", "description_EA_Swank", 0,
            'BUTCHER_OF_BLAVIKEN', 'Swank', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_Finesse', "title_EA_Finesse", "description_EA_Finesse", 0,
            'CANT_TOUCH_THIS', 'Finesse', "statistic_finesse_kills", 5, ES_FinesseKills);
        Witcher3ModsRegisterDefinition('EA_GwintCollector', "title_EA_GwintCollector", "description_EA_GwintCollector", 0,
            'CARD_COLLECTOR', 'GwintCollector', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_Dendrology', "title_EA_Dendrology", "description_EA_Dendrology", 0,
            'DENDROLOGIST', 'Dendrology', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_EnvironmentUnfriendly', "title_EA_EnvironmentUnfriendly", "description_EA_EnvironmentUnfriendly", 0,
            'ENVIRONMENTALLY_UNFRIENDLY', 'EnvironmentUnfriendly', "statistic_environment_kills", 50, ES_EnvironmentKills);
        Witcher3ModsRegisterDefinition('EA_FundamentalsFirst', "title_EA_FundamentalsFirst", "description_EA_FundamentalsFirst", 0,
            'EVEN_ODDS', 'FundamentalsFirst', "statistic_fundamentals_kills", 2, ES_FundamentalsFirstKills);
        Witcher3ModsRegisterDefinition('EA_FindBaronsFamily', "title_EA_FindBaronsFamily", "description_EA_FindBaronsFamily", 0,
            'FAMILY_COUNSELOR', 'FindBaronsFamily', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_NeedForSpeed', "title_EA_NeedForSpeed", "description_EA_NeedForSpeed", 0,
            'FAST_AND_FURIOUS', 'NeedForSpeed', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_MonsterHuntEkimma', "title_EA_MonsterHuntEkimma", "description_EA_MonsterHuntEkimma", 0,
            'FEARLESS_VAMPIRE_SLAYER', 'MonsterHuntEkimma', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_MonsterHuntFiend', "title_EA_MonsterHuntFiend", "description_EA_MonsterHuntFiend", 0,
            'FIEND_OR_FOE', 'MonsterHuntFiend', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_FireInTheHole', "title_EA_FireInTheHole", "description_EA_FireInTheHole", 0,
            'FIRE_IN_THE_HOLE', 'FireInTheHole', "statistic_destroyed_nests", 10, ES_DestroyedNests);
        Witcher3ModsRegisterDefinition('EA_FistOfTheSouthStar', "title_EA_FistOfTheSouthStar", "description_EA_FistOfTheSouthStar", 0,
            'FIST_OF_THE_SOUTH_STAR', 'FistOfTheSouthStar', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_CompleteKeiraMetz', "title_EA_CompleteKeiraMetz", "description_EA_CompleteKeiraMetz", 0,
            'FRIENDS_WITH_BENEFITS', 'CompleteKeiraMetz', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_GetAllForKaerMorhenBattle', "title_EA_GetAllForKaerMorhenBattle", "description_EA_GetAllForKaerMorhenBattle", 0,
            'FULL_CREW', 'GetAllForKaerMorhenBattle', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_GeraltandFriends', "title_EA_GeraltandFriends", "description_EA_GeraltandFriends", 0,
            'GERALT_AND_FRIENDS', 'GeraltandFriends', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_CompleteWitcherContracts', "title_EA_CompleteWitcherContracts", "description_EA_CompleteWitcherContracts", 0,
            'THE_PROFESSIONAL', 'CompleteWitcherContracts', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_Explorer', "title_EA_Explorer", "description_EA_Explorer", 0,
            'GLOBETROTTER', 'Explorer', "", 100, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_GwintMaster', "title_EA_GwintMaster", "description_EA_GwintMaster", 0,
            'GWENT_MASTER', 'GwintMaster', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_FusSthSth', "title_EA_FusSthSth", "description_EA_FusSthSth", 0,
            'HUMPTY_DUMPTY', 'FusSthSth', "statistic_aardfall_kills", 10, ES_AardFallKills);
        Witcher3ModsRegisterDefinition('EA_TrainedInKaerMorhen', "title_EA_TrainedInKaerMorhen", "description_EA_TrainedInKaerMorhen", 0,
            'KAER_MORHEN_TRAINED', 'TrainedInKaerMorhen', "statistic_counterattack_chain", 10, ES_CounterattackChain);
        Witcher3ModsRegisterDefinition('EA_CompleteSkelligeRaceForCrown', "title_EA_CompleteSkelligeRaceForCrown", "description_EA_CompleteSkelligeRaceForCrown", 0,
            'MAKER', 'CompleteSkelligeRaceForCrown', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_BreakingBad', "title_EA_BreakingBad", "description_EA_BreakingBad", 0,
            'LETS_COOK', 'BreakingBad', "statistic_known_potions", 12, ES_KnownPotionRecipes);
        Witcher3ModsRegisterDefinition('EA_FoundYennefer', "title_EA_FoundYennefer", "description_EA_FoundYennefer", 0,
            'LILAC', 'FoundYennefer', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_TechnoProgress', "title_EA_TechnoProgress", "description_EA_TechnoProgress", 0,
            'MASTER_MARKSMAN', 'TechnoProgress', "statistic_head_shot_kills", 50, ES_HeadShotKills);
        Witcher3ModsRegisterDefinition('EA_Immortal', "title_EA_Immortal", "description_EA_Immortal", 0,
            'MUNCHKIN', 'Immortal', "", 35, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_TrialOfGrasses', "title_EA_TrialOfGrasses", "description_EA_TrialOfGrasses", 0,
            'MUTANT', 'TrialOfGrasses', "", 4, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_YenGetInfoAboutCiri', "title_EA_YenGetInfoAboutCiri", "description_EA_YenGetInfoAboutCiri", 0,
            'NECROMANCER', 'YenGetInfoAboutCiri', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_Rage', "title_EA_Rage", "description_EA_Rage", 0,
            'OVERKILL', 'Rage', "statistic_bleed_burn_poison", 10, ES_BleedingBurnedPoisoned);
        Witcher3ModsRegisterDefinition('EA_FinishTheGameEasy', "title_EA_FinishTheGameEasy", "description_EA_FinishTheGameEasy", 0,
            'PASSED_THE_TRIAL', 'FinishTheGameEasy', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_PestControl', "title_EA_PestControl", "description_EA_PestControl", 0,
            'PEST_CONTROL', 'PestControl', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_PowerOverwhelming', "title_EA_PowerOverwhelming", "description_EA_PowerOverwhelming", 0,
            'POWER_OVERWHELMING', 'PowerOverwhelming', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_FinishTheGameNormal', "title_EA_FinishTheGameNormal", "description_EA_FinishTheGameNormal", 0,
            'RAN_THE_GAUNTLET', 'FinishTheGameNormal', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_MonsterHuntFogling', "title_EA_MonsterHuntFogling", "description_EA_MonsterHuntFogling", 0,
            'SHRIEKER', 'MonsterHuntFogling', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_FindCiri', "title_EA_FindCiri", "description_EA_FindCiri", 0,
            'SOMETHING_MORE', 'FindCiri', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_TheEvilestThing', "title_EA_TheEvilestThing", "description_EA_TheEvilestThing", 0,
            'THE_EVILEST_THING', 'TheEvilestThing', "statistic_burning_gas_triggers", 10, ES_DragonsDreamTriggers);
        Witcher3ModsRegisterDefinition('EA_MonsterHuntDoppler', "title_EA_MonsterHuntDoppler", "description_EA_MonsterHuntDoppler", 0,
            'THE_DOPPLER_EFFECT', 'MonsterHuntDoppler', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_EnemyOfMyFriend', "title_EA_EnemyOfMyFriend", "description_EA_EnemyOfMyFriend", 0,
            'ENEMY_OF_MY_ENEMY', 'EnemyOfMyFriend', "statistic_charmed_kills", 20, ES_CharmedNPCKills);
        Witcher3ModsRegisterDefinition('EA_DefeatEredin', "title_EA_DefeatEredin", "description_EA_DefeatEredin", 0,
            'THE_KING', 'DefeatEredin', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_Cerberus', "title_EA_Cerberus", "description_EA_Cerberus", 0,
            'TRIPLE_THREAT', 'Cerberus', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_FinishTheGameHard', "title_EA_FinishTheGameHard", "description_EA_FinishTheGameHard", 0,
            'WALKED_THE_PATH', 'FinishTheGameHard', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_LearningTheRopes', "title_EA_LearningTheRopes", "description_EA_LearningTheRopes", 0,
            'WHAT_WAS_THAT', 'LearningTheRopes', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_MonsterHuntLamia', "title_EA_MonsterHuntLamia", "description_EA_MonsterHuntLamia", 0,
            'WOODLAND_SPIRIT', 'MonsterHuntLamia', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_ConvinceGeelsToBetrayEredin', "title_EA_ConvinceGeelsToBetrayEredin", "description_EA_ConvinceGeelsToBetrayEredin", 0,
            'XENONAUT', 'ConvinceGeelsToBetrayEredin', "", 0, ES_Undefined);
    }

    function Witcher3ModsBuildHeartsOfStoneCatalog()
    {
        Witcher3ModsRegisterDefinition('EA_Thirst', "title_EA_Thirst", "description_EA_Thirst", 1,
            'EP1_8', 'Thirst', "statistic_active_potions", 7, ES_ActivePotions);
        Witcher3ModsRegisterDefinition('EA_TheCompletePicture', "title_EA_TheCompletePicture", "description_EA_TheCompletePicture", 1,
            'EP1_4', 'TheCompletePicture', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_LatestFashion', "title_EA_LatestFashion", "description_EA_LatestFashion", 1,
            'EP1_10', 'LatestFashion', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_ToadPrince', "title_EA_ToadPrince", "description_EA_ToadPrince", 1,
            'EP1_1', 'ToadPrince', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_KilledIt', "title_EA_KilledIt", "description_EA_KilledIt", 1,
            'EP1_13', 'KilledIt', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_PartyAnimal', "title_EA_PartyAnimal", "description_EA_PartyAnimal", 1,
            'EP1_2', 'PartyAnimal', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_WantedDeadOrBovine', "title_EA_WantedDeadOrBovine", "description_EA_WantedDeadOrBovine", 1,
            'EP1_11', 'WantedDeadOrBovine', "statistic_killed_cows", 20, ES_KilledCows);
        Witcher3ModsRegisterDefinition('EA_HeartsOfStone', "title_EA_HeartsOfStone", "description_EA_HeartsOfStone", 1,
            'EP1_5', 'HeartsOfStone', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_Slide', "title_EA_Slide", "description_EA_Slide", 1,
            'EP1_12', 'Slide', "statistic_slide_time", 10, ES_SlideTime);
        Witcher3ModsRegisterDefinition('EA_FeatherStrongerThanSword', "title_EA_FeatherStrongerThanSword", "description_EA_FeatherStrongerThanSword", 1,
            'EP1_7', 'FeatherStrongerThanSword', "statistic_self_arrow_kills", 3, ES_SelfArrowKills);
        Witcher3ModsRegisterDefinition('EA_Auctioneer', "title_EA_Auctioneer", "description_EA_Auctioneer", 1,
            'EP1_3', 'Auctioneer', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_KillEtherals', "title_EA_KillEtherals", "description_EA_KillEtherals", 1,
            'EP1_6', 'KillEtherals', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_DivineWhip', "title_EA_DivineWhip", "description_EA_DivineWhip", 1,
            'EP1_9', 'DivineWhip', "", 0, ES_Undefined);
    }

    function Witcher3ModsBuildBloodAndWineCatalog()
    {
        Witcher3ModsRegisterDefinition('EA_ChampionOfBeauclair', "title_EA_ChampionOfBeauclair", "description_EA_ChampionOfBeauclair", 2,
            'EP2_4', 'ChampionOfBeauclair', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_Goliath', "title_EA_Goliath", "description_EA_Goliath", 2,
            'EP2_13', 'Goliath', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_ReadyToRoll', "title_EA_ReadyToRoll", "description_EA_ReadyToRoll", 2,
            'EP2_10', 'ReadyToRoll', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_LikeAVirgin', "title_EA_LikeAVirgin", "description_EA_LikeAVirgin", 2,
            'EP2_5', 'LikeAVirgin', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_HastaLaVista', "title_EA_HastaLaVista", "description_EA_HastaLaVista", 2,
            'EP2_12', 'HastaLaVista', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_GotToHaveThemAll', "title_EA_GotToHaveThemAll", "description_EA_GotToHaveThemAll", 2,
            'EP2_8', 'GotToHaveThemAll', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_BeauclairMostWanted', "title_EA_BeauclairMostWanted", "description_EA_BeauclairMostWanted", 2,
            'EP2_3', 'BeauclairMostWanted', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_HeroOfBeauclair', "title_EA_HeroOfBeauclair", "description_EA_HeroOfBeauclair", 2,
            'EP2_2', 'HeroOfBeauclair', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_HomeSweetHome', "title_EA_HomeSweetHome", "description_EA_HomeSweetHome", 2,
            'EP2_6', 'HomeSweetHome', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_BloodAndWine', "title_EA_BloodAndWine", "description_EA_BloodAndWine", 2,
            'EP2_9', 'BloodAndWine', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_BeauclairWelcomeTo', "title_EA_BeauclairWelcomeTo", "description_EA_BeauclairWelcomeTo", 2,
            'EP2_1', 'BeauclairWelcomeTo', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_TurnedEveryStone', "title_EA_TurnedEveryStone", "description_EA_TurnedEveryStone", 2,
            'EP2_7', 'TurnedEveryStone', "", 0, ES_Undefined);
        Witcher3ModsRegisterDefinition('EA_SchoolOfTheMutant', "title_EA_SchoolOfTheMutant", "description_EA_SchoolOfTheMutant", 2,
            'EP2_11', 'SchoolOfTheMutant', "", 0, ES_Undefined);
    }

    function Witcher3ModsLoadConfiguredAchievementTargets()
    {
        var Witcher3ModsDefinitionsManager : CDefinitionsManagerAccessor;
        var Witcher3ModsAchievementConfiguration : SCustomNode;
        var Witcher3ModsConfiguredAchievementName, Witcher3ModsConfiguredAchievementKey : name;
        var Witcher3ModsAchievementCursor, Witcher3ModsDefinitionCursor, Witcher3ModsConfiguredTarget : int;
        Witcher3ModsDefinitionsManager = theGame.GetDefinitionsManager();
        Witcher3ModsAchievementConfiguration = Witcher3ModsDefinitionsManager.GetCustomDefinition('achievements');
        for (Witcher3ModsAchievementCursor = 0; Witcher3ModsAchievementCursor < Witcher3ModsAchievementConfiguration.subNodes.Size(); Witcher3ModsAchievementCursor += 1)
        {
            if (Witcher3ModsDefinitionsManager.GetCustomNodeAttributeValueName(Witcher3ModsAchievementConfiguration.subNodes[Witcher3ModsAchievementCursor], 'name_name', Witcher3ModsConfiguredAchievementName))
            {
                Witcher3ModsConfiguredAchievementKey = AchievementEnumToName(AchievementNameToEnum(Witcher3ModsConfiguredAchievementName));
                if (Witcher3ModsDefinitionsManager.GetCustomNodeAttributeValueInt(Witcher3ModsAchievementConfiguration.subNodes[Witcher3ModsAchievementCursor], 'requiredValue', Witcher3ModsConfiguredTarget) && Witcher3ModsConfiguredTarget > 0)
                {
                    for (Witcher3ModsDefinitionCursor = 0; Witcher3ModsDefinitionCursor < Witcher3ModsAchievementDefinitions.Size(); Witcher3ModsDefinitionCursor += 1)
                    {
                        // Only registered statistics consume this XML threshold in CheckProgress.
                        // Mutagen slots (4), level (35), and travel points (100) use script conditions.
                        if (Witcher3ModsAchievementDefinitions[Witcher3ModsDefinitionCursor].Witcher3ModsAchievementKey == Witcher3ModsConfiguredAchievementKey && Witcher3ModsAchievementDefinitions[Witcher3ModsDefinitionCursor].Witcher3ModsStatistic != ES_Undefined)
                            Witcher3ModsAchievementDefinitions[Witcher3ModsDefinitionCursor].Witcher3ModsRequiredProgress = Witcher3ModsConfiguredTarget;
                    }
                }
            }
        }
    }

    function Witcher3ModsFindAchievementIndex(Witcher3ModsAchievementKey : name) : int
    {
        var Witcher3ModsAchievementCursor : int;
        for (Witcher3ModsAchievementCursor = 0; Witcher3ModsAchievementCursor < Witcher3ModsAchievementDefinitions.Size(); Witcher3ModsAchievementCursor += 1)
            if (Witcher3ModsAchievementDefinitions[Witcher3ModsAchievementCursor].Witcher3ModsAchievementKey == Witcher3ModsAchievementKey) return Witcher3ModsAchievementCursor;
        return -1;
    }
}
