package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerQTTMS;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWMS;
	import com.iblsoft.flexiweather.ogc.WMSLayerConfiguration;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	public class InteractiveLayerWMSWithQTT extends InteractiveLayerWMS
	{
		private var tiledLayer: InteractiveLayerQTTMS;
		
		public function InteractiveLayerWMSWithQTT(container:InteractiveWidget, cfg:WMSLayerConfiguration)
		{
			super(container, cfg);
			
			//tiledLayer = new InteractiveLayerQTTMS(container);
		}
		
//		override public function draw(graphics: Graphics): void
//		{
//			
//		}
		
	}
}