package eu.claudius.iacob.music.writer.commands {
import eu.claudius.iacob.common.MusicUtils;
import eu.claudius.iacob.constants.Commands;
import eu.claudius.iacob.constants.IntrinsicShapeGeometry;
import eu.claudius.iacob.constants.Keys;
import eu.claudius.iacob.constants.Prefixes;
import eu.claudius.iacob.draw2D.BaseDrawingTools;
import eu.claudius.iacob.music.writer.IScoreContext;

import flash.geom.Point;
import flash.geom.Rectangle;

import ro.ciacob.math.Fraction;
import ro.ciacob.math.IFraction;

public class PutCluster extends AbstractScoreWritingCommand {

    // The last position on a standard 5 lines staff, counting from `0` (underneath the first line, a D in treble clef),
    // is the 10th position (above the last line, an "upper G" in the treble clef).
    private static const LAST_STANDARD_POSITION:uint = 10;

    /**
     * Command to draw a "cluster" on the canvas, i.e., zero, one, or several noteheads positioned on the
     * last defined staff, as to musically represent, respectively, a rest, a note, or a chord. The
     * command only receives musical information and inferences the correct drawing methods to call, and
     * the correct parameters to pass to those methods.
     *
     * @param   duration
     *          IFraction implementor instance representing musical intrinsic duration of the "cluster",
     *          e.g., 1/4 will represent a quarter (aka "quaver"). Specific durations are to be used for
     *          dotted values, e.g., 3/8 will represent a dotted quarter/quaver.
     *
     * @param   midiPitches
     *          Vector of sorted uints, lowest to highest, representing the MIDI pitches that make up this
     *          "cluster". An empty `midiPitches` Vector is a legit value, and will produce a musical rest
     *          of the given `duration`. A `midiPitches` Vector of only one value will produce a note; and a
     *          `midiPitches` Vector of several values will produce a chord. Accidentals will automatically
     *          be added as needed.
     *
     * @param   tieIndices
     *          Optional. Vector of ints denoting which of the existing "cluster" elements tie to the next
     *          of element of same pitch found in the next adjacent cluster, if any should be available.
     *          The values in the `tieIndices` refer to the indices of `midiPitches`, e.g., `0` will indicate
     *          the lowest pitch (the "bass") in the "cluster" ties to the same pitch in the next chord. A
     *          `tieIndices` Vector only containing the value `-1` indicates all cluster elements tie next.
     *          A `tieIndices` Vector containing both `-1` and other positive values (including `0`) ties
     *          everything EXCEPT the positive indices given. An empty `tieIndices` Vector is ignored.
     *
     * NOTE: inside the underlying `params` Number Vector, the content is allocated as follows:
     *  - [0] numerator of `duration` Fraction;
     *  - [1] denominator of `duration` Fraction;
     *  - [2] number of MIDI pitches available, let it be NUM_PITCH;
     *  - [3] number of tie indices available, let it be NUM_TIE;
     *  - [4-n] the actual MIDI pitches; `n` can be computed as 4 + (NUM_PITCH - 1);
     *  - [m-p] the actual tie indices; if NUM_PITCH is `0`, then `m` is `4`; otherwise, it is (`n` + 1);
     *    `p` can be computed as `m` + (NUM_TIE - 1). If NUM_TIE is also `0`, then nothing is written in
     *    `params` past the index `3`.
     */
    public function PutCluster(
            duration:IFraction,
            midiPitches:Vector.<uint>,
            tieIndices:Vector.<int> = null) {

        if (!duration) {
            duration = Fraction.ZERO;
        }

        const params:Vector.<Number> = new Vector.<Number>;
        params.push(duration.numerator, duration.denominator);
        const numMidiPitches:uint = (midiPitches ? midiPitches.length : 0)
        params.push(numMidiPitches);
        const numTieIndices:uint = (tieIndices ? tieIndices.length : 0);
        params.push(numTieIndices);
        var i:int;
        if (numMidiPitches) {
            for (i = 0; i < numMidiPitches; i++) {
                params.push(midiPitches[i]);
            }
        }
        if (numTieIndices) {
            for (i = 0; i < numTieIndices; i++) {
                params.push(numTieIndices[i]);
            }
        }
        super(this, Commands.PUT_CLUSTER, params);
    }

    public function get duration():IFraction {
        return new Fraction(params[0], params[1]);
    }

    public function get midiPitches():Vector.<uint> {
        const pitches:Vector.<uint> = new Vector.<uint>();
        const numMidiPitches:uint = params[2];
        if (numMidiPitches) {
            const start:uint = 4;
            const end:uint = start + (numMidiPitches - 1);
            var i:int;
            for (i = start; i <= end; i++) {
                pitches.push(params[i]);
            }
        }
        return pitches;
    }

    public function get tieIndices():Vector.<int> {
        const ties:Vector.<int> = new Vector.<int>();
        const numTieIndices:uint = params[3];
        if (numTieIndices) {
            const numMidiPitches:uint = params[2];
            const start:uint = (numMidiPitches == 0) ? 4 : 4 + (numMidiPitches - 1) + 1;
            const end:uint = start + (numTieIndices - 1);
            var i:int;
            for (i = start; i <= end; i++) {
                ties.push(params[i]);
            }
        }
        return ties;
    }

    override public function execute(context:IScoreContext = null):Object {
        if (context && context.container && context.$has(Prefixes.STAFF)) {
            var staffBounds:Rectangle = context.$get('bounds', Prefixes.STAFF) as Rectangle;
            var prevObjectBounds:Rectangle = context.$get('bounds') as Rectangle;
            var staffPositions:Array = context.$get('intrinsicPositions', Prefixes.STAFF) as Array;
            var underPosition:Number = context.$get('underPosition', Prefixes.STAFF) as Number;
            var overPosition : Number = context.$get('overPosition',Prefixes.STAFF) as Number;
            var staffStep:Number = context.$get('step', Prefixes.STAFF) as Number;
            var staffLineThickness = context.$get('thickness', Prefixes.STAFF) as Number;
            var hPadding:uint = context.$get(Keys.HORIZONTAL_PADDING, Prefixes.SETTINGS) as uint;

            // An empty cluster is a rest.
            if (!midiPitches.length) {
                // TODO: iplement in a next version
                return null;
            }

            // We need to know the width of individual noteheads types in order to accommodate ledger lines,
            // if any, as those must push notes to the right in order to secure a portion where they are clearly visible.
            var fullNoteheadW:Number = context.$get(Keys.FULL_NOTEHEAD_WIDTH) as Number;
            if (!fullNoteheadW) {
                fullNoteheadW = BaseDrawingTools.measureShape(IntrinsicShapeGeometry.FULL_NOTEHEAD, staffStep).width;
                context.store(fullNoteheadW, Keys.FULL_NOTEHEAD_WIDTH);
            }

            // TODO: obtain general positions offset, based on current clef.
            var positionsOffset:int = 0;

            // We need to separate noteheads horizontally (i.e., to avoid colisions between seconds) and vertically (i.e., on staff, under the staff, or over the staff).
            const PRIMARY_TAG:String = 'primary';
            const SECONDARY_TAG:String = 'secondary';
            const INTRINSIC_TAG:String = 'intrinsic';
            const UNDER_TAG:String = 'under';
            const OVER_TAG:String = 'over';
            var lastPosition:Number = NaN;
            var positionDelta:int = 0;
            var positionsInfo:Array = [];
            var mustShowLedgerLines:Boolean = false;
            var numUpperPositions:uint = 0;
            var numLowerPositions:uint = 0;
            var ledgerPosition:uint = 0;
            for (var i:int = 0; i < midiPitches.length; i++) {
                var midiPitch:uint = midiPitches[i];
                var positionInfo:Object = MusicUtils.midiToPosition(midiPitch);
                var currentPosition:int = (positionInfo.position + positionsOffset);
                var $t = [];
                if (!isNaN(lastPosition)) {
                    positionDelta = Math.abs(currentPosition - lastPosition);
                    if (positionDelta < 2) {
                        $t.push(SECONDARY_TAG);
                    } else {
                        $t.push(PRIMARY_TAG);
                        lastPosition = currentPosition;
                    }
                } else {
                    $t.push(PRIMARY_TAG);
                    lastPosition = currentPosition;
                }
                if (currentPosition < 0) {
                    $t.push(UNDER_TAG);
                    mustShowLedgerLines = true;
                    ledgerPosition = Math.abs(currentPosition);
                    if (ledgerPosition > numLowerPositions) {
                        numLowerPositions = ledgerPosition;
                    }
                } else if (currentPosition > LAST_STANDARD_POSITION) {
                    $t.push(OVER_TAG);
                    mustShowLedgerLines = true;
                    ledgerPosition = (currentPosition - LAST_STANDARD_POSITION);
                    if (ledgerPosition > numUpperPositions) {
                        numUpperPositions = ledgerPosition;
                    }
                } else {
                    $t.push(INTRINSIC_TAG);
                }
                positionInfo.tags = $t;
                positionsInfo.push(positionInfo);
            }

            // By now we should have all the info needed for the actual drawing. We will first draw the ledger lines,
            // if any are needed, and then the notes.
            var ledgerLinesX:Number = prevObjectBounds.right + hPadding;
            var haveTwoColumnsLedger:Boolean;
            var ledgerLinesWidth:Number;
            var numLedgerLines:uint;

            // Draw the ledger lines below, if applicable.
            var ledgerBelowPositions : Array;
            if (mustShowLedgerLines && numLowerPositions) {
                haveTwoColumnsLedger = (positionsInfo.filter(function (item:Object, ...ignore) {
                    var t:Array = item.tags;
                    if (t && t.length && t.indexOf(UNDER_TAG) != -1 && t.indexOf(SECONDARY_TAG) != -1) {
                        return true;
                    }
                    return false;
                }).length > 0);
                ledgerLinesWidth = haveTwoColumnsLedger ? fullNoteheadW * 2.5 : fullNoteheadW * 1.5;
                numLedgerLines = Math.ceil(numLowerPositions / 2);
                var result : Object = BaseDrawingTools.drawStaffLines(context.container, numLedgerLines, ledgerLinesWidth,
                        new Point(ledgerLinesX, underPosition - staffLineThickness / 2));
                ledgerBelowPositions = result.intrinsicPositions;
            }

            // Draw the ledger lines above, if applicable.
            var ledgerAbovePositions : Array;
            if (mustShowLedgerLines && numUpperPositions) {
                haveTwoColumnsLedger = (positionsInfo.filter(function (item:Object, ...ignore) {
                    var t:Array = item.tags;
                    if (t && t.length && t.indexOf(OVER_TAG) != -1 && t.indexOf(SECONDARY_TAG) != -1) {
                        return true;
                    }
                    return false;
                }).length > 0);
                ledgerLinesWidth = haveTwoColumnsLedger ? fullNoteheadW * 2.5 : fullNoteheadW * 1.5;
                numLedgerLines = Math.ceil(numUpperPositions / 2);
                var expectedLedgerHeight : Number = BaseDrawingTools.measureStaff (numLedgerLines);
                var result : Object = BaseDrawingTools.drawStaffLines(context.container, numLedgerLines, ledgerLinesWidth,
                        new Point (ledgerLinesX, overPosition - expectedLedgerHeight + staffLineThickness / 2));
                ledgerAbovePositions = result.intrinsicPositions;
            }

            // Draw the noteheads, in two columns if there is at least one seconds, or in a single column otherwise.
            var noteheadsX:Number = ledgerLinesX + (mustShowLedgerLines ? fullNoteheadW * 0.25 : 0);
            for (var i = 0; i < positionsInfo.length; i++) {
                var positionInfo : Object = positionsInfo[i] as Object;
                var t : Array = positionInfo.tags;
                var isSecondary : Boolean = (t.indexOf(SECONDARY_TAG) != -1);
                var isOver : Boolean = (t.indexOf(OVER_TAG) != -1);
                var isUnder : Boolean = (t.indexOf(UNDER_TAG) != -1);
                var x : Number = isSecondary? noteheadsX + fullNoteheadW : noteheadsX;
                var y : Number = isUnder?
                        ledgerBelowPositions [ledgerBelowPositions.length - 1 + positionInfo.position]: isOver?
                                ledgerAbovePositions [positionInfo.position - LAST_STANDARD_POSITION] :
                                staffPositions[positionInfo.position];
                BaseDrawingTools.placeFullNotehead(context.container, x, y, staffStep);
            }
        }

        // TODO: decide what to return here.
        return null;
    }
}
}
