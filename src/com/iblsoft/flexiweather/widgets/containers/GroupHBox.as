package com.iblsoft.flexiweather.widgets.containers
{
	import mx.containers.BoxDirection;
	import spark.layouts.HorizontalLayout;
	import spark.layouts.supportClasses.LayoutBase;

	[Exclude(name = "layout", kind = "property")]
	public class GroupHBox extends GroupBox
	{
		private function get horizontalLayout(): HorizontalLayout
		{
			return HorizontalLayout(layout);
		}

		//--------------------------------------------------------------------------
		//
		//  Properties
		//
		//--------------------------------------------------------------------------
		//----------------------------------
		//  gap
		//----------------------------------
		[Inspectable(category = "General", defaultValue = "6")]
		/**
		 *  @copy spark.layouts.HorizontalLayout#gap
		 *
		 *  @default 6
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion Flex 4
		 */
		public function get gap(): int
		{
			return horizontalLayout.gap;
		}

		/**
		 *  @private
		 */
		public function set gap(value: int): void
		{
			horizontalLayout.gap = value;
		}

		//----------------------------------
		//  columnCount
		//----------------------------------
		[Bindable("propertyChange")]
		[Inspectable(category = "General")]
		/**
		 *  @copy spark.layouts.HorizontalLayout#columnCount
		 *
		 *  @default -1
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion Flex 4
		 */
		public function get columnCount(): int
		{
			return horizontalLayout.columnCount;
		}

		//----------------------------------
		//  paddingLeft
		//----------------------------------
		[Inspectable(category = "General", defaultValue = "0.0")]
		/**
		 *  @copy spark.layouts.HorizontalLayout#paddingLeft
		 *
		 *  @default 0
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion Flex 4
		 */
		public function get paddingLeft(): Number
		{
			return horizontalLayout.paddingLeft;
		}

		/**
		 *  @private
		 */
		public function set paddingLeft(value: Number): void
		{
			horizontalLayout.paddingLeft = value;
		}

		//----------------------------------
		//  paddingRight
		//----------------------------------
		[Inspectable(category = "General", defaultValue = "0.0")]
		/**
		 *  @copy spark.layouts.HorizontalLayout#paddingRight
		 *
		 *  @default 0
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion Flex 4
		 */
		public function get paddingRight(): Number
		{
			return horizontalLayout.paddingRight;
		}

		/**
		 *  @private
		 */
		public function set paddingRight(value: Number): void
		{
			horizontalLayout.paddingRight = value;
		}

		//----------------------------------
		//  paddingTop
		//----------------------------------
		[Inspectable(category = "General", defaultValue = "0.0")]
		/**
		 *  @copy spark.layouts.HorizontalLayout#paddingTop
		 *
		 *  @default 0
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion Flex 4
		 */
		public function get paddingTop(): Number
		{
			return horizontalLayout.paddingTop;
		}

		/**
		 *  @private
		 */
		public function set paddingTop(value: Number): void
		{
			horizontalLayout.paddingTop = value;
		}

		//----------------------------------
		//  paddingBottom
		//----------------------------------
		[Inspectable(category = "General", defaultValue = "0.0")]
		/**
		 *  @copy spark.layouts.HorizontalLayout#paddingBottom
		 *
		 *  @default 0
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion Flex 4
		 */
		public function get paddingBottom(): Number
		{
			return horizontalLayout.paddingBottom;
		}

		/**
		 *  @private
		 */
		public function set paddingBottom(value: Number): void
		{
			horizontalLayout.paddingBottom = value;
		}

		//----------------------------------
		//  requestedMaxColumnCount
		//----------------------------------
		[Inspectable(category = "General")]
		/**
		 *  @copy spark.layouts.HorizontalLayout#requestedMaxColumnCount
		 *
		 *  @default -1
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 2.5
		 *  @productversion Flex 4.5
		 */
		public function get requestedMaxColumnCount(): int
		{
			return horizontalLayout.requestedMaxColumnCount;
		}

		/**
		 *  @private
		 */
		public function set requestedMaxColumnCount(value: int): void
		{
			horizontalLayout.requestedMaxColumnCount = value;
		}

		//----------------------------------
		//  requestedMinColumnCount
		//----------------------------------
		[Inspectable(category = "General")]
		/**
		 *  @copy spark.layouts.HorizontalLayout#requestedMinColumnCount
		 *
		 *  @default -1
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 2.5
		 *  @productversion Flex 4.5
		 */
		public function get requestedMinColumnCount(): int
		{
			return horizontalLayout.requestedMinColumnCount;
		}

		/**
		 *  @private
		 */
		public function set requestedMinColumnCount(value: int): void
		{
			horizontalLayout.requestedMinColumnCount = value;
		}

		//----------------------------------
		//  requestedColumnCount
		//----------------------------------
		[Inspectable(category = "General")]
		/**
		 *  @copy spark.layouts.HorizontalLayout#requestedColumnCount
		 *
		 *  @default -1
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion Flex 4
		 */
		public function get requestedColumnCount(): int
		{
			return horizontalLayout.requestedColumnCount;
		}

		/**
		 *  @private
		 */
		public function set requestedColumnCount(value: int): void
		{
			horizontalLayout.requestedColumnCount = value;
		}

		//----------------------------------
		//  columnHeight
		//----------------------------------
		[Inspectable(category = "General")]
		/**
		 * @copy spark.layouts.HorizontalLayout#columnWidth
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion Flex 4
		 */
		public function get columnWidth(): Number
		{
			return horizontalLayout.columnWidth;
		}

		/**
		 *  @private
		 */
		public function set columnWidth(value: Number): void
		{
			horizontalLayout.columnWidth = value;
		}

		//----------------------------------
		//  variablecolumnHeight
		//----------------------------------
		[Inspectable(category = "General", enumeration = "true,false", defaultValue = "true")]
		/**
		 * @copy spark.layouts.HorizontalLayout#variableColumnWidth
		 *
		 *  @default true
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion Flex 4
		 */
		public function get variableColumnWidth(): Boolean
		{
			return horizontalLayout.variableColumnWidth;
		}

		/**
		 *  @private
		 */
		public function set variableColumnWidth(value: Boolean): void
		{
			horizontalLayout.variableColumnWidth = value;
		}

		//----------------------------------
		//  horizontalAlign
		//----------------------------------
		[Inspectable(category = "General", enumeration = "left,right,center", defaultValue = "left")]
		/**
		 *  @copy spark.layouts.HorizontalLayout#horizontalAlign
		 *
		 *  @default "left"
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion Flex 4
		 */
		public function get horizontalAlign(): String
		{
			return horizontalLayout.horizontalAlign;
		}

		/**
		 *  @private
		 */
		public function set horizontalAlign(value: String): void
		{
			horizontalLayout.horizontalAlign = value;
		}

		//----------------------------------
		//  verticalAlign
		//----------------------------------
		[Inspectable(category = "General", enumeration = "top,bottom,middle,justify,contentJustify,baseline", defaultValue = "top")]
		/**
		 *  @copy spark.layouts.HorizontalLayout#verticalAlign
		 *
		 *  @default "top"
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion Flex 4
		 */
		public function get verticalAlign(): String
		{
			return horizontalLayout.verticalAlign;
		}

		/**
		 *  @private
		 */
		public function set verticalAlign(value: String): void
		{
			horizontalLayout.verticalAlign = value;
		}

		//----------------------------------
		//  firstIndexInView
		//----------------------------------
		[Bindable("indexInViewChanged")]
		[Inspectable(category = "General")]
		/**
		 *  @copy spark.layouts.HorizontalLayout#firstIndexInView
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion Flex 4
		 */
		public function get firstIndexInView(): int
		{
			return horizontalLayout.firstIndexInView;
		}

		//----------------------------------
		//  lastIndexInView
		//----------------------------------
		[Bindable("indexInViewChanged")]
		[Inspectable(category = "General")]
		/**
		 * @copy spark.layouts.HorizontalLayout#lastIndexInView
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion Flex 4
		 */
		public function get lastIndexInView(): int
		{
			return horizontalLayout.lastIndexInView;
		}

		//--------------------------------------------------------------------------
		//
		//  Overridden Properties
		//
		//--------------------------------------------------------------------------
		//----------------------------------
		//  layout
		//----------------------------------    
		/**
		 *  @private
		 */
		override public function set layout(value: LayoutBase): void
		{
			throw(new Error(resourceManager.getString("components", "layoutReadOnly")));
		}

		public function GroupHBox()
		{
			super();
		}

		override protected function childrenCreated(): void
		{
			super.childrenCreated();
			super.layout = new HorizontalLayout();
		}
	}
}
