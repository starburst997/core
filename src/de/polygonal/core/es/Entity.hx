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

import de.polygonal.core.es.EntityMessage;
import de.polygonal.core.es.EntityMessageBuffer;
import de.polygonal.core.tools.ClassTools;
import de.polygonal.core.es.EntitySystem as Es;
import de.polygonal.ds.tools.Bits;

using de.polygonal.core.es.EntitySystem;
using de.polygonal.core.es.EntityTools;

/**
	Base entity class
**/
@:keep
@:keepSub
@:access(de.polygonal.core.es.EntitySystem)
@:build(de.polygonal.core.macro.IntConsts.build(
[
	BIT_SKIP_SUBTREE,
	BIT_SKIP_TICK,
	BIT_SKIP_POST_TICK,
	BIT_SKIP_DRAW,
	BIT_SKIP_POST_DRAW,
	BIT_IS_GLOBAL,
	BIT_PARENTLESS,
	BIT_FREED
], true, false))
@:build(de.polygonal.core.es.EntityMacro.build())
@:autoBuild(de.polygonal.core.es.EntityMacro.build())
class Entity
{
	/**
		type, phase, flags: -------- ----TTTT TTTTPPPP FFFFFFFF
		                                                      ^
															  LSB
	**/
	
	static inline var NUM_FLAG_BITS = 8;
	
	static inline var NUM_PHASE_BITS = 4;
	static inline var MAX_PHASE = (1 << NUM_PHASE_BITS) - 1;
	
	static inline var NUM_TYPE_BITS = 8;
	static inline var MAX_TYPE = (1 << NUM_TYPE_BITS) - 1;
	
	@:noCompletion static function comparePhase(a:Entity, b:Entity) return a.phase - b.phase;
	
	inline static function getEntityType<T:Entity>(clss:Class<T>):Int
	{
		#if flash
		return untyped clss["ENTITY_TYPE"];
		#elseif js
		return untyped clss["ENTITY_TYPE"];
		#else
		return Reflect.field(clss, "ENTITY_TYPE");
		#end
	}
	
	#if debug
	static var _classNameLut = new haxe.ds.StringMap<Int>();
	static var _nextEntityId = 0;
	#end
	
	@:noCompletion var mBits:Int;
	
	/**
		The name of this entity.
	**/
	#if debug
	public var name(default, null):String;
	#else
	public var name(get, set):String;
	#if !debug @:extern #end
	@:noCompletion inline function get_name():String { assert(id != null); return getName(); }
	#if !debug @:extern #end
	@:noCompletion inline function set_name(value:String):String { assert(id != null); setName(value); return value; }
	#end
	
	/**
		Every entity has an unique identifier.
	*/
	@:noCompletion var id(default, null):EntityId;
	
	/**
		Every subclass of the Entity class can be identified by an unique integer value.
	**/
	public var type(get, never):Int;
	@:extern @:noCompletion inline function get_type():Int return mBits >>> (NUM_FLAG_BITS + NUM_PHASE_BITS);
	
	/**
		Execution order in the range [0, `MAX_PHASE`] (smaller value equals higher priority);
		only effective after calling `sort()`. Default is 0.
	**/
	public var phase(get, set):Int;
	#if !debug @:extern #end
	@:noCompletion inline function get_phase():Int return (mBits >>> NUM_FLAG_BITS) & Bits.mask(NUM_PHASE_BITS);
	#if !debug @:extern #end
	@:noCompletion inline function set_phase(value:Int):Int { assert(value >= 0 && value < MAX_PHASE, 'phase out of range $NUM_PHASE_BITS'); mBits |= value << NUM_FLAG_BITS; return value; }
	
