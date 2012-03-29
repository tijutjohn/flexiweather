package com.iblsoft.flexiweather.utils
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.core.UIComponent;
	
	import org.osmf.events.TimeEvent;

	public class AsyncManager extends UIComponent
	{
		private static var _counter: int = 0;
		
		private var _uid: int;
		
		private var _timer: Timer;
		private var _stack: Array;
		private var _presence: Dictionary;
		
		private var _maxCallsPerTick: int;
		
		
		public function AsyncManager()
		{
			_uid = _counter++;
			
			init();
		}
		
		private function init(): void
		{
			_stack = new Array();
			_presence = new Dictionary();
			_maxCallsPerTick = 120;
		}
		public function start(): void
		{
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
//			if (!_timer)
//			{
//				_timer = new Timer(70);
//				_timer.addEventListener(TimerEvent.TIMER, onTimerEvent);
//			}
//			if (!_timer.running)
//				_timer.start();
		}
		public function stop(): void
		{
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
//			if (!_timer)
//			{
//				_timer.stop();
//			}
		}
		
		private function onEnterFrame(event: Event): void
		{
			tick();
		}
		private function onTimerEvent(event: TimerEvent): void
		{
			tick();
		}
		
		protected function tick(): void
		{
			if (_stack.length == 0)
			{
				stop();
				return;
			}
			
			var total: int = Math.min(_stack.length, _maxCallsPerTick);
			trace("AsyncManager ["+_uid+"] onTimerEvent total: " + total + " / " + _stack.length);
			if (total > 0)
			{
				for (var i: int = 0; i < total; i++)
				{
					var obj: Object = _stack.shift();
					delete _presence[obj.obj];
					(obj.callback as Function).apply(null, obj.arguments);
				}
			}
		}
		public function addCall(obj: Object, callback: Function, arguments: Array): void
		{
			//TODO this is jut for testing, we need to be sure, that callback and arguments are always same
			if (!_presence[obj])
			{
				_presence[obj] = true;
				_stack.push({obj: obj, callback: callback, arguments: arguments});
			}
		}
	}
}