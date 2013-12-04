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
		public static const LAYER_INITIALIZED: String = 'layerInitialized';
		public static const FEATURES_LOADED: String = 'featuresLoaded';
		public static const FEATURES_IMPORTED: String = 'featuresImported';
		public static const ALPHA_CHANGED: String = 'alphaChanged';
		public static const VISIBILITY_CHANGED: String = 'visibilityChanged';
		public static const VISIBILITY_EFFECT_FINISHED: String = 'visibilityEffectFinished';
		public static const LAYER_ROLL_OVER: String = 'layerRollOver';
		public static const LAYER_ROLL_OUT: String = 'layerRollOut';
		public static const LEGENDS_AREA_UPDATED: String = 'legendsAreaUpdated';
		public static const AREA_CHANGED: String = 'areaChanged';
		
		public static const INVALIDATE_DYNAMIC_PART: String = 'invalidateDynamicPart';
		
		public var text: String;
		public var interactiveLayer: InteractiveLayer;
		public var point: Point;
		public var area: Rectangle;
		public var newFeaturesCount: int;
		public var newFeatures: ArrayCollection;
		public var topLeftCoord: Coord;
		public var bottomRightCoord: Coord;
		public var refreshFeaturesObject: Object;
		public var data: Object;

		public function InteractiveLayerEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone(): Event
		{
			var ile: InteractiveLayerEvent = new InteractiveLayerEvent(type, bubbles, cancelable);
			ile.text = text;
			ile.interactiveLayer = interactiveLayer;
			ile.point = point;
			ile.area = area;
			ile.newFeaturesCount = newFeaturesCount;
			ile.newFeatures = newFeatures;
			ile.topLeftCoord = topLeftCoord;
			ile.bottomRightCoord = bottomRightCoord;
			ile.refreshFeaturesObject = refreshFeaturesObject;
			ile.data = data;
			
			return ile;
		}
	}
}
