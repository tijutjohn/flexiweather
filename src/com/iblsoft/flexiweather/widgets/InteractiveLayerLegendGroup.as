package com.iblsoft.flexiweather.widgets
{
	import spark.components.Group;
	
	public class InteractiveLayerLegendGroup extends Group
	{
		static public var groupUID: int = 0;
		
		public var groupID: int;
		
		override public function set visible(value:Boolean):void
		{
			super.visible = value;
		}
		
		public function InteractiveLayerLegendGroup()
		{
			groupID = groupUID++;
			super();
		}
		
		override public function toString(): String
		{
			return "InteractiveLayerLegendGroup: "+ groupID;
		}
	}
}