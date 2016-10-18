import de.polygonal.core.es.Entity;
import de.polygonal.core.es.EntitySystem as Es;
import haxe.unit.TestCase;
import haxe.unit.TestRunner;

using de.polygonal.core.es.EntityTools;

@:access(de.polygonal.core.es.Entity)
@:access(de.polygonal.core.es.EntitySystem)
class TestEntity extends TestCase
{
	public function new()
	{
		super();
		Es.init();
	}
	
	function testSize()
	{
		var a = new Entity("a");
			var b = new Entity("b");
			var c = new Entity("c");
			var d = new Entity("d");
				var e = new Entity("e");
				var f = new Entity("f");
		
		a.add(b);
		a.add(c);
		a.add(d);
			d.add(e);
			d.add(f);
			
		assertEquals(Es.getSize(a), 5);
		assertEquals(Es.getSize(b), 0);
		assertEquals(Es.getSize(c), 0);
		assertEquals(Es.getSize(d), 2);
		assertEquals(Es.getSize(e), 0);
		assertEquals(Es.getSize(f), 0);
		
		var s = new Entity("s");
			var b = new Entity("b");
			var c = new Entity("c");
			var d = new Entity("d");
		s.add(b);
		s.add(c);
		s.add(d);
		
		var a = new Entity("a");
		a.add(s);
		
		assertEquals(Es.getSize(a), 4);
		assertEquals(Es.getSize(s), 3);
		assertEquals(Es.getSize(b), 0);
		assertEquals(Es.getSize(c), 0);
		assertEquals(Es.getSize(d), 0);
	}
	
	function testGetChildAt()
	{
		var a = new E("a");
		var b = new E("b");
		var c = new E("c");
		var d = new E("d");
		
		a.add(b);
		assertEquals(a.getChildAt(0).name, "b");
		
		a.add(c);
		assertEquals(a.getChildAt(0).name, "b");
		assertEquals(a.getChildAt(1).name, "c");
		
		a.add(d);
		
		assertEquals(a.getChildAt(0).name, "b");
		assertEquals(a.getChildAt(1).name, "c");
		assertEquals(a.getChildAt(2).name, "d");
		
		a.free();
		b.free();
		c.free();
		d.free();
	}
	
	function testRemoveChildren()
	{
		var o = new E("o");
			var h = new E("h");
			var r = new E("r");
				var a = new E("a");
					var aa = new E("aa");
					var ab = new E("ab");
					var ac = new E("ac");
					a.add(aa);
					a.add(ab);
					a.add(ac);
				var b = new E("b");
					var ba = new E("ba");
					var bb = new E("bb");
					var bc = new E("bc");
					b.add(ba);
					b.add(bb);
					b.add(bc);
				var c = new E("c");
					var ca = new E("ca");
					var cb = new E("cb");
					var cc = new E("cc");
					c.add(ca);
					c.add(cb);
					c.add(cc);
			r.add(a);
			r.add(b);
			r.add(c);
			var t = new E("t");
		o.add(h);
		o.add(r);
		o.add(t);
		
		r.removeChildren();
		
		assertEquals("o,h,r,t", printPreorder(o));
		assertEquals("a,aa,ab,ac", printPreorder(a));
		assertEquals("b,ba,bb,bc", printPreorder(b));
		assertEquals("c,ca,cb,cc", printPreorder(c));
		
		assertEquals(0, r.childCount);
		
		assertEquals(null, r.firstChild);
		assertEquals(null, r.lastChild);
		
		assertEquals(0, Es.getSize(r));
		assertEquals(3, Es.getSize(o));
		
		assertEquals(0, Es.getDepth(a));
		assertEquals(1, Es.getDepth(aa));
		assertEquals(1, Es.getDepth(ab));
		assertEquals(1, Es.getDepth(ac));
		
		assertEquals(0, Es.getDepth(b));
		assertEquals(1, Es.getDepth(ba));
		assertEquals(1, Es.getDepth(bb));
		assertEquals(1, Es.getDepth(bc));
		
		assertEquals(0, Es.getDepth(c));
		assertEquals(1, Es.getDepth(ca));
		assertEquals(1, Es.getDepth(cb));
		assertEquals(1, Es.getDepth(cc));
	}
	
