package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.syndication.ParsingTools;

	public class LookAt extends KmlObject
	{
		/*
			<!-- inherited from AbstractView element -->
			<TimePrimitive>...</TimePrimitive>  <!-- gx:TimeSpan or gx:TimeStamp -->
			<gx:ViewerOptions>
			<option> name=" " type="boolean">     <!-- name="streetview", "historicalimagery", "sunlight", or "groundnavigation" -->
			</option>
			</gx:ViewerOptions>

			<!-- specific to LookAt -->
			<longitude>0</longitude>            <!-- kml:angle180 -->
			<latitude>0</latitude>              <!-- kml:angle90 -->
			<altitude>0</altitude>              <!-- double -->
			<heading>0</heading>                <!-- kml:angle360 -->
			<tilt>0</tilt>                      <!-- kml:anglepos90 -->
			<range></range>                     <!-- double -->
			<altitudeMode>clampToGround</altitudeMode>
			<!--kml:altitudeModeEnum:clampToGround, relativeToGround, absolute -->
			<!-- or, gx:altitudeMode can be substituted: clampToSeaFloor, relativeToSeaFloor -->

		*/
		private var _longitude: Number;
		private var _latitude: Number;
		private var _altitude: Number;
		private var _heading: Number;
		private var _tilt: Number;
		private var _range: Number;
		private var _altitudeMode: String;

		public function LookAt(s_namespace: String, x: XMLList)
		{
			super(s_namespace, x);
			var kml: Namespace = new Namespace(s_namespace);
			this._longitude = ParsingTools.nanCheck(this.xml.kml::longitude);
			this._latitude = ParsingTools.nanCheck(this.xml.kml::latitude);
			this._altitude = ParsingTools.nanCheck(this.xml.kml::altitude);
			this._heading = ParsingTools.nanCheck(this.xml.kml::heading);
			this._tilt = ParsingTools.nanCheck(this.xml.kml::tilt);
			this._range = ParsingTools.nanCheck(this.xml.kml::range);
			this._altitudeMode = ParsingTools.nullCheck(this.xml.kml::altitudeMode);
		}
	}
}
