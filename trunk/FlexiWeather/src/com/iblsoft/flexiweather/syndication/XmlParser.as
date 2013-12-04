package com.iblsoft.flexiweather.syndication
{
	import com.iblsoft.flexiweather.ogc.kml.data.KMZFile;
	import flash.events.EventDispatcher;

	/**
	 * The parent class of all the RSS and Atom parsers. Provides functions for
	 * setting and parsing XML.
	 *
	 * @langversion ActionScript 3.0
	 * @playerversion Flash 8.5
	 * @tiptext
	 */
	public class XmlParser extends EventDispatcher
	{
		protected var xml: XML;

		/**
		 * Parses the specified feed into an XML object, and populates the
		 * subclassing parser.
		 *
		 * @param xmlStr A string of XML that is an RSS or an Atom feed.
		 *
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		protected function parseSource(xmlStr: String): void
		{
			this.populate(new XML(xmlStr));
		}

		public function cleanup(): void
		{
			xml = null;
		}

		/**
		 * Populates the subclassing parser.
		 *
		 * @param newXml An XML object that represents an RSS or an Atom feed.
		 *
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function populate(newXml: XML): void
		{
			this.xml = newXml;
		}
	}
}
