package {

import eu.claudius.iacob.constants.ClefTypes;
import eu.claudius.iacob.constants.Keys;
import eu.claudius.iacob.draw2D.BaseDrawingTools;
import eu.claudius.iacob.music.writer.ScoreWriter;
import eu.claudius.iacob.music.writer.commands.PutCleff;
import eu.claudius.iacob.music.writer.commands.PutCluster;
import eu.claudius.iacob.music.writer.commands.PutStaff;

import flash.display.Graphics;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFieldType;
import flash.text.TextFormat;

[SWF(width="1280", height="800")]
public class MusicNotator extends Sprite {

    public function MusicNotator() {
        // One needs to click the stage in order to run the tests.
        stage.addEventListener(MouseEvent.CLICK, function (...etc):void {
            trace('CLICKED!');
            _doTests();
        });
    }

    private function _doTests():void {
        // TEST: draw a staff.
        // Call the drawLines function with sample parameters
        var numLines:uint = 5;
        var width:Number = 1200;
        var color:uint = 0xFF0000; // Red color
        var thickness:uint = 3;
        var interstice:uint = 60;
        var anchor:Point = new Point(50, 100);
        var linesResult:Object = BaseDrawingTools.drawStaffLines(this, numLines, width, anchor, color, thickness, interstice);

        // Visualize the resulting geometry
        var staffBounds:Rectangle = (linesResult.bounds as Rectangle);
        graphics.lineStyle(1, 0x0000FF);
        graphics.drawRect(staffBounds.x, staffBounds.y, staffBounds.width, staffBounds.height);

        // Draw dots with numbers to visualize the positions
        var p:Array = linesResult.intrinsicPositions.concat();
        p.unshift(linesResult.underPosition);
        p.push(linesResult.overPosition);
        var _t:TextField;
        var tf:TextFormat = new TextFormat('Arial', 12, 0x0000ff, true);
        for (var i:int = 0; i < p.length; i++) {
            var position:Number = (p[i] as Number);
            graphics.drawRect(staffBounds.x, position - 1, 2, 2);
            _t = new TextField();
            _t.type = TextFieldType.DYNAMIC;
            _t.autoSize = TextFieldAutoSize.CENTER;
            _t.thickness = 600;
            _t.defaultTextFormat = tf;
            _t.border = true;
            _t.text = ('' + i);
            addChild(_t);
            _t.x = (staffBounds.x - 15);
            _t.y = position - _t.height / 2;
        }

        // TEST: drawing ellipsis (1)
        /*
                var centerX:Number = stage.stageWidth / 2;
                var centerY:Number = stage.stageHeight / 2;
                var shortAxis:Number = 50;
                var ellipseColor:uint = 0xFF0000; // Red
                var retVal:Object = BaseDrawingTools.drawFullNotehead(this, centerX, centerY, shortAxis, ellipseColor);

                // Visualize the resulting geometry
                var box:Rectangle = retVal.bounds;
                graphics.lineStyle(2, 0x00FFFF);
                graphics.drawRect(box.left, box.top, box.width, box.height);

                graphics.lineStyle(2, 0xFF00FF);
                graphics.drawRect(retVal.rightAnchor.x - 5, retVal.rightAnchor.y - 5, 10, 10);
                graphics.drawRect(retVal.leftAnchor.x - 5, retVal.leftAnchor.y - 5, 10, 10);
        */

        // TEST: place custom graphic
        var clefInfo:Object = BaseDrawingTools.placeTrebleClef(this, staffBounds.left, linesResult.intrinsicPositions[3], linesResult.step);
        var clefBounds:Rectangle = clefInfo.bounds;
        graphics.lineStyle(2, 0x00ff00);
        graphics.drawRect(clefBounds.x, clefBounds.y, clefBounds.width, clefBounds.height);

        // TEST: drawing ellipsis (2) with ledger line(s)
        var ellipseResult:Object = BaseDrawingTools.drawFullNotehead(this, clefBounds.right + 20, linesResult.underPosition, interstice, 0xff00ff);
        var ledgerLinesResult:Object = BaseDrawingTools.drawStaffLines(this, 1, ellipseResult.bounds.width + 20, new Point(ellipseResult.bounds.x - 10, linesResult.underPosition), 0xff9900, 3);

        // TEST: draw sharp sign on G pitch
        var sharpInfo:Object = BaseDrawingTools.placeSharp(this, ledgerLinesResult.bounds.right + 10,
                linesResult.intrinsicPositions[3], linesResult.step);
        var sharpBounds:Rectangle = sharpInfo.bounds;
        graphics.lineStyle(2, 0xff33ff);
        graphics.drawRect(sharpBounds.x, sharpBounds.y, sharpBounds.width, sharpBounds.height);

        // TEST: draw natural sign on G pitch
        var naturalInfo:Object = BaseDrawingTools.placeNatural(this, sharpBounds.right + 10, linesResult.intrinsicPositions[3], linesResult.step);
        var naturalBounds:Rectangle = naturalInfo.bounds;
        graphics.lineStyle(2, 0x3366ff);
        graphics.drawRect(naturalBounds.x, naturalBounds.y, naturalBounds.width, naturalBounds.height);

        // TEST: draw flat on G pitch
        var flatInfo:Object = BaseDrawingTools.placeFlat(this, naturalBounds.right + 10, linesResult.intrinsicPositions[3], linesResult.step);
        var flatBounds:Rectangle = flatInfo.bounds;
        graphics.lineStyle(2, 0xff6633);
        graphics.drawRect(flatBounds.x, flatBounds.y, flatBounds.width, flatBounds.height);

        // TEST: draw bass clef on F pitch (2nd staff line from top)
        var bassClefInfo:Object = BaseDrawingTools.placeBassClef(this, flatBounds.right + 10, linesResult.intrinsicPositions[7], linesResult.step);
        var bassBounds:Rectangle = bassClefInfo.bounds;
        graphics.lineStyle(2, 0x3366ff);
        graphics.drawRect(bassBounds.x, bassBounds.y, bassBounds.width, bassBounds.height);

        // TEST: draw shape nothead on F pitch
        var hoteHeadInfo:Object = BaseDrawingTools.placeFullNotehead(this, bassBounds.right + 10,
                linesResult.intrinsicPositions[7], linesResult.step);
        var noteheadBounds:Rectangle = hoteHeadInfo.bounds;
        graphics.drawRect(noteheadBounds.x, noteheadBounds.y, noteheadBounds.width, noteheadBounds.height);

        // TEST: draw shape nothead on E pitch
        hoteHeadInfo = BaseDrawingTools.placeFullNotehead(this, noteheadBounds.right + 10,
                linesResult.intrinsicPositions[6], linesResult.step);
        noteheadBounds = hoteHeadInfo.bounds;
        graphics.drawRect(noteheadBounds.x, noteheadBounds.y, noteheadBounds.width, noteheadBounds.height);

        // TEST: draw shape nothead on G pitch
        hoteHeadInfo = BaseDrawingTools.placeFullNotehead(this, noteheadBounds.right + 10,
                linesResult.intrinsicPositions[8], linesResult.step);
        noteheadBounds = hoteHeadInfo.bounds;
        graphics.drawRect(noteheadBounds.x, noteheadBounds.y, noteheadBounds.width, noteheadBounds.height);

        // TEST: draw shape nothead on A pitch
        hoteHeadInfo = BaseDrawingTools.placeFullNotehead(this, noteheadBounds.right + 10,
                linesResult.intrinsicPositions[9], linesResult.step);
        noteheadBounds = hoteHeadInfo.bounds;
        graphics.drawRect(noteheadBounds.x, noteheadBounds.y, noteheadBounds.width, noteheadBounds.height);


        // ========================
        // TESTING THE SCORE WRITER
        // ========================
        // Prepare the canvas
        var swCanvas:Sprite = new Sprite();
        var swg:Graphics = swCanvas.graphics;
        var swgY:Number = Math.max(
                staffBounds.bottom,
                p[0],
                ledgerLinesResult.bounds.bottom,
                clefBounds.bottom,
                ellipseResult.bounds.bottom
        ) + 20;
        swg.lineStyle(2, 0x0033ff);
        var swW:Number = 1278;
        var swH:Number = (800 - swgY - 2);
        swg.drawRect(0, 0, swW, swH);
        addChild(swCanvas);
        swCanvas.y = swgY;

        //----
        var settings:Object = {};
        settings[Keys.HORIZONTAL_PADDING] = 10;
        var writer:ScoreWriter = new ScoreWriter(swCanvas, settings);
        writer.addCommand(new PutStaff(swW - 40, 20, 100));
        writer.addCommand(new PutCleff(ClefTypes.BASS));
        writer.addCommand(new PutCleff(ClefTypes.TREBLE));
        writer.addCommand(new PutCleff(ClefTypes.BASS));
        writer.addCommand(new PutCleff(ClefTypes.LAST_KNOWN));
        writer.addCommand(new PutCluster(null, new <uint>[58, 59, 60, 62, 64, 65, 67, 69, 71, 72, 74, 76, 77, 79, 81, 83, 84]));

        writer.write();
    }

}
}
