package com.iblsoft.flexiweather.ogc.editable
{
	import flash.events.IEventDispatcher;

	public interface IHighlightableItem extends IEventDispatcher
	{
		function canReleaseHighlight(): Boolean;
		function set highlighted(b: Boolean): void;
		function get highlighted(): Boolean;
	}
}
