package com.iblsoft.flexiweather.ogc.kml.features.styles
{
	import com.iblsoft.flexiweather.ogc.kml.features.Document;
	import com.iblsoft.flexiweather.ogc.kml.features.Icon;
	import com.iblsoft.flexiweather.ogc.kml.features.KML;
	import com.iblsoft.flexiweather.syndication.ParsingTools;

	public class PolyStyle extends ColorStyle
	{
		/*
			<!-- inherited from ColorStyle -->
			<color>ffffffff</color>            <!-- kml:color -->
			<colorMode>normal</colorMode>      <!-- kml:colorModeEnum: normal or random -->

			<!-- specific to PolyStyle -->
			<fill>1</fill>                     <!-- boolean -->
			<outline>1</outline>               <!-- boolean -->
		*/
		private var _fill: Boolean;
		private var _outline: Boolean;

		public function PolyStyle(kml: KML, s_namespace: String, x: XMLList, document: Document)
		{
			super(kml, s_namespace, x, document);
			var kmlns: Namespace = new Namespace(s_namespace);
			var fill: Number = ParsingTools.nanCheck(this.xml.kmlns::fill);
			if (isNaN(fill))
				this._fill = true;
			else
				this._fill = (fill == 1);
			var outline: Number = ParsingTools.nanCheck(this.xml.kmlns::outline);
			if (isNaN(outline))
				this._outline = true;
			else
				this._outline = (outline == 1);
		}

		public function get fill(): Boolean
		{
			return this._fill;
		}

		public function get outline(): Boolean
		{
			return this._outline;
		}
	}
}
