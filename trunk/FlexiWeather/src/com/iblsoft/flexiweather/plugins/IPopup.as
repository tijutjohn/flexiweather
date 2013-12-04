package com.iblsoft.flexiweather.plugins
{
	import flash.events.IEventDispatcher;
	import mx.core.IFlexDisplayObject;

	public interface IPopup extends IEventDispatcher
	{
		function setPopupManager(popupManager: IPopupManager): void;
		function getPopup(): IFlexDisplayObject;
		function canBeClosed(): Boolean;
		function popupIsOpening(): void;
		function popupIsClosing(): void;
	}
}
