package com.iblsoft.flexiweather.events
{
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.collections.ArrayCollection;

	public class InteractiveLayerEvent extends Event
	{
		public  static const FEATURE_INFO_RECEIVED: String = 'featureInfoReceived';
		public  static const FEATURES_LOADED: String = 'featuresLoaded';
		public  static const FEATURES_IMPORTED: String = 'featuresImported';
		public  static const VISIBILITY_CHANGED: String = 'visibilityChanged';
		public  static const VISIBILITY_EFFECT_FINISHED: String = 'visibilityEffectFinished';
		public  static const LAYER_ROLL_OVER: String = 'layerRollOver';
		public  static const LAYER_ROLL_OUT: String = 'layerRollOut';
		public  static const LEGENDS_AREA_UPDATED: String = 'legendsAreaUpdated';
		public  static const AREA_CHANGED: String = 'areaChangeds';
		
		public  static const LAYER_LOADIND_START: String = 'layerLoadingStart';
		public  static const LAYER_LOADED: String = 'layerLoaded';
		public  static const ALL_LAYERS_LOADED: String = 'allLayersLoaded';
		
		public var text: String;
		public var interactiveLayer: InteractiveLayer;
		public var point: Point;
		public var area: Rectangle;
		public var newFeaturesCount: int;
		public var newFeatures: ArrayCollection;
		
		public var topLeftCoord: Coord;
		public var bottomRightCoord: Coord;
		
		public var refreshFeaturesObject: Object;
		
		public function InteractiveLayerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}