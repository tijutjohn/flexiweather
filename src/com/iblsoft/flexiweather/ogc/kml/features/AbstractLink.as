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
	public class AbstractLink extends KmlObject
	{
		//todo: add constants for the enum values?
		private var _href: String;
		private var _refreshMode: String;
		private var _refreshInterval: Number;
		private var _viewRefreshMode: String;
		private var _viewRefreshTime: Number;
		private var _viewBoundScale: Number;
		private var _viewFormat: String;
		private var _httpQuery: String;

		/**
		*	Constructor for class.
		*
		*	@param x An XML document that contains an individual Entry element from
		*	an Aton XML feed.
		*
		*/
		public function AbstractLink(s_namespace: String, x: XMLList)
		{
			super(s_namespace, x);
			var kml: Namespace = new Namespace(s_namespace);
			this._href = ParsingTools.nullCheck(this.xml.kml::href);
			this._refreshMode = ParsingTools.nullCheck(this.xml.kml::refreshMode);
			this._refreshInterval = ParsingTools.nanCheck(this.xml.kml::refreshInterval);
			this._viewRefreshMode = ParsingTools.nullCheck(this.xml.kml::viewRefreshMode);
			this._viewRefreshTime = ParsingTools.nanCheck(this.xml.kml::viewRefreshTime);
			this._viewBoundScale = ParsingTools.nanCheck(this.xml.kml::viewBoundScale);
			this._viewFormat = ParsingTools.nullCheck(this.xml.kml::viewFormat);
			this._httpQuery = ParsingTools.nullCheck(this.xml.kml::httpQuery);
		}

		/**
		*	A String that contains the title for the entry.
		*/
		public function get href(): String
		{
			return this._href;
		}

		/**
		*	A String that contains the title for the entry.
		*/
		public function get refreshMode(): String
		{
			return this._refreshMode;
		}

		/**
		*	A String that contains the title for the entry.
		*/
		public function get refreshInterval(): Number
		{
			return this._refreshInterval;
		}

		/**
		*	A String that contains the title for the entry.
		*/
		public function get viewRefreshMode(): String
		{
			return this._viewRefreshMode;
		}

		/**
		*	A String that contains the title for the entry.
		*/
		public function get viewRefreshTime(): Number
		{
			return this._viewRefreshTime;
		}

		/**
		*	A String that contains the title for the entry.
		*/
		public function get viewBoundScale(): Number
		{
			return this._viewBoundScale;
		}

		/**
		*	A String that contains the title for the entry.
		*/
		public function get viewFormat(): String
		{
			return this._viewFormat;
		}

		/**
		  *	A String that contains the title for the entry.
		  */
		public function get httpQuery(): String
		{
			return this._httpQuery;
		}

		public override function toString(): String
		{
			return "AbstractLink: " + "href: " + this._href;
		}
	}
}
