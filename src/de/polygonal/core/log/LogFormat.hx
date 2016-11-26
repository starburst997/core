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
package de.polygonal.core.log;

@:build(de.polygonal.core.macro.IntConsts.build(
[
	PRINT_DATE,
	PRINT_TIME,
	PRINT_TIME_STEP,
	
	PRINT_LEVEL,
	PRINT_NAME,
	PRINT_TAG,
	
	PRINT_CLASS,
	PRINT_CLASS_SHORT,
	PRINT_METHOD,
	PRINT_LINE
], true, true))
class LogFormat
{
	public inline static var PRESET_RAW = 0;
	
	public inline static var PRESET_BRIEF = PRINT_TIME_STEP | PRINT_LEVEL | PRINT_NAME | PRINT_TAG;
	
	public inline static var PRESET_BRIEF_INFOS = PRESET_BRIEF | PRINT_LINE | PRINT_CLASS | PRINT_CLASS_SHORT | PRINT_METHOD;
	
	public inline static var PRESET_FULL = PRESET_BRIEF_INFOS | PRINT_DATE | PRINT_TIME;
}