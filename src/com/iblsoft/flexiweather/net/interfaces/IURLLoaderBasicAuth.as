package com.iblsoft.flexiweather.net.interfaces
{
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	
	import flash.events.IEventDispatcher;

	public interface IURLLoaderBasicAuth extends IEventDispatcher
	{
		function setResponseHeaders(headers: Array, responseURL: String, status: int, loader: Object): void;
	}
}