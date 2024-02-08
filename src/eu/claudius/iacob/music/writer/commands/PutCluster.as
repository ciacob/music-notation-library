package eu.claudius.iacob.music.writer.commands {
import eu.claudius.iacob.common.MusicUtils;
import eu.claudius.iacob.constants.AccidentalTypes;
import eu.claudius.iacob.constants.ClefTypes;
import eu.claudius.iacob.constants.Commands;
import eu.claudius.iacob.constants.IntrinsicShapeGeometry;
import eu.claudius.iacob.constants.Keys;
import eu.claudius.iacob.constants.Prefixes;
import eu.claudius.iacob.draw2D.BaseDrawingTools;
import eu.claudius.iacob.music.writer.IScoreContext;

import flash.display.Shape;
import flash.display.Sprite;
import flash.geom.Point;
import flash.geom.Rectangle;

import ro.ciacob.math.Fraction;
import ro.ciacob.math.IFraction;

public class PutCluster extends AbstractScoreWritingCommand {

    // The last position on a standard 5 lines staff, counting from `0` (underneath the first line, a D in treble clef),
    // is the 10th position (above the last line, an "upper G" in the treble clef).
    private static const LAST_STANDARD_POSITION:uint = 10;

    // Storage for the resulting bounds of the noteheads, upper and/or lower ledger lines, if applicable,
    // and accidentals (also if applicable).
    private var _compositeBounds:Rectangle;

    // Storage for the individual bounds of the noteheads, ledger lines, accidentals.
    private var _individualBounds:Vector.<Rectangle>;

    /**
     * Registers a Rectangle of an individual Shape placed or drawn as part of this cluster (e.g., noteheads,
     * upper and/or lower ledger lines, accidentals, whichever applicable. The Rectangle is both stored
     * individually and merged into a resulting, larger boundary (see `_compositeBounds`).
     *
     * @param   bounds
     *          Rectangle of an individual Shape to be stored.
     */
    private function _storeIndividualBounds(bounds:Rectangle):void {
        if (!_compositeBounds) {
            _compositeBounds = bounds.clone();
        } else {
            _compositeBounds = _compositeBounds.union(bounds);
        }
        if (!_individualBounds) {
            _individualBounds = new Vector.<Rectangle>();
        }
        _individualBounds.push(bounds);
    }

    /**
     * Removes duplicate values from a Vector of uints, keeping the first occurrence of each unique value.
     *
     * @param   source
     *          The Vector of uints from which duplicates should be removed.
     *
     * @return  A Vector of uints with duplicate values removed, maintaining the order of the first occurrences.
     */
    private function _removeDuplicates(source:Vector.<uint>):Vector.<uint> {
        const uniquePitches:Vector.<uint> = new Vector.<uint>();
        const encounteredPitches:Object = {};
        for each (var pitch:uint in source) {
            if (!encounteredPitches[pitch]) {
                uniquePitches.push(pitch);
                encounteredPitches[pitch] = true;
            }
        }
        return uniquePitches;
    }

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

        // Filter out duplicate MIDI pitches and sort them from lowest to highest.
        midiPitches = _removeDuplicates(midiPitches);
        midiPitches.sort(function (pitchA:uint, pitchB:uint):int {
            return (pitchA - pitchB)
        });

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

    /**
     * Retrieves the musical intrinsic duration of the cluster.
     *
     * @return An IFraction implementor instance representing the musical intrinsic duration of the cluster.
     */
    public function get duration():IFraction {
        return new Fraction(params[0], params[1]);
    }

    /**
     * Retrieves the MIDI pitches that make up this cluster.
     *
     * @return A Vector of sorted uints, lowest to highest, representing the MIDI pitches that make up this cluster.
     */
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

    /**
     * Retrieves the tie indices denoting which elements of the cluster tie to the next adjacent cluster.
     *
     * @return A Vector of ints denoting which elements of the cluster tie to the next adjacent cluster.
     */
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

    /**
     * Executes the PutCluster command, drawing the cluster components on the canvas.
     *
     * @param   context
     *          The IScoreContext instance representing the context in which the cluster is drawn.
     *
     * @return  An object containing the resulting bounds of the cluster components.
     */
    override public function execute(context:IScoreContext = null):Object {
        if (context && context.container && context.$has(Prefixes.STAFF)) {

            var prevObjectBounds:Rectangle = context.$get('bounds') as Rectangle;
            var staffPositions:Array = context.$get('intrinsicPositions', Prefixes.STAFF) as Array;
            var underPosition:Number = context.$get('underPosition', Prefixes.STAFF) as Number;
            var overPosition:Number = context.$get('overPosition', Prefixes.STAFF) as Number;
            var staffStep:Number = context.$get('step', Prefixes.STAFF) as Number;
            var staffLineThickness:uint = context.$get('thickness', Prefixes.STAFF) as Number;
            var hPadding:uint = context.$get(Keys.HORIZONTAL_PADDING, Prefixes.SETTINGS) as uint;
            var iPadding:uint = context.$get(Keys.INNER_CLUSTER_PADDING, Prefixes.SETTINGS) as uint;
            var clefType:int = (context.$get(Keys.CLEF_TYPE, Prefixes.CLEFF) as int) || ClefTypes.TREBLE;

            var isOver:Boolean;
            var isUnder:Boolean;
            var x:Number;
            var y:Number;
            var tags:Array;
            var accidentalInducedOffset:Number;

            // An empty cluster is a rest.
            if (!midiPitches.length) {
                // TODO: implement in a next version
                return null;
            }

            // We need to know the width of individual noteheads types in order to accommodate
            // ledger lines, if any, as those must push notes to the right in order to secure a
            // portion where they are clearly visible.
            var fullNoteheadW:Number = context.$get(Keys.FULL_NOTEHEAD_WIDTH) as Number;
            if (!fullNoteheadW) {
                fullNoteheadW = BaseDrawingTools.measureShape(IntrinsicShapeGeometry.FULL_NOTEHEAD, staffStep).width;
                context.store(fullNoteheadW, Keys.FULL_NOTEHEAD_WIDTH);
            }

            // We need to separate noteheads horizontally (i.e., to avoid collisions between
            // seconds) and vertically (i.e., on staff, under the staff, or over the staff). We
            // also need to account for accidentals, as these will push both notes and ledger lines
            // to the right.
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
            var i:int;
            var positionInfo:Object;
            var midiPitch:uint;
            var currentPosition:int;
            for (i = 0; i < midiPitches.length; i++) {
                midiPitch = midiPitches[i];
                positionInfo = MusicUtils.midiToPosition(midiPitch, clefType);
                currentPosition = positionInfo.position;
                tags = [];
                if (!isNaN(lastPosition)) {
                    positionDelta = Math.abs(currentPosition - lastPosition);
                    if (positionDelta < 2) {
                        tags.push(SECONDARY_TAG);
                    } else {
                        tags.push(PRIMARY_TAG);
                        lastPosition = currentPosition;
                    }
                } else {
                    tags.push(PRIMARY_TAG);
                    lastPosition = currentPosition;
                }
                if (currentPosition < 0) {
                    tags.push(UNDER_TAG);
                    mustShowLedgerLines = true;
                    ledgerPosition = Math.abs(currentPosition);
                    if (ledgerPosition > numLowerPositions) {
                        numLowerPositions = ledgerPosition;
                    }
                } else if (currentPosition > LAST_STANDARD_POSITION) {
                    tags.push(OVER_TAG);
                    mustShowLedgerLines = true;
                    ledgerPosition = (currentPosition - LAST_STANDARD_POSITION);
                    if (ledgerPosition > numUpperPositions) {
                        numUpperPositions = ledgerPosition;
                    }
                } else {
                    tags.push(INTRINSIC_TAG);
                }
                positionInfo.tags = tags;
                positionsInfo.push(positionInfo);
            }

            // By now we should have all the info needed for the actual drawing. We will first draw
            // the ledger lines, if any are needed, then the accidentals, if any is needed, and
            // then the notes.
            var noteInitialX:Number = prevObjectBounds.right + hPadding;
            var haveWideLedger:Boolean;
            var ledgerWidth:Number;
            var numLedgerLines:uint;
            var result:Object;

            // Draw the ledger lines below, if applicable.
            var ledgerBelowPositions:Array;
            var ledgerBelowShape:Shape;
            var ledgerBelowBounds:Rectangle;
            if (mustShowLedgerLines && numLowerPositions) {
                haveWideLedger = (positionsInfo.filter(function (item:Object, ...ignore):Boolean {
                    tags = item.tags;
                    return !!(tags && tags.length && tags.indexOf(UNDER_TAG) != -1 && tags.indexOf(SECONDARY_TAG) != -1);

                }).length > 0);
                ledgerWidth = haveWideLedger ? fullNoteheadW * 2.5 : fullNoteheadW * 1.5;
                numLedgerLines = Math.ceil(numLowerPositions / 2);
                result = BaseDrawingTools.drawStaffLines(context.container, numLedgerLines, ledgerWidth,
                        new Point(noteInitialX, underPosition - staffLineThickness / 2));
                ledgerBelowShape = result.shape;
                ledgerBelowBounds = result.bounds;
                ledgerBelowPositions = result.intrinsicPositions;
            }

            // Draw the ledger lines above, if applicable.
            var ledgerAbovePositions:Array;
            var ledgerAboveShape:Shape;
            var ledgerAboveBounds:Rectangle;
            if (mustShowLedgerLines && numUpperPositions) {
                haveWideLedger = (positionsInfo.filter(function (item:Object, ...ignore):Boolean {
                    tags = item.tags;
                    return !!(tags && tags.length && tags.indexOf(OVER_TAG) != -1 && tags.indexOf(SECONDARY_TAG) != -1);

                }).length > 0);
                ledgerWidth = haveWideLedger ? fullNoteheadW * 2.5 : fullNoteheadW * 1.5;
                numLedgerLines = Math.ceil(numUpperPositions / 2);
                var expectedLedgerHeight:Number = BaseDrawingTools.measureStaff(numLedgerLines);
                result = BaseDrawingTools.drawStaffLines(context.container, numLedgerLines, ledgerWidth,
                        new Point(noteInitialX, overPosition - expectedLedgerHeight + staffLineThickness / 2));
                ledgerAboveShape = result.shape;
                ledgerAboveBounds = result.bounds;
                ledgerAbovePositions = result.intrinsicPositions;
            }

            // Draw the accidentals, if applicable
            accidentalInducedOffset = 0;
            var accidentalInitialX:Number = prevObjectBounds.right + hPadding;
            var accidentalEffectiveX:Number = accidentalInitialX;
            var accidentalBounds:Vector.<Rectangle> = new Vector.<Rectangle>;
            var accidentalShapes:Vector.<Sprite> = new Vector.<Sprite>;
            var accidentalPitches:Array = positionsInfo.filter(function (item:Object, ...ignore):Boolean {
                return item.isBlackKey;
            });

            // Handle corner-case: minor second made of same-pitch class notes, e.g., C and C#. One
            // SHARP and one NATURAL accidental should be displayed adjacent to each other in this
            // situation, in front of the double headed C pitch. The natural will be closest to the
            // note.
            var forcedNaturals:Array = positionsInfo.filter(function (item:Object, i:int, p:Array):Boolean {
                if (p[i + 1] && !item.isBlackKey && p[i + 1].pitchClass == item.pitchClass) {
                    item.accidentalType = AccidentalTypes.NATURAL;
                    return true;
                }
                return false;
            });
            if (forcedNaturals.length) {
                accidentalPitches = accidentalPitches.concat(forcedNaturals);
            }

            // It is common practice to draw accidentals from the highest pitched to the lowest,
            // so that, if any relocation is needed in order to avoid collisions, the highest
            // accidentals are closest to the noteheads.
            accidentalPitches.reverse();
            var accidentalResult:Object;
            for (i = 0; i < accidentalPitches.length; i++) {
                var accidentalPitch:Object = accidentalPitches[i];
                tags = (accidentalPitch.tags as Array);
                isOver = (tags.indexOf(OVER_TAG) != -1);
                isUnder = (tags.indexOf(UNDER_TAG) != -1);
                x = accidentalInitialX;
                y = isUnder ?
                        ledgerBelowPositions [ledgerBelowPositions.length - 1 + accidentalPitch.position] : isOver ?
                                ledgerAbovePositions [accidentalPitch.position - LAST_STANDARD_POSITION] :
                                staffPositions[accidentalPitch.position];

                // Initially draw the accidental at the horizontal position where the noteheads would
                // normally be drawn.
                var fn:Function;
                switch (accidentalPitch.accidentalType) {
                    case AccidentalTypes.SHARP:
                        fn = BaseDrawingTools.placeSharp;
                        break;
                    case AccidentalTypes.FLAT:
                        fn = BaseDrawingTools.placeFlat;
                        break;
                    case AccidentalTypes.NATURAL:
                        fn = BaseDrawingTools.placeNatural;
                        break;
                }
                if (!fn) {
                    continue;
                }
                accidentalResult = fn(context.container, x, y, staffStep);
                var currAccidentalShape:Sprite = (accidentalResult.shape as Sprite);
                var currBounds:Rectangle = (accidentalResult.bounds);

                // Right-align the accidental; this will give common ground to different types of
                // accidentals, such as sharps, naturals and flats, which have various widths. This way,
                // there will be a common gap between the accidental and the following notehead, regardless
                // of its type (and, therefore, width).
                currBounds.x -= currBounds.width;
                currAccidentalShape.x = currBounds.x;

                // Keep horizontally offsetting the accidentals in respect to each other (to the left,
                // repeatedly, as needed) so that they do not collide; once they've reached equilibrium,
                // shift them right in bloc, and move the already drawn ledger lines (if applicable to
                // their right); draw the noteheads in relation to the moved ledger lines thereafter.
                MusicUtils.leftShiftAsNeeded(currBounds, accidentalBounds, iPadding);
                currAccidentalShape.x = currBounds.x;
                if (currBounds.x < accidentalEffectiveX) {
                    accidentalEffectiveX = currBounds.x;
                }
                accidentalBounds.push(currBounds as Rectangle);
                accidentalShapes.push(currAccidentalShape);
            }

            // Note: by now, `accidentalEffectiveX` should always be "less than" `accidentalsInitialX`,
            // at the very least by the accidental own width (since we right-aligned the accidental
            // to its initial X position).
            accidentalInducedOffset = (accidentalInitialX - accidentalEffectiveX);
            for (i = 0; i < accidentalShapes.length; i++) {
                currAccidentalShape = accidentalShapes[i];
                currAccidentalShape.x += accidentalInducedOffset;
                currBounds = accidentalBounds[i];
                currBounds.x += accidentalInducedOffset;
                _storeIndividualBounds(currBounds);
            }

            // If we drew any accidentals, make amendments to the symbols following them
            // (ledger lines, if any, and noteheads).
            if (accidentalPitches.length > 0) {

                // Add a padding between accidentals and noteheads.
                accidentalInducedOffset += iPadding;

                // If we have ledger lines, move them to the right to accommodate the accidentals.
                if (ledgerBelowShape) {
                    ledgerBelowShape.x += accidentalInducedOffset;
                    ledgerBelowBounds.x += accidentalInducedOffset;
                }
                if (ledgerAboveShape) {
                    ledgerAboveShape.x += accidentalInducedOffset;
                    ledgerAboveBounds.x += accidentalInducedOffset;
                }

                // Shift noteheads start position to the right, to account for all accidentals.
                noteInitialX += accidentalInducedOffset;
            }

            // Record ledger lines horizontal position only at this point, so that it accounts for
            // the horizontal offset induced by accidentals, if applicable.
            if (ledgerBelowBounds) {
                _storeIndividualBounds(ledgerBelowBounds);
            }
            if (ledgerAboveBounds) {
                _storeIndividualBounds(ledgerAboveBounds);
            }

            // Draw the noteheads, in two columns if there is at least one seconds, or in a single column
            // otherwise.
            var noteheadsX:Number = noteInitialX + (mustShowLedgerLines ? fullNoteheadW * 0.25 : 0);
            for (i = 0; i < positionsInfo.length; i++) {
                positionInfo = positionsInfo[i] as Object;
                tags = positionInfo.tags;
                var isSecondary:Boolean = (tags.indexOf(SECONDARY_TAG) != -1);
                isOver = (tags.indexOf(OVER_TAG) != -1);
                isUnder = (tags.indexOf(UNDER_TAG) != -1);
                x = isSecondary ? noteheadsX + fullNoteheadW : noteheadsX;
                y = isUnder ?
                        ledgerBelowPositions [ledgerBelowPositions.length - 1 + positionInfo.position] : isOver ?
                                ledgerAbovePositions [positionInfo.position - LAST_STANDARD_POSITION] :
                                staffPositions[positionInfo.position];
                result = BaseDrawingTools.placeFullNotehead(context.container, x, y, staffStep);
                _storeIndividualBounds(result.bounds);
            }
        }

        // Returning the composite bounds, so that next drawing operations will know to start drawing from
        // the right edge of this cluster (i.e., not overlap it).
        return {
            bounds: _compositeBounds
        };
    }
}
}
