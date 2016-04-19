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

import de.polygonal.core.es.EntityMessage;
import de.polygonal.core.es.EntityMessageQue;
import de.polygonal.core.util.Assert.assert;
import de.polygonal.core.util.ClassUtil;
import de.polygonal.core.es.EntitySystem in Es;
import de.polygonal.ds.Bits;

using de.polygonal.core.es.EntitySystem;

/**
	Base entity class
**/
@:keep
@:keepSub
@:access(de.polygonal.core.es.EntitySystem)
@:access(de.polygonal.core.es.EntityMessageQue)
@:build(de.polygonal.core.macro.IntConsts.build(
[
	BIT_SKIP_SUBTREE,
	BIT_SKIP_MSG,
	BIT_SKIP_TICK,
	BIT_SKIP_POST_TICK,
	BIT_SKIP_DRAW,
	BIT_SKIP_POST_DRAW,
	BIT_STOP_PROPAGATION,
	BIT_FREED,
	BIT_IS_GLOBAL,
	BIT_NO_PARENT
], true, false))
@:build(de.polygonal.core.es.EntityMacro.build())
@:autoBuild(de.polygonal.core.es.EntityMacro.build())
class Entity
{
	inline static var FLAG_BITS = 10;
	inline static var PHASE_BITS = 6;
	inline static var TYPE_BITS = 16;
	
