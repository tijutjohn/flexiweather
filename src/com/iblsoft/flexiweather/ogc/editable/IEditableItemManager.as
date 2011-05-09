package com.iblsoft.flexiweather.ogc.editable
{
	public interface IEditableItemManager
	{
		function addEditableItem(item: IEditableItem): void;
		function removeEditableItem(item: IEditableItem): void;
		
		function setMouseMoveCapture(item: IMouseEditableItem): void;
		function releaseMouseMoveCapture(item: IMouseEditableItem): void;
		function setMouseClickCapture(item: IMouseEditableItem): void;
		function releaseMouseClickCapture(item: IMouseEditableItem): void;

		function selectItem(item: ISelectableItem, dispatchChangeEvent: Boolean = true): void;
		
		function doHitTest(
				f_stageX: Number, f_stageY: Number,
				classFilter: Class = null,
				b_visibleOnly: Boolean = true): Array;

	}
}