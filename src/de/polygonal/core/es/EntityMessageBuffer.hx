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

import de.polygonal.core.es.Entity;
import de.polygonal.core.util.Assert.assert;
import de.polygonal.ds.ArrayList;
import de.polygonal.ds.ArrayedQueue;
import de.polygonal.ds.NativeArray;
import de.polygonal.ds.tools.NativeArrayTools;

import de.polygonal.core.es.Entity as E;

using de.polygonal.ds.tools.NativeArrayTools;
using de.polygonal.core.es.EntitySystem;

/**
	A messaging system used by the entity system
**/
@:access(de.polygonal.core.es.Entity)
@:access(de.polygonal.core.es.EntityMessage)
@:access(de.polygonal.core.es.EntitySystem)
class EntityMessageBuffer
{
	inline static var MAX_BUFFER_SIZE = 0x8000;
	inline static var MSG_SIZE = 8;
	inline static var MSG_SIZE_SHIFT = 3;
	inline static var MSG_STUB = -1;
	
	inline static var POS_SENDER_INDEX = 0;
	inline static var POS_SENDER_INNER = 1;
	inline static var POS_RECIPIENT_INDEX = 2;
	inline static var POS_RECIPIENT_INNER = 3;
	inline static var POS_SUBTREE_SIZE = 4;
	inline static var POS_MSG_TYPE = 5;
	inline static var POS_MSG_DATA = 6;
	
	var mQue:NativeArray<Int>;
	var mSize = 0;
	var mFront = 0;
	var mBatchQue:ArrayedQueue<Int>;
	var mData:NativeArray<Dynamic>;
	var mNextDataIndex = 0;
	var mFlushing = false;
	var mCallbacks:Array<Void->Void>;
	var mCallbacksCount = 0;
	
	public function new()
	{
		mQue = NativeArrayTools.alloc(MAX_BUFFER_SIZE * MSG_SIZE);
		mQue.init(0);
		mBatchQue = new ArrayedQueue<Int>(MAX_BUFFER_SIZE);
		mData = NativeArrayTools.alloc(MAX_BUFFER_SIZE);
		mData.init(null);
		mCallbacks = new Array<Void->Void>();
	}
	
	public function free()
	{
		mQue = null;
		
		mBatchQue.free();
		mBatchQue = null;
		
		mData.nullify();
		mData = null;
		
		mCallbacks = null;
	}
	
	public function sendToMultiple(sender:E, recipients:ArrayList<Entity>, type:Int, ?data:Dynamic)
	{
		assert(sender != null);
		assert(type >= 0 && type <= EntityMessage.MAX_ID);
		assert(mSize + recipients.size < MAX_BUFFER_SIZE, "message queue exhausted");
		
		if (sender.id == null) return;
		
		var senderIndex = sender.id.index;
		var senderInner = sender.id.inner;
		var dataIndex = getDataIndex(data);
		
		var k = recipients.size;
		mBatchQue.unsafeEnqueue(k);
		
		var i = 0, q = mQue, f = mFront + mSize, p, recipient;
		while (i < k)
		{
			recipient = recipients.get(i++);
			
			p = (f++ & (MAX_BUFFER_SIZE - 1)) << MSG_SIZE_SHIFT;
			
			q.set(p + POS_SENDER_INDEX, senderIndex);
			q.set(p + POS_SENDER_INNER, senderInner);
			q.set(p + POS_RECIPIENT_INDEX, recipient.id.index);
			q.set(p + POS_RECIPIENT_INNER, recipient.id.inner);
			q.set(p + POS_SUBTREE_SIZE, recipient.getSize());
			q.set(p + POS_MSG_TYPE, type);
			q.set(p + POS_MSG_DATA, dataIndex);
		}
		mSize += k;
	}
	
	public function sendTo(sender:E, recipient:E, type:Int, ?data:Dynamic)
	{
		assert(sender != null);
		assert(recipient != null);
		
		if (sender.id == null) return;
		if (recipient.id == null || recipient.mBits & E.BIT_FREED > 0) return; 
		
		mBatchQue.unsafeEnqueue(1);
		
		var dataIndex = getDataIndex(data);
		var q = mQue, p = ((mFront + mSize++) & (MAX_BUFFER_SIZE - 1)) << MSG_SIZE_SHIFT;
		
		q.set(p + POS_SENDER_INDEX, sender.id.index);
		q.set(p + POS_SENDER_INNER, sender.id.inner);
		q.set(p + POS_RECIPIENT_INDEX, recipient.id.index);
		q.set(p + POS_RECIPIENT_INNER, recipient.id.inner);
		q.set(p + POS_SUBTREE_SIZE, 0);
		q.set(p + POS_MSG_TYPE, type);
		q.set(p + POS_MSG_DATA, dataIndex);
	}
	
