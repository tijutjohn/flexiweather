package com.iblsoft.flexiweather.ogc.kml.data
{
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;
	import com.iblsoft.flexiweather.ogc.kml.features.KMLFeature;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	public class KMLReflectionData extends ReflectionData
	{
		public var feature: KMLFeature;

		public function KMLReflectionData(iw: InteractiveWidget)
		{
			super(iw);
		}

		override public function remove(): void
		{
			super.remove();
			feature = null;
		}
	}
}
