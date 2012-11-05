package com.iblsoft.flexiweather.ogc.kml.features
{

	/**
	*	Class that represents an Entry element within an Atom feed
	*
	* 	@langversion ActionScript 3.0
	*	@playerversion Flash 8.5
	*	@tiptext
	*
	* 	@see http://www.atomenabled.org/developers/syndication/atom-format-spec.php#rfc.section.4.1.2
	*/
	public class Coordinates
	{
		//todo: add constants for the enum values?
		private var _coordsList: Array;

		/**
		*	Constructor for class.
		*
		*	@param x An XML document that contains an individual Entry element from
		*	an Aton XML feed.
		*
		*/
		public function Coordinates(string: String)
		{
			string = fixCoordinatesString(string);
			var stringSplit: Array = string.split(" ");
			_coordsList = new Array();
			var total: int = stringSplit.length;
			for (var i: int = 0; i < total; i++)
			{
				var str: String = stringSplit[i] as String;
				if (str && str.length > 0)
				{
					var coordinate: Object = new Object();
					var coordString: Array = stringSplit[i].split(",");
					if (coordString.length == 3)
					{
						coordinate.lon = coordString[0];
						coordinate.lat = coordString[1];
						coordinate.alt = coordString[2];
						_coordsList.push(coordinate);
					}
					else if (coordString.length == 2)
					{
						coordinate.lon = coordString[0];
						coordinate.lat = coordString[1];
						_coordsList.push(coordinate);
					}
				}
			}
		}

		public function cleanupKML(): void
		{
			if (_coordsList && _coordsList.length > 0)
			{
				while (_coordsList.length > 1)
				{
					var coordinate: Object = _coordsList.shift();
					coordinate = null;
				}
				_coordsList = null;
			}
		}

		private function fixCoordinatesString(string: String): String
		{
			var changes: Boolean = false;
			var stringSplit: Array
			do
			{
				changes = false;
				stringSplit = string.split(", ");
				if (stringSplit.length > 1)
					changes = true;
				string = stringSplit.join(',');
				stringSplit = string.split(" ,");
				if (stringSplit.length > 1)
					changes = true;
				string = stringSplit.join(',');
			} while (changes)
			return string;
		}

		/**
		  *	A String that contains the title for the entry.
		  */
		public function get coordsList(): Array
		{
			return this._coordsList;
		}

		public function toString(): String
		{
			return "Coords";
			//return "Coordinates: " + " lat: " + this._lat + " lon: " + this._lon + " alt: " + this._alt;
		}
	}
}