	public function sendToChildren(sender:E, type:Int, ?data:Dynamic)
	{
		assert(sender != null);
		assert(type >= 0 && type <= EntityMessage.MAX_ID);
		
		if (sender.id == null) return;
		var recipient = sender.firstChild;
		if (recipient == null || recipient.id == null) return;
		
		var senderIndex = sender.id.index;
		var senderInner = sender.id.inner;
		
		var dataIndex = getDataIndex(data);
		
		assert(mSize + sender.childCount < MAX_BUFFER_SIZE, "message queue exhausted");
		
		var k = sender.childCount;
		mBatchQue.unsafeEnqueue(k);
		var i = 0, q = mQue, f = mFront + mSize, p;
		while (i++ < k)
		{
			p = (f++ & (MAX_BUFFER_SIZE - 1)) << MSG_SIZE_SHIFT;
			
			q.set(p + POS_SENDER_INDEX, senderIndex);
			q.set(p + POS_SENDER_INNER, senderInner);
			q.set(p + POS_RECIPIENT_INDEX, recipient.id.index);
			q.set(p + POS_RECIPIENT_INNER, recipient.id.inner);
			q.set(p + POS_SUBTREE_SIZE, recipient.getSize());
			q.set(p + POS_MSG_TYPE, type);
			q.set(p + POS_MSG_DATA, dataIndex);
			
			recipient = recipient.sibling;
		}
		
		mSize += k;
	}
	
	public function sendToDescandants(sender:E, type:Int, ?data:Dynamic)
	{
		assert(sender != null);
		assert(type >= 0 && type <= EntityMessage.MAX_ID);
		
		if (sender.id == null) return;
		var recipient = sender.firstChild;
		if (recipient == null || recipient.id == null) return;
		
		var senderIndex = sender.id.index;
		var senderInner = sender.id.inner;
		
		var dataIndex = getDataIndex(data);
		
		assert(mSize + sender.getSize() < MAX_BUFFER_SIZE, "message queue exhausted");
		
		var k = sender.getSize();
		mBatchQue.unsafeEnqueue(k);
		var i = 0, q = mQue, f = mFront + mSize, p;
		while (i++ < k)
		{
			p = (f++ & (MAX_BUFFER_SIZE - 1)) << MSG_SIZE_SHIFT;
			
			q.set(p + POS_SENDER_INDEX, senderIndex);
			q.set(p + POS_SENDER_INNER, senderInner);
			q.set(p + POS_RECIPIENT_INDEX, recipient.id.index);
			q.set(p + POS_RECIPIENT_INNER, recipient.id.inner);
			q.set(p + POS_SUBTREE_SIZE, recipient.getSize());
			q.set(p + POS_MSG_TYPE, type);
			q.set(p + POS_MSG_DATA, dataIndex);
			
			recipient = recipient.next;
		}
		
		mSize += k;
	}
	
	public function sendToAncestors(sender:E, type:Int, ?data:Dynamic)
	{
		assert(sender != null);
		assert(type >= 0 && type <= EntityMessage.MAX_ID);
		
		if (sender.id == null) return;
		var recipient = sender.parent;
		if (recipient == null || recipient.id == null) return;
		
		var senderIndex = sender.id.index;
		var senderInner = sender.id.inner;
		
		var dataIndex = getDataIndex(data);
		
		assert(mSize + sender.getDepth() < MAX_BUFFER_SIZE, "message queue exhausted");
		
		var k = sender.getDepth();
		mBatchQue.unsafeEnqueue(k);
		var i = 0, q = mQue, f = mFront + mSize, p;
		while (i++ < k)
		{
			p = (f++ & (MAX_BUFFER_SIZE - 1)) << MSG_SIZE_SHIFT;
			
			q.set(p + POS_SENDER_INDEX, senderIndex);
			q.set(p + POS_SENDER_INNER, senderInner);
			q.set(p + POS_RECIPIENT_INDEX, recipient.id.index);
			q.set(p + POS_RECIPIENT_INNER, recipient.id.inner);
			q.set(p + POS_SUBTREE_SIZE, recipient.getSize());
			q.set(p + POS_MSG_TYPE, type);
			q.set(p + POS_MSG_DATA, dataIndex);
			
			recipient = recipient.parent;
		}
		
		mSize += k;
	}
	
