package com.iblsoft.flexiweather.ogc.kml.features.styles
{
	import com.iblsoft.flexiweather.ogc.kml.features.Document;
	import com.iblsoft.flexiweather.ogc.kml.features.KML;
	import com.iblsoft.flexiweather.syndication.Namespaces;
	import com.iblsoft.flexiweather.syndication.ParsingTools;

	public class Style extends StyleSelector
	{
		private var _iconStyle: IconStyle;
		private var _labelStyle: LabelStyle;
		private var _lineStyle: LineStyle;
		private var _polyStyle: PolyStyle;

		public function Style(kml: KML, s_namespace: String, x: XMLList, document: Document)
		{
			super(kml, s_namespace, x, document);
			var kmlns: Namespace = new Namespace(s_namespace);
			if (ParsingTools.nullCheck(this.xml.kmlns::IconStyle))
				this._iconStyle = new IconStyle(kml, s_namespace, this.xml.kmlns::IconStyle, document);
			if (ParsingTools.nullCheck(this.xml.kmlns::LabelStyle))
				this._labelStyle = new LabelStyle(kml, s_namespace, this.xml.kmlns::LabelStyle, document);
			if (ParsingTools.nullCheck(this.xml.kmlns::LineStyle))
				this._lineStyle = new LineStyle(kml, s_namespace, this.xml.kmlns::LineStyle, document);
			if (ParsingTools.nullCheck(this.xml.kmlns::PolyStyle))
				this._polyStyle = new PolyStyle(kml, s_namespace, this.xml.kmlns::PolyStyle, document);
		}

		override public function cleanupKML(): void
		{
			super.cleanupKML();
			if (_iconStyle)
			{
				_iconStyle.cleanupKML();
				_iconStyle = null;
			}
			if (_labelStyle)
			{
				_labelStyle.cleanupKML();
				_labelStyle = null;
			}
			if (_lineStyle)
			{
				_lineStyle.cleanupKML();
				_lineStyle = null;
			}
			if (_polyStyle)
			{
				_polyStyle.cleanupKML();
				_polyStyle = null;
			}
		}

		public function get iconStyle(): IconStyle
		{
			return this._iconStyle;
		}

		public function get labelStyle(): LabelStyle
		{
			return this._labelStyle;
		}

		public function get lineStyle(): LineStyle
		{
			return this._lineStyle;
		}

		public function get polyStyle(): PolyStyle
		{
			return this._polyStyle;
		}

		override public function toString(): String
		{
			var tmp: String = "Style \n";
			tmp += "\t iconStyle: " + _iconStyle + "\n";
			tmp += "\t _labelStyle: " + _labelStyle + "\n";
			tmp += "\t _lineStyle: " + _lineStyle + "\n";
			tmp += "\t _polyStyle: " + _polyStyle + "\n";
			return tmp;
		}
	}
}
