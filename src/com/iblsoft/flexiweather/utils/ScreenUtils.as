package com.iblsoft.flexiweather.utils
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.filters.BitmapFilter;
	import flash.geom.Point;
	
	import mx.core.Application;
	import mx.core.UIComponent;
	
	import mx.core.FlexGlobals;
	
	public class ScreenUtils
	{
		public static function moveSpriteToButKeepFullyOnScreen(c: Sprite, pt: Point): void
		{
			var f_sw: Number = FlexGlobals.topLevelApplication.screen.width;
			var f_sh: Number = FlexGlobals.topLevelApplication.screen.height;
			c.x = pt.x;
			c.y = pt.y;
			if(c.x + c.width > f_sw)
				c.x = f_sw - c.width;
			if(c.y + c.height > f_sh)
				c.y = f_sh - c.height;
		}

		public static function localPointContainedIn(src: Sprite, pt: Point, dst: Sprite): Boolean
		{
			var ptRemapped: Point = dst.globalToLocal(src.localToGlobal(pt));
			return pt.x >= 0
					&& pt.x < dst.width
					&& pt.y >= 0
					&& pt.y < dst.height;
		}
		
		public static function isVisible(o: DisplayObject): Boolean
		{
			if(o == null)
				return false;
			while(o != null) {
				if(!o.visible)
					return false;
				o = o.parent;
			}
			return true;
		}
		
		private static var sm_dimFilter: BitmapFilter = BitmapFilterUtils.createGrayscale(0.3);

		public static function setEnabledWithDim(o: UIComponent, b_enabled: Boolean): void
		{
			if (o)
			{
				if(o.enabled != b_enabled) {
					o.enabled = b_enabled;
					var l_filters: Array = o.filters;
					if(!b_enabled)
						BitmapFilterUtils.addFilterTo(o, sm_dimFilter);
					else
						BitmapFilterUtils.removeFilterFrom(o, sm_dimFilter);
				}
			}
		}
	}
}