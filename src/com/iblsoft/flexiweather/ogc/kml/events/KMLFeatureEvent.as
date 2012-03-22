package com.iblsoft.flexiweather.ogc.kml.events
{
	import com.iblsoft.flexiweather.ogc.kml.features.KMLFeature;
	
	import flash.events.Event;
	
	public class KMLFeatureEvent extends Event
	{
		public static const KML_FEATURE_CLICK: String = 'kmlFeatureClick';
		public static const KML_FEATURE_ROLL_OVER: String = 'kmlFeatureRollOver';
		public static const KML_FEATURE_ROLL_OUT: String = 'kmlFeatureRollOut';
		
		public static const KML_FEATURE_POSITION_CHANGE: String = 'kmlFeaturePositionChange';
		public static const KML_FEATURE_VISIBILITY_CHANGE: String = 'kmlFeatureVisibilityChange';
		
		public var kmlFeature: KMLFeature;
		
		public function KMLFeatureEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}