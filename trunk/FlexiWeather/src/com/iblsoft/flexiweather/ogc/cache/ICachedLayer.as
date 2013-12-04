package com.iblsoft.flexiweather.ogc.cache
{

	public interface ICachedLayer
	{
		function clearCache(): void;
		function getCache(): ICache;
	}
}
