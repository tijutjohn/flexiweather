package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.proj.Coord;
	
	import flash.display.Graphics;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	
	public class InteractiveLayerRoute extends InteractiveLayer
	{
		private var _ma_coords: ArrayCollection;
		protected var m_highlightedCoord: Coord = null;
		protected var m_selectedCoord: Coord = null;
//		protected var m_highlightedLineFrom: Coord = null;

		public static const CHANGE: String = "interactiveLayerRouteChanged";
		 
		public function InteractiveLayerRoute(container: InteractiveWidget)
		{
			super(container);
			setStyle("routeColor", 0x000000);
			setStyle("routeAlpha", 1.0);
			setStyle("routeFillColor", 0x00FF00);
			setStyle("routeFillAlpha", 1.0);
			setStyle("pointColor", 0x000000);
			setStyle("pointAlpha", 1.0);
			setStyle("pointFillColor", 0x00FF00);
			setStyle("pointFillAlpha", 1.0);
			setStyle("pointHighlightFillColor", 0xFFFFFF);
			setStyle("pointHighlightFillAlpha", 1.0);
			coords  = new ArrayCollection();
		}
		
		[Bindable (event="coordsChanged")]
		public function get coords():ArrayCollection
		{
			return _ma_coords;
		}

		public function set coords(value:ArrayCollection):void
		{
			if (_ma_coords)
				_ma_coords.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onCoordsCollectionChanged);
			_ma_coords = value;
			if (_ma_coords)
				_ma_coords.addEventListener(CollectionEvent.COLLECTION_CHANGE, onCoordsCollectionChanged);
		}

		private function notifyChange(): void
		{
			dispatchEvent(new Event("coordsChanged"));
		}
		
		public function clearRoute(): void
		{
			_ma_coords.removeAll();
		}
		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			invalidateDynamicPart();
		}

		override public function onMouseDown(event: MouseEvent): Boolean
		{
			if(event.shiftKey || event.ctrlKey)
				return false;
			var c: Coord = container.pointToCoord(event.localX, event.localY);
			if(c == null)
				return false;

			var cHit: Coord = getHitCoord(new Point(event.localX, event.localY));
			if(cHit != null) {
				//setHighlightedCoord(cHit);
				m_selectedCoord = cHit;
			}
			else {
				_ma_coords.addItem(c);
				notifyChange();
				
				setHighlightedCoord(c);
				m_selectedCoord = c;
			}
			return true;
		}

		override public function onMouseUp(event: MouseEvent): Boolean
		{
			if(event.shiftKey || event.ctrlKey)
				return false;
			m_selectedCoord = null;
			invalidateDynamicPart();
			return true;
		}
		
		override public function onMouseMove(event: MouseEvent): Boolean
		{
			if(event.shiftKey || event.ctrlKey)
				return false;
			var c: Coord;
			if(m_selectedCoord == null) {
				var mousePt: Point = new Point(event.localX, event.localY);
				c = getHitCoord(mousePt);
				setHighlightedCoord(c);
			}
			else {
				c = container.pointToCoord(event.localX, event.localY);
				var i: int = _ma_coords.getItemIndex(m_selectedCoord);
				_ma_coords.setItemAt(c, i);
				notifyChange();
				
				m_selectedCoord = c;
				m_highlightedCoord = c;
				invalidateDynamicPart();				
			}
			return true;
		}
		
		override public function onMouseDoubleClick(event: MouseEvent): Boolean
		{
			if(event.shiftKey || event.ctrlKey)
				return false;
			var c: Coord;
			var mousePt: Point = new Point(event.localX, event.localY);
			c = getHitCoord(mousePt);
			if(c != null) {
				var i: int = _ma_coords.getItemIndex(c);
				_ma_coords.removeItemAt(i);
				notifyChange();
				
				invalidateDynamicPart();
			}
			return true;
		}
		
		protected function onCoordsCollectionChanged(event: CollectionEvent): void
		{
			trace("onCoordsCollectionChanged: " + _ma_coords.length);
			invalidateDynamicPart();
		}
		
		override public function draw(graphics: Graphics): void
		{
			super.draw(graphics);
			var ptPrev: Point;
			var pt: Point;
			var i_routeColor: uint = uint(getStyle("routeColor"));
			var f_routeAlpha: uint = Number(getStyle("routeAlpha"));
			var i_routeFillColor: uint = uint(getStyle("routeFillColor"));
			var f_routeFillAlpha: uint = Number(getStyle("routeFillAlpha"));
			var i_pointColor: uint = uint(getStyle("pointColor"));
			var f_pointAlpha: uint = Number(getStyle("pointAlpha"));
			var i_pointFillColor: uint = uint(getStyle("pointFillColor"));
			var f_pointFillAlpha: uint = Number(getStyle("pointFillAlpha"));
			var i_pointHighlightFillColor: uint = uint(getStyle("pointHighlightFillColor"));
			var f_pointHighlightFillAlpha: uint = Number(getStyle("pointHighlightFillAlpha"));
			for each(var c: Coord in _ma_coords) {			
				pt = container.coordToPoint(c);
				if(ptPrev != null) {
					// draw glow
					graphics.beginFill(i_routeColor, f_routeAlpha);
					graphics.lineStyle(6, i_routeColor, f_routeAlpha, false, LineScaleMode.NORMAL, null, JointStyle.MITER);
					graphics.moveTo(ptPrev.x, ptPrev.y);
					graphics.lineTo(pt.x, pt.y);
					graphics.endFill();

					graphics.beginFill(i_routeFillColor, f_routeFillAlpha);
					var ptDiff: Point = pt.subtract(ptPrev);
					ptDiff.normalize(15);
					var ptDiff2: Point = new Point(ptDiff.x, ptDiff.y);
					ptDiff2.normalize(8);
					var ptPerp: Point = new Point(ptDiff.y, -ptDiff.x);
					ptPerp.normalize(5); 
					graphics.moveTo(pt.x - ptDiff2.x, pt.y - ptDiff2.y);
					graphics.lineTo(pt.x + ptPerp.x - ptDiff.x, pt.y + ptPerp.y - ptDiff.y);
					graphics.lineTo(pt.x - ptPerp.x - ptDiff.x, pt.y - ptPerp.y - ptDiff.y);
					graphics.lineTo(pt.x - ptDiff2.x, pt.y - ptDiff2.y);
					graphics.endFill();

					graphics.beginFill(i_routeFillColor, f_routeFillAlpha);
					graphics.lineStyle(4, i_routeFillColor, f_routeFillAlpha, false, LineScaleMode.NORMAL, null, JointStyle.MITER);
					graphics.moveTo(ptPrev.x, ptPrev.y);
					graphics.lineTo(pt.x, pt.y);
					graphics.endFill();

					graphics.beginFill(i_routeFillColor, f_routeFillAlpha);
					graphics.moveTo(pt.x - ptDiff2.x, pt.y - ptDiff2.y);
					graphics.lineTo(pt.x + ptPerp.x - ptDiff.x, pt.y + ptPerp.y - ptDiff.y);
					graphics.lineTo(pt.x - ptPerp.x - ptDiff.x, pt.y - ptPerp.y - ptDiff.y);
					graphics.lineTo(pt.x - ptDiff2.x, pt.y - ptDiff2.y);
					graphics.endFill();
				}
				ptPrev = pt;
			}
			for each(c in _ma_coords) {			
				pt = container.coordToPoint(c);
				graphics.beginFill(
						m_highlightedCoord != c ? i_pointFillColor : i_pointHighlightFillColor,
						f_pointFillAlpha);
				graphics.lineStyle(1, i_pointColor, f_pointAlpha);
				graphics.drawCircle(pt.x, pt.y, 6);
				graphics.endFill();
			}
		}

		protected function getHitCoord(ptHit: Point): Coord
		{		
			var cBest: Coord = null;
			var f_best: Number = NaN;
			for each(var c: Coord in _ma_coords) {
				var pt: Point = container.coordToPoint(c);
				var f_dist: Number = pt.subtract(ptHit).length;
				if((f_dist <= 7 && cBest == null) || f_dist < f_best) {
					f_best = f_dist;
					cBest = c;
				}
			}
			return cBest;
		}

		protected function setHighlightedCoord(c: Coord): void
		{
			if(m_highlightedCoord != c) {
				m_highlightedCoord = c;
				invalidateDynamicPart();
			}
		}
		
	}
}
