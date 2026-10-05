      private var Witcher3ModsCategoryRows:Array;
      private var Witcher3ModsCategoryExpanded:Boolean;

      public function Witcher3ModsSetCategoryRows(Witcher3ModsRows:Array):void
      {
         Witcher3ModsCategoryRows = null;
         if (Witcher3ModsRows && Witcher3ModsRows.length &&
             (Witcher3ModsRows[0].Witcher3ModsAchievement || Witcher3ModsRows[0].Witcher3ModsSummary))
         {
            Witcher3ModsCategoryRows = Witcher3ModsRows;
            Witcher3ModsCategoryExpanded = Boolean(Witcher3ModsRows[0].dropDownOpened);
         }
      }

      override public function getDropDownData():Array
      {
         return Witcher3ModsCategoryRows ? Witcher3ModsCategoryRows : super.getDropDownData();
      }

      override public function IsOpenedByDefault():Boolean
      {
         if (!Witcher3ModsCategoryRows) return super.IsOpenedByDefault();
         if (Witcher3ModsCategoryExpanded) return true;
         for each (var Witcher3ModsRow:Object in Witcher3ModsCategoryRows)
            if (Witcher3ModsRow.tracked && Witcher3ModsRow.status != 2) return true;
         return false;
      }

      private function Witcher3ModsRenderCategory():void
      {
         hideDropdown();
         selectedIndex = -1;
         dropDownData = [];
         for each (var Witcher3ModsRow:Object in Witcher3ModsCategoryRows)
            if (Witcher3ModsCategoryExpanded || (Witcher3ModsRow.tracked && Witcher3ModsRow.status != 2))
               dropDownData.push(Witcher3ModsRow);
         if (dropDownData.length) showDropdown();
         if (_dropdownRef)
         {
            // Match native W3DropdownMenuListItem.open(): settle creation, then
            // commit header selection. CLIK selectedIndex is deferred.
            _dropdownRef.validateNow();
            _dropdownRef.selectedIndex = -1;
            _dropdownRef.validateNow();
         }
         mcOpenedState.gotoAndStop(Witcher3ModsCategoryExpanded ? "opened" : "closed");
         var Witcher3ModsParent:QuestDropDownList = parent as QuestDropDownList;
         if (Witcher3ModsParent && !Witcher3ModsParent.Witcher3ModsRebuilding) Witcher3ModsParent.updatePosition(null);
      }

      private function Witcher3ModsChangeCategory(Witcher3ModsExpanded:Boolean):void
      {
         var Witcher3ModsChanged:Boolean = Witcher3ModsCategoryExpanded != Witcher3ModsExpanded;
         Witcher3ModsCategoryExpanded = Witcher3ModsExpanded;
         for each (var Witcher3ModsRow:Object in Witcher3ModsCategoryRows) Witcher3ModsRow.dropDownOpened = Witcher3ModsExpanded;
         Witcher3ModsRenderCategory();
         if (Witcher3ModsChanged)
            dispatchEvent(new red.core.events.GameEvent(red.core.events.GameEvent.CALL, "OnCategoryOpened", [CategoryTag, Witcher3ModsExpanded]));
      }

      public function Witcher3ModsToggleCategory():void
      {
         if (Witcher3ModsCategoryRows) Witcher3ModsChangeCategory(!Witcher3ModsCategoryExpanded);
         else if (isOpen()) super.close();
         else super.open();
      }

      override public function open(Witcher3ModsAllowSound:Boolean = true):void
      {
         if (!Witcher3ModsCategoryRows) { super.open(Witcher3ModsAllowSound); return; }
         if (Witcher3ModsAllowSound) Witcher3ModsChangeCategory(true);
         else Witcher3ModsRenderCategory();
      }

      override public function close():void
      {
         if (!Witcher3ModsCategoryRows) { super.close(); return; }
         // Native cleanup closes detached renderers: never persist that operation.
         if (!parent || !stage || (parent is QuestDropDownList && (parent as QuestDropDownList).Witcher3ModsRebuilding)) { hideDropdown(); return; }
         // A collapsed category with pins is physically open for native navigation.
         // Clicking its header and the category action both toggle logical state.
         Witcher3ModsChangeCategory(!Witcher3ModsCategoryExpanded);
      }
