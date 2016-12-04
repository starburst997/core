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

import de.polygonal.core.es.Entity as E;
import de.polygonal.core.es.EntitySystem as Es;

using de.polygonal.core.es.EntitySystem;
using de.polygonal.core.es.EntityTools;

@:access(de.polygonal.core.es.Entity)
@:access(de.polygonal.core.es.EntitySystem)
class EntityTools
{
	/**
		Pretty-prints the subtree starting at `root`.
	**/
	public static function print(root:E):String
	{
		if (root == null) return Std.string(root);
		
		var depth = function(x:E):Int
		{
			if (x.parent == null) return 0;
			var e = x;
			var c = 0;
			while (e.parent != null)
			{
				c++;
				e = e.parent;
			}
			return c;
		}	
		
		var s = "";
		var a = [root];
		var size = root.getSize();
		var e = root.next;
		for (i in 0...size)
		{
			a.push(e);
			e = e.next;
		}
		for (e in a)
		{
			var d = depth(e);
			for (i in 0...d)
			{
				if (i == d - 1)
					s += "+--- ";
				else
					s += "|    ";
			}
			s += "" + e.name + "\n";
		}
		return s;
	}
	
	/**
		Returns an iterator over all descendants of `entity`.
	**/
	public static function getDescendants(entity:E, includingRoot = false):Iterator<E>
	{
		var i = 0;
		var s = entity.getSize() + (includingRoot ? 1 : 0);
		var walker = includingRoot ? entity : entity.next;
		return
		{
			hasNext: function()
			{
				return i < s;
			},
			next: function()
			{
				i++;
				var t = walker;
				walker = walker.next;
				return t;
			}
		}
	}
	
	/**
		Returns an iterator over all children of `entity`.
	**/
	public static function getChildren(entity:E):Iterator<E>
	{
		var walker = entity.firstChild;
		return
		{
			hasNext: function()
			{
				return walker != null;
			},
			next: function()
			{
				var t = walker;
				walker = walker.sibling;
				return t;
			}
		}
	}
	
	/**
		Returns an iterator over all ancestors of `entity`.
	**/
	public static function getAncestors(entity:E):Iterator<E>
	{
		var walker = entity.parent;
		return
		{
			hasNext: function()
			{
				return walker != null;
			},
			next: function()
			{
				var t = walker;
				walker = walker.parent;
				return t;
			}
		}
	}
	
	/**
		Returns an iterator over all siblings left and right of `entity`.
	**/
	public static function getSiblings(entity:E):Iterator<E>
	{
		if (entity.parent == null)
		{
			return
			{
				hasNext: function() return false,
				next: function() return null
			}
		}
		var walker = entity.parent.firstChild;
		return
		{
			hasNext: function()
			{
				if (walker == entity && walker.sibling == null) return false;
				return walker != null;
			},
			next: function()
			{
				var t = walker;
				if (t == entity)
				{
					walker = walker.sibling;
					t = walker;
				}
				if (walker != null)
					walker = walker.sibling;
				return t;
			}
		}
	}
	
	/**
		Returns true if `other` is a descendant of `entity`.
	**/
	public static function isDescendantOf(entity:E, other:E):Bool
	{
		var e = entity;
		while (e != null)
		{
			if (e.parent == other) return true;
			e = e.parent;
		}
		return false;
	}
	
	/**
		Returns true if `other` is a child of `entity`.
	**/
	public static function isChildOf(entity:E, other:E):Bool
	{
		var e = entity.firstChild;
		while (e != null)
		{
			if (e == other) return true;
			e = e.sibling;
		}
		return false;
	}
	
	/**
		Finds the first child matching the given `name` or class `clss` or both.
	**/
	public static function findChild<T:E>(source:E, ?name:String, ?clss:Class<T>):T
	{
		var n, t, lut;
		
		if (name != null && clss != null)
		{
			n = source.firstChild;
			t = E.getEntityType(clss);
			while (n != null)
			{
				if (t == n.type && name == n.name) return cast n;
				n = n.sibling;
			}
			n = source.firstChild;
			lut = Es._superLut;
			while (n != null)
			{
				if (lut.hasPair(n.type, t) && n.name == name) return cast n;
				n = n.sibling;
			}
		}
		else
		if (clss != null)
		{
			n = source.firstChild;
			t = E.getEntityType(clss);
			while (n != null)
			{
				if (t == n.type) return cast n;
				n = n.sibling;
			}
			n = source.firstChild;
			lut = Es._superLut;
			while (n != null)
			{
				if (lut.hasPair(n.type, t)) return cast n;
				n = n.sibling;
			}
		}
		else
		{
			n = source.firstChild;
			while (n != null)
			{
				if (n.name == name) return cast n;
				n = n.sibling;
			}
		}
		return null;
	}
	
