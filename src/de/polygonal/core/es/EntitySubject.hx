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
import de.polygonal.ds.ArrayList;
import de.polygonal.ds.IntIntHashTable;
import de.polygonal.ds.NativeArray;
import de.polygonal.ds.tools.ObjectPool;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	An entity that can take the part of a subject in the observer pattern
	
	Observers are updated by sending messages to them.
**/
class EntitySubject extends Entity
{
	static var _recipients:ObjectPool<ArrayList<Entity>> = null;
	static var _count = 0;
	
	var mObserverTable:NativeArray<ArrayList<EntityId>>;
	var mStatus:IntIntHashTable;
	var mRecipients:ArrayList<Entity>;
	
	public function new(name:String = null, isGlobal:Null<Bool> = false)
	{
		super(name, isGlobal);
		
		mObserverTable = NativeArrayTools.alloc(EntityMessage.MAX_ID + 1).init(null);
		mObserverTable.set(0, new ArrayList(4));
		mStatus = new IntIntHashTable(1024);
		mRecipients = new ArrayList(16);
		
		if (_recipients == null)
			_recipients = new ObjectPool(function() return new ArrayList<Entity>());
		_count++;
	}
	
	override public function free()
	{
		for (i in mObserverTable) i.free();
		mObserverTable.nullify();
		mObserverTable = null;
		mStatus.free();
		mStatus = null;
		mRecipients.free();
		mRecipients = null;
		
		if (--_count == 0)
		{
			_recipients.free();
			_recipients = null;
		}
		
		super.free();
	}
	
	public function subscribe(entity:Entity, ?messages:Array<Int>, message = -1):Bool
	{
		#if debug
		if (messages == null && message >= 0)
			assert(EntityMessage.isValid(message), "unknown message type");
		#end
		
		if (entity.id == null) return false;
		
		var id = entity.id;
		
		if (messages != null)
		{
			//invoke subscribe() for all given types, generic type (-1) is not allowed
			var success = true;
			for (i in messages)
			{
				assert(i >= 0);
				success = success && subscribe(entity, null, i);
			}
			return success;
		}
		
		function add()
		{
			var list = mObserverTable.get(message + 1);
			if (list == null)
			{
				list = new ArrayList(4);
				mObserverTable.set(message + 1, list);
			}
			list.pushBack(id);
		}
		
		var inner = id.inner;
		
		var status = mStatus;
		if (status.hasKey(inner)) //subscription exists?
		{
			if (status.get(inner) < 0) //subscribed to all types?
			{
				if (message < 0) return false; //no change, quit
				
				//shift from generic list to specific list
				mObserverTable.get(0).remove(id);
				add();
				status.remap(inner, message);
				return true;
			}
			else
			{
				//must exist in specific list
				if (message < 0)
				{
					//shift from specific list(s) to generic list
					for (i in mObserverTable) if (i != null) i.remove(id);
					while (status.unset(inner)) {}
				}
				else
				{
					//add to another targeted list
					var list = mObserverTable.get(message + 1);
					if (list != null && list.contains(id)) return false; //no change
				}
				
				add();
				status.set(inner, message);
			}
		}
		else
		{
			//subscribe for the first time
			status.set(inner, message);
			add();
		}
		return true;
	}
	
