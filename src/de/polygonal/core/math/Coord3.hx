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
package de.polygonal.core.math;

/**
	A point representing a location in (`x`,`y`,`z`) coordinate space.
**/
#if !doc @:generic #end
class Coord3<T:Float>
{
	public var x:T;
	public var y:T;
	public var z:T;
	
	public function new(x:T = untyped 0, y:T = untyped 0, z:T = untyped 0)
	{
		set(x, y, z);
	}
	
	inline public function of(other:Coord3<T>)
	{
		x = other.x;
		y = other.y;
		z = other.z;
	}
	
	inline public function set(x:T, y:T, z:T)
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}
	
	inline public function zero()
	{
		x = cast 0;
		y = cast 0;
		z = cast 0;
	}
	
	inline public function isZero():Bool
	{
		return untyped x == 0 && y == 0;
	}
	
	inline public function equals(other:Coord3<T>):Bool
	{
		return other.x == x && other.y == y;
	}
	
	public function clone():Coord3<T>
	{
		return new Coord3<T>(x, y, z);
	}
	
	public function toString():String
	{
		return Printf.format("{ Coord3 %-.4f %-.4f %-.4f }", [x, y, z]);
	}
}

typedef Coord3f = Coord3<Float>;
typedef Coord3i = Coord3<Int>;