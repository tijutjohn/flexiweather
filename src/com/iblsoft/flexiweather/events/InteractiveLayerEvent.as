package com.iblsoft.flexiweather.events
{
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	
	import flash.events.Event;
	import flash.geom.Point;

	public class InteractiveLayerEvent extends Event
	{
		public  static const FEATURE_INFO_RECEIVED: String = 'featureInfoReceived';
		public  static const VISIBILITY_CHANGED: String = 'visibilityChanged';
		public  static const LAYER_ROLL_OVER: String = 'layerRollOver';
		public  static const LAYER_ROLL_OUT: String = 'layerRollOut';
		
		public var text: String;
		public var interactiveLayer: InteractiveLayer;
		public var point: Point;
		
		public function InteractiveLayerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}