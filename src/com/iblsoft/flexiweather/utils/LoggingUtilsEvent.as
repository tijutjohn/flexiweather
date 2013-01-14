package com.iblsoft.flexiweather.utils
{
	import flash.events.Event;
	
	public class LoggingUtilsEvent extends Event
	{
		public static const LOG_ENTRY: String = 'logEntry';
		
		public var message: String;
		
		public function LoggingUtilsEvent(type:String, message: String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			this.message = message;
		}
	}
}