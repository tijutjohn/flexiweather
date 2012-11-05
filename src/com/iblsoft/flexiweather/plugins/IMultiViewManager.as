package com.iblsoft.flexiweather.plugins
{
	import com.iblsoft.flexiweather.ogc.multiview.data.MultiViewConfiguration;

	public interface IMultiViewManager
	{
		function multiViewDialogOpened(): void;
		function multiViewDialogClosed(): void;
		function changeMultiView(configuration: MultiViewConfiguration): void;
	}
}
