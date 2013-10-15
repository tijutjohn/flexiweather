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
		public static const EMPTY: String = 'empty';
		private static var _counter: int = 0;
		private var _uid: int;
		private var _timer: Timer;
		protected var _stack: Array;
		protected var _presence: Dictionary;

		public function get notEmpty(): Boolean
		{
			if (_stack)
				return _stack.length > 0;
			return false;
		}
		private var _maxCallsPerTick: int;
		private var _maxFrameDuration: Number;

		public function get maxCallsPerTick(): int
		{
			return _maxCallsPerTick;
		}

		public function set maxCallsPerTick(value: int): void
		{
			_maxCallsPerTick = value;
		}
		/**
		 * You can store here any data, which you want to have after all task are done
		 */
		public var data: Object;

		public function AsyncManager(name: String)
		{
			_uid = _counter++;
			this.name = name;
			init();
		}

		public function cleanup(): void
		{
			stop();
			if (_stack && _stack.length > 0)
			{
				while (_stack.length > 0)
				{
					var obj: Object = _stack.shift();
					delete _presence[obj.obj];
					obj = null;
				}
			}
			_stack = null;
			if (_presence)
			{
				for (var str: String in _presence)
				{
					delete _presence[str];
				}
				_presence = null;
			}
		}

		private function init(): void
		{
			_stack = new Array();
			_presence = new Dictionary();
			_maxCallsPerTick = 120;
		}

		public function start(): void
		{
			if (!hasEventListener(Event.ENTER_FRAME))
				addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}

		public function stop(): void
		{
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		}

		private function onEnterFrame(event: Event): void
		{
			tick();
		}

		private function onTimerEvent(event: TimerEvent): void
		{
			tick();
		}

		protected function notifyEmpty(): void
		{
			dispatchEvent(new Event(EMPTY));
		}

		protected function tick(): void
		{
			if (_stack.length == 0)
			{
				stop();
				notifyEmpty();
				return;
			}
			var total: int = Math.min(_stack.length, _maxCallsPerTick);
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

		public function removeCall(obj: Object): void
		{
			if (_presence[obj])
			{
				var total: int = _stack.length;
				for (var i: int = 0; i < total; i++)
				{
					var stackObj: Object = _stack[i];
					if (stackObj.obj == obj)
					{
						_stack.splice(1, 0);
						delete _presence[obj];
						return;
					}
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
