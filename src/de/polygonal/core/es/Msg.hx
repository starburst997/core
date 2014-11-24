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

/**
	Entities communicate through messages. A message object therefore stores the message content.
**/
@:build(de.polygonal.core.es.MsgMacro.addMeta())
@:build(de.polygonal.core.macro.IntEnum.build([I, F, B, S, O, USED], true, false))
@:allow(de.polygonal.core.es.MsgQue)
class Msg
{
	public static function name(type:Int):String
	{
		var meta = haxe.rtti.Meta.getType(Msg);
		
		if (meta.names.length == 0) return 'unknown type ($type)';
		
		var names = meta.names[0];
		if (type < 0 || type > names.length - 1) return 'unknown type ($type)';
		return meta.names[0][type];
	}
	
	public static function totalMessages():Int
	{
		var meta = haxe.rtti.Meta.getType(Msg);
		return Std.parseInt(meta.count[0]);
	}
	
	@:noCompletion var mInt:Int;
	@:noCompletion var mFloat:Float;
	@:noCompletion var mBool:Bool;
	@:noCompletion var mString:String;
	@:noCompletion var mObject:Dynamic;
	@:noCompletion var mFlags:Int;
	
	/**
		Integer value. Only valid if hasInt() == true.
	**/
	public var int(get_int, set_int):Int;
	@:noCompletion inline function get_int():Int
	{
		assert(mFlags & I > 0, "no int stored");
		return mInt;
	}
	@:noCompletion inline function set_int(value:Int):Int
	{
		assert(mFlags & USED == 0);
		
		mFlags |= I;
		mInt = value;
		return value;
	}
	
	/**
		Float value. Only valid if hasFloat() == true.
	**/
	public var float(get_float, set_float):Float;
	@:noCompletion inline function get_float():Float
	{
		assert(mFlags & F > 0, "no float stored");
		return mFloat;
	}
	@:noCompletion inline function set_float(value:Float):Float
	{
		assert(mFlags & USED == 0);
		
		mFlags |= F;
		mFloat = value;
		return value;
	}
	
	/**
		Boolean value. Only valid if hasBool() == true.
	**/
	public var bool(get_bool, set_bool):Bool;
	@:noCompletion inline function get_bool():Bool
	{
		assert(mFlags & B > 0, "no bool stored");
		return mBool;
	}
	@:noCompletion inline function set_bool(value:Bool):Bool
	{
		assert(mFlags & USED == 0);
		
		mFlags |= B;
		mBool = value;
		return value;
	}
	
	/**
		String value. Only valid if hasString() == true.
	**/
	public var string(get_string, set_string):String;
	@:noCompletion inline function get_string():String
	{
		assert(mFlags & S > 0, "no string stored");
		return mString;
	}
	@:noCompletion inline function set_string(value:String):String
	{
		assert(mFlags & USED == 0);
		
		mFlags |= S;
		mString = value;
		return value;
	}
	
	/**
		Dynamic value. Only valid if hasObject() == true.
	**/
	public var object(get_object, set_object):Dynamic;
	@:noCompletion inline function get_object():Dynamic
	{
		assert(mFlags & O > 0, "no object stored");	
		return mObject;
	}
	@:noCompletion inline function set_object(value:Dynamic):Dynamic
	{
		assert(mFlags & USED == 0);
		
		mFlags |= O;
		mObject = value;
		return value;
	}
	
	/**
		True if the message stores an integer value.
	**/
	inline public function hasInt() return mFlags & I > 0;
	
	/**
		True if the message stores a float value.
	**/
	inline public function hasFloat() return mFlags & F > 0;
	
	/**
		True if the message stores an integer value.
	**/
	inline public function hasBool() return mFlags & B > 0;
	
	/**
		True if the message stores a string value.
	**/
	inline public function hasString() return mFlags & S > 0;
	
	/**
		Trhe if the message stores an object.
	**/
	inline public function hasObject() return mFlags & O > 0;
	
	function new() {}
	
	@:noCompletion function toString():String
	{
		var a = [];
		if (mFlags & I > 0) a.push('int=$mInt');
		if (mFlags & F > 0) a.push('float=$mFloat');
		if (mFlags & B > 0) a.push('bool=$mBool');
		if (mFlags & S > 0) a.push('string=$mString');
		if (mFlags & O > 0) a.push('object=$mObject');
		if (a.length > 0) return '{ Msg a.join(", ") }';
		return "{ Msg }";
	}
}