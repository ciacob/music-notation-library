package eu.claudius.iacob.draw2D {
import eu.claudius.iacob.constants.IntrinsicShapeGeometry;

import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.display.Shape;
import flash.display.Sprite;
import flash.geom.ColorTransform;
import flash.geom.Point;
import flash.geom.Rectangle;

public class BaseDrawingTools {
    public static const NOTEHEAD_MAJOR_AXIS_FACTOR:Number = 1.65;
    public static const NOTEHEAD_ANGLE:Number = -10;

    public function BaseDrawingTools() {
    }

    /**
     * This method draws a number of equidistant, parallel lines to be used as a music staff. It returns
     * an object that describes the geometry of the resulting drawing. Note that the actual drawing will be
     * placed in a Shape that will be appended to given `container`.
     *
     * @param   container
     *          A Sprite (subclass) to draw in.
     *
     * @param   numLines
     *          How many lines to be drawn. The minimum enforced value is `1`. The ability to draw more than 5
     *          lines is justified by the need of having ledger lines, which can, in theory, extend
     *          indefinitely above or below a 5-lines staff.
     *
     * @param   width
     *          How wide the drawn lines must be. Minimum enforced value is `1`.
     *
     * @param   anchor
     *          Top-left point, in the system of coordinates of the given `container`, to start drawing from.
     *          Lines are drawn from top to bottom, so this argument defines the top-left point of the
     *          top-most line being drawn.
     *
     * @param   color
     *          Optional. The color to draw the lines in; defaults to black.
     *
     * @param   thickness
     *          Optional. Thickness of the lines being drawn; default, and minimum enforced value is `2`.
     *
     * @param   interstice
     *          Optional. Vertical space between two adjacent lines; default, and minimum enforced value
     *          is`15`.
     *
     * @return Object with the following information:
     * - shape:
     *   The Shape object the staff lines have been drawn in. It is already positioned properly,
     *   and can be subjected to subsequent manipulation, such as recoloring via `ColorTransform`.
     *
     *  - bounds:
     *    A Rectangle representing the drawn lines, with no intervening padding or space.
     *
     * - step:
     *   Half the vertical distance between the bottom line and the line immediately above it.
     *
     * - intrinsicPositions:
     *   Array of Numbers, where each Number represents a `y` value where the center of a notehead could
     *   legitimately be placed. There are 11 intrinsic positions on a standard 5-lines staff: beneath the
     *   first (bottom) line, on the first line, between the first and second line, and so forth.
     *
     * - underPosition:
     *   Number representing the `y` value of the first ledger line below the staff (e.g., vertical position
     *   of a "middle C" in the treble clef).
     *
     * - overPosition:
     *   Number representing the `y` value of the first ledger line above the staff (e.g., vertical position
     *   of a "middle C" in the bass clef).
     */


    public static function drawStaffLines(container:Sprite, numLines:uint, width:Number,
                                          anchor:Point = null, color:uint = 0x000000,
                                          thickness:uint = 2, interstice:uint = 15):Object {

        // Provide defaults and enforce minimum values.
        if (numLines < 1) {
            numLines = 1;
        }
        if (width < 1) {
            width = 1;
        }
        if (anchor == null) {
            anchor = new Point(0, 0);
        }
        if (thickness < 2) {
            thickness = 2;
        }
        if (interstice < 15) {
            interstice = 15;
        }

        // Compute basic geometry (in parent coordinates).
        var top:Number = anchor.y;
        var bottom:Number = anchor.y + ((numLines - 1) * interstice) + (numLines * thickness);
        var height:Number = (bottom - top);
        var left:Number = anchor.x;
        var staffBounds:Rectangle = new Rectangle(left, top, width, height);
        var step:Number = (interstice / 2 + thickness / 2);

        // Draw the lines (in local coordinates) and compute the remaining geometry (in parent coordinates).
        var staff:Shape = new Shape();
        var g:Graphics = staff.graphics;
        g.beginFill(color);

        var i:uint;
        var lineY:Number;
        var position:Number;
        var intrinsicPositions:Array = [];
        for (i = 0; i < numLines; i++) {
            lineY = i * (thickness + interstice);
            g.drawRect(0, lineY, width, thickness);

            // Register middle of the line as an intrinsic position (in parent coordinates).
            position = anchor.y + (lineY + thickness / 2);
            intrinsicPositions.unshift(position);

            // Register middle of next space as an intrinsic position.
            position = anchor.y + (lineY + thickness / 2 + step);
            intrinsicPositions.unshift(position);
        }

        // Add the Shape to given container, and position it.
        g.endFill();
        container.addChild(staff);
        staff.x = anchor.x;
        staff.y = anchor.y;

        // Add an extra "intrinsic position" above the first line. This will legitimately be located outside
        // the `staffBounds` rectangle.
        intrinsicPositions.push(top + thickness / 2 - step);

        // Register the "under" and "over" positions.
        var underPosition:Number = (intrinsicPositions[0] + step);
        var overPosition:Number = (intrinsicPositions[intrinsicPositions.length - 1] - step);

        // Return the values object
        return {
            shape: staff,
            bounds: staffBounds,
            step: step,
            intrinsicPositions: intrinsicPositions,
            underPosition: underPosition,
            overPosition: overPosition,
            thickness: thickness
        };
    }

    /**
     * Measures the expected height of a staff without actually drawing the staff.
     * @param   numLines
     *          How many lines the staff would contain. Minimum enforced value is `1`.
     *
     * @param   thickness
     *          Optional. Thickness of the would-be staff lines. Default, and minimum enforced value is `2`.
     *
     * @param   interstice
     *          Optional. Vertical space between two adjacent lines of the would-be staff. Default, and minimum
     *          enforced value is `15`.
     *
     * @return  Number, representing the calculated height.
     */
    public static function measureStaff (numLines:uint, thickness:uint = 2, interstice:uint = 15) : Number {
        // Provide defaults and enforce minimum values.
        if (numLines < 1) {
            numLines = 1;
        }
        if (thickness < 2) {
            thickness = 2;
        }
        if (interstice < 15) {
            interstice = 15;
        }
        return ((numLines - 1) * interstice) + (numLines * thickness);
    }

    /**
     * Draws a full (i.e., not hollow) notehead to be used for depicting a musical pitch on a staff.
     *
     * More specifically, it draws an angled ellipse inside a container and returns information about the
     * resulting ellipse's size, position and anchor points. Note that both the intrinsic ratio of the
     * ellipse and its angle are fixed, and based on the MAJOR_AXIS_FACTOR and NOTEHEAD_ANGLE constants.
     *
     * @param   container
     *          A Sprite (subclass) to draw the ellipse in.
     *
     * @param   leftX
     *          The x-coordinate representing the ellipse's left boundary. Resulting ellipse will
     *          be left-aligned to it.
     *
     * @param   centerY
     *          The y-coordinate representing the ellipse's vertical center. Resulting ellipse will be
     *          vertically centered on it.
     *
     * @param   maxHeight
     *          The maximum height the ellipse is allowed to have, rotation observed. Resulting ellipse
     *          will be at most as tall as this value.
     *
     * @param   color
     *          Optional. The color to fill the ellipse with. Default is black.
     *
     * @return An object containing the following properties:
     * - shape: The Shape object the notehead has been drawn in. It is already positioned and
     *   rotated properly, and can be subjected to subsequent manipulation,such as recoloring via
     *   `ColorTransform`.
     *
     * - leftAnchor: The rotated left major endpoint of the ellipse. Can be used for attaching a
     *   downward stem to the notehead.
     *
     * - rightAnchor: The rotated right major endpoint of the ellipse. Can be used for attaching a
     *   upward stem to the notehead.
     *
     * - bounds: A Rectangle representing the bounding box of the drawn notehead, in the
     *   coordinates system of the given `container`. Can be used for zone hinting, or to draw a
     *   visible selection box in a music editing application.
     */
    public static function drawFullNotehead(
            container:Sprite,
            leftX:Number,
            centerY:Number,
            maxHeight:Number,
            color:uint = 0x000000):Object {

        // Prepare for drawing.
        var minorAxis:Number = BaseDrawingTools.calculateMinorAxis(maxHeight, NOTEHEAD_ANGLE);
        var majorAxis:Number = minorAxis * NOTEHEAD_MAJOR_AXIS_FACTOR;
        var initialLocalLeft:Number = (-majorAxis);
        var initialLocalTop:Number = (-minorAxis);
        var initialWidth:Number = (majorAxis * 2);
        var initialHeight:Number = (minorAxis * 2);
        var angleRadians:Number = NOTEHEAD_ANGLE * (Math.PI / 180);

        // Draw inside a Shape, add the Shape to given container, rotate it, and position vertically.
        var ellipse:Shape = new Shape();
        var g:Graphics = ellipse.graphics;
        g.beginFill(color);
        g.drawEllipse(initialLocalLeft, initialLocalTop, initialWidth, initialHeight);
        g.endFill();
        container.addChild(ellipse);
        ellipse.rotation = NOTEHEAD_ANGLE;
        ellipse.y = centerY;

        // COMPUTE INITIAL (NOT ROTATED) GEOMETRY POINTS.
        var rotationPoint:Point = new Point(0, 0);

        // initial left major endpoint
        var initialLME:Point = new Point(initialLocalLeft, 0);

        // initial right major endpoint
        var initialRME:Point = new Point(majorAxis, 0);

        // initial top minor endpoint
        var initialTME:Point = new Point(0, initialLocalTop);

        // initial bottom minor endpoint;
        var initialBME:Point = new Point(0, minorAxis);

        // COMPUTE FINAL (ROTATED) GEOMETRY POINTS.
        // final left major endpoint
        var finalLME:Point = rotatePoint(initialLME, rotationPoint, angleRadians);

        // final right major endpoint
        var finalRME:Point = rotatePoint(initialRME, rotationPoint, angleRadians);

        // final top minor endpoint
        var finalTME:Point = rotatePoint(initialTME, rotationPoint, angleRadians);

        // final bottom minor end point
        var finalBME:Point = rotatePoint(initialBME, rotationPoint, angleRadians);

        // COMPUTE FINAL BOUNDS (not rotated bounds of the rotated geometry).
        var finalLocalLeft:Number = Math.min(finalLME.x, finalRME.x, finalTME.x, finalBME.x);
        var finalLocalRight:Number = Math.max(finalLME.x, finalRME.x, finalTME.x, finalBME.x);
        var finalLocalTop:Number = Math.min(finalLME.y, finalRME.y, finalTME.y, finalBME.y);
        var finalLocalBottom:Number = Math.max(finalLME.y, finalRME.y, finalTME.y, finalBME.y);
        var finalWidth:Number = (finalLocalRight - finalLocalLeft);
        var finalHeight:Number = (finalLocalBottom - finalLocalTop);
        leftX += (finalWidth / 2);
        var parentBounds:Rectangle = new Rectangle(
                leftX + finalLocalLeft,
                centerY + finalLocalTop,
                finalWidth,
                finalHeight
        );

        // Position the ellipse horizontally
        ellipse.x = leftX;

        // Reinterpret useful geometry in the context of the given `container` and return it.
        finalLME.x += leftX;
        finalLME.y += centerY;
        finalRME.x += leftX;
        finalRME.y += centerY;
        return {
            shape: ellipse,
            bounds: parentBounds,
            leftAnchor: finalLME,
            rightAnchor: finalRME
        };
    }

    /**
     * Instantiates a precompiled shape from an embedded SWF and adds it to given `container`, at requested
     * (`x`,`y`) coordinates, offset according to given `anchorPoint` and scaled with respect to given
     * `stepSize`. Returns an Object with useful information.
     *
     * @param   shapeClass
     *          The class of the precompiled shape to instantiate and place.
     *
     * @param   shapeGeometry
     *          Rectangle describing the shape's intrinsic anchor point and unscaled width/height. Values are
     *          taken from the `IntrinsicShapeGeometry` constants class.
     *
     * @param   container
     *          A Sprite or subclass to add the shape to.
     *
     * @param   x
     *          The x-coordinate where the shape should be placed within the `container`.
     *
     * @param   y
     *          The y-coordinate where the shape should be placed within the `container`.
     *
     * @param   stepSize
     *          Controls placed shape's XY scaling. Essentially, you will set `stepSize` to the real value
     *          obtained from an actual drawn staff in order to obtain a normal, or "regular" size of the
     *          shape, i.e., one that is appropriate to that staff size; you can set a larger value to obtain
     *          an oversized shape, or a smaller one to obtain an undersized shape (e.g., to create a grace
     *          note notehead). All shapes have been authored the way that they have an intrinsic (or
     *          "innate") `stepSize` of `2.786`: any larger value will upscale them, any smaller value will
     *          downscale them.
     *
     * @param   color
     *          Optional. The color to tint the shape with. Default is black (0x000000).
     *
     * @param   anchorPoint
     *          Optional. If missing, the one from the provided `shapeGeometry` is assumed.
     *          Note: the anchor point controls what setting the `x` and `y` properties on the placed shape
     *          do. The `anchorpoint` is essentially an offset to be subtracted from the given `x` and `y`
     *          values. E.g., a 100 by 100px shape having an `anchorPoint` of (50,50) will be `anchored` in
     *          its center, the way that setting its `x` and `y` properties at (0,0) will actually position
     *          the shape at (-50,-50) inside the `container`.
     *
     * @return  An Object containing this information:
     *          - shape: The DisplayObject of the placed shape within the `container`.
     *          - bounds: A Rectangle representing the bounding box of the placed shape, in the coordinates
     *            system of the given `container`.
     */
    public static function placeShape(
            shapeClass:Class,
            shapeGeometry:Rectangle,
            container:Sprite, x:Number, y:Number,
            stepSize:Number,
            color:uint = 0x000000,
            anchorPoint:Point = null):Object {


        const INTRINSIC_COLOR:uint = 0x000000;

        if (!anchorPoint) {
            anchorPoint = new Point(shapeGeometry.x, shapeGeometry.y);
        }

        // Instantiate given `shapeClass`, and add it to some internal container, in order to be able
        // to preserve the integrity of the given `anchorPoint`, in spite any future scaling. Move the
        // resulting shape into the negative space of the internal container, so that the containers
        // "origin" effectively becomes the requested `anchorPoint`.
        var shape:DisplayObject = (new shapeClass() as DisplayObject);
        var innerContainer:Sprite = new Sprite();
        innerContainer.addChild(shape);
        shape.x = (anchorPoint.x * -1);
        shape.y = (anchorPoint.y * -1);

        // Scale the internal container to the ratio of given `stepSize` to the intrinsic step size.
        // Scaling will happen around the internal container's "origin", which will preserve the
        // requested `anchorPoint`.
        var shapeScale:Number = 1;
        if (!isNaN(stepSize)) {
            shapeScale = getScaleForStepSize(stepSize);
            innerContainer.scaleX = innerContainer.scaleY = shapeScale;
        }

        // Place the internal container at requested `x`, `y`. This effectively aligns its "origin" to
        // requested coordinates, thus honouring the requested `anchorPoint`.
        container.addChild(innerContainer);
        innerContainer.x = x;
        innerContainer.y = y;

        // Color the Shape, if needed (shapes intrinsic color is black; we only tint the internal container
        // if other color was requested.
        if (color != INTRINSIC_COLOR) {
            var red:uint = (color >> 16) & 0xFF;
            var green:uint = (color >> 8) & 0xFF;
            var blue:uint = color & 0xFF;
            var ct:ColorTransform = new ColorTransform(0, 0, 0, 1, red, green, blue);
            innerContainer.transform.colorTransform = ct;
        }

        // Compute the geometry of the resulting shape, in the coordinates system of the given `container`.
        var scaledGeometry:Rectangle = scaleShapeGeometry(shapeGeometry, shapeScale);
        var $bounds:Rectangle = new Rectangle(
                x - scaledGeometry.x,
                y - scaledGeometry.y,
                scaledGeometry.width,
                scaledGeometry.height
        );

        // Return useful information.
        return {
            shape: innerContainer,
            bounds: $bounds
        }
    }

    /**
     * Uses the `placeShape()` method in order to add a TrebleClef shape to given `container`. Certain
     * arguments are omitted (e.g., `shapeClass`) since we already know their value. See documentation on
     * `placeShape()`, which is not repeated here.
     */
    public static function placeTrebleClef(container:Sprite,
                                           x:Number, y:Number, stepSize:Number = NaN,
                                           color:uint = 0x000000):Object {

        return placeShape(MusicShapes.TREBLE_CLEF, IntrinsicShapeGeometry.TREBLE_CLEF,
                container, x, y, stepSize, color);
    }

    /**
     * Uses the `placeShape()` method in order to add a BassClef shape to given `container`. Certain
     * arguments are omitted (e.g., `shapeClass`) since we already know their value. See documentation on
     * `placeShape()`, which is not repeated here.
     */
    public static function placeBassClef(container:Sprite,
                                         x:Number, y:Number, stepSize:Number = NaN,
                                         color:uint = 0x000000):Object {

        return placeShape(MusicShapes.BASS_CLEFF, IntrinsicShapeGeometry.BASS_CLEFF,
                container, x, y, stepSize, color);
    }

    /**
     * Uses the `placeShape()` method in order to add a FullNotehead shape to given `container`. Certain
     * arguments are omitted (e.g., `shapeClass`) since we already know their value. See documentation on
     * `placeShape()`, which is not repeated here.
     */
    public static function placeFullNotehead(container:Sprite,
                                             x:Number, y:Number, stepSize:Number = NaN,
                                             color:uint = 0x000000):Object {

        return placeShape(MusicShapes.FULL_NOTEHEAD, IntrinsicShapeGeometry.FULL_NOTEHEAD,
                container, x, y, stepSize, color);
    }

    /**
     * Uses the `placeShape()` method in order to add a Sharp shape to given `container`. Certain
     * arguments are omitted (e.g., `shapeClass`) since we already know their value. See documentation on
     * `placeShape()`, which is not repeated here.
     */
    public static function placeSharp(container:Sprite,
                                      x:Number, y:Number, stepSize:Number = NaN,
                                      color:uint = 0x000000):Object {

        return placeShape(MusicShapes.SHARP_SIGN, IntrinsicShapeGeometry.SHARP_SIGN,
                container, x, y, stepSize, color);
    }

    /**
     * Uses the `placeShape()` method in order to add a Natural shape to given `container`. Certain
     * arguments are omitted (e.g., `shapeClass`) since we already know their value. See documentation on
     * `placeShape()`, which is not repeated here.
     */
    public static function placeNatural(container:Sprite,
                                        x:Number, y:Number, stepSize:Number = NaN,
                                        color:uint = 0x000000):Object {

        return placeShape(MusicShapes.NATURAL_SIGN, IntrinsicShapeGeometry.NATURAL_SIGN,
                container, x, y, stepSize, color);
    }

    /**
     * Uses the `placeShape()` method in order to add a Flat shape to given `container`. Certain
     * arguments are omitted (e.g., `shapeClass`) since we already know their value. See documentation on
     * `placeShape()`, which is not repeated here.
     */
    public static function placeFlat(container:Sprite,
                                     x:Number, y:Number, stepSize:Number = NaN,
                                     color:uint = 0x000000):Object {

        return placeShape(MusicShapes.FLAT_SIGN, IntrinsicShapeGeometry.FLAT_SIGN,
                container, x, y, stepSize, color);
    }

    /**
     * Scales all values in the provided `shapeGeometry` according to given `scaleFactor`. Returns a scaled
     * copy of the original rectangle, which is left untouched.
     *
     * @param   shapeGeometry
     *          Rectangle describing the intrinsic geometry of a shape. See:
     *          `eu.claudius.iacob.constants.IntrinsicShapeGeometry`.
     *
     * @param   scaleFactor
     *          Factor to scale all values inside `shapeGeometry` by.
     *
     * @return  A copy of `shapeGeometry`, with all the values scaled.
     */
    public static function scaleShapeGeometry(shapeGeometry:Rectangle, scaleFactor:Number):Rectangle {
        return new Rectangle(
                shapeGeometry.x * scaleFactor,
                shapeGeometry.y * scaleFactor,
                shapeGeometry.width * scaleFactor,
                shapeGeometry.height * scaleFactor
        );
    }

    /**
     * Computes a scale factor based on given `stepSize`.
     *
     * @param   stepSize
     *          Indirectly controls XY scaling of a shape. See documentation on `placeShape()`, which is not
     *          repeated here.
     *
     * @return  A scale factor as a positive decimal number, e.g., `0.5` means "shrunk by half".
     */
    public static function getScaleForStepSize(stepSize:Number):Number {
        return (stepSize / IntrinsicShapeGeometry.INTRINSIC_STEP_SIZE);
    }

    /**
     * Transforms and returns given `shapeGeometry` based on the provided `stepSize`.
     *
     * @param   shapeGeometry
     *          The shape geometry to transform (upscale or downscale).
     *
     * @param   stepSize
     *          The step size to compute a factor from.
     *
     * @return  The transformed geometry. See documentation on:
     *          - `getScaleForStepSize()`;
     *          - `scaleShapeGeometry()`;
     *          - `placeShape()`;
     */
    public static function measureShape (shapeGeometry : Rectangle, stepSize:Number) : Rectangle {
        var scaleFactor : Number = getScaleForStepSize (stepSize);
        return scaleShapeGeometry (shapeGeometry, scaleFactor);
    }

    /**
     * Rotates a point around a specified origin by a given angle in radians.
     *
     * @param point The point to be rotated.
     * @param origin The point serving as the rotation origin.
     * @param angleInRadians The angle in radians by which to rotate the point.
     *
     * @return A new Point representing the rotated position of the original point.
     */
    public static function rotatePoint(point:Point, origin:Point, angleInRadians:Number):Point {
        var rotatedX:Number = point.x * Math.cos(angleInRadians) - point.y * Math.sin(angleInRadians);
        var rotatedY:Number = point.x * Math.sin(angleInRadians) + point.y * Math.cos(angleInRadians);
        return new Point(rotatedX, rotatedY);
    }

    /**
     * Calculates the minor axis of an ellipse that fits within a specified vertical space when rotated at a given angle.
     *
     * @param verticalSpace The vertical space in pixels where the rotated ellipse needs to fit.
     * @param angleInDegrees The angle of rotation in degrees for the ellipse.
     * @return The minor axis length of the ellipse in pixels.
     */
    public static function calculateMinorAxis(verticalSpace:Number, angleInDegrees:Number):Number {
        // Convert the angle from degrees to radians
        var angleInRadians:Number = angleInDegrees * (Math.PI / 180);

        // Calculate the minor axis using trigonometry
        // The minor axis is half of the vertical space divided by the cosine of the angle
        var minorAxis:Number = verticalSpace / (2 * Math.cos(angleInRadians));
        return minorAxis;
    }


}
}
