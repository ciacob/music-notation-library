package eu.claudius.iacob.music.writer.commands {
import eu.claudius.iacob.constants.ClefTypes;
import eu.claudius.iacob.constants.Commands;
import eu.claudius.iacob.constants.Keys;
import eu.claudius.iacob.constants.Prefixes;
import eu.claudius.iacob.draw2D.BaseDrawingTools;
import eu.claudius.iacob.music.writer.IScoreContext;

import flash.geom.Rectangle;

public class PutClef extends AbstractScoreWritingCommand {

    /**
     * Command to draw a clef on the most recently drawn staff. Calls into
     * `BaseDrawingTools.placeTrebleClef()` and `BaseDrawingTools.placeBassClef()`.
     *
     * @param   type
     *          Type of clef to use, where:
     *          - `0` means to repeat the last type of cleff used; defaults to the treble cleff;
     *          - `1` is the treble clef;
     *          - `2` is the bass clef.
     *
     * @param   color
     *          The color to draw the clef in, optional. See `BaseDrawingTools.placeShape()` for defaults.
     */
    public function PutClef(type:int, color:uint = 0) {

        var params:Vector.<Number> = new Vector.<Number>;
        params.push(type, color);
        super(this, Commands.PUT_CLEF, params);
    }

    public function get $type():int {
        return params[0];
    }

    public function set $type(value:int):void {
        params[0] = value;
    }

    public function get color():uint {
        return params[1];
    }

    override public function execute(context:IScoreContext = null):Object {
        if (context && context.container && context.$has(Prefixes.STAFF)) {
            // Handle "last known" clef type, default to Treble.
            if ($type == ClefTypes.LAST_KNOWN) {
                $type = (context.$get(Keys.CLEF_TYPE, Prefixes.CLEFF) as int) || ClefTypes.TREBLE;
            }

            // Resolve clef type to a function in class `BaseDrawingTools`. Also resolve
            // type specific params to pass to that function.
            var drawingFn:Function = null;
            var posIndex:int = -1;
            switch ($type) {
                case ClefTypes.TREBLE:
                    drawingFn = BaseDrawingTools.placeTrebleClef;
                    posIndex = 3;
                    break;
                case ClefTypes.BASS:
                    drawingFn = BaseDrawingTools.placeBassClef;
                    posIndex = 7;
                    break;
            }

            // Only proceed if a suitable drawing function has been identified.
            if (drawingFn && context.$has(Prefixes.STAFF)) {
                var staffBounds:Rectangle = context.$get('bounds', Prefixes.STAFF) as Rectangle;
                var prevObjectBounds:Rectangle = context.$get('bounds') as Rectangle;
                var staffPositions:Array = context.$get('intrinsicPositions', Prefixes.STAFF) as Array;
                var staffStep:Number = context.$get('step', Prefixes.STAFF) as Number;
                var hPadding:uint = context.$get(Keys.HORIZONTAL_PADDING, Prefixes.SETTINGS) as uint;

                var payload:Object = drawingFn(
                        context.container,
                        prevObjectBounds ? hPadding + prevObjectBounds.right : staffBounds.x + hPadding,
                        staffPositions[posIndex],
                        staffStep,
                        color
                );
                payload[Keys.CLEF_TYPE] = $type;

                // Make information on last introduced cleff available under the `Prefixes.CLEFF` prefix.
                context.store(payload, Prefixes.CLEFF);
            }

            // Also return the same data as anonymous data, so the next object being written to the score will
            // know about the geometry of the object written just before it.
            return payload;
        }

        return null;
    }
}
}
