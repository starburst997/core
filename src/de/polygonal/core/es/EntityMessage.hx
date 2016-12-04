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

import de.polygonal.core.util.Assert.assert;
import de.polygonal.ds.tools.ObjectPool;
import de.polygonal.core.es.Entity as E;

/**
	Entities communicate through messages.
	
	A message object stores the message content.
**/
@:allow(de.polygonal.core.es.EntityMessageBuffer)
@:access(de.polygonal.core.es.Entity)

class EntityMessage
{
	#if debug
	static var _nameLut = new Array<String>();
	public static function resolveName(messageId:Int):String return _nameLut[messageId];
	public static function isValid(messageId:Int):Bool return _nameLut[messageId] != null;
	#end
	
	inline static var FLAG_STOP_PROPAGATION = 0x01;
	inline static var FLAG_STOP_IMMEDIATE_PROPAGATION = 0x02;
	
	public static var MESSAGE_COUNT(default, null) = 0;
	public static var MAX_ID(default, null) = 0;
	
	static inline function getGroup(msgType:Int) return (msgType - (msgType & (32 - 1))) >> 5;
	
	@:noCompletion static var mMessages:ObjectPool<EntityMessage> = null;
	
	@:noCompletion static function init()
	{
		mMessages = new ObjectPool<EntityMessage>(function() return new EntityMessage());
		
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
				#if (verbose == "extra")
				L.v(de.polygonal.Printf.format("%40s -> %s", [Type.getClassName(cl) + ":" + names[i], ids[i]]));
				#end
				_nameLut[ids[i]] = names[i];
			}
		}
		#end
	}
	
	@:noCompletion static function gc()
	{
		for (message in mMessages)
		{
			message.data = null;
			message.sender = null;
		}
	}
	
	@:noCompletion static function get(type:Int, data:{}, sender:Entity):EntityMessage
	{
		var o = mMessages.get();
		o.type = type;
		o.data = data;
		o.sender = sender;
		o.mFlags = 0;
		return o;
	}
	
	@:noCompletion static function put(message:EntityMessage)
	{
		mMessages.put(message);
	}
	
	public var type(default, null):Int;
	public var data(default, null):{};
	public var sender(default, null):Entity;
	
	@:noCompletion var mFlags:Int;
	
	public function new() {}
	
	@:extern inline public function stopPropagation() mFlags |= FLAG_STOP_PROPAGATION;
	@:extern inline public function stopImmediatePropagation() mFlags |= FLAG_STOP_PROPAGATION | FLAG_STOP_IMMEDIATE_PROPAGATION;
	
	@:extern inline public function field<T>(field:String):T
	{
		assert(Reflect.hasField(data, field), 'message data is missing property "$field"');
		return Reflect.field(data, field);
	}
	
	#if debug
	public function toString():String
	{
		var name = resolveName(type);
		name = (name != null) ? 'name=$name[$type]' : 'type=$type';
		var data = data != null ? ', data=$data' : '';
		return '[object EntityMessage: $name$data, sender=${sender.name}]';
	}
	#end
}