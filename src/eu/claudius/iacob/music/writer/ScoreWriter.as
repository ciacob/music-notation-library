package eu.claudius.iacob.music.writer {
import eu.claudius.iacob.constants.Prefixes;
import eu.claudius.iacob.music.writer.commands.IScoreWritingCommand;

import flash.display.Graphics;

import flash.display.Sprite;
import flash.geom.Rectangle;

public class ScoreWriter {


    private var _container:Sprite;
    private var _context:IScoreContext;
    private var _commands:Vector.<IScoreWritingCommand>;

    public function ScoreWriter(container:Sprite,
                                settings:Object = null,
                                controller:IScoreController = null) {
        _container = container;
        _commands = new Vector.<IScoreWritingCommand>;
        _context = new ScoreContext(container);
        if (settings) {
            _context.store(settings, Prefixes.SETTINGS);
        }
    }

    public function addCommand(command:IScoreWritingCommand):void {
        _commands.push(command);
    }

    public function write():void {
        var numCommands:uint = _commands.length;
        _context.store(numCommands, Prefixes.NUM_COMMANDS);
        for (var i:int = 0; i < numCommands; i++) {
            _context.store(i, Prefixes.COMMAND_INDEX);
            var cmd:IScoreWritingCommand = _commands[i];
            var volatilePayload : Object = cmd.execute(_context);

            // [DEBUG]
            if (volatilePayload) {
                var g:Graphics = _container.graphics;
                g.lineStyle(2, 0xff0000);
                var bounds:Rectangle = (volatilePayload.bounds as Rectangle);
                g.drawRect(bounds.x, bounds.y, bounds.width, bounds.height);
            }
            // [/DEBUG]

            _context.store(volatilePayload);
        }
    }

    public function wipeOut():void {
        _context = new ScoreContext(_container);
        _container.graphics.clear();
        while (_container.numChildren) {
            _container.removeChildAt(0);
        }
        // TODO: recycle elements rather than letting them be garbage collected.
    }
}
}
