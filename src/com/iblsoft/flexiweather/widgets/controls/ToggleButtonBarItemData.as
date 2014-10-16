package com.iblsoft.flexiweather.widgets.controls
{
	import flash.events.Event;
	import flash.events.EventDispatcher;

	[Event(name="change", type="flash.events.Event")]
	public class ToggleButtonBarItemData extends EventDispatcher
	{
		public static const NORMAL: String = 'normal';
		public static const TOGGLE: String = 'toggle';
		public static const EXCLUSIVE: String = 'exclusive';

		private var m_ident: String;
		private var m_label: String;
		private var m_tooltip: String;

		private var _enabled: Boolean;

		[Bindable]
		public function get ident():String
		{
			return m_ident;
		}

		public function set ident(value:String):void
		{
			m_ident = value;
			notifyChange();
		}

		[Bindable]
		public function get label():String
		{
			return m_label;
		}

		public function set label(value:String):void
		{
			m_label = value;
			notifyChange();
		}

		[Bindable]
		public function get tooltip():String
		{
			return m_tooltip;
		}

		public function set tooltip(value:String):void
		{
			m_tooltip = value;
			notifyChange();
		}

		[Bindable (event="enabledChanged")]
		public function get enabled():Boolean
		{
			return _enabled;
		}

		public function set enabled(value:Boolean):void
		{
			_enabled = value;
			notify("enabledChanged");
			notifyChange();
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
			notifyChange();
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
			notifyChange();
		}

		private function notifyChange(): void
		{
			notify(Event.CHANGE);
		}
		private function notify(type:String): void
		{
			dispatchEvent(new Event(type));
		}

		public function ToggleButtonBarItemData()
		{
		}

	}
}