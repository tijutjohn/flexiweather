package com.iblsoft.flexiweather.ogc.kml.data
{

	public class KMLResourceKey
	{
		public var href: String;
		private var _baseURL: String
		public var type: String;

		private var _keyString: String;
		
		public function KMLResourceKey(href: String, baseURL: String, type: String)
		{
			if (!baseURL)
				baseURL = '';
			this.href = href;
			this.baseURL = baseURL;
			this.type = type;
			
			updateKeyString();
		}
		
		private function updateKeyString(): void
		{
			_keyString = baseURL + "__" + href + "__" + type;	
		}

		public function get baseURL(): String
		{
			return _baseURL;
		}

		public function set baseURL(value: String): void
		{
			_baseURL = value;
			updateKeyString();
		}

		public function toString(): String
		{
			return _keyString;
		}
	}
}
