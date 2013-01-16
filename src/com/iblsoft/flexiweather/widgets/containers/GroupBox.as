package com.iblsoft.flexiweather.widgets.containers
{
	import com.iblsoft.flexiweather.widgets.containers.skins.GroupBoxSkin;
	import flash.display.Graphics;
	import flash.display.LineScaleMode;
	import flash.events.Event;
	import flashx.textLayout.formats.VerticalAlign;
	import mx.core.IVisualElement;
	import spark.components.Group;
	import spark.components.Label;
	import spark.components.SkinnableContainer;
	import spark.components.VGroup;
	import spark.core.IDisplayText;
	import spark.layouts.HorizontalLayout;
	import spark.layouts.VerticalLayout;
	import spark.layouts.supportClasses.LayoutBase;
	import spark.primitives.Rect;

	/**
	 *  The background color of the application. This color is used as the stage color for the
	 *  application and the background color for the HTML embed tag.
	 *
	 *  @langversion 3.0
	 *  @playerversion Flash 10
	 *  @playerversion AIR 1.5
	 *  @productversion Flex 4
	 */
	[Style(name = "backgroundColor", type = "uint", format = "Color", inherit = "no", theme = "spark")]
	[Style(name = "borderColor", type = "uint", format = "Color", inherit = "no", theme = "spark")]
	[Style(name = "titleColor", type = "uint", format = "Color", inherit = "no", theme = "spark")]
	public class GroupBox extends SkinnableContainer
	{
		[SkinPart(require = "true")]
		public var contents: Group;
		[SkinPart(require = "true")]
		public var topGroup: Group;
		[SkinPart(require = "true")]
		public var titleDisplay: IDisplayText;
		[SkinPart(require = "true")]
		public var background: Rect;
		[SkinPart(require = "true")]
		public var titleBackground: Rect;
		[SkinPart(require = "true")]
		public var border: Rect;
		private var _captionGap: int;

		[Bindable]
		public function get captionGap(): int
		{
			return _captionGap;
		}

		public function set captionGap(value: int): void
		{
			if (_captionGap != value)
			{
				_captionGap = value;
				if (skin)
					skin.invalidateDisplayList();
			}
		}
		private var _cornerRadius: int = 10;

		[Bindable]
		public function get cornerRadius(): int
		{
			return _cornerRadius;
		}

		public function set cornerRadius(value: int): void
		{
			_cornerRadius = value;
			if (skin)
				skin.invalidateDisplayList();
		}
		//----------------------------------
		//  title
		//----------------------------------
		/**
		 *  @private
		 */
		private var _title: String = "";
		/**
		 *  @private
		 */
		private var titleChanged: Boolean;

		[Bindable]
		[Inspectable(category = "General", defaultValue = "")]
		/**
		 *  Title or caption displayed in the title bar.
		 *
		 *  @default ""
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion Flex 4
		 */
		public function get title(): String
		{
			return _title;
		}

		/**
		 *  @private
		 */
		public function set title(value: String): void
		{
			_title = value;
			if (titleDisplay)
				titleDisplay.text = title;
			if (skin)
				skin.invalidateDisplayList();
		}

		public function GroupBox()
		{
			super();
			setStyle('skinClass', GroupBoxSkin);
			setStyle('backgroundColor', 0xffffff);
		}

		override protected function attachSkin(): void
		{
			super.attachSkin();
		}

		/**
		 *  @private
		 */
		override protected function partAdded(partName: String, instance: Object): void
		{
			super.partAdded(partName, instance);
			if (instance == titleDisplay)
			{
				titleDisplay.text = title;
				invalidateDisplayList();
			}
		}

		override protected function partRemoved(partName: String, instance: Object): void
		{
			super.partRemoved(partName, instance);
		}
	}
}
