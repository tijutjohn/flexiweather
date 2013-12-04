package com.iblsoft.flexiweather.ogc.kml.features.styles
{
	import com.iblsoft.flexiweather.ogc.kml.features.Document;
	import com.iblsoft.flexiweather.ogc.kml.features.Icon;
	import com.iblsoft.flexiweather.ogc.kml.features.KML;
	import com.iblsoft.flexiweather.syndication.ParsingTools;

	public class LineStyle extends ColorStyle
	{
		/*
			<s<!-- inherited from ColorStyle -->
			<color>ffffffff</color>            <!-- kml:color -->
			<colorMode>normal</colorMode>      <!-- colorModeEnum: normal or random -->

			<!-- specific to LineStyle -->
			<width>1</width>                            <!-- float -->
			<gx:outerColor>ffffffff</gx:outerColor>     <!-- kml:color -->
			<gx:outerWidth>0.0</gx:outerWidth>          <!-- float -->
			<gx:physicalWidth>0.0</gx:physicalWidth>    <!-- float -->
			<gx:labelVisibility>0</gx:labelVisibility>  <!-- boolean -->
		*/
		private var _width: Number;

		public function LineStyle(kml: KML, s_namespace: String, x: XMLList, document: Document)
		{
			super(kml, s_namespace, x, document);
			var kmlns: Namespace = new Namespace(s_namespace);
			this._width = ParsingTools.nanCheck(this.xml.kmlns::width);
		}

		public function get width(): Number
		{
			return this._width;
		}
	}
}
