package com.iblsoft.flexiweather.ogc.multiview.layouts
{
	import spark.layouts.ColumnAlign;
	import spark.layouts.RowAlign;
	import spark.layouts.TileLayout;
	
	public class MultiViewLayout extends TileLayout
	{
		
		override public function set columnAlign(value:String):void
		{
			super.columnAlign = ColumnAlign.JUSTIFY_USING_GAP;
		}
		
		override public function set rowAlign(value:String):void
		{
			super.rowAlign = RowAlign.JUSTIFY_USING_GAP;
		}
		
		public function MultiViewLayout()
		{
			super();
			
			columnAlign =  ColumnAlign.JUSTIFY_USING_GAP;
			rowAlign =  RowAlign.JUSTIFY_USING_GAP;
		}
		
		override public function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			trace("MultiviewLayout updateDisplayList ["+unscaledWidth+","+unscaledHeight+"]");
		}
	}
}