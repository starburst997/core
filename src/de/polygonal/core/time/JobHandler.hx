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
package de.polygonal.core.time;

class JobHandler implements TimelineListener
{
	var mJob:Job;
	var mId:Int;
	
	public function new(job:Job = null)
	{
		mJob = job;
		mId = -1;
	}
	
	public function run(job:Job = null, duration:Float, delay = 0.):JobHandler
	{
		if (job != null) mJob = job;
		mId = Timeline.schedule(this, duration, delay);
		return this;
	}
	
	public function cancel()
	{
		if (mJob != null && mId != -1)
			Timeline.cancel(mId);
	}
	
	function onInstant(id:Int, iteration:Int)
	{
	}
	
	function onStart(id:Int, iteration:Int)
	{
		mJob.onStart();
	}
	
	function onProgress(alpha:Float)
	{
		mJob.onProgress(alpha);
	}
	
	function onFinish(id:Int, iteration:Int)
	{
		if (mJob != null)
		{
			mJob.onComplete();
			mJob = null;
		}
	}
	
	function onCancel(id:Int)
	{
		if (mJob != null)
		{
			mJob.onAbort();
			mJob = null;
		}
	}
}