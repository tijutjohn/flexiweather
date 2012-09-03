package com.iblsoft.flexiweather.plugins
{
	import com.iblsoft.flexiweather.ogc.multiview.data.MultiViewConfiguration;

	public interface IMultiViewManager
	{
		function changeMultiView(configuration: MultiViewConfiguration): void;
		//DocStorageWebService is only in OnlineWeather project, so for now, we are requesting just Object
		function getMapsDocStorage(): Object;
	}
}