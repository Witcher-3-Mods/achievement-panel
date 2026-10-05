      public var Witcher3ModsAchievementsActive:Boolean = false;
      public var Witcher3ModsNativeListFrame:flash.display.MovieClip;
      public var Witcher3ModsList:red.game.witcher3.menus.journal.QuestListModule;
      public var Witcher3ModsObjectives:red.game.witcher3.menus.journal.QuestSubListModule;
      public var Witcher3ModsDetails:red.game.witcher3.menus.common.Witcher3ModsTextAreaModuleCustomInput;

      // Called through the already registered tutorial movie, only for AP context.
      public function Witcher3ModsEnableAchievements():void
      {
         if (Witcher3ModsAchievementsActive) return;
         Witcher3ModsAchievementsActive = true;
         mcMainListModule.active = false;
         mcGlossarySubModule.active = false;
         mcTextAreaModule.active = false;
         mcMainListModule.visible = mcMainListModule.enabled = false;
         mcGlossarySubModule.visible = mcGlossarySubModule.enabled = false;
         mcTextAreaModule.visible = mcTextAreaModule.enabled = false;
         mcVideoObject.visible = false;

         Witcher3ModsList = new Witcher3ModsMC_MODULE_QuestList();
         Witcher3ModsObjectives = new Witcher3ModsMC_MODULE_ObjectiveList();
         Witcher3ModsDetails = new Witcher3ModsMC_MODULE_TextAreaLegend();
         Witcher3ModsList.name = "Witcher3ModsList";
         Witcher3ModsObjectives.name = "Witcher3ModsObjectives";
         Witcher3ModsDetails.name = "Witcher3ModsDetails";
         Witcher3ModsList.menuName = menuName;
         Witcher3ModsList.DataBindingKey = "Witcher3Mods.achievement.list";
         Witcher3ModsList.dataBindingKey = "Witcher3Mods.achievement.list";
         // Native journal document normally supplies these inspector settings.
         Witcher3ModsList.DropDownItemRendererClass = "Witcher3ModsQuestDropDownListItem";
         Witcher3ModsList.DropDownListClass = "Witcher3ModsDropDownList";
         Witcher3ModsList.ItemListClass = "Witcher3ModsW3ScrollingListNoBG";
         Witcher3ModsList.ItemRendererClass = "Witcher3ModsQuestListItem";
         Witcher3ModsList.enableInitCallback = false;
         Witcher3ModsObjectives.dataBindingKey = "Witcher3Mods.achievement.objectives";
         Witcher3ModsDetails.dataBindingKey = "Witcher3Mods.achievement.description";
         Witcher3ModsList.x = 28.8;
         Witcher3ModsList.y = 144.6;
         Witcher3ModsObjectives.x = 720.35;
         Witcher3ModsObjectives.y = 136;
         Witcher3ModsDetails.x = 1322.55;
         Witcher3ModsDetails.y = 215.45;

         addChild(Witcher3ModsList);
         addChild(Witcher3ModsObjectives);
         addChild(Witcher3ModsDetails);
         initModuleDynamically(Witcher3ModsList);
         initModuleDynamically(Witcher3ModsObjectives);
         initModuleDynamically(Witcher3ModsDetails);
         Witcher3ModsList.active = true;
         Witcher3ModsObjectives.active = true;
         Witcher3ModsDetails.active = true;
         Witcher3ModsList.addEventListener(ListEvent.INDEX_CHANGE, Witcher3ModsSelectionChanged, false, 0, true);
         Witcher3ModsList.validateNow();
         Witcher3ModsObjectives.validateNow();
         Witcher3ModsDetails.validateNow();
         // Root tutorial artwork starts at 220; journal content/frame start at
         // 164.6/160.25. Move only AP's left border, preserving ordinary tutorials.
         Witcher3ModsNativeListFrame.y = 160.25 - 220;
         // setMask() only stores/sizes mcMask. Dynamically added children do not
         // inherit the module timeline's clip-depth range: bind the actual mask.
         Witcher3ModsList.mcDropDownList.mask = Witcher3ModsList.mcDropDownMask;
         Witcher3ModsList.enableTouch(true);
         Witcher3ModsList.selectModuleOnClick = true;
         Witcher3ModsDetails.enableTouch(true);
      }

      private function Witcher3ModsSelectionChanged(Witcher3ModsEvent:scaleform.clik.events.ListEvent):void
      {
         var Witcher3ModsRow:Object = Witcher3ModsEvent.itemData;
         if (!Witcher3ModsRow || (!Witcher3ModsRow.Witcher3ModsAchievement && !Witcher3ModsRow.Witcher3ModsSummary)) return;
         Witcher3ModsDetails.SetTitle(Witcher3ModsRow.label);
         Witcher3ModsDetails.SetText(Witcher3ModsRow.description);
         Witcher3ModsDetails.setDifficulty(Witcher3ModsRow.reqdifficulty);
         Witcher3ModsDetails.setLocation(Witcher3ModsRow.secondLabel);
         Witcher3ModsDetails.setHeaderColor(Witcher3ModsRow.isStory);
         Witcher3ModsDetails.setCrest(Witcher3ModsRow.questArea);
         Witcher3ModsDetails.ShowSkullIcon(false);
      }
