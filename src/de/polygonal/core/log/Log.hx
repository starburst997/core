/*
Copyright (c) 2016 Michael Baczynski, http://www.polygonal.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package de.polygonal.core.log;

import de.polygonal.core.log.LogLevel;
import de.polygonal.ds.Sll;
import de.polygonal.ds.tools.Bits;

/**
	A simple, lightweight log.
	
	Messages are passed to registered `LogHandler` objects.
**/
class Log
{
	public var name(default, null):String;
	
	public var inclTag:EReg = null;
	public var exclTag:EReg = null;
	
	/**
		The log `level` for controlling logging output.
		Enabling logging at a given level also enables logging at all higher levels.
	**/
	public var level(get, set):LogLevel;
	function get_level():LogLevel return mLevel;
	function set_level(value:LogLevel):LogLevel
	{
		mLevel = value;
		if (value == Off)
			mMask = 0;
		else
			mMask = Bits.mask(LogLevel.getConstructors().length) & ~Bits.mask(value.getIndex());
		return value;
	}
	
	var mHandlers:Sll<LogHandler>;
	var mLevel:LogLevel;
	var mMask:Int;
	
	public function new(name:String)
	{
		this.name = name;
		mHandlers = new Sll<LogHandler>();
		mLevel = Debug;
		mMask = 1 << mLevel.getIndex();
	}
	
	public function addHandler(handler:LogHandler)
	{
		if (mHandlers.contains(handler)) return;
		mHandlers.add(handler);
	}
	
	public function removeHandler(handler:LogHandler)
	{
		mHandlers.remove(handler);
	}
	
	public function getHandler():Array<LogHandler>
	{
		return Lambda.array(mHandlers);
	}
	
	/**
		Logs a `LogLevel.VERBOSE` message.
	**/
	public function v(msg:String, ?tag:String, ?posInfos:haxe.PosInfos)
	{
		if (mMask & (1 << Verbose.getIndex()) > 0) output(Verbose, msg, tag, posInfos);
	}
	
	/**
		Logs a `LogLevel.DEBUG` message.
	**/
	public function d(msg:String, ?tag:String, ?posInfos:haxe.PosInfos)
	{
		if (mMask & (1 << Debug.getIndex()) > 0) output(Debug, msg, tag, posInfos);
	}
	
	/**
		Logs a `LogLevel.INFO` message.
	**/
	public function i(msg:String, ?tag:String, ?posInfos:haxe.PosInfos)
	{
		if (mMask & (1 << Info.getIndex()) > 0) output(Info, msg, tag, posInfos);
	}
	
	/**
		Logs a `LogLevel.WARN` message.
	**/
	public function w(msg:String, ?tag:String, ?posInfos:haxe.PosInfos)
	{
		if (mMask & (1 << Warn.getIndex()) > 0) output(Warn, msg, tag, posInfos);
	}
	
	/**
		Logs a `LogLevel.ERROR` message.
	**/
	public function e(msg:String, ?tag:String, ?posInfos:haxe.PosInfos)
	{
		if (mMask & (1 << Error.getIndex()) > 0) output(Error, msg, tag, posInfos);
	}
	
	function output(lvl:LogLevel, msg:String, tag:String, ?posInfos:haxe.PosInfos)
	{
		if (mHandlers.isEmpty()) return;
		if (inclTag != null && !inclTag.match(tag)) return;
		if (exclTag != null &&  exclTag.match(tag)) return;
		var n = mHandlers.head;
		var message = new LogMessage(this, lvl, msg, tag, posInfos);
		while (n != null)
		{
			var next = n.next;
			n.val.onMessage(message);
			n = next;
		}
	}
}