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
	public class BoundaryCommon extends KmlObject
	{
		private var _linearRing: LinearRing;

		/**
		*	Constructor for class.
		*
		*	@param x An XML document that contains an individual Entry element from
		*	an Aton XML feed.
		*
		*/
		public function BoundaryCommon(s_namespace: String, x: XMLList)
		{
			super(s_namespace, x);
			var kml: Namespace = new Namespace(s_namespace);
			this._linearRing = new LinearRing(s_namespace, this.xml.kml::LinearRing);
		}

		override public function cleanupKML(): void
		{
			super.cleanupKML();
			if (_linearRing)
			{
				_linearRing.cleanupKML();
				_linearRing = null;
			}
		}

		/**
		*	A String that contains the title for the entry.
		*/
		public function get linearRing(): LinearRing
		{
			return this._linearRing;
		}

		public override function toString(): String
		{
			return "Boundary Common: linearRing: " + this._linearRing;
		}
	}
}
