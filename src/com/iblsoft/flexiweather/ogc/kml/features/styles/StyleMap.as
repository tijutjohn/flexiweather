package com.iblsoft.flexiweather.ogc.kml.features.styles
{
	import com.iblsoft.flexiweather.ogc.kml.features.Document;
	import com.iblsoft.flexiweather.ogc.kml.features.KML;
	import com.iblsoft.flexiweather.syndication.ParsingTools;
	import flash.utils.Dictionary;

	public class StyleMap extends StyleSelector
	{
		private var _pairs: Dictionary;

		public function StyleMap(kml: KML, s_namespace: String, x: XMLList, document: Document)
		{
			super(kml, s_namespace, x, document);
			var kmlns: Namespace = new Namespace(s_namespace);
			_pairs = new Dictionary();
			var i: XML;
			for each (i in this.xml.kmlns::Pair)
			{
				var pair: Pair = new Pair(kml, s_namespace, XMLList(i), document)
				_pairs[pair.key] = pair;
			}
		}

		override public function cleanupKML(): void
		{
			super.cleanupKML();
			for each (var pair: Pair in _pairs)
			{
				pair.cleanupKML();
				delete _pairs[pair.key];
				pair = null;
			}
			_pairs = null;
		}

		public function get styleUrl(): String
		{
			return getStyleUrlByKey('normal');
		}

		public function get style(): Style
		{
			return getStyleByKey('normal');
		}

		public function getStyleUrlByKey(key: String): String
		{
			for each (var pair: Pair in _pairs)
			{
				if (pair.key == key)
				{
					if (pair.styleUrl)
						return pair.styleUrl;
				}
			}
			return null;
		}

		public function getStyleByKey(key: String): Style
		{
			for each (var pair: Pair in _pairs)
			{
				if (pair.key == key)
				{
					if (pair.style)
						return pair.style;
				}
			}
			return null;
		}

		override public function toString(): String
		{
			var tmp: String = "StyleMap \n";
			return tmp;
		}
	}
}
import com.iblsoft.flexiweather.ogc.kml.features.Document;
import com.iblsoft.flexiweather.ogc.kml.features.KML;
import com.iblsoft.flexiweather.ogc.kml.features.styles.Style;
import com.iblsoft.flexiweather.syndication.Namespaces;
import com.iblsoft.flexiweather.syndication.ParsingTools;
import com.iblsoft.flexiweather.syndication.XmlElement;

class Pair extends XmlElement
{
	/**
	 * can be "normal" or "highlight "
	 */
	private var _key: String;
	private var _styleUrl: String;
	private var _style: Style;

	public function Pair(kml: KML, s_namespace: String, x: XMLList, document: Document)
	{
		super(s_namespace, x);
		var kmlns: Namespace = new Namespace(s_namespace);
		if (ParsingTools.nullCheck(this.xml.kmlns::Style))
			this._style = new Style(kml, s_namespace, this.xml.kmlns::Style, document);
		this._key = ParsingTools.nullCheck(this.xml.kmlns::key);
		this._styleUrl = ParsingTools.nullCheck(this.xml.kmlns::styleUrl);
	}

	override public function cleanupKML(): void
	{
		super.cleanupKML();
		if (_style)
		{
			_style.cleanupKML();
			_style = null;
		}
	}

	public function get key(): String
	{
		return _key;
	}

	public function get styleUrl(): String
	{
		return _styleUrl;
	}

	public function get style(): Style
	{
		return _style;
	}
}
