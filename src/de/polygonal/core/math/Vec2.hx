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

import de.polygonal.core.math.Coord2.Coord2f;
import de.polygonal.core.math.Mathematics.M;
import de.polygonal.core.math.random.Random;

/**
	A 2d vector; a geometric object that has both a magnitude (or length) and direction.
**/
class Vec2 extends Coord2f
{
	/**
		Returns the angle between segments formed by the vector `a` and `b`.
	**/
	public inline static function angle(a:Vec2, b:Vec2):Float
	{
		return Math.atan2(perpDot(a, b), dot(a, b));
	}
	
	/**
		Computes the unit length vector `out` = (`b`-`a`)/||`b`-`a`|| and returns the length of `b`-`a`.
	**/
	public inline static function dir(a:Vec2, b:Vec2, out:Vec2):Float
	{
		var dx = b.x - a.x;
		var dy = b.y - a.y;
		var l = Math.sqrt(dx * dx + dy * dy);
		out.x = dx / l;
		out.y = dy / l;
		return l;
	}
	
	/**
		Computes the unit length vector `out` = (`b`-`a`)/||`b`-`a`|| and returns the length of `b`-`a`, where a = (`ax`,`ay`) and b = (`bx`,`by`).
	**/
	public inline static function dirf(ax:Float, ay:Float, bx:Float, by:Float, out:Vec2):Float
	{
		var dx = bx - ax;
		var dy = by - ay;
		var l = Math.sqrt(dx * dx + dy * dy);
		out.x = dx / l;
		out.y = dy / l;
		return l;
	}
	
	/**
		Computes the dot product `a` · `b`.
		
		Also known as inner product or scalar product.
	**/
	public inline static function dot(a:Vec2, b:Vec2):Float return dotf(a.x, a.y, b.x, b.y);
	
	/**
		Computes the dot product (`ax`,`ay`) · (`bx`,`by`).
		
		Also known as inner product or scalar product.
	**/
	public inline static function dotf(ax:Float, ay:Float, bx:Float, by:Float) return ax * bx + ay * by;
	
	/**
		Tests if `c` is left, on or right of an infinite line through `a` and `b`.
		
		Returns a value that is:
		
		 - &gt; 0 for `c` left of the line through `a` and `b`
		 - = 0 for `c` on the line
		 - &lt; 0 for `c` right of the line
	**/
	public inline static function isLeft(a:Vec2, b:Vec2, c:Vec2):Float
	{
		return (b.y - a.x) * (c.y - a.y) - (c.y - a.x) * (b.y - a.y);
	}
	
	/**
		Returns `out` = min(`a`,`b`).
	**/
	public inline static function min(a:Vec2, b:Vec2, out:Vec2)
	{
		out.x = M.fmin(a.x, b.x);
		out.y = M.fmin(a.y, b.y);
	}
	
	/**
		Returns `out` = max(`a`,`b`).
	**/
	public inline static function max(a:Vec2, b:Vec2, out:Vec2)
	{
		out.x = M.fmax(a.x, b.x);
		out.y = M.fmax(a.y, b.y);
	}
	
	/**
		Returns the midpoint `out` = (`a`+`b`)/2.
	**/
	public inline static function midpoint(a:Vec2, b:Vec2, out:Vec2):Vec2
	{
		out.x = a.x + (b.x - a.x) / 2;
		out.y = a.y + (b.y - a.y) / 2;
		return out;
	}
	
	/**
		Gram-Schmidt orthonormalization of `u` and `v`.
	**/
	public static function orthonormalize(u:Vec2, v:Vec2)
	{
		u.normalize();
		var uv = dot(u, v);
		v.x -= u.x * uv;
		v.y -= u.y * uv;
		v.normalize();
	}
	
	/**
		Computes the perpendicular bisector `out` of the segment between the point `a` and `b`.
		
		The perpendicular bisector is the line that passes through the midpoint between `a` and `b`
		(given by (`a`+`b`)/2) and is perpendicular to the vector `b`-`a`.
		Equation: p(t) = 1/2 (`a`+`b`) + perp(`b`-`a`)`t`
	**/
	public inline static function perpBisecor(a:Vec2, b:Vec2, t:Float, out:Vec2)
	{
		var ax = a.x;
		var ay = a.y;
		var bx = b.x;
		var by = b.y;
		var dx = -(by - ay);
		var dy =  (bx - ax);
		out.x = (ax + bx) / 2 + dx * t;
		out.y = (ay + by) / 2 + dy * t;
	}
	
	/**
		Computes the perp-dot product perp(`a`)`b`, where perp() is defined to rotate a vector 90° counterclockwise (CCW).
		
		Also known as exterior product or outer product.
		This is the determinant of the matrix with first row `a` and second row `b`.
	**/
	public inline static function perpDot(a:Vec2, b:Vec2):Float return perpDotf(a.x, a.y, b.x, b.y);
	
	/**
		Computes the perp-dot product perp((`ax`,`ay`))(`bx`,`by`), where perp() is defined to rotate a vector 90° counterclockwise (CCW).
	**/
	public inline static function perpDotf(ax:Float, ay:Float, bx:Float, by:Float):Float return ax * by - ay * bx;
	
	/**
		Creates a random vector with x in the range [`minX`,`maxX`] and y in the range [`minY`,`maxY`].
	**/
	public inline static function random(minX:Float, maxX:Float, minY:Float, maxY:Float):Vec2
	{
		return new Vec2(Random.frandRange(minX, maxX), Random.frandRange(minY, maxY));
	}
	
	/**
		Vector reflection. Returns `out` = `v`-(2dot(`v`,`n`))`n`.
	**/
	public inline static function reflect(v:Vec2, n:Vec2, out:Vec2):Vec2
	{
		var t = v.x * n.x + v.y * n.y;
		out.x = v.x - (2 * t) * n.x;
		out.y = v.y - (2 * t) * n.y;
		return out;
	}
	
	/**
		Vector reflection. Returns `out` = `v`-(2dot(`v`,`n`))`n`.
	**/
	public inline static function reflectf(vx:Float, vy:Float, nx:Float, ny:Float, out:Vec2):Vec2
	{
		var t = vx * nx + vy * ny;
		out.x = vx - (2 * t) * nx;
		out.y = vy - (2 * t) * ny;
		return out;
	}
	
	/**
		Computes the signed triangle area formed by the points `a`, `b` and `c`.
	**/
	public inline static function signedTriArea(a:Vec2, b:Vec2, c:Vec2):Float
	{
		return (a.x - c.x) * (b.y - c.y) - (a.y - c.y) * (b.x - c.x);
	}
	
	public function new(x:Float = 0., y:Float = 0.)
	{
		super(x, y);
	}
	
	public inline function flip():Vec2
	{
		x = -x;
		y = -y;
		return this;
	}
	
	/**
		The vector length.
	**/
	public inline function length():Float
	{
		return Math.sqrt(lengthSq());
	}
	
	/**
		The squared vector length.
	**/
	public inline function lengthSq():Float
	{
		return x * x + y * y;
	}
	
	/**
		Right-handed perp operator (z-axis pointing out of the screen); returns (`y`,-`x`).
	**/
	public inline function perpR()
	{
		var t = y; y = -x; x = t;
	}
	
	/**
		Left-handed perp operator (z-axis pointing into the screen); returns (-`y`,`x`).
	**/
	public inline function perpL()
	{
		var t = y; y = x; x = -t;
	}
	
	/**
		Converts this vector to unit length and returns the original vector length.
	**/
	public inline function normalize():Float
	{
		var l = length();
		l = l < M.EPS ? 0 : 1 / l;
		x *= l;
		y *= l;
		return l;
	}
	
	/**
		Scales this vector by `value`.
	**/
	public inline function scale(value:Float)
	{
		x *= value;
		y *= value;
	}
	
	/**
		Clamps this vector to `max` length.
	**/
	public inline function clamp(max:Float)
	{
		var l = lengthSq();
		if (l > max * max)
		{
			l = Math.sqrt(l);
			x = (x / l) * max;
			y = (y / l) * max;
		}
	}
	
	override public function clone():Vec2
	{
		return new Vec2(x, y);
	}
	
	override public function toString():String
	{
		return Printf.format("{ Vec2 %-.4f %-.4f }", [x, y]);
	}
}