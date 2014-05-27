package com.iblsoft.flexiweather.widgets.controls
{
	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class ToggleButtonBarItemData extends EventDispatcher
	{
		public static const NORMAL: String = 'normal';
		public static const TOGGLE: String = 'toggle';
		public static const EXCLUSIVE: String = 'exclusive';
		
		[Bindable]
		public var ident: String;
		[Bindable]
		public var label: String;
		[Bindable]
		public var tooltip: String;
		
		private var _enabled: Boolean;
		[Bindable (event="enabledChanged")]
		public function get enabled():Boolean
		{
			return _enabled;
		}

		public function set enabled(value:Boolean):void
		{
			_enabled = value;
			notify("enabledChanged");
		}
		
		public var type: String;
		
//		public var toggle: Boolean;
//		public var exclusive: String;  
		public var iconToggle: Class;
		public var priority: int;
		
		private var _icon: Class;

		[Bindable (event="iconChanged")]
		public function get icon():Class
		{
			return _icon;
		}

		public function set icon(value:Class):void
		{
			_icon = value;
			notify("iconChanged");
		}
		
		private var _iconTest: Class;

		[Bindable (event="iconTestChanged")]
		public function get iconTest():Class
		{
			return _iconTest;
		}

		public function set iconTest(value:Class):void
		{
			_iconTest = value;
			notify("iconTestChanged");
		}
		
		private function notify(type:String): void
		{
			dispatchEvent(new Event(type));
		}

	}
}