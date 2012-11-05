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
	public class Point extends Geometry
	{
		//todo: add constants for the enum values?
		private var _coordinates: Coordinates;

		/**
		*	Constructor for class.
		*
		*	@param x An XML document that contains an individual Entry element from
		*	an Aton XML feed.
		*
		*/
		public function Point(s_namespace: String, x: XMLList)
		{
			super(s_namespace, x);
			var kml: Namespace = new Namespace(s_namespace);
			if (ParsingTools.nullCheck(this.xml.kml::coordinates) != null)
				this._coordinates = new Coordinates(ParsingTools.nullCheck(this.xml.kml::coordinates));
		}

		override public function cleanupKML(): void
		{
			super.cleanupKML();
			if (_coordinates)
			{
				_coordinates.cleanupKML();
				_coordinates = null;
			}
		}

		/**
		*	A String that contains the title for the entry.
		*/
		public function get coordinates(): Coordinates
		{
			return this._coordinates;
		}

		public override function toString(): String
		{
			return "Point: " + this._coordinates;
		}
	}
}
