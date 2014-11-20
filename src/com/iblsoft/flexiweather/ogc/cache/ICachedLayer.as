package com.iblsoft.flexiweather.ogc.cache
{

	public interface ICachedLayer
	{
		function clearCache(b_disposeDisplayed: Boolean): void;
		function getCache(): ICache;
	}
}