	function testRemove1()
	{
		var a = new E("a");
		var b = new E("b");
		a.add(b);
		a.remove(b);
		assertEquals("a", printPreorder(a));
		
		var a = new E("a");
		var b = new E("b");
		var c = new E("c");
		a.add(b);
		a.add(c);
		
		a.remove(c);
		assertEquals("a,b", printPreorder(a));
		a.remove(b);
		assertEquals("a", printPreorder(a));
	}
	
	function testRemove2()
	{
		var a = new E("a");
		var b = new E("b");
		var c = new E("c");
		a.add(b);
		b.add(c);
		
		assertEquals("a,b,c", printPreorder(a));
		
		a.remove(b);
		assertEquals("a", printPreorder(a));
		assertEquals("b,c", printPreorder(b));
		
		var a = new E("a");
		var b = new E("b");
		var c = new E("c");
		a.add(b);
		b.add(c);
		var d = new E("d");
		a.add(d);
		assertEquals("a,b,c,d", printPreorder(a));
		
		a.remove(b);
		assertEquals("a,d", printPreorder(a));
		assertEquals("b,c", printPreorder(b));
	}
	
	function testRemove3()
	{
		var a = new E("a");
		var b = new E("b");
		var c = new E("c");
		var d = new E("d");
		var e = new E("e");
		a.add(b);
			b.add(c);
		
		a.add(d);
			d.add(e);
		
		assertEquals("a,b,c,d,e", printPreorder(a));
		
		a.remove(d);
		assertEquals("a,b,c", printPreorder(a));
		assertEquals("d,e", printPreorder(d));
		
		var a = new E("a");
		var b = new E("b");
		var c = new E("c");
		var d = new E("d");
		var e = new E("e");
		var f = new E("f");
		var g = new E("g");
		
		a.add(b);
			b.add(c);
		
		a.add(d);
			d.add(e);
		
		a.add(f);
			f.add(g);
		
		assertEquals("a,b,c,d,e,f,g", printPreorder(a));
		
		a.remove(d);
		assertEquals("a,b,c,f,g", printPreorder(a));
		assertEquals("d,e", printPreorder(d));
	}
	
	function testUpdateLastChild()
	{
		var a = new Entity("a");
		var b = new Entity("b");
		var c = new Entity("c");
		
		a.add(b);
		assertEquals(a.lastChild, b);
		
		a.remove(b);
		assertEquals(a.lastChild, null);
		
		a.add(b);
		a.add(c);
		
		c.remove();
		assertEquals(a.lastChild, b);
		
		b.remove();
		assertEquals(a.lastChild, null);
		
		a.add(b);
		a.add(c);
		
		b.remove();
		assertEquals(a.lastChild, c);
	}
	
	function testChildIndex()
	{
		var a = new Entity("a");
		
		assertEquals(-1, a.getChildIndex());
		
		var b = new Entity("b");
		a.add(b);
		
		assertEquals(0, b.getChildIndex());
		
		var c = new Entity("c");
		a.add(c);
		
		assertEquals(0, b.getChildIndex());
		assertEquals(1, c.getChildIndex());
	}
	
	function testDepth()
	{
		var a = new Entity("a");
		var b = new Entity("b");
		
		assertEquals(Es.getDepth(a), 0);
		assertEquals(Es.getDepth(b), 0);
		
		a.add(b);
		
		assertEquals(Es.getDepth(a), 0);
		assertEquals(Es.getDepth(b), 1);
		
		var c = new Entity("c");
			b.add(c);
			
		var d = new Entity("d");
			c.add(d);
		
		assertEquals(Es.getDepth(a), 0);
		assertEquals(Es.getDepth(b), 1);
		assertEquals(Es.getDepth(c), 2);
		assertEquals(Es.getDepth(d), 3);
		
		b.remove(c);
		
		assertEquals(Es.getDepth(a), 0);
		assertEquals(Es.getDepth(b), 1);
		assertEquals(Es.getDepth(c), 0);
		assertEquals(Es.getDepth(d), 1);
		
		var a = new Entity("a");
		var s = new Entity("s");
			var b = new Entity("b");
		s.add(b);
		
		a.add(s);
		
		assertEquals(Es.getDepth(a), 0);
		assertEquals(Es.getDepth(s), 1);
		assertEquals(Es.getDepth(b), 2);
		
		var a = new Entity("a");
		var s = new Entity("s");
			var b = new Entity("b");
			var c = new Entity("b");
		s.add(b);
		s.add(c);
		
		a.add(s);
		
		assertEquals(Es.getDepth(a), 0);
		assertEquals(Es.getDepth(s), 1);
		assertEquals(Es.getDepth(b), 2);
		assertEquals(Es.getDepth(c), 2);
	}
	
