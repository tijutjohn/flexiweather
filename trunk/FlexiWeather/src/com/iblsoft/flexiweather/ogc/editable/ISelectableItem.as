package com.iblsoft.flexiweather.ogc.editable
{
	import flash.events.IEventDispatcher;

	public interface ISelectableItem extends IEventDispatcher
	{
		function set selected(b: Boolean): void;
		function get selected(): Boolean;
	}
}
