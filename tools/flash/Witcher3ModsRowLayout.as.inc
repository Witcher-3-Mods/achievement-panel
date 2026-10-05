      private var Witcher3ModsNativeLayout:Object;

      private function Witcher3ModsLayoutRow():void
      {
         // Objective renderers inherit this class but have no crest/level column.
         if (!crests || !tfLevel || !textField || !tfSecondLine || !headerColor) return;
         if (!Witcher3ModsNativeLayout)
            Witcher3ModsNativeLayout = {iconX:crests.x, iconY:crests.y,
               titleX:textField.x, titleWidth:textField.width,
               subtitleX:tfSecondLine.x, subtitleWidth:tfSecondLine.width,
               levelVisible:tfLevel.visible};
         // Restore first: renderers are reused for summary rows and native quests.
            crests.x = Witcher3ModsNativeLayout.iconX;
            crests.y = Witcher3ModsNativeLayout.iconY;
            textField.x = Witcher3ModsNativeLayout.titleX;
            textField.width = Witcher3ModsNativeLayout.titleWidth;
            tfSecondLine.x = Witcher3ModsNativeLayout.subtitleX;
            tfSecondLine.width = Witcher3ModsNativeLayout.subtitleWidth;
            tfLevel.visible = Witcher3ModsNativeLayout.levelVisible;
         if (!data || (!data.Witcher3ModsAchievement && !data.Witcher3ModsSummary)) return;
         tfLevel.visible = false;
         tfLevel.htmlText = "";
         var Witcher3ModsPadding:Number = 10;
         var Witcher3ModsStripe:flash.geom.Rectangle = headerColor.getBounds(this);
         var Witcher3ModsTextX:Number = Witcher3ModsStripe.right + Witcher3ModsPadding;
         if (String(data.questArea).indexOf("Witcher3Mods_EA_") == 0)
         {
            var Witcher3ModsIcon:flash.geom.Rectangle = crests.getBounds(this);
            crests.x += Witcher3ModsStripe.right + Witcher3ModsPadding - Witcher3ModsIcon.left;
            crests.y += Witcher3ModsStripe.top + (Witcher3ModsStripe.height - Witcher3ModsIcon.height) / 2 - Witcher3ModsIcon.top;
            Witcher3ModsTextX = crests.getBounds(this).right + Witcher3ModsPadding - 4;
         }
         textField.x = Witcher3ModsTextX;
         textField.width = Witcher3ModsNativeLayout.titleX + Witcher3ModsNativeLayout.titleWidth - Witcher3ModsTextX;
         tfSecondLine.x = Witcher3ModsTextX;
         tfSecondLine.width = Witcher3ModsNativeLayout.subtitleX + Witcher3ModsNativeLayout.subtitleWidth - Witcher3ModsTextX;
      }

      private function Witcher3ModsSetRowDescription():void
      {
         if (!data || !data.Witcher3ModsAchievement || !tfSecondLine || !data.Witcher3ModsRowDescription) return;
         Witcher3ModsLayoutRow();
         var Witcher3ModsDescription:String = String(data.Witcher3ModsRowDescription);
         tfSecondLine.text = Witcher3ModsDescription;
         // Keep the native fixed-height row. Full descriptions remain in details.
         while (Witcher3ModsDescription.length > 0 && (tfSecondLine.numLines > 1 || tfSecondLine.textWidth > tfSecondLine.width - 4))
         {
            Witcher3ModsDescription = Witcher3ModsDescription.substr(0, Witcher3ModsDescription.length - 1);
            tfSecondLine.text = Witcher3ModsDescription + "...";
         }
      }

      override protected function draw():void
      {
         super.draw();
         Witcher3ModsLayoutRow();
      }
