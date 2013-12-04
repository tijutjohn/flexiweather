package com.iblsoft.flexiweather.ogc.editable
{

	public interface IEditableItem
	{
		function onRegisteredAsEditableItem(eim: IEditableItemManager): void;
		function onUnregisteredAsEditableItem(eim: IEditableItemManager): void;
		function hitTestPoint(x: Number, y: Number, b_checkPrecise: Boolean = false): Boolean;
		function get editPriority(): int;
	}
}
