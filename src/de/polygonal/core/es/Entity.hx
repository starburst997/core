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
	Base entity class
**/
@:access(de.polygonal.core.es.EntitySystem)
@:access(de.polygonal.core.es.MsgQue)
@:build(de.polygonal.core.macro.IntConsts.build(
[
	BIT_SKIP_SUBTREE,
	BIT_SKIP_MSG,
	BIT_SKIP_TICK,
	BIT_SKIP_DRAW,
	BIT_STOP_PROPAGATION,
	BIT_MARK_FREE,
	BIT_NAME_PUBLISHED,
	BIT_NO_PARENT
], true, false))
@:build(de.polygonal.core.es.EntityMacro.build())
@:autoBuild(de.polygonal.core.es.EntityMacro.build())
@:keep
@:keepSub
class Entity
{
	inline static var ID_ANCESTOR = 1;
	inline static var ID_CHILD = 2;
	inline static var ID_DESCENDANT = 3;
	inline static var ID_PARENT = 4;
	inline static var ID_SIBLING = 5;
	
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
	
	inline static function getMsgQue() return EntitySystem.mMsgQue;
	
	inline static function getInheritLut() return EntitySystem.mInheritanceLut;
	
	/**
		Every entity has an unique identifier.
	*/
	public var id(default, null):EntityId;
	
	/**
		Every subclass of the Entity class can be identified by an unique integer value.
	**/
	public var type(default, null):Int;
	
	/**
		A pointer to the next entity in a preorder sequence.
	**/
	public var preorder(default, null):Entity;
	
	public var phase:Int = -1;
	
	/**
		The name of this entity.
		
		Default is null.
	**/
	public var name(default, null):String = null;
	
	@:noCompletion var mFlags:Int;
	
	public function new(?name:String, isGlobal:Bool = false)
	{
		mFlags = BIT_NO_PARENT;
		type = __getType();
		
		if (isGlobal && name == null)
			name = Reflect.field(Type.getClass(this), "ENTITY_NAME");
		
		this.name = name;
		
		EntitySystem.register(this, isGlobal);
	}
	
	/**
		Recursively destroys the subtree rooted at this entity (including this entity) from the bottom up.
		
		This invokes``onFree()`` on each entity, giving each entity the opportunity to perform some cleanup (e.g. free resources or unregister from listeners).
	**/
	public function free()
	{
		if (mFlags & BIT_MARK_FREE > 0) return;
		
		if (parent != null) parent.remove(this);
		Es.freeEntityTree(this);
	}
	
	/**
		The parent or null if this is a top entity.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var parent(get_parent, set_parent):Entity;
	@:noCompletion inline function get_parent():Entity
	{
		assert(mFlags & BIT_MARK_FREE == 0);
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
		
		<warn>This value should never be changed by the user.</warn>
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
		
		<warn>This value should never be changed by the user.</warn>
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
		If true, ``MainLoop`` updates this entity at regular intervals by invoking the ``onTick()`` method.
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
		If true, ``MainLoop`` renderes this entity at regular intervals by invoking the ``onDraw()`` method.
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
		If true, this entity can receive messages.
		
		Default is true.
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
		If false, skips updating the subtree rooted at this node.
		
		Default is true.
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
		An incoming message.
		
		<warn>Only valid inside ``onMsg()``.</warn>
	**/
	public var incomingMessage(get_incomingMessage, never):Msg;
	@:noCompletion function get_incomingMessage():Msg
	{
		return getMsgQue().getMsgIn();
	}
	
	/**
		A message that will be sent when calling ``EntitySystem::dispatchMessages()``.
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
		var k = x.getSize() + 1;
		setSize(getSize() + k);
		
		var p = parent;
		while (p != null)
		{
			p.setSize(p.getSize() + k);
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
		var d = getDepth() + 1;
		var e = x;
		var i = x.getSize() + 1;
		while (i-- > 0)
		{
			e.setDepth(e.getDepth() + d);
			e = e.preorder;
		}
		
		lastChild = x;
		
		x.mFlags &= ~BIT_NO_PARENT;
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
			x = find(ID_CHILD, clss);
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
		var k = x.getSize() + 1;
		setSize(getSize() - k);
		
		var n = parent;
		while (n != null)
		{
			n.setSize(n.getSize() - k);
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
			var prev = child;
			while (prev != null) //find predecessor
			{
				if (prev.sibling == x) break;
				prev = prev.sibling;
			}
			
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
		var d = getDepth() + 1;
		var n = x;
		var i = x.getSize() + 1;
		while (i-- > 0)
		{
			n.setDepth(n.getDepth() - d);
			n = n.preorder;
		}
		
		x.mFlags |= BIT_NO_PARENT;
		x.parent = null;
		x.onRemove(this);
		
		return;
	}
	
	/**
		Removes all child entities from this entity.
	**/
	public function removeChildren():Entity
	{
		var k = getSize();
		
		var c = child, next, p, d;
		while (c != null)
		{
			next = c.sibling;
			
			findLastLeaf(c).preorder = null;
			
			d = c.getDepth();
			p = c.preorder;
			while (p != null)
			{
				p.setDepth(p.getDepth() - d);
				p = p.preorder;
			}
			c.setDepth(0);
			
			c.sibling = c.parent = null;
			c.mFlags |= BIT_NO_PARENT;
			c.onRemove(this);
			
			c = next;
		}
		
		child = lastChild = null;
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
		
		return this;
	}
	
