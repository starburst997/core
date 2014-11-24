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

import de.polygonal.core.es.Msg;
import de.polygonal.core.es.MsgQue;
import de.polygonal.core.util.Assert.assert;
import de.polygonal.core.util.ClassUtil;
import de.polygonal.core.es.EntitySystem in Es;

/**
	Base entity class.
**/
@:access(de.polygonal.core.es.EntitySystem)
@:access(de.polygonal.core.es.MsgQue)
@:build(de.polygonal.core.macro.IntEnum.build(
[
	BIT_SKIP_SUBTREE,
	BIT_SKIP_MSG,
	BIT_SKIP_TICK,
	BIT_SKIP_DRAW,
	BIT_STOP_PROPAGATION,
	BIT_MARK_FREE,
	BIT_NAME_PUBLISHED,
], true, false))
@:build(de.polygonal.core.es.EntityMacro.build())
@:autoBuild(de.polygonal.core.es.EntityMacro.build())
class Entity
{
	inline public static var REL_ANCESTOR = 0;
	inline public static var REL_CHILD = 1;
	inline public static var REL_DESCENDANT = 2;
	inline public static var REL_SIBLING = 3;
	//inline public static var REL_ROOT = 3;
	
	inline static function getEntityType<T:Entity>(C:Class<T>):Int
	{
		#if flash
		return untyped C.ENTITY_TYPE;
		#else
		return Reflect.field(C, "ENTITY_TYPE");
		#end
	}
	
	inline static function getMsgQue() return Es.mMsgQue;
	
	inline static function getInheritLut() return Es.mInheritanceLut;
	
	/**
		Every entity has an unique identifier.
	*/
	public var id(default, null):EntityId;
	
	/**
		Every subclass of the Entity class can be identified by a unique integer value.
	**/
	public var type(default, null):Int;
	
	/**
		A pointer to the next entity in a preorder sequence.
	**/
	public var preorder(default, null):Entity;
	
	@:noCompletion var mFlags:Int;
	@:noCompletion var mName:String;
	
	public function new(?name:String)
	{
		mFlags = 0;
		type = __getType();
		
		Es.register(this);
		
		#if debug
		if (name == null)
			name = ClassUtil.getUnqualifiedClassName(this);
		#end
		
		if (name != null) mName = name;
	}
	
	/**
		Recursively destroys the subtree rooted at this entity (including this entity) from the bottom up.
		
		This invokes the method `onFree` on each entity, giving each entity the opportunity to perform some cleanup (e.g. free resources or unregister from listeners).
	**/
	public function free()
	{
		if (mFlags & BIT_MARK_FREE > 0) return;
		
		if (parent != null) parent.remove(this);
		Es.freeEntityTree(this);
	}
	
	/**
		The parent or null if this is a top entity.
		
		__Never modify this value.__
	**/
	public var parent(get_parent, set_parent):Entity;
	@:noCompletion inline function get_parent():Entity
	{
		return Es.getParent(this);
	}
	@:noCompletion inline function set_parent(value:Entity)
	{
		Es.setParent(this, value);
		return value;
	}
	
	/**
		The first child or null if this entity has no children.
		
		__Don't modify this value.__
	**/
	public var child(get_child, set_child):Entity;
	@:noCompletion inline function get_child():Entity
	{
		return Es.getChild(this);
	}
	@:noCompletion inline function set_child(value:Entity)
	{
		Es.setChild(this, value);
		return value;
	}
	
	/**
		The next sibling or null if this entity has no sibling.
		
		__Don't modify this value.__
	**/
	public var sibling(get_sibling, set_sibling):Entity;
	@:noCompletion inline function get_sibling():Entity
	{
		return Es.getSibling(this);
	}
	@:noCompletion inline function set_sibling(value:Entity)
	{
		Es.setSibling(this, value);
		return value;
	}
	
	/**
		The last child or null if this entity has no children.
		
		__Don't modify this value.__
	**/
	public var lastChild(get_lastChild, set_lastChild):Entity;
	@:noCompletion inline function get_lastChild():Entity
	{
		return Es.getLastChild(this);
	}
	@:noCompletion inline function set_lastChild(value:Entity)
	{
		Es.setLastChild(this, value);
		return value;
	}
	
