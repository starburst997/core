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

import de.polygonal.core.fmt.StringUtil;
import de.polygonal.core.util.Assert.assert;
import de.polygonal.Printf;
import de.polygonal.core.util.ClassTools;
import de.polygonal.ds.ArrayList;
import de.polygonal.ds.NativeArray;
import de.polygonal.ds.tools.NativeArrayTools;
import de.polygonal.core.es.Entity in E;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	A messaging system used by the entity system
**/
@:access(de.polygonal.core.es.Entity)
@:access(de.polygonal.core.es.EntitySystem)
class EntityMessageQue
{
	inline static var MAX_BUFFER_SIZE = 0x8000;
	inline static var MSG_STUB = -1;
	inline static var MSG_SIZE = 8;
	inline static var POS_SENDER_INDEX = 0;
	inline static var POS_SENDER_INNER = 1;
	inline static var POS_RECIPIENT_INDEX = 2;
	inline static var POS_RECIPIENT_INNER = 3;
	inline static var POS_MSG_INDEX = 4;
	inline static var POS_MSG_TYPE = 5;
	inline static var POS_SKIP_DIR = 6;
	inline static var POS_SKIP_COUNT = 7;
	
	var mQue:NativeArray<Int>;
	var mMessages:NativeArray<EntityMessage>;
	var mBufferSize:Int;
	var mFront:Int;
	var mMessageIndex:Int;
	var mSending:Bool;
	var mCurrentIncomingMessageIndex:Int;
	var mCurrentOutgoingMessage:EntityMessage;
	
	public function new()
	{
		mQue = NativeArrayTools.alloc(MAX_BUFFER_SIZE * MSG_SIZE);
		mQue.init(0);
		mMessages = NativeArrayTools.alloc(MAX_BUFFER_SIZE);
		mMessages.init(null);
		mBufferSize = 0;
		mFront = 0;
		mMessageIndex = 0;
		mSending = false;
	}
	
	function getIncomingMessage():EntityMessage
	{
		return mCurrentIncomingMessageIndex < 0 ? null : mMessages.get(mCurrentIncomingMessageIndex);
	}
	
	function getOutgoingMessage():EntityMessage
	{
		var o = mMessages.get(mMessageIndex);
		if (o == null)
		{
			o = new EntityMessage(mMessageIndex);
			mMessages.set(mMessageIndex, o);
		}
		mCurrentOutgoingMessage = o;
		return o;
	}
	