	function testAdd1()
	{
		var a = new E("a");
		var b = new E("b");
		a.add(b);
		
		assertEquals("a,b", printPreorder(a));
		
		var a = new E("a");
		var b = new E("b");
		var c = new E("c");
		a.add(b);
		a.add(c);
		assertEquals("a,b,c", printPreorder(a));
		
		var a = new E("a");
		var b = new E("b");
		a.add(b);
		assertEquals("a,b", printPreorder(a));
		
		var c = new E("c");
		var d = new E("d");
		c.add(d);
		assertEquals("c,d", printPreorder(c));
		
		a.add(c);
		assertEquals("a,b,c,d", printPreorder(a));
	}
	
	function testAdd2()
	{
		var r = new E("r");
			var a = new E("a");
				var c = new E("c");
				a.add(c);
			r.add(a);
		assertEquals("r,a,c", printPreorder(r));
	}
	
	function testAdd3()
	{
		var r = new E("r");
			var a = new E("a");
				var c = new E("c");
				a.add(c);
			r.add(a);
			var b = new E("b");
			r.add(b);
		assertEquals("r,a,c,b", printPreorder(r));
	}
	
	function testAddRemove1()
	{
		var r = new E("r");
		
		var bag = new E("bag");
		
		var a = new E("a");
		var b = new E("b");
		
		var t = new E("t");
		
		r.add(bag);
		bag.add(a);
		bag.add(b);
		
		assertEquals("r,bag,a,b", printPreorder(r));
		
		a.remove();
		
		assertEquals("r,bag,b", printPreorder(r));
		
		r.add(a);
		
		assertEquals("r,bag,b,a", printPreorder(r));
	}
	
	function testAddOnRemove()
	{
		var a = new E("a");
		var b = new E("b");
		
		b.onRemoveFunc = function()
		{
			a.add(b);
			
			assertEquals(1, Es.getSize(a));
			assertEquals(a.firstChild, b);
			assertEquals(b.parent, a);
			assertEquals("a,b", printPreorder(a));
			assertEquals("b", printPreorder(b));
		}
		
		a.add(b);
		a.remove(b);
	}
	
	function testRemoveOnAdd()
	{
		var a = new E("a");
		var b = new E("b");
		
		b.onAddFunc = function()
		{
			a.remove(b);
			
			assertEquals(0, Es.getSize(a));
			assertEquals(a.firstChild, null);
			assertEquals(b.parent, null);
			assertEquals("a", printPreorder(a));
			assertEquals("b", printPreorder(b));
		}
		
		a.add(b);
	}
	
	function testRemoveAllChildren()
	{
		var r = new Entity("r");
		var a = new Entity("a");
			var a1a = new Entity("a1a");
			var a1b = new Entity("a1b");
				var a2a = new Entity("a2a");
		var b = new Entity("b");
		var c = new Entity("c");
		r.add(a);
			a.add(a1a);
			a.add(a1b);
				a1b.add(a2a);
		r.add(b);
		r.add(c);
		
		assertEquals(3, a.getSubtreeSize());
		
		EntityTools.removeChildren(a);
		
		assertEquals(0, a1a.getDepth());
		assertEquals(0, a1b.getDepth());
		assertEquals(1, a2a.getDepth());
		
		assertEquals(0, a.getSubtreeSize());
		assertEquals(1, a1b.getSubtreeSize());
		
		assertEquals(null, a1a.parent);
		assertEquals(null, a1b.parent);
		assertEquals(a1b, cast a2a.parent);
		
		assertEquals("r,a,b,c", printPreorder(r));
		assertEquals(3, r.getSubtreeSize());
		assertEquals(0, a.getSubtreeSize());
		assertEquals(0, b.getSubtreeSize());
		assertEquals(0, c.getSubtreeSize());
		
		r.free();
		
		var r = new Entity("r");
			var a = new Entity("a");
				var a1 = new Entity("a1");
					var a2 = new Entity("a2");
			var b = new Entity("b");
		
		r.add(a);
			a.add(a1);
			a1.add(a2);
		r.add(b);
		
		a1.removeChildren();
		
		assertEquals("r,a,a1,b", printPreorder(r));
		
		assertEquals(3, r.getSubtreeSize());
		assertEquals(1, a.getSubtreeSize());
		assertEquals(0, a1.getSubtreeSize());
		assertEquals(0, b.getSubtreeSize());
	}
	
