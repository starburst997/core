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

import de.polygonal.core.es.Entity in E;
import de.polygonal.core.util.Assert.assert;
import de.polygonal.core.util.ClassTools;
import de.polygonal.ds.ArrayList;
import de.polygonal.ds.IntIntHashTable;
import de.polygonal.ds.NativeArray;
import de.polygonal.ds.tools.NativeArrayTools;
import haxe.ds.StringMap;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	Manages all active entities
**/
@:access(de.polygonal.core.es.Entity)
@:access(de.polygonal.core.es.EntityMessageQue)
class EntitySystem
{
	/**
		The total number of entities that this system supports.
	**/
	public static inline var MAX_SUPPORTED_ENTITIES = 0xFFFE;
	
	static inline var OFFSET_PREORDER = 0;
	static inline var OFFSET_PARENT = 1;
	static inline var OFFSET_FIRST_CHILD = 2;
	static inline var OFFSET_LAST_CHILD = 3;
	static inline var OFFSET_SIBLING = 4;
	static inline var OFFSET_SIZE = 5;
	static inline var OFFSET_DEPTH = 6;
	static inline var OFFSET_NUM_CHILDREN = 7;
	
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
	static var _entitiesByName:StringMap<E>;
	static var _messageQueue:EntityMessageQue;
	static var _superLut:IntIntHashTable;
	static var _callbacks:NativeArray<ArrayList<Entity->Bool>>;
	
	static var _nextInnerId:Int;
	static var _free:Int;
	
	/**
		Initializes the entity system.
		
		@param maxEntityCount the total number of supported entities.
		@param maxMessageCount the total capacity of the message queue.
	**/
	@:access(de.polygonal.core.es.EntityMessage)
	public static function init(maxEntityCount:Int = 0x8000)
	{
		assert(maxEntityCount > 0 && maxEntityCount <= MAX_SUPPORTED_ENTITIES);
		
		if (_freeList != null)
		{
			//TODO kill
		/*	for (i in 0..._freeList.size())
			{
				if (_freeList.get(i) != null)
				{
					_freeList.get(i).preorder = null;
					_freeList.get(i).id = null;
				}
			}
			
			_freeList.nullify();
			_freeList = null;
			
			#if alchemy
			_tree.free();
			_next.free();
			#end
			
			_tree = null;
			_entitiesByName = null;
			_next = null;
			_nextInnerId = 0;
			_superLut.free();
			_superLut = null;*/
		}
		
		EntityMessage.init();
		
		_freeList = NativeArrayTools.alloc(1 + maxEntityCount); //index 0 is reserved for NULL
		
		//first element is stored at index=1 (0 is reserved for NULL)
		#if alchemy
		_next = new de.polygonal.ds.mem.ShortMemory(1 + maxEntityCount, "es_freelist_shorts");
		#else
		_next = NativeArrayTools.alloc(1 + maxEntityCount);
		#end
		for (i in 1...maxEntityCount) _next.set(i, i + 1);
		_next.set(maxEntityCount, -1);
		
		#if alchemy
		_tree = new de.polygonal.ds.mem.ShortMemory((1 + maxEntityCount) << 3, "topology");
		#else
		_tree = NativeArrayTools.alloc((1 + maxEntityCount) << 3);
		_tree.init(0);
		#end
		
		_entitiesByName = new StringMap<E>();
		_messageQueue = new EntityMessageQue();
		_superLut = new IntIntHashTable(1024);
		_callbacks = NativeArrayTools.alloc(3);
		for (i in 0...3) _callbacks.set(i, new ArrayList());
		
		_nextInnerId = 0;
		_free = 1;
	}
	
	#if debug
	public static function printAll():String
	{
		var s = "";
		var args = new Array<Dynamic>();
		var a = _freeList;
		for (i in 0...a.length)
		{
			if (a[i] != null)
			{
				var name = Std.string(a[i]);
				if (a[i].mBits & Entity.BIT_IS_GLOBAL > 0) name += " GLOBAL";
				args[0] = i;
				args[1] = name;
				s += Printf.format("% 5d: %s\n", args);
			}
		}
		return s;
	}
	#end
	
