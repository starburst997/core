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

import de.polygonal.core.es.Entity as E;
import de.polygonal.core.es.EntitySystem;
import de.polygonal.core.time.Timebase;
import de.polygonal.core.time.TimebaseListener;
import de.polygonal.core.time.Timeline;
import de.polygonal.core.util.Assert.assert;
import de.polygonal.ds.NativeArray;
import de.polygonal.ds.tools.NativeArrayTools;

using de.polygonal.core.es.EntityTools;
using de.polygonal.ds.tools.NativeArrayTools;

/**
	The top entity responsible for updating the entire entity hierachy
**/
@:access(de.polygonal.core.es.EntitySystem)
class MainLoop extends E implements TimebaseListener
{
	var mBufferedEntities:NativeArray<E>;
	var mStack:NativeArray<E>;
	var mPostFlags:NativeArray<Bool>;
	var mTop = 0;
	var mNumBufferedEntities = 0;
	var mMaxBufferSize = 0;
	var mElapsedTime = 0.;
	
	public function new()
	{
		assert(EntitySystem.lookup(MainLoop) == null,
			"MainLoop instance already created, use EntitySystem.lookup(MainLoop);");
		
		super(MainLoop.ENTITY_NAME, true);
		
		//*2 because every entity can be updated twice (pre/post visit)
		mBufferedEntities = NativeArrayTools.alloc(EntitySystem.MAX_SUPPORTED_ENTITIES * 2);
		mStack = NativeArrayTools.alloc(EntitySystem.MAX_SUPPORTED_ENTITIES * 2);
		mPostFlags = NativeArrayTools.alloc(EntitySystem.MAX_SUPPORTED_ENTITIES * 2);
		
		Timebase.addListener(this);
	}
	
	override function onFree()
	{
		Timebase.removeListener(this);
	}
	
	override function onTick(dt:Float)
	{
		//process scheduled events
		Timeline.update();
		
		//prune scratch list for gc at regular intervals
		mElapsedTime += dt;
		if (mElapsedTime > 30)
		{
			mElapsedTime = 0;
			mBufferedEntities.nullify(mMaxBufferSize);
			mMaxBufferSize = 0;
		}
		
		propagateTick(dt);
		
		EntityMessaging.flushBuffer();
	}
	
	override function onDraw(alpha:Float)
	{
		propagateDraw(alpha);
	}
	
	function propagateTick(dt:Float)
	{
		var a = mBufferedEntities, p = mPostFlags, e;
		mNumBufferedEntities = bufferEntities();
		for (i in 0...mNumBufferedEntities)
		{
			e = a.get(i);
			if (e.mBits & (E.BIT_SKIP_TICK | E.BIT_FREED | E.BIT_PARENTLESS) == 0)
			{
				if (p.get(i)) //post-subtree update?
				{
					if (e.mBits & E.BIT_SKIP_POST_TICK == 0)
						e.onPostTick(dt);
				}
				else
					e.onTick(dt);
			}
		}
	}
	
	function propagateDraw(alpha:Float)
	{
		var a = mBufferedEntities, p = mPostFlags, e;
		mNumBufferedEntities = bufferEntities();
		for (i in 0...mNumBufferedEntities)
		{
			e = a.get(i);
			if (e.mBits & (E.BIT_SKIP_DRAW | E.BIT_FREED | E.BIT_PARENTLESS) == 0)
			{
				if (p.get(i)) //post-subtree update?
				{
					if (e.mBits & E.BIT_SKIP_POST_DRAW == 0)
						e.onPostDraw(alpha);
				}
				else
					e.onDraw(alpha);
			}
		}
	}
	
	function bufferEntities():Int
	{
		var a = mBufferedEntities;
		var p = mPostFlags;
		var s = mStack;
		var k = 0, j = 0, t;
		var e = firstChild, last = null;
		while (e != null)
		{
			if (e.mBits & E.BIT_SKIP_SUBTREE != 0)
			{
				e = e.getNextSubtree();
				continue;
			}
			
			if (e.firstChild != null)
			{
				s.set(j++, e);
				last = e.lastChild;
			}
			
			a.set(k, e);
			p.set(k, false);
			k++;
			
			if (j > 0 && last == e)
			{
				t = s.get(--j);
				a.set(k, t);
				p.set(k, true);
				k++;
			}
			
			e = e.next;
		}
		
		while (j > 0)
		{
			t = s.get(--j);
			a.set(k, t);
			p.set(k, true);
			k++;
		}
		
		if (k > mMaxBufferSize) mMaxBufferSize = k;
		return k;
	}
}