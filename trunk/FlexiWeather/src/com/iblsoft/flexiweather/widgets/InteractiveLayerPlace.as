package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeature;
	import com.iblsoft.flexiweather.proj.Coord;

	public class InteractiveLayerPlace
	{
		public var coord: Coord;
		public var placeLabel: String;
		public var tooltip: String;
		public var featureTypeName: String;
		public var conditionName: String;
		public var feature: WFSFeature;
		[Bindable]
		public var pointColor: uint = 0xffffff;
		[Bindable]
		public var pointType: String = 'circle';
		public var pointLetter: String = '';
		public var pointLetterColor: uint = 0xffffff;
		public var locationLabel: String = 'none';

		public function InteractiveLayerPlace()
		{
		}

		public function updateFromPlace(place: InteractiveLayerPlace): void
		{
			if (place.coord)
				coord = new Coord(place.coord.crs, place.coord.x, place.coord.y);
			pointColor = place.pointColor;
			pointType = place.pointType;
			pointLetter = place.pointLetter;
			pointLetterColor = place.pointLetterColor;
			locationLabel = place.locationLabel;
		}
	}
}
