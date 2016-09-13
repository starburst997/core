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

/**
	Example:
	
	<pre>
	@:build(de.polygonal.core.macro.IntConsts.build([CONST_0, CONST_1, CONST_2], false, true))
	class MyClass {}
	</pre>
	
	Result:
	
	<pre>
	class MyClass
	{
	    public inline static var CONST_0:Int = 0;
	    public inline static var CONST_1:Int = 1;
	    public inline static var CONST_2:Int = 2;
	}
	</pre>
	
	Example:
	
	<pre>
	@:build(de.polygonal.core.macro.IntConsts.build([CONST_0, CONST_1, CONST_2], true, false))
	class MyClass {}
	</pre>
	
	Result:
	
	<pre>
	class MyClass
	{
	    inline static var CONST_0:Int = 0x01;
	    inline static var CONST_1:Int = 0x02;
	    inline static var CONST_2:Int = 0x04;
	}
	</pre>
**/
class IntConsts
{
	macro public static function build(e:Expr, bits:Bool, publicAccess:Bool):Array<Field>
	{
		var p = Context.currentPos();
		var fields = Context.getBuildFields();
		
		var next = 0;
		
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
									var i = next++;
									var val = bits ? (1 << i) : i;
									fields.push
									({
										name: d,
										doc: null,
										meta: [],
										access: [AStatic, publicAccess ? APublic : APrivate, AInline],
										kind: FVar(TPath( { pack: [], name: "Int", params: [], sub: null } ), { expr: EConst(CInt(Std.string(val))), pos: p } ),
										pos: p
									});
								case _: Context.error("unsupported declaration", p);
							}
						case _: Context.error("unsupported declaration", p);
					}
				}
			case _: Context.error("unsupported declaration", p);
		}
		
		fields.push
		({
			name: "NUM_CONSTS", doc: "The total number of generated constants.", meta: [], access: [APublic, AStatic, AInline], pos: p,
			kind: FVar(TPath( { pack: [], name: "Int", params: [], sub: null } ), { expr: EConst(CInt(Std.string(next))), pos: p } ),
		});
		
		return fields;
	}
}