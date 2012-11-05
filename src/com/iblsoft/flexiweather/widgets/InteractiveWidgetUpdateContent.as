package com.iblsoft.flexiweather.widgets
{

	public class InteractiveWidgetUpdateContent
	{
		public static var CRS_CHANGED: int = 1;
		public static var VIEW_BBOX_MOVED: int = 2;
		public static var VIEW_BBOX_SIZE_CHANGED: int = 4;
		public static var LAYER_ORDER_CHANGED: int = 8;
		/**
		 * If layer was added or removed from Interactive widget
		 */
		public static var LAYERS_CHANGED: int = 16;
		/**
		 * This includes all properties change (visible, alpha, style....)
		 */
		public static var LAYER_PROPERTY_CHANGED: int = 32;
		private var _flag: uint;

		public function get anyChange(): Boolean
		{
			return _flag != 0;
		}

		public function get noChange(): Boolean
		{
			return _flag == 0;
		}

		public function InteractiveWidgetUpdateContent(statusFlag: uint)
		{
			_flag = statusFlag;
		}
	}
}
