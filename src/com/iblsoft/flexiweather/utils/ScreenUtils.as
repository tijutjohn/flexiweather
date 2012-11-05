package com.iblsoft.flexiweather.utils
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.filters.BitmapFilter;
	import flash.geom.Point;
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;

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

		public static function moveSpriteToButHideWhenNotFullOnScreen(c: DisplayObject, pt: Point): void
		{
			var f_sw: Number = FlexGlobals.topLevelApplication.screen.width;
			var f_sh: Number = FlexGlobals.topLevelApplication.screen.height;
			c.x = pt.x;
			c.y = pt.y;
			c.visible = true;
			if (c.x + c.width > f_sw)
				c.visible = false;
			if (c.y + c.height > f_sh)
				c.visible = false;
			if (c.x < 0)
				c.visible = false;
			if (c.y < 0)
				c.visible = false;
		}

		public static function moveSpriteToButKeepFullyOnScreen(c: DisplayObject, pt: Point): void
		{
			var f_sw: Number = FlexGlobals.topLevelApplication.screen.width;
			var f_sh: Number = FlexGlobals.topLevelApplication.screen.height;
			c.x = pt.x;
			c.y = pt.y;
			if (c.x + c.width > f_sw)
				c.x = f_sw - c.width;
			if (c.y + c.height > f_sh)
				c.y = f_sh - c.height;
			if (c.x < 0)
				c.x = 0;
			if (c.y < 0)
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
