package com.iblsoft.flexiweather.plugins
{
	import com.iblsoft.flexiweather.ogc.multiview.data.MultiViewConfiguration;

	public interface IMultiViewManager
	{
		function changeMultiView(configuration: MultiViewConfiguration): void;
	}
}