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
package de.polygonal.core.es;

import haxe.macro.Context;
import haxe.macro.Expr;

/**
	Helper macro generating unique message ids
	
	Example:
	
	<pre>
	@:build(de.polygonal.core.es.EntityMessageMacro.build([MSG1, MSG2]))
	class MyMessages {}<br/>
	@:build(de.polygonal.core.es.EntityMessageMacro.build([MSG1, MSG2, MSG3]))
	class MyOtherMessages {}
	</pre>
	
	Result:
	
	<pre>
	class MyMessages
	{
	    public inline static var MSG1:Int = 0;
	    public inline static var MSG2:Int = 1;
	}
	
	class MyOtherMessages
	{
	    public inline static var MSG1:Int = 32;
	    public inline static var MSG2:Int = 33;
	    public inline static var MSG3:Int = 34;
	}
	</pre>
**/
class EntityMessageMacro
{
	#if macro
	static var _indexLut = new Array<String>();
	static var _countLut = new Array<Int>();
	static var _maxId = 0;
	#end
	
	macro static function build(e:Expr):Array<Field>
	{
		var p = Context.currentPos();
		var fields = Context.getBuildFields();
		
		var cl = Context.getLocalClass().get();
		var module = cl.module;
		var name = cl.name;
		
		var index = -1;
		for (i in 0..._indexLut.length)
		{
			if (_indexLut[i] == module + name)
			{
				index = i;
				break;
			}
		}
		if (index < 0)
		{
			_indexLut.push(module + name);
			_countLut.push(0);
			index = (_indexLut.length - 1);
		}
		
		var meta = [];
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
									var i = (index << 5) + next;
									if (i > 0x7FFF) Context.fatalError("message id out of range [0,0x7FFF]", p);
									if (next == 32) Context.fatalError("message count out of range [0,32]", p);
									next++;
									
									if (i > _maxId) _maxId = i;
									meta.push({id: i, name: d});
									
									fields.push
									({
										name: d,
										doc: 'A global unique id that identifies messages of type $d.',
										meta: [],
										access: [AStatic, APublic, AInline],
										kind: FVar(TPath({pack: [], name: "Int", params: [], sub: null}), {expr: EConst(CInt(Std.string(i))), pos: p}),
										pos: p
									});
								case _: Context.error("unsupported declaration", p);
							}
						case _: Context.error("unsupported declaration", p);
					}
				}
			case _: Context.error("unsupported declaration", p);
		}
		
		_countLut[index] = next;
		
		#if debug
		//add meta for resolving message names at run time
		var resolveName =
		if (cl.pack.length > 0)
			cl.pack.join(".") + "." + name;
		else
		{
			if (module != name)
				name
			else
				module;
		}
		
		switch (Context.getModule("de.polygonal.core.es.EntityMessage")[0])
		{
			case TInst(t, params):
				var ct = t.get();
				if (ct.meta.has(resolveName)) ct.meta.remove(resolveName);
				ct.meta.add(resolveName,
				[
					{expr: EArrayDecl([for (i in meta) {expr: EConst(CInt(Std.string(i.id))), pos: p}]), pos: p},
					{expr: EArrayDecl([for (i in meta) {expr: EConst(CString(i.name)), pos: p}]), pos: p}
				], p);
			case _:
		}
		#end
		
		var totalCount = 0;
		for (i in _countLut) totalCount += i;
		
		//just report total message count
		Context.onGenerate(
			function(_)
			{
				var module = "de.polygonal.core.es.EntityMessage";
				switch (Context.getModule(module)[0])
				{
					case TInst(t, params):
						var ct = t.get();
						if (ct.meta.has(module)) ct.meta.remove(module);
						ct.meta.add(module,
						[
							{expr: EConst(CString(Std.string(totalCount))), pos: p},
							{expr: EConst(CString(Std.string(_maxId))), pos: p},
						], p);
					case _:
				}
			});
		return fields;
	}
}