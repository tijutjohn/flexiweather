package com.iblsoft.flexiweather.ogc.kml.features.styles
{
	import com.iblsoft.flexiweather.ogc.kml.features.Document;
	import com.iblsoft.flexiweather.ogc.kml.features.Icon;
	import com.iblsoft.flexiweather.ogc.kml.features.KML;
	import com.iblsoft.flexiweather.syndication.Namespaces;
	import com.iblsoft.flexiweather.syndication.ParsingTools;

	public class IconStyle extends ColorStyle
	{
		/*
			<scale>1</scale>                   <!-- float -->
			<heading>0</heading>               <!-- float -->
			<Icon>
			<href>...</href>
			</Icon>
			<hotSpot x="0.5"  y="0.5"
			xunits="fraction" yunits="fraction"/>
		*/
		private var _scale: Number;
		private var _heading: Number;
		private var _icon: Icon;
		private var _hotspot: HotSpot;

		public function IconStyle(kml: KML, s_namespace: String, x: XMLList, document: Document)
		{
			super(kml, s_namespace, x, document);
			var kmlns: Namespace = new Namespace(s_namespace);
			this._scale = ParsingTools.nanCheck(this.xml.kmlns::scale);
			this._heading = ParsingTools.nanCheck(this.xml.kmlns::heading);
			var h: XML = (this.xml.kmlns::hotSpot)[0] as XML;
			if (h)
				this._hotspot = new HotSpot(h);
			if (ParsingTools.nullCheck(this.xml.kmlns::Icon))
				this._icon = new Icon(s_namespace, this.xml.kmlns::Icon);
		}

		override public function cleanupKML(): void
		{
			super.cleanupKML();
			if (_hotspot)
				_hotspot = null;
			if (_icon)
				_icon = null;
		}

		public function get scale(): Number
		{
			if (isNaN(this._scale))
				return 1;
			return this._scale;
		}

		public function get heading(): Number
		{
			return this._heading;
		}

		public function get icon(): Icon
		{
			return this._icon;
		}

		public function get hotspot(): HotSpot
		{
			return this._hotspot;
		}
	}
}