	function testSetFirst()
	{
		var r = new E("r");
			var a = new E("a");
		r.add(a);
		
		a.setFirst();
		assertEquals(r.firstChild, a);
		assertEquals(r.lastChild, a);
		assertEquals(r.firstChild.sibling, null);
		assertEquals("r,a", printPreorder(r));
		
		var r = new E("r");
			var a = new E("a");
			var b = new E("b");
		r.add(a);
		r.add(b);
		b.setFirst();
		
		assertEquals(r.firstChild, b);
		assertEquals(r.lastChild, a);
		assertEquals(b.sibling, a);
		assertEquals(a.sibling, null);
		assertEquals("r,b,a", printPreorder(r));
		
		var r = new E("r");
			var a = new E("a");
			var b = new E("b");
			var c = new E("c");
		r.add(a);
		r.add(b);
		r.add(c);
		assertEquals("r,a,b,c", printPreorder(r));
		assertEquals(c.sibling, null);
		
		b.setFirst();
		assertEquals("r,b,a,c", printPreorder(r));
		assertEquals(b.sibling, a);
		assertEquals(a.sibling, c);
		assertEquals(c.sibling, null);
		assertEquals(r.next, b);
		assertEquals(b.next, a);
		assertEquals(a.next, c);
		assertEquals(c.next, null);
		
		var r = new E("r");
			var a = new E("a");
			var b = new E("b");
			var c = new E("c");
		r.add(a);
		r.add(b);
		r.add(c);
		assertEquals("r,a,b,c", printPreorder(r));
		c.setFirst();
		
		assertEquals("r,c,a,b", printPreorder(r));
		assertEquals(c.sibling, a);
		assertEquals(a.sibling, b);
		assertEquals(b.sibling, null);
		
		function createTree():E
		{
			var r = new E("r");
				var a = new E("a");
					a.add(new E("aa"));
					a.add(new E("ab"));
					a.add(new E("ac"));
				var b = new E("b");
					b.add(new E("ba"));
					b.add(new E("bb"));
					b.add(new E("bc"));
				var c = new E("c");
					c.add(new E("ca"));
					c.add(new E("cb"));
					c.add(new E("cc"));
			r.add(a);
			r.add(b);
			r.add(c);
			return r;
		}
		
		var r = createTree();
		var o = new E("o");
		o.add(new E("h"));
		o.add(r);
		o.add(new E("t"));
		var b = r.getChildAt(0);
		b.setFirst();
		assertEquals("o,h,r,a,aa,ab,ac,b,ba,bb,bc,c,ca,cb,cc,t", printPreorder(o));
		o.free();
		
		var r = createTree();
		var o = new E("o");
		o.add(new E("h"));
		o.add(r);
		o.add(new E("t"));
		var b = r.getChildAt(1);
		b.setFirst();
		assertEquals("o,h,r,b,ba,bb,bc,a,aa,ab,ac,c,ca,cb,cc,t", printPreorder(o));
		o.free();
		
		var r = createTree();
		var o = new E("o");
		o.add(new E("h"));
		o.add(r);
		o.add(new E("t"));
		var b = r.getChildAt(2);
		b.setFirst();
		assertEquals("o,h,r,c,ca,cb,cc,a,aa,ab,ac,b,ba,bb,bc,t", printPreorder(o));
		o.free();
	}
	
