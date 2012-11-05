package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.syndication.ParsingTools;

	/**
	*	Class that represents an Entry element within an Atom feed
	*
	* 	@langversion ActionScript 3.0
	*	@playerversion Flash 8.5
	*	@tiptext
	*
	* 	@see http://www.atomenabled.org/developers/syndication/atom-format-spec.php#rfc.section.4.1.2
	*/
	public class AbstractLatLonBox extends KmlObject
	{
		//todo: add constants for the enum values?
		private var _north: Number;
		private var _south: Number;
		private var _east: Number;
		private var _west: Number;

		/**
		*	Constructor for class.
		*
		*	@param x An XML document that contains an individual Entry element from
		*	an Aton XML feed.
		*
		*/
		public function AbstractLatLonBox(s_namespace: String, x: XMLList)
		{
			super(s_namespace, x);
			var kml: Namespace = new Namespace(s_namespace);
			this._north = ParsingTools.nanCheck(this.xml.kml::north);
			this._south = ParsingTools.nanCheck(this.xml.kml::south);
			this._east = ParsingTools.nanCheck(this.xml.kml::east);
			this._west = ParsingTools.nanCheck(this.xml.kml::west);
		}

		public function get north(): Number
		{
			return this._north;
		}

		public function get south(): Number
		{
			return this._south;
		}

		public function get east(): Number
		{
			return this._east;
		}

		public function get west(): Number
		{
			return this._west;
		}

		public override function toString(): String
		{
			return "AbstractLatLonBox: " + " north: " + this._north + "south: " + this._south + "east: " + this._east + " west: " + this._west;
		}
	}
}
