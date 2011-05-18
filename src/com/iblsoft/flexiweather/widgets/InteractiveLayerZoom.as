package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.proj.Coord;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.GesturePhase;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.events.TransformGestureEvent;
	import flash.geom.Rectangle;
	import flash.ui.Multitouch;
	import flash.utils.Timer;
	
	import mx.events.DynamicEvent;
	import mx.messaging.AbstractConsumer;
	
	public class InteractiveLayerZoom extends InteractiveLayer
	{
		protected var _r: Rectangle;
		protected var mb_requireCtrlKey: Boolean = true;

		protected var m_wheelZoomTimer: Timer = new Timer(500, 1); 
		protected var mb_finalChangeOccuredAfterWheelZoom: Boolean = true; 
		
		private var _zoomAreaSprite: Sprite;
		private var _showZoomingArea: Boolean = false;
		
		public function InteractiveLayerZoom(container: InteractiveWidget = null)
		{
			super(container);
			m_wheelZoomTimer.stop();
			m_wheelZoomTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onMouseWheelTimer);
			waitForContainer();
		}
		private function waitForContainer(): void
		{
			if (!container || !container.stage)
				callLater(waitForContainer)
			else {	
				if (Multitouch.supportedGestures)
				{
					container.stage.addEventListener(TransformGestureEvent.GESTURE_ZOOM, onGestureZoom);
					container.stage.addEventListener(TransformGestureEvent.GESTURE_PAN, onGesturePan);
					container.stage.addEventListener(TransformGestureEvent.GESTURE_SWIPE, onGestureSwipe);
//					addEventListener(TransformGestureEvent.GESTURE_ZOOM, onGestureZoom);
//					addEventListener(TransformGestureEvent.GESTURE_PAN, onGesturePan);
//					addEventListener(TransformGestureEvent.GESTURE_SWIPE, onGestureSwipe);
				}
			}
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
		
				createChildrenNoGesturesMode();
//			if (!Multitouch.supportedGestures)
//			{
//			} else {
//				addEventListener(TransformGestureEvent.GESTURE_ZOOM, onGestureZoom);
//			}
				
			
			
		}
		
		private function onGestureSwipe(event: TransformGestureEvent): void
		{
			trace("onGestureSwipe: phase: " + event.phase + " -> "  + event.offsetX + " , " + event.offsetY);
		}
		private function onGesturePan(event: TransformGestureEvent): void
		{
			trace("onGesturePan: phase: " + event.phase + " -> " + event.offsetX + " , " + event.offsetY);
		}
		private function onGestureZoom(event: TransformGestureEvent): void
		{
			
			trace("onGestureZoom: target: " + event.target);
			trace("onGestureZoom: target: " + event.currentTarget);
			trace("onGestureZoom: phase: " + event.phase + " ->  scale: " + event.scaleX + ", " + event.scaleY);
			trace("onGestureZoom: local: " + event.localX + ", " + event.localY);
//			trace("onGestureZoom: offset: " + event.offsetX + ", " + event.offsetY);
//			trace("onGestureZoom: rotation: " + event.rotation + ", " + event.offsetY);
			
			var b_finalChange: Boolean = event.phase == GesturePhase.END;
			
			var x: int = event.localX;
			var y: int = event.localX;
			gestureZoom(x, y, event.scaleX, event.scaleY, b_finalChange);
		}
		
		private var _middleX: int = 0;
		private var _middleY: int = 0;
		private var _oldMiddle: Coord;
		private var _scale: Number = 1;
		
		private function gestureZoom(middleX: int, middleY: int,  scaleX: Number, scaleY: Number, b_finalChange: Boolean): void
		{
			var r: Rectangle = container.getViewBBox().toRectangle();
			var rOld: Rectangle = container.getViewBBox().toRectangle();
			
			var w: Number = container.width;
			var h: Number = container.height;
			var bW: Number = r.width;
			var bH: Number = r.height;
			
			var scale: Number = (scaleX + scaleY) / 2;
			var middle: Coord = container.pointToCoord(middleX, middleY);
			if(!middle)
				return;
			if (_oldMiddle)
				trace("\n middle: " + middle.toString() + " old: " + _oldMiddle.toString());
			else
				trace("\n middle: " + middle.toString() + " old: NULL ");
			
			r.x = middle.x - (middle.x - rOld.x) / scale;
			r.y = middle.y - (middle.y - rOld.y) / scale;
			
//			if (_oldMiddle)
//			{
//				r.x -= middle.x - _oldMiddle.x;
//				r.y -= middle.y - _oldMiddle.y;
//				_oldMiddle = null;
//			} else {
//				_oldMiddle = middle;
//			}
				_oldMiddle = middle;
			
			_middleX = middleX;
			_middleY = middleY;
			_scale = scale;
			
			r.width = rOld.width / scale;
			r.height = rOld.height / scale;
			
			container.setViewBBox(BBox.fromRectangle(r), b_finalChange);
			
			invalidateDynamicPart();
			
		}
		private function createChildrenNoGesturesMode(): void
		{
			_zoomAreaSprite = new Sprite();
			addChild(_zoomAreaSprite);
			
			_zoomAreaSprite.visible = _showZoomingArea;
			
		}
		
		override public function destroy(): void
		{
			removeChild(_zoomAreaSprite);
		}
        override public function onMouseRollOver(event:MouseEvent): Boolean
        {
//        	trace("\n\nZOOM onMouseRollOver");
        	
        	container.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        	container.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
        	
        	return true;
        }
        override public function onMouseRollOut(event:MouseEvent):Boolean
        {
//        	trace("ZOOM onMouseRollOut");
        	
        	container.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        	container.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
        	return true;
        }

        private function onKeyDown(event: KeyboardEvent): void
        {
//        	trace("onKeyDown: " + event.keyCode + " ctrl: " + event.ctrlKey);
        	if (!_showZoomingArea && event.ctrlKey)
        	{
        		_showZoomingArea = true;
        		invalidateDisplayList();
        	}
        }
        private function onKeyUp(event: KeyboardEvent): void
        {
//        	trace("onKeyUp: " + event.keyCode + " ctrl: " + event.ctrlKey);
        	if (_showZoomingArea && !event.ctrlKey)
        	{
        		_showZoomingArea = false;
//        		_zoomAreaSprite.visible = false;
        		invalidateDisplayList();
        	}
        }
        
        private var _zoomStartY: int = -1;
        override public function onMouseDown(event: MouseEvent): Boolean
        {
			if(!event.ctrlKey && mb_requireCtrlKey || event.shiftKey)
				return false;
			if(!event.buttonDown)
				return false;
				
//			trace("zoom onMouseDown " + event.target + ", " + event.currentTarget);
			if (event.target == _zoomAreaSprite)
			{
				_zoomStartY = event.localY;
			} else {
	        	_r = new Rectangle(event.localX, event.localY, 0, 0);
	        	invalidateDynamicPart();
	  		}
        	return true;
        }

        override public function onMouseUp(event: MouseEvent): Boolean
        {
			if(_r == null)
				return false;
				
			if (event.target == _zoomAreaSprite)
			{
				_zoomStartY = -1;
			} else {
				//create new rectangle from old one with correct left, top, right, bottom properties (it matters on direction of draggine when zoom rectange is created
				_r = new Rectangle(Math.min(_r.left, _r.right), Math.min(_r.top, _r.bottom), Math.abs(_r.left - _r.right),  Math.abs(_r.top - _r.bottom));
				
				if((_r.width) > 5 && (_r.height) > 5) {
		        	var r: Rectangle = container.getViewBBox().toRectangle();
		        	var w: Number = container.width;
		        	var h: Number = container.height;
		        	var bW: Number = r.width;
		        	var bH: Number = r.height;
		        	r.width = bW / w * _r.width;
		        	r.height = bH / h * _r.height;
		        	r.x = r.x + _r.x / w * bW;
		        	r.y = r.y + (h - _r.bottom) / h * bH;
		        	container.setViewBBox(BBox.fromRectangle(r), true);
				}        	
	        	_r = null;
	        	invalidateDynamicPart();
	 		 }
        	return true;
        }
        
        override public function onMouseMove(event: MouseEvent):Boolean
        {
        	if (event.target == _zoomAreaSprite)
			{
				if(!event.ctrlKey && mb_requireCtrlKey || event.shiftKey)
					return false;
				if(!event.buttonDown)
					return false;
				if (_zoomStartY > 0)
				{
					var diff: Number = (event.localY - _zoomStartY);
//					trace("zoom area: " + diff);
					onDeltaZoom(diff);
					_zoomStartY = event.localY;
				}
			} else {
				if(_r == null)
					return false;
				_r.width = event.localX - _r.x;
				_r.height = event.localY - _r.y;
	        	invalidateDynamicPart();
	  		}
        	return true;
        }
        
        override public function onAreaChanged(b_finalChange:Boolean): void
        {
        	if(b_finalChange) {
        		// remember final area change
        		mb_finalChangeOccuredAfterWheelZoom = true;
        	} else {
        		if(m_wheelZoomTimer.running) {
	        		// non-final area change occured while waiting for final change,
	        		// so just waiting timeout
					m_wheelZoomTimer.repeatCount = 1;
					m_wheelZoomTimer.reset();
					m_wheelZoomTimer.start();
        		}
        	}
        }

		override public function onMouseWheel(event: MouseEvent): Boolean
		{
			//if(!event.ctrlKey && mb_requireCtrlKey)
			//	return false;
			return onDeltaZoom(event.delta)
		}
		
		private function onDeltaZoom(delta: int): Boolean
		{
        	var bbox: Rectangle = container.getViewBBox().toRectangle();
        	var f_bboxCenterX: Number = bbox.x + bbox.width / 2.0; 
        	var f_bboxCenterY: Number = bbox.y + bbox.height / 2.0;
        	var f_width: Number = bbox.width;
        	var f_height: Number = bbox.height;
        	var b_changed: Boolean = false;
			if(delta > 0) {
	        	f_width *= 0.75;
	        	f_height *= 0.75;
	        	b_changed = true;
			}
			if(delta < 0) {
	        	f_width /= 0.75;
	        	f_height /= 0.75;
	        	b_changed = true;
			}
			if(b_changed) {
				m_wheelZoomTimer.repeatCount = 1;
				m_wheelZoomTimer.reset();
				m_wheelZoomTimer.start();
				// do only non-final area change
	        	container.setViewBBox(BBox.fromRectangle(new Rectangle(
		        		f_bboxCenterX - f_width / 2.0,
		        		f_bboxCenterY - f_height / 2.0,
		        		f_width,
		        		f_height)), false);
	        	invalidateDynamicPart();
	        	
	        	// but start timer to defer final zoom change, but only if final change
	        	// doesn't occur in between (initiated by someone else)
	        	mb_finalChangeOccuredAfterWheelZoom = false;
		 	}
			return true;
		}

		protected function onMouseWheelTimer(event: Event = null): void
		{
			if(!mb_finalChangeOccuredAfterWheelZoom) {
				// noone else commited a final area change, so let's do it 
				container.setViewBBox(container.getViewBBox(), true);
			}
		}
		
		override public function draw(graphics: Graphics): void
		{
			super.draw(graphics);
			
			//draw zoom area on right side
			var gr: Graphics = _zoomAreaSprite.graphics;
			gr.clear()
			gr.beginFill(0,0.35);
			gr.drawRoundRectComplex( width - 50, 20, 30, height - 40, 5, 5, 5, 5);
			gr.endFill();
			
			_zoomAreaSprite.visible = _showZoomingArea;
			
//			var gr2: Graphics = graphics;
//			gr2.beginFill(0xff0000);
//			gr2.drawCircle(_middleX, _middleY, 30 * _scale);
//			gr2.endFill();
			
			if(_r != null) {
				graphics.beginFill(0, 0.5);
				graphics.lineStyle(1, 0xFFFFFF, 0.8);
				graphics.drawRect(_r.x, _r.y, _r.width, _r.height);
				graphics.endFill();
//				graphics.drawRect(_r.x, _r.y, _r.width, _r.height);
			}
		}
		
		// getters & setters
		[Bindable]
		public function get requireCtrlKey(): Boolean
		{ return mb_requireCtrlKey; }

		public function set requireCtrlKey(b: Boolean): void
		{ mb_requireCtrlKey = b; }

		public function set notRequireCtrlKey(b: Boolean): void
		{ mb_requireCtrlKey = !b; }
	}
}