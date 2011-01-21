package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	
	public interface ICache
	{
		function invalidate(s_crs: String, bbox: BBox): void;
	}
}