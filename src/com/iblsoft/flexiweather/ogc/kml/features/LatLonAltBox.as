package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.syndication.ParsingTools;

	public class LatLonAltBox extends AbstractLatLonBox
	{
		private var _minAltitude: Number;
		private var _maxAltitude: Number;

		public function LatLonAltBox(s_namespace: String, x: XMLList)
		{
			super(s_namespace, x);
			var kml: Namespace = new Namespace(s_namespace);
			this._minAltitude = ParsingTools.nanCheck(this.xml.kml::minAltitude);
			this._maxAltitude = ParsingTools.nanCheck(this.xml.kml::maxAltitude);
		}

		public function get minAltitude(): Number
		{
			return this._minAltitude;
		}

		public function get maxAltitude(): Number
		{
			return this._maxAltitude;
		}
	}
}
