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
	public class LinearRing extends Geometry
	{
		//todo: add constants for the enum values?
		// Can contain: <extrude>, <tessellate>, <altitudeMode>, <coordinates>
		// We support coordinates only
		private var _coordinates: Coordinates;
		private var _coordinatesPoints: Array;

		/**
		*	Constructor for class.
		*
		*	@param x An XML document that contains an individual Entry element from
		*	an Aton XML feed.
		*
		*/
		public function LinearRing(s_namespace: String, x: XMLList)
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
			if (_coordinatesPoints)
			{
				_coordinatesPoints.removeAll();
				_coordinatesPoints = null;
			}
		}

		/**
		*	A String that contains the title for the entry.
		*/
		public function get coordinates(): Coordinates
		{
			return this._coordinates;
		}

		public function get coordinatesPoints(): Array
		{
			if (_coordinatesPoints)
				return _coordinatesPoints;
			return [];
		}

		public function set coordinatesPoints(a: Array): void
		{
			_coordinatesPoints = a;
		}

		public override function toString(): String
		{
			return "LinearRing: " + super.toString() + " coordinates" + this._coordinates;
		}
	}
}
