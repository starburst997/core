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

import de.polygonal.core.math.Mathematics.M;
import de.polygonal.core.util.Assert.assert;
import de.polygonal.ds.BucketList;
import de.polygonal.ds.IntIntHashTable;
import de.polygonal.ds.Vector;

/**
	An entity that can take the part of a subject in the observer pattern
	
	Observers are updated by sending messages to them.
**/
class ObservableEntity extends Entity
{
	var mBuckets:BucketList<EntityId>;
	var mStatus:IntIntHashTable;
	var mTypeCount:Vector<Int>;
	var mTmpArray1 = new Array<EntityId>();
	var mTmpArray2 = new Array<Entity>();
	
	public function new(name:String = null, isGlobal:Null<Bool> = false, bucketSize = 4, shrink = true)
	{
		super(name, isGlobal);
		
		var k = EntityMessage.countTotalMessages() + 1; //use zero index to store observers attached to all types
		mBuckets = new BucketList<EntityId>(M.max(k, 2), bucketSize, shrink);
		mStatus = new IntIntHashTable(1024, k * 100);
		
		mTypeCount = new Vector<Int>(k);
		for (i in 0...k) mTypeCount[i] = 0;
	}
	
	override public function free()
	{
		super.free();
		
		mBuckets.free();
		mStatus.free();
		
		mBuckets = null;
		mStatus = null;
		mTypeCount = null;
		mTmpArray1 = null;
		mTmpArray2 = null;
	}
	
	public function clearObservers()
	{
		mBuckets.clear();
		mStatus.clear(true);
		
		for (i in 0...mTypeCount.length) mTypeCount[i] = 0;
	}
	
	public function attach(e:Entity, ?msgTypes:Array<Int>, msgType:Int = -1):Bool
	{
		assert(msgType < EntityMessage.countTotalMessages());
		
		var id = e.id;
		if (id == null) return false; //invalid entity (freed)
		
		assert(id.inner >= 0);
		
		if (msgTypes != null)
		{
			var success = true;
			for (i in msgTypes)
			{
				assert(i != -1);
				success = success && attach(e, null, i);
			}
			
			return success;
		}
		
		//an entity can be stored in the global list or the local list, but not in both simultaneously.
		if (mStatus.hasKey(id.inner)) //is entity attached?
		{
			if (mStatus.hasPair(id.inner, -1)) //stored in global list?
			{
				if (msgType == -1) return false; //no change
				
				//global list -> local list
				mBuckets.removeAt(0, id);
				mBuckets.add(msgType + 1, id);
				
				mStatus.clrPair(id.inner, -1); 
				mStatus.set(id.inner, msgType);
				
				decCount(-1);
				incCount(msgType);
				
				return true;
			}
			else
			{
				if (msgType == -1) //local list(s) -> global list?
				{
					var success1 = false;
					for (i in 1...mBuckets.numBuckets)
					{
						if (mBuckets.removeAt(i, id))
						{
							success1 = true;
							decCount(i - 1);
						}
					}
					
					incCount(-1);
					
					while (mStatus.clr(id.inner)) {}
					
					mBuckets.add(0, id);
					mStatus.set(id.inner, -1);
					
					return true;
				}
				else
				{
					if (mBuckets.exists(msgType + 1, id)) return false; //no change
					
					//add to another local list
					mBuckets.add(msgType + 1, id);
					mStatus.set(id.inner, msgType);
					incCount(msgType);
				}
			}
		}
		else
		{
			//added for the first time
			assert(!mStatus.hasKey(id.inner)); //id must not have a status yet
			assert(!mBuckets.contains(id)); //id must not be contained in bucket list
			
			mBuckets.add(msgType + 1, id);
			mStatus.set(id.inner, msgType);
			incCount(msgType);
		}
		
		return true;
	}
	
	public function detach(e:Entity, ?msgTypes:Array<Int>, msgType:Int = -1):Bool
	{
		var id = e.id;
		if (id == null) return false; //invalid entity (freed)
		
		assert(id.inner >= 0);
		
		if (msgTypes != null)
		{
			var success = true;
			for (i in msgTypes)
			{
				assert(i != -1);
				
				success = success && detach(e, i);
			}
			return success;
		}
		
		//check if e is attached
		
		var has1 = mStatus.hasKey(id.inner);
		
		if (!has1) return false; //quit: not attached
		
		if (mStatus.hasPair(id.inner, -1)) //stored in global list?
		{
			mBuckets.removeAt(0, id);
			mStatus.clr(id.inner);
			decCount(-1);
			
			return true;
		}
		else
		{
			//must be in local list
			if (msgType == -1)
			{
				//remove from all local lists
				var t = mStatus.get(id.inner);
				while (t != IntIntHashTable.KEY_ABSENT)
				{
					if (mStatus.clr(id.inner)) decCount(t);
					
					mBuckets.removeAt(t + 1, id);
					
					t = mStatus.get(id.inner);
				}
				
				assert(!mStatus.hasKey(id.inner));
			}
			else
			{
				var success = mBuckets.removeAt(msgType + 1, id);
				if (mStatus.clrPair(id.inner, msgType)) decCount(msgType);
				
				return success;
			}
			
			return true;
		}
	}
	
	public function hasObservers(msgType:Int):Bool
	{
		return getCount(msgType) > 0;
	}
	
	@:access(de.polygonal.core.es.EntityMessageQue)
	@:access(de.polygonal.core.es.EntitySystem)
	public function dispatch(msgType:Int, dispatch = true)
	{
		if (getCount(msgType) == 0) return; //early out: no observers
		
		var a = mTmpArray1;
		var b = mTmpArray2;
		var q = Entity.getMsgQue();
		var entities = EntitySystem.mFreeList;
		
		var k = 0;
		k += mBuckets.getBucketData(msgType + 1, a, 0);
		k += mBuckets.getBucketData(0, a, k);
		
		var e:Entity, id:EntityId;
		var n = k;
		var j = 0;
		var i = 0;
		
		inline function removeAll(id:EntityId)
		{
			while (mStatus.clr(id.inner)) {}
			
			for (i in 0...mBuckets.numBuckets)
			{
				if (mBuckets.removeAt(i, id))
					decCount(i - 1);
			}
		}
		
		//remove invalid/obsolete entities
		while (i < n)
		{
			id = a[i++];
			
			e = entities[id.index];
			
			if (id.inner & 0x80000000 != 0 || id.inner != e.id.inner)
			{
				removeAll(id);
				k--;
				continue;
			}
			
			b[j++] = e;
		}
		
		//enqueue
		n = k;
		i = 0;
		while (i < n) q.enqueue(this, b[i++], msgType, --k, 0);
		
		if (dispatch) EntitySystem.dispatchMessages();
	}
	
	inline function getCount(msgType:Int):Int return mTypeCount[0] + mTypeCount[msgType + 1];
	
	inline function incCount(msgType:Int) mTypeCount.set(msgType + 1, mTypeCount.get(msgType + 1) + 1);
	
	inline function decCount(msgType:Int) mTypeCount.set(msgType + 1, mTypeCount.get(msgType + 1) - 1);
}