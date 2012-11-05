package com.iblsoft.flexiweather.plugins
{
	import mx.core.IFlexDisplayObject;

	public interface IPopupManager
	{
		function openPopup(popup: IFlexDisplayObject, isModal: Boolean): void;
	}
}