	public function flush(?onFinish:Void->Void)
	{
		if (mSize == 0)
		{
			for (i in 0...mCallbacksCount)
			{
				mCallbacks[i]();
				mCallbacks[i] = null;
			}
			mCallbacksCount = 0;
			if (onFinish != null) onFinish();
			return;
		}
		
		if (onFinish != null) mCallbacks[mCallbacksCount++] = onFinish;
		
		if (mFlushing) return;
		mFlushing = true;
		
		var a = EntitySystem._freeList, q = mQue, i, pos, batchSize, skipCount, immediate;
		
		var sender:Entity, recipient:Entity, message = EntityMessage.get(-1, null, null);
		
		inline function dequeue(n)
		{
			mFront = (mFront + n) & (MAX_BUFFER_SIZE - 1);
			mSize -= n;
		}
		inline function get(offset) return q.get(pos + offset);
		inline function getEntity(index) return a.get(get(index));
		
		while (mSize > 0)
		{
			pos = mFront << MSG_SIZE_SHIFT;
			
			batchSize = mBatchQue.dequeue();
			if (batchSize > 1)
			{
				sender = getEntity(POS_SENDER_INDEX);
				if (sender == null || sender.id.inner != get(POS_SENDER_INNER))
				{
					//discard entire batch
					dequeue(batchSize);
					continue;
				}
				
				//set once and use for all recipients
				message.type = get(POS_MSG_TYPE);
				message.data = mData.get(get(POS_MSG_DATA));
				message.sender = sender;
				
				while (batchSize > 0)
				{
					dequeue(1); //always dequeue before calling notify() because nothing prevents recipients for sending messages in onMessage()
					
					recipient = getEntity(POS_RECIPIENT_INDEX);
					if (recipient == null || recipient.id.inner != get(POS_RECIPIENT_INNER))
					{
						pos += MSG_SIZE;
						batchSize--;
						continue;
					}
					
					recipient.onMessage(message);
					
					//stop propagation?
					if (message.mFlags & EntityMessage.FLAG_STOP_PROPAGATION > 0)
					{
						var immediate = message.mFlags & EntityMessage.FLAG_STOP_IMMEDIATE_PROPAGATION > 0;
						message.mFlags = 0;
						
						if (immediate)
						{
							//skip entire batch
							dequeue(batchSize);
							break;
						}
						else
						{
							//skip all descendants
							skipCount = get(POS_SUBTREE_SIZE);
							dequeue(skipCount);
							pos += skipCount * MSG_SIZE;
							batchSize -= skipCount;
						}
					}
					
					pos += MSG_SIZE;
					batchSize--;
				}
			}
			else
			{
				dequeue(1);
				
				sender = getEntity(POS_SENDER_INDEX);
				if (sender == null || sender.id.inner != get(POS_SENDER_INNER)) continue;
				
				recipient = getEntity(POS_RECIPIENT_INDEX);
				if (recipient == null || recipient.id.inner != get(POS_RECIPIENT_INNER)) continue;
				
				message.sender = sender;
				message.type = get(POS_MSG_TYPE);
				message.data = mData.get(get(POS_MSG_DATA));
				
				recipient.onMessage(message);
			}
		}
		
		for (i in 0...mNextDataIndex) mData.set(i, null);
		mNextDataIndex = 0;
		
		EntityMessage.put(message);
		
		mFlushing = false;
		
		for (i in 0...mCallbacksCount)
		{
			mCallbacks[i]();
			mCallbacks[i] = null;
		}
		mCallbacksCount = 0;
	}
	
	inline function getDataIndex(data:Dynamic)
	{
		return
		if (data != null)
		{
			var i = mNextDataIndex++;
			mData.set(i, data);
			i;
		}
		else
			-1;
	}
}