	inline static function getEntityType<T:Entity>(clss:Class<T>):Int
	{
		#if flash
			#if aot
			return untyped Std.int(clss["ENTITY_TYPE"]); //Float->Int, see EntityMacro
			#else
			return untyped clss["ENTITY_TYPE"];
			#end
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
	
	inline static function getMsgQue() return Es._msgQue;
	
	inline static function getInheritLut() return Es._inheritanceLut;
	
	/**
		Every entity has an unique identifier.
	*/
	public var id(default, null):EntityId;
	
	/**
		Every subclass of the Entity class can be identified by an unique integer value.
	**/
	public var type(get, never):Int;
	inline function get_type():Int return mBits >>> (FLAG_BITS + PHASE_BITS);
	
	/**
		Execution order in the range [0, 15] (smaller value equals higher priority); only effective after calling `applyPhase()`.
		Default is 0.
	**/
	public var phase(get, set):Int;
	inline function get_phase():Int return (mBits >>> FLAG_BITS) & Bits.mask(PHASE_BITS);
	inline function set_phase(value:Int):Int
	{
		assert(value >= 0 && value < (2 << (PHASE_BITS - 1)));
		
		mBits |= value << FLAG_BITS;
		return value;
	}
	
	/**
		The name of this entity.
		
		Default is null.
	**/
	public var name(default, null):String;
	
	@:noCompletion var mBits:Int;
	
	public function new(?name:String, isGlobal:Bool = false)
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
				
				trace("assign " + entityId + " to " + entityName);
				Reflect.setField(cl, "ENTITY_TYPE", entityId);
			}
		}
		#end
		
		assert(__getType() < (2 << (TYPE_BITS - 1)));
		
		mBits = (__getType() << (FLAG_BITS + PHASE_BITS)) | BIT_NO_PARENT | BIT_SKIP_POST_TICK | BIT_SKIP_POST_DRAW;
		
		if (isGlobal && name == null) name = Reflect.field(Type.getClass(this), "ENTITY_NAME");
		
		#if debug
		if (name == null) name = "DEBUG_" + ClassUtil.getClassName(this);
		#end
		
		this.name = name;
		
		Es.register(this, isGlobal);
	}
	
	/**
		Recursively destroys the subtree rooted at this entity (including this entity) from the bottom up.
		
		This invokes``onFree()`` on each entity, giving each entity the opportunity to perform some cleanup (e.g. free resources or unregister from listeners).
	**/
	public function free()
	{
		if (mBits & BIT_FREED > 0) return;
		
		if (parent != null) parent.remove(this);
		Es.freeEntityTree(this);
		Es._treeChanged = true;
	}
	
	/**
		A pointer to the next entity in a preorder sequence.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var preorder(get, set):Entity;
	@:noCompletion inline function get_preorder():Entity
	{
		assert(mBits & BIT_FREED == 0);
		
		return Es.getPreorder(this);
	}
	@:noCompletion inline function set_preorder(value:Entity)
	{
		Es.setPreorder(this, value);
		return value;
	}
	
	/**
		The parent or null if this is a top entity.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var parent(get, set):Entity;
	@:noCompletion inline function get_parent():Entity
	{
		assert(mBits & BIT_FREED == 0);
		
		return Es.getParent(this);
	}
	@:noCompletion inline function set_parent(value:Entity)
	{
		Es.setParent(this, value);
		return value;
	}
	
	/**
		The first child or null if this entity has no children.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var firstChild(get, set):Entity;
	@:noCompletion inline function get_firstChild():Entity
	{
		assert(mBits & BIT_FREED == 0);
		
		return Es.getFirstChild(this);
	}
	@:noCompletion inline function set_firstChild(value:Entity)
	{
		Es.setFirstChild(this, value);
		return value;
	}
	
	/**
		The last child or null if this entity has no children.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var lastChild(get, set):Entity;
	@:noCompletion inline function get_lastChild():Entity
	{
		assert(mBits & BIT_FREED == 0);
		
		return Es.getLastChild(this);
	}
	@:noCompletion inline function set_lastChild(value:Entity)
	{
		Es.setLastChild(this, value);
		return value;
	}
	
	/**
		The next sibling or null if this entity has no sibling.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var sibling(get, set):Entity;
	@:noCompletion inline function get_sibling():Entity
	{
		assert(mBits & BIT_FREED == 0);
		
		return Es.getSibling(this);
	}
	@:noCompletion inline function set_sibling(value:Entity)
	{
		Es.setSibling(this, value);
		return value;
	}
	
	/**
		The total number of child entities.
	**/
	public var numChildren(get, set):Int;
	@:noCompletion inline function get_numChildren():Int
	{
		assert(mBits & BIT_FREED == 0);
		
		return Es.getNumChildren(this);
	}
	@:noCompletion inline function set_numChildren(value:Int):Int
	{
		Es.setNumChildren(this, value);
		return value;
	}
	
	/**
		If true, ``MainLoop`` updates this entity at regular intervals by invoking the ``onTick(dt, false)`` method.
	**/
	public var tickable(get, set):Bool;
	@:noCompletion inline function get_tickable():Bool return mBits & BIT_SKIP_TICK == 0;
	@:noCompletion function set_tickable(value:Bool):Bool
	{
		value ? mBits &= ~BIT_SKIP_TICK : mBits |= BIT_SKIP_TICK;
		return value;
	}
	
	/**
		If true, ``MainLoop`` updates this entity at regular intervals by invoking the ``onTick(dt, true)`` method.
	**/
	public var postTickable(get, set):Bool;
	inline function get_postTickable():Bool return mBits & BIT_SKIP_POST_TICK == 0;
	function set_postTickable(value:Bool):Bool
	{
		value ? mBits &= ~BIT_SKIP_POST_TICK : mBits |= BIT_SKIP_POST_TICK;
		return value;
	}
	
	/**
		If true, ``MainLoop`` renderes this entity at regular intervals by invoking the ``onDraw()`` method.
	**/
	public var drawable(get, set):Bool;
	@:noCompletion inline function get_drawable():Bool
	{
		return mBits & BIT_SKIP_DRAW == 0;
	}
	@:noCompletion function set_drawable(value:Bool):Bool
	{
		value ? mBits &= ~BIT_SKIP_DRAW : mBits |= BIT_SKIP_DRAW;
		return value;
	}
	
	public var postDrawable(get, set):Bool;
	inline function get_postDrawable():Bool return mBits & BIT_SKIP_POST_DRAW == 0;
	function set_postDrawable(value:Bool):Bool
	{
		value ? mBits &= ~BIT_SKIP_POST_DRAW : mBits |= BIT_SKIP_POST_DRAW;
		return value;
	}
	
	/**
		If true, this entity can receive messages.
		
		Default is true.
	**/
	public var notifiable(get, set):Bool;
	@:noCompletion inline function get_notifiable():Bool
	{
		return mBits & BIT_SKIP_MSG == 0;
	}
	@:noCompletion function set_notifiable(value:Bool):Bool
	{
		value ? mBits &= ~BIT_SKIP_MSG : mBits |= BIT_SKIP_MSG;
		return value;
	}
	
	/**
		If false, skips updating the subtree rooted at this node.
		
		Default is true.
	**/
	public var passable(get, set):Bool;
	@:noCompletion inline function get_passable():Bool
	{
		return mBits & BIT_SKIP_SUBTREE == 0;
	}
	@:noCompletion function set_passable(value:Bool):Bool
	{
		value ? mBits &= ~BIT_SKIP_SUBTREE : mBits |= BIT_SKIP_SUBTREE;
		Es._treeChanged = true;
		return value;
	}
	
	/**
		An incoming message.
		
		<warn>Only valid inside ``onMsg()``.</warn>
	**/
	public var incomingMessage(get, never):EntityMessage;
	@:noCompletion function get_incomingMessage():EntityMessage
	{
		return getMsgQue().getMsgIn();
	}
	
	/**
		A message that will be sent when calling ``EntitySystem::dispatchMessages()``.
	**/
	public var outgoingMessage(get, never):EntityMessage;
	@:noCompletion function get_outgoingMessage():EntityMessage
	{
		return getMsgQue().getMsgOut();
	}
	
	/**
		Adds a child entity to this entity and returns the newly added entity.
		
		- if `inst` is omitted, creates and adds an instance of the class `clss` to this entity.
		- if `clss` is omitted, adds `inst` to this entity.
	**/
	public function add<T:Entity>(?clss:Class<T>, ?inst:T):T
	{
		assert(clss != null || inst != null);
		
		Es._treeChanged = true;
		
		var x:Entity = inst;
		if (x == null)
			x = Type.createInstance(clss, []);
		
		assert(x.parent != this);
		assert(x.parent == null);
		
		x.parent = this;
		
		//update #children
		numChildren++;
		
		//update size on ancestors
		var k = x.getSize() + 1;
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
			firstChild = x;
			x.sibling = null;
			
			//fix preorder pointer
			var i = x.findLastLeaf();
			i.preorder = preorder;
			preorder = x;
		}
		else
		{
			//case 2: with children
			//fix preorder pointers
			var i = lastChild.findLastLeaf();
			var j = x.findLastLeaf();
			
			j.preorder = i.preorder;
			i.preorder = x;
			
			lastChild.sibling = x;
		}
		
		//update depth on subtree
		var d = getDepth() + 1;
		var e = x;
		var i = x.getSize() + 1;
		while (i-- > 0)
		{
			e.setDepth(e.getDepth() + d);
			e = e.preorder;
		}
		
		lastChild = x;
		
		x.mBits &= ~BIT_NO_PARENT;
		x.onAdd();
		return cast x;
	}
	
	/**
		Removes a child entity or this entity.
		
		- finds and removes the entity `x` if `clss` is omitted.
		- finds and removes the first entity of type `clss` if `x` is omitted.
		- removes __this entity__ if called without arguments.
	**/
	public function remove<T:Entity>(x:Entity = null, ?clss:Class<T>)
	{
		assert(x != this);
		
		if (clss != null)
		{
			x = findChild(clss);
			
			assert(x != null);
			remove(x);
			return;
		}
		
		if (x == null)
		{
			//remove myself
			assert(parent != null);
			parent.remove(this);
			return;
		}
		
		assert(x.parent != null);
		assert(x != this);
		assert(x.parent == this);
		
		Es._treeChanged = true;
		
		//update #children
		numChildren--;
		
		//update size on ancestors
		var k = x.getSize() + 1;
		setSize(getSize() - k);
		
		var n = parent;
		while (n != null)
		{
			n.setSize(n.getSize() - k);
			n = n.parent;
		}
		
		//case 1: first child is removed
		if (firstChild == x)
		{
			//update lastChild
			if (firstChild.sibling == null)
				lastChild = null;
			
			var i = x.findLastLeaf();
			
			preorder = i.preorder;
			i.preorder = null;
			
			firstChild = x.sibling;
			x.sibling = null;
		}
		else
		{
			//case 2: second to last child is removed
			var prev = firstChild;
			while (prev != null) //find predecessor
			{
				if (prev.sibling == x) break;
				prev = prev.sibling;
			}
			
			assert(prev != null);
			
			//update lastChild
			if (x.sibling == null)
				lastChild = prev;
			
			var i = prev.findLastLeaf();
			var j = x.findLastLeaf();
			
			i.preorder = j.preorder;
			j.preorder = null;
			
			prev.sibling = x.sibling;
			x.sibling = null;
		}
		
		//update depth on subtree
		var d = getDepth() + 1;
		var n = x;
		var i = x.getSize() + 1;
		while (i-- > 0)
		{
			n.setDepth(n.getDepth() - d);
			n = n.preorder;
		}
		
		x.mBits |= BIT_NO_PARENT;
		x.parent = null;
		x.onRemove(this);
	}
	
	/**
		Removes all child entities from this entity.
	**/
	public function removeChildren()
	{
		var c = firstChild;
		
		if (c == null) return;
		
		var next, p, d, k = getSize();
		while (c != null)
		{
			next = c.sibling;
			
			c.findLastLeaf().preorder = null;
			
			d = c.getDepth();
			p = c.preorder;
			while (p != null)
			{
				p.setDepth(p.getDepth() - d);
				p = p.preorder;
			}
			c.setDepth(0);
			
			c.sibling = c.parent = null;
			c.mBits |= BIT_NO_PARENT;
			c.onRemove(this);
			
			c = next;
		}
		
		firstChild = lastChild = null;
		preorder = sibling;
		numChildren = 0;
		
		//update size on ancestors
		var n = parent;
		while (n != null)
		{
			n.setSize(n.getSize() - k);
			n = n.parent;
		}
		setSize(0);
		
		Es._treeChanged = true;
	}
	
	/**
		Finds the first child that matches the given `name` or class (`clss`) or both.
	**/
	public function findChild<T:Entity>(?name:String, ?clss:Class<T>):T
	{
		var n, t, lut;
		
		if (name != null && clss != null)
		{
			n = firstChild;
			t = getEntityType(clss);
			while (n != null)
			{
				if (t == n.type && name == n.name) return cast n;
				n = n.sibling;
			}
			n = firstChild;
			lut = getInheritLut();
			while (n != null)
			{
				if (lut.hasPair(n.type, t) && n.name == name) return cast n;
				n = n.sibling;
			}
		}
		else
		if (clss != null)
		{
			n = firstChild;
			t = getEntityType(clss);
			while (n != null)
			{
				if (t == n.type) return cast n;
				n = n.sibling;
			}
			n = firstChild;
			lut = getInheritLut();
			while (n != null)
			{
				if (lut.hasPair(n.type, t)) return cast n;
				n = n.sibling;
			}
		}
		else
		{
			n = firstChild;
			while (n != null)
			{
				if (n.name == name) return cast n;
				n = n.sibling;
			}
		}
		return null;
	}
	
	/**
		Finds the first sibling that matches the given `name` or class (`clss`) or both.
	**/
	public function findSibling<T:Entity>(?name:String, ?clss:Class<T>):T
	{
		if (parent == null) return null;
		
		var n, t, lut;
		
		if (name != null && clss != null)
		{
			n = parent.firstChild;
			t = getEntityType(clss);
			while (n != null)
			{
				if (n != this)
					if (t == n.type && name == n.name)
						return cast n;
				n = n.sibling;
			}
			n = parent.firstChild;
			lut = getInheritLut();
			while (n != null)
			{
				if (n != this)
				{
					if (lut.hasPair(n.type, t) && name == n.name)
						return cast n;
				}
				n = n.sibling;
			}
		}
		else
		if (clss != null)
		{
			n = parent.firstChild;
			t = getEntityType(clss);
			while (n != null)
			{
				if (n != this)
					if (t == n.type)
						return cast n;
				n = n.sibling;
			}
			n = parent.firstChild;
			lut = getInheritLut();
			while (n != null)
			{
				if (n != this)
				{
					if (lut.hasPair(n.type, t))
						return cast n;
				}
				n = n.sibling;
			}
		}
		else
		{
			n = parent.firstChild;
			while (n != null)
			{
				if (n.name == name) return cast n;
				n = n.sibling;
			}
		}
		return null;
	}
	
	/**
		Finds the first ancestor that matches the given `name` or class (`clss`) or both.
	**/
	public function findAncestor<T:Entity>(?name:String, ?clss:Class<T>):T
	{
		var n, t, lut;
		
		if (clss != null && name != null)
		{
			var p = parent;
			n = p;
			t = getEntityType(clss);
			while (n != null)
			{
				if (n.type == t && name == n.name) return cast n;
				n = n.parent;
			}
			n = p;
			lut = getInheritLut();
			while (n != null)
			{
				if (lut.hasPair(n.type, t) && name == n.name) return cast n;
				n = n.parent;
			}
		}
		else
		if (clss != null)
		{
			var p = parent;
			n = p;
			t = getEntityType(clss);
			while (n != null)
			{
				if (n.type == t) return cast n;
				n = n.parent;
			}
			n = p;
			lut = getInheritLut();
			while (n != null)
			{
				if (lut.hasPair(n.type, t)) return cast n;
				n = n.parent;
			}
		}
		else
		{
			n = parent;
			while (n != null)
			{
				if (n.name == name) return cast n;
				n = n.parent;
			}
		}
		return null;
	}
	
	/**
		Finds the first descendant that matches the given `name` or class (`clss`) or both.
	**/
	public function findDescendant<T:Entity>(?name:String, ?clss:Class<T>):T
	{
		var n, t, lut;
		
		if (clss != null && name != null)
		{
			var last =
			if (sibling != null)
				sibling;
			else
				findLastLeaf().preorder;
			n = firstChild;
			t = getEntityType(clss);
			while (n != last)
			{
				if (t == n.type && name == n.name) return cast n;
				n = n.preorder;
			}
			n = firstChild;
			lut = getInheritLut();
			while (n != last)
			{
				if (lut.hasPair(n.type, t) && name == n.name) return cast n;
				n = n.preorder;
			}
		}
		else
		if (clss != null)
		{
			var last =
			if (sibling != null)
				sibling;
			else
				findLastLeaf().preorder;
			n = firstChild;
			t = getEntityType(clss);
			while (n != last)
			{
				if (t == n.type) return cast n;
				n = n.preorder;
			}
			n = firstChild;
			lut = getInheritLut();
			while (n != last)
			{
				if (lut.hasPair(n.type, t)) return cast n;
				n = n.preorder;
			}
		}
		else
		{
			n = firstChild;
			var last = sibling;
			while (n != last)
			{
				if (n.name == name) return cast n;
				n = n.preorder;
			}
		}
		return null;
	}
	
	/**
		Sends a message of type `msgType` to `recipient`.
		
		If `dispatch` is true, the message will leave the message queue immediately.
	**/
	public function sendDirectMessage(recipient:Entity, msgType:Int, dispatch:Bool = false)
	{
		var q = getMsgQue();
		var e = recipient;
		if (e != null)
			q.enqueue(this, e, msgType, 0, 0);
		else
		{
			q.clrMessage();
			dispatch = false;
		}
		
		if (dispatch) q.dispatch();
	}
	
	/**
		Sends a message of type `msgType` to the parent entity.
		
		If `dispatch` is true, the message will leave the message queue immediately.
	**/
	public function sendMessageToParent(msgType:Int, dispatch = false)
	{
		var q = getMsgQue();
		var e = parent;
		if (e != null)
			q.enqueue(this, e, msgType, 0, -1);
		else
		{
			q.clrMessage();
			return;
		}
		
		if (dispatch) q.dispatch();
	}
	
	/**
		Sends a message of type `msgType` to all ancestors.
		
		If `dispatch` is true, the message will leave the message queue immediately.
	**/
	public function sendMessageToAncestors(msgType:Int, dispatch = false)
	{
		var q = getMsgQue();
		var e = parent;
		if (e == null)
		{
			q.clrMessage();
			return;
		}
		
		var k = getDepth();
		if (k == 0) dispatch = false;
		while (k-- > 0)
		{
			q.enqueue(this, e, msgType, k, -1);
			e = e.parent;
		}
		
		if (dispatch) q.dispatch();
	}
	
	/**
		Sends a message of type `msgType` to all descendants.
		
		If `dispatch` is true, the message will leave the message queue immediately.
	**/
	public function sendMessageToDescendants(msgType:Int, dispatch = false)
	{
		var q = getMsgQue();
		var e = firstChild;
		if (e == null)
		{
			q.clrMessage();
			return;
		}
		var k = getSize();
		if (k == 0) dispatch = false;
		while (k-- > 0)
		{
			q.enqueue(this, e, msgType, k, 1);
			e = e.preorder;
		}
		
		if (dispatch) q.dispatch();
	}
	
	/**
		Sends a message of type `msgType` to all children.
		
		If `dispatch` is true, the message will leave the message queue immediately.
	**/
	public function sendMessageToChildren(msgType:Int, dispatch = false)
	{
		var q = getMsgQue();
		var e = firstChild;
		if (e == null)
		{
			q.clrMessage();
			return;
		}
		var k = numChildren;
		if (k == 0) dispatch = false;
		while (k-- > 0)
		{
			q.enqueue(this, e, msgType, k, 1);
			e = e.sibling;
		}
		
		if (dispatch) q.dispatch();
	}
	
	/**
		Returns the child index of this entity or -1 if this entity has no parent.
	**/
	public function getChildIndex():Int
	{
		var p = parent;
		if (p == null) return -1;
		
		var i = 0;
		var e = p.firstChild;
		while (e != this)
		{
			i++;
			e = e.sibling;
		}
		return i;
	}
	
	/**
		Returns the child at `index` (zero-based).
	**/
	public function getChildAt(index:Int):Entity
	{
		assert(index >= 0 && index < numChildren, 'index $index out of range');
		var i = 0;
		var e = firstChild;
		for (i in 0...index) e = e.sibling;
		return e;
	}
	
	/**
		Sort children by phase.
	**/
	public function applyPhase()
	{
		if (numChildren < 1) return;
		
		//quick test if sorting is necessary
		var sorted = true;
		var c = firstChild;
		var p = c.phase;
		c = c.sibling;
		while (c != null)
		{
			if (c.phase < p)
			{
				sorted = false;
				break;
			}
			c = c.sibling;
		}
		
		if (sorted) return;
		
		Es._treeChanged = true;
		
		var t = lastChild.findLastLeaf().preorder;
		
		//merge sort taken from de.polygonal.ds.Sll
		var h = firstChild;
		var p, q, e, tail = null;
		var insize = 1;
		var nmerges, psize, qsize, i;
		while (true)
		{
			p = h;
			h = tail = null;
			nmerges = 0;
			while (p != null)
			{
				nmerges++;
				psize = 0; q = p;
				for (i in 0...insize)
				{
					psize++;
					q = q.sibling;
					if (q == null) break;
				}
				qsize = insize;
				while (psize > 0 || (qsize > 0 && q != null))
				{
					if (psize == 0)
					{
						e = q;
						q = q.sibling;
						qsize--;
					}
					else
					if (qsize == 0 || q == null)
					{
						e = p;
						p = p.sibling;
						psize--;
					}
					else
					if (q.phase - p.phase >= 0)
					{
						e = p;
						p = p.sibling;
						psize--;
					}
					else
					{
						e = q;
						q = q.sibling;
						qsize--;
					}
					
					if (tail != null)
						tail.sibling = e;
					else
						h = e;
					
					tail = e;
				}
				p = q;
			}
			tail.sibling = null;
			if (nmerges <= 1) break;
			insize <<= 1;
		}
		
		firstChild = h;
		lastChild = tail;
		
		//rebuild preorder links
		preorder = firstChild;
		var c = firstChild;
		var l = lastChild;
		while (c != l)
		{
			c.findLastLeaf().preorder = c.sibling;
			c = c.sibling;
		}
		lastChild.findLastLeaf().preorder = t;
	}
	
	/**
		Convenience method for casting this Entity to the type `clss`.
	**/
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
	public inline function is<T:Entity>(clss:Class<T>):Bool
	{
		#if flash
		return untyped __is__(this, clss);
		#else
		return getInheritLut().hasPair(type, getEntityType(clss));
		#end
	}
	
	/**
		Stops message propagation to the subtree rooted at this entity if called inside `onMsg()`.
	**/
	inline function stop()
	{
		mBits |= BIT_STOP_PROPAGATION;
	}
	
	public function toString():String
	{
		if (name == null) name = '[${ClassUtil.getClassName(this)}]';
		return '{ Entity $name }';
	}
	
	inline function lookup<T:Entity>(clss:Class<T>):T return Es.lookup(clss);
	
	@:noCompletion function onAdd() {}
	
	@:noCompletion function onRemove(parent:Entity) {}
	
	@:noCompletion function onFree() {}
	
	@:noCompletion function onTick(dt:Float, post:Bool) {}
	
	@:noCompletion function onDraw(alpha:Float, post:Bool) {}
	
	@:noCompletion function onMsg(msgType:Int, sender:Entity) {}
	
	@:noCompletion function __getType()
	{
		#if debug
		return Reflect.field(Type.getClass(this), "ENTITY_TYPE");
		#else
		return 0; //overriden by macro
		#end
	}
}