	public function new(global = false)
	{
		#if debug
		//assign at runtime; prevent problems with compiler caching macros
		var stack = [];
		var cl:Class<Dynamic> = Type.getClass(this);
		while (cl != null)
		{
			stack.push(cl);
			cl = Type.getSuperClass(cl);
		}
		while (stack.length > 0)
		{
			cl = stack.pop();
			var entityName = Reflect.field(cl, "ENTITY_NAME");
			if (!_classNameLut.exists(entityName))
			{
				var entityId = _nextEntityId++;
				_classNameLut.set(entityName, entityId);
				Reflect.setField(cl, "ENTITY_TYPE", entityId);
			}
		}
		#end
		assert(_getType() <= MAX_TYPE);
		
		mBits = (_getType() << (NUM_FLAG_BITS + NUM_PHASE_BITS)) | (BIT_PARENTLESS | BIT_SKIP_POST_TICK | BIT_SKIP_POST_DRAW);
		
		Es.register(this, global);
	}
	
	/**
		Recursively destroys the subtree rooted at this entity (including this entity) from the bottom up.
		
		This invokes``onFree()`` on each entity, giving each entity the opportunity to perform some cleanup (e.g. free resources or unregister from listeners).
	**/
	public function free()
	{
		if (id == null) return;
		if (mBits & BIT_FREED > 0) return;
		if (parent != null) parent.remove(this);
		Es.freeSubtree(this);
	}
	
	/**
		A pointer to the next entity in a preorder sequence.
	**/
	public var next(get, never):Entity;
	#if !debug @:extern #end
	@:noCompletion inline function get_next():Entity { assert(mBits & BIT_FREED == 0); return getNext(); }
	
	/**
		The parent or null if this is a top entity.
	**/
	public var parent(get, never):Entity;
	#if !debug @:extern #end
	@:noCompletion inline function get_parent():Entity { assert(mBits & BIT_FREED == 0); return getParent(); }
	
	/**
		The first child or null if this entity has no children.
	**/
	public var firstChild(get, never):Entity;
	#if !debug @:extern #end
	@:noCompletion inline function get_firstChild():Entity { assert(mBits & BIT_FREED == 0); return getFirstChild(); }
	
	/**
		The last child or null if this entity has no children.
	**/
	public var lastChild(get, never):Entity;
	#if !debug @:extern #end
	@:noCompletion inline function get_lastChild():Entity { assert(mBits & BIT_FREED == 0); return getLastChild(); }
	
	/**
		The next sibling or null if this entity has no sibling.
	**/
	public var sibling(get, never):Entity;
	#if !debug @:extern #end
	@:noCompletion inline function get_sibling():Entity { assert(mBits & BIT_FREED == 0); return getSibling(); }
	
	/**
		The total number of child entities.
	**/
	public var childCount(get, never):Int;
	#if !debug @:extern #end
	@:noCompletion inline function get_childCount():Int { assert(mBits & BIT_FREED == 0); return getChildCount(); }
	
	/**
		If true, ``MainLoop`` updates this entity at regular intervals by invoking the ``onTick(dt, false)`` method.
	**/
	public var tickable(get, set):Bool;
	#if !debug @:extern #end
	@:noCompletion inline function get_tickable():Bool return mBits & BIT_SKIP_TICK == 0;
	#if !debug @:extern #end
	@:noCompletion inline function set_tickable(value:Bool):Bool { value ? mBits &= ~BIT_SKIP_TICK : mBits |= BIT_SKIP_TICK; return value; }
	
	/**
		If true, ``MainLoop`` updates this entity at regular intervals by invoking the ``onTick(dt, true)`` method.
	**/
	public var postTickable(get, set):Bool;
	#if !debug @:extern #end
	@:noCompletion inline function get_postTickable():Bool return mBits & BIT_SKIP_POST_TICK == 0;
	#if !debug @:extern #end
	@:noCompletion inline function set_postTickable(value:Bool):Bool { value ? mBits &= ~BIT_SKIP_POST_TICK : mBits |= BIT_SKIP_POST_TICK; return value; }
	
	/**
		If true, ``MainLoop`` renderes this entity at regular intervals by invoking the ``onDraw()`` method.
	**/
	public var drawable(get, set):Bool;
	#if !debug @:extern #end
	@:noCompletion inline function get_drawable():Bool return mBits & BIT_SKIP_DRAW == 0;
	#if !debug @:extern #end
	@:noCompletion inline function set_drawable(value:Bool):Bool { value ? mBits &= ~BIT_SKIP_DRAW : mBits |= BIT_SKIP_DRAW; return value; }
	
