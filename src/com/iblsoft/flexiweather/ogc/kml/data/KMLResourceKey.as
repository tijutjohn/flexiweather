package com.iblsoft.flexiweather.ogc.kml.data
{

	public class KMLResourceKey
	{
		public var href: String;

		private var _baseURL: String

		public var type: String;

		public function KMLResourceKey(href: String, baseURL: String, type: String)
		{
			if (!baseURL)
				baseURL = '';
			this.href = href;
			this.baseURL = baseURL;
			this.type = type;
		}

		public function get baseURL(): String
		{
			return _baseURL;
		}

		public function set baseURL(value: String): void
		{
			_baseURL = value;
		}

		public function toString(): String
		{
			return baseURL + "__" + href + "__" + type;
		}
	}
}