	/**
		The total number of child entities.
	**/
	public var numChildren(get_numChildren, set_numChildren):Int;
	@:noCompletion inline function get_numChildren():Int
	{
		return Es.getNumChildren(this);
	}
	@:noCompletion inline function set_numChildren(value:Int):Int
	{
		Es.setNumChildren(this, value);
		return value;
	}
	
	/**
		The total number of descendants.
	**/
	public var size(get_size, never):Int;
	@:noCompletion inline function get_size():Int
	{
		return Es.getSize(this);
	}
	
	/**
		The length of the path from the root node to this node.
		The root node is at depth 0.
	**/
	public var depth(get_depth, never):Int;
	@:noCompletion inline function get_depth():Int
	{
		return Es.getDepth(this);
	}
	
	/**
		The name of this entity. Default is null.
	 */
	public var name(get_name, set_name):String;
	@:noCompletion inline function get_name():String
	{
		return mName;
	}
	@:noCompletion function set_name(value:String):String
	{
		if (value == name) return value;
		if (mFlags & BIT_NAME_PUBLISHED > 0)
			Es.changeName(this, value);
		mName = value;
		return value;
	}
	
	/**
		If true, `MainLoop` updates this entity at regular intervals by invoking the onTick() method.
	**/
	public var tickable(get_tickable, set_tickable):Bool;
	@:noCompletion inline function get_tickable():Bool
	{
		return mFlags & BIT_SKIP_TICK == 0;
	}
	@:noCompletion function set_tickable(value:Bool):Bool
	{
		mFlags = value ? (mFlags & ~BIT_SKIP_TICK) : (mFlags | BIT_SKIP_TICK);
		return value;
	}
	
	/**
		If true, `MainLoop` renderes this entity at regular intervals by invoking the onDraw() method.
	**/
	public var drawable(get_drawable, set_drawable):Bool;
	@:noCompletion inline function get_drawable():Bool
	{
		return mFlags & BIT_SKIP_DRAW == 0;
	}
	@:noCompletion function set_drawable(value:Bool):Bool
	{
		mFlags = value ? (mFlags & ~BIT_SKIP_DRAW) : (mFlags | BIT_SKIP_DRAW);
		return value;
	}
	
	/**
		If true, this entity can receive messages. Default is true.
	**/
	public var notifiable(get_notifiable, set_notifiable):Bool;
	@:noCompletion inline function get_notifiable():Bool
	{
		return mFlags & BIT_SKIP_MSG == 0;
	}
	@:noCompletion function set_notifiable(value:Bool):Bool
	{
		mFlags = value ? (mFlags & ~BIT_SKIP_MSG) : (mFlags | BIT_SKIP_MSG);
		return value;
	}
	
	/**
		If false, skips updating the subtree rooted at this node. Default is true.
	**/
	public var passable(get_passable, set_passable):Bool;
	@:noCompletion inline function get_passable():Bool
	{
		return mFlags & BIT_SKIP_SUBTREE == 0;
	}
	@:noCompletion function set_passable(value:Bool):Bool
	{
		mFlags = value ? (mFlags & ~BIT_SKIP_SUBTREE) : (mFlags | BIT_SKIP_SUBTREE);
		return value;
	}
	
	/**
		A received message. __Only valid inside a msgTo*() method.__
	**/
	public var incomingMessage(get_incomingMessage, never):Msg;
	@:noCompletion function get_incomingMessage():Msg
	{
		return getMsgQue().getMsgIn();
	}
	
	/**
		A message that will be sent when calling msgTo*().
	**/
	public var outgoingMessage(get_outgoingMessage, never):Msg;
	@:noCompletion function get_outgoingMessage():Msg
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
		
		var x:Entity = inst;
		if (x == null)
			x = Type.createInstance(clss, []);
		
		assert(x.parent != this);
		assert(x.parent == null);
		
		x.parent = this;
		
		//update #children
		numChildren++;
		
		//update size on ancestors
		var k = x.size + 1;
		setSize(size + k);
		
		var p = parent;
		while (p != null)
		{
			p.setSize(p.size + k);
			p = p.parent;
		}
		
