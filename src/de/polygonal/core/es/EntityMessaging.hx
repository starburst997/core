package de.polygonal.core.es;

import de.polygonal.core.util.Assert.assert;
import de.polygonal.core.es.Entity as E;
import de.polygonal.ds.ArrayList;
import de.polygonal.ds.tools.ObjectPool;
import haxe.Timer;

using de.polygonal.core.es.EntitySystem;

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
	
	public static inline function sendBufferedToChildren(root:E, type:Int, ?data:Dynamic)
	{
		mMessageBuffer.sendToChildren(root, type, data);
	}
	
	public static inline function sendBufferedToDescedants(root:E, type:Int, ?data:Dynamic)
	{
		mMessageBuffer.sendToDescandants(root, type, data);
	}
	
	public static inline function sendBufferedToAncestors(root:E, type:Int, ?data:Dynamic)
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
	
	/*public static function sendToMany(sender:E, recipients:ArrayList<E>, type:Int, ?data:{})
	{
		var m = mMessage;
		m.type = type; m.data = data; m.sender = sender;
		
		for (i in 0...recipients.size)
		{
			
		}
	}*/
	
	public static function sendToChildren(root:E, type:Int, ?data:Dynamic)
	{
		assert(root != null);
		
		if (root.id == null) return;
		var e = root.firstChild;
		if (e == null) return;
		
		var message = EntityMessage.get(type, data, root);
		
		var k = root.childCount;
		var a = createList();
		var i = 0;
		while (i < k)
		{
			a[i++] = e;
			e = e.sibling;
		}
		
		i = 0;
		while (i < k)
		{
			a[i++].onMessage(message);
			if (message.mFlags & EntityMessage.FLAG_STOP_PROPAGATION > 0)
			{
				message.mFlags = 0;
				break;
			}
		}
		
		EntityMessage.put(message);
	}
	
	public static function sendToDescedants(root:E, type:Int, ?data:Dynamic)
	{
		assert(root != null);
		
		if (root.id == null) return;
		var e = root.firstChild;
		if (e == null) return;
		
		var message = EntityMessage.get(type, data, root);
		
		var k = root.getSize();
		var a = createList();
		var b = [];
		var i = 0;
		while (i < k)
		{
			a[i] = e;
			b[i] = e.getSize();
			i++;
			e = e.next;
		}
		
		i = 0;
		while (i < k)
		{
			a[i++].onMessage(message);
			if (message.mFlags & EntityMessage.FLAG_STOP_PROPAGATION > 0)
			{
				var immediate = message.mFlags & EntityMessage.FLAG_STOP_IMMEDIATE_PROPAGATION > 0;
				message.mFlags = 0;
				if (immediate) break;
				i += b[i - 1];
				continue;
			}
		}
		
		EntityMessage.put(message);
	}
	
	public static function sendToAncestors(root:E, type:Int, ?data:Dynamic)
	{
		assert(root != null);
		
		if (root.id == null) return;
		var e = root.parent;
		if (e == null) return;
		
		var message = EntityMessage.get(type, data, root);
		
		/*while (e != null)
		{
			e.onMessage(message);
			if (message.mFlags & EntityMessage.FLAG_STOP_PROPAGATION > 0)
			{
				message.mFlags = 0;
				break;
			}
			e = e.parent;
		}*/
		
		var k = root.getDepth();
		var a = createList();
		var i = 0;
		while (i < k)
		{
			a[i++] = e;
			e = e.parent;
		}
		i = 0;
		while (i < k)
		{
			e = a[i++];
			e.onMessage(message);
			if (message.mFlags & EntityMessage.FLAG_STOP_PROPAGATION > 0)
			{
				message.mFlags = 0;
				break;
			}
		}
		
		EntityMessage.put(message);
	}
	
	static function createList():Array<Entity>
	{
		//trace('create list ');
		
		return [];
	}
}