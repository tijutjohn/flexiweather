package com.iblsoft.flexiweather.net.events
{
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	[Event(name = DATA_LOADED, type = "com.iblsoft.flexiweather.net.events.UniURLLoaderEvent")]
	public class UniURLLoaderEvent extends Event
	{
		public static const RUN_STOPPED_REQUEST: String = "runStoppedRequest";
		public static const STOP_REQUEST: String = "stopRequest";
		public static const LOAD_STARTED: String = "loadStarted";
		public static const DATA_LOADED: String = "dataLoaded";
		protected var m_result: Object;
		protected var m_request: URLRequest;
		protected var m_loader: URLLoader;
		protected var m_associatedData: Object;

		public function UniURLLoaderEvent(
				type: String, result: Object, request: URLRequest, associatedData: Object,
				bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
			m_result = result;
			m_request = request;
			m_associatedData = associatedData;
		}

		public override function clone(): Event
		{
			return new UniURLLoaderEvent(type, m_result, m_request, m_associatedData, bubbles, cancelable);
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