	/**
		Dispatches all queued messages.
	**/
	public static inline function dispatchMessages()
	{
		_messageQueue.flush();
	}
	
	/**
		Returns the entity that matches the given `name` or null if such an entity does not exist.
	**/
	public static inline function findByName<T:Entity>(name:String):T
	{
		return cast _entitiesByName.get(name);
	}
	
	/**
		Returns the entity whose name is set to `clss`::ENTITY_NAME or null if such an entity does not exist.
	**/
	public static inline function lookup<T:Entity>(clss:Class<T>):T
	{
		var name =
		#if flash
		untyped clss.ENTITY_NAME;
		#elseif js
		untyped clss["ENTITY_NAME"]; //TODO not needed
		#else
		Reflect.field(clss, "ENTITY_NAME");
		#end
		return cast _entitiesByName.get(name);
	}
	
	/**
		Returns the entity that matches the given `id` or null if such an entity does not exist.
	**/
	public static inline function findById(id:EntityId):E
	{
		if (id.index > 0)
		{
			var e = _freeList.get(id.index);
			if (e != null)
				return (e.id.inner == id.inner) ? e : null;
			else
				return null;
		}
		else
			return null;
	}
	
	public static function onCreate(f:Entity->Bool)
	{
		_callbacks[0].add(f);
	}
	
	public static function onAdd(f:Entity->Bool)
	{
		_callbacks[1].add(f);
	}
	
	public static function onRemove(f:Entity->Bool)
	{
		_callbacks[2].add(f);
	}
	
	static function register(e:E, isGlobal:Bool)
	{
		if (_freeList == null) init();
		assert(e.id == null, "Entity already registered");
		
		var i = _free;
		
		assert(i != -1);
		
		_free = _next.get(i);
		_freeList.set(i, e);
		
		e.id = new EntityId(_nextInnerId++, i);
		
		if (isGlobal)
		{
			assert(e.name != null);
			assert(!_entitiesByName.exists(e.name), "Entity \"" + ClassTools.getUnqualifiedClassName(e) + "\" already mapped to \"" + e.name + "\"");
			_entitiesByName.set(e.name, e);
			e.mBits |= E.BIT_IS_GLOBAL;
			#if verbose
			L.d("Entity \"" + ClassTools.getClassName(e) + "\" is now globally accessible by the name \"" + e.name + "\"", "es");
			#end
		}
		
		var lut = _superLut;
		if (!lut.hasKey(e.type))
		{
			var t = e.type;
			lut.set(t, t);
			var sc:Class<E> = Reflect.field(Type.getClass(e), "SUPER_CLASS");
			while (sc != null)
			{
				_superLut.set(t, E.getEntityType(sc));
				sc = Reflect.field(sc, "SUPER_CLASS");
			}
		}
		
		onCallback(e, 0);
		NUM_ACTIVE_ENTITIES++;
	}
	
	@:access(de.polygonal.core.es.EntityId)
	static function unregister(e:E)
	{
		assert(e.id != null);
		
		var i = e.id.index;
		
		//nullify for gc
		_freeList.set(i, null);
		
		var pos = i << 3;
		for (i in 0...8) _tree.set(pos + i, 0);
		
		//mark as free
		_next.set(i, _free);
		_free = i;
		
		//don't forget to nullify preorder pointer
		e.preorder = null;
		
		//remove from name => entity mapping
		if (e.mBits & E.BIT_IS_GLOBAL > 0)
		{
			_entitiesByName.remove(e.name);
			e.mBits &= ~E.BIT_IS_GLOBAL;
		}
		
		//mark as removed by setting msb to one
		e.id.inner |= 0x80000000;
		e.id = null;
		
		NUM_ACTIVE_ENTITIES--;
	}
	
	static function onCallback(e:Entity, type:Int)
	{
		var a = _callbacks[type];
		var i = 0;
		var k = a.size;
		while (i < k)
		{
			if (a.get(i)(e))
			{
				a.swapPop(i);
				k--;
				continue;
			}
			i++;
		}
	}
	