	/**
		Returns the first child named `name` or null if no such child exists.
	**/
	inline public function findChildByName(name:String):Entity
	{
		var e:Entity = find(ID_CHILD, name);
		return e;
	}
	
	/**
		Returns the first child of type `clss` or null if no such child exists.
	**/
	inline public function findChildByClss<T:Entity>(clss:Class<T>):T
	{
		return find(ID_CHILD, clss);
	}
	
	/**
		Returns the first sibling named `name` or null if no such sibling exists.
	**/
	inline public function findSiblingByName(name:String):Entity
	{
		var e:Entity = find(ID_SIBLING, name);
		return e;
	}
	
	/**
		Returns the first sibling of type `clss` or null if no such sibling exists.
	**/
	inline public function findSiblingByClss<T:Entity>(clss:Class<T>):T
	{
		return find(ID_SIBLING, clss);
	}
	
	/**
		Returns the first ancestor named `name` or null if no such ancestor exists.
	**/
	inline public function findAncestorByName(name:String):Entity
	{
		var e:Entity = find(ID_ANCESTOR, name);
		return e;
	}
	
	/**
		Returns the first ancestor of type `clss` or null if no such ancestor exists.
	**/
	inline public function findAncestorByClss<T:Entity>(clss:Class<T>):T
	{
		return find(ID_ANCESTOR, clss);
	}
	
	/**
		Returns the first descendant named `name` or null if no such descendant exists.
	**/
	inline public function findDescendantByName(name:String):Entity
	{
		var e:Entity = find(ID_DESCENDANT, name);
		return e;
	}
	
	/**
		Returns the first descendant of type `clss` or null if no such descendant exists.
	**/
	inline public function findDescendantByClss<T:Entity>(clss:Class<T>):T
	{
		return find(ID_DESCENDANT, clss);
	}
	
	/**
		Sends a message of type `msgType` to `recipient`.
		
		If `dispatch` is true, the message will leave the message queue immediately.
	**/
	inline public function sendTo(recipient:Entity, msgType:Int, dispatch:Bool = false)
	{
		send(recipient, -1, msgType, dispatch);
	}
	
	/**
		Sends a message of type `msgType` to the parent entity.
		
		If `dispatch` is true, the message will leave the message queue immediately.
	**/
	inline public function sendToParent(msgType:Int, dispatch = false)
	{
		send(null, ID_PARENT, msgType, dispatch);
	}
	
	/**
		Sends a message of type `msgType` to all ancestors.
		
		If `dispatch` is true, the message will leave the message queue immediately.
	**/
	inline public function sendToAncestors(msgType:Int, dispatch = false)
	{
		send(null, ID_ANCESTOR, msgType, dispatch);
	}
	
	/**
		Sends a message of type `msgType` to all descendants.
		
		If `dispatch` is true, the message will leave the message queue immediately.
	**/
	inline public function sendToDescendants(msgType:Int, dispatch = false)
	{
		send(null, ID_DESCENDANT, msgType, dispatch);
	}
	
	/**
		Sends a message of type `msgType` to all children.
		
		If `dispatch` is true, the message will leave the message queue immediately.
	**/
	inline public function sendToChildren(msgType:Int, dispatch = false)
	{
		send(null, ID_CHILD, msgType, dispatch);
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
		if (parent == null || parent.child == this) return; //no parent or already first?
		
		var c = parent.child;
		
		while (c != null) //find predecessor to this entity
		{
			if (c.sibling == this) break;
			c = c.sibling;
		}
		
		if (this == parent.lastChild)
		{
			parent.lastChild = c;
			findLastLeaf(c).preorder = findLastLeaf(this).preorder;
		}
		else
			findLastLeaf(c).preorder = sibling;
		
		c.sibling = sibling;
		sibling = parent.child;
		findLastLeaf(this).preorder = parent.child;
		
		parent.child = this;
		parent.preorder = this;
	}
	
	/**
		Successively swaps this entity with its next siblings until it becomes the last sibling.
	**/
	public function setLast()
	{
		if (parent == null || sibling == null) return; //no parent or already last?
		
		var c = parent.child, last, tmp;
		
		if (c == this) //first child?
		{
			parent.preorder = parent.child = sibling;
		}
		else
		{
			while (c != null) //find predecessor to this entity
			{
				if (c.sibling == this) break;
				c = c.sibling;
			}
			
			findLastLeaf(c).preorder = c.sibling = sibling;
		}
		
		last = parent.lastChild;
		last.sibling = this;
		tmp = findLastLeaf(last).preorder;
		findLastLeaf(last).preorder = this;
		findLastLeaf(this).preorder = tmp;
		sibling = null;
		parent.lastChild = this;
	}
	
	/**
		Sort children by phase.
	**/
	public function sortChildren()
	{
		if (numChildren < 1) return;
		
		//quick test if sorting is necessary
		var sorted = true;
		var c = child;
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
		
		var t = findLastLeaf(lastChild).preorder;
		
		//merge sort taken from de.polygonal.ds.Sll
		var h = child;
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
		
		child = h;
		lastChild = tail;
		
		//rebuild preorder links
		preorder = child;
		var c = child;
		var l = lastChild;
		while (c != l)
		{
			findLastLeaf(c).preorder = c.sibling;
			c = c.sibling;
		}
		findLastLeaf(lastChild).preorder = t;
	}
	
	/**
		Convenience method for casting this Entity to the type `clss`.
	**/
	inline public function as<T:Entity>(clss:Class<T>):T
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
	inline public function is<T:Entity>(clss:Class<T>):Bool
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
		mFlags |= BIT_STOP_PROPAGATION;
	}
	
	function isDescendantOf(other:Entity):Bool
	{
		var e = this;
		while (e != null)
		{
			if (e.parent == other)
				return true;
			e = e.parent;
		}
		return false;
	}
	
	public function toString():String
	{
		if (name == null) name = '[${ClassUtil.getClassName(this)}]';
		return '{ Entity $name }';
	}
	
	@:noCompletion function send(?recipient:Entity, relation:Int, msgType:Int, dispatch:Bool = false)
	{
		var q = getMsgQue(), e;
		
		if (recipient != null)
		{
			e = recipient;
			if (e != null)
				q.enqueue(this, e, msgType, 0, 0);
			else
			{
				q.clrMessage();
				dispatch = false;
			}
		}
		else
		{
			switch (relation)
			{
				case ID_ANCESTOR:
					e = parent;
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
				
				case ID_CHILD:
					e = child;
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
				
				case ID_DESCENDANT:
					e = child;
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
				
				case ID_PARENT:
					e = parent;
					if (e != null)
						q.enqueue(this, e, msgType, 0, -1);
					else
					{
						q.clrMessage();
						dispatch = false;
					}
			}
		}
		
		if (dispatch) q.dispatch();
	}

	inline function lookup<T:Entity>(clss:Class<T>):T
	{
		return EntitySystem.lookup(clss);
	}
	
	@:noCompletion function find<T:Entity>(relation:Int, ?clss:Class<T>, ?name:String):T
	{
		assert(clss == null || name == null);
		
		var n, t, lut;
		
		switch (relation)
		{
			case ID_ANCESTOR:
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
			
			case ID_CHILD:
				if (clss != null)
				{
					n = child;
					t = getEntityType(clss);
					while (n != null)
					{
						if (t == n.type) return cast n;
						n = n.sibling;
					}
					n = child;
					lut = getInheritLut();
					while (n != null)
					{
						if (lut.hasPair(n.type, t)) return cast n;
						n = n.sibling;
					}
				}
				else
				{
					n = child;
					while (n != null)
					{
						if (n.name == name) return cast n;
						n = n.sibling;
					}
				}
			
			case ID_DESCENDANT:
				if (clss != null)
				{
					var last =
					if (sibling != null)
						sibling;
					else
						findLastLeaf(this).preorder;
					n = child;
					t = getEntityType(clss);
					while (n != last)
					{
						if (t == n.type) return cast n;
						n = n.preorder;
					}
					n = child;
					lut = getInheritLut();
					while (n != last)
					{
						if (lut.hasPair(n.type, t)) return cast n;
						n = n.preorder;
					}
				}
				else
				{
					n = child;
					var last = sibling;
					while (n != last)
					{
						if (n.name == name) return cast n;
						n = n.preorder;
					}
				}
			
			case ID_SIBLING:
				if (parent == null) return null;
				
				if (clss != null)
				{
					n = parent.child;
					t = getEntityType(clss);
					while (n != null)
					{
						if (n != this)
							if (t == n.type)
								return cast n;
						n = n.sibling;
					}
					n = parent.child;
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
					n = parent.child;
					while (n != null)
					{
						if (n.name == name) return cast n;
						n = n.sibling;
					}
				}
		}
		
		return null;
	}
	
	@:noCompletion function onAdd() {}
	
	@:noCompletion function onRemove(parent:Entity) {}
	
	@:noCompletion function onFree() {}
	
	@:noCompletion function onTick(dt:Float) {}
	
	@:noCompletion function onPostTick(alpha:Float) {}
	
	@:noCompletion function onDraw(alpha:Float) {}
	
	@:noCompletion function onPostDraw(alpha:Float) {}
	
	@:noCompletion function onMsg(msgType:Int, sender:Entity) {}
	
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
	
	//total number of descendants
	@:noCompletion inline function getSize():Int return Es.getSize(this);
	@:noCompletion inline function setSize(value:Int) Es.setSize(this, value);

	//length of the path from the root node to this node (root is at depth 0)
	@:noCompletion inline function getDepth():Int return Es.getDepth(this);
	@:noCompletion inline function setDepth(value:Int) Es.setDepth(this, value);
	
	@:noCompletion function __getType() return 0; //overriden by macro
}