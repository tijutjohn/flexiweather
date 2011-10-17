package com.iblsoft.flexiweather.net.interfaces
{
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	public interface IURLLoaderBasicAuthListener
	{
		function addBasicAuthListeners(basicAuthLoader: IURLLoaderBasicAuth, urlLoader: URLLoader):void;
		function removeBasicAuthListeners(): void;
	}
}