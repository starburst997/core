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
package de.polygonal.core.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr.Field;
import haxe.macro.Expr.FieldType;
import sys.FileSystem;
import sys.io.File;
import Type.ValueType;
using Reflect;

typedef Node =
{
	var key:String; var val:String;
	var parent:Node;
	var children:Array<Node>;
	var a:Array<Field>;
}
#end

class Config
{
	macro public static function build(path:String):Array<Field>
	{
		var module = Std.string(Context.getLocalModule());
		Context.registerModuleDependency(module, path);
		
		function insert(obj:{}, path:Array<String>, pos:Int, val:Dynamic)
		{
			if (obj.hasField(path[pos]))
			{
				if (pos == path.length - 1)
					obj.setField(path[pos], val);
				else
					insert(obj.field(path[pos]), path, pos + 1, val);
			}
			else
			{
				if (pos == path.length - 1)
					obj.setField(path[pos], val);
				else
				{
					var q = {};
					obj.setField(path[pos], q);
					insert(q, path, pos + 1, val);
				}
			}
		}
		
		if (!FileSystem.exists(path)) Context.fatalError('file "$path" not found', Context.currentPos());
		
		var contents = File.getContent(path);
		var rawStruct = {};
		var valStruct = {};
		
		var keyValuePairs = parse(contents);
		var i = 0, k = keyValuePairs.length, key, val, a;
		while (i < k)
		{
			key = keyValuePairs[i++];
			val = keyValuePairs[i++];
			a = key.split(".");
			insert(rawStruct, a, 0, val);
			try 
			{
				insert(valStruct, a, 0, getValue(val));
			}
			catch(error:Dynamic)
			{
				var min = contents.indexOf(val);
				var max = min + val.length;
				Context.fatalError("invalid value", Context.makePosition({min: min, max: max, file: path}));
			}
		}
		
		function getNodeTree(o:Dynamic):Node
		{
			inline function getNode():Node
				return {key: null, val: null, parent: null, children: null, a: []};
			
			var root = getNode();
			root.key = "root";
			
			var stack:Array<Dynamic> = [root, o];
			var top = 2;
			var fields, n, c;
			while (top > 0)
			{
				o = stack[--top];
				n = stack[--top];
				
				fields = o.fields();
				
				//calling Reflect.fields("string")
				if (fields.length == 2 && fields[0] == "__s" && fields[1] == "length")
					continue;
				
				for (key in fields)
				{
					//create child node `c` & add to parent `n`
					c = getNode();
					c.key = key;
					c.val = o.field(key);
					c.parent = n;
					if (n.children == null) n.children = [];
					n.children.push(c);
					
					//push child on stack
					stack[top++] = c;
					stack[top++] = c.val;
				}
			}
			return root;
		}
		
		function serialize(n:Node):String
		{
			if (n.children != null)
				for (child in n.children)
					serialize(child);
			if (n.children != null) //skip leafs
				n.val = "{" + [for (child in n.children) '${child.key}:${child.val}'].join(",") + "}";
			return n.val;
		}
		
		var pos = Context.currentPos();
		
		function buildFields(n:Node):Array<Field>
		{
			if (n.children != null)
				for (child in n.children)
					buildFields(child);
			
			var p = n.parent;
			if (p != null)
			{
				if (n.a.length > 0)
				{
					var field:Field =
					{
						name: n.key,
						kind: FVar(TAnonymous(cast n.a)),
						pos: pos
					}
					p.a.push(field);
				}
				else
				{
					var name =
					switch (Type.typeof(n.val))
					{
						case ValueType.TInt: "Int";
						case ValueType.TFloat: "Float";
						case ValueType.TBool: "Bool";
						case ValueType.TClass(String): "String";
						case _: null;
					}
					var field =
					{
						name: n.key,
						kind: FVar(TPath({name: name, pack: []})),
						pos: pos
					}
					p.a.push(field);
				}
			}
			return cast n.a;
		}
		
		var fields = Context.getBuildFields();
		fields.push
		({
			name: "config",
			kind: FVar(
				TAnonymous(buildFields(getNodeTree(valStruct))),
				Context.parse(serialize(getNodeTree(rawStruct)), pos)
				),
			access: [AStatic, APublic],
			pos: pos
		});
		
		return fields;
	}
	
	static function parse(contents:String):Array<String>
	{
		var out = [];
		var s = new EReg("\r\n", "g").replace(contents, "\n");
		var lines = s.split("\n"), key, val, path;
		var matchLine = ~/(\S+)\s+(\S+)/;
		var matchComment = ~/^[\/#]/;
		for (line in lines)
		{
			if (matchComment.match(line)) continue;
			if (!matchLine.match(line)) continue;
			key = matchLine.matched(1);
			val = matchLine.matched(2);
			out.push(key);
			out.push(val);
		}
		return out;
	}
	
	static function getValue(s:String):Dynamic
	{
		var r;
		
		r = ~/^(["'])(.*?)\1$/;
		if (r.match(s)) return r.matched(2);
		
		r =  ~/^[-+]?[0-9]*\.[0-9]*$/;
		if (r.match(s)) return Std.parseFloat(s);
		
		r = ~/^[-+]?\d+$/;
		if (r.match(s)) return Std.parseInt(s);
		
		r = ~/^(true|false)$/;
		if (r.match(s)) return (s == "true" ? true : false);
		
		throw 'invalid value $s';
	}
	
	#if !macro
	public static function overwrite(contents:String, obj:Dynamic)
	{
		function insert(parent:Dynamic, key:String, val:Dynamic)
		{
			var tmp = key.split(".");
			var n = parent;
			for (i in 0...tmp.length - 1)
			{
				var t = Reflect.field(n, tmp[i]);
				assert(t != null);
				Reflect.setField(n, tmp[i], t);
				n = t;
			}
			Reflect.setField(n, tmp[tmp.length - 1], val);
		}
		
		var keyValuePairs = parse(contents);
		var i = 0;
		var k = keyValuePairs.length;
		while (i < k)
		{
			var key = keyValuePairs[i++];
			var val = getValue(keyValuePairs[i++]);
			insert(obj, key, val);
		}
	}
	#end
}