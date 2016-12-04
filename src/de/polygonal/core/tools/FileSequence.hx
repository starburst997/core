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

import haxe.ds.StringMap;

/**
	Finds groups of items that follow a naming convention containing a numerical sequence index (e.g. fileA.001.png, fileA.002.png, fileA.003.png...).
**/
class FileSequence
{
	var mTrailingDigitsOnly = false;
	
	public function new(trailingDigitsOnly = false)
	{
		mTrailingDigitsOnly = trailingDigitsOnly;
	}
	
	public function find(values:Array<String>):Array<{name:String, items:Array<String>}>
	{
		values = values.copy();
		
		var matchDigits = ~/\d+/g;
		var output = [];
		
		discardStringsWithoutDigits(values);
		if (values.length == 0) return output; //quit; nothing to do
		
		/* group by comparing regular expressions, e.g. "foo01bar001" is transformed to "\D{3}\d{2}\D{3}\d{3}" */
		
		var regexLut = new StringMap<EReg>();
		for (i in values) regexLut.set(i, getRegEx(i));
		var groups = assign(values, function(a, b) return regexLut.get(a).match(b));
		
		/* remove numbers; string portion has to be identical; e.g. "a1b" and "a2c" are transformed to "ab" and "ac" */
		
		var cmpAlphabetical = function(a:String, b:String)
		{
			a = a.toLowerCase();
			b = b.toLowerCase();
			return a < b ? -1 : (a > b ? 1 : 0);
		}
		var tmp = new Array<Array<String>>();
		var stringLut:StringMap<String>;
		var cmp = function(a:String, b:String):Bool return stringLut.get(a) == stringLut.get(b);
		for (group in groups)
		{
			stringLut = new StringMap<String>();
			for (i in values) stringLut.set(i, matchDigits.replace(i, ""));
			for (j in assign(group, cmp))
			{
				j.sort(cmpAlphabetical);
				tmp.push(j);
			}
		}
		groups = tmp;
		
		/* now strings only differ by their numbers; so test if the numbers define a sequence */
		
		for (group in groups)
		{
			//build lookup tables
			//example:
			//foo_bar_5_6_0001
			//cols    ^ ^ ^
			//        0 1 2
			//column 1: left="foo_bar_5_" digits="6" right="_0001"
			
			var rows = group.length;
			var cols = countCols(group[0]);
			
			var lut:Array<String> = [];
			
			inline function getIndex(col, row) return col * rows + row;
			
			var offsetL = cols * rows * 0;
			inline function setL(col, row, val) lut[offsetL + getIndex(col, row)] = val;
			inline function getL(col, row) return lut[offsetL + getIndex(col, row)];
			
			var offsetN = cols * rows * 1;
			inline function setN(col, row, val) lut[offsetN + getIndex(col, row)] = val;
			inline function getN(col, row) return lut[offsetN + getIndex(col, row)];
			
			var offsetR = cols * rows * 2;
			inline function setR(col, row, val) lut[offsetR + getIndex(col, row)] = val;
			inline function getR(col, row) return lut[offsetR + getIndex(col, row)];
			
			var tmp = group.copy();
			for (col in 0...cols)
			{
				for (row in 0...rows)
				{
					matchDigits.match(tmp[row]);
					tmp[row] = matchDigits.matchedRight(); //match from left to right
					
					var left = matchDigits.matchedLeft();
					if (col > 0) left = getL(col - 1, row) + getN(col - 1, row) + left;
					setL(col, row, left);
					setN(col, row, matchDigits.matched(0));
					setR(col, row, matchDigits.matchedRight());
				}
			}
			
			/* scan from rightmost column (=max) to leftmost column; */
			
			var pass;
			
			var col = cols;
			while (--col > -1)
			{
				//check if string portions *left of* digits are exactly the same
				pass = true;
				var first = getL(col, 0);
				for (i in 1...rows)
				{
					if (first != getL(col, i))
					{
						pass = false;
						break;
					}
				}
				if (!pass) mTrailingDigitsOnly ? break : continue; //no sequence possible
				
				//check if string portions *right of* digits are exactly the same
				if (col < cols - 1)
				{
					pass = true;
					var first = getR(col, 0);
					for (i in 1...rows)
					{
						if (first != getR(col, 1))
						{
							pass = false;
							break;
						}
					}
				}
				if (!pass) mTrailingDigitsOnly ? break : continue; //no sequence possible
				
				//all leading strings match; now check if digits are of same length (padded with leading zeros).
				
				var firstLength = getN(col, 0).length;
				for (i in 1...rows)
				{
					if (firstLength != getN(col, i).length)
					{
						pass = false;
						break;
					}
				}
				if (!pass) mTrailingDigitsOnly ? break : continue; //no sequence possible
				
				//check if digits define a counter, there might be gaps
				var sorted = [];
				var tmp = group.copy();
				for (i in 0...rows) sorted[Std.parseInt(getN(col, i))] = tmp[i];
				
				var name = getL(col, 0) + '{counter}' + getR(col, 0);
				
				getSequences(sorted, name, output);
				
				break; //found sequence(s); no need to search remaining cols
			}
		}
		return output;
	}
	
	function discardStringsWithoutDigits(inout:Array<String>)
	{
		var matchDigits = ~/\d+/g;
		var i = 0;
		var k = inout.length;
		while (i < k)
		{
			if (matchDigits.match(inout[i]))
			{
				i++;
				continue;
			}
			k--;
			var last = inout.pop();
			if (i < k) inout[i] = last;
		}
	}
	
	function getRegEx(s:String):EReg
	{
		var pattern = "^", ereg = ~/\d+/, p;
		do
		{
			if (ereg.match(s))
			{
				p = ereg.matchedPos();
				pattern += '\\D{${p.pos}}\\d{${p.len}}';
				s = ereg.matchedRight();
			}
			else
			{
				pattern += '\\D{${s.length}}';
				break;
			}
		}
		while (true);
		pattern += "$";
		return new EReg(pattern, "");
	}
	
	function assign<T>(input:Array<T>, compare:T->T->Bool):Array<Array<T>>
	{
		var list = input.copy();
		var output = new Array<Array<T>>();
		var a = new Array<T>();
		var k = list.length, tail;
		var i, j;
		while (k > 0)
		{
			tail = list.pop();
			k--;
			i = k - 1; j = 0;
			while (i >= 0)
			{
				if (compare(tail, list[i]))
				{
					//swap i with last element and pop
					a[j++] = list[i];
					list[i] = list[--k];
					list.pop();
				}
				i--;
			}
			if (j > 0)
			{
				//output group
				a[j++] = tail;
				output.push(a);
				a = [];
			}
		}
		return output;
	}
	
	function countCols(s:String):Int
	{
		var matchDigits = ~/\d+/g;
		var c = 0;
		while (true)
		{
			if (!matchDigits.match(s)) break;
			s = matchDigits.matchedRight();
			c++;
		}
		return c;
	}
	
	function getSequences(sorted:Array<String>, name:String, output:Array<{name:String, items:Array<String>}>)
	{
		var min = -1;
		var max = -1;
		
		inline function add()
		{
			var sequence = [];
			while (min <= max) sequence.push(sorted[min++]);
			if (sequence.length > 1)
				output.push({name: name, items: sequence});
		}
		
		var i = 0;
		var k = sorted.length;
		while (i < k)
		{
			if (min == -1 && sorted[i] != null)
			{
				min = i;
				max = i;
				i++;
				continue;
			}
			if (min != -1 && sorted[i] == null)
			{
				add();
				min = -1;
			}
			max++;
			i++;
		}
		if (min != -1) add();
	}
}