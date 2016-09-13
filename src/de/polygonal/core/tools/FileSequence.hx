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

import de.polygonal.ds.Sll;
import de.polygonal.ds.tools.Compare;

//private typedef Strings = Array<String>;

class FileSequence
{
	public static function find(values:Array<String>):Array<Array<String>>
	{
		var first = null;
		var ereg:EReg = null;
		
		var match = function(a, b)
		{
			/*if (a != first)
			{
				first = a;
				ereg = getRegEx(a);
			}*/
			//return ereg.match(b);
			
			return getRegEx(a).match(b);
		}
		
		var r = ~/\d+/g;
		
		var matches = split(values, match);
		
		for (i in matches)
		{
			L.i('match list:');
			trace(i.join("\n"));
		}
		
		
		var set = matches[1];
		var x = set.map(function(e) return r.replace(e, ""));
		
		match = function(a, b) return r.replace(a, "") == r.replace(b, "");
		var output = split(set, match);
		
		for (i in output)
		{
			L.w(i);
			//000 W/activity(TestFileSequence.main 0092): [bla_1_04,bla_2_06,bla_3_05]
			
			//now we have a potential set that can be a sequence
			
			i.sort(Compare.cmpAlphabeticalRise);
			
			L.w(i);
			//000 W/activity(TestFileSequence.main 0098): [bla_1_04,bla_2_06,bla_3_05]
			
			//TODO find i
			
			var sequenceList = test(i);
		
			for (i in sequenceList)
			{
				trace('sequence:');
				for (j in i)
				{
					trace('  ' + j);
				}
			}
			break;
		}
		
		
		return null;
	}
	
	static function getRegEx(string:String):EReg
	{
		//build regular expression; e.g. foo_001_bar1.ext -> "^.{4}\d{3}.{4}\d{1}.{4}$"
		var pattern = "^", ereg = ~/\d+/, p;
		do
		{
			if (ereg.match(string))
			{
				p = ereg.matchedPos();
				pattern += '.{${p.pos}}\\d{${p.len}}';
				string = ereg.matchedRight();
			}
			else
			{
				pattern += '.{${string.length}}';
				break;
			}
		}
		while (true);
		pattern += "$";
		return new EReg(pattern, "");
	}
	
	static function split(input:Array<String>, equal:String->String->Bool):Array<Array<String>>
	{
		var list = new Sll<String>(input), output = [], set = [], first:String;
		while (!list.isEmpty())
		{
			var n = list.head;
			
			first = n.val;
			set.push(n.val);
			list.removeHead();
			
			n = list.head;
			while (n != null)
			{
				var hook = n.next;
				if (equal(first, n.val))
				{
					set.push(n.val);
					n.unlink();
				}
				n = hook;
			}
			
			if (set.length > 1)
			{
				output.push(set);
				set = [];
			}
			else
				set.pop();
		}
		return output;
	}
	
	/**
		Finds all file sequences in `a`. At this point all strings only differ by their numbers
	**/
	static function test(a:Array<String>):Array<Array<String>>
	{
		var output = [];
		var ereg = ~/\d+/;
		
		/* determine #levels, e.g. "name_1_name001_name2 has 3 levels */
		
		var levels = 0;
		var s = a[0];
		do
		{
			if (ereg.match(s))
			{
				s = ereg.matchedRight();
				levels++;
			}
			else
				break;
		}
		while (true);
		
		/* compare from left -> right */
		
		var list = a.copy();
		
		inline function match(s:String, numLevels:Int):{pos:Int, right:String}
		{
			for (i in 0...numLevels)
			{
				ereg.match(s);
				s = ereg.matchedRight();
			}
			return {pos: Std.parseInt(ereg.matched(0)), right: s};
		}
		
		var level = 1;
		while (level <= levels)
		{
			var remainder = [];
			
			while (list.length > 0)
			{
				//first entry defines string right of number
				var sequence = [];
				
				var o = match(list[0], level);
				
				var right = o.right;
				sequence.push({pos: o.pos, name: list[0]});
				
				list.shift();
				
				var i = 0;
				var k = list.length;
				while (i < k)
				{
					var o = match(list[i], level);
					
					if (right == o.right)
					{
						sequence.push({pos: o.pos, name: list[i]});
						
						list.splice(i, 1);
						k--;
						continue;
					}
					
					i++;
				}
				
				if (sequence.length == 1)
				{
					//no sequence found; remember for next iteration with level + 1
					remainder.push(sequence[0].name);
					continue;
				}
				
				//found sequence, sort by position and store
				sequence.sort(function(a, b) return a.pos - b.pos);
				output.push([for (i in 0...sequence.length) sequence[i].name]);
			}
			
			//process next level
			level++;
			list = remainder;
		}
		
		return output;
	}
}