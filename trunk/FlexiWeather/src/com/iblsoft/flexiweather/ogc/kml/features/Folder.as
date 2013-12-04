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
	public class Folder extends Container
	{
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
		public function Folder(kml: KML, s_namespace: String, x: XMLList)
		{
			super(kml, s_namespace, x);
		}

		public override function toString(): String
		{
			return "Folder: ";
		}
	}
}
