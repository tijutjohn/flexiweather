package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.ogc.BBox;
	
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	
	public class InteractiveLayerZoom extends InteractiveLayer
	{
		protected var _r: Rectangle;
		protected var mb_requireCtrlKey: Boolean = true;

		protected var m_wheelZoomTimer: Timer = new Timer(500, 1); 
		protected var mb_finalChangeOccuredAfterWheelZoom: Boolean = true; 
		
		public function InteractiveLayerZoom(container: InteractiveWidget = null)
		{
			super(container);
			m_wheelZoomTimer.stop();
			m_wheelZoomTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onMouseWheelTimer);
		}
		
        override public function onMouseDown(event: MouseEvent): Boolean
        {
			if(!event.ctrlKey && mb_requireCtrlKey || event.shiftKey)
				return false;
			if(!event.buttonDown)
				return false;
        	_r = new Rectangle(event.localX, event.localY, 0, 0);
        	invalidateDynamicPart();
        	return true;
        }

        override public function onMouseUp(event: MouseEvent): Boolean
        {
			if(_r == null)
				return false;
			_r.width = event.localX - _r.x;
			_r.height = event.localY - _r.y;
			
			if(_r.width > 5 && _r.height > 5) {
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
        	return true;
        }
        
        override public function onMouseMove(event: MouseEvent):Boolean
        {
			if(_r == null)
				return false;
			_r.width = event.localX - _r.x;
			_r.height = event.localY - _r.y;
        	invalidateDynamicPart();
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
        	var bbox: Rectangle = container.getViewBBox().toRectangle();
        	var f_bboxCenterX: Number = bbox.x + bbox.width / 2.0; 
        	var f_bboxCenterY: Number = bbox.y + bbox.height / 2.0;
        	var f_width: Number = bbox.width;
        	var f_height: Number = bbox.height;
        	var b_changed: Boolean = false;
			if(event.delta > 0) {
	        	f_width *= 0.75;
	        	f_height *= 0.75;
	        	b_changed = true;
			}
			if(event.delta < 0) {
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

		protected function onMouseWheelTimer(event: TimerEvent): void
		{
			if(!mb_finalChangeOccuredAfterWheelZoom) {
				// noone else commited a final area change, so let's do it 
				container.setViewBBox(container.getViewBBox(), true);
			}
		}
		
		override public function draw(graphics: Graphics): void
		{
			super.draw(graphics);
			if(_r != null) {
				graphics.beginFill(0, 0.5);
				graphics.drawRect(_r.x, _r.y, _r.width, _r.height);
				graphics.endFill();
				graphics.lineStyle(1, 0xFFFFFF, 0.8);
				graphics.drawRect(_r.x, _r.y, _r.width, _r.height);
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