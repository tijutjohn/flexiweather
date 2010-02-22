package com.iblsoft.flexiweather.utils
{
	import flash.events.Event;
	import flash.net.URLRequest;

	public class UniURLLoaderEvent extends Event
	{
		protected var m_result: Object;
		protected var m_request: URLRequest;

		public function UniURLLoaderEvent(
				type: String, result: Object, request: URLRequest,
				bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
			m_result = result;
			m_request = request;
		}
		
		public function get result(): Object
		{ return m_result; }

		public function get request(): Object
		{ return m_request; }
	}
}