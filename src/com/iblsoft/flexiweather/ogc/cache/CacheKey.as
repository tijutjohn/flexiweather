package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	
	import flash.net.URLRequest;

	public class CacheKey
	{
		private var ms_key: String;
		
		public function get key(): String
		{
			return ms_key;
		}
		public function set key(value: String): void
		{
			ms_key = value;
		}
		
		public var url: URLRequest;
		public var crs: String;
		public var bbox: BBox;
		
		public function CacheKey(s_crs: String, bbox: BBox, url: URLRequest)
		{
			crs = s_crs;
			bbox = bbox;
			this.url = url;
		}
		
		public function toString(): String
		{ return ms_key; }
	}
}