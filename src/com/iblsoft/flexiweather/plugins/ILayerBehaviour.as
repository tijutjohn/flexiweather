package com.iblsoft.flexiweather.plugins
{
	import flash.display.DisplayObject;

	public interface ILayerBehaviour extends IAbility
	{
		function editBehaviour(
		s_behaviourId: String, s_value: String,
				parent: DisplayObject,
				saveCallback: Function, cancelCallback: Function = null): void;
	}
}