	function enqueue(sender:E, recipient:E, type:Int, remaining:Int, direction:Int)
	{
		//direction: 0=direct, 1=descendants 2=ancestors
		assert(sender != null && recipient != null);
		assert(type >= 0 && type <= 0xFFFF);
		assert(mBufferSize < MAX_BUFFER_SIZE, "message queue exhausted");
		
		#if (debug && verbose == "extra")
		var senderName = sender.name;
		if (senderName == null) senderName = ClassTools.getUnqualifiedClassName(sender);
		if (senderName.length > 30) senderName = StringUtil.ellipsis(senderName, 30, 1, true);
		var recipientName = recipient.name;
		if (recipientName == null) recipientName = ClassTools.getUnqualifiedClassName(recipient);
		if (recipientName.length > 30) recipientName = StringUtil.ellipsis(recipientName, 30, 1, true);
		var messageName = EntityMessage.resolveName(type);
		if (messageName.length > 20) messageName = StringUtil.ellipsis(messageName, 20, 1, true);
		L.d(Printf.format('<- [%30s] -> [%-30s]: [%-20s] (remaining: $remaining)', [senderName, recipientName, messageName]), "es", null);
		#end
		
		var i = (mFront + mBufferSize++) % MAX_BUFFER_SIZE;
		var p = i * MSG_SIZE;
		var q = mQue;
		
		if (recipient.mBits & (E.BIT_SKIP_MSG | E.BIT_FREED) > 0)
		{
			//enqueue message even if recipient won't receive it;
			//required for properly stopping a message propagation (when an entity calls stop())
			mQue.set(p, MSG_STUB);
			return;
		}
		
		q.set(p + POS_SENDER_INDEX, sender.id.index);
		q.set(p + POS_SENDER_INNER, sender.id.inner);
		q.set(p + POS_RECIPIENT_INDEX, recipient.id.index);
		q.set(p + POS_RECIPIENT_INNER, recipient.id.inner);
		q.set(p + POS_MSG_INDEX, mMessageIndex);
		q.set(p + POS_MSG_TYPE, type);
		q.set(p + POS_SKIP_DIR, direction);
		q.set(p + POS_SKIP_COUNT, remaining);
		
		//use single message instance for multiple recipients
		if (remaining > 0) return;
		if (mCurrentOutgoingMessage != null)
		{
			mCurrentOutgoingMessage = null;
			mMessageIndex++; 
		}
	}
	function flush()
	{
		if (mBufferSize == 0 || mSending) return;
		mSending = true;
		
		var a = EntitySystem._freeList, q = mQue, p, sender, recipient;
		
		inline function get(i) return q.get(p + i);
		inline function getEntity(i) return a.get(get(i));
		inline function dequeue(n)
		{
			mFront = (mFront + n) % MAX_BUFFER_SIZE;
			mBufferSize -= n;
		}
		
		while (mBufferSize > 0)
		{
			p = mFront * MSG_SIZE;
			dequeue(1);
			
			if (get(POS_SENDER_INDEX) == MSG_STUB) continue;
			
			sender = getEntity(POS_SENDER_INDEX);
			if (sender == null || sender.id.inner != get(POS_SENDER_INNER))
			{
				L.w("Discard message: sender lost");
				continue;
			}
			
			recipient = getEntity(POS_RECIPIENT_INDEX);
			if (recipient == null || recipient.id.inner != get(POS_RECIPIENT_INNER))
			{
				L.w("Discard message: recipient lost");
				continue;
			}
			
			#if (debug && verbose == "extra")
			var senderId = sender.name == null ? Std.string(sender.id) : sender.name;
			if (senderId.length > 30) senderId = StringUtil.ellipsis(senderId, 30, 1, true);
			var recipientId = recipient.name == null ? Std.string(recipient.id) : recipient.name;
			if (recipientId.length > 30) recipientId = StringUtil.ellipsis(recipientId, 30, 1, true);
			var msgName = EntityMessage.resolveName(get(POS_MSG_TYPE));
			if (msgName.length > 20) msgName = StringUtil.ellipsis(msgName, 20, 1, true);
			L.d(Printf.format('-> [%30s] -> [%-30s]: [%-20s] (remaining: %d)', [senderId, recipientId, msgName, q.get(p + POS_SKIP_COUNT)]), "es", null);
			#end
			
			if (recipient.mBits & E.BIT_SKIP_MSG > 0) continue;
			
			mCurrentIncomingMessageIndex = get(POS_MSG_INDEX);
			recipient.onMsg(get(POS_MSG_TYPE), sender);
			
			if (recipient.mBits & E.BIT_STOP_PROPAGATION > 0)
			{
				recipient.mBits &= ~E.BIT_STOP_PROPAGATION;
				
				var direction = get(POS_SKIP_DIR);
				var skip =
				if (direction > 0)
					EntitySystem.getSize(recipient); //skip subtree rooted at the *recipient*, not the sender
				else
					get(POS_SKIP_COUNT);
				
				dequeue(skip); //skip remaining messages
				
				#if (verbose == "extra")
				if (direction > 0)
					L.d('Stop message propagation to descendants at entity "${recipient.name}" (skipping $skip messages)', "es");
				else
				if (direction < 0)
					L.d('Stop message propagation to ancestors at entity "${recipient.name}" (skipping $skip messages)', "es");
				#end
			}
		}
		
		for (i in 0...mMessageIndex) mMessages.get(i).data = null;
		mMessageIndex = 0;
		mCurrentIncomingMessageIndex = -1;
		mSending = false;
	}
	
	function discardMessage()
	{
		if (mCurrentOutgoingMessage != null)
		{
			mCurrentOutgoingMessage.data = null;
			mCurrentOutgoingMessage = null;
		}
	}
}