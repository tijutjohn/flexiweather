package com.iblsoft.flexiweather.utils
{
	import flash.events.EventDispatcher;
	
	import mx.controls.TextArea;

	public class LoggingUtils
	{
		public function LoggingUtils()
		{
		}
		
		static public function dispatchLogEvent(dispatcher: EventDispatcher, message: String): void
		{
			dispatcher.dispatchEvent(new LoggingUtilsEvent(LoggingUtilsEvent.LOG_ENTRY, message, true));
		}
		
		static public function logMessageIntoTextArea(textArea: TextArea, message: String): void
		{
			textArea.text = message + "\n" + textArea.text;
		}
	}
}