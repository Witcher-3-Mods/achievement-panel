      public var Witcher3ModsRebuilding:Boolean = false;
      private var Witcher3ModsModList:Boolean = false;

      override public function updateData(Witcher3ModsData:Array):void
      {
         Witcher3ModsModList = Boolean(Witcher3ModsData && Witcher3ModsData.length &&
            (Witcher3ModsData[0].Witcher3ModsAchievement || Witcher3ModsData[0].Witcher3ModsSummary));
         var Witcher3ModsSurgical:Boolean = updateSurgicallyOnDataSet;
         if (Witcher3ModsModList) updateSurgicallyOnDataSet = false;
         Witcher3ModsRebuilding = Witcher3ModsModList;
         super.updateData(Witcher3ModsData);
         Witcher3ModsRebuilding = false;
         updateSurgicallyOnDataSet = Witcher3ModsSurgical;
         if (Witcher3ModsModList)
         {
            updatePosition(null);
            if (dataProvider && dataProvider.length > 0)
            {
               ShowRenderers(true);
               UpdateEmptyStateFeedback(false);
            }
         }
      }

      override public function restoreSelectionState():void
      {
         if (Witcher3ModsModList) Witcher3ModsRestoreCategoryState();
         else super.restoreSelectionState();
      }

      override public function saveSelectionState():void
      {
         // Mod restoration uses row tags/preferences. Native saving disables
         // smooth scrolling until its own async restore callback, which we skip.
         if (!Witcher3ModsModList) super.saveSelectionState();
      }

      public function Witcher3ModsRestoreCategoryState():void
      {
         var Witcher3ModsFound:Boolean = false;
         for (var Witcher3ModsIndex:int = 0; Witcher3ModsIndex < dataProvider.length; Witcher3ModsIndex++)
         {
            var Witcher3ModsCategory:red.game.witcher3.controls.W3DropdownMenuListItem = getRendererAt(Witcher3ModsIndex) as red.game.witcher3.controls.W3DropdownMenuListItem;
            if (!Witcher3ModsCategory) continue;
            if (Witcher3ModsCategory.IsOpenedByDefault()) Witcher3ModsCategory.open(false);
            var Witcher3ModsRows:Array = Witcher3ModsCategory.getDropDownData();
            var Witcher3ModsVisibleIndex:int = 0;
            for each (var Witcher3ModsRow:Object in Witcher3ModsRows)
            {
               if (!Witcher3ModsRow.dropDownOpened && !(Witcher3ModsRow.tracked && Witcher3ModsRow.status != 2)) continue;
               if (Witcher3ModsRow.selected && Witcher3ModsCategory.GetDropdownGridRef())
               {
                  selectedIndex = Witcher3ModsIndex;
                  Witcher3ModsCategory.SelectSubListItem(Witcher3ModsVisibleIndex);
                  Witcher3ModsFound = true;
               }
               Witcher3ModsVisibleIndex++;
            }
         }
         if (!Witcher3ModsFound) Witcher3ModsFocusFirstCategory();
      }

      public function Witcher3ModsFocusFirstCategory():void
      {
         if (!dataProvider || !dataProvider.length) return;
         selectedIndex = 0;
         validateNow();
         var Witcher3ModsFirst:red.game.witcher3.controls.W3DropdownMenuListItem = getRendererAt(0) as red.game.witcher3.controls.W3DropdownMenuListItem;
         if (!Witcher3ModsFirst) return;
         if (Witcher3ModsFirst.isOpen())
         {
            // Flush pending selection before requesting -1: the native setter
            // ignores a value equal to the committed index even if one is queued.
            Witcher3ModsFirst.GetDropdownListRef().validateNow();
            Witcher3ModsFirst.SelectSubListItem(-1);
            Witcher3ModsFirst.GetDropdownListRef().validateNow();
         }
         Witcher3ModsFirst.selectedIndex = -1;
         Witcher3ModsFirst.selected = true;
         Witcher3ModsFirst.focused = 1;
         var Witcher3ModsFirstHighlight:flash.display.DisplayObject = Witcher3ModsFirst.getChildByName("mcSelectionHighlight");
         if (Witcher3ModsFirstHighlight) Witcher3ModsFirstHighlight.visible = true;
         updatePosition(null);
         if (scrollBar) scrollBar.position = 0;
         if (scrollTweener) scrollTweener.paused = true;
         com.gskinner.motion.GTweener.removeTweens(this);
         scrollTweener = null;
         m_lastScrollPosition = 0;
         y = m_defaultPosition;
      }

      override public function handleInput(Witcher3ModsEvent:scaleform.clik.events.InputEvent):void
      {
         var Witcher3ModsCategory:red.game.witcher3.controls.W3DropdownMenuListItem = getRendererAt(selectedIndex) as red.game.witcher3.controls.W3DropdownMenuListItem;
         var Witcher3ModsRows:Array = Witcher3ModsCategory ? Witcher3ModsCategory.getDropDownData() : null;
         var Witcher3ModsSwitch:Boolean = red.game.witcher3.managers.InputManager.getInstance().isSwitchPlatform();
         var Witcher3ModsToggle:String = Witcher3ModsSwitch ? scaleform.clik.constants.NavigationCode.GAMEPAD_X : scaleform.clik.constants.NavigationCode.GAMEPAD_Y;
         if (!Witcher3ModsEvent.handled && (_focused || !focusable) && enabled && visible && Witcher3ModsRows && Witcher3ModsRows.length &&
             (Witcher3ModsRows[0].Witcher3ModsAchievement || Witcher3ModsRows[0].Witcher3ModsSummary) &&
             Witcher3ModsEvent.details.navEquivalent == Witcher3ModsToggle && Witcher3ModsEvent.details.value == scaleform.clik.constants.InputValue.KEY_DOWN)
         {
            // Handle the category action before forwarding input to its rows.
            // Pins keep a collapsed category physically open: toggle logical state.
            (Witcher3ModsCategory as QuestDropdownMenuListItem).Witcher3ModsToggleCategory();
            Witcher3ModsCategory.selectedIndex = -1;
            Witcher3ModsCategory.selected = true;
            var Witcher3ModsHighlight:flash.display.DisplayObject = Witcher3ModsCategory.getChildByName("mcSelectionHighlight");
            if (Witcher3ModsHighlight) Witcher3ModsHighlight.visible = true;
            updatePosition(null);
            // Native collapse leaves a tween/offset belonging to the expanded list.
            var Witcher3ModsOffset:Number = Math.max(0, Math.min(Witcher3ModsCategory.y, m_currentListHeight - listHeight));
            if (scrollBar) scrollBar.position = Witcher3ModsOffset;
            if (scrollTweener) scrollTweener.paused = true;
            com.gskinner.motion.GTweener.removeTweens(this);
            scrollTweener = null;
            m_lastScrollPosition = Witcher3ModsOffset;
            y = m_defaultPosition - Witcher3ModsOffset;
            for (var Witcher3ModsIndex:int = 0; Witcher3ModsIndex < dataProvider.length; Witcher3ModsIndex++)
            {
               var Witcher3ModsHeader:red.game.witcher3.controls.W3DropdownMenuListItem = getRendererAt(Witcher3ModsIndex) as red.game.witcher3.controls.W3DropdownMenuListItem;
               if (!Witcher3ModsHeader) continue;
               for each (var Witcher3ModsRow:Object in Witcher3ModsHeader.getDropDownData())
               {
                  if (Witcher3ModsRow.Witcher3ModsSummary)
                     dispatchEvent(new red.core.events.GameEvent(red.core.events.GameEvent.CALL, "OnEntrySelected", [Witcher3ModsRow.tag]));
               }
            }
            Witcher3ModsEvent.handled = true;
            Witcher3ModsEvent.stopImmediatePropagation();
            return;
         }
         super.handleInput(Witcher3ModsEvent);
      }
