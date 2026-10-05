      // Separate instances of the native quest artwork, never real journal entries.
      private var Witcher3ModsContainers:Array = [];

      private function Witcher3ModsSetAchievements(Witcher3ModsData:Object, Witcher3ModsIndex:int):void
      {
         var Witcher3ModsRows:Array = Witcher3ModsData as Array;
         var Witcher3ModsCursor:int;
         var Witcher3ModsContainer:HudQuestContainer;
         var Witcher3ModsType:Class = Object(mcSystemQuestContainer).constructor as Class;
         if (!Witcher3ModsRows) Witcher3ModsRows = [];
         while (Witcher3ModsContainers.length > Witcher3ModsRows.length)
         {
            Witcher3ModsContainer = Witcher3ModsContainers.pop() as HudQuestContainer;
            removeChild(Witcher3ModsContainer);
         }
         for (Witcher3ModsCursor = 0; Witcher3ModsCursor < Witcher3ModsRows.length; Witcher3ModsCursor++)
         {
            if (Witcher3ModsCursor == Witcher3ModsContainers.length)
            {
               Witcher3ModsContainer = new Witcher3ModsType() as HudQuestContainer;
               addChild(Witcher3ModsContainer);
               Witcher3ModsContainer.validateNow();
               Witcher3ModsContainers.push(Witcher3ModsContainer);
            }
            Witcher3ModsContainer = Witcher3ModsContainers[Witcher3ModsCursor];
            Witcher3ModsContainer.x = mcSystemQuestContainer.x;
            Witcher3ModsContainer.onQuestNameSet(String(Witcher3ModsRows[Witcher3ModsCursor].title));
            Witcher3ModsContainer.onQuestNameColorSet(0xffcc00);
            Witcher3ModsContainer.onDifficultyUpdate(false);
            Witcher3ModsContainer.onObjectiveDataSet([{name:String(Witcher3ModsRows[Witcher3ModsCursor].description), isHighlighted:true, isMutuallyExclusive:false, isNew:false}], -1);
            Witcher3ModsContainer.alpha = 1;
         }
         // Layout only: no game queries, no updates to real objective data.
         removeEventListener(flash.events.Event.ENTER_FRAME, Witcher3ModsLayoutAchievements);
         if (Witcher3ModsRows.length > 0)
            addEventListener(flash.events.Event.ENTER_FRAME, Witcher3ModsLayoutAchievements, false, 0, true);
         Witcher3ModsLayoutAchievements(null);
         dispatchEvent(new GameEvent(GameEvent.UPDATE, moduleName));
      }

      private function Witcher3ModsContainerBottom(Witcher3ModsContainer:HudQuestContainer):Number
      {
         var Witcher3ModsList:Object = Witcher3ModsContainer.mcQuestObjectiveList;
         var Witcher3ModsBottom:Number = Witcher3ModsList.mcTitleLineSeparator.getBounds(this).bottom;
         var Witcher3ModsCursor:int;
         var Witcher3ModsRenderer:Object;
         for (Witcher3ModsCursor = 0; Witcher3ModsCursor < Witcher3ModsList.numRenderers; Witcher3ModsCursor++)
         {
            Witcher3ModsRenderer = Witcher3ModsList.getRendererAt(Witcher3ModsCursor);
            if (Witcher3ModsRenderer && Witcher3ModsRenderer.visible && Witcher3ModsRenderer.data)
               Witcher3ModsBottom = Math.max(Witcher3ModsBottom, Witcher3ModsRenderer.tfObjective.getBounds(this).bottom);
         }
         return Witcher3ModsBottom;
      }

      private function Witcher3ModsLayoutAchievements(Witcher3ModsEvent:flash.events.Event):void
      {
         var Witcher3ModsNextY:Number = mcSystemQuestContainer.y;
         var Witcher3ModsCursor:int;
         var Witcher3ModsContainer:HudQuestContainer;
         if (mcSystemQuestContainer.alpha > 0)
            Witcher3ModsNextY = Witcher3ModsContainerBottom(mcSystemQuestContainer) + 24;
         for (Witcher3ModsCursor = 0; Witcher3ModsCursor < Witcher3ModsContainers.length; Witcher3ModsCursor++)
         {
            Witcher3ModsContainer = Witcher3ModsContainers[Witcher3ModsCursor];
            Witcher3ModsContainer.y = Witcher3ModsNextY;
            Witcher3ModsNextY = Witcher3ModsContainerBottom(Witcher3ModsContainer) + 24;
         }
      }