	static function freeEntityTree(e:E)
	{
		if (getSize(e) < 512)
			freeRecursive(e); //postorder traversal
		else
			freeIterative(e); //inverse levelorder traversal
	}
	
	static inline function getPreorder(e:E):E
	{
		return _freeList.get(_tree.get(pos(e, OFFSET_PREORDER)));
	}
	static inline function setPreorder(e:E, value:E)
	{
		_tree.set(pos(e, OFFSET_PREORDER), value == null ? 0 : value.id.index);
	}
	
	static inline function getParent(e:E):E
	{
		return _freeList.get(_tree.get(pos(e, OFFSET_PARENT)));
	}
	static inline function setParent(e:E, value:E)
	{
		_tree.set(pos(e, OFFSET_PARENT), value == null ? 0 : value.id.index);
	}
	
	static inline function getFirstChild(e:E):E
	{
		return _freeList.get(_tree.get(pos(e, OFFSET_FIRST_CHILD)));
	}
	static inline function setFirstChild(e:E, value:E)
	{
		_tree.set(pos(e, OFFSET_FIRST_CHILD), value == null ? 0 : value.id.index);
	}
	
	static inline function getLastChild(e:E):E
	{
		return _freeList.get(_tree.get(pos(e, OFFSET_LAST_CHILD)));
	}
	static inline function setLastChild(e:E, value:E)
	{
		_tree.set(pos(e, OFFSET_LAST_CHILD), value == null ? 0 : value.id.index);
	}
	
	static inline function getSibling(e:E):E
	{
		return _freeList.get(_tree.get(pos(e, OFFSET_SIBLING)));
	}
	static inline function setSibling(e:E, value:E)
	{
		_tree.set(pos(e, OFFSET_SIBLING), value == null ? 0 : value.id.index);
	}
	
	public static inline function getSize(e:E):Int
	{
		return _tree.get(pos(e, OFFSET_SIZE));
	}
	static inline function setSize(e:E, value:Int)
	{
		_tree.set(pos(e, OFFSET_SIZE), value);
	}
	
	static inline function getDepth(e:E):Int
	{
		return _tree.get(pos(e, OFFSET_DEPTH));
	}
	static inline function setDepth(e:E, value:Int)
	{
		_tree.set(pos(e, OFFSET_DEPTH), value);
	}
	
	static inline function getNumChildren(e:E):Int
	{
		return _tree.get(pos(e, OFFSET_NUM_CHILDREN));
	}
	static inline function setNumChildren(e:E, value:Int)
	{
		_tree.set(pos(e, OFFSET_NUM_CHILDREN), value);
	}
	
	static inline function pos(e:E, shift:Int):Int
	{
		return (e.id.index << 3) + shift;
	}
   	
	static function freeRecursive(e:E)
	{
		var n = e.firstChild;
		while (n != null)
		{
			var sibling = n.sibling;
			freeRecursive(n);
			n = sibling;
		}
		e.mBits |= E.BIT_FREED;
		e.onFree();
		unregister(e);
		
		#if verbose
		L.d("Entity \"" + ClassTools.getUnqualifiedClassName(e) + "\" freed", "es");
		#end
	}
	
	static function freeIterative(e:E)
	{
		var k = getSize(e) + 1;
		var a = new Array<E>();
		var q = [e];
		var i = 0;
		var s = 1;
		var j, c;
		while (i < s)
		{
			j = q[i++];
			a[--k] = j; //add in reverse order
			c = j.firstChild;
			while (c != null)
			{
				q[s++] = c;
				c = c.sibling;
			}
		}
		for (e in a)
		{
			e.mBits |= E.BIT_FREED;
			e.onFree();
			unregister(e);
			#if verbose
			L.d("Entity \"" + ClassTools.getUnqualifiedClassName(e) + "\" freed", "es");
			#end
		}
	}
	
	static inline function findLastLeaf(e:Entity):Entity
	{
		//find bottom-most, right-most entity in the subtree e
		while (e.firstChild != null) e = getLastChild(e);
		return e;
	}
	
	static inline function nextSubtree(e:Entity):Entity
	{
		var t = e.sibling;
		return t != null ? t : findLastLeaf(e).preorder;
	}
}