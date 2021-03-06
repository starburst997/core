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
package de.polygonal.core.math.ease;

/**
	Power easing out (quadratic, cubic, quartic, quintic)
	
	See Robert Penner Easing Equations.
**/
class PowEaseOut implements Interpolation<Float>
{
	public inline static var DEGREE_QUADRATIC = 2;
	public inline static var DEGREE_CUBIC     = 3;
	public inline static var DEGREE_QUARTIC   = 4;
	public inline static var DEGREE_QUINTIC   = 5;
	
	public var degree:Int;
	
	public function new(degree:Int)
	{
		assert(degree > 1 && degree < 6);
		this.degree = degree;
	}
	
	/**
		Computes the easing value using the given parameter `t` in the interval [0,1].
	**/
	public function interpolate(t:Float):Float
	{
		return Math.pow(t - 1, degree) * (degree & 1 == 0 ? -1 : 1) + 1;
	}
}