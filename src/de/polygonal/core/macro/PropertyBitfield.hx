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

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.Field;

class PropertyBitfield
{
	macro public static function build(e:Expr):Array<Field>
	{
		var pos = Context.currentPos();
		var names = [];
		
		try
		{
			switch (e.expr)
			{
				case EArrayDecl(a):
					for (b in a)
					{
						switch (b.expr)
						{
							case EConst(c):
								switch (c)
								{
									case CIdent(d):
										names.push(d);
									case _: throw 1;
								}
							case _: throw 1;
						}
					}
				case _: throw 1;
			}
		}
		catch(error:Dynamic)
		{
			Context.error("unsupported declaration", pos);
		}
		
		var fields = Context.getBuildFields();
		var bitfield = names.shift();
		
		function camelCaseToSnakeCase(value:String):String
			return ~/[A-Z]/g.map(value, function(r) return "_" + r.matched(0).toLowerCase());
		
		function createProperty(name:String, bit:Int)
		{
			//public var {name}(get, set):Bool;
			fields.push(
			{
				kind: FProp("get", "set", macro : Bool),
				meta: [],
				name: name,
				pos: pos,
				access: [APublic]
			});
			
			//inline function get_{name}():Bool return {bitfield} & {bit} > 0;
			fields.push(
			{
				kind: FFun({args: [],
					expr: macro { return $i{bitfield} & $v{bit} > 0; },
					params: [], ret: macro : Bool}),
				meta: [],
				name: "get_" + name,
				pos: pos,
				access: [AInline]
			});
			
			//inline function set_{name}(value:Bool):Bool { {bitfield} = value ? mFlags | {bit} : {bitfield} & ~{bit}; return value; }
			fields.push(
			{
				kind: FFun({args: [{meta: [], name: "value", type: macro : Bool, opt: false, value: null}],
					expr: macro { $i{bitfield} = $i{"value"} ? $i{bitfield} | $v{bit} : $i{bitfield} & ~$v{bit}; return $i{"value"}; },
					params: [], ret: macro : Bool}),
				meta: [],
				name: "set_" + name,
				pos: pos,
				access: [AInline]
			});
			
			fields.push
			({
				name: "FLAG_" + camelCaseToSnakeCase(name).toUpperCase(),
				doc: null,
				meta: [],
				access: [AStatic, APublic, AInline],
				kind: FVar(TPath( { pack: [], name: "Int", params: [], sub: null } ), macro $v{bit} ),
				pos: pos
			});
		}
		
		for (i in 0...names.length) createProperty(names[i], 1 << i);
		
		return fields;
	}
}