	function testSetLast()
	{
		var r = new E("r");
			var a = new E("a");
		r.add(a);
		a.setLast();
		assertEquals(r.firstChild, a);
		assertEquals(r.lastChild, a);
		assertEquals("r,a", printPreorder(r));
		
		var r = new E("r");
			var a = new E("a");
			var b = new E("b");
		r.add(a);
		r.add(b);
		a.setLast();
		assertEquals(r.firstChild, b);
		assertEquals(r.lastChild, a);
		assertEquals(b.sibling, a);
		assertEquals(a.sibling, null);
		assertEquals("r,b,a", printPreorder(r));
		
		var r = new E("r");
			var a = new E("a");
			var b = new E("b");
			var c = new E("c");
		r.add(a);
		r.add(b);
		r.add(c);
		assertEquals("r,a,b,c", printPreorder(r));
		b.setLast();
		
		assertEquals("r,a,c,b", printPreorder(r));
		assertEquals(a.sibling, c);
		assertEquals(c.sibling, b);
		assertEquals(b.sibling, null);
		assertEquals(a.next, c);
		assertEquals(c.next, b);
		assertEquals(b.next, null);
		assertEquals(r.next, a);
		assertEquals(r.firstChild, a);
		assertEquals(r.lastChild, b);
		
		var r = new E("r");
			var s = new E("s");
				var a = new E("a");
				var b = new E("b");
				var c = new E("c");
			s.add(a);
			s.add(b);
			s.add(c);
		r.add(s);
		
		var d = new E("d");
		r.add(d);
		assertEquals("r,s,a,b,c,d", printPreorder(r));
		
		b.setLast();
		assertEquals("r,s,a,c,b,d", printPreorder(r));
		assertEquals(a.sibling, c);
		assertEquals(c.sibling, b);
		assertEquals(b.sibling, null);
		assertEquals(a.next, c);
		assertEquals(c.next, b);
		assertEquals(b.next, d);
		assertEquals(r.next, s);
		assertEquals(r.firstChild, s);
		assertEquals(s.lastChild, b);
		assertEquals(s.next, a);
		
		var r = new E("r");
			var a = new E("a");
			var b = new E("b");
		r.add(a);
		r.add(b);
		assertEquals("r,a,b", printPreorder(r));
		a.setLast();
		assertEquals("r,b,a", printPreorder(r));
		assertEquals(r.firstChild, b);
		assertEquals(r.lastChild, a);
		assertEquals(b.sibling, a);
		assertEquals(a.sibling, null);
		assertEquals(r.next, b);
		assertEquals(b.next, a);
		assertEquals(a.next, null);
		
		function createTree():E
		{
			var r = new E("r");
				var a = new E("a");
					a.add(new E("aa"));
					a.add(new E("ab"));
					a.add(new E("ac"));
				var b = new E("b");
					b.add(new E("ba"));
					b.add(new E("bb"));
					b.add(new E("bc"));
				var c = new E("c");
					c.add(new E("ca"));
					c.add(new E("cb"));
					c.add(new E("cc"));
			r.add(a);
			r.add(b);
			r.add(c);
			return r;
		}

		var r = createTree();
		var o = new E("o");
		o.add(new E("h"));
		o.add(r);
		o.add(new E("t"));
		var b = r.getChildAt(0);
		b.setLast();
		assertEquals("o,h,r,b,ba,bb,bc,c,ca,cb,cc,a,aa,ab,ac,t", printPreorder(o));
		o.free();

		var r = createTree();
		var o = new E("o");
		o.add(new E("h"));
		o.add(r);
		o.add(new E("t"));
		var b = r.getChildAt(1);
		b.setLast();
		assertEquals("o,h,r,a,aa,ab,ac,c,ca,cb,cc,b,ba,bb,bc,t", printPreorder(o));
		o.free();

		var r = createTree();
		var o = new E("o");
		o.add(new E("h"));
		o.add(r);
		o.add(new E("t"));
		var b = r.getChildAt(2);
		b.setLast();
		assertEquals("o,h,r,a,aa,ab,ac,b,ba,bb,bc,c,ca,cb,cc,t", printPreorder(o));
		o.free();
	}
	
