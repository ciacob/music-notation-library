package eu.claudius.iacob.common {
import eu.claudius.iacob.constants.ClefTypes;
import eu.claudius.iacob.constants.CleffOffsets;

import flash.geom.Rectangle;

/**
 * A utility class for music-related operations.
 */
public class MusicUtils {

    /**
     * Constructor for the MusicUtils class.
     */
    public function MusicUtils() {
    }

    /**
     * An array representing the chromatic scale for reference and debugging purposes.
     * It contains note names from C to B, while using SHARPS.
     */
    public static const CHROMATIC_SCALE:Vector.<String> = new <String>[
        "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
    ];

    /**
     * An array representing the chromatic scale for reference and debugging purposes.
     * It contains note names from C to B, while using FLATS.
     */
    public static const CHROMATIC_SCALE_ALTERNATE:Vector.<String> = new <String>[
        "C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"
    ];

    /**
     * An Array representing disposition of black keys (aka "chromatic" keys in this context)
     * on a modern music keyboard. ZEROS mean white/diatonic keys, while ONES mean black/chromatic
     * keys.
     */
    public static const CHROMATIC_MAP:Vector.<uint> = new <uint> [
        0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0
    ];

    /**
     * An array that maps MIDI notes to positions within a staff.
     */
    public static const POSITIONS:Vector.<int> = new <int>[
        -1, // C
        -1, // C#
        0, // D
        0, // D#
        1, // E
        2, // F
        2, // F#
        3, // G
        3, // G#
        4, // A
        4, // A#
        5 // B
    ];

    /**
     * The index of the middle C octave, which is used as a reference point.
     */
    public static const MIDDLE_C_OCTAVE_INDEX:uint = 4;

    /**
     * Generates all possible spellings for the given MIDI pitches using both sharp and flat notations.
     *
     * @param midiPitches - An array of MIDI pitches (an integer array representing musical notes).
     * @return An array of arrays containing all possible spellings for the input MIDI pitches.
     *         Each inner array represents one possible spelling, and the outer array contains all
     *         such spellings.
     */
    public static function getSpellings(midiPitches:Array):Array {
        var spellings:Array = [];

        for each (var midiNote:uint in midiPitches) {
            // Calculate the MIDI note index within the lookup table
            const index:uint = midiNote % 12;

            // Get the note name from both chromatic scales
            const sharpNote:String = CHROMATIC_SCALE[index];
            const flatNote:String = CHROMATIC_SCALE_ALTERNATE[index];

            // Create an array with unique spellings
            const noteSpellings:Array = [sharpNote];
            if (sharpNote !== flatNote) {
                noteSpellings.push(flatNote);
            }

            // Add noteSpellings to the spellings array
            spellings.push(noteSpellings);
        }

        // Create all possible combinations of spellings
        var result:Array = _combineSpellings(spellings);
        return result;
    }

    /**
     * Converts a MIDI note to its position on a musical staff.
     *
     * @param midiNote The MIDI note value to convert.
     * @param clefType The type of clef (e.g., ClefTypes.BASS, ClefTypes.TREBLE).
     * @return An Object containing the following properties:
     * - midiNote: The original MIDI note value.
     * - matchingNote: The corresponding diatonic note (e.g., "white key", such as "C", "D", "G", etc).
     * - octaveIndex: The index of the octave that the note belongs to (e.g., 4 for Middle C).
     * - position: The position of the note on the musical staff based on the specified clef.
     */
    public static function midiToPosition(midiNote:uint, clefType:int):Object {

        // Calculate the MIDI note index within the lookup table
        const index:uint = midiNote % 12;
        var matchingNote:String = CHROMATIC_SCALE[index];
        const octaveIndex:int = (midiNote - index) / 12 - 1;
        const isBlackKey:Boolean = !!CHROMATIC_MAP[index];

        // "Middle C" is in octave with index "4"
        const deltaToMiddleOctave:int = octaveIndex - MIDDLE_C_OCTAVE_INDEX;

        // There are 7 positions per octave, since each diatonic note takes a different position,
        // and there are 7 diatonic notes.
        const intrinsicOffset:int = (deltaToMiddleOctave * 7);

        // Also, the current clef will render the "Middle C" upper or lower, and carries its own offset.
        var cleffOffset:int = 0;
        switch (clefType) {
            case ClefTypes.BASS:
                cleffOffset = CleffOffsets.BASS;
                break;
            case ClefTypes.TREBLE:
            default:
                cleffOffset = CleffOffsets.TREBLE;
                break;
        }

        // Retrieve the corresponding position from the table
        const position:int = POSITIONS[index] + intrinsicOffset + cleffOffset;

        return {
            "midiNote": midiNote,
            "matchingNote": matchingNote,
            "octaveIndex": octaveIndex,
            "position": position,
            "isBlackKey": isBlackKey
        }
    }

    /**
     * Generates all possible combinations of spellings for the given notes using a recursive approach.
     *
     * @param spellings - An array of arrays containing possible spellings for each note.
     * @return An array of arrays containing all possible combinations of spellings for the given notes.
     */
    private static function _combineSpellings(spellings:Array):Array {
        if (spellings.length == 0) {
            return [];
        }
        var firstSpelling:Array = spellings[0];
        var restSpellings:Array = spellings.slice(1);
        var combined:Array = [];
        for each (var note:String in firstSpelling) {
            var restCombinations:Array = _combineSpellings(restSpellings);
            for each (var combination:Array in restCombinations) {
                combined.push([note].concat(combination));
            }
        }
        return combined;
    }

    /**
     * Checks and left-shifts the current rectangle to avoid intersections with other rectangles. Used
     * mainly for positioning accidental, but rather agnostic otherwise.
     *
     * @param currRectangle The current rectangle to be checked and shifted.
     * @param otherRectangles An array of other rectangles to check for intersections.
     * @param padding The amount of padding to apply when shifting the rectangle (default is 5).
     */
    public static function leftShiftAsNeeded(currRectangle:Rectangle, otherRectangles:Vector.<Rectangle>, padding:int = 5):void {
        var intersects:Boolean = false;

        // Continue checking for intersections until no more intersections are found
        while (true) {
            intersects = false; // Reset the flag

            // Check for intersections with all other rectangles
            for each (var otherRect:Rectangle in otherRectangles) {
                if (currRectangle.intersects(otherRect)) {
                    intersects = true;
                    break; // No need to check further if there's an intersection
                }
            }

            // If intersection is found, slide the current rectangle to the left
            if (intersects) {
                currRectangle.x -= currRectangle.width + padding;
            } else {
                // No intersections found, exit the loop
                break;
            }
        }
    }

}
}