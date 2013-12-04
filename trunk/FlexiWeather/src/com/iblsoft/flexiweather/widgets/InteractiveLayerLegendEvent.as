package com.iblsoft.flexiweather.widgets
{
	import flash.events.Event;
	
	import spark.components.Group;
	
	public class InteractiveLayerLegendEvent extends Event
	{
		public static const LEGEND_CLICK: String = 'legendClicked';
		public static const LEGEND_ROLLOVER: String = 'legendRollover';
		public static const LEGEND_ROLLOUT: String = 'legendRollout';
		
		public var legend: InteractiveLayerLegendImage;
		public var legendGroup: InteractiveLayerLegendGroup;
		
		public function InteractiveLayerLegendEvent(type:String, legend: InteractiveLayerLegendImage, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			this.legend = legend;
		}
		
		override public function clone(): Event
		{
			var e: InteractiveLayerLegendEvent = new InteractiveLayerLegendEvent(type, legend, bubbles, cancelable);
			return e;
		}
	}
}