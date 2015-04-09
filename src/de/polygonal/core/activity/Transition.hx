/*
Copyright (c) 2014 Michael Baczynski, http://www.polygonal.de

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
package de.polygonal.core.activity;

import de.polygonal.core.es.Entity;
import de.polygonal.core.time.Interval;
import de.polygonal.core.util.ClassUtil;
import haxe.ds.StringMap;

@:enum
abstract TransitionType(Int)
{
    var Push = 1;
    var Pop = 2;
    var Change = 3;
}

@:access(de.polygonal.core.activity.Activity)
@:access(de.polygonal.core.activity.ActivityManager)
class Transition extends Entity
{
	var mA:Activity;
	var mB:Activity;
	var mInterval:Interval = new Interval(1);
	var mListener:TransitionListener;
	var mType:TransitionType;
	var mTransitionLookup = new StringMap<TransitionListener>();
	
	public function new() 
	{
		super();
		tickable = false;
		drawable = false;
	}
	
	public function register(from:Class<Activity>, to:Class<Activity>, effect:TransitionListener)
	{
		var a = from == null ? "*" : ClassUtil.getUnqualifiedClassName(from);
		var b = to == null ? "*" : ClassUtil.getUnqualifiedClassName(to);
		mTransitionLookup.set('$a-$b', effect);
	}
	
	/**
		Push `b` over `a`.
	**/
	public function push(a:Activity, b:Activity)
	{
		run(a, b, Push);
	}
	
	/**
		Pop `b` off `a`.
		
		- `b` can be null in case `a` has no parent activity.
	**/
	public function pop(a:Activity, b:Activity)
	{
		run(a, b, Pop);
	}
	
	/**
		Replace `a` (and all parent activities of `a`) with `b`.
	**/
	public function change(a:Activity, b:Activity)
	{
		run(a, b, Change);
	}
	
	function run(a:Activity, b:Activity, type:TransitionType)
	{
		var nameA = a == null ? "null" : ClassUtil.getUnqualifiedClassName(a);
		var nameB = ClassUtil.getUnqualifiedClassName(b);
		
		var lut = mTransitionLookup;
		do
		{
			mListener = lut.get('$nameA-$nameB');
			if (mListener != null) break;
			
			mListener = lut.get('*-$nameB');
			if (mListener != null) break;
			
			mListener = lut.get('$nameA-*');
			if (mListener != null) break;
			
			mListener = lut.get('*-*');
			if (mListener != null) break;
		}
		while (false);
		
		mListener == null ? finish(a, b, type) : start(a, b, type);
	}
	
	function start(a:Activity, b:Activity, type:TransitionType)
	{
		mA = a;
		mB = b;
		mListener.onStart(a, b, type);
		mType = type;
		mInterval.duration = mListener.getDuration(a, b, type);
		tickable = true;
	}
	
	function finish(a:Activity, b:Activity, type:TransitionType)
	{
		inline function stopAndRemove(x:Activity)
		{
			x.onStop();
			x.remove();
			if (!x.isPersistent()) x.free();
		}
		
		switch (type)
		{
			case Push:
				if (b.isFullSize() && a != null)
				{
					var above = getStackedActivitiesBelowIncluding(a);
					for (i in above)
						if (i.state == Paused)
							i.onStop();
				}
				b.onResume();
			
			case Pop:
				if (b == null)
				{
					//a has no parent
					stopAndRemove(a);
					return;
				}
				
				var above = getStackedActivitiesAboveIncluding(a);
				for (i in above) stopAndRemove(i);
				
				switch (b.state)
				{
					case Paused, Started:
						b.onResume();
					
					case Stopped:
						b.onRestart();
						b.onStart();
						b.onResume();
					
					case _:
				}
			
			case Change:
				//stop entire activity stack (all activities below a)
				var e:Activity = a;
				while (true)
				{
					var parent = e.parent;
					var isRoot = e.isRootActivity();
					stopAndRemove(e);
					if (isRoot) break;
					e = cast parent;
				}
				b.onResume();
		}
	}
	
	override function onTick(dt:Float)
	{
		mListener.onProgress(mA, mB, mInterval.advance(dt), mType);
		if (mInterval.finished)
		{
			mListener.onFinish(mA, mB, mType);
			tickable = false;
			drawable = true;
		}
	}
	
	override function onDraw(alpha:Float)
	{
		drawable = false;
		var a = mA;
		var b = mB;
		mA = null;
		mB = null;
		finish(a, b, mType);
	}
	
	function getStackedActivitiesBelowIncluding(e:Activity):Array<Activity>
	{
		var out = [];
		var p = e;
		while (!p.isRootActivity())
		{
			out.push(p);
			p = cast p.parent;
		}
		out.push(p);
		return out;
	}
	
	function getStackedActivitiesAboveIncluding(e:Activity):Array<Activity>
	{
		inline function findChildActivity(x:Entity):Activity
		{
			var a = null;
			var c = x.child;
			while (c != null)
			{
				if (c.is(Activity))
				{
					a = cast c;
					break;
				}
				c = c.sibling;
			}
			return a;
		}
		
		var c = e;
		while (c.child != null) c = findChildActivity(c);
		
		var out = [];
		var p = c;
		while (p != e)
		{
			out.push(p);
			p = cast p.parent;
		}
		
		out.push(e);
		return out;
	}
}