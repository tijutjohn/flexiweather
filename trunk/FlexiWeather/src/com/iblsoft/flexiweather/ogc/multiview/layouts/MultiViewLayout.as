package com.iblsoft.flexiweather.ogc.multiview.layouts
{
	import mx.events.DragEvent;
	import spark.components.supportClasses.GroupBase;
	import spark.layouts.ColumnAlign;
	import spark.layouts.RowAlign;
	import spark.layouts.TileLayout;
	import spark.layouts.TileOrientation;
	import spark.layouts.supportClasses.DropLocation;

	public class MultiViewLayout extends TileLayout
	{
		override public function set columnAlign(value: String): void
		{
//			super.columnAlign = ColumnAlign.JUSTIFY_USING_WIDTH;
			super.columnAlign = ColumnAlign.LEFT;
		}

		override public function set rowAlign(value: String): void
		{
//			super.rowAlign = RowAlign.JUSTIFY_USING_HEIGHT;
			super.rowAlign = RowAlign.TOP;
		}

		public function MultiViewLayout()
		{
			super();
//			columnAlign =  ColumnAlign.JUSTIFY_USING_WIDTH;
//			rowAlign =  RowAlign.JUSTIFY_USING_HEIGHT;
			columnAlign = ColumnAlign.LEFT;
			rowAlign = RowAlign.TOP;
		}

		override public function updateDisplayList(unscaledWidth: Number, unscaledHeight: Number): void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}

		override protected function calculateDropIndex(x: Number, y: Number): int
		{
			var dropIndex: int = super.calculateDropIndex(x, y);
			var colWidth: int = columnWidth;
			var rowHeight: int = rowHeight;
			var xStart: Number = x - paddingLeft;
			var yStart: Number = y - paddingTop;
			var column: int = Math.floor(xStart / (colWidth + horizontalGap));
			var row: int = Math.floor(yStart / (rowHeight + verticalGap));
			// Check whether x is closer to left column or right column:
			var midColumnLine: Number;
			var midRowLine: Number
			var rowOrientation: Boolean = orientation == TileOrientation.ROWS;
			if (rowOrientation)
			{
				// Mid-line is at the middle of the cell
				midColumnLine = (column + 1) * (colWidth + horizontalGap) - horizontalGap - colWidth / 2;
				// Mid-line is at the middle of the gap between the rows
				midRowLine = (row + 1) * (rowHeight + verticalGap) - verticalGap / 2;
			}
			else
			{
				// Mid-line is at the middle of the gap between the columns
				midColumnLine = (column + 1) * (colWidth + horizontalGap) - horizontalGap / 2;
				// Mid-line is at the middle of the cell
				midRowLine = (row + 1) * (rowHeight + verticalGap) - verticalGap - rowHeight / 2;
			}
//			if (xStart > midColumnLine)
//				column++;
//			if (yStart > midRowLine)
//				row++;
			// Limit row and column, if any one is too far from the drop location
			// And there is white space
			if (column > columnCount || row > rowCount)
			{
				row = rowCount;
				column = columnCount;
			}
			if (column < 0)
				column = 0;
			if (row < 0)
				row = 0;
			if (rowOrientation)
			{
				if (row >= rowCount)
					row = rowCount - 1;
			}
			else
			{
				if (column >= columnCount)
					column = columnCount - 1;
			}
//			var result:Array = calculateDropCellIndex(x, y);
//			var row:int = result[0]; 
//			var column:int = result[1]; 
			var index: int;
			if (orientation == TileOrientation.ROWS)
				index = row * columnCount + column;
			else
				index = column * rowCount + row;
			var layoutTarget: GroupBase = target;
			var count: int = layoutTarget.numElements;
			if (index > count)
				index = count;
			return index;
		}

		override public function calculateDropLocation(dragEvent: DragEvent): DropLocation
		{
			var dropLocation: DropLocation = super.calculateDropLocation(dragEvent);
			return dropLocation;
		}
	}
}
