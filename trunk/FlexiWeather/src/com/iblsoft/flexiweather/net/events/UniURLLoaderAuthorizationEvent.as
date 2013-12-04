package com.iblsoft.flexiweather.net.events
{
	import flash.events.Event;

	[Event(name = AUTHORIZATION_FAILED, type = "com.iblsoft.flexiweather.net.events.UniURLLoaderEvent")]
	public class UniURLLoaderAuthorizationEvent extends Event
	{
		public static const AUTHORIZATION_FAILED: String = "authorizationFailed";

		public function UniURLLoaderAuthorizationEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}
