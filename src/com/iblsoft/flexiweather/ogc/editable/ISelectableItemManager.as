package com.iblsoft.flexiweather.ogc.editable
{
	public interface ISelectableItemManager
	{
		function selectItem(item: ISelectableItem, dispatchChangeEvent: Boolean = true): void;
	}
}