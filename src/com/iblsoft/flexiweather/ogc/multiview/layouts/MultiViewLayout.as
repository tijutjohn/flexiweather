package com.iblsoft.flexiweather.ogc.multiview.layouts
{
	import spark.layouts.TileLayout;
	
	public class MultiViewLayout extends TileLayout
	{
		public function MultiViewLayout()
		{
			super();
		}
		
		override public function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			trace("MultiviewLayout updateDisplayList ["+unscaledWidth+","+unscaledHeight+"]");
		}
	}
}