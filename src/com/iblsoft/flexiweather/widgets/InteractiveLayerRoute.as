package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.proj.Coord;
	
	import flash.display.Graphics;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	
	public class InteractiveLayerRoute extends InteractiveLayer
	{
		protected var ma_coords: ArrayCollection = new ArrayCollection();
		protected var m_highlightedCoord: Coord = null;
		protected var m_selectedCoord: Coord = null;
//		protected var m_highlightedLineFrom: Coord = null;

		public static const CHANGE: String = "interactiveLayerRouteChanged";
		 
		public function InteractiveLayerRoute(container: InteractiveWidget)
		{
			super(container);
			ma_coords.addEventListener(CollectionEvent.COLLECTION_CHANGE, onCoordsCollectionChanged);
		}
		
		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			ma_coords.removeAll();
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
				ma_coords.addItem(c);
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
				var i: int = ma_coords.getItemIndex(m_selectedCoord);
				ma_coords.setItemAt(c, i);
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
				var i: int = ma_coords.getItemIndex(c);
				ma_coords.removeItemAt(i);
				invalidateDynamicPart();
			}
			return true;
		}
		
		protected function onCoordsCollectionChanged(event: CollectionEvent): void
		{
			invalidateDynamicPart();
		}
		
		override public function draw(graphics: Graphics): void
		{
			super.draw(graphics);
			var ptPrev: Point;
			var pt: Point;
			for each(var c: Coord in ma_coords) {			
				pt = container.coordToPoint(c);
				if(ptPrev != null) {
					// draw glow
					graphics.beginFill(0);
					graphics.lineStyle(6, 0x000000, 1, false, LineScaleMode.NORMAL, null, JointStyle.MITER);
					graphics.moveTo(ptPrev.x, ptPrev.y);
					graphics.lineTo(pt.x, pt.y);
					graphics.endFill();

					graphics.beginFill(0x000000, 1);
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

					graphics.beginFill(0);
					graphics.lineStyle(4, 0x00FF00, 1, false, LineScaleMode.NORMAL, null, JointStyle.MITER);
					graphics.moveTo(ptPrev.x, ptPrev.y);
					graphics.lineTo(pt.x, pt.y);
					graphics.endFill();

					graphics.beginFill(0x00FF00, 1);
					graphics.moveTo(pt.x - ptDiff2.x, pt.y - ptDiff2.y);
					graphics.lineTo(pt.x + ptPerp.x - ptDiff.x, pt.y + ptPerp.y - ptDiff.y);
					graphics.lineTo(pt.x - ptPerp.x - ptDiff.x, pt.y - ptPerp.y - ptDiff.y);
					graphics.lineTo(pt.x - ptDiff2.x, pt.y - ptDiff2.y);
					graphics.endFill();
				}
				ptPrev = pt;
			}
			for each(c in ma_coords) {			
				pt = container.coordToPoint(c);
				graphics.beginFill(m_highlightedCoord != c ? 0x00FF00 : 0xFFFFFF, 1);
				graphics.lineStyle(1, 0x000000, 1);
				graphics.drawCircle(pt.x, pt.y, 6);
				graphics.endFill();
			}
		}

		protected function getHitCoord(ptHit: Point): Coord
		{		
			var cBest: Coord = null;
			var f_best: Number = NaN;
			for each(var c: Coord in ma_coords) {
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
		
		// getters & setters
		public function get coords(): ArrayCollection
		{ return ma_coords; }
	}
}
