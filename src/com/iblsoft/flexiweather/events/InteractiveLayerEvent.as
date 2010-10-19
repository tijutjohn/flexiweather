package com.iblsoft.flexiweather.events
{
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class InteractiveLayerEvent extends Event
	{
		public  static const FEATURE_INFO_RECEIVED: String = 'featureInfoReceived';
		public  static const FEATURES_IMPORTED: String = 'featuresImported';
		public  static const VISIBILITY_CHANGED: String = 'visibilityChanged';
		public  static const VISIBILITY_EFFECT_FINISHED: String = 'visibilityEffectFinished';
		public  static const LAYER_ROLL_OVER: String = 'layerRollOver';
		public  static const LAYER_ROLL_OUT: String = 'layerRollOut';
		public  static const LEGENDS_AREA_UPDATED: String = 'legendsAreaUpdated';
		
		public var text: String;
		public var interactiveLayer: InteractiveLayer;
		public var point: Point;
		public var area: Rectangle;
		public var newFeaturesCount: int;
		
		public function InteractiveLayerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}