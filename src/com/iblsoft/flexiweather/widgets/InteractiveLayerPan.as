package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.ogc.BBox;
	
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	public class InteractiveLayerPan extends InteractiveLayer
	{
		internal var _p: Point;
		internal var mb_requireShiftKey: Boolean = true;
		
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
        	_p = new Point(event.localX, event.localY);
        	return true;
        }

        override public function onMouseUp(event: MouseEvent): Boolean
        {
			if(_p == null)
				return false;
			if(doPanTo(new Point(event.localX, event.localY), true)) {
	        	//invalidateDynamicPart();
	        }
        	_p = null;
        	return true;
        }
        
        override public function onMouseMove(event:MouseEvent):Boolean
        {
			if(_p == null)
				return false;
			if(doPanTo(new Point(event.localX, event.localY), false)) {
	        	invalidateDynamicPart();
	        }
        	return true;
        }

        protected function doPanTo(p: Point, b_finalChange: Boolean): Boolean
        {
			var pDiff: Point = p.subtract(_p);
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