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
	public class LatLonBox extends AbstractLatLonBox
	{
		//todo: add constants for the enum values?
		private var _rotation: Number;

		/**
		*	Constructor for class.
		*
		*	@param x An XML document that contains an individual Entry element from
		*	an Aton XML feed.
		*
		*/
		public function LatLonBox(s_namespace: String, x: XMLList)
		{
			super(s_namespace, x);
			var kml: Namespace = new Namespace(s_namespace);
			this._rotation = ParsingTools.nanCheck(this.xml.kml::rotation);
		}

		public function get rotation(): Number
		{
			return this._rotation;
		}

		public override function toString(): String
		{
			return "LatLonBox: " + super.toString() + " rotation: " + this._rotation;
		}
	}
}
