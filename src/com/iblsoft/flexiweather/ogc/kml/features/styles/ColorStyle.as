package com.iblsoft.flexiweather.ogc.kml.features.styles
{
	import com.iblsoft.flexiweather.ogc.kml.features.Document;
	import com.iblsoft.flexiweather.ogc.kml.features.KML;
	import com.iblsoft.flexiweather.syndication.Namespaces;
	import com.iblsoft.flexiweather.syndication.ParsingTools;

	public class ColorStyle extends Style
	{
		private var _color: uint;
		private var _alpha: Number;
		/**
		 * Allowed values are: "normal" or "random"
		 */
		private var _colorMode: String;

		public function ColorStyle(kml: KML, s_namespace: String, x: XMLList, document: Document)
		{
			super(kml, s_namespace, x, document);
			var kmlns: Namespace = new Namespace(s_namespace);
			var colorStr: String = ParsingTools.nullCheck(this.xml.kmlns::color);
			if (colorStr)
			{
				if (colorStr.indexOf("#") == 0)
					colorStr = colorStr.substring(1, colorStr.length);
				_alpha = parseInt("0x" + colorStr.substr(0, 2));
				_alpha = _alpha / 255;
				//color is stored as  aabbggrr
				colorStr = colorStr.substr(6, 2) + colorStr.substr(4, 2) + colorStr.substr(2, 2);
				this._color = parseInt("0x" + colorStr);
			}
			this._colorMode = ParsingTools.nullCheck(this.xml.kmlns::colorMode);
		}

		public function get alpha(): Number
		{
			return this._alpha;
		}

		public function get color(): uint
		{
			return this._color;
		}

		public function get colorMode(): String
		{
			return this._colorMode;
		}

		public override function toString(): String
		{
			return "ColorStyle: [" + super.toString() + "] color: " + this._color + " alpha" + alpha + " mode: " + this._colorMode;
		}
	}
}
