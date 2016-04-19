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

import de.polygonal.core.es.EntitySystem as Es;

using de.polygonal.core.es.EntitySystem;

@:access(de.polygonal.core.es.EntitySystem)
class EntityTools
{
	/**
		Pretty-prints the entity hierarchy starting at `root`.
	**/
	public static function print(root:Entity):String
	{
		if (root == null) return root.toString();
		
		function depth(x:Entity):Int
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
		
		var s = root.name + '\n';
		
		var a = [root];
		
		var e = root.preorder;
		while (e != null)
		{
			a.push(e);
			
			e = e.preorder;
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
	
	public static function getDescendants(e:Entity, includeCaller = false):Iterator<Entity>
	{
		var i = 0;
		var s = e.getSize() + (includeCaller ? 1 : 0);
		var walker = includeCaller ? e : e.preorder;
		
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
				walker = walker.preorder;
				return t;
			}
		}
	}
	
	public static function getChildren(e:Entity):Iterator<Entity>
	{
		var walker = e.firstChild;
		
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
	
	public static function getAncestors(e:Entity):Iterator<Entity>
	{
		var walker = e.parent;
		
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
	
	public static function getSiblings(e:Entity):Iterator<Entity>
	{
		if (e.parent == null)
		{
			return
			{
				hasNext: function() return false,
				next: function() return null
			}
		}
		
		var walker = e.parent.firstChild;
		
		return
		{
			hasNext: function()
			{
				if (walker == e && walker.sibling == null) return false;
				return walker != null;
			},
			next: function()
			{
				var t = walker;
				if (t == e)
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
		Returns true if `other` is a descendant of `e`.
	**/
	public static function isDescendantOf(e:Entity, other:Entity):Bool
	{
		while (e != null)
		{
			if (e.parent == other) return true;
			e = e.parent;
		}
		
		return false;
	}
	
	/**
		Returns true if `other` is a child of `e`.
	**/
	public static function isChildOf(e:Entity, other:Entity):Bool
	{
		var i = e.firstChild;
		while (i != null)
		{
			if (i == other) return true;
			i = i.sibling;
		}
		
		return false;
	}
	
	/**
		Successively swaps this entity with its previous siblings until it becomes the first sibling.
	**/
	public static function setFirst(e:Entity)
	{
		if (e.parent == null || e.parent.firstChild == e) return; //no parent or already first?
		
		Es._treeChanged = true;
		
		var c = e.parent.firstChild;
		
		while (c != null) //find predecessor to this entity
		{
			if (c.sibling == e) break;
			c = c.sibling;
		}
		
		if (e == e.parent.lastChild)
		{
			e.parent.lastChild = c;
			c.findLastLeaf().preorder = e.findLastLeaf().preorder;
		}
		else
			c.findLastLeaf().preorder = e.sibling;
		
		c.sibling = e.sibling;
		e.sibling = e.parent.firstChild;
		e.findLastLeaf().preorder = e.parent.firstChild;
		
		e.parent.firstChild = e;
		e.parent.preorder = e;
	}
	
	/**
		Successively swaps this entity with its next siblings until it becomes the last sibling.
	**/
	public static function setLast(e:Entity)
	{
		if (e.parent == null || e.sibling == null) return; //no parent or already last?
		
		Es._treeChanged = true;
		
		var c = e.parent.firstChild, last, tmp;
		
		if (c == e) //first child?
		{
			e.parent.preorder = e.parent.firstChild = e.sibling;
		}
		else
		{
			while (c != null) //find predecessor to this entity
			{
				if (c.sibling == e) break;
				c = c.sibling;
			}
			
			c.findLastLeaf().preorder = c.sibling = e.sibling;
		}
		
		last = e.parent.lastChild;
		last.sibling = e;
		tmp = last.findLastLeaf().preorder;
		last.findLastLeaf().preorder = e;
		e.findLastLeaf().preorder = tmp;
		e.sibling = null;
		e.parent.lastChild = e;
	}
}