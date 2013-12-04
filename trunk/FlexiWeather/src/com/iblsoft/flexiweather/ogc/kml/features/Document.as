package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.ogc.kml.data.KMZFile;
	import com.iblsoft.flexiweather.ogc.kml.features.styles.Style;
	import com.iblsoft.flexiweather.ogc.kml.features.styles.StyleMap;
	import com.iblsoft.flexiweather.ogc.kml.features.styles.StyleSelector;

	/**
	*	Class that represents an Entry element within an Atom feed
	*
	* 	@langversion ActionScript 3.0
	*	@playerversion Flash 8.5
	*	@tiptext
	*
	* 	@see http://www.atomenabled.org/developers/syndication/atom-format-spec.php#rfc.section.4.1.2
	*/
	public class Document extends Container
	{
		public var baseUrlPath: String;
		private var _styles: Array;

		// todo: Support Schema, StyleSelector elements
		/**
		*	Constructor for class.
		*
		*	@param x An XML document that contains an individual Entry element from
		*	an Aton XML feed.
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/
		public function Document(kml: KML, s_namespace: String, x: XMLList)
		{
			super(kml, s_namespace, x);
			var kmlns: Namespace = new Namespace(s_namespace);
			_styles = [];
			var i: XML;
			var style: StyleSelector;
			for each (i in this.xml.kmlns::Style)
			{
				style = new Style(kml, s_namespace, XMLList(i), this);
				this._styles.push(style);
			}
			for each (i in this.xml.kmlns::StyleMap)
			{
				style = new StyleMap(kml, s_namespace, XMLList(i), this);
				this._styles.push(style);
			}
		}

		override public function cleanup(): void
		{
			super.cleanup();
			if (_styles && _styles.length > 0)
			{
				while (_styles.length > 1)
				{
					var style: StyleSelector = _styles.shift() as StyleSelector;
					style.cleanupKML();
					style = null;
				}
				_styles = null;
			}
		}

		public function setBitmapsInSharedStylesFromKMZ(kmzFile: KMZFile): void
		{
			for each (var style: StyleSelector in _styles)
			{
			}
		}

		private function fixStyleUrlID(id: String): String
		{
			if (id.indexOf('#') == 0)
				return id.substr(1, id.length - 1);
			return id;
		}

		public function getStyleSelectorByID(id: String): StyleSelector
		{
			id = fixStyleUrlID(id);
			if (_styles)
			{
				for each (var style: StyleSelector in _styles)
				{
					if (style.id == id)
						return style;
				}
			}
			return null;
		}

		public function getStyleByID(id: String): Style
		{
			id = fixStyleUrlID(id);
			if (_styles)
			{
				for each (var style: StyleSelector in _styles)
				{
					if (style is Style)
					{
						if (style.id == id)
							return style as Style;
					}
				}
			}
			return null;
		}

		public override function toString(): String
		{
			return "Document: styles: " + _styles.length;
		}
	}
}
