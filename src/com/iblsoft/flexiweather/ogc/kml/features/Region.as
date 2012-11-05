package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.syndication.ParsingTools;

	public class Region extends KmlObject
	{
		private var _latLongAltBox: LatLonAltBox;
		private var _lod: Lod;

		public function Region(s_namespace: String, x: XMLList)
		{
			super(s_namespace, x);
			var kmlns: Namespace = new Namespace(s_namespace);
			if (ParsingTools.nullCheck(this.xml.kmlns::LatLonAltBox))
				this._latLongAltBox = new LatLonAltBox(s_namespace, this.xml.kmlns::LatLonAltBox);
			if (ParsingTools.nullCheck(this.xml.kmlns::Lod))
				this._lod = new Lod(s_namespace, this.xml.kmlns::Lod);
		}

		override public function cleanupKML(): void
		{
			super.cleanupKML();
			if (_latLongAltBox)
			{
				_latLongAltBox.cleanupKML();
				_latLongAltBox = null;
			}
			if (_lod)
			{
				_lod.cleanupKML();
				_lod = null;
			}
		}

		public function get lod(): Lod
		{
			return this._lod;
		}

		public function get latLongAltBox(): LatLonAltBox
		{
			return this._latLongAltBox;
		}
	}
}
