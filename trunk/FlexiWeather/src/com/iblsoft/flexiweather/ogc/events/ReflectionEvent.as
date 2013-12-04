package com.iblsoft.flexiweather.ogc.events
{
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;
	import flash.events.Event;

	public class ReflectionEvent extends Event
	{
		public static const ADD_REFLECTION: String = 'addReflection';
		public static const REMOVE_REFLECTION: String = 'removeReflection';
		public var reflection: ReflectionData;

		public function ReflectionEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}
