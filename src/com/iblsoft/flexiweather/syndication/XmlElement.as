package com.iblsoft.flexiweather.syndication
{
	import flash.events.EventDispatcher;

	/**
	 * The parent class of any feed-related class that is populated with XML.
	 * This class provides an easy way to get and set the XML used to populate
	 * most of the RSS and Atom related classes.
	 *
	 * @langversion ActionScript 3.0
	 * @playerversion Flash 8.5
	 * @tiptext
	 */
	public class XmlElement extends EventDispatcher
	{
		protected var xmlSource: XMLList;
		protected var namespace: String;

		/**
		 * Create a new NewsFeedElement instance.
		 *
		 * @param x The XML used to populate the NewsFeedElement.
		 *
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function XmlElement(s_namespace: String, x: XMLList)
		{
			this.xmlSource = x;
			this.namespace = s_namespace;
		}

		public function cleanupKML(): void
		{
			xmlSource = null;
		}

		/**
		 * Get the XML used to populate the NewsFeedElement.
		 *
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get xml(): XMLList
		{
			return this.xmlSource;
		}

		/**
		 * Set the XML used to populate the NewsFeedElement.
		 *
		 * @param x The XML used to populate the NewsFeedElement.
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function set xml(x: XMLList): void
		{
			this.xmlSource = x;
		}
	}
}
