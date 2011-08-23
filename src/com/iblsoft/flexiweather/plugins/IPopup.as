package com.iblsoft.flexiweather.plugins
{
	import mx.core.IFlexDisplayObject;

	public interface IPopup
	{
		function getPopup(): IFlexDisplayObject;
		function canBeClosed(): Boolean;
		function popupIsOpening():void;
		function popupIsClosing():void;
	}
}