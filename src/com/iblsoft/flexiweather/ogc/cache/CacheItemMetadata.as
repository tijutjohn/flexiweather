package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	
	import flash.net.URLRequest;

	public dynamic class CacheItemMetadata
	{
		public var crs: String;
		public var bbox: BBox;
		public var url: URLRequest;
			
		/**
		 * time in which image is valid 
		 */		
		public var validity: Date;
		
		/**
		 * Dimensions, which will be part of Cache key 
		 */		
		public var dimensions: Array;
		
		public var updateCycleAge: uint;
		
		public function CacheItemMetadata()
		{
			super();
		}
		
		/*
		static public function createFromObject(object: Object): CacheItemMetadata
		{
			var metadata: CacheItemMetadata = new CacheItemMetadata();
			for (var name: String in object)
			{
				var obj: * = object[name];
				metadata[name] = object;
			}
			return metadata;
		}*/
	}
}