	public function unsubscribe(entity:Entity, ?messages:Array<Int>, message = -1):Bool
	{
		#if debug
		if (messages == null && message >= 0)
			assert(EntityMessage.isValid(message), "unknown message type");
		#end
		
		if (entity.id == null) return false;
		
		var status = mStatus;
		
		var id = entity.id;
		var inner = id.inner;
		
		if (!status.hasKey(inner)) return false; //subscription exists?
		
		if (messages != null)
		{
			//invoke unsubscribe() for all given types
			var success = true;
			for (i in messages)
			{
				assert(i != -1);
				success = success && unsubscribe(entity, i);
			}
			return success;
		}
		
		if (status.hasPair(inner, -1)) //subscribed to all types?
		{
			if (message >= 0)
			{
				//if subscribed to all types, can't unsubscribe from specific type
				return false;
			}
			
			//remove from generic list
			mObserverTable.get(0).remove(id);
			status.unset(inner);
			return true;
		}
		
		//remove from specific list(s)
		var success = false;
		if (message < 0)
		{
			var inner = id.inner;
			var type = status.get(inner);
			while (type != IntIntHashTable.KEY_ABSENT)
			{
				if (status.unset(inner))
				{
					mObserverTable.get(type + 1).remove(id);
					success = true;
				}
				type = status.get(inner);
			}
		}
		else
		{
			var list = mObserverTable.get(message + 1);
			if (list != null)
			{
				status.unsetPair(inner, message);
				success = list.remove(id);
			}
		}
		return success;
	}
	
	@:access(de.polygonal.core.es.EntityMessage)
	public function notify(type:Int, ?data:{}, buffered = false)
	{
		assert(id != null);
		
		if (mStatus.isEmpty()) return;
		
		var list = collectRecipients(type);
		
		if (buffered)
			EntityMessaging.sendBufferedToMultiple(this, list, type, data);
		else
		{
			var message = EntityMessage.get(type, data, this), entity;
			for (i in 0...list.size)
			{
				entity = list.get(i);
				if (entity.id != null) entity.onMessage(message);
			}
			EntityMessage.put(message);
		}
		
		list.clear(true);
		_recipients.put(list);
	}
	
	public function clearSubscribers()
	{
		mStatus.clear();
		for (i in mObserverTable)
			if (i != null) i.clear(true);
		mObserverTable.nullify(1);
	}
	
	public function hasSubscribers(message:Int):Bool
	{
		var table = mObserverTable, ids;
		
		ids = table.get(0);
		if (ids.size > 0) return true;
		
		ids = table.get(message + 1);
		return ids != null && ids.size > 0;
	}
	
	public function addCallback(message:Int, func:Void->Void)
	{
		new MessageCallback(this, message, func);
	}
	
	@:access(de.polygonal.core.es.EntitySystem)
	function collectRecipients(message:Int):ArrayList<Entity>
	{
		#if debug
		assert(message != -1);
		assert(EntityMessage.isValid(message), "unknown message type");
		#end
		
		var a = mObserverTable.get(0);
		var b = mObserverTable.get(message + 1);
		
		var k = a.size + (b != null ? b.size : 0);
		
		var output = _recipients.get();
		output.reserve(k);
		
		var list = EntitySystem._freeList, id:EntityId;
		
		var i = 0;
		var k = a.size;
		while (i < k)
		{
			id = a.get(i);
			if (id.inner >= 0)
			{
				output.unsafePushBack(list.get(id.index));
				i++;
				continue;
			}
			
			//remove invalid observer from generic list
			a.swapPop(i); k--;
			mStatus.unset(id.inner & ~0x80000000);
			mObserverTable.get(0).remove(id);
		}
		
		if (b == null) return output;
		
		i = 0;
		k = b.size;
		while (i < k)
		{
			id = b.get(i);
			if (id.inner >= 0)
			{
				output.unsafePushBack(list.get(id.index));
				i++;
				continue;
			}
			
			//remove invalid observer from all specific types
			b.swapPop(i); k--;
			var inner = id.inner & ~0x80000000;
			for (i in mObserverTable) if (i != null) i.remove(id);
			while (mStatus.unset(inner)) {}
		}
		
		return output;
	}
}

private class MessageCallback extends Entity
{
	var mFunc:Void->Void;
	
	public function new(subject:EntitySubject, message:Int, func:Void->Void)
	{
		super();
		subject.subscribe(this, message);
		mFunc = func;
	}
	
	override function onMessage(message:EntityMessage)
	{
		mFunc();
		mFunc = null;
		message.sender.as(EntitySubject).unsubscribe(this);
		free();
	}
}