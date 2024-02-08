package eu.claudius.iacob.music.writer {
import eu.claudius.iacob.constants.Prefixes;
import eu.claudius.iacob.music.writer.commands.IScoreWritingCommand;
import eu.claudius.iacob.music.writer.commands.PutClef;
import eu.claudius.iacob.music.writer.commands.PutCluster;
import eu.claudius.iacob.music.writer.commands.PutStaff;

import flash.display.Graphics;

import flash.display.Sprite;
import flash.geom.Rectangle;

import ro.ciacob.math.IFraction;

public class ScoreWriter {

    private var _container:Sprite;
    private var _context:IScoreContext;
    private var _commands:Vector.<IScoreWritingCommand>;
    private var _controller:IScoreController;
    private var _settings : Object;

    public function ScoreWriter(container:Sprite,
                                settings:Object = null,
                                controller:IScoreController = null) {
        _container = container;
        _settings = settings;
        _controller = controller;
        _commands = new Vector.<IScoreWritingCommand>;
        _context = new ScoreContext(container);
        if (_settings) {
            _context.store(_settings, Prefixes.SETTINGS);
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
            //if (volatilePayload) {
            //    try {
            //        var g:Graphics = _container.graphics;
            //        g.lineStyle(2, 0xff0000);
            //        var bounds:Rectangle = (volatilePayload.bounds as Rectangle);
            //        g.drawRect(bounds.x, bounds.y, bounds.width, bounds.height);
            //    } catch (e : Error) {
            //        trace(e, '\n', e.getStackTrace());
            //    }
            //}
            // [/DEBUG]

            _context.store(volatilePayload);
        }
    }

    public function wipeOut():void {
        _commands.length = 0;
        _context = new ScoreContext(_container);
        if (_settings) {
            _context.store(_settings, Prefixes.SETTINGS);
        }
        _container.graphics.clear();
        while (_container.numChildren) {
            _container.removeChildAt(0);
        }
        // TODO: recycle elements rather than letting them be garbage collected.
    }


    // -----------------------------------
    // WRAPPERS, TO SPEED UP SCORE WRITING
    // -----------------------------------

    public function putStaff(width:Number, x:Number, y:Number):ScoreWriter {
        var command:PutStaff = new PutStaff(width, x, y);
        addCommand(command);
        return this;
    }

    public function putClef(clefType:int):ScoreWriter {
        var command:PutClef = new PutClef(clefType);
        addCommand(command);
        return this;
    }

    public function putCluster(duration:IFraction, midiPitches:Vector.<uint>, tieIndices:Vector.<int> = null):ScoreWriter {
        var command:PutCluster = new PutCluster(duration, midiPitches, tieIndices);
        addCommand(command);
        return this;
    }
}
}
