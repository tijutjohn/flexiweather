package com.iblsoft.flexiweather.events
{
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	
	import flash.events.Event;

	public class WFSEvent extends Event
	{
		public static const FEATURE_CREATED: String = 'featureCreated';
		public static const FEATURE_REMOVED: String = 'featureRemoved';
		public static const FEATURE_EDITED: String = 'featureEdited';
		
		public var feature: WFSFeatureEditable;
		
		public function WFSEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}