package com.iblsoft.flexiweather.ogc
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;

	public class SchemaParserDataItemAttribute extends EventDispatcher
	{
		public static const USE_OPTIONAL: String = 'optional';
		public static const USE_REQUIRED: String = 'required';
		public var name: String;
		public var type: String;
		public var use_val: String;
		public var default_val: Object;
		public var fixed: Object;

		public function SchemaParserDataItemAttribute()
		{
		}
	}
}
