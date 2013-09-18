package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.plugins.IConsole;
	import com.iblsoft.flexiweather.proj.Projection;
	
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.GesturePhase;
	import flash.events.MouseEvent;
	import flash.events.TransformGestureEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.ui.Multitouch;
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import mx.effects.Move;
	import mx.effects.easing.Quadratic;
	import mx.events.ChildExistenceChangedEvent;
	import mx.events.TweenEvent;
	import mx.messaging.AbstractConsumer;

	[Event(name = "startPanning", type = "flash.events.Event")]
	[Event(name = "stopPanning", type = "flash.events.Event")]
	public class InteractiveLayerPan extends InteractiveLayer
	{
		public static const MOUSE_MOVE_DELAY: int = 1500;
		
		public static const PAN: String = 'pan';
		public static const START_PANNING: String = 'startPanning';
		public static const STOP_PANNING: String = 'stopPanning';
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
		private var _wrapLimiter: WrapLimiter;

		private var _doPanDelayed: DoPanDelay;
		
		public function InteractiveLayerPan(container: InteractiveWidget = null)
		{
			super(container);
			
			_type = PAN;
			
			_doPanDelayed = new DoPanDelay(doRealPan, MOUSE_MOVE_DELAY);
			
			addEventListener(ChildExistenceChangedEvent.CHILD_ADD, onChildAdd);
			waitForContainer();
		}

		private function waitForContainer(): void
		{
			if (!container || !container.stage)
				callLater(waitForContainer)
			else
			{
				_wrapLimiter = new WrapLimiter(container, 1);
				if (Multitouch.supportedGestures)
				{
					container.stage.addEventListener(TransformGestureEvent.GESTURE_PAN, onGesturePan);
					container.stage.addEventListener(TransformGestureEvent.GESTURE_SWIPE, onGestureSwipe);
				}
			}
		}

		private function onChildAdd(event: ChildExistenceChangedEvent): void
		{
		}

		private function onGesturePan(event: TransformGestureEvent): void
		{
			if (!enabled)
				return;
			var b_finalChange: Boolean = event.phase == GesturePhase.END;
			doRealPan(event.offsetX, event.offsetY, b_finalChange);
		}

		private function onGestureSwipe(event: TransformGestureEvent): void
		{
			if (!enabled)
				return;
			if (mb_requireShiftKey)
				return;
			var b_finalChange: Boolean = event.phase == GesturePhase.END;
			doRealPan(event.offsetX, event.offsetY, b_finalChange);
		}

		override public function onMouseRollOver(event:MouseEvent):Boolean
		{
			return startPanning(event);
		}
		override public function onMouseDown(event: MouseEvent): Boolean
		{
			return startPanning(event);
		}
		
		private function startPanning(event: MouseEvent): Boolean
		{
			if (!event.shiftKey && mb_requireShiftKey || event.ctrlKey)
				return false;
			if (!event.buttonDown)
				return false;
			if (supportsPanAnimation)
			{
				if (_animate && _animate.isPlaying)
					_animate.stop();
				addEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
			_p = new Point(event.localX, event.localY);
			_oldPoint = _p;
			_oldStartPoint = _p;
			_moveIntervalPoint = _p;
			dispatchEvent(new Event(InteractiveLayerPan.START_PANNING, true));
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
			if (doPanTo(_moveIntervalPoint, true, 'onMoveAnimateEnd'))
			{
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
				if (doPanTo(_moveIntervalPoint, false, 'onMoveAnimate'))
					invalidateDynamicPart();
			}
			_animPoint = _moveIntervalPoint;
		}

		override public function onMouseRollOut(event:MouseEvent):Boolean
		{
			return finishPanning(event);
		}
		
		override public function onMouseUp(event: MouseEvent): Boolean
		{
			return finishPanning(event);
		}
		
		private function finishPanning(event: MouseEvent): Boolean
		{
			if (supportsPanAnimation)
				removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			if (_p == null)
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
			}
			else
			{
				if (doPanTo(endP, true, 'OnMouseUp'))
				{
					//invalidateDynamicPart();
				}
				_p = null;
			}
			_oldStartPoint = null;
			dispatchEvent(new Event(InteractiveLayerPan.STOP_PANNING, true));
			return true;
		}

		private function onMouseMoveDelay(): void
		{
			if (doPanTo(_moveIntervalPoint, true, 'onMouseMoveDelay'))
				invalidateDynamicPart();
		}
		private var _oldPoint: Point;

		override public function onMouseMove(event: MouseEvent): Boolean
		{
			if (_oldStartPoint == null)
				return false;
			var finalChange: Boolean = false; //false
			if (!supportsPanAnimation)
			{
				_oldPoint = _moveIntervalPoint;
				_moveIntervalPoint = new Point(event.localX, event.localY);
			}
			clearInterval(_moveInterval);
			_moveInterval = setInterval(onMouseMoveDelay, MOUSE_MOVE_DELAY);
			if (_moveIntervalPoint)
			{
				if (doPanTo(_moveIntervalPoint, finalChange, 'onMouseMove'))
					invalidateDynamicPart();
			}
			return true;
		}

		private function onEnterFrame(event: Event): void
		{
			var pLocalMouse: Point = container.globalToLocal(new Point(stage.mouseX, stage.mouseY));
			_diffMouseX = pLocalMouse.x - _oldMouseX;
			_diffMouseY = pLocalMouse.y - _oldMouseY;
			_oldMouseX = pLocalMouse.x;
			_oldMouseY = pLocalMouse.y;
			_oldPoint = _moveIntervalPoint;
			_moveIntervalPoint = new Point(_oldMouseX, _oldMouseY);
			if (_diffMouseX != 0 || _diffMouseY != 0)
				clearInterval(_moveInterval);
		}

		protected function doPanTo(p: Point, b_finalChange: Boolean, test: String): Boolean
		{
			if (!_p && !_oldStartPoint)
				return false;
			var pDiff: Point = p.subtract(_p);
			_p = p;
			if (Math.abs(pDiff.x) > 1 || Math.abs(pDiff.y) > 1 || b_finalChange)
			{
//				var r: BBox = container.getViewBBox();
//				var w: Number = container.width;
//				var h: Number = container.height;
//				pDiff.x = pDiff.x * r.width / w;
//				pDiff.y = pDiff.y * r.height / h;
//				container.setViewBBox(r.translated(-pDiff.x, pDiff.y), b_finalChange);
				doRealPan(pDiff.x, pDiff.y, b_finalChange);
				return true;
			}
			return false;
		}

		private function extentRatio(): Number
		{
			var projection: Projection = container.getCRSProjection();
			var viewBBox: BBox = container.getExtentBBox();
			var extentRatio: Number = 100 * viewBBox.width / projection.extentBBox.width;
			return extentRatio;
		}

		private function allowWrapHorizontally(): Boolean
		{
			var projection: Projection = container.getCRSProjection();
			var extentRatio: Number = extentRatio();
			var percentageTreshold: Number = 1;
			var withinTreshold: Boolean = Math.abs(100 - extentRatio) < percentageTreshold;
			return projection.wrapsHorizontally && withinTreshold;
		}
		
		
		private var _diff: Point;
		
		
		/**
		 * Panning function exposed 
		 * @param xDiff
		 * @param yDiff
		 * 
		 */		
		public function doPan(xDiff: int, yDiff: int): void
		{
			_doPanDelayed.doPan(xDiff, yDiff);
		}
		
		private function doRealPan(xDiff: Number, yDiff: Number, b_finalChange: Boolean): void
		{
			var r: BBox = container.getViewBBox();
			var w: Number = container.width;
			var h: Number = container.height;
			xDiff = xDiff * r.width / w;
			yDiff = yDiff * r.height / h;
			if (!_diff)
				_diff = new Point(xDiff, yDiff);
			_diff.x = xDiff;
			_diff.y = yDiff;
			
//			if (xDiff == 0 && yDiff == 0)
//			{
//				trace("InteractiveLayerPan doRealPan: diff 0,0");
//				return;
//			}
			
			invalidateDynamicPart(true);
			var projection: Projection = container.getCRSProjection();
			r = r.translated(-xDiff, yDiff);
			var extentBBox: BBox = container.getExtentBBox();
			var allowHorizontalWrap: Boolean = allowWrapHorizontally();
			if (allowHorizontalWrap && !extentBBox.contains(r) && xDiff != 0)
			{
				var f_wrappingStep: Number = -xDiff;
				while (extentBBox.translated(f_wrappingStep, 0).intersects(r))
				{
					extentBBox = extentBBox.translated(f_wrappingStep, 0);
					if (extentBBox.contains(r))
					{
						var a1: Array = container.mapBBoxToViewReflections(extentBBox);
						var a2: Array = container.mapBBoxToViewReflections(r);
						for (var i: int = 0; i < a1.length && i < a2.length; ++i)
						{
							if (projection.extentBBox.contains(a1[i]))
							{
								extentBBox = a1[i];
								r = a2[i];
							}
						}
						extentBBox = _wrapLimiter.moveViewBBoxBack(extentBBox);
//						container.setExtentBBox(extentBBox, false);
						break;
					}
				}
			}
			//check if viewBBox wi ll be moved and in that case move extentBBox first
			var moveX: Number = _wrapLimiter.getWrapMoveBackSize(r);
			if (moveX != 0)
				r = _wrapLimiter.moveViewBBoxBack(r);
			if (!allowHorizontalWrap)
			{
				if (r.xMin < extentBBox.xMin)
					r = r.translated(-r.xMin + extentBBox.xMin, 0);
				if (r.xMax > extentBBox.xMax)
					r = r.translated(-r.xMax + extentBBox.xMax, 0);
			}
			container.setExtentBBox(extentBBox, false);
			container.setViewBBox(r, b_finalChange);
			
//			updateContainerArea(extentBBox, r, b_finalChange);
		}

		private var _updateContainerAreaInterval: uint = 500;
		private var _lastUpdateTime: Number;
		private var _delayedUpdatedTimeout: Number;
		
		private var _extentBBox: BBox;
		private var _viewBBox: BBox;
		private var _viewBBoxFinalChange: Boolean;
		
		public function updateContainerArea(extentBBox: BBox, viewBBox: BBox, viewBBoxFinalChange: Boolean): void
		{
			_extentBBox = extentBBox;
			_viewBBox = viewBBox;
			_viewBBoxFinalChange = viewBBoxFinalChange;
			
			var currentTime: Number = getTimer();
			var timeSinceLastUpdate: Number = currentTime - _lastUpdateTime;
			if (isNaN(_lastUpdateTime) || timeSinceLastUpdate >= _updateContainerAreaInterval)
			{
				delayedUpdateContainerArea();
			} else {
				clearTimeout(_delayedUpdatedTimeout);
				_delayedUpdatedTimeout = setTimeout(delayedUpdateContainerArea, _updateContainerAreaInterval - timeSinceLastUpdate);
			}
		}
		
		private function delayedUpdateContainerArea(): void
		{			
			_lastUpdateTime = getTimer();
			container.setExtentBBox(_extentBBox, false);
			container.setViewBBox(_extentBBox, true);
		}
		
		
//		private var _txt: TextField;
		/*
		override protected function createChildren():void
		{
			super.createChildren();

			_txt = new TextField();
			addChild(_txt);
		}*/
		override public function draw(graphics: Graphics): void
		{
			super.draw(graphics);
			var gr: Graphics = graphics;
//			if (_diff)
//			{
//				_txt.text = 'PAN: ' + _diff.x + ' , ' + _diff.y;
//				_txt.x = (width - _txt.textWidth)/2
//				_txt.y = (height - _txt.textHeight)/2
//			}
		}

		// getters & setters
		[Bindable]
		public function get requireShiftKey(): Boolean
		{
			return mb_requireShiftKey;
		}

		public function set requireShiftKey(b: Boolean): void
		{
			mb_requireShiftKey = b;
		}

		public function set notRequireShiftKey(b: Boolean): void
		{
			mb_requireShiftKey = !b;
		}

		override public function toString(): String
		{
			return "InteractiveLayerPan ";
		}

		public function wrapDebug(console: IConsole): void
		{
			console.print('PAN Wrap Debug', 'Info', 'Pan');
			console.print("\t allowWrapHorizontally: " + allowWrapHorizontally(), 'Info', 'Pan');
			console.print("\t extentRatio: " + extentRatio(), 'Info', 'Pan');
			console.print("\t left: " + _wrapLimiter.leftWrapLimitForMovingBack(), 'Info', 'Pan');
			console.print("\t right: " + _wrapLimiter.rightWrapLimitForMovingBack(), 'Info', 'Pan');
			var r: BBox = container.getViewBBox();
			console.print("\t size: " + _wrapLimiter.getWrapMoveBackSize(r), 'Info', 'Pan');
		}

	}
}
import com.iblsoft.flexiweather.ogc.BBox;
import com.iblsoft.flexiweather.proj.Projection;
import com.iblsoft.flexiweather.widgets.InteractiveWidget;

import flash.utils.clearTimeout;
import flash.utils.getTimer;
import flash.utils.setTimeout;

class WrapLimiter
{
	private var _container: InteractiveWidget;
	private var _projection: Projection;
	private var _maxReflections: int = 1;

	public function WrapLimiter(container: InteractiveWidget, maxReflections: int)
	{
		_container = container;
		_maxReflections = maxReflections
	}

	private function getProjection(): void
	{
		_projection = _container.getCRSProjection();
	}

	public function projectionExtentWidth(): Number
	{
		getProjection();
		var projectionBBox: BBox = _projection.extentBBox;
		var projWidth: int = projectionBBox.width;
		return projWidth;
	}

	public function rightWrapLimitForMovingBack(): Number
	{
		getProjection();
		var projectionBBox: BBox = _projection.extentBBox;
		var projWidth: Number = projectionExtentWidth();
		var rightMinimumForOffsetBack: Number = projectionBBox.xMin + 2 * projWidth; // * (_maxReflections + 1);
		return rightMinimumForOffsetBack;
	}

	public function leftWrapLimitForMovingBack(): Number
	{
		getProjection();
		var projectionBBox: BBox = _projection.extentBBox;
		var projWidth: int = projectionBBox.width;
		var leftMinimumForOffsetBack: int = projectionBBox.xMin - projWidth; // * _maxReflections;
		return leftMinimumForOffsetBack;
	}

