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
package de.polygonal.core.es;

#if log
import de.polygonal.core.log.Log;
import de.polygonal.sys.LogSystem;
class L
{
	static var _log:Log;
	public static var log(get, never):Log;
	static function get_log():Log
	{
		if (_log == null) _log = LogSystem.getLog("es", true);
		return _log;
	}
	
	public static inline function v(msg:Dynamic, ?tag:String, ?posInfos:haxe.PosInfos) log.v(msg, tag, posInfos);
	public static inline function d(msg:Dynamic, ?tag:String, ?posInfos:haxe.PosInfos) log.d(msg, tag, posInfos);
	public static inline function i(msg:Dynamic, ?tag:String, ?posInfos:haxe.PosInfos) log.i(msg, tag, posInfos);
	public static inline function w(msg:Dynamic, ?tag:String, ?posInfos:haxe.PosInfos) log.w(msg, tag, posInfos);
	public static inline function e(msg:Dynamic, ?tag:String, ?posInfos:haxe.PosInfos) log.e(msg, tag, posInfos);
}
#else
class L
{
	@:extern public static inline function v(x:Dynamic, ?tag:String) {}
	@:extern public static inline function d(x:Dynamic, ?tag:String) {}
	@:extern public static inline function i(x:Dynamic, ?tag:String) {}
	@:extern public static inline function w(x:Dynamic, ?tag:String) {}
	@:extern public static inline function e(x:Dynamic, ?tag:String) {}
}
#end