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

class EaseFactory
{
	public static function create(type:Ease):Interpolation<Float>
	{
		return
		switch (type)
		{
			case None: new NullEase();
			
			case Flash(acceleration): new FlashEase(acceleration);
			
			case PowIn(degree):    new PowEaseIn(degree);
			case PowOut(degree):   new PowEaseOut(degree);
			case PowInOut(degree): new PowEaseInOut(degree);
			
			case SinIn:    new SinEaseIn();
			case SinOut:   new SinEaseOut();
			case SinInOut: new SinEaseInOut();
			
			case ExpIn:    new ExpEaseIn();
			case ExpOut:   new ExpEaseOut();
			case ExpInOut: new ExpEaseInOut();
			
			case CircularIn:    new CircularEaseIn();
			case CircularOut:   new CircularEaseOut();
			case CircularInOut: new CircularEaseInOut();
			
			case BackIn(overshoot):    new BackEaseIn(overshoot);
			case BackOut(overshoot):   new BackEaseOut(overshoot);
			case BackInOut(overshoot): new BackEaseInOut(overshoot);
			
			case ElasticIn(amplitude, period):    new ElasticEaseIn(amplitude, period);
			case ElasticOut(amplitude, period):   new ElasticEaseOut(amplitude, period);
			case ElasticInOut(amplitude, period): new ElasticEaseInOut(amplitude, period);
			
			case BounceIn:    new BounceEaseIn();
			case BounceOut:   new BounceEaseOut();
			case BounceInOut: new BounceEaseInOut();
		}
	}
}