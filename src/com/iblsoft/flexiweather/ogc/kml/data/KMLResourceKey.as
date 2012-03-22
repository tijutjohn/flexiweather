package com.iblsoft.flexiweather.ogc.kml.data
{
	public class KMLResourceKey
	{
		public var href: String;
		public var baseURL: String
		public var type: String;
		
		public function KMLResourceKey(href: String, baseURL: String, type: String)
		{
			if (!baseURL)
				baseURL = '';
			
			this.href = href;
			this.baseURL = baseURL;
			this.type = type;
		}
		
		public function toString(): String
		{
			return baseURL + "__" + href + "__" + type;
		}
	}
}