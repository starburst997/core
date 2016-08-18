/*
Copyright (c) 2012-2014 Michael Baczynski, http://www.polygonal.de

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

import de.polygonal.core.util.Assert.assert;
import de.polygonal.core.util.ClassTools;

/**
	Entities communicate through messages.
	
	A message object stores the message content.
**/
@:allow(de.polygonal.core.es.EntityMessageQue)
@:allow(de.polygonal.core.es.ObservableEntity)
class EntityMessage
{
	public static var MESSAGE_COUNT(default, null) = 0;
	public static var MAX_ID(default, null) = 0;
	
	static inline function getGroup(msgType:Int) return (msgType - (msgType & (32 - 1))) >> 5;
	
	static function init()
	{
		var meta = haxe.rtti.Meta.getType(EntityMessage);
		
		var s = Type.getClassName(EntityMessage);
		var o:Array<String> = Reflect.field(meta, s);
		if (o == null) return;
		Reflect.deleteField(meta, s);
		
		MESSAGE_COUNT = cast o[0];
		MAX_ID = cast o[1];
		
		#if debug
		var fields = Reflect.fields(meta);
		for (field in fields)
		{
			var cl:Class<Dynamic> = Type.resolveClass(field);
			
			var ids:Array<Int> = Reflect.field(meta, field)[0];
			var names:Array<String> = Reflect.field(meta, field)[1];
			for (i in 0...ids.length)
			{
				assert(Reflect.field(cl, names[i]) == ids[i]);
				#if verbose
				L.d(de.polygonal.Printf.format("%40s -> %s", [Type.getClassName(cl) + ":" + names[i], ids[i]]));
				#end
				_nameLut[ids[i]] = names[i];
			}
		}
		#end
	} 
	
	#if debug
	static var _nameLut = new Array<String>();
	public static function resolveName(messageId:Int):String return _nameLut[messageId];
	public static function isValid(messageId:Int):Bool return _nameLut[messageId] != null;
	#end
	
	public var id(default, null):Int;
	public var data:Dynamic;
	
	public function new(id:Int)
	{
		this.id = id;
	}
}