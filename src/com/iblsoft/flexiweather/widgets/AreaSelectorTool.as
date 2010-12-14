package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.proj.Coord;
	
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.core.UIComponent;

	public class AreaSelectorTool extends InteractiveLayer
	{
		private var _areaComponent: AreaRectangle;
		
		private var _r: Rectangle;
		private var _mouseDown: Boolean;
		private var _toolIsCreated: Boolean;
		
		private var _p: Point;
		
		private var _selectedBBox: BBox;
		public function get selectedBBox(): BBox
		{
			return _selectedBBox;
		}
	
		public function AreaSelectorTool(container: InteractiveWidget = null)
		{
			super(container);
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			_areaComponent = new AreaRectangle();
			addChild(_areaComponent);
		}
		
		override protected function childrenCreated():void
		{
			super.childrenCreated();
		}
		
		private function getMousePoint(event: MouseEvent): Point
		{
			var p: Point = new Point(event.stageX, event.stageY);
			p = this.globalToLocal(p);
//			trace("local p: " + p);
			
			return p;
		}
		
		override public function onMouseDown(event: MouseEvent): Boolean
        {
//			if(!event.ctrlKey && mb_requireCtrlKey || event.shiftKey)
			if(event.ctrlKey || event.shiftKey)
				return false;
//			if(!event.buttonDown)
//				return false;
			
			if (_areaComponent.isResizing)
			{
				_areaComponent.mouseEnabled = false;
				_areaComponent.enableSprites(false);
				return false;
			}
			
    		_toolIsCreated = (event.target == _areaComponent);
//        	trace("onMouseDown ["+_toolIsCreated+"] target: " + event.target + " ("+(event.target == _areaComponent)+") , curr: " + event.currentTarget + "  ("+(event.currentTarget == _areaComponent)+")");
    		
			_areaComponent.mouseEnabled = _toolIsCreated;
			
			if (!_toolIsCreated)
			{	
				_areaComponent.x = _areaComponent.y = 0;
				
				_p = getMousePoint(event);
				
        		_r = new Rectangle(_p.x, _p.y, 0, 0);
        		_mouseDown = true;
//	        	trace("onMouseDown " + _r);
	        	invalidateDynamicPart();
	  		} else {
	  			_areaComponent.startDrag();
	  		}
        	return true;
        }

        override public function onMouseUp(event: MouseEvent): Boolean
        {
        	if(event.ctrlKey || event.shiftKey)
				return false;
				
			if(_r == null || _areaComponent.isResizing)
				return false;
				
        	if (!_toolIsCreated)
			{	
					
				//create new rectangle from old one with correct left, top, right, bottom properties (it matters on direction of draggine when zoom rectange is created
				_r = new Rectangle(Math.min(_r.left, _r.right), Math.min(_r.top, _r.bottom), Math.abs(_r.left - _r.right),  Math.abs(_r.top - _r.bottom));
				
//				trace("onMouseUp " + _r);
				
				if((_r.width) > 5 && (_r.height) > 5) {
		        	findAreaCoordinates();
				}        
				_toolIsCreated = true;	
	        	//_r = null;
	        	_mouseDown = false;
	        	invalidateDynamicPart();
	  		} else {
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
        
        override public function onMouseMove(event: MouseEvent):Boolean
        {
        	if(event.ctrlKey || event.shiftKey)
				return false;
				
			if(_r == null || !_mouseDown || _areaComponent.isResizing)
				return false;
				
        	if (!_toolIsCreated)
			{
//				trace("local: ["+event.localX+","+event.localY+"] stage: ["+event.stageX+","+event.stageY+"]");
				_p = getMousePoint(event);
				_r.width = _p.x - _r.x;
				_r.height = _p.y - _r.y;
				
	//			trace("onMouseMove " + _r);
	        	invalidateDynamicPart();
	  		}
	  		findAreaCoordinates();
        	return true;
        }
        
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			if(_r != null) {
				_areaComponent.draw(_r, !_toolIsCreated);
			}
		}
		
		public function findAreaCoordinates(): void
		{
			var r: Rectangle = container.getViewBBox().toRectangle();
//        	trace("AreaSelectorTool: viewBox rectangle: " + r);  
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
					
//					trace("BBOX: rect: " + r);
//			trace(" bbox: " + bbox);
			
			var topLeftCoord: Coord = findCoordinates(_selectedBBox.xMin, _selectedBBox.yMax);
			var bottomRightCoord: Coord = findCoordinates(_selectedBBox.xMax, _selectedBBox.yMin);
//			trace("end");
			
			var ile: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveLayerEvent.AREA_CHANGED);
			ile.topLeftCoord = topLeftCoord;
			ile.bottomRightCoord = bottomRightCoord;
			dispatchEvent(ile);
//		        	container.setViewBBox(bbox, true);
		}
		public function findCoordinates(x: Number, y: Number): Coord
		{
			var c: Coord = new Coord(container.getCRS(),x,y);
//			trace("findCoordinates ["+x+","+y+"]: " + c.toString() + " nice: " + c.toNiceString());
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
	
	private var _r: Rectangle;
	
	
	public function AreaRectangle()
	{
		
	}
	
	override protected function createChildren():void
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
	public function draw(r: Rectangle = null, _toolIsCreating: Boolean = false): void
	{
		enableSprites(!_toolIsCreating);
		
		if (r)
			_r = r;
		
		if(_r != null) {
			var gr: Graphics = graphics;
			gr.clear();
			
			if (r)
			{
				leftX = Math.min(_r.x, _r.x + _r.width);
				rightX = Math.max(_r.x, _r.x + _r.width);
				topY = Math.min(_r.y, _r.y + _r.height);
				bottomY = Math.max(_r.y, _r.y + _r.height);
				
//				trace("X: " + leftX + " , " + rightX);
//				trace("Y: " + topY + " , " + bottomY);
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
	
	override protected function childrenCreated():void
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
//		trace("onSpriteDown local: ["+event.localX+","+event.localY+"] stage: ["+event.stageX+","+event.stageY+"]");
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
		
//		trace("onSpriteMove : " + event.target + " curr: " + event.currentTarget);
//		trace("onSpriteMove : " + event.localX + " , " + event.localY);
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
				leftX = p.x;
				break;
			case _rightEdge:
				rightX = p.x;
				break;
			case _topEdge:
				topY = p.y;			
				break;
			case _bottomEdge:
				bottomY = p.y;
				break;
			case _bottomRightCorner:
				rightX = p.x;
				bottomY = p.y;
				break;
		}
//		trace("onSpriteMove local: ["+event.localX+","+event.localY+"] stage: ["+event.stageX+","+event.stageY+"]");
		updateRectangleOnDrag();
		
		(this.parent as AreaSelectorTool).findAreaCoordinates();
	}
	
	private function updateRectangleOnDrag(): void
	{
		_r.x = Math.min(leftX, rightX);	
		_r.y = Math.min(topY, bottomY);	
		_r.width = Math.abs(leftX - rightX);	
		_r.height = Math.abs(topY - bottomY);	
		
//		trace("updateRectangleOnDrag: " + _r);
		draw(null, true);
	}
	
	private function onSpriteUp(event: MouseEvent): void
	{
//		trace("onSpriteUp local: ["+event.localX+","+event.localY+"] stage: ["+event.stageX+","+event.stageY+"]");
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, onSpriteMove);
		stage.removeEventListener(MouseEvent.MOUSE_UP, onSpriteUp);
		
		computeBoundingBox(event);
		draw(_r, false);
		isResizing = false;
		
		_currentlyDraggedSprite = null;
		
		mouseEnabled = true;
		enableSprites(true);
		
		//fix negative position
//		trace("UP: " + x + " , " + y);
//		trace("UP1: " + leftX + " , " + topY + " : " + rightX + " , " + bottomY);
//		trace("UP2: " + _r.x + " , " + _r.y + " size: " + _r.width + " , " + _r.height);
//		if (leftX < 0 || topY < 0)
//		{
//			
//		}
		
	}
}