	/**
		Finds the first sibling matching the given `name` or class `clss` or both.
	**/
	public static function findSibling<T:E>(source:E, ?name:String, ?clss:Class<T>):T
	{
		if (source.parent == null) return null;
		
		var n, t, lut;
		
		if (name != null && clss != null)
		{
			n = source.parent.firstChild;
			t = E.getEntityType(clss);
			while (n != null)
			{
				if (n != source)
					if (t == n.type && name == n.name)
						return cast n;
				n = n.sibling;
			}
			n = source.parent.firstChild;
			lut = Es._superLut;
			while (n != null)
			{
				if (n != source)
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
			n = source.parent.firstChild;
			t = E.getEntityType(clss);
			while (n != null)
			{
				if (n != source)
					if (t == n.type)
						return cast n;
				n = n.sibling;
			}
			n = source.parent.firstChild;
			lut = Es._superLut;
			while (n != null)
			{
				if (n != source)
				{
					if (lut.hasPair(n.type, t))
						return cast n;
				}
				n = n.sibling;
			}
		}
		else
		{
			n = source.parent.firstChild;
			while (n != null)
			{
				if (n.name == name) return cast n;
				n = n.sibling;
			}
		}
		return null;
	}
	
	/**
		Finds the first ancestor matching the given `name` or class `clss` or both.
	**/
	public static function findAncestor<T:E>(source:E, ?name:String, ?clss:Class<T>):T
	{
		var n, t, lut;
		
		if (clss != null && name != null)
		{
			var p = source.parent;
			n = p;
			t = E.getEntityType(clss);
			while (n != null)
			{
				if (n.type == t && name == n.name) return cast n;
				n = n.parent;
			}
			n = p;
			lut = Es._superLut;
			while (n != null)
			{
				if (lut.hasPair(n.type, t) && name == n.name) return cast n;
				n = n.parent;
			}
		}
		else
		if (clss != null)
		{
			var p = source.parent;
			n = p;
			t = E.getEntityType(clss);
			while (n != null)
			{
				if (n.type == t) return cast n;
				n = n.parent;
			}
			n = p;
			lut = Es._superLut;
			while (n != null)
			{
				if (lut.hasPair(n.type, t)) return cast n;
				n = n.parent;
			}
		}
		else
		{
			n = source.parent;
			while (n != null)
			{
				if (n.name == name) return cast n;
				n = n.parent;
			}
		}
		return null;
	}
	
	/**
		Finds the first descendant matching the given `name` or class `clss` or both.
	**/
	public static function findDescendant<T:E>(source:E, ?name:String, ?clss:Class<T>):T
	{
		var n, t, lut;
		
		if (clss != null && name != null)
		{
			var last =
			if (source.sibling != null)
				source.sibling;
			else
				source.getLastLeaf().next;
			n = source.firstChild;
			t = E.getEntityType(clss);
			while (n != last)
			{
				if (t == n.type && name == n.name) return cast n;
				n = n.next;
			}
			n = source.firstChild;
			lut = Es._superLut;
			while (n != last)
			{
				if (lut.hasPair(n.type, t) && name == n.name) return cast n;
				n = n.next;
			}
		}
		else
		if (clss != null)
		{
			var last =
			if (source.sibling != null)
				source.sibling;
			else
				source.getLastLeaf().next;
			n = source.firstChild;
			t = E.getEntityType(clss);
			while (n != last)
			{
				if (t == n.type) return cast n;
				n = n.next;
			}
			n = source.firstChild;
			lut = Es._superLut;
			while (n != last)
			{
				if (lut.hasPair(n.type, t)) return cast n;
				n = n.next;
			}
		}
		else
		{
			n = source.firstChild;
			var last = source.sibling;
			while (n != last)
			{
				if (n.name == name) return cast n;
				n = n.next;
			}
		}
		return null;
	}
	
	/**
		The depth is defined as the length of the path from the root entity (=depth 0) to `entity`.
	**/
	public static inline function getDepth(entity:E)
	{
		return Es.getDepth(entity);
	}
	
	/**
		The number of descendants of `entity`.
	**/
	public static inline function getSubtreeSize(entity:E)
	{
		return Es.getSize(entity);
	}
	
	/**
		Finds the bottom-most, right-most entity in the subtree rooted at `e`
	**/
	public static inline function getLastLeaf(entity:E):E
	{
		while (entity.firstChild != null)
			entity = entity.getLastChild();
		return entity;
	}
	
	/**
		Finds the entity containing the next subtree right of `entity`.
	**/
	public static inline function getNextSubtree(entity:E):E
	{
		var sibling = entity.sibling;
		if (sibling != null)
			return sibling;
		else
			return getLastLeaf(entity).next;
	}
	
	/**
		Returns the child index of `entity` or -1 if `entity` has no parent.
	**/
	public static function getChildIndex(entity:E):Int
	{
		var p = entity.parent;
		if (p == null) return -1;
		
		var i = 0;
		var e = p.firstChild;
		while (e != entity)
		{
			i++;
			e = e.sibling;
		}
		return i;
	}
	
	/**
		Returns the child at `index` (zero-based).
	**/
	public static function getChildAt(entity:E, index:Int):E
	{
		assert(index >= 0 && index < entity.childCount, 'index $index out of range');
		var i = 0;
		var e = entity.firstChild;
		for (i in 0...index) e = e.sibling;
		return e;
	}
	
	/**
		Removes all children from `entity`.
	**/
	public static function removeChildren(entity:E)
	{
		var child = entity.firstChild;
		if (child == null) return;
		
		var next = entity.getNextSubtree();
		var size = entity.getSize();
		
		var hook, i, d;
		while (child != null)
		{
			hook = child.sibling;
			
			child.getLastLeaf().setNext(null);
			
			d = child.getDepth();
			i = child.next;
			while (i != null)
			{
				i.setDepth(i.getDepth() - d);
				i = i.next;
			}
			
			child.setDepth(0);
			child.setParent(null);
			child.setSibling(null);
			child.mBits |= E.BIT_PARENTLESS;
			child.onRemove(entity);
			child = hook;
		}
		
		entity.setFirstChild(null);
		entity.setLastChild(null);
		entity.setChildCount(0);
		entity.setNext(next);
		
		var n = entity.parent;
		while (n != null)
		{
			n.setSize(n.getSize() - size);
			n = n.parent;
		}
		entity.setSize(0);
	}
	
	/**
		Successively swaps `entity` with its previous siblings until it becomes the first sibling.
	**/
	public static function setFirst(entity:E)
	{
		var e = entity;
		if (e.parent == null || e.parent.firstChild == e) return; //no parent or already first?
		
		var child = e.parent.firstChild;
		while (child != null) //find predecessor to this entity
		{
			if (child.sibling == e) break;
			child = child.sibling;
		}
		if (e == e.parent.lastChild)
		{
			e.parent.setLastChild(child);
			child.getLastLeaf().setNext(e.getLastLeaf().next);
		}
		else
			child.getLastLeaf().setNext(e.sibling);
		child.setSibling(e.sibling);
		e.setSibling(e.parent.firstChild);
		e.getLastLeaf().setNext(e.parent.firstChild);
		
		e.parent.setFirstChild(e);
		e.parent.setNext(e);
	}
	
	/**
		Successively swaps `entity` with its next siblings until it becomes the last sibling.
	**/
	public static function setLast(entity:E)
	{
		var e = entity;
		if (e.parent == null || e.sibling == null) return; //no parent or already last?
		
		var child = e.parent.firstChild, last, tmp;
		if (child == e) //first child?
		{
			e.parent.setFirstChild(e.sibling);
			e.parent.setNext(e.sibling);
		}
		else
		{
			while (child != null) //find predecessor to this entity
			{
				if (child.sibling == e) break;
				child = child.sibling;
			}
			
			child.setSibling(e.sibling);
			child.getLastLeaf().setNext(e.sibling);
		}
		last = e.parent.lastChild;
		last.setSibling(e);
		tmp = last.getLastLeaf().next;
		last.getLastLeaf().setNext(e);
		e.getLastLeaf().setNext(tmp);
		e.setSibling(null);
		e.parent.setLastChild(e);
	}
	
	public static function sortChildren(entity:E, cmp:E->E->Int)
	{
		if (entity.childCount < 1) return;
		
		//quick test if sorting is necessary
		var sorted = true;
		var first = entity.firstChild;
		var c = first;
		c = c.sibling;
		while (c != null)
		{
			if (cmp(c, first) < 0)
			{
				sorted = false;
				break;
			}
			c = c.sibling;
		}
		
		if (sorted) return;
		
		var t = entity.lastChild.getLastLeaf().next;
		
		//merge sort taken from de.polygonal.ds.Sll
		var h = entity.firstChild;
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
					if (cmp(q, p) >= 0)
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
						tail.setSibling(e);
					else
						h = e;
					
					tail = e;
				}
				p = q;
			}
			tail.setSibling(null);
			if (nmerges <= 1) break;
			insize <<= 1;
		}
		
		entity.setFirstChild(h);
		entity.setLastChild(tail);
		
		//rebuild preorder pointers
		entity.setNext(entity.firstChild);
		var c = entity.firstChild;
		var l = entity.lastChild;
		while (c != l)
		{
			c.getLastLeaf().setNext(c.sibling);
			c = c.sibling;
		}
		entity.lastChild.getLastLeaf().setNext(t);
	}
}