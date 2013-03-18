package com.iblsoft.flexiweather.utils
{
	import flash.events.Event;
	
	public class LoggingUtilsErrorEvent extends Event
	{
		public static const ERROR_LOG_ENTRY: String = 'errorLogEntry';
		
		public var errorObject: Object;
		public var message: String;
		
		public function LoggingUtilsErrorEvent(type:String, errorObject: Object, message: String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			this.errorObject = errorObject;
			this.message = message;
		}
		
		override public function clone(): Event
		{
			return new LoggingUtilsErrorEvent(type, errorObject, message, bubbles, cancelable);
		}
	}
}