	public var postDrawable(get, set):Bool;
	#if !debug @:extern #end
	@:noCompletion inline function get_postDrawable():Bool return mBits & BIT_SKIP_POST_DRAW == 0;
	#if !debug @:extern #end
	@:noCompletion inline function set_postDrawable(value:Bool):Bool { value ? mBits &= ~BIT_SKIP_POST_DRAW : mBits |= BIT_SKIP_POST_DRAW; return value; }
	
	/**
		If false, skips updating the subtree rooted at this node. Default is true.
	**/
	public var passable(get, set):Bool;
	#if !debug @:extern #end
	@:noCompletion inline function get_passable():Bool return mBits & BIT_SKIP_SUBTREE == 0;
	#if !debug @:extern #end
	@:noCompletion inline function set_passable(value:Bool):Bool { value ? mBits &= ~BIT_SKIP_SUBTREE : mBits |= BIT_SKIP_SUBTREE; return value; }
	
	/**
		Adds a child entity to this entity and returns the newly added entity.
		
		- if `inst` is omitted, creates and adds an instance of the class `clss` to this entity.
		- if `clss` is omitted, adds `inst` to this entity.
	**/
	public function add<T:Entity>(?clss:Class<T>, ?inst:T):T
	{
		assert(clss != null || inst != null);
		
		var child:Entity = inst;
		if (child == null) child = Type.createInstance(clss, []);
		
		assert(child.parent != this);
		assert(child.parent == null);
		
		child.setParent(this);
		
		//update #children
		setChildCount(childCount + 1);
		
		//update size (ancestors)
		var k = child.getSize() + 1;
		setSize(getSize() + k);
		
		var p = parent;
		while (p != null)
		{
			p.setSize(p.getSize() + k);
			p = p.parent;
		}
		
		if (firstChild == null)
		{
			//case 1: without children
			setFirstChild(child);
			child.setSibling(null);
			
			//fix preorder pointer
			var i = child.getLastLeaf();
			i.setNext(next);
			setNext(child);
		}
		else
		{
			//case 2: with children
			//fix preorder pointers
			var i = lastChild.getLastLeaf();
			var j = child.getLastLeaf();
			
			j.setNext(i.next);
			i.setNext(child);
			
			lastChild.setSibling(child);
		}
		
		//update depth on subtree
		var d = getDepth() + 1;
		var e = child;
		var i = child.getSize() + 1;
		while (i-- > 0)
		{
			e.setDepth(e.getDepth() + d);
			e = e.next;
		}
		
		setLastChild(child);
		
		child.mBits &= ~BIT_PARENTLESS;
		child.onAdd();
		Es.testCallbacks(child, CallbackType.OnAdd);
		return cast child;
	}
	
	/**
		Removes `child` or this entity if `child` is omitted. 
		
		- finds and removes the entity `x` if `clss` is omitted.
		- finds and removes the first entity of type `clss` if `x` is omitted.
		- removes __this entity__ if called without arguments.
	**/
	public function remove<T:Entity>(child:Entity = null, ?clss:Class<T>)
	{
		assert(child != this);
		
		if (clss != null)
		{
			child = findChild(clss);
			assert(child != null);
			remove(child);
			return;
		}
		
		if (child == null)
		{
			//remove myself
			assert(parent != null);
			parent.remove(this);
			return;
		}
		
		assert(child != null);
		assert(child.parent != null);
		assert(child != this);
		assert(child.parent == this);
		
		//update #children
		setChildCount(childCount - 1);
		
		//update size on ancestors
		var k = child.getSize() + 1;
		setSize(getSize() - k);
		var n = parent;
		while (n != null)
		{
			n.setSize(n.getSize() - k);
			n = n.parent;
		}
		
		//case 1: first child is removed
		if (firstChild == child)
		{
			//first and only child?
			if (child.sibling == null) setLastChild(null);
			
			var i = child.getLastLeaf();
			
			setNext(i.next);
			i.setNext(null);
			setFirstChild(child.sibling);
			child.setSibling(null);
		}
		else
		{
			//case 2: second to last child is removed
			var pre = firstChild;
			while (pre != null) //find predecessor
			{
				if (pre.sibling == child) break;
				pre = pre.sibling;
			}
			
			assert(pre != null);
			
			//update lastChild
			if (child.sibling == null)
				setLastChild(pre);
			
			var i = pre.getLastLeaf();
			var j = child.getLastLeaf();
			
			i.setNext(j.next);
			j.setNext(null);
			
			pre.setSibling(child.sibling);
			child.setSibling(null);
		}
		
		//update depth on subtree
		var d = getDepth() + 1;
		var n = child;
		var i = child.getSize() + 1;
		while (i-- > 0)
		{
			n.setDepth(n.getDepth() - d);
			n = n.next;
		}
		
		child.mBits |= BIT_PARENTLESS;
		child.setParent(null);
		child.onRemove(this);
		Es.testCallbacks(child, CallbackType.OnRemove);
	}
	
	#if !debug @:extern #end
	public inline function sendMessageTo(recipient:Entity, type:Int, ?data:{})
		EntityMessaging.sendTo(this, recipient, type, data);
	
	#if !debug @:extern #end
	public inline function sendMessageToChildren(type:Int, ?data:{})
		EntityMessaging.sendToChildren(this, type, data);
	
	#if !debug @:extern #end
	public inline function sendMessageToDescendants(type:Int, ?data:{})
		EntityMessaging.sendToDescedants(this, type, data);
	
	#if !debug @:extern #end
	public inline function sendMessageToAncestors(type:Int, ?data:{})
		EntityMessaging.sendToAncestors(this, type, data);
	
	#if !debug @:extern #end
	public inline function flushMessageBuffer(?onFinish:Void->Void)
		EntityMessaging.flushBuffer(onFinish);
	
	#if !debug @:extern #end
	public inline function findChild<T:Entity>(clss:Class<T>, ?name:String):T
		return EntityTools.findChild(this, name, clss);
	
	#if !debug @:extern #end
	public inline function findChildByName(?name:String):Entity
		return EntityTools.findChild(this, name);
	
	#if !debug @:extern #end
	public inline function findSibling<T:Entity>(?name:String, ?clss:Class<T>):T
		return EntityTools.findSibling(this, name, clss);
	
	#if !debug @:extern #end
	public inline function findDescendant<T:Entity>(?name:String, ?clss:Class<T>):T
		return EntityTools.findDescendant(this, name, clss);
	
	#if !debug @:extern #end
	public inline function findAncestor<T:Entity>(?name:String, ?clss:Class<T>):T
		return EntityTools.findAncestor(this, name, clss);
	
	#if !debug @:extern #end
	inline public function sortChildrenByPhase() sortChildren(comparePhase);
	
	/**
		Convenience method for casting this Entity to the type `clss`.
	**/
	#if !debug @:extern #end
	public inline function as<T:Entity>(clss:Class<T>):T
	{
		#if flash
		return untyped __as__(this, clss);
		#else
		return cast this;
		#end
	}
	
	/**
		Convenience method for Std.is(this, `clss`);
	**/
	#if !debug @:extern #end
	public inline function is<T:Entity>(clss:Class<T>):Bool
	{
		#if flash
		return untyped __is__(this, clss);
		#else
		return Es._superLut.hasPair(type, getEntityType(clss));
		#end
	}
	
	#if debug
	public function toString()
	{
		return '[object Entity: name=$name]';
	}
	#end
	
	#if !debug @:extern #end
	inline function lookup<T:Entity>(clss:Class<T>):T return Es.lookup(clss);
	
	@:noCompletion function onAdd() {}
	
	@:noCompletion function onRemove(parent:Entity) {}
	
	@:noCompletion function onFree() {}
	
	@:noCompletion function onTick(dt:Float) {}
	
	@:noCompletion function onPostTick(dt:Float) {}
	
	@:noCompletion function onDraw(alpha:Float) {}
	
	@:noCompletion function onPostDraw(alpha:Float) {}
	
	@:noCompletion function onMessage(message:EntityMessage) {}
	
	@:noCompletion function _getType()
	{
		#if debug
		return Reflect.field(Type.getClass(this), "ENTITY_TYPE");
		#else
		return 0; //overriden by macro
		#end
	}
}