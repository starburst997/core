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
import de.polygonal.ds.IntIntHashTable;
import haxe.ds.StringMap;
import haxe.ds.Vector;

import de.polygonal.core.es.Entity in E;

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
	inline public static var MAX_SUPPORTED_ENTITIES = 0xFFFE;
	
	/**
		Maximum capacity of the message queue.
		
		By default, a total of 32768 messages can be handled per game tick.
		This requires up to 896 KiB of memory (576 KiB if alchemy is used).
	**/
	inline public static var DEFAULT_MAX_MESSAGE_COUNT = 0x8000;
	
	/**
		The total number of supported entities.
		
		Default is 0x8000.
	**/
	inline public static var DEFAULT_MAX_ENTITY_COUNT = 0x8000;
	
	inline static var OFFSET_PREORDER = 0;
	inline static var OFFSET_PARENT = 1;
	inline static var OFFSET_FIRST_CHILD = 2;
	inline static var OFFSET_LAST_CHILD = 3;
	inline static var OFFSET_SIBLING = 4;
	inline static var OFFSET_SIZE = 5;
	inline static var OFFSET_DEPTH = 6;
	inline static var OFFSET_NUM_CHILDREN = 7;
	
	//unique id, incremented every time an entity is registered
	static var _nextInnerId:Int;
	
	//all existing entities
	static var _freeList:Vector<E>;
	
	#if alchemy
	static var _next:de.polygonal.ds.mem.ShortMemory;
	#else
	static var _next:Vector<Int>;
	#end
	
	static var _free:Int;
	
	//indices [0,3]: parent, child, sibling, last child (indices into the free list)
	//indices [4,6]: size (#descendants), tree depth, #children
	//index 7 is unused
	#if alchemy
	static var _tree:de.polygonal.ds.mem.ShortMemory;
	#else
	static var _tree:Vector<Int>;
	#end
	
	//name => [entities by name]
	static var _entitiesByName:StringMap<E> = null;
	
	//circular message buffer
	static var _msgQue:EntityMessageQue;
	
	//maps class x to all superclasses of x
	static var _inheritanceLut:IntIntHashTable;
	
	static var _treeChanged:Bool;
	
	/**
		Initializes the entity system.
		
		@param maxEntityCount the total number of supported entities.
		@param maxMessageCount the total capacity of the message queue.
	**/
	public static function init(maxEntityCount:Int = DEFAULT_MAX_ENTITY_COUNT, maxMessageCount:Int = DEFAULT_MAX_MESSAGE_COUNT)
	{
		if (_freeList != null) return;
		
		_nextInnerId = 0;
		
		assert(maxEntityCount > 0 && maxEntityCount <= MAX_SUPPORTED_ENTITIES);
		
		_freeList = new Vector<E>(1 + maxEntityCount); //index 0 is reserved for null
		
		#if alchemy
		_tree = new de.polygonal.ds.mem.ShortMemory((1 + maxEntityCount) << 3, "topology");
		#else
		_tree = new Vector<Int>((1 + maxEntityCount) << 3);
		for (i in 0..._tree.length) _tree[i] = 0;
		#end
		
		_entitiesByName = new StringMap<E>();
		
		//first element is stored at index=1 (0 is reserved for NULL)
		#if alchemy
		_next = new de.polygonal.ds.mem.ShortMemory(1 + maxEntityCount, "es_freelist_shorts");
		for (i in 1...maxEntityCount)
			_next.set(i, i + 1);
		_next.set(maxEntityCount, -1);
		#else
		_next = new Vector<Int>(1 + maxEntityCount);
		for (i in 1...maxEntityCount)
			_next[i] = (i + 1);
		_next[maxEntityCount] = -1;
		#end
		
		_free = 1;
		
		_msgQue = new EntityMessageQue(maxMessageCount);
		
		_inheritanceLut = new IntIntHashTable(1024);
		
		_treeChanged = true;
		
		#if verbose
			//topology array
			var bytesUsed = 0;
			#if alchemy
			bytesUsed += _tree.size * 2;
			bytesUsed += _next.size * 2;
			bytesUsed += _msgQue.mQue.size;
			#else
			bytesUsed += _tree.length * 4;
			bytesUsed += _next.length * 4;
			bytesUsed += _msgQue.mQue.length * 4;
			#end
			
			bytesUsed += _freeList.length * 4;
			
			L.d('using ${bytesUsed >> 10} KiB for managing $maxEntityCount entities and ${maxMessageCount} messages.', "es");
		#end
	}
	
	/**
		Disposes the system by explicitly nullifying all references for GC'ing used resources.
		
		This nullifies all `EntityId` objects but does not include calling the free() method on all registered entities.
	**/
	public static function free()
	{
		if (_freeList == null) return;
		
		for (i in 0..._freeList.length)
		{
			if (_freeList[i] != null)
			{
				_freeList[i].preorder = null;
				_freeList[i].id = null;
			}
		}
		
		_freeList = null;
		
		#if alchemy
		_tree.free();
		_next.free();
		#end
		
		_tree = null;
		_entitiesByName = null;
		_next = null;
		_nextInnerId = 0;
		_inheritanceLut.free();
		_inheritanceLut = null;
	}
	
	/**
		Dispatches all queued messages.
	**/
	inline public static function dispatchMessages() _msgQue.dispatch();
	
	/**
		Returns the entity that matches the given `name` or null if such an entity does not exist.
	**/
	inline public static function findByName<T:Entity>(name:String):T
	{
		return cast _entitiesByName.get(name);
	}
	
	/**
		Returns the entity whose name is set to `clss`::ENTITY_NAME or null if such an entity does not exist.
	**/
	inline public static function lookup<T:Entity>(clss:Class<T>):T
	{
		var name =
		#if flash
		untyped clss.ENTITY_NAME;
		#elseif js
		untyped __js__('clss["ENTITY_NAME"]');
		#else
		Reflect.field(clss, "ENTITY_NAME");
		#end
		return cast _entitiesByName.get(name);
	}
	
	/**
		Returns the entity that matches the given `id` or null if such an entity does not exist.
	**/
	inline public static function findById(id:EntityId):E
	{
		if (id.index > 0)
		{
			var e = _freeList[id.index];
			if (e != null)
				return (e.id.inner == id.inner) ? e : null;
			else
				return null;
		}
		else
			return null;
	}
	
	static function register(e:E, isGlobal:Bool)
	{
		if (_freeList == null) init();
		
		assert(e.id == null, "Entity has already been registered");
		
		var i = _free;
		
		assert(i != -1);
		
		#if alchemy
		_free = _next.get(i);
		#else
		_free = _next[i];
		#end
		
		_freeList[i] = e;
		
		var id = new EntityId();
		id.inner = _nextInnerId++;
		id.index = i;
		e.id = id;
		
		if (isGlobal)
		{
			assert(e.name != null);
			registerName(e);
		}
		
		var lut = _inheritanceLut;
		if (!lut.hasKey(e.type))
		{
			var t = e.type;
			lut.set(t, t);
			
			var sc:Class<E> = Reflect.field(Type.getClass(e), "SUPER_CLASS");
			while (sc != null)
			{
				_inheritanceLut.set(t, E.getEntityType(sc));
				sc = Reflect.field(sc, "SUPER_CLASS");
			}
		}
	}
	
	static function unregister(e:E)
	{
		assert(e.id != null);
		
		#if (verbose == "extra")
		L.d('$e is gone', "es");
		#end
		
		var i = e.id.index;
		
		//nullify for gc
		_freeList[i] = null;
		
		var pos = i << 3;
		
		#if alchemy
		for (i in 0...8) _tree.set(pos + i, 0);
		#else
		for (i in 0...8) _tree[pos + i] = 0;
		#end
		
		//mark as free
		#if alchemy
		_next.set(i, _free);
		#else
		_next[i] = _free;
		#end
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
	}
	
	static function freeEntityTree(e:E)
	{
		#if verbose
		var c = getSize(e) + 1;
		if (c > 1)
			L.d('freeing up $c entities ...', "es");
		else
			L.d('freeing up one entity ...', "es");
		#end
		
		if (getSize(e) < 512)
			freeRecursive(e); //postorder traversal
		else
			freeIterative(e); //inverse levelorder traversal
	}
	
	inline public static function getPreorder(e:E):E return _freeList[get(pos(e, OFFSET_PREORDER))];
	inline static function setPreorder(e:E, value:E) set(pos(e, OFFSET_PREORDER), value == null ? 0 : value.id.index);
	
	inline public static function getParent(e:E):E return _freeList[get(pos(e, OFFSET_PARENT))];
	inline static function setParent(e:E, value:E) set(pos(e, OFFSET_PARENT), value == null ? 0 : value.id.index);
	
	inline public static function getFirstChild(e:E):E return _freeList[get(pos(e, OFFSET_FIRST_CHILD))];
	inline static function setFirstChild(e:E, value:E) set(pos(e, OFFSET_FIRST_CHILD), value == null ? 0 : value.id.index);
	
	inline public static function getLastChild(e:E):E return _freeList[get(pos(e, OFFSET_LAST_CHILD))];
	inline static function setLastChild(e:E, value:E) set(pos(e, OFFSET_LAST_CHILD), value == null ? 0 : value.id.index);
	
	inline public static function getSibling(e:E):E return _freeList[get(pos(e, OFFSET_SIBLING))];
	inline static function setSibling(e:E, value:E) set(pos(e, OFFSET_SIBLING), value == null ? 0 : value.id.index);
	
	inline public static function getSize(e:E):Int return get(pos(e, OFFSET_SIZE));
	inline static function setSize(e:E, value:Int) set(pos(e, OFFSET_SIZE), value);
	
	inline public static function getDepth(e:E):Int return get(pos(e, OFFSET_DEPTH));
	inline static function setDepth(e:E, value:Int) set(pos(e, OFFSET_DEPTH), value);
	
	inline public static function getNumChildren(e:E):Int return get(pos(e, OFFSET_NUM_CHILDREN));
	inline static function setNumChildren(e:E, value:Int) set(pos(e, OFFSET_NUM_CHILDREN), value);
	
	inline static function get(i:Int):Int
	{
		return
		#if alchemy
		_tree.get(i);
		#else
		_tree[i];
		#end
	}
	
	inline static function set(i:Int, value:Int)
	{
		#if alchemy
		_tree.set(i, value);
		#else
		_tree[i] = value;
		#end
	}
	
	inline static function pos(e:E, shift:Int):Int return (e.id.index << 3) + shift;
   	
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
		
		#if verbose
		L.d('free ${e.name}');
		#end
		
		e.onFree();
		unregister(e);
	}
	
	static function freeIterative(e:E)
	{
		var k = getSize(e) + 1;
		var a = new Vector<E>(k);
		for (i in 0...k) a[i] = null;
		
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
			
			#if verbose
			L.d('free ${e.name}');
			#end
			
			e.onFree();
			unregister(e);
		}
	}
	
	static function registerName(e:E)
	{
		assert(e.id != null, "Entity is not registered, call EntitySystem.register() before");
		
		if (_entitiesByName.exists(e.name))
			throw '${e.name} already registered to ${_entitiesByName.get(e.name)}';
		
		_entitiesByName.set(e.name, e);
		e.mBits |= E.BIT_IS_GLOBAL;
		
		#if verbose
		L.d('registered entity by name: ${e.name} => $e', "es");
		#end
	}
	
	inline public static function findLastLeaf(e:Entity):Entity
	{
		//find bottom-most, right-most entity in the subtree e
		while (e.firstChild != null) e = getLastChild(e);
		
		return e;
	}
	
	inline public static function nextSubtree(e:Entity):Entity
	{
		var t = e.sibling;
		
		return t != null ? t : findLastLeaf(e).preorder;
	}
}