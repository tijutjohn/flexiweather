package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.ogc.BBox;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import mx.effects.Move;
	import mx.effects.easing.Quadratic;
	import mx.events.TweenEvent;
	
	public class InteractiveLayerPan extends InteractiveLayer
	{
		public var supportsPanAnimation: Boolean;
		
		internal var _oldStartPoint: Point;
		internal var _p: Point;
		internal var mb_requireShiftKey: Boolean = true;
		
		private var _moveInterval: int;
        private var _moveIntervalPoint: Point;
        
        private var _oldMouseX: int;
		private var _oldMouseY: int;
		private var _diffMouseX: int;
		private var _diffMouseY: int;
		
		private var _animate: Move;
		
		public function InteractiveLayerPan(container: InteractiveWidget = null)
		{
			super(container);
		}
		
        override public function onMouseDown(event: MouseEvent): Boolean
        {
			if(!event.shiftKey && mb_requireShiftKey || event.ctrlKey)
				return false;
			if(!event.buttonDown)
				return false;
				
			if (supportsPanAnimation)
			{
				if (_animate && _animate.isPlaying)
				{
					_animate.stop();
				}
				addEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
			
        	_p = new Point(event.localX, event.localY);
        	_oldPoint = _p;
        	_oldStartPoint = _p;
        	_moveIntervalPoint = _p;
        	return true;
        }

		private function getFinalPanPoint(point: Point, oldPoint: Point): Point
		{
			var lastDistance: Number = Point.distance(oldPoint, point);
			var t: Number = lastDistance / -50; 
			
			var x: int = (1 - t) * point.x + t * oldPoint.x;
			var y: int = (1 - t) * point.y + t * oldPoint.y;
			 
			return new Point(x, y);
			
		}
		private function onMoveAnimateEnd(event: TweenEvent): void
		{
			_moveIntervalPoint = new Point(int(event.value[0]), int(event.value[1]));
			if(doPanTo(_moveIntervalPoint, true, 'onMoveAnimateEnd')) {
		        	//invalidateDynamicPart();
	        }
	        _p = null;
		}
		private var _animPoint: Point = new Point();
		private function onMoveAnimate(event: TweenEvent): void
		{
			_moveIntervalPoint = new Point(int(event.value[0]), int(event.value[1]));
			if (Point.distance(_moveIntervalPoint, _animPoint) > 0)
			{ 
				if(doPanTo(_moveIntervalPoint, false, 'onMoveAnimate')) {
			        invalidateDynamicPart();
		        }
		 	}
	        _animPoint = _moveIntervalPoint;
		}
        override public function onMouseUp(event: MouseEvent): Boolean
        {
        	if (supportsPanAnimation)
        		removeEventListener(Event.ENTER_FRAME, onEnterFrame);
        	
			if(_p == null)
				return false;
				
			clearInterval(_moveInterval);
			
			var endP: Point = new Point(event.localX, event.localY);
			var dist: Number = Point.distance(_p, endP)
			var lastDistance: Number = Point.distance(_oldPoint, endP);
			
		        
		    if (supportsPanAnimation && lastDistance > 1)
			{
				var finalPoint: Point = getFinalPanPoint(endP, _oldPoint);
				
				_animate = new Move(this);
				_animate.easingFunction = Quadratic.easeOut;
				_animate.xFrom = endP.x;
				_animate.xTo = finalPoint.x;
				
				_animate.yFrom = endP.y;
				_animate.yTo = finalPoint.y;
				_animate.addEventListener(TweenEvent.TWEEN_UPDATE, onMoveAnimate);
				_animate.addEventListener(TweenEvent.TWEEN_END, onMoveAnimateEnd);
				_animate.play([this]);
				
				
			} else {
				if(doPanTo(endP, true, 'OnMouseUp')) {
	        		//invalidateDynamicPart();
	        	}
	        	_p = null;
			}
			_oldStartPoint = null;
        	return true;
        }
        
       
        
        private function onMouseMoveDelay(): void
        {
        	if(doPanTo(_moveIntervalPoint, true, 'onMouseMoveDelay')) {
	        	invalidateDynamicPart();
	        }
        }
        
        private var _oldPoint: Point;
        
        override public function onMouseMove(event:MouseEvent):Boolean
        {
			if(_oldStartPoint == null)
				return false;
				
			var finalChange: Boolean = false; //false
			if (!supportsPanAnimation)
			{
	        	_oldPoint = _moveIntervalPoint;
				_moveIntervalPoint = new Point(event.localX, event.localY);
			}
			
			clearInterval(_moveInterval);
			_moveInterval = setInterval(onMouseMoveDelay, 600);
			
			if (_moveIntervalPoint)
			{
//				trace("onMouseMove target: " + event.target + " CURRENT TARGET: " + event.currentTarget);
//				trace("onMouseMove target: " + event.localX +","+ event.localY);
				if(doPanTo(_moveIntervalPoint, finalChange, 'onMouseMove')) {
		        	invalidateDynamicPart();
		        }
		 	}
	        
        	return true;
        }

		
		private function onEnterFrame(event: Event): void
		{
			
			var pLocalMouse: Point = container.globalToLocal(new Point(stage.mouseX , stage.mouseY));
			
			_diffMouseX = pLocalMouse.x - _oldMouseX; 
			_diffMouseY = pLocalMouse.y - _oldMouseY;
			 
			_oldMouseX = pLocalMouse.x;
			_oldMouseY = pLocalMouse.y;
			
			
			_oldPoint = _moveIntervalPoint;
	        
			_moveIntervalPoint = new Point(_oldMouseX, _oldMouseY);
			
			if (_diffMouseX != 0 || _diffMouseY != 0)
				clearInterval(_moveInterval);
				
//			trace("\t enter frame  " + _moveIntervalPoint);
		}
			
        protected function doPanTo(p: Point, b_finalChange: Boolean, test: String): Boolean
        {
        	if (!_p && !_oldStartPoint)
        	{
        		return false;
        	}
        	
			var pDiff: Point = p.subtract(_p);
//			trace("p diff ["+test+"]: " + pDiff + " p : " + p + " _p: " + _p);
			_p = p;
			
			if(Math.abs(pDiff.x) > 1 || Math.abs(pDiff.y) > 1 || b_finalChange) {
	        	var r: BBox = container.getViewBBox();
	        	var w: Number = container.width;
	        	var h: Number = container.height;
	        	pDiff.x = pDiff.x * r.width / w;
	        	pDiff.y = pDiff.y * r.height / h;
	        	container.setViewBBox(r.translated(-pDiff.x, pDiff.y), b_finalChange);
				return true;        	
			}
			return false;        	
        }

		// getters & setters
		[Bindable]
		public function get requireShiftKey(): Boolean
		{ return mb_requireShiftKey; }

		public function set requireShiftKey(b: Boolean): void
		{ mb_requireShiftKey = b; }

		public function set notRequireShiftKey(b: Boolean): void
		{ mb_requireShiftKey = !b; }
	}
}