package eu.claudius.iacob.music.writer.commands {
import eu.claudius.iacob.music.writer.IScoreContext;

/**
 * Baseline definition for an IScoreWritingCommand implementer.
 *
 * A ScoreWritingCommand essentially entails a `type` and an arbitrary number of Numeric parameters
 * (`params`), but subclasses can further develop this typology as needed. It also presents an `execute()`
 * command that is responsible with actually producing the effect that is specific to this particular type of
 * command.
 */
public interface IScoreWritingCommand {
    function get type () : String;
    function get params () : Vector.<Number>;
    function execute (context : IScoreContext = null) : Object;
}
}
