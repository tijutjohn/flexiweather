package com.iblsoft.flexiweather.ogc.editable
{
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	public interface IMouseEditableItem extends IEditableItem
	{
		function onMouseMove(pt: Point): Boolean;
		function onMouseClick(pt: Point): Boolean;
		function onMouseDoubleClick(pt: Point): Boolean;
		function onMouseDown(pt: Point): Boolean;
		function onMouseUp(pt: Point): Boolean;
	}
}