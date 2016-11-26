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

import de.polygonal.core.fmt.StringTools;
import de.polygonal.core.log.LogFormat.*;
import de.polygonal.core.log.LogLevel;
import de.polygonal.core.log.LogMessage;
import de.polygonal.core.time.Timebase;
import de.polygonal.ds.tools.Bits;
import haxe.ds.StringMap;

import de.polygonal.core.log.LogFormat.*;

/**
	Receives log messages from a log and exports them to various outputs.
**/
class LogHandler
{
	public var level(get, set):LogLevel;
	function get_level():LogLevel return mLevel;
	function set_level(value:LogLevel):LogLevel
	{
		mLevel = value;
		if (value == Off)
			mMask = 0;
		else
			mMask = Bits.mask(LogLevel.getConstructors().length) & ~Bits.mask(value.getIndex());
		return value;
	}
	
	var mMessage:LogMessage;
	var mLevel:LogLevel;
	var mMask:Int;
	var mFormatFlags = LogFormat.PRESET_BRIEF_INFOS;
	var mFormats:StringMap<Int> = null;
	var mArgs = new Array<Dynamic>();
	var mVals = new Array<Dynamic>();
	var mMatchLineEnds = ~/[\r\n]/;
	var mMatchCR = ~/\r/g;
	var mMatchCRLF = ~/\r\n/g;
	
	function new()
	{
		level = Verbose;
	}
	
	public function free() {}
	
	public function setFormat(formatFlags:Int, tag:String = null)
	{
		if (tag != null)
		{
			if (mFormats == null)
				mFormats = new StringMap<Int>();
			mFormats.set(tag, formatFlags);
		}
		else
			mFormatFlags = formatFlags;
	}
	
	public function onMessage(message:LogMessage)
	{
		mMessage = message;
		
		if (mMask & (1 << message.lvl.getIndex()) == 0) return;
		var flags = mFormatFlags;
		if (mFormats != null && mFormats.exists(message.tag))
			flags = mFormats.get(message.tag);
		output(format(message, flags));
		
		mMessage = null;
	}
	
	function format(message:LogMessage, flags:Int):String
	{
		var f = flags;
		if (f == 0) return message.msg;
		
		var args = mArgs;
		var vals = mVals;
		
		for (i in 0...args.length) args.pop();
		for (i in 0...vals.length) vals.pop();
		
		var fmt, val;
		
		if (f & (PRINT_DATE | PRINT_TIME) > 0)
		{
			var date = Date.now().toString();
			args.push("%s");
			vals.push
			(
				if (f & (PRINT_DATE | PRINT_TIME) == PRINT_DATE | PRINT_TIME)
					date.substr(5); //mm-dd hh:mm:ss
				else
				if (f & PRINT_TIME > 0)
					date.substr(11); //hh:mm:ss
				else
					date.substr(5, 5) //mm-dd
			);
		}
		
		if (f & PRINT_TIME_STEP > 0)
		{
			if (Timebase.context == None) f &= ~PRINT_TIME_STEP;
		}
		
		if (f & PRINT_TIME_STEP > 0)
		{
			fmt = f & (PRINT_DATE | PRINT_TIME) > 0 ? " %s%d" : "%s%d";
			switch (Timebase.context)
			{
				case Tick:
					args.push(fmt);
					vals.push("T");
					vals.push(Timebase.numTickCalls);
				
				case Draw: "D";
					args.push(fmt);
					vals.push("D");
					vals.push(Timebase.numDrawCalls);
				
				case None:
			};
		}
		
		if (f & PRINT_LEVEL > 0)
		{
			args.push(f & (PRINT_DATE | PRINT_TIME | PRINT_TIME_STEP) > 0 ? " %s" : "%s");
			vals.push(message.lvl.getName().charAt(0));
		}
		
		if (f & PRINT_NAME > 0)
		{
			args.push(f & PRINT_LEVEL > 0 ? "/%s" : "%s");
			vals.push(message.log.name);
			if (f & PRINT_TAG > 0)
			{
				if (message.tag != null)
				{
					args.push("/%s");
					vals.push(message.tag);
				}
			}
		}
		
		if (message.pos != null)
		{
			if (f & (PRINT_CLASS | PRINT_METHOD | PRINT_LINE) > 0)
			{
				fmt = "(";
				if (f & PRINT_CLASS > 0)
				{
					var className = message.pos.className;
					if (f & PRINT_CLASS_SHORT > 0)
						className = className.substr(className.lastIndexOf(".") + 1);
					if (className.length > 30)
						className = StringTools.ellipsis(className, 30, 0);
					fmt += "%s";
					vals.push(className);
				}
				if (f & PRINT_METHOD > 0)
				{
					var methodName = message.pos.methodName;
					if (methodName.length > 30) methodName = StringTools.ellipsis(methodName, 30, 0);
					fmt += (f & PRINT_CLASS > 0) ? ".%s" : "%s";
					vals.push(methodName);
				}
				if (f & PRINT_LINE > 0)
				{
					fmt += (f & (PRINT_CLASS | PRINT_METHOD) > 0) ? " %04d" : "%04d";
					vals.push(message.pos.lineNumber);
				}
				fmt += ")";
				args.push(fmt);
			}
		}
		
		var s = message.msg;
		if (mMatchLineEnds.match(s))
		{
			s = mMatchCRLF.replace(s, "\n");
			var lines = s.split("\n");
			args.push("%s");
			vals.push(":\n");
			var k = lines.length;
			for (i in 0...k)
			{
				if (f & PRINT_LEVEL > 0)
				{
					args.push("%s");
					vals.push(message.lvl.getName().charAt(0));
				}
				if (f & PRINT_NAME > 0)
				{
					args.push(f & PRINT_LEVEL > 0 ? "/%s" : "%s");
					vals.push(message.log.name);
					if (f & PRINT_TAG > 0)
					{
						if (message.tag != null)
						{
							args.push("/%s");
							vals.push(message.tag);
						}
					}
				}
				fmt = i < k - 1 ? ": %s\n" : ": %s";
				args.push(fmt);
				vals.push(lines[i]);
			}
		}
		else
		{
			args.push(": %s");
			vals.push(s);
		}
		
		return Printf.format(args.join(""), vals);
	}
	
	function output(msg:String)
	{
		return throw "override for implementation";
	}
}