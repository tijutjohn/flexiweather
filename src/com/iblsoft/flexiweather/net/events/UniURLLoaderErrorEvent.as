package com.iblsoft.flexiweather.net.events
{
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	[Event(name = DATA_LOAD_FAILED, type = "com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent")]
	public class UniURLLoaderErrorEvent extends Event
	{
		public static const DATA_LOAD_FAILED: String = "dataLoadFailed";
		public static const ERROR_BAD_IMAGE: String = "errorBadImage";
		public static const ERROR_IO: String = "errorIO";
		/**
		 * result is received but format is not included in allowedFormats array
		 */
		public static const ERROR_UNEXPECTED_FORMAT: String = "errorUnexpectedFormat";
		/**
		 * result is received, and format is allowed, but content is invalid (not as expected)
		 */
		public static const ERROR_INVALID_CONTENT: String = "errorInvalidConter";
		public static const ERROR_SECURITY: String = "errorSecurity";
		public static const ERROR_CANCELLED: String = "errorCancelled";
		protected var m_result: Object;
		protected var m_request: URLRequest;
		protected var m_loader: URLLoader;
		protected var m_associatedData: Object;
		protected var m_errorString: String;
		protected var m_errorID: int;

		public function UniURLLoaderErrorEvent(
				type: String, result: Object, request: URLRequest, associatedData: Object, errorString: String = null, errorID: int = -1,
				bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
			m_result = result;
			m_request = request;
			m_associatedData = associatedData;
			m_errorString = errorString;
			m_errorID = errorID;
		}

		public override function clone(): Event
		{
			return new UniURLLoaderErrorEvent(type, m_result, m_request, m_associatedData, m_errorString, m_errorID, bubbles, cancelable);
		}

		public function get errorString(): String
		{
			return m_errorString;
		}

		public function get errorID(): int
		{
			return m_errorID;
		}

		public function get result(): Object
		{
			return m_result;
		}

		public function get request(): URLRequest
		{
			return m_request;
		}

		public function get associatedData(): Object
		{
			return m_associatedData;
		}
	}
}
