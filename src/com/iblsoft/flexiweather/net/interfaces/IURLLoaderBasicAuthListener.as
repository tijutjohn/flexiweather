package com.iblsoft.flexiweather.net.interfaces
{
	import com.iblsoft.flexiweather.net.data.UniURLLoaderData;
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	public interface IURLLoaderBasicAuthListener
	{
		function addBasicAuthListeners(basicAuthLoader: IURLLoaderBasicAuth, urlLoader: URLLoader, data: UniURLLoaderData): void;
		function removeBasicAuthListeners(): void;
		function getData(): UniURLLoaderData;
		function destroy(): void;
	}
}