	public function getWrapMoveBackSize(bbox: BBox): Number
	{
		getProjection();
		var rightMinimumForOffsetBack: Number = rightWrapLimitForMovingBack();
		var leftMinimumForOffsetBack: Number = leftWrapLimitForMovingBack();
		var moveX: Number;
		var projWidth: Number;
		if (bbox.xMin > rightMinimumForOffsetBack)
		{
			projWidth = projectionExtentWidth();
			moveX = -1 * projWidth;
			return moveX;
		}
		if (bbox.xMin < leftMinimumForOffsetBack)
		{
			projWidth = projectionExtentWidth();
			moveX = 2 * projWidth;
			return moveX;
		}
		return 0;
	}

	public function moveViewBBoxBack(bbox: BBox): BBox
	{
		getProjection();
		var rightMinimumForOffsetBack: Number = rightWrapLimitForMovingBack();
		var leftMinimumForOffsetBack: Number = rightWrapLimitForMovingBack();
		var moveX: Number;
		var projWidth: Number;
		if (bbox.xMin > rightMinimumForOffsetBack || bbox.xMin < leftMinimumForOffsetBack)
		{
			moveX = getWrapMoveBackSize(bbox);
			bbox = moveViewBBoxBackBy(bbox, moveX, 0);
		}
		return bbox;
	}

	public function moveViewBBoxBackBy(bbox: BBox, xDiff: Number, yDiff: Number): BBox
	{
		bbox = bbox.translated(xDiff, yDiff);
		return bbox;
	}

}

class DoPanDelay {

	private var _doPanTimeOut: int
	private var _doPanTime: Number;
	private var _callback: Function;
	private var _delayTime: int;
	private var _xDiff: Number;
	private var _yDiff: Number;
	
	public function DoPanDelay(callback: Function, delayTime: int): void
	{
		_callback = callback;
		_delayTime = delayTime;
		
		_doPanTimeOut = 0;
		_doPanTime = 0;
		_xDiff = 0;
		_yDiff = 0;
	}

	public function doPan(xDiff: Number, yDiff: Number): void
	{
		_xDiff += xDiff;
		_yDiff += yDiff;
		
//		trace("DoPanDealy doPan ["+xDiff + ", " + yDiff + "] total ["+_xDiff + ", " + _yDiff + "]");
		var timeDifference: Number = getTimer() - _doPanTime; 
		if (timeDifference > _delayTime)
		{
			doPanDelayed();
		} else {
		
			if (_xDiff != 0 || _yDiff != 0)
			{
//				trace("DoPanDealy doPan callback: FALSE");
				_xDiff /= 2;
				_yDiff /= 2;
				_callback(_xDiff, _yDiff, false);
			}
			
			if (_doPanTimeOut > 0)
				clearTimeout(_doPanTimeOut);
		
			var timeToNextPan: Number = _delayTime - timeDifference;
			_doPanTimeOut = setTimeout(doPanDelayed, timeToNextPan);
		}
	}
		
	private function doPanDelayed(): void
	{
		_doPanTimeOut = 0;
		
		if (_xDiff != 0 || _yDiff != 0)
		{
//			trace("DoPanDealy doPanDelayed callback: TRUE");
			_callback(_xDiff, _yDiff, true);
			_xDiff = 0;
			_yDiff = 0;
		}
		
		_doPanTime = getTimer();
	}
}