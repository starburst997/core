/*
Copyright (c) 2012-2014 Michael Baczynski, http://www.polygonal.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ALL KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ALL CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package de.polygonal.core.es;

import de.polygonal.core.math.Mathematics;
import de.polygonal.core.util.Assert.assert;
import de.polygonal.ds.ArrayList;
import de.polygonal.ds.IntHashTable;
import de.polygonal.ds.IntIntHashTable;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	An entity that can take the part of a subject in the observer pattern
	
	Observers are updated by sending messages to them.
**/
class ObservableEntity extends Entity
{
	inline static var ALL = -1;
	
	var mObserverTable:IntHashTable<ArrayList<EntityId>>;
	var mState:IntIntHashTable;
	var mRecipients:ArrayList<Entity>;
	
	public function new(name:String = null, isGlobal:Null<Bool> = false)
	{
		super(name, isGlobal);
		
		mObserverTable = new IntHashTable(Mathematics.nextPow2(EntityMessage.MAX_ID));
		mObserverTable.set(ALL, new ArrayList(4));
		mState = new IntIntHashTable(1024);
		mRecipients = new ArrayList(16);
	}
	
	override public function free()
	{
		super.free();
		
		mState.free();
		mState = null;
		
		for (i in mObserverTable) i.free();
		mObserverTable.free();
		mObserverTable = null;
		mRecipients.free();
		mRecipients = null;
	}
	
	public function attach(entity:Entity, ?msgTypes:Array<Int>, msgType:Int = ALL):Bool
	{
		#if debug
		if (msgTypes == null && msgType != ALL)
			assert(EntityMessage.isValid(msgType), "unknown message type");
		#end
		
		var id = entity.id;
		if (id == null) return false; //invalid entity, quit
		assert(id.inner >= 0);
		
		if (msgTypes != null)
		{
			//invoke attach() for all given message types
			var success = true;
			for (i in msgTypes)
			{
				assert(i != -1);
				success = success && attach(entity, null, i);
			}
			return success;
		}
		
		inline function add()
		{
			#if (debug && verbose)
			if (msgType == ALL)
				L.d('Entity $entity is now attached to $this');
			else
				L.d('Entity $entity is now attached to $this:${EntityMessage.resolveName(msgType)}');
			#end
			
			var list = mObserverTable.get(msgType);
			if (list == null)
			{
				list = new ArrayList(4);
				mObserverTable.set(msgType, list);
			}
			list.pushBack(id);
		}
		
		var s = mState;
		if (s.hasKey(id.inner)) //entity exists?
		{
			if (s.get(id.inner) == ALL) //exists in untargeted list
			{
				if (msgType == ALL) return false; //no change
				
				//shift from untargeted to targeted list
				mObserverTable.get(ALL).remove(id);
				add();
				s.remap(id.inner, msgType);
				return true;
			}
			else
			{
				if (msgType == ALL) //exists in targeted list
				{
					//shift from targeted list(s) to untargeted list
					for (i in mObserverTable) i.remove(id);
					while (s.unset(id.inner)) {}
				}
				else
				{
					//add to another targeted list
					var list = mObserverTable.get(msgType);
					if (list != null && list.contains(id)) return false; //no change
				}
				
				add();
				s.set(id.inner, msgType);
			}
		}
		else
		{
			//attach for the first time
			s.set(id.inner, msgType);
			add();
		}
		return true;
	}
	
	public function detach(entity:Entity, ?msgTypes:Array<Int>, msgType:Int = ALL):Bool
	{
		#if debug
		if (msgTypes == null && msgType != ALL)
			assert(EntityMessage.isValid(msgType), "unknown message type");
		#end
		
		var id = entity.id;
		if (id == null) return false; //stalled entity; removed when calling dispatch(), clearObservers() or free()
		assert(id.inner >= 0);
		
		var s = mState;
		if (!s.hasKey(id.inner)) return false; //not attached
		
		if (msgTypes != null)
		{
			var success = true;
			for (i in msgTypes)
			{
				assert(i != ALL);
				success = success && detach(entity, i);
			}
			return success;
		}
		
		if (s.hasPair(id.inner, ALL))
		{
			//remove from wild card list
			mObserverTable.get(ALL).remove(id);
			s.unset(id.inner);
			
			#if verbose
			L.d('Entity $entity is now detached from $this');
			#end
			return true;
		}
		
		//remove from targeted lists
		var success = false;
		if (msgType == ALL)
		{
			var key = s.get(id.inner);
			while (key != IntIntHashTable.KEY_ABSENT)
			{
				if (s.unset(id.inner))
				{
					#if (debug && verbose)
					L.d('Entity $entity is now detached from $this:${EntityMessage.resolveName(key)}');
					#end
					mObserverTable.get(key).remove(id);
					success = true;
				}
				key = s.get(id.inner);
			}
		}
		else
		{
			var list = mObserverTable.get(msgType);
			if (list != null)
			{
				#if (debug && verbose)
				L.d('Entity $entity is now detached from $this:${EntityMessage.resolveName(msgType)}');
				#end
				s.unsetPair(id.inner, msgType);
				success = list.remove(id);
			}
		}
		return success;
	}
	
	@:access(de.polygonal.core.es.EntityMessageQue)
	@:access(de.polygonal.core.es.EntitySystem)
	public function dispatch(msgType:Int, dispatch = true)
	{
		#if debug
		assert(msgType != ALL);
		assert(EntityMessage.isValid(msgType), "unknown message type");
		#end
		
		var a = mObserverTable.get(ALL);
		var b = mObserverTable.get(msgType);
		
		var k = a.size + (b != null ? b.size : 0);
		if (k == 0) return;
		
		var r = mRecipients;
		r.clear();
		r.reserve(k);
		
		var q = EntitySystem._messageQueue, entities = EntitySystem._freeList, id:EntityId, e;
		for (i in 0...a.size)
		{
			id = a.get(i);
			e = entities.get(id.index);
			if (id.inner < 0 || e == null || id.inner != e.id.inner)
			{
				a.remove(id);
				mState.unset(id.inner);
			}
			else
				r.unsafePushBack(e);
		}
		
		if (b != null)
		{
			for (i in 0...b.size)
			{
				id = b.get(i);
				e = entities.get(id.index);
				if (id.inner < 0 || e == null || id.inner != e.id.inner)
				{
					for (i in mObserverTable) i.remove(id);
					while (mState.unset(id.inner)) {}
				}
				else
					r.unsafePushBack(e);
			}
		}
		
		k = r.size;
		for (i in 0...r.size) q.enqueue(this, r.get(i), msgType, --k, 0);
		if (dispatch) EntitySystem.dispatchMessages();
	}
	
	public function clearObservers()
	{
		mState.clear();
		for (i in mObserverTable) i.clear(true);
		mObserverTable.clear();
	}
	
	public function hasObservers(msgType:Int):Bool
	{
		return mObserverTable.hasKey(msgType);
	}
}