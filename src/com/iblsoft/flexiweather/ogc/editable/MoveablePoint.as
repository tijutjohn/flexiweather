package com.iblsoft.flexiweather.ogc.editable
{
	import flash.display.Sprite;
	import flash.geom.Point;
	
	public class MoveablePoint extends Sprite
			implements IMouseEditableItem, IHighlightableItem
	{
		protected var m_feature: WFSFeatureEditable;
		protected var mi_pointIndex: uint;
	
		protected var m_pt: Point;
		
		protected var mb_highlighted: Boolean = false;
		protected var mb_selected: Boolean = false;
		
		protected var m_editableItemManager: IEditableItemManager;
		protected var mb_dragging: Boolean = false;
	
		public function MoveablePoint(feature: WFSFeatureEditable, i_pointIndex: uint)
		{
			super();
	
			doubleClickEnabled = true;

			m_feature = feature;
			mi_pointIndex = i_pointIndex;
			m_pt = feature.getPoint(i_pointIndex);
	
			update();
		}
		
		public function update(): void
		{
			graphics.clear();

			graphics.lineStyle(mb_highlighted ? 4 : 2, 0x000000);
			graphics.beginFill(mb_selected ? 0x00ff00 : 0xffff00, 0.8);
			graphics.drawCircle(m_pt.x, m_pt.y, mb_highlighted ? 7 : 5);
			graphics.endFill();
		}
		
		public function onRegisteredAsEditableItem(eim: IEditableItemManager): void
		{ m_editableItemManager = eim; }
	
		public function onUnregisteredAsEditableItem(eim: IEditableItemManager): void
		{ m_editableItemManager = null; }

		public function get editPriority(): int
		{ return 100; }
	
		// IHighlightableItem implementation
		public function canReleaseHighlight(): Boolean
		{
			return !mb_dragging; 
		}
	
		public function set highlighted(b: Boolean): void
		{
			if(mb_highlighted != b) {
				mb_highlighted = b;
				update();
			}
		}
	
		public function get highlighted(): Boolean
		{ return mb_highlighted; }
	
		// IMouseEditableItem implementation
		public function onMouseMove(pt: Point): Boolean
		{
			if(!mb_dragging)
				return false;
			m_pt = pt;
			update();
			m_feature.setPoint(mi_pointIndex, m_pt);
			return true;
		}
	
		public function onMouseClick(pt: Point): Boolean
		{ return false; }
	
		public function onMouseDoubleClick(pt: Point): Boolean
		{
			m_feature.deselect();
			if(m_feature is IClosableCurve && m_feature.coordinates.length > 2) {
				if(mi_pointIndex == 0) {
					var closableCurve: IClosableCurve = IClosableCurve(m_feature);
					if(!closableCurve.isCurveClosed())
						closableCurve.closeCurve();
				}
			}
			return true;
		}
	
		public function onMouseDown(pt: Point): Boolean
		{
			m_editableItemManager.setMouseMoveCapture(this);
			m_editableItemManager.setMouseClickCapture(this);
			mb_dragging = true;
			return true;
		}
	
		public function onMouseUp(pt: Point): Boolean
		{
			if(!mb_dragging)
				return false;
			m_editableItemManager.releaseMouseMoveCapture(this);
			m_editableItemManager.releaseMouseClickCapture(this);
				mb_dragging = false;
			if(mi_pointIndex == 0 || mi_pointIndex == (m_feature.getPoints().length - 1)) {
				// if finished moving of first of last point...
				if(m_feature is IClosableCurve && m_feature.getPoints().length >= 2) {
					// ... of a closable curve with more than 2 points ...
					var closableCurve: IClosableCurve = IClosableCurve(m_feature);
					if(!closableCurve.isCurveClosed()) {
						// ... which is not closed yet
						var ptFirst: Point = m_feature.getPoint(0);
						var ptLast: Point = m_feature.getPoint(m_feature.getPoints().length - 1);
						var f_dist: Number = (ptFirst.subtract(ptLast)).length;
						if(f_dist < 5) {
							closableCurve.closeCurve();
							m_feature.removePoint(m_feature.getPoints().length - 1);
						}
					}
				}
			}
			return true;
		}
		
		public function getPoint(): Point
		{ return m_pt; }

		public function setPoint(pt: Point): void
		{
			if(!pt.equals(m_pt)) {
				m_pt = pt;
				update();
			}
		}
		
		public function getFeature(): WFSFeatureEditable
		{ return m_feature; }
		
		public function get selected(): Boolean
		{
			return(mb_selected);
		}
		
		public function set selected(val: Boolean): void
		{
			mb_selected = val;
			
			update();
		}
	}
}