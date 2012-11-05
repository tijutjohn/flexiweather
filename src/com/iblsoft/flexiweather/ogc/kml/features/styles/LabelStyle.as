package com.iblsoft.flexiweather.ogc.kml.features.styles
{
	import com.iblsoft.flexiweather.ogc.kml.features.Document;
	import com.iblsoft.flexiweather.ogc.kml.features.KML;
	import com.iblsoft.flexiweather.syndication.ParsingTools;

	public class LabelStyle extends ColorStyle
	{
		private var _scale: Number;

		public function LabelStyle(kml: KML, s_namespace: String, x: XMLList, document: Document)
		{
			super(kml, s_namespace, x, document);
			var kmlns: Namespace = new Namespace(s_namespace);
			this._scale = ParsingTools.nanCheck(this.xml.kmlns::scale);
		}

		public function get scale(): Number
		{
			return this._scale;
		}

		public override function toString(): String
		{
			return "LabelStyle: [" + super.toString() + "] _scale: " + _scale;
		}
	}
}
