package eu.claudius.iacob.common {
public class MusicUtils {
    public function MusicUtils() {
    }

    // Chromatic scale, fore reference and debug
    public static const CHROMATIC_SCALE:Vector.<String> = new <String>[
        "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
        ];

    // Define an array that maps MIDI notes to positions
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

    public static const MIDDLE_C_OCTAVE_INDEX : uint = 4;


    public static function midiToPosition(midiNote:uint):Object {

        // Calculate the MIDI note index within the lookup table
        const index:uint = midiNote % 12;
        var matchingNote:String = CHROMATIC_SCALE[index];
        const octaveIndex:int = (midiNote - index) / 12 - 1;

        // "Middle C" is in octave with index"4"
        const offsetToMiddleOctave:int = octaveIndex - MIDDLE_C_OCTAVE_INDEX;

        // There are 7 positions per octave, since each diatonic note takes a different position,
        // and there are 7 diatonic notes.
        const offsetToApply:int = (offsetToMiddleOctave * 7);

        // Retrieve the corresponding position from the table
        const position:int = POSITIONS[index] + offsetToApply;
        return {
            "midiNote": midiNote,
            "matchingNote": matchingNote,
            "octaveIndex": octaveIndex,
            "position": position
        }
    }
}
}
