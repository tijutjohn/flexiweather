package com.iblsoft.flexiweather.plugins
{
	import mx.core.IFlexDisplayObject;

	public interface IPopup
	{
		function setPopupManager(popupManager: IPopupManager): void;
		
		function getPopup(): IFlexDisplayObject;
		function canBeClosed(): Boolean;
		function popupIsOpening():void;
		function popupIsClosing():void;
	}
}