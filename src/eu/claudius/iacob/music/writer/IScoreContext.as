package eu.claudius.iacob.music.writer {
import flash.display.Sprite;

/**
 * Interface all score contexts must use. A "score context" is a data structure enabling to package
 * volatile information about the current state of a ScoreWriter. Some score writing commands will need
 * more data in order to perform their task tan mere parameters, and an IScoreContext implementor is the
 * perfect container to pass such data.
 */
public interface IScoreContext {
    function get container () : Sprite;

    function store (payload : Object, prefixOrKey : String = null) : void;

    function $get (key : String,  prefix : String = null) : Object;

    function $has (prefixOrKey : String, key : String = null) : Boolean;
}
}
