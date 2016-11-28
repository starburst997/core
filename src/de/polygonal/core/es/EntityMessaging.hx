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
package de.polygonal.core.es;

import de.polygonal.core.util.Assert.assert;
import de.polygonal.core.es.Entity as E;
import de.polygonal.ds.ArrayList;
import de.polygonal.ds.tools.ObjectPool;
import haxe.Timer;

using de.polygonal.core.es.EntitySystem;
using de.polygonal.ds.tools.NativeArrayTools;

@:access(de.polygonal.core.es.EntitySystem)
@:access(de.polygonal.core.es.EntityMessage)
@:access(de.polygonal.core.es.Entity)
class EntityMessaging
{
	static var mMessageBuffer:EntityMessageBuffer = null;
	static var mLists:ObjectPool<ArrayList<Entity>>;
	
	static function init()
	{
		mMessageBuffer = new EntityMessageBuffer();
		mLists = new ObjectPool
		(
			function() return new ArrayList<Entity>(),
			function(x:ArrayList<Entity>) x.free(),
			1024
		);
	}
	
	public static inline function sendBufferedTo(sender:E, recipient:E, type:Int, ?data:{})
	{
		mMessageBuffer.sendTo(sender, recipient, type, data);
	}
	
	public static inline function sendBufferedToMultiple(sender:E, recipients:ArrayList<E>, type:Int, ?data:{})
	{
		mMessageBuffer.sendToMultiple(sender, recipients, type, data);
	}
	
	public static inline function sendBufferedToChildren(root:E, type:Int, ?data:{})
	{
		mMessageBuffer.sendToChildren(root, type, data);
	}
	
	public static inline function sendBufferedToDescedants(root:E, type:Int, ?data:{})
	{
		mMessageBuffer.sendToDescandants(root, type, data);
	}
	
	public static inline function sendBufferedToAncestors(root:E, type:Int, ?data:{})
	{
		mMessageBuffer.sendToAncestors(root, type, data);
	}
	
	public static inline function flushBuffer(?onFinish:Void->Void)
	{
		mMessageBuffer.flush(onFinish);
	}
	
	public static function sendTo(sender:E, recipient:E, type:Int, ?data:{})
	{
		assert(sender != null && recipient != null);
		if (sender.id == null || recipient.id == null) return;
		
		var message = EntityMessage.get(type, data, sender);
		recipient.onMessage(message);
		EntityMessage.put(message);
	}
	
	public static function sendToMultiple(sender:E, recipients:ArrayList<E>, type:Int, ?data:{})
	{
		var message = EntityMessage.get(type, data, sender);
		for (i in 0...recipients.size) recipients.get(i).onMessage(message);
		EntityMessage.put(message);
	}
	
	public static function sendToChildren(root:E, type:Int, ?data:{})
	{
		assert(root != null);
		
		if (root.id == null) return;
		var e = root.firstChild;
		if (e == null) return;
		
		var message = EntityMessage.get(type, data, root);
		var k = root.childCount;
		var l = mLists.get().reserve(k);
		var d = l.getData();
		var i;
		
		i = 0;
		while (i < k)
		{
			d.set(i, e);
			e = e.sibling;
			i++;
		}
		
		i = 0;
		while (i < k)
		{
			d.get(i).onMessage(message);
			d.set(i, null);
			i++;
			if (message.mFlags & EntityMessage.FLAG_STOP_PROPAGATION > 0)
			{
				while (i < k) d.set(i++, null);
				break;
			}
		}
		
		mLists.put(l);
		EntityMessage.put(message);
	}
	
	public static function sendToDescedants(root:E, type:Int, ?data:{})
	{
		assert(root != null);
		
		if (root.id == null) return;
		var e = root.firstChild;
		if (e == null) return;
		
		var message = EntityMessage.get(type, data, root);
		var k = root.getSize();
		var l = mLists.get().reserve(k);
		var d = l.getData();
		var i, j;
		var immediate;
		var b = [];
		
		i = 0;
		while (i < k)
		{
			d.set(i, e);
			b[i] = e.getSize();
			i++;
			e = e.next;
		}
		
		i = 0;
		while (i < k)
		{
			d.get(i).onMessage(message);
			d.set(i, null);
			i++;
			if (message.mFlags & EntityMessage.FLAG_STOP_PROPAGATION > 0)
			{
				immediate = message.mFlags & EntityMessage.FLAG_STOP_IMMEDIATE_PROPAGATION > 0;
				if (immediate)
				{
					while (i < k) d.set(i++, null);
					break;
				}
				j = i;
				i += b[i - 1];
				while (j < i) d.set(j++, null);
				continue;
			}
		}
		
		mLists.put(l);
		EntityMessage.put(message);
	}
	
	public static function sendToAncestors(root:E, type:Int, ?data:{})
	{
		assert(root != null);
		
		if (root.id == null) return;
		var e = root.parent;
		if (e == null) return;
		
		var message = EntityMessage.get(type, data, root);
		
		var k = root.getDepth();
		var l = mLists.get().reserve(k);
		var d = l.getData();
		var i;
		
		i = 0;
		while (i < k)
		{
			d.set(i, e);
			e = e.parent;
			i++;
		}
		
		i = 0;
		while (i < k)
		{
			d.get(i).onMessage(message);
			d.set(i, null);
			i++;
			if (message.mFlags & EntityMessage.FLAG_STOP_PROPAGATION > 0)
			{
				while (i < k) d.set(i++, null);
				break;
			}
		}
		
		mLists.put(l);
		EntityMessage.put(message);
	}
}