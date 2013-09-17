package com.iblsoft.flexiweather.utils
{
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.filters.BitmapFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	
	import spark.primitives.Rect;

	public class ScreenUtils
	{
		public static var stage: Stage;

		public static function get stageWidth(): int
		{
			if (stage)
				return stage.stageWidth;
			return 0;
		}

		public static function get stageHeight(): int
		{
			if (stage)
				return stage.stageHeight;
			return 0;
		}

		public static function willBeFullVisible(c: DisplayObject, pt: Point, container: InteractiveWidget = null): Boolean
		{
//			trace("moveSpriteToButHideWhenNotFullOnScreen: " + pt);
			
			var f_screenTop: Number;
			var f_screenLeft: Number;
			var f_screenRight: Number;
			var f_screenBottom: Number;
			
			if (!container)
			{
				f_screenTop = 0;
				f_screenLeft = 0;
				f_screenRight = FlexGlobals.topLevelApplication.screen.width;
				f_screenBottom = FlexGlobals.topLevelApplication.screen.height;
			} else {
				var topLeft: Point = new Point(0,0);
				var bottomRight: Point = new Point(container.width, container.height);
				
				var tl: Point = container.localToGlobal(topLeft);
				var br: Point = container.localToGlobal(bottomRight);
				
//				trace("moveSpriteToButHideWhenNotFullOnScreen: " + topLeft + " , " + tl);
//				trace("moveSpriteToButHideWhenNotFullOnScreen: " + bottomRight + " , " + br);
				
				f_screenLeft = tl.x;
				f_screenTop = tl.y;
				f_screenRight = br.x;
				f_screenBottom = br.y;
			}
			
			var willBeVisible: Boolean = true;
			
//			var xOutside: int = -2000;
			
			if (pt.x + c.width > f_screenRight)
			{
//				c.x = xOutside;
				willBeVisible = false;
			}
			if (pt.y + c.height > f_screenBottom)
			{
//				c.x = xOutside;
				willBeVisible = false;
			}
			if (pt.x < f_screenLeft)
			{
//				c.x = xOutside;
				willBeVisible = false;
			}
			if (pt.y < f_screenTop)
			{
//				c.x = xOutside;
				willBeVisible = false;
			}
			return willBeVisible;
		}
		public static function moveSpriteToButHideWhenNotFullOnScreen(c: DisplayObject, pt: Point, container: InteractiveWidget = null): void
		{
//			trace("moveSpriteToButHideWhenNotFullOnScreen: " + pt);
			
			var f_screenTop: Number;
			var f_screenLeft: Number;
			var f_screenRight: Number;
			var f_screenBottom: Number;
			
			if (!container)
			{
				f_screenTop = 0;
				f_screenLeft = 0;
				f_screenRight = FlexGlobals.topLevelApplication.screen.width;
				f_screenBottom = FlexGlobals.topLevelApplication.screen.height;
			} else {
				var topLeft: Point = new Point(0,0);
				var bottomRight: Point = new Point(container.width, container.height);
				
				var tl: Point = container.localToGlobal(topLeft);
				var br: Point = container.localToGlobal(bottomRight);
				
//				trace("moveSpriteToButHideWhenNotFullOnScreen: " + topLeft + " , " + tl);
//				trace("moveSpriteToButHideWhenNotFullOnScreen: " + bottomRight + " , " + br);
				
				f_screenLeft = tl.x;
				f_screenTop = tl.y;
				f_screenRight = br.x;
				f_screenBottom = br.y;
			}
			
			c.x = pt.x;
			c.y = pt.y;
			c.visible = true;
			
			var xOutside: int = -2000;
			
			if (c.x + c.width > f_screenRight)
			{
				c.x = xOutside;
				c.visible = false;
			}
			if (c.y + c.height > f_screenBottom)
			{
				c.x = xOutside;
				c.visible = false;
			}
			if (c.x < f_screenLeft)
			{
				c.x = xOutside;
				c.visible = false;
			}
			if (c.y < f_screenTop)
			{
				c.x = xOutside;
				c.visible = false;
			}
		}

		public static function moveSpriteToButKeepFullyOnScreen(c: DisplayObject, pt: Point, container: InteractiveWidget = null): void
		{
			var f_screenTop: Number;
			var f_screenLeft: Number;
			var f_screenRight: Number;
			var f_screenBottom: Number;
			
			if (!container)
			{
				f_screenTop = 0;
				f_screenLeft = 0;
				f_screenRight = FlexGlobals.topLevelApplication.screen.width;
				f_screenBottom = FlexGlobals.topLevelApplication.screen.height;
			} else {
				var topLeft: Point = new Point(0,0);
				var bottomRight: Point = new Point(container.width, container.height);
				
				var tl: Point = container.localToGlobal(topLeft);
				var br: Point = container.localToGlobal(bottomRight);
				
//				trace("moveSpriteToButKeepFullyOnScreen: " + topLeft + " , " + tl);
//				trace("moveSpriteToButKeepFullyOnScreen: " + bottomRight + " , " + br);
				
				f_screenLeft = tl.x;
				f_screenTop = tl.y;
				f_screenRight = br.x;
				f_screenBottom = br.y;
			}
			
			
			c.x = pt.x;
			c.y = pt.y;
			if (c.x + c.width > f_screenRight)
				c.x = f_screenRight - c.width;
			if (c.y + c.height > f_screenBottom)
				c.y = f_screenBottom - c.height;
			if (c.x < f_screenLeft)
				c.x = 0;
			if (c.y < f_screenTop)
				c.y = 0;
		}

		public static function localPointContainedIn(src: DisplayObject, pt: Point, dst: DisplayObject): Boolean
		{
			var ptRemapped: Point = dst.globalToLocal(src.localToGlobal(pt));
			return pt.x >= 0 && pt.x < dst.width && pt.y >= 0 && pt.y < dst.height;
		}

		public static function isVisible(o: DisplayObject): Boolean
		{
			if (o == null)
				return false;
			while (o != null)
			{
				if (!o.visible)
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
				if (o.enabled != b_enabled)
				{
					o.enabled = b_enabled;
					var l_filters: Array = o.filters;
					if (!b_enabled)
						BitmapFilterUtils.addFilterTo(o, sm_dimFilter);
					else
						BitmapFilterUtils.removeFilterFrom(o, sm_dimFilter);
				}
			}
		}
	}
}