		if (child == null)
		{
			//case 1: without children
			child = x;
			x.sibling = null;
			
			//fix preorder pointer
			var i = findLastLeaf(x);
			i.preorder = preorder;
			preorder = x;
		}
		else
		{
			//case 2: with children
			//fix preorder pointers
			var i = findLastLeaf(lastChild);
			var j = findLastLeaf(x);
			
			j.preorder = i.preorder;
			i.preorder = x;
			
			lastChild.sibling = x;
		}
		
		//update depth on subtree
		var d = depth + 1;
		var e = x;
		var i = x.size + 1;
		while (i-- > 0)
		{
			e.setDepth(e.depth + d);
			e = e.preorder;
		}
		
		lastChild = x;
		
		x.onAdd();
		
		return cast x;
	}
	
	/**
		Removes a child entity and returns
		
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
		
		//update #children
		numChildren--;
		
		//update size on ancestors
		var k = x.size + 1;
		setSize(size - k);
		
		var n = parent;
		while (n != null)
		{
			n.setSize(n.size - k);
			n = n.parent;
		}
		
		//case 1: first child is removed
		if (child == x)
		{
			//update lastChild
			if (child.sibling == null)
				lastChild = null;
			
			var i = findLastLeaf(x);
			
			preorder = i.preorder;
			i.preorder = null;
			
			child = x.sibling;
			x.sibling = null;
		}
		else
		{
			//case 2: second to last child is removed
			var prev = child.findPredecessor(x);
			
			assert(prev != null);
			
			//update lastChild
			if (x.sibling == null)
				lastChild = prev;
			
			var i = findLastLeaf(prev);
			var j = findLastLeaf(x);
			
			i.preorder = j.preorder;
			j.preorder = null;
			
			prev.sibling = x.sibling;
			x.sibling = null;
		}
		
		//update depth on subtree
		var d = depth + 1;
		var n = x;
		var i = x.size + 1;
		while (i-- > 0)
		{
			n.setDepth(n.depth - d);
			n = n.preorder;
		}
		
		x.parent = null;
		x.onRemove(this);
		
		return;
	}
	
	/**
		Removes all child entities from this entity.
	**/
	public function removeChildren():Entity
	{
		var n = child;
		while (n != null)
		{
			var hook = n.sibling;
			
			var i = findLastLeaf(n);
			preorder = i.preorder;
			i.preorder = null;
			
			n.parent = n.sibling = null;
			n = hook;
		}
		
		child = null;
		lastChild = null;
		
		return this;
	}
	
	/**
		Returns the first ancestor of type `clss` (if `name` is omitted) or the first ancestor named `name` (if `clss` is omitted).
	**/
	public function findAncestor<T:Entity>(?clss:Class<T>, ?name:String):T
	{
		assert(clss == null || name == null);
		
		if (clss != null)
		{
			var p = parent;
			var n = p;
			var t = getEntityType(clss);
			while (n != null)
			{
				if (n.type == t) return cast n;
				n = n.parent;
			}
			n = p;
			var lut = getInheritLut();
			while (n != null)
			{
				if (lut.hasPair(n.type, t)) return cast n;
				n = n.parent;
			}
		}
		else
		{
			var n = parent;
			while (n != null)
			{
				if (n.name == name) return cast n;
				n = n.parent;
			}
		}
		
		return null;
	}
	
	/**
		Returns the first descendant of type `clss` (if `name` is omitted) or the first descendant named `name` (if `clss` is omitted).
	**/
	public function findDescendant<T:Entity>(?clss:Class<T>, ?name:String):T
	{
		assert(clss == null || name == null);
		
		if (clss != null)
		{
			var last =
			if (sibling != null)
				sibling;
			else
				findLastLeaf(this).preorder;
			var n = child;
			var t = getEntityType(clss);
			while (n != last)
			{
				if (t == n.type) return cast n;
				n = n.preorder;
			}
			n = child;
			var lut = getInheritLut();
			while (n != last)
			{
				if (lut.hasPair(n.type, t)) return cast n;
				n = n.preorder;
			}
		}
		else
		{
			var n = child;
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
		Returns the first child of type `clss` (if `name` is omitted) or the first child named `name` (if `clss` is omitted).
	**/
	public function findChild<T:Entity>(?clss:Class<T>, ?name:String):T
	{
		assert(clss == null || name == null);
		
		var c = null;
		
		if (clss != null)
		{
			var n = child;
			var t = getEntityType(clss);
			while (n != null)
			{
				if (t == n.type) return cast n;
				n = n.sibling;
			}
			n = child;
			var lut = getInheritLut();
			while (n != null)
			{
				if (lut.hasPair(n.type, t)) return cast n;
				n = n.sibling;
			}
		}
		else
		{
			var n = child;
			while (n != null)
			{
				if (n.name == name) return cast n;
				n = n.sibling;
			}
		}
		
		return null;
	}
	
	/**
		Returns the first sibling of type `clss` (if `name` is omitted) or the first sibling named `name` (if `clss` is omitted).
	**/
	public function findSibling<T:Entity>(?clss:Class<T>, ?name:String):T
	{
		assert(clss == null || name == null);
		
		if (parent == null) return null;
		
		if (clss != null)
		{
			var n = parent.child;
			var t = getEntityType(clss);
			while (n != null)
			{
				if (n != this)
					if (t == n.type)
						return cast n;
				n = n.sibling;
			}
			n = parent.child;
			var lut = getInheritLut();
			while (n != null)
			{
				if (n != this)
					if (lut.hasPair(n.type, t)) return cast n;
				n = n.sibling;
			}
		}
		else
		{
			var n = parent.child;
			while (n != null)
			{
				if (n.name == name) return cast n;
				n = n.sibling;
			}
		}
		
		return null;
	}
	
	//TODO single message func?
	
	/**
		Sends a message of type `msgType` to `entity`.
		
		If `dispatch` is true, the message will leave the message queue immediately.
	**/
	public function msgTo(entity:Entity, msgType:Int, dispatch:Bool = false):Entity
	{
		var q = getMsgQue();
		if (entity != null)
			q.enqueue(this, entity, msgType, 0, 0);
		else
		{
			q.clrMessage();
			dispatch = false;
		}
		if (dispatch) q.dispatch();
		return this;
	}
	
	/**
		Sends a message of type `msgType` to the parent entity.
		
		If `dispatch` is true, the message will leave the message queue immediately.
	**/
	public function msgToParent(msgType:Int, dispatch = false):Entity
	{
		var e = parent;
		var q = getMsgQue();
		if (e != null)
			q.enqueue(this, e, msgType, 0, -1);
		else
		{
			q.clrMessage();
			dispatch = false;
		}
		
		if (dispatch) q.dispatch();
		
		return this;
	}
	
	/**
		Sends a message of type `msgType` to all ancestors.
		
		If `dispatch` is true, the message will leave the message queue immediately.
	**/
	public function msgToAncestors(msgType:Int, dispatch = false):Entity
	{
		var q = getMsgQue();
		var e = parent;
		if (e == null)
		{
			q.clrMessage();
			return this;
		}
		
		var k = depth;
		if (k == 0) dispatch = false;
		while (k-- > 0)
		{
			q.enqueue(this, e, msgType, k, -1);
			e = e.parent;
		}
		
		if (dispatch) q.dispatch();
		return this;
	}
	
	/**
		Sends a message of type `msgType` to all descendants.
		
		If `dispatch` is true, the message will leave the message queue immediately.
	**/
	public function msgToDescendants(msgType:Int, dispatch = false):Entity
	{
		var q = getMsgQue();
		var e = child;
		if (e == null)
		{
			q.clrMessage();
			return this;
		}
		var k = size;
		if (k == 0) dispatch = false;
		while (k-- > 0)
		{
			q.enqueue(this, e, msgType, k, 1);
			e = e.preorder;
		}
		
		if (dispatch) q.dispatch();
		return this;
	}
	
	/**
		Sends a message of type `msgType` to all children.
		
		If `dispatch` is true, the message will leave the message queue immediately.
	**/
	public function msgToChildren(msgType:Int, dispatch = false):Entity
	{
		var q = getMsgQue();
		var e = child;
		if (e == null)
		{
			q.clrMessage();
			return this;
		}
		var k = numChildren;
		if (k == 0) dispatch = false;
		while (k-- > 0)
		{
			q.enqueue(this, e, msgType, k, 1);
			e = e.sibling;
		}
		
		if (dispatch) q.dispatch();
		return this;
	}
	
	/**
		Returns the child index of this entity or -1 if this entity has no parent.
	**/
	public function getChildIndex():Int
	{
		var p = parent;
		if (p == null) return -1;
		
		var i = 0;
		var e = p.child;
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
		var e = child;
		for (i in 0...index)
			e = e.sibling;
		return e;
	}
	
	/**
		Successively swaps this entity with its previous siblings until it becomes the first sibling.
	**/
	public function setFirst()
	{
		if (parent == null) return; //no parent?
		if (parent.child == this) return; //first child?
		
		var c = parent.child;
		var pre = c.findPredecessor(this);
		
		if (sibling == null)
			parent.lastChild = this;
		
		pre.preorder = preorder;
		pre.sibling = sibling;
		preorder = sibling = c;
		parent.child = parent.preorder = this;
	}
	
	/**
		Successively swaps this entity with its next siblings until it becomes the last sibling.
	**/
	public function setLast()
	{
		if (parent == null || sibling == null) return; //no parent or already last?
		
		var c = parent.child;
		if (c == this) //first child?
		{
			while (c.sibling != null) c = c.sibling; //find last child
			c.sibling = this;
			
			preorder = c.preorder;
			c.preorder = this;
			parent.child = parent.preorder = sibling;
		}
		else
		{
			while (c != null) //find predecessor to this
			{
				if (c.sibling == this) break;
				c = c.sibling;
			}
			
			c.sibling = c.preorder = sibling;
			sibling.sibling = this;
			preorder = sibling.preorder;
			sibling.preorder = this;
		}
		
		sibling = null;
		parent.lastChild = this;
	}
	
	/**
		Stops message propagation if called inside `onMsg()`.
	**/
	inline function stop()
	{
		mFlags |= BIT_STOP_PROPAGATION;
	}
	
	/**
		Convenience method for casting this Entity to the type `clss`.
	**/
	inline function as<T:Entity>(clss:Class<T>):T
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
	inline function is<T>(clss:Class<T>):Bool
	{
		#if flash
		return untyped __is__(this, clss);
		#else
		return Std.is(this, clss);
		#end
	}
	
	/**
		Handles multiple calls to `is()` in one shot by checking all classes in `x` against this class.
	**/
	public function isAny(clss:Array<Class<Dynamic>>):Bool
	{
		for (i in clss)
			if (is(cast i))
				return true;
		return false;
	}
	
	inline function publish(name:String)
	{
		assert(mFlags & BIT_NAME_PUBLISHED == 0);
		this.name = name;
		mFlags |= BIT_NAME_PUBLISHED;
		Es.changeName(this, mName);
	}
	
	public function toString():String
	{
		if (name == null) name = '[${ClassUtil.getClassName(this)}]';
		return '{ Entity $name }';
	}
	
	@:noCompletion function onAdd() {}
	
	@:noCompletion function onRemove(parent:Entity) {}
	
	@:noCompletion function onFree() {}
	
	@:noCompletion function onTick(dt:Float) {}
	
	@:noCompletion function onDraw(alpha:Float) {}
	
	@:noCompletion function onMsg(msgType:Int, sender:Entity) {}
	
	@:noCompletion inline function findPredecessor(e:Entity):Entity
	{
		assert(parent == e.parent);
		 
		var i = this;
		while (i != null)
		{
			if (i.sibling == e) break;
			i = i.sibling;
		}
		return i;
	}
	
	@:noCompletion inline function findLastLeaf(e:Entity):Entity
	{
		//find bottom-most, right-most entity in this subtree
		while (e.child != null) e = e.lastChild;
		return e;
	}
	
	@:noCompletion inline function nextSubtree():Entity
	{
		return
		if (sibling != null)
			sibling;
		else
			findLastLeaf(this).preorder;
	}
	
	@:noCompletion inline function setSize(value:Int)
	{
		Es.setSize(this, value);
	}
	
	@:noCompletion inline function setDepth(value:Int)
	{
		Es.setDepth(this, value);
	}
	
	@:noCompletion function __getType() return 0; //overriden by macro
}