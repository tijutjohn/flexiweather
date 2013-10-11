package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.proj.Coord;
	import flash.display.Graphics;
	import flash.geom.Point;

	public class InteractiveLayerNorthIndicator extends InteractiveLayer
	{
		private var _northIndicator: NorthIndicator;
		private var _currentDirection: Number;
		private var _recomputeNeeded: Boolean;
		private var _indicatorPosition: Point;

		public function set indicatorPosition(point: Point): void
		{
			_indicatorPosition = point;
			onIndicatorPositionChanged();
		}

		public function InteractiveLayerNorthIndicator(container: InteractiveWidget = null)
		{
			super(container);
			_indicatorPosition = new Point(40, 40);
		}
		
		override protected function createChildren(): void
		{
			super.createChildren();
			
			if (!_northIndicator)
				_northIndicator = new NorthIndicator();
		}

		override protected function childrenCreated(): void
		{
			if (!_northIndicator.parent)
				addChild(_northIndicator);
			
			mouseEnabled = false;
			mouseChildren = false;
		}

		override protected function commitProperties(): void
		{
			super.commitProperties();
		}

		public function onIndicatorPositionChanged(): void
		{
			invalidate();
		}

		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			invalidate();
		}

		private function invalidate(): void
		{
			findDirection();
			invalidateDynamicPart();
		}

		private function get northExists(): Boolean
		{
			return coordExists(new Coord('CRS:84', 90, 0));
		}

		private function get southExists(): Boolean
		{
			return coordExists(new Coord('CRS:84', -90, 0));
		}

		private function coordExists(coord: Coord): Boolean
		{
			var p: Point = container.coordToPoint(coord);
			return (p != null);
		}

		private function findDirection(): void
		{
			if (!container)
				return;
			
			var startCoord: Coord = container.pointToCoord(_indicatorPosition.x, _indicatorPosition.y);
			if (!startCoord)
				return;
			startCoord = startCoord.toLaLoCoord();
			var endCoord: Coord;
			var nextCoord: Coord;
			if (northExists)
			{
				nextCoord = new Coord('CRS:84', startCoord.x, startCoord.y + (90 - startCoord.y) / 2);
				if (_northIndicator)
					_northIndicator.text = "N";
			}
			else if (southExists)
			{
				nextCoord = new Coord('CRS:84', startCoord.x, startCoord.y + (-90 - startCoord.y) / 2);
				if (_northIndicator)
					_northIndicator.text = "S";
			}
			var indicatorPosition: Point = container.coordToPoint(startCoord);
			var nextCoordPoint: Point = container.coordToPoint(nextCoord);
			//find angle between indicatorPoint and nextCoordPoint
			var w: int = nextCoordPoint.x - indicatorPosition.x;
			var h: int = nextCoordPoint.y - indicatorPosition.y;
			var angle: Number = Math.atan2(h, w);
			_currentDirection = angle * 180 / Math.PI;
		}

		override public function draw(graphics: Graphics): void
		{
			super.draw(graphics);
			
			if (_northIndicator)
			{
				if (_indicatorPosition)
				{
					_northIndicator.x = _indicatorPosition.x;
					_northIndicator.y = _indicatorPosition.y;
				}
				_northIndicator.rotation = _currentDirection
			}
		}
	}
}
import flash.display.Graphics;
import flash.filters.GlowFilter;
import flash.geom.Point;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import mx.core.UIComponent;

class NorthIndicator extends UIComponent
{
	private var _tfParent: UIComponent;
	private var _textfield: TextField;
	private var _perimeter: int;
	private var _text: String;
	private var _textChanged: Boolean;
	private var _glow: GlowFilter;

	public function set text(value: String): void
	{
		_text = value;
		_textChanged = true;
		invalidateProperties();
	}
	private var _rotationChanged: Boolean;

	override public function set rotation(value: Number): void
	{
		super.rotation = value;
		_rotationChanged = true;
		invalidateProperties();
	}

	public function NorthIndicator()
	{
		_perimeter = 25;
		text = 'N';
	}

	override protected function createChildren(): void
	{
		super.createChildren();
		_tfParent = new UIComponent();
		_textfield = new TextField();
		_glow = new GlowFilter(0xffffff, 0.7);
	}

	override protected function childrenCreated(): void
	{
		super.childrenCreated();
		addChild(_tfParent);
		_tfParent.addChild(_textfield);
		filters = [_glow];
		draw();
	}

	override protected function commitProperties(): void
	{
		super.commitProperties();
		if (_textfield && _textChanged)
		{
			_textfield.text = _text;
			_textfield.embedFonts = true;
			var frm: TextFormat = _textfield.getTextFormat();
			frm.size = 13;
			frm.color = 0x00000;
			frm.font = 'defaultFontMX';
			_textfield.setTextFormat(frm);
			_textfield.autoSize = TextFieldAutoSize.LEFT;
			_textfield.width = 40;
			_textfield.height = 40;
			_textfield.x = _textfield.textWidth / -2;
			_textfield.y = _textfield.textHeight / -2;
			_tfParent.x = _perimeter + _textfield.textWidth / 2 + 5;
			_tfParent.y = 0
			_textChanged = false;
		}
		if (_rotationChanged && _tfParent)
		{
			_tfParent.rotation = -rotation;
			_rotationChanged = false;
		}
	}

	public function draw(): void
	{
		drawStar(_perimeter, _perimeter * 0.25);
	}

	private function drawTriangle(clr: uint, p1: Point, p2: Point, p3: Point): void
	{
		var gr: Graphics = graphics;
		gr.lineStyle(1, 0);
		gr.beginFill(clr);
		gr.moveTo(p1.x, p1.y);
		gr.lineTo(p2.x, p2.y);
		gr.lineTo(p3.x, p3.y);
		gr.lineTo(p1.x, p1.y);
		gr.endFill();
	}

	private function drawStar(perimeter: int, innerPerimeter: int): void
	{
		var gr: Graphics = graphics;
		var ip1: Point = new Point(innerPerimeter * Math.cos(315 * Math.PI / 180), innerPerimeter * Math.sin(315 * Math.PI / 180));
		var ip2: Point = new Point(innerPerimeter * Math.cos(225 * Math.PI / 180), innerPerimeter * Math.sin(225 * Math.PI / 180));
		var ip3: Point = new Point(innerPerimeter * Math.cos(135 * Math.PI / 180), innerPerimeter * Math.sin(135 * Math.PI / 180));
		var ip4: Point = new Point(innerPerimeter * Math.cos(45 * Math.PI / 180), innerPerimeter * Math.sin(45 * Math.PI / 180));
		var center: Point = new Point(0, 0);
		var rightPoint: Point = new Point(perimeter, 0);
		var leftPoint: Point = new Point(-perimeter, 0);
		var topPoint: Point = new Point(0, -perimeter);
		var bottomPoint: Point = new Point(0, perimeter);
		drawTriangle(0xffffff, rightPoint, ip1, center);
		drawTriangle(0xaaaaaa, topPoint, center, ip1);
		drawTriangle(0xffffff, topPoint, ip2, center);
		drawTriangle(0xaaaaaa, leftPoint, center, ip2);
		drawTriangle(0xffffff, leftPoint, ip3, center);
		drawTriangle(0xaaaaaa, bottomPoint, center, ip3);
		drawTriangle(0xffffff, bottomPoint, ip4, center);
		drawTriangle(0xaaaaaa, rightPoint, center, ip4);
	}
}
