package com.iblsoft.flexiweather.widgets.basicauth.events
{
	import com.iblsoft.flexiweather.net.data.UniURLLoaderData;
	import flash.events.Event;

	public class BasicAuthEvent extends Event
	{
		public static const AUTHENTICATION_CANCELLED: String = 'authentication cancelled';
		public static const CREDENTIALS_READY: String = 'credentials ready';
		public var username: String;
		public var password: String;
		public var domain: String;
		public var realm: String;
		public var requestData: UniURLLoaderData;

		public function BasicAuthEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}