	function testPhase()
	{
		var r = new E("r");
		var a = new E("a");
		var b = new E("b");
		var c = new E("c");
		
		r.add(a);
		r.add(b);
		r.add(c);
		
		a.phase = 3;
		b.phase = 2;
		c.phase = 1;
		
		assertEquals("r,a,b,c", printPreorder(r));
		
		r.sortChildrenByPhase();
		
		assertEquals(c, cast r.firstChild);
		assertEquals(a, cast r.lastChild);
		assertEquals(b, cast c.sibling);
		assertEquals(a, cast b.sibling);
		assertEquals(null, a.sibling);
		
		assertEquals("r,c,b,a", printPreorder(r));
		
		function createTree():E
		{
			var r = new E("r");
				var a = new E("a");
				a.phase = 2;
					a.add(new E("aa"));
					a.add(new E("ab"));
					a.add(new E("ac"));
				var b = new E("b");
				b.phase = 3;
					b.add(new E("ba"));
					b.add(new E("bb"));
					b.add(new E("bc"));
				var c = new E("c");
				c.phase = 1;
					c.add(new E("ca"));
					c.add(new E("cb"));
					c.add(new E("cc"));
			r.add(a);
			r.add(b);
			r.add(c);
			return r;
		}
		
		var r = createTree();
		var o = new E("o");
		o.add(new E("h"));
		o.add(r);
		o.add(new E("t"));
		
		assertEquals("o,h,r,a,aa,ab,ac,b,ba,bb,bc,c,ca,cb,cc,t", printPreorder(o));
		
		r.sortChildrenByPhase();
		
		assertEquals("o,h,r,c,ca,cb,cc,a,aa,ab,ac,b,ba,bb,bc,t", printPreorder(o));
	}
	
	function testDescendantsIterator()
	{
		var a = new Entity('a');
		var b = new Entity('b');
		var c = new Entity('c');
		
		var result:Array<String> = [];
		
		for (e in a.getDescendants()) result.push(e.name);
		assertEquals("", result.join(""));
		result = [];
		
		a.add(b);
		
		for (e in a.getDescendants()) result.push(e.name);
		assertEquals("b", result.join(""));
		result = [];
		
		a.add(c);
		
		for (e in a.getDescendants()) result.push(e.name);
		assertEquals("bc", result.join(""));
	}
	
	function testAncestorsIterator()
	{
		var a = new Entity('a');
		var b = new Entity('b');
		var c = new Entity('c');
		
		var result:Array<String> = [];
		
		for (e in a.getAncestors()) result.push(e.name);
		assertEquals("", result.join(""));
		result = [];
		
		a.add(b);
		
		for (e in b.getAncestors()) result.push(e.name);
		assertEquals("a", result.join(""));
		result = [];
		
		b.add(c);
		
		for (e in c.getAncestors()) result.push(e.name);
		assertEquals("ba", result.join(""));
	}
	
	function testSiblingsIterator()
	{
		var a = new Entity('a');
		var b = new Entity('b');
		var c = new Entity('c');
		var d = new Entity('d');
		
		var result:Array<String> = [];
		
		for (e in a.getSiblings()) result.push(e.name);
		assertEquals("", result.join(""));
		result = [];
		
		a.add(b);
		
		for (e in b.getSiblings()) result.push(e.name);
		assertEquals("", result.join(""));
		result = [];
		
		a.add(c);
		
		for (e in b.getSiblings()) result.push(e.name);
		assertEquals("c", result.join(""));
		result = [];
		
		for (e in c.getSiblings()) result.push(e.name);
		assertEquals("b", result.join(""));
		result = [];
		
		a.add(d);
		
		for (e in d.getSiblings()) result.push(e.name);
		assertEquals("bc", result.join(""));
		result = [];
		
		for (e in d.getSiblings()) result.push(e.name);
		assertEquals("bc", result.join(""));
		result = [];
		
		for (e in c.getSiblings()) result.push(e.name);
		assertEquals("bd", result.join(""));
		result = [];
		
		for (e in b.getSiblings()) result.push(e.name);
		assertEquals("cd", result.join(""));
	}
	
	function printPreorder(e:Entity):String
	{
		var a = [];
		while (e != null)
		{
			a.push(e.name);
			e = e.next;
		}
		return a.join(',');
	}
}

private class Callback
{
	public static var onAdd:Entity->Entity->Void = null;
	public static var onRemove:Entity->Entity->Void = null;
}

private class E extends Entity
{
	public var onAddFunc:Void->Void;
	public var onRemoveFunc:Void->Void;
	
	public function new(name:String)
	{
		super(name);
		onAddFunc = function() {};
		onRemoveFunc = function() {};
	}
	
	override function onAdd()
	{
		if (Callback.onAdd != null) Callback.onAdd(this, parent);
		onAddFunc();
	}
	
	override function onRemove(parent:Entity)
	{
		if (Callback.onRemove != null) Callback.onRemove(this, parent);
		onRemoveFunc();
	}
}