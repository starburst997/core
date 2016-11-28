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
package de.polygonal.core.math;

import de.polygonal.ds.ArrayedQueue;

/**
	The arithmetic mean of a set of numbers.
**/
class Mean
{
	/**
		The total amount of numbers; calling `add()` increases `size` by one.
	**/
	public var size(get, never):Int;
	function get_size():Int return mQue.size;
	
	var mValue:Float;
	var mQue:ArrayedQueue<Float>;
	var mChanged:Bool;
	
	public function new(capacity:Int, initialValue:Float = 0)
	{
		mQue = new ArrayedQueue<Float>(capacity);
		for (i in 0...capacity) mQue.unsafeEnqueue(initialValue);
		clear();
	}
	
	/**
		The arithmetic mean of the current set of numbers.
	**/
	public var value(get_value, never):Float;
	inline function get_value():Float
	{
		if (mChanged) compute();
		return mValue;
	}
	
	/**
		Removes all numbers from the set.
	**/
	public inline function clear()
	{
		mValue = 0;
		mChanged = true;
	}
	
	/**
		Adds `value` to the set of numbers.
		
		If `size` equals `capacity`, the oldest numbers is overwritten by `value`.
	**/
	public function add(value:Float)
	{
		var q = mQue;
		if (q.size == q.capacity) q.dequeue();
		q.unsafeEnqueue(value);
		mChanged = true;
	}
	
	function compute()
	{
		mChanged = false;
		mValue = 0;
		var q = mQue;
		if (q.isEmpty()) return;
		for (i in 0...q.size) mValue += q.get(i);
		mValue /= size;
	}
}