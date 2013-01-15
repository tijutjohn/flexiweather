package com.iblsoft.flexiweather.utils
{
	import flash.events.EventDispatcher;
	
	import spark.components.TextArea;
	
	public class LoggingUtils
	{
		public function LoggingUtils()
		{
		}
		
		static public function dispatchLogEvent(dispatcher: EventDispatcher, message: String, bubbles: Boolean = false, cancelable: Boolean = false ): void
		{
			dispatcher.dispatchEvent(new LoggingUtilsEvent(LoggingUtilsEvent.LOG_ENTRY, message, bubbles, cancelable));
		}
		
		static public function logMessageIntoTextArea(textArea: TextArea, message: String): void
		{
			textArea.text = message + "\n" + textArea.text;
		}
	}
}