package com.iblsoft.flexiweather.ogc.editable
{
	import flash.events.MouseEvent;
	import flash.geom.Point;

	public interface IMouseEditableItem extends IEditableItem
	{
		function onMouseMove(pt: Point, event: MouseEvent): Boolean;
		function onMouseClick(pt: Point, event: MouseEvent): Boolean;
		function onMouseDoubleClick(pt: Point, event: MouseEvent): Boolean;
		function onMouseDown(pt: Point, event: MouseEvent): Boolean;
		function onMouseUp(pt: Point, event: MouseEvent): Boolean;
	}
}
