package eu.claudius.iacob.music.writer.commands {
import eu.claudius.iacob.music.writer.IScoreContext;

import flash.errors.IllegalOperationError;

public class AbstractScoreWritingCommand  implements IScoreWritingCommand {

    private var _type : String;
    private var _params : Vector.<Number>;
    public function AbstractScoreWritingCommand (
            subclass : AbstractScoreWritingCommand,
            type : String,
            params : Vector.<Number>) {

        if (!subclass) {
            throw (new IllegalOperationError('Class is abstract and cannot be initialized directly.'));
            return;
        }

        _type = type;
        _params = params;
    }

    public function get type () : String {
        return _type;
    }

    public function get params () : Vector.<Number> {
        return _params;
    }

    public function execute (context : IScoreContext = null) : Object {
        throw (new IllegalOperationError('You must override this method in your subclass.'));
    }
}
}
