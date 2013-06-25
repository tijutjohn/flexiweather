package com.iblsoft.flexiweather.widgets
{
	import spark.components.Group;
	
	public class InteractiveLayerLegendGroup extends Group
	{
		override public function set visible(value:Boolean):void
		{
			super.visible = value;
		}
		
		public function InteractiveLayerLegendGroup()
		{
			super();
		}
	}
}