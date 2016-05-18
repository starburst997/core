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
package de.polygonal.core.log;

import de.polygonal.ds.tools.Bits;

/**
	A set of standard logging levels that can be used to filter logging output.
**/
class LogLevel
{
	/**
		A message level providing tracing information.
	**/
	public inline static var DEBUG = 0x01;
	
	/**
		A message level for informational messages.
	**/
	public inline static var INFO = 0x02;
	
	/**
		A message level indicating a potential problem.
	**/
	public inline static var WARN = 0x04;
	
	/**
		A message level indicating a serious failure.
	**/
	public inline static var ERROR = 0x08;
	
	/**
		A special level that can be used to turn off logging.
	**/
	public inline static var OFF = 0x10;
	
	/**
		A bitfield of all log levels.
	**/
	public inline static var ALL = DEBUG | INFO | WARN | ERROR | OFF;

	/**
		Returns the human-readable name of a log level.
	**/
	public static function getName(level:Int):String
	{
		return
		switch (Bits.ntz(level))
		{
			case 0: "DEBUG";
			case 1: "INFO";
			case 2: "WARN";
			case 3: "ERROR";
			case 4: "OFF";
			case _: "?";
		}
	}
	
	public static function getShortName(level:Int):String
	{
		return
		switch (Bits.ntz(level))
		{
			case 0: "D";
			case 1: "I";
			case 2: "W";
			case 3: "E";
			case 4: "O";
			case _: "?";
		}
	}
}