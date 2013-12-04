package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.syndication.ParsingTools;
	import com.iblsoft.flexiweather.syndication.XmlElement;

	/**
	*	Class that represents an Entry element within an Atom feed
	*
	* 	@langversion ActionScript 3.0
	*	@playerversion Flash 8.5
	*	@tiptext
	*
	* 	@see http://www.atomenabled.org/developers/syndication/atom-format-spec.php#rfc.section.4.1.2
	*/
	public class KmlObject extends XmlElement
	{
		//todo: add constants for the enum values?
		private var _id: String;

		/**
		*	Constructor for class.
		*
		*	@param x An XML document that contains an individual Entry element from
		*	an Aton XML feed.
		*
		*/
		public function KmlObject(s_namespace: String, x: XMLList)
		{
			super(s_namespace, x);
			var kml: Namespace = new Namespace(s_namespace);
			this._id = ParsingTools.nullCheck(this.xml.kml::id);
		}

		/**
		*	A String that contains the title for the entry.
		*/
		public function get id(): String
		{
			return this._id;
		}

		override public function toString(): String
		{
			return "KmlObject with id: " + this._id;
		}
	}
}
