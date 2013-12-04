package com.iblsoft.flexiweather.utils
{
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import spark.components.TextArea;
	import spark.formatters.DateTimeFormatter;
	
	public class LoggingUtils extends EventDispatcher
	{
		private var _listeners: Dictionary;
		private var _errorListeners: Dictionary;
		
		private static var _instance: LoggingUtils;
		
		public static function get instance(): LoggingUtils
		{
			if (!_instance)
			{
				_instance = new LoggingUtils();
			}
				
			return _instance;
		}
		public function LoggingUtils()
		{
			_listeners = new Dictionary();
			_errorListeners = new Dictionary();
		}
		
		public function addErrorLogEntryListener(dispatcher: EventDispatcher): void
		{
			if (!hasLogEntryListener(dispatcher))
			{
				_errorListeners[dispatcher] = dispatcher;
				dispatcher.addEventListener(LoggingUtilsErrorEvent.ERROR_LOG_ENTRY, redispatchErrorEvent);
			}
			
		}
		public function addLogEntryListener(dispatcher: EventDispatcher): void
		{
			if (!hasLogEntryListener(dispatcher))
			{
				_listeners[dispatcher] = dispatcher;
				dispatcher.addEventListener(LoggingUtilsEvent.LOG_ENTRY, redispatchEvent);
			}
		}
		
		private function redispatchErrorEvent(event: LoggingUtilsErrorEvent): void
		{
			dispatchEvent(event);	
		}
		private function redispatchEvent(event: LoggingUtilsEvent): void
		{
			dispatchEvent(event);	
		}
		
		public function hasErrorLogEntryListener(dispatcher: EventDispatcher): Boolean
		{
			if (_errorListeners[dispatcher])
			{
				var ed: EventDispatcher = _errorListeners[dispatcher] as EventDispatcher;
				if (ed && ed.hasEventListener(LoggingUtilsErrorEvent.ERROR_LOG_ENTRY))
					return true;
			}
			return false;
		}
		public function hasLogEntryListener(dispatcher: EventDispatcher): Boolean
		{
			if (_listeners[dispatcher])
			{
				var ed: EventDispatcher = _listeners[dispatcher] as EventDispatcher;
				if (ed && ed.hasEventListener(LoggingUtilsEvent.LOG_ENTRY))
					return true;
			}
			return false;
		}
		
		static public function dispatchErrorEvent(dispatcher: EventDispatcher, errorObject: Object, message: String, bubbles: Boolean = false, cancelable: Boolean = false ): void
		{
			
			var _logUtilsSingleton: LoggingUtils = LoggingUtils.instance;
			
			//listen to this dispatcher log entry event to redispatch them
			_logUtilsSingleton.addErrorLogEntryListener(dispatcher);
			
			dispatcher.dispatchEvent(new LoggingUtilsErrorEvent(LoggingUtilsErrorEvent.ERROR_LOG_ENTRY, errorObject, message, bubbles, cancelable));
		}
		
		static public function dispatchLogEvent(dispatcher: EventDispatcher, message: String, bubbles: Boolean = false, cancelable: Boolean = false ): void
		{
			var _logUtilsSingleton: LoggingUtils = LoggingUtils.instance;
			
			//listen to this dispatcher log entry event to redispatch them
			_logUtilsSingleton.addLogEntryListener(dispatcher);
			
			dispatcher.dispatchEvent(new LoggingUtilsEvent(LoggingUtilsEvent.LOG_ENTRY, message, bubbles, cancelable));
		}
		
		static public function getTimestamp(): String
		{
			var time: Date = new Date();
			var formatter: DateTimeFormatter = new DateTimeFormatter();
			formatter.dateTimePattern = "[HH:mm:ss] ";
			var formattedTime: String = formatter.format(time);
			
			return formattedTime;
			
		}
		static public function logMessageIntoTextArea(textArea: TextArea, message: String): void
		{
			
			textArea.text = getTimestamp() + message + "\n" + textArea.text;
		}
	}
}