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

import de.polygonal.core.es.Entity;
import de.polygonal.core.tools.ClassTools;
import de.polygonal.ds.IntIntHashTable;
import de.polygonal.ds.NativeArray;
import de.polygonal.ds.tools.NativeArrayTools;
import haxe.ds.StringMap;
import de.polygonal.core.es.Entity as E;

using de.polygonal.ds.tools.NativeArrayTools;

enum CallbackType { OnRegister; OnAdd; OnRemove; OnUnregister; }

/**
	Manages all active entities
**/
@:access(de.polygonal.core.es.Entity)
@:access(de.polygonal.core.es.EntityMessageBuffer)
class EntitySystem
{
	/**
		The total number of entities that this system supports.
	**/
	public static inline var MAX_SUPPORTED_ENTITIES = 0xFFFE;
	
	static inline var POS_PREORDER = 0;
	static inline var POS_PARENT = 1;
	static inline var POS_FIRST_CHILD = 2;
	static inline var POS_LAST_CHILD = 3;
	static inline var POS_SIBLING = 4;
	static inline var POS_SIZE = 5;
	static inline var POS_DEPTH = 6;
	static inline var POS_NUM_CHILDREN = 7;
	
	public static var NUM_ACTIVE_ENTITIES(default, null) = 0;
	
	static var _freeList:NativeArray<E>;
	
	#if alchemy
	static var _next:de.polygonal.ds.mem.ShortMemory;
	#else
	static var _next:NativeArray<Int>;
	#end
	
	//indices [0,3]: parent, child, sibling, last child (indices into free list)
	//indices [4,7]: size (#descendants), tree depth, #children
	#if alchemy
	static var _tree:de.polygonal.ds.mem.ShortMemory;
	#else
	static var _tree:NativeArray<Int>;
	#end
	
	static var _names:NativeArray<String>;
	static var _callbacks:NativeArray<Array<Entity->Bool>>;
	static var _globalEntityLut:NativeArray<E>;
	static var _superLut:IntIntHashTable;
	static var _nextInner:Int;
	static var _free:Int;
	
	/**
		Initializes the entity system.
		
		@param maxEntityCount the total number of supported entities.
		@param maxMessageCount the total capacity of the message queue.
	**/
	@:access(de.polygonal.core.es.EntityMessage)
	@:access(de.polygonal.core.es.EntityMessaging)
	public static function init(maxEntityCount:Int = 0x8000)
	{
		assert(maxEntityCount > 0 && maxEntityCount <= MAX_SUPPORTED_ENTITIES);
		
		assert(_freeList == null);
		
		//first element is stored at index=1 (0 is reserved for NULL)
		_freeList = NativeArrayTools.alloc(1 + maxEntityCount); 
		#if alchemy
		_next = new de.polygonal.ds.mem.ShortMemory(1 + maxEntityCount, "es_freelist_i16");
		#else
		_next = NativeArrayTools.alloc(1 + maxEntityCount);
		#end
		for (i in 1...maxEntityCount) _next.set(i, i + 1);
		_next.set(maxEntityCount, -1);
		#if alchemy
		_tree = new de.polygonal.ds.mem.ShortMemory((1 + maxEntityCount) * 8, "es_topology_i16");
		#else
		_tree = NativeArrayTools.alloc((1 + maxEntityCount) * 8);
		_tree.init(0);
		#end
		
		_names = NativeArrayTools.alloc(1 + maxEntityCount);
		
		var k = CallbackType.getConstructors().length;
		_callbacks = NativeArrayTools.alloc(k);
		for (i in 0...k) _callbacks.set(i, new Array<Entity->Bool>());
		
		EntityMessage.init();
		EntityMessaging.init();
		
		_globalEntityLut = NativeArrayTools.alloc(1024);
		_superLut = new IntIntHashTable(1024);
		
		_nextInner = 0;
		_free = 1;
	}
	
	public static function free()
	{
		_freeList.nullify();
		_freeList = null;
		
		#if alchemy
		_next.free();
		_tree.free();
		#end
		_next = null;
		_tree = null;
		
		_names.nullify();
		_names = null;
		_callbacks.nullify();
		_callbacks = null;
		_globalEntityLut.nullify();
		_globalEntityLut = null;
		_superLut.free();
		_superLut = null;
	}
	
	#if debug
	public static function print():String
	{
		var s = "";
		var args = new Array<Dynamic>();
		var a = _freeList;
		for (i in 0...a.length)
		{
			if (a[i] != null)
			{
				var name = Std.string(a[i]);
				if (a[i].mBits & Entity.BIT_IS_GLOBAL > 0) name += " [GLOBAL]";
				args[0] = i;
				args[1] = name;
				s += Printf.format("% 5d: %s\n", args);
			}
		}
		return s;
	}
	#end
	
	/**
		Returns the global entity that matches the given `name`. If `name` is omitted, "`clss`.ENTITY_NAME" is used.
	**/
	public static function lookup<T:Entity>(clss:Class<T>):T
	{
		return cast _globalEntityLut.get(Entity.getEntityType(clss));
	}
	
	public static function registerCallback(type:CallbackType, func:Entity->Bool)
	{
		_callbacks[type.getIndex()].push(func);
	}
	
	public static function unregisterCallback(type:CallbackType, func:Entity->Bool)
	{
		_callbacks[type.getIndex()].remove(func);
	}
	
	@:access(de.polygonal.core.es.EntityMessage)
	public static function gc()
	{
		EntityMessage.gc();
	}
	
	static function register(entity:E, global:Bool)
	{
		if (_freeList == null) init();
		
		var i = _free;
		
		assert(i != -1);
		
		_free = _next.get(i);
		_freeList.set(i, entity);
		
		assert(entity.id == null, "already registered");
		entity.id = new EntityId(_nextInner++, i);
		
		if (global)
		{
			var type2 = Entity.getEntityType(Type.getClass(entity));
			if (entity.type != type2) throw 2;
			
			assert(_globalEntityLut.get(entity.type) == null);
			_globalEntityLut.set(entity.type, entity);
			
			entity.mBits |= E.BIT_IS_GLOBAL;
			
			L.v('Registered global entity (${ClassTools.getClassName(entity)}[${entity.type}])', "es");
		}
		
		var lut = _superLut;
		if (!lut.hasKey(entity.type))
		{
			var t = entity.type;
			lut.set(t, t);
			var sc:Class<E> = Reflect.field(Type.getClass(entity), "SUPER_CLASS");
			while (sc != null)
			{
				_superLut.set(t, E.getEntityType(sc));
				sc = Reflect.field(sc, "SUPER_CLASS");
			}
		}
		
		NUM_ACTIVE_ENTITIES++;
		testCallbacks(entity, CallbackType.OnRegister);
		L.v('registered $entity', "es");
	}
	
	@:access(de.polygonal.core.es.EntityId)
	static function unregister(entity:E)
	{
		assert(entity.id != null);
		
		var index = entity.id.index;
		
		//nullify for gc
		_freeList.set(index, null);
		
		//zero out topology
		var pos = index << 3;
		for (i in 0...8) _tree.set(pos + i, 0);
		
		//vacate slot, mark as free
		_next.set(index, _free);
		_free = index; //TODO store in queue?
		
		//remove <name,entity> mapping
		if (entity.mBits & E.BIT_IS_GLOBAL > 0)
		{
			_globalEntityLut.set(entity.type, null);
			entity.mBits &= ~E.BIT_IS_GLOBAL;
		}
		
		entity.mBits |= E.BIT_FREED | E.BIT_SKIP_DRAW | E.BIT_SKIP_TICK | E.BIT_SKIP_SUBTREE;
		
		//mark as freed by setting msb
		entity.id.inner |= 0x80000000;
		
		//nullify id for gc
		entity.id = null;
		
		NUM_ACTIVE_ENTITIES--;
		testCallbacks(entity, CallbackType.OnUnregister);
		
		L.v('unregistered $entity', "es");
	}
	
	static function testCallbacks(e:Entity, type:CallbackType)
	{
		var a = _callbacks[type.getIndex()];
		var k = a.length;
		if (k == 0) return;
		var i = 0;
		while (i < k)
		{
			if (!a[i](e))
			{
				a[i] = a.pop();
				k--;
				continue;
			}
			i++;
		}
	}
	
	static function freeSubtree(e:E)
	{
		//bottom-up order: push all, then pop
		var a = [];
		while (e != null)
		{
			a.push(e);
			e = e.next;
		}
		for (i in 0...a.length)
		{
			e = a.pop();
			e.mBits |= E.BIT_FREED | E.BIT_SKIP_DRAW | E.BIT_SKIP_TICK | E.BIT_SKIP_SUBTREE;
			e.onFree();
			unregister(e);
		}
	}
	
	static inline function getName(e:E):String
	{
		assert(e.id != null);
		return _names.get(e.id.index);
	}
	static inline function setName(e:E, name:String)
	{
		assert(e.id != null);
		_names.set(e.id.index, name);
	}
	
	static inline function getNext(e:E):E
	{
		return _freeList.get(_tree.get(pos(e, POS_PREORDER)));
	}
	static inline function setNext(e:E, value:E)
	{
		_tree.set(pos(e, POS_PREORDER), value == null ? 0 : value.id.index);
	}
	
	static inline function getParent(e:E):E
	{
		return _freeList.get(_tree.get(pos(e, POS_PARENT)));
	}
	static inline function setParent(e:E, value:E)
	{
		_tree.set(pos(e, POS_PARENT), value == null ? 0 : value.id.index);
	}
	
	static inline function getFirstChild(e:E):E
	{
		return _freeList.get(_tree.get(pos(e, POS_FIRST_CHILD)));
	}
	static inline function setFirstChild(e:E, value:E)
	{
		_tree.set(pos(e, POS_FIRST_CHILD), value == null ? 0 : value.id.index);
	}
	
	static inline function getLastChild(e:E):E
	{
		return _freeList.get(_tree.get(pos(e, POS_LAST_CHILD)));
	}
	static inline function setLastChild(e:E, value:E)
	{
		_tree.set(pos(e, POS_LAST_CHILD), value == null ? 0 : value.id.index);
	}
	
	static inline function getSibling(e:E):E
	{
		return _freeList.get(_tree.get(pos(e, POS_SIBLING)));
	}
	static inline function setSibling(e:E, value:E)
	{
		_tree.set(pos(e, POS_SIBLING), value == null ? 0 : value.id.index);
	}
	
	public static inline function getSize(e:E):Int
	{
		return _tree.get(pos(e, POS_SIZE));
	}
	static inline function setSize(e:E, value:Int)
	{
		_tree.set(pos(e, POS_SIZE), value);
	}
	
	static inline function getDepth(e:E):Int
	{
		return _tree.get(pos(e, POS_DEPTH));
	}
	static inline function setDepth(e:E, value:Int)
	{
		_tree.set(pos(e, POS_DEPTH), value);
	}
	
	static inline function getChildCount(e:E):Int
	{
		return _tree.get(pos(e, POS_NUM_CHILDREN));
	}
	static inline function setChildCount(e:E, value:Int)
	{
		_tree.set(pos(e, POS_NUM_CHILDREN), value);
	}
	
	static inline function pos(e:E, shift:Int):Int
	{
		return (e.id.index << 3) + shift;
	}
}