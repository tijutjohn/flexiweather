package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	
	public interface ICache
	{
		/**
		 * Debug function for getting information about cache 
		 * @return 
		 * 
		 */		
		function debugCache(): String;
		
		function setAnimationModeEnable(value: Boolean): void;
		function invalidate(s_crs: String, bbox: BBox): void;
	}
}