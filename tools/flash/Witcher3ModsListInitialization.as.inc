      private var Witcher3ModsListReady:Boolean = false;
      private var Witcher3ModsInitialRowsDelivered:Boolean = false;
      private var Witcher3ModsPendingRows:Array;
      private var Witcher3ModsInitialTimer:flash.utils.Timer;
      private function Witcher3ModsQueueInitialRows():void
      {
         if (!Witcher3ModsListReady || Witcher3ModsInitialTimer) return;
         // Invisible Scaleform clips do not advance ENTER_FRAME. A one-shot
         // timer runs after configUI without depending on the hidden timeline.
         Witcher3ModsInitialTimer = new flash.utils.Timer(1, 1);
         Witcher3ModsInitialTimer.addEventListener(flash.events.TimerEvent.TIMER, Witcher3ModsOnInitialTimer, false, 0, true);
         Witcher3ModsInitialTimer.start();
         addEventListener(Event.REMOVED_FROM_STAGE, Witcher3ModsCancelInitialRows, false, 0, true);
      }

      private function Witcher3ModsCancelInitialRows(Witcher3ModsEvent:Event):void
      {
         if (Witcher3ModsEvent.target != this) return;
         Witcher3ModsStopInitialTimer();
         Witcher3ModsPendingRows = null;
         removeEventListener(Event.REMOVED_FROM_STAGE, Witcher3ModsCancelInitialRows);
      }

      private function Witcher3ModsStopInitialTimer():void
      {
         if (!Witcher3ModsInitialTimer) return;
         Witcher3ModsInitialTimer.stop();
         Witcher3ModsInitialTimer.removeEventListener(flash.events.TimerEvent.TIMER, Witcher3ModsOnInitialTimer);
         Witcher3ModsInitialTimer = null;
      }

      private function Witcher3ModsOnInitialTimer(Witcher3ModsEvent:flash.events.TimerEvent):void
      {
         Witcher3ModsStopInitialTimer();
         Witcher3ModsFlushInitialRows();
      }

      override public function handleListData(Witcher3ModsData:Object, Witcher3ModsIndex:int):void
      {
         var Witcher3ModsRows:Array = Witcher3ModsData as Array;
         try
         {
         if (Witcher3ModsIndex < 0 && Witcher3ModsRows && Witcher3ModsRows.length &&
             (Witcher3ModsRows[0].Witcher3ModsAchievement || Witcher3ModsRows[0].Witcher3ModsSummary))
         {
            if (!Witcher3ModsInitialRowsDelivered || !Witcher3ModsListReady || !mcDropDownList || Witcher3ModsRows[0].Witcher3ModsOpeningFocus)
            {
               // Binding arrays can be reused by the producer before the timer.
               // Retain our own flat row snapshot, not the borrowed binding array.
               Witcher3ModsPendingRows = [];
               for (var Witcher3ModsRowIndex:int = 0; Witcher3ModsRowIndex < Witcher3ModsRows.length; Witcher3ModsRowIndex++)
               {
                  var Witcher3ModsSourceRow:Object = Witcher3ModsRows[Witcher3ModsRowIndex];
                  var Witcher3ModsCopy:Object = {};
                  for (var Witcher3ModsProperty:String in Witcher3ModsSourceRow)
                     Witcher3ModsCopy[Witcher3ModsProperty] = Witcher3ModsSourceRow[Witcher3ModsProperty];
                  Witcher3ModsPendingRows.push(Witcher3ModsCopy);
               }
               Witcher3ModsQueueInitialRows();
               return;
            }
         }
         super.handleListData(Witcher3ModsData, Witcher3ModsIndex);
         }
         catch (Witcher3ModsBindingError:Error)
         {
            throw Witcher3ModsBindingError;
         }
      }

      private function Witcher3ModsFlushInitialRows():void
      {
         Witcher3ModsStopInitialTimer();
         removeEventListener(Event.REMOVED_FROM_STAGE, Witcher3ModsCancelInitialRows);
         if (!Witcher3ModsListReady || !mcDropDownList || !Witcher3ModsPendingRows) return;
         var Witcher3ModsRows:Array = Witcher3ModsPendingRows;
         Witcher3ModsPendingRows = null;
         Witcher3ModsInitialRowsDelivered = true;
         for each (var Witcher3ModsInitialRow:Object in Witcher3ModsRows) Witcher3ModsInitialRow.selected = false;
         try
         {
            super.handleListData(Witcher3ModsRows, -1);
         }
         catch (Witcher3ModsError:Error)
         {
            throw Witcher3ModsError;
         }
         mcDropDownList.validateNow();
         (mcDropDownList as QuestDropDownList).Witcher3ModsFocusFirstCategory();
         // Initial binding delivery can precede the root menu's selection listener.
         // Replay only the selected row to refresh both detail columns once ready.
         for each (var Witcher3ModsRow:Object in Witcher3ModsRows)
         {
            if (Witcher3ModsRow.Witcher3ModsSummary)
            {
               dispatchEvent(new red.core.events.GameEvent(red.core.events.GameEvent.CALL, "OnEntrySelected", [Witcher3ModsRow.tag]));
               break;
            }
         }
      }
