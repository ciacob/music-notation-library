package eu.claudius.iacob.music.writer.commands {
import eu.claudius.iacob.constants.Commands;
import eu.claudius.iacob.constants.Prefixes;
import eu.claudius.iacob.draw2D.BaseDrawingTools;
import eu.claudius.iacob.music.writer.IScoreContext;

import flash.geom.Point;

public class PutStaff extends AbstractScoreWritingCommand {

    private const NUM_LINES:uint = 5;

    /**
     * Command to draw a staff on the canvas. Calls into `BaseDrawingTools.drawStaffLines()`.
     * @param   width
     *          Width of the staff, in pixels;
     *
     * @param   x
     *          The `x` the staff will be placed at;
     *
     * @param   y
     *          The `y` the staff will be placed at;
     *
     * @param   interstice
     *          Optional. Interstice (vertical space between the lines). See
     *          `BaseDrawingTools.drawStaffLines()` for defaults.
     *
     * @param   thickness
     *          Optional. Thickness of staff lines, in pixels. See `BaseDrawingTools.drawStaffLines()`
     *          for defaults.
     *
     * @param   color
     *          Optional. Color for the staff lines, as RGB uint. See `BaseDrawingTools.drawStaffLines()`
     *          for defaults.
     */
    public function PutStaff(width:Number, x:Number, y:Number,
                             interstice:uint = 0,
                             thickness:uint = 0,
                             color:uint = 0) {

        var params:Vector.<Number> = new Vector.<Number>;
        params.push(width, x, y, interstice, thickness, color)
        super(this, Commands.PUT_STAFF, params);
    }

    public function get width():Number {
        return params[0];
    }

    public function get x():Number {
        return params[1];
    }

    public function get y():Number {
        return params[2];
    }

    public function get interstice():uint {
        return params[3];
    }

    public function get thickness():uint {
        return params[4];
    }

    public function get color():uint {
        return params[5];
    }

    public function get anchor():Point {
        return new Point(x, y);
    }

    override public function execute(context:IScoreContext = null):Object {
        if (context) {
            var payload:Object = BaseDrawingTools.drawStaffLines(
                    context.container,
                    NUM_LINES,
                    width,
                    anchor,
                    color,
                    thickness,
                    interstice
            );

            // Make information on last introduced staff available under the `Prefixes.STAFF` prefix.
            context.store(payload, Prefixes.STAFF);
        }
        // No applicable information for volatile/anonymous storage.
        return null;
    }
}
}
