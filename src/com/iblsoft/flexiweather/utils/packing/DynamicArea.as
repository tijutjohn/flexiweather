package com.iblsoft.flexiweather.utils.packing
{
	import flash.display.Graphics;
	import flash.geom.Rectangle;

	public class DynamicArea
	{
		public var area: Rectangle;
		public var itemArea: Rectangle;
		public var empty: Boolean = true;
		public var parentArea: DynamicArea;
		public var firstArea: DynamicArea;
		public var secondArea: DynamicArea;

		public function DynamicArea(_parentArea: DynamicArea)
		{
			parentArea = _parentArea
		}

		public function create(totalArea: Rectangle): void
		{
			area = totalArea;
			firstArea = new DynamicArea(this);
			secondArea = new DynamicArea(this);
		}

		public function createFromItem(item: Rectangle, firstAreaDirection: String, secondAreaDirection: String, totalArea: Rectangle = null): void
		{
			if (totalArea)
				area = totalArea;
			empty = false;
			firstArea = new DynamicArea(this);
			secondArea = new DynamicArea(this);
			creatAreas(item, firstAreaDirection + "-" + secondAreaDirection);
		}

		private function creatAreas(item: Rectangle, directions: String): void
		{
			var newArea: Rectangle;
			var left: Number = area.x;
			var right: Number = area.x + area.width;
			var top: Number = area.y;
			var bottom: Number = area.y + area.height;
			var horizontalItemPos: Number;
			var verticalItemPos: Number;
			switch (directions)
			{
				//primary horizontal cases
				case "right-down":
				{
					/**
					 * -----------
					 * | i |  1  |
					 * -----------
					 * |    2    |
					 * -----------
					 */
					horizontalItemPos = left + item.width;
					verticalItemPos = top + item.height;
					firstArea.create(new Rectangle(horizontalItemPos, top, area.width - item.width, item.height));
					secondArea.create(new Rectangle(left, verticalItemPos, area.width, area.height - item.height));
					itemArea = new Rectangle(left, top, item.width, item.height);
					break;
				}
				case "left-down":
				{
					/**
					 * -----------
					 * | 1  | i  |
					 * -----------
					 * |    2    |
					 * -----------
					 */
					horizontalItemPos = right - item.width;
					verticalItemPos = top + item.height;
					firstArea.create(new Rectangle(left, top, horizontalItemPos - left, item.height));
					secondArea.create(new Rectangle(left, verticalItemPos, area.width, area.height - item.height));
					itemArea = new Rectangle(horizontalItemPos, top, item.width, item.height);
					break;
				}
				case "right-up":
				{
					/**
					 * -----------
					 * |    2    |
					 * -----------
					 * | i |  1  |
					 * -----------
					 */
					horizontalItemPos = left + item.width;
					verticalItemPos = bottom - item.height;
					firstArea.create(new Rectangle(horizontalItemPos, verticalItemPos, area.width - item.width, item.height));
					secondArea.create(new Rectangle(left, top, area.width, area.height - item.height));
					itemArea = new Rectangle(left, verticalItemPos, item.width, item.height);
					break;
				}
				case "left-up":
				{
					/**
					 * -----------
					 * |    2    |
					 * -----------
					 * |  1  | i |
					 * -----------
					 */
					horizontalItemPos = right - item.width;
					verticalItemPos = bottom - item.height;
					firstArea.create(new Rectangle(left, verticalItemPos, area.width - item.width, item.height));
					secondArea.create(new Rectangle(left, top, area.width, area.height - item.height));
					itemArea = new Rectangle(horizontalItemPos, verticalItemPos, item.width, item.height);
					break;
				}
				//primary vertical cases
				case "down-right":
				{
					/**
					 * ---------
					 * | i |   |
					 * |---| 2 |
					 * | 1 |   |
					 * ---------
					 */
					horizontalItemPos = left + item.width;
					verticalItemPos = top + item.height;
					firstArea.create(new Rectangle(left, verticalItemPos, item.width, area.height - item.height));
					secondArea.create(new Rectangle(horizontalItemPos, top, area.width - item.width, area.height));
					itemArea = new Rectangle(left, top, item.width, item.height);
					break;
				}
				case "down-left":
				{
					/**
					 * ---------
					 * |   | i |
					 * | 2 |---|
					 * |   | 1 |
					 * ---------
					 */
					horizontalItemPos = right - item.width;
					verticalItemPos = top + item.height;
					firstArea.create(new Rectangle(horizontalItemPos, verticalItemPos, item.width, area.height - item.height));
					secondArea.create(new Rectangle(left, top, area.width - item.width, area.height));
					itemArea = new Rectangle(horizontalItemPos, top, item.width, item.height);
					break;
				}
				case "up-right":
				{
					/**
					 * ---------
					 * | 1 |   |
					 * |---| 2 |
					 * | i |   |
					 * ---------
					 */
					horizontalItemPos = left + item.width;
					verticalItemPos = bottom - item.height;
					firstArea.create(new Rectangle(left, top, item.width, area.height - item.height));
					secondArea.create(new Rectangle(horizontalItemPos, top, area.width - item.width, area.height));
					itemArea = new Rectangle(left, verticalItemPos, item.width, item.height);
					break;
				}
				case "up-left":
				{
					/**
					 * ---------
					 * |   | 1 |
					 * | 2 |---|
					 * |   | i |
					 * ---------
					 */
					horizontalItemPos = right - item.width;
					verticalItemPos = bottom - item.height;
					firstArea.create(new Rectangle(horizontalItemPos, top, item.width, area.height - item.height));
					secondArea.create(new Rectangle(left, top, area.width - item.width, area.height));
					itemArea = new Rectangle(horizontalItemPos, verticalItemPos, item.width, item.height);
					break;
				}
			}
		}

		public function findSuitableArea(item: Rectangle, searchIn: String, areas: Array): void
		{
			var areaD: Number;
			var itemD: Number;
			var density: Number;
			if (searchIn == "first" || searchIn == "both")
			{
				if (firstArea)
				{
					if (firstArea.empty && isSuitableArea(firstArea.area, item))
					{
						areaD = firstArea.area.width * firstArea.area.height;
						itemD = item.width * item.height;
						density = itemD / areaD;
						areas.push({area: firstArea, density: density});
					}
					firstArea.findSuitableArea(item, searchIn, areas);
				}
			}
			if (searchIn == "second" || searchIn == "both")
			{
				if (secondArea)
				{
					if (secondArea.empty && isSuitableArea(secondArea.area, item))
					{
						areaD = secondArea.area.width * secondArea.area.height;
						itemD = item.width * item.height;
						density = itemD / areaD;
						areas.push({area: secondArea, density: density});
					}
					secondArea.findSuitableArea(item, searchIn, areas);
				}
			}
		}

		private function isSuitableArea(area: Rectangle, item: Rectangle): Boolean
		{
			if (area && area.width >= item.width && area.height >= item.height)
				return true;
			return false;
		}

		public function draw(gr: Graphics): void
		{
			gr.lineStyle(1, 0xff0000);
			if (area)
				gr.drawRect(area.x, area.y, area.width, area.height);
			if (firstArea)
				firstArea.draw(gr);
			if (secondArea)
				secondArea.draw(gr);
		}

		public function getBiggestItemArea(rectangle: Rectangle): void
		{
			if (!empty)
			{
				if (itemArea.left < rectangle.left || itemArea.width == 0)
					rectangle.left = itemArea.left;
				if (itemArea.right > rectangle.right || itemArea.width == 0)
					rectangle.right = itemArea.right;
				if (itemArea.top < rectangle.top || itemArea.height == 0)
					rectangle.top = itemArea.top;
				if (itemArea.bottom > rectangle.bottom || itemArea.height == 0)
					rectangle.bottom = itemArea.bottom;
			}
			if (firstArea)
				firstArea.getBiggestItemArea(rectangle);
			if (secondArea)
				secondArea.getBiggestItemArea(rectangle);
		}
	}
}
