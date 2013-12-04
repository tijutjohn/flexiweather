package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.syndication.ParsingTools;

	public class Lod extends KmlObject
	{
		private var _minLodPixels: Number;
		private var _maxLodPixels: Number;
		private var _minFadeExtent: Number;
		private var _maxFadeExtent: Number;

		public function Lod(s_namespace: String, x: XMLList)
		{
			super(s_namespace, x);
			var kml: Namespace = new Namespace(s_namespace);
			this._minLodPixels = ParsingTools.nanCheck(this.xml.kml::minLodPixels);
			this._maxLodPixels = ParsingTools.nanCheck(this.xml.kml::maxLodPixels);
			this._minFadeExtent = ParsingTools.nanCheck(this.xml.kml::minFadeExtent);
			this._maxFadeExtent = ParsingTools.nanCheck(this.xml.kml::maxFadeExtent);
		}

		public function get minLodPixels(): Number
		{
			return this._minLodPixels;
		}

		public function get maxLodPixels(): Number
		{
			return this._maxLodPixels;
		}

		public function get minFadeExtent(): Number
		{
			return this._minFadeExtent;
		}

		public function get maxFadeExtent(): Number
		{
			return this._maxFadeExtent;
		}
	}
}
