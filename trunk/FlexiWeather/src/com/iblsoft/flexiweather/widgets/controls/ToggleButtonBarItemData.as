package com.iblsoft.flexiweather.widgets.controls
{
	[Bindable]
	public class ToggleButtonBarItemData
	{
		public static const NORMAL: String = 'normal';
		public static const TOGGLE: String = 'toggle';
		public static const EXCLUSIVE: String = 'exclusive';
		
		public var ident: String;
		public var label: String;
		public var tooltip: String;
		
		private var _enabled: Boolean;
		public function get enabled():Boolean
		{
			return _enabled;
		}

		public function set enabled(value:Boolean):void
		{
			_enabled = value;
		}
		
		public var type: String;
		
//		public var toggle: Boolean;
//		public var exclusive: String;  
		public var iconToggle: Class;
		public var priority: int;
		
		private var _icon: Class;



		public function get icon():Class
		{
			return _icon;
		}

		public function set icon(value:Class):void
		{
			_icon = value;
		}

	}
}