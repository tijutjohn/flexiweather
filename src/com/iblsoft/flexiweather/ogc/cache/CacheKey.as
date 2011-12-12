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
		public var validity: Date;
		
		public function CacheKey(s_crs: String, bbox: BBox, url: URLRequest, validity: Date = null)
		{
			crs = s_crs;
			bbox = bbox;
			this.url = url;
			this.validity = validity;
		}
		
		public function toString(): String
		{ return ms_key; }
	}
}