package eu.claudius.iacob.constants {
import flash.geom.Rectangle;

/**
 * Table of intrinsic music shapes geometry, as Rectangles formatted as follows:
 * - `x`: The `x` coordinate of the shapes anchor point;
 * - `y`: The `y` coordinate of the shapes anchor point;
 * - `width`: The unscaled width of the shape;
 * - `height`: The unscaled height of the shape;
 */
public class IntrinsicShapeGeometry {
    public function IntrinsicShapeGeometry() {
    }

    public static const INTRINSIC_STEP_SIZE:Number = 2.786;

    public static const TREBLE_CLEF:Rectangle = new Rectangle(0, 23.8, 13.996, 38.116);

    public static const BASS_CLEFF:Rectangle = new Rectangle(0, 5.45, 14.508, 17.132);

    public static const FULL_NOTEHEAD:Rectangle = new Rectangle(0, 2.7, 6.517, 5.287);

    public static const SHARP_SIGN = new Rectangle(0, 7.05, 4.878, 13.997);

    public static const NATURAL_SIGN = new Rectangle(0, 7.812, 3.381, 15.492);

    public static const FLAT_SIGN = new Rectangle(0, 8.891, 4.303, 12.111);
}
}
