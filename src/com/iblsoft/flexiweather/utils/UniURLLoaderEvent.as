package com.iblsoft.flexiweather.utils
{
	import flash.events.Event;
	import flash.net.URLRequest;

	public class UniURLLoaderEvent extends Event
	{
		protected var m_result: Object;
		protected var m_request: URLRequest;
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
			return new UniURLLoaderEvent(type, m_result, m_request, bubbles, cancelable);
		}
		
		public function get result(): Object
		{ return m_result; }

		public function get request(): URLRequest
		{ return m_request; }
		
		public function get associatedData(): Object
		{ return m_associatedData; }
	}
}