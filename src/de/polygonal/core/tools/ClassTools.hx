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
package de.polygonal.core.tools;

class ClassTools
{
	/**
		Returns the qualified class name of `value`.
	**/
	public static function getClassName(value:Dynamic):String
	{
		if (Std.is(value, Class))
			return Type.getClassName(value);
		else
		if (Type.getClass(value) != null)
			return getClassName(Type.getClass(value));
		else
			return "";
	}
	
	/**
		Returns the unqualified class name of `value`.
	**/
	public static function getUnqualifiedClassName(value:Dynamic):String
	{
		if (Std.is(value, Class))
		{
			var s = Type.getClassName(value);
			return s.substr(s.lastIndexOf(".") + 1);
		}
		else
		if (Type.getClass(value) != null)
			return getUnqualifiedClassName(Type.getClass(value));
		else
			return "";
	}
	
	/**
		Extracts the package name from `value`.
	**/
	public static function getPackageName(value:Dynamic):String
	{
		if (Std.is(value, String))
		{
			var s:String = value;
			var i = s.lastIndexOf(".");
			if (i != -1)
				return s.substr(0, i);
			else
				return "";
		}
		else
		if (Std.is(value, Class))
		{
			var s = Type.getClassName(value);
			var i = s.lastIndexOf(".");
			if (i != -1)
				return s.substr(0, i);
			else
				return "";
		}
		else
		if (Type.getClass(value) != null)
			return getPackageName(Type.getClass(value));
		else
			throw "invalid argument";
	}
	/**
		Creates an instance of a class given a fully qualified class `name`.
	**/
	public static function createInstance<T>(name:String, ?args:Array<Dynamic>):T
	{
		if (args == null) args = [];
		return Type.createInstance(Type.resolveClass(name), args);
	}
}