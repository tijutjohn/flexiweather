package com.iblsoft.flexiweather.ogc.editable
{
	import flash.events.MouseEvent;

	public interface ISelectableItemManager
	{
		function selectItem(item: ISelectableItem, mouseEvent: MouseEvent = null, dispatchChangeEvent: Boolean = true): void;
	}
}