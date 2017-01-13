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
package de.polygonal.core.time;

import de.polygonal.ds.Sll;

@:enum
abstract TimebaseContext(Int)
{
  var None = 0;
  var Tick = 1;
  var Draw = 2;
}

/**
	A Timebase is a constantly ticking source of time.
**/
class Timebase
{
	/**
		Converts `seconds` seconds to ticks.
	**/
	public static inline function secondsToTicks(seconds:Float):Int
	{
		return Math.round(seconds / tickRate);
	}
	
	/**
		Converts `ticks` to seconds.
	**/
	public static inline function ticksToSeconds(ticks:Int):Float
	{
		return ticks * tickRate;
	}
	
	/**
		If true, time is consumed using a fixed time step (default is true).
	**/
	public static var useFixedTimeStep = true;
	
	/**
		The update rate measured in seconds per tick.
		
		The default update rate is 60 ticks per second (or ~16.6ms per tick).
	**/
	public static var tickRate(default, null) = .01666666;
	
	/**
		The accumulator limit in seconds. Default is ten times `tickRate`.
	**/
	public static var accumulatorLimit = 10 * tickRate;
	
	/**
		Elapsed time in seconds since application start.
	**/
	public static var elapsedTime(default, null) = 0.;
	
	/**
		Elapsed "virtual" time in seconds (includes scaling).
	**/
	public static var elapsedGameTime(default, null) = 0.;
	
	/**
		Current frame delta time in seconds.
	**/
	public static var timeDelta(default, null) = 0.;
	
	/**
		Current "virtual" frame delta time in seconds (includes scaling).
	**/
	public static var gameTimeDelta(default, null) = 0.;
	
	/**
		The current time scale > 0.
	**/
	public static var timeScale = 1.;
	
	/**
		The total number of processed ticks since application start.
	**/
	public static var numTickCalls(default, null) = 0;
	
	/**
		The total number of rendered frames since application start.
	**/
	public static var numDrawCalls(default, null) = 0;
	
	/**
		Frames per second (how many frames were rendered in 1 second).
		
		Updated every second.
	**/
	public static var fps(default, null) = 60;
	
	public static var context = TimebaseContext.None;
	
	public static function addListener(listener:TimebaseListener)
	{
		if (_listenerList == null) _listenerList = new Sll<TimebaseListener>();
		if (!_listenerList.contains(listener)) _listenerList.add(listener);
	}
	
	public static function removeListener(listener:TimebaseListener)
	{
		_listenerList.remove(listener);
	}
	
	static var _time:Time;
	static var _listenerList:Sll<TimebaseListener>;
	static var _paused:Bool;
	static var _remainingFreezeTime = 0.;
	static var _accumulator = 0.;
	static var _fpsTicks = 0;
	static var _fpsTime = 0.;
	static var _past = 0.;
	
	public static function setTime(time:Time)
	{
		if (_time != null)
		{
			_time.setTimingEventHandler(null);
			if (time == null)
			{
				_time = null;
				return;
			}
		}
		_time = time;
		_time.setTimingEventHandler(handleTimeUpdate);
		
		elapsedTime = elapsedGameTime = timeDelta = gameTimeDelta = 0;
		numTickCalls = numDrawCalls = 0;
	}
	
	public static function free()
	{
		if (_listenerList != null)
		{
			_listenerList.free();
			_listenerList = null;
		}
	}
	
	/**
		Stops the flow of time.
	**/
	public static function pause()
	{
		if (_paused) return;
		_paused = true;
	}
	
	/**
		Resumes the flow of time.
	**/
	public static function resume()
	{
		if (!_paused) return;
		_paused = false;
		_accumulator = 0.;
		_past = _time.now();
	}
	
	/**
		Toggles (pause/resume) the flow of time.
	**/
	public static function togglePause()
	{
		_paused ? resume() : pause();
	}
	
	/**
		Freezes the flow of time for `seconds`.
	**/
	public static function freeze(seconds:Float)
	{
		_remainingFreezeTime = seconds;
		_accumulator = 0;
	}
	
	/**
		Performs a manual update step.
	**/
	public static function step(dt = 0., draw = true)
	{
		if (dt == 0) dt = tickRate;
		
		timeDelta = dt;
		elapsedTime += timeDelta;
		
		assert(timeScale > 0);
		
		gameTimeDelta = dt * timeScale;
		elapsedGameTime += gameTimeDelta;
		
		onTick(dt);
		if (draw) onDraw(1);
		
		context = None;
	}
	
	static function handleTimeUpdate(now:Float):Void 
	{
		if (_paused) return;
		
		assert(timeScale > 0);
		
		var dt = now - _past;
		_past = now;
		
		timeDelta = dt;
		elapsedTime += dt;
		
		_fpsTicks++;
		_fpsTime += dt;
		if (_fpsTime >= 1)
		{
			_fpsTime = 0;
			fps = _fpsTicks;
			_fpsTicks = 0;
		}
		
		if (_remainingFreezeTime > 0.)
		{
			_remainingFreezeTime -= timeDelta;
			onTick(0.);
			onDraw(1.);
			return;
		}
		
		if (useFixedTimeStep)
		{
			_accumulator += timeDelta * timeScale;
			
			//clamp accumulator to prevent "spiral of death"
			if (_accumulator > accumulatorLimit) _accumulator = accumulatorLimit;
			
			var updated = false;
			while (_accumulator >= tickRate)
			{
				_accumulator -= tickRate;
				gameTimeDelta = tickRate * timeScale;
				elapsedGameTime += gameTimeDelta;
				onTick(gameTimeDelta);
				updated = true;
				if (_paused) break;
			}
			
			if (updated) onDraw(_accumulator / tickRate);
		}
		else
		{
			_accumulator = 0;
			gameTimeDelta = dt * timeScale;
			elapsedGameTime += gameTimeDelta;
			onTick(gameTimeDelta);
			onDraw(1.);
		}
	}
	
	@:access(de.polygonal.core.time.TimebaseListener)
	inline static function onTick(dt:Float)
	{
		if (_listenerList == null) return;
		
		context = Tick;
		var n = _listenerList.head, next;
		while (n != null)
		{
			next = n.next;
			n.val.onTick(dt);
			n = next;
		}
		numTickCalls++;
		context = None;
	}
	
	@:access(de.polygonal.core.time.TimebaseListener)
	inline static function onDraw(alpha:Float)
	{
		if (_listenerList == null) return;
		
		context = Draw;
		var n = _listenerList.head, next;
		while (n != null)
		{
			next = n.next;
			n.val.onDraw(alpha);
			n = next;
		}
		numDrawCalls++;
		context = None;
	}
}