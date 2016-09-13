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
package de.polygonal.core.util;

import haxe.ds.StringMap;

class FileSequence
{
	//TODO percent sign
	//explcicit/exact : preserve #digits
	public static function find(list:Array<String>):Array<{name:String, items:Array<String>}>
	{
		var result = [];
		
		if (list.length < 2) return result;
		
		list = sort(unique(list));
		
		var nth = list;
		
		var n = 1;
		var k = 0;
		
		var iter = 0;
		while (true)
		{
			if (iter++ > 10)
			{
				trace( 'bail out: ' + list[0]);
				break;
			}
			
			var org = list.copy();
			
			var output = scan(nth);
			
			//search exhausted?
			if (output.length == 0)
			{
				if (++k == 2)
					return result;
			}
			else
				k = 0;
			
			for (indices in output)
			{
				var seq = Lambda.array(Lambda.map(indices, function(x) return org[x]));
				result.push({name: makeName(seq[0], n), items: seq}); //store sequence
				list = subtract(list, seq); //remove sequence from list
			}
			
			if (list.length < 2) break; //done: no items left
			
			//replace the first n occurences of \d+ with XXX
			var regex = ~/\d+/;
			var hasCounter = false;
			nth = [];
			for (i in 0...list.length)
			{
				var v = list[i];
				for (j in 0...n)
				{
					if (regex.match(v))
					{
						v = regex.replace(v, "XXX");
						hasCounter = true;
					}
				}
				nth[i] = v;
			}
			
			if (!hasCounter) break; //done: no counter
			
			n++;
		}
		
		return result;
	}
	
	static function makeName(name:String, nth:Int):String
	{
		//replace nth occurence of counter with "xxx"
		var p = null;
		var i = 1;
		var s = name;
		var regex = ~/\d+/;
		while (regex.match(s))
		{
			if (i == nth) p = regex.matchedPos();
			
			var filler = StringTools.rpad("", "X", regex.matched(0).length);
			s = regex.replace(s, filler);
			i++;
		}
		if (p == null) return "??";
		
		return name.substr(0, p.pos) + "xxx" + name.substr(p.pos + p.len);
	}
	
	static function scan(list:Array<String>):Array<Array<Int>>
	{
		var output = [];
		
		if (list.length < 2) return output; //early out
		
		//TODO don't allocate array every time
		var indices = null;
		var regex = ~/\d+/; //match counter
		
		var l0 = null;
		var r0 = null;
		var c0 = -1;
		
		var l1, r1, c1;
		
		var i = 0;
		var k = list.length;
		while (i < k)
		{
			if (!regex.match(list[i])) { i++; continue; } //ignore items without digits
			
			//split into left-counter-right
			l0 = regex.matchedLeft();
			c0 = Std.parseInt(regex.matched(0));
			r0 = regex.matchedRight();
			
			//start sequence using current value as reference
			indices = [i++];
			break;
		}
		
		if (indices == null) return output; //quit: no counter found
		
		while (i < k)
		{
			if (!regex.match(list[i])) { i++; continue; } //ignore items without digits
			
			l1 = regex.matchedLeft();
			c1 = Std.parseInt(regex.matched(0));
			r1 = regex.matchedRight();
			
			//compare with previous item
			if (l1 == l0 && (c1 - c0 == 1) && r1 == r0) //successor?
			{
				c0 = c1;
				
				//add to sequence
				indices.push(i++);
				continue;
			}
			
			if (indices.length > 1) output.push(indices); //store result?
			
			//disjoint, start over using current item as reference
			l0 = l1;
			c0 = c1;
			r0 = r1;
			indices = [i++];
		}
		
		if (indices.length > 1) output.push(indices); //store result?
		
		return output;
	}
	
	static function subtract(a:Array<String>, b:Array<String>):Array<String>
	{
		//returns a - b
		var map = new StringMap<Bool>();
		for (i in b) map.set(i, true);
		return Lambda.array(Lambda.filter(a, function(x) return !map.exists(x)));
	}
	
	static function unique(x:Array<String>):Array<String>
	{
		var map = new StringMap<Bool>();
		var a = [];
		for (i in x)
		{
			if (!map.exists(i))
			{
				map.set(i, true);
				a.push(i);
			}
		}
		return a;
	}
	
	static function sort(list:Array<String>):Array<String>
	{
		inline function count(x:String):Int
		{
			//value_56 => value_% => returns 1
			//value123_03_1 => value%_%_% => returns 3 
			x = ~/\d+/g.replace(x, '%');
			var c = 0;
			for (i in 0...x.length)
				if (x.charAt(i) == '%')
					c++;
			return c;
		}
		
		var a:Array<Array<String>> = [];
		for (i in list)
		{
			var c = count(i) - 1;
			if (c < 0) continue;
			if (a[c] == null) a[c] = [];
			a[c].push(i);
		}
		
		var tmp = [];
		for (i in 0...a.length)
		{
			if (a[i] != null)
			{
				a[i].sort(function(a:String, b:String):Int return a < b ? -1 : (a > b ? 1 : 0));
				for (j in a[i]) tmp.push(j);
			}
		}
		return tmp;
	}
}