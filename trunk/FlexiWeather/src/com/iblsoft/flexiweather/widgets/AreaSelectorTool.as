package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.configuration.ProjectionConfiguration;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.core.UIComponent;

	public class AreaSelectorTool extends InteractiveLayer
	{
		public static const AREA_CREATED: String = 'area created';
		public static const AREA_CANCELLED: String = 'area cancelled';
		private var _areaComponent: AreaRectangle;
		private var _r: CustomRectangle;
		private var _mouseDown: Boolean;
		private var _toolIsCreated: Boolean;
		private var _p: Point;
		private var _projection: Projection;
		private var _projectionConfiguration: ProjectionConfiguration;

		public function set projectionConfiguration(value: ProjectionConfiguration): void
		{
			_projectionConfiguration = value;
			_projection = Projection.getByCfg(value);
		}
		private var _selectedBBox: BBox;

		public function get selectedBBox(): BBox
		{
			return _selectedBBox;
		}

		public function AreaSelectorTool(container: InteractiveWidget = null)
		{
			super(container);
		}

		override protected function createChildren(): void
		{
			super.createChildren();
			_areaComponent = new AreaRectangle();
			addChild(_areaComponent);
		}

		override protected function childrenCreated(): void
		{
			super.childrenCreated();
		}

		/**
		 * on area change update selected BBox
		 * @param b_finalChange
		 *
		 */
		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			super.onAreaChanged(b_finalChange);
			updateRectangleFromViewBBox()
		}

		private function getMousePoint(event: MouseEvent): Point
		{
			var p: Point = new Point(event.stageX, event.stageY);
			p = this.globalToLocal(p);
			return p;
		}

		override public function onMouseDown(event: MouseEvent): Boolean
		{
//			if(!event.ctrlKey && mb_requireCtrlKey || event.shiftKey)
			if (event.ctrlKey || event.shiftKey)
				return false;
//			if(!event.buttonDown)
//				return false;
			
			systemManager.getSandboxRoot().addEventListener(MouseEvent.MOUSE_UP, onMouseUpOutside);
			
			if (_areaComponent.isResizing)
			{
				_areaComponent.mouseEnabled = false;
				_areaComponent.enableSprites(false);
				return false;
			}
			_toolIsCreated = (event.target == _areaComponent);
			_areaComponent.mouseEnabled = _toolIsCreated;
			if (!_toolIsCreated)
			{
				_areaComponent.x = _areaComponent.y = 0;
				_p = getMousePoint(event);
				_r = new CustomRectangle(_p.x, _p.y, 0, 0);
				_mouseDown = true;
				invalidateDynamicPart();
			}
			else
				_areaComponent.startDrag();
			return true;
		}
		private var _lastCreatedRectangle: CustomRectangle;

		private function onMouseUpOutside(event: MouseEvent): void
		{
			onMouseUp(event);
		}
		override public function onMouseUp(event: MouseEvent): Boolean
		{
			systemManager.getSandboxRoot().removeEventListener(MouseEvent.MOUSE_UP, onMouseUpOutside);
			
			if (event.ctrlKey || event.shiftKey)
				return false;
			if (_r == null || _areaComponent.isResizing)
				return false;
			if (!_toolIsCreated)
			{
				//create new rectangle from old one with correct left, top, right, bottom properties (it matters on direction of draggine when zoom rectange is created
				_r = new CustomRectangle(Math.min(_r.left, _r.right), Math.min(_r.top, _r.bottom), Math.abs(_r.left - _r.right), Math.abs(_r.top - _r.bottom));
				_mouseDown = false;
				if ((_r.width) > 5 && (_r.height) > 5)
				{
					findAreaCoordinates();
					_lastCreatedRectangle = _r
					dispatchEvent(new Event(AREA_CREATED));
				}
				else
				{
					_r = _lastCreatedRectangle;
//					dispatchEvent(new Event(AREA_CANCELLED));
					_areaComponent.mouseEnabled = true;
					_areaComponent.enableSprites(true);
					return true;
				}
				_toolIsCreated = true;
				invalidateDynamicPart();
			}
			else
			{
				_areaComponent.stopDrag();
				_r.x += _areaComponent.x;
				_r.y += _areaComponent.y;
				_areaComponent.draw(_r, true);
				_areaComponent.x = _areaComponent.y = 0;
				findAreaCoordinates();
			}
			_areaComponent.mouseEnabled = true;
			_areaComponent.enableSprites(true);
			return true;
		}

		public function clearSelection(): void
		{
			_r = null;
			_areaComponent.draw(new CustomRectangle(0, 0, 0, 0));
		}

		public function createSelection(bbox: BBox): void
		{
			_toolIsCreated = true;
			_selectedBBox = bbox;
			_r = new CustomRectangle();
			updateRectangleFromViewBBox();
			invalidateDisplayList();
		}

		override public function onMouseMove(event: MouseEvent): Boolean
		{
			if (event.ctrlKey || event.shiftKey)
				return false;
			if (_r == null || !_mouseDown || _areaComponent.isResizing)
				return false;
			if (!_toolIsCreated)
			{
				_p = getMousePoint(event);
				_r.width = _p.x - _r.x;
				_r.height = _p.y - _r.y;
				invalidateDynamicPart();
			}
			findAreaCoordinates();
			return true;
		}

		override protected function updateDisplayList(unscaledWidth: Number, unscaledHeight: Number): void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if (_r != null)
				_areaComponent.draw(_r, !_toolIsCreated);
		}

		public function findAreaCoordinates(): void
		{
			if (!_r)
				return;
			var r: Rectangle = container.getViewBBox().toRectangle();
			var w: Number = container.width;
			var h: Number = container.height;
			var bW: Number = r.width;
			var bH: Number = r.height;
			r.width = bW / w * _r.width;
			r.height = bH / h * _r.height;
			r.x = r.x + _r.x / w * bW;
			r.y = r.y + (h - _r.bottom) / h * bH;
			var xMin: Number = Math.min(r.left, r.right);
			var yMin: Number = Math.min(r.top, r.bottom);
			var xMax: Number = Math.max(r.left, r.right);
			var yMax: Number = Math.max(r.top, r.bottom);
			r.left = xMin;
			r.top = yMin;
			r.right = xMax;
			r.bottom = yMax;
			_selectedBBox = BBox.fromRectangle(r);
			var topLeftCoord: Coord = findCoordinates(_selectedBBox.xMin, _selectedBBox.yMax);
			var bottomRightCoord: Coord = findCoordinates(_selectedBBox.xMax, _selectedBBox.yMin);
			var ile: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveLayerEvent.AREA_CHANGED);
			ile.topLeftCoord = topLeftCoord;
			ile.bottomRightCoord = bottomRightCoord;
			dispatchEvent(ile);
		}

		private function updateRectangleFromViewBBox(): void
		{
			if (_r)
			{
				var bbox1: Rectangle = container.getViewBBox().toRectangle();
				var r: BBox = _selectedBBox; //container.getViewBBox().toRectangle();
				var r2: Rectangle = _selectedBBox.toRectangle(); //container.getViewBBox().toRectangle();
				var w: Number = container.width;
				var h: Number = container.height;
				var bW: Number = r.width;
				var bH: Number = r.height;
				var newWidth: Number = r.width * w / bbox1.width;
				var newHeight: Number = r.height * h / bbox1.height;
				var newX: Number = (r2.x - bbox1.x) * w / bbox1.width;
				var newY: Number = h - (r2.y - bbox1.y) * h / bbox1.height
				_r.width = newWidth;
				_r.height = newHeight;
				_r.x = newX;
				_r.y = newY - _r.height;
			}
		}

		public function findCoordinates(x: Number, y: Number): Coord
		{
//			if (_projection)
//			{
////				_projection.
//
//				var c: Coord = m_iw.pointToCoord(event.localX, event.localY).toLaLoCoord();
//			}
			var crs: String = container.getCRS();
			var c: Coord = new Coord(crs, x, y).toLaLoCoord();
			return c;
		}
	}
}
import mx.core.UIComponent;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.display.Graphics;
import flash.geom.Point;
import flash.display.DisplayObject;
import com.iblsoft.flexiweather.widgets.AreaSelectorTool;
import com.iblsoft.flexiweather.ogc.BBox;

class CustomRectangle extends Rectangle
{
	public function CustomRectangle(x: Number = 0, y: Number = 0, width: Number = 0, height: Number = 0)
	{
		super(x, y, width, height);
	}
}

class AreaRectangle extends UIComponent
{
	public var isResizing: Boolean;
	private var _leftEdge: Sprite;
	private var _rightEdge: Sprite;
	private var _topEdge: Sprite;
	private var _bottomEdge: Sprite;
	private var _bottomRightCorner: Sprite;
	private var _currentlyDraggedSprite: Sprite;
	private var leftX: Number;
	private var rightX: Number;
	private var topY: Number;
	private var bottomY: Number;
	private var _r: CustomRectangle;

	public function AreaRectangle()
	{
	}

	override protected function createChildren(): void
	{
		super.createChildren();
		_leftEdge = new Sprite();
		_rightEdge = new Sprite();
		_topEdge = new Sprite();
		_bottomEdge = new Sprite();
		_bottomRightCorner = new Sprite();
		addChild(_leftEdge);
		addChild(_rightEdge);
		addChild(_topEdge);
		addChild(_bottomEdge);
		addChild(_bottomRightCorner);
	}

	public function enableSprites(enable: Boolean): void
	{
		_leftEdge.mouseEnabled = enable;
		_rightEdge.mouseEnabled = enable;
		_topEdge.mouseEnabled = enable;
		_bottomEdge.mouseEnabled = enable;
		_bottomRightCorner.mouseEnabled = enable;
	}

	public function draw(r: CustomRectangle = null, _toolIsCreating: Boolean = false, drawEmptyRectangle: Boolean = false): void
	{
		enableSprites(!_toolIsCreating);
		if (_toolIsCreating && r && r.width == 0 && r.height == 0)
			return;
		if (r)
			_r = r;
		if (_r != null)
		{
			var gr: Graphics = graphics;
			gr.clear();
			if (r)
			{
				leftX = Math.min(_r.x, _r.x + _r.width);
				rightX = Math.max(_r.x, _r.x + _r.width);
				topY = Math.min(_r.y, _r.y + _r.height);
				bottomY = Math.max(_r.y, _r.y + _r.height);
			}
			var lineWidth: int = 5;
			gr.beginFill(0, 0.5);
			gr.drawRect(_r.x, _r.y, _r.width, _r.height);
			gr.endFill();
			gr = _leftEdge.graphics;
			gr.clear();
			gr.lineStyle(lineWidth, 0xFFFFFF);
			gr.moveTo(leftX, topY);
			gr.lineTo(leftX, bottomY);
			gr = _topEdge.graphics;
			gr.clear();
			gr.lineStyle(lineWidth, 0xFFFFFF);
			gr.moveTo(leftX, topY);
			gr.lineTo(rightX, topY);
			gr = _rightEdge.graphics;
			gr.clear();
			gr.lineStyle(lineWidth, 0xFFFFFF);
			gr.moveTo(rightX, topY);
			gr.lineTo(rightX, bottomY);
			gr = _bottomEdge.graphics;
			gr.clear();
			gr.lineStyle(lineWidth, 0xFFFFFF);
			gr.moveTo(leftX, bottomY);
			gr.lineTo(rightX, bottomY);
			var cornerSizeWidth: int = Math.min(30, Math.abs(rightX - leftX));
			var cornerSizeHeight: int = Math.min(30, Math.abs(bottomY - topY));
			var rx: Number = Math.max(rightX, leftX);
			var by: Number = Math.max(topY, bottomY);
			gr = _bottomRightCorner.graphics;
			gr.clear();
			gr.beginFill(0xFFFFFF, 0.5);
			gr.moveTo(rx, by - cornerSizeHeight);
			gr.lineTo(rx, by);
			gr.lineTo(rx - cornerSizeWidth, by);
			gr.lineTo(rx, by - cornerSizeHeight);
			gr.endFill();
		}
	}

	override protected function childrenCreated(): void
	{
		super.childrenCreated();
		_leftEdge.addEventListener(MouseEvent.MOUSE_DOWN, onSpriteDown);
		_rightEdge.addEventListener(MouseEvent.MOUSE_DOWN, onSpriteDown);
		_topEdge.addEventListener(MouseEvent.MOUSE_DOWN, onSpriteDown);
		_bottomEdge.addEventListener(MouseEvent.MOUSE_DOWN, onSpriteDown);
		_bottomRightCorner.addEventListener(MouseEvent.MOUSE_DOWN, onSpriteDown);
	}

	private function onSpriteDown(event: MouseEvent): void
	{
		isResizing = true;
		_currentlyDraggedSprite = event.target as Sprite;
		mouseEnabled = false;
		enableSprites(false);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, onSpriteMove);
		stage.addEventListener(MouseEvent.MOUSE_UP, onSpriteUp);
	}

	private function onSpriteMove(event: MouseEvent): void
	{
		mouseEnabled = false;
		enableSprites(false);
		computeBoundingBox(event);
	}

	private function computeBoundingBox(event: MouseEvent): void
	{
		if (!(event.target as DisplayObject).parent)
			return;
		var p: Point = new Point(event.stageX, event.stageY);
		p = this.globalToLocal(p);
		switch (_currentlyDraggedSprite)
		{
			case _leftEdge:
			{
				leftX = p.x;
				break;
			}
			case _rightEdge:
			{
				rightX = p.x;
				break;
			}
			case _topEdge:
			{
				topY = p.y;
				break;
			}
			case _bottomEdge:
			{
				bottomY = p.y;
				break;
			}
			case _bottomRightCorner:
			{
				rightX = p.x;
				bottomY = p.y;
				break;
			}
		}
		updateRectangleOnDrag();
		(this.parent as AreaSelectorTool).findAreaCoordinates();
	}

	private function updateRectangleOnDrag(): void
	{
		_r.x = Math.min(leftX, rightX);
		_r.y = Math.min(topY, bottomY);
		_r.width = Math.abs(leftX - rightX);
		_r.height = Math.abs(topY - bottomY);
		draw(null, true);
	}

	private function onSpriteUp(event: MouseEvent): void
	{
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, onSpriteMove);
		stage.removeEventListener(MouseEvent.MOUSE_UP, onSpriteUp);
		computeBoundingBox(event);
		draw(_r, false);
		isResizing = false;
		_currentlyDraggedSprite = null;
		mouseEnabled = true;
		enableSprites(true);
		//fix negative position
//		if (leftX < 0 || topY < 0)
//		{
//			
//		}
	}
}
