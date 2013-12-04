package com.iblsoft.flexiweather.ogc.kml.data
{
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;
	import com.iblsoft.flexiweather.ogc.data.ReflectionDictionary;
	import com.iblsoft.flexiweather.ogc.kml.features.KMLFeature;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	public class KMLFeaturesReflectionDictionary extends ReflectionDictionary
	{
		public function KMLFeaturesReflectionDictionary(iw: InteractiveWidget): void
		{
			super(iw);
		}

		override protected function createNewReflectionData(): ReflectionData
		{
			return new KMLReflectionData(_iw);
		}

		public function updateKMLFeature(feature: KMLFeature): void
		{
			for each (var reflection: KMLReflectionData in _dictionary)
			{
				reflection.feature = feature;
			}
		}
	}
}
