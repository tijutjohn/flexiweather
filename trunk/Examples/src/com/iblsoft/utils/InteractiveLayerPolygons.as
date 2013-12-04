package com.iblsoft.utils
{
	import com.iblsoft.flexiweather.ogc.kml.features.Point;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import mx.collections.ArrayCollection;
	import mx.core.mx_internal;
	import spark.primitives.Graphic;

	public class InteractiveLayerPolygons extends InteractiveLayer
	{
		protected var ma_polygons: ArrayCollection;
		protected var ma_currentPoints: ArrayCollection;
		protected var mb_polygonCompleted: Boolean;
		protected var m_currentCoord: Coord;

		public function InteractiveLayerPolygons(container: InteractiveWidget = null)
		{
			super(container);
			ma_currentPoints = new ArrayCollection();
			ma_polygons = new ArrayCollection();
			mb_polygonCompleted = true;
		}

		public function get polygons(): ArrayCollection
		{
			return ma_polygons;
		}

		protected function moveToCoord(graphics: Graphics, coord: Coord): void
		{
			var p0: flash.geom.Point = container.coordToPoint(coord);
			graphics.moveTo(p0.x, p0.y);
			m_currentCoord = coord;
		}

		protected function lineToCoord(graphics: Graphics, coord: Coord): void
		{
			var a_coords: Array = Coord.interpolateGreatArc(m_currentCoord, coord, distanceValidator);
			for each (var c: Coord in a_coords)
			{
				var p: flash.geom.Point = container.coordToPoint(c);
				graphics.lineTo(p.x, p.y);
			}
			m_currentCoord = coord;
		}

		protected function distanceValidator(c1: Coord, c2: Coord): Boolean
		{
			var f_distance: Number = c1.distanceTo(c2);
			return (f_distance < 100);
		}

		override public function draw(graphics: Graphics): void
		{
			drawStaticPart(graphics);
			drawLastSegment(graphics);
			super.draw(graphics);
		}

		public function clearPolygons(): void
		{
			ma_polygons.removeAll();
			ma_currentPoints.removeAll();
			mb_polygonCompleted = true;
			invalidateDynamicPart(true);
		}

		public function clearRecentPolygon(): void
		{
			if (!mb_polygonCompleted)
			{
				ma_currentPoints.removeAll();
				mb_polygonCompleted = true;
				invalidateDynamicPart(true);
				return;
			}
			if (ma_polygons.length > 0)
			{
				ma_polygons.removeItemAt(ma_polygons.length - 1);
				invalidateDynamicPart(true);
			}
		}

		protected function drawCompletedPolygons(graphics: Graphics): void
		{
			graphics.lineStyle(2, 0xff0000, 0.7, true);
			for each (var a_polygonPoints: ArrayCollection in ma_polygons)
			{
				moveToCoord(graphics, a_polygonPoints[0]);
				for each (var c1: Coord in a_polygonPoints)
				{
					lineToCoord(graphics, c1);
				}
				lineToCoord(graphics, a_polygonPoints[0]);
			}
		}

		protected function drawStaticPart(graphics: Graphics): void
		{
			graphics.clear();
			drawCompletedPolygons(graphics);
			if (mb_polygonCompleted)
				graphics.lineStyle(2, 0xff0000, 0.7, true);
			else
				graphics.lineStyle(2, 0x00ff00, 0.7, true);
			if (ma_currentPoints.length > 0)
			{
				moveToCoord(graphics, ma_currentPoints[0])
				for each (var c1: Coord in ma_currentPoints)
				{
					lineToCoord(graphics, c1);
				}
			}
		}

		protected function drawLastSegment(graphics: Graphics): void
		{
			if (ma_currentPoints.length > 0)
				lineToCoord(graphics, ma_currentPoints[0]);
		}

		override public function onMouseClick(event: MouseEvent): Boolean
		{
			if (event.altKey || event.shiftKey || event.ctrlKey)
				return false;
			var c: Coord = container.pointToCoord(event.localX, event.localY);
			ma_currentPoints.addItem(c);
			mb_polygonCompleted = false;
			invalidateDynamicPart(true);
			return true;
		}

		override public function onMouseDoubleClick(event: MouseEvent): Boolean
		{
			mb_polygonCompleted = true;
			if (ma_currentPoints.length > 2)
			{
				ma_polygons.addItem(ma_currentPoints);
				ma_currentPoints = new ArrayCollection();
			}
			else
				ma_currentPoints.removeAll();
			invalidateDynamicPart(true);
			return true;
		}

		override public function onMouseMove(event: MouseEvent): Boolean
		{
			if (mb_polygonCompleted)
				return false;
			drawStaticPart(graphics);
			if (ma_currentPoints.length > 0)
			{
				var x: Number = event.localX;
				var y: Number = event.localY;
				lineToCoord(graphics, container.pointToCoord(x, y));
				//var p: flash.geom.Point = new flash.geom.Point(x, y);
				//graphics.lineTo(p.x, p.y);
				drawLastSegment(graphics);
			}
			return true;
		}

		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			invalidateDynamicPart(true);
		}
	}
}
