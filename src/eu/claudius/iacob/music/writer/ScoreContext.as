package eu.claudius.iacob.music.writer {
import flash.display.Sprite;

import ro.ciacob.utils.Strings;

public class ScoreContext implements IScoreContext {

    var _container:Sprite;
    var _storage:Object;

    public function ScoreContext(container:Sprite) {
        _container = container;
        _storage = {};
    }

    public function get container():Sprite {
        return _container;
    }

    public function store(payload:Object, prefixOrKey:String = null):void {
        if (payload) {
            prefixOrKey = Strings.trim(prefixOrKey);
            prefixOrKey = prefixOrKey ? (prefixOrKey + '_') : '';
            if (_isPrimitive(payload) && prefixOrKey) {
                _storage[prefixOrKey] = payload;
                return;
            }
            for (var key in payload) {
                _storage[prefixOrKey + key] = payload[key];
            }
        }
    }

    public function $get(key:String, prefix:String = null):Object {
        if (prefix) {
            key = (prefix + '_' + key);
        }
        return _storage[key];
    }

    public function $has(prefixOrKey:String, key:String = null):Boolean {

        // Search by <key>, or by <prefix>_<key>.
        var query:String = [
            Strings.trim(prefixOrKey),
            Strings.trim(key)
        ].join('_');
        if (query in _storage) {
            return true;
        }

        // Enable search by a prefix alone, e.g., "is there any key that begins with <prefix>?"
        for (var key in _storage) {
            if (Strings.beginsWith(key, query)) {
                return true;
            }
        }
        return false;
    }

    private function _isPrimitive(value:*):Boolean {
        return (
                (value is String) ||
                (value is Number) ||
                (value is uint) ||
                (value is int) ||
                (value is Boolean)
        );
    }
}
}
