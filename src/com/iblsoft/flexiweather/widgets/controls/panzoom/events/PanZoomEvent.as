package com.iblsoft.flexiweather.widgets.controls.panzoom.events
{
	import flash.events.Event;
	
	/**
	 * An event specific to the PanZoomComponent
	 * 
	 */
	public class PanZoomEvent extends Event
	{
		
		/**
		 * Event relevant to zooming
		 */
		public static const ZOOM:String = "zoom";
		/**
		 * Event relevant to panning
		 */
		public static const PAN:String = "pan";
		/**
		 * Content redrawn
		 */
		public static const CONTENT_REDRAWN:String = "contentRedrawn";
		
		public static const SLIDER_CHANGED:String = "sliderChanged";
		
		/**
		 * Constructor
		 * 
		 */
		public function PanZoomEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}