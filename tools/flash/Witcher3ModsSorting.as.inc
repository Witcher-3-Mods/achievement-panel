      private function Witcher3ModsTitleSortKey(Witcher3ModsTitle:String):String
      {
         // Polish letters follow their base letter; independent of OS/Flash locale.
         return Witcher3ModsTitle.toLowerCase().replace(/ą/g,"a~").replace(/ć/g,"c~").replace(/ę/g,"e~").replace(/ł/g,"l~").replace(/ń/g,"n~").replace(/ó/g,"o~").replace(/ś/g,"s~").replace(/ź/g,"z~1").replace(/ż/g,"z~2");
      }

      private function Witcher3ModsCompareRows(Witcher3ModsLeft:Object, Witcher3ModsRight:Object):int
      {
         if (Witcher3ModsLeft.originalCat != Witcher3ModsRight.originalCat)
            return Witcher3ModsLeft.originalCat < Witcher3ModsRight.originalCat ? -1 : 1;
         if (Boolean(Witcher3ModsLeft.tracked) != Boolean(Witcher3ModsRight.tracked))
            return Witcher3ModsLeft.tracked ? -1 : 1;
         var Witcher3ModsLeftTitle:String = Witcher3ModsTitleSortKey(String(Witcher3ModsLeft.title));
         var Witcher3ModsRightTitle:String = Witcher3ModsTitleSortKey(String(Witcher3ModsRight.title));
         if (Witcher3ModsLeftTitle != Witcher3ModsRightTitle)
            return Witcher3ModsLeftTitle < Witcher3ModsRightTitle ? -1 : 1;
         if (Witcher3ModsLeft.originalId == Witcher3ModsRight.originalId) return 0;
         return Witcher3ModsLeft.originalId < Witcher3ModsRight.originalId ? -1 : 1;
      }
