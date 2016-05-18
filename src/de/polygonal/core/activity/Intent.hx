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

class Intent
{
	public var caller(default, null):Activity;
	
	public var extras(default, null):Extras;
	
	public var isChild:Bool;
	
	public function new(caller:Activity, extras:Dynamic)
	{
		this.caller = caller;
		this.extras = new Extras(extras);
	}
}

private class Extras
{
	public var map(default, null):Dynamic;
	
	public var get:ExtrasGet;
	public var has:ExtrasHas;
	
	public function new(data:Dynamic)
	{
		map = data;
		get = new ExtrasGet(map);
		has = new ExtrasHas(map);
	}
}

private class ExtrasGet implements Dynamic<Dynamic>
{
	var mMap:Dynamic;
	
	public function new(map:Dynamic)
	{
		if (map == null) map = {};
		mMap = map;
	}
	
	public function resolve(key:String):Dynamic
	{
		if (Reflect.hasField(mMap, key))
			return Reflect.field(mMap, key);
		throw 'Extras object is missing field $key';
	}
}

private class ExtrasHas implements Dynamic<Bool>
{
	var mMap:Dynamic;
	
	public function new(map:Dynamic) mMap = map;
	
	public function resolve(key:String):Bool
	{
		if (mMap == null) return false;
		return Reflect.hasField(mMap, key);
	}
}