package com.iblsoft.flexiweather.widgets.controls
{
	import spark.components.ToggleButton;
	
	public class ToggleButtonBarButton extends ToggleButton
	{
		public var type: String;
		
		override public function set enabled(value:Boolean):void
		{
			super.enabled = value;
		}
		
		override public function set selected(value:Boolean):void
		{
			//normal buttons are not selecteble
			if (type && type == ToggleButtonBarItemData.NORMAL)
				value = false;
			
			super.selected = value;	
		}
		
		public function ToggleButtonBarButton()
		{
			super();
		}
	}
}