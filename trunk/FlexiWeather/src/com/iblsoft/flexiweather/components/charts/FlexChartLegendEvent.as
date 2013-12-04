package com.iblsoft.flexiweather.components.charts
{
	import flash.events.Event;
	
	public class FlexChartLegendEvent extends Event
	{
		public static const SERIE_VISIBILITY_CHANGE: String = 'serieVisibilityChange';
		
		public var serie: ChartSerie;
		public var visibility: Boolean;
		
		public function FlexChartLegendEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			var e: FlexChartLegendEvent = new FlexChartLegendEvent(type, bubbles, cancelable);
			e.serie = serie;
			e.visibility = visibility;
			
			return e;
		}
	}
}