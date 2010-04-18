package com.iblsoft.flexiweather.ogc.editable
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWFS;
	import com.iblsoft.flexiweather.ogc.WFSFeatureBase;
	
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	
	public class WFSFeatureEditable extends WFSFeatureBase
			implements IEditableItem, IHighlightableItem, ISelectableItem
	{
		protected var mb_selected: Boolean;
		protected var mb_highlighted: Boolean;
		protected var mb_modified: Boolean = false;
		protected var m_editableSprite: Sprite = new Sprite();
		protected var ml_movablePoints: Array = [];

		protected var m_editableItemManager: IEditableItemManager;
		protected var m_master: InteractiveLayerWFSEditable;

		public function WFSFeatureEditable(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
			addChild(m_editableSprite);
			m_editableSprite.visible = false;
		}
		
		override public function update(master: InteractiveLayerWFS): void
		{
			super.update(master);
			m_master = InteractiveLayerWFSEditable(master);
			var eim: IEditableItemManager = IEditableItemManager(master); 

			var mp: MoveablePoint;
			var i: uint;
			for(i = 0; i < m_points.length; ++i) {
				if(i >= ml_movablePoints.length) {
					mp = new MoveablePoint(this, i);
					ml_movablePoints.push(mp);
					m_editableSprite.addChild(mp);
					eim.addEditableItem(mp);
					continue;
				}
				mp = ml_movablePoints[i];
				var pt: Point = getPoint(i);
				if(pt == null)
					continue;  // TODO: check for CRS
				if(!mp.getPoint().equals(pt)) {
					// reuse MoveablePoint instance, just change it's location 
					mp.setPoint(pt);
				}
			}
			for(; i < ml_movablePoints.length; ++i) {
				mp = ml_movablePoints[i];
				eim.removeEditableItem(mp);
				m_editableSprite.removeChild(mp);
			}
			m_editableSprite.visible = mb_selected;
		}
		
		public function toInsertGML(xmlInsert: XML): void
		{}

		public function toUpdateGML(xmlUpdate: XML): void
		{}

		public function setPoint(i_pointIndex: uint, pt: Point): void
		{
			m_points[i_pointIndex] = pt;
			m_coordinates[i_pointIndex] = m_master.container.pointToCoord(pt.x, pt.y);
			update(m_master);
			modified = true;
		}
		
		public function insertPointBefore(i_pointIndex: uint, pt: Point): void
		{
			m_points.addItemAt(pt, i_pointIndex);
			m_coordinates.addItemAt(m_master.container.pointToCoord(pt.x, pt.y), i_pointIndex);
			update(m_master);
			modified = true;
		}
		
		public function deselect(): void
		{
			if(selected)
				m_editableItemManager.selectItem(null);
		}

		public function snapPoint(ptClicked: Point, ignoredFeature: WFSFeatureEditable = null): Point
		{
			var ptClickedStage: Point = localToGlobal(ptClicked);
			var a_snapPoints: Array = m_editableItemManager.doHitTest(
					ptClickedStage.x, ptClickedStage.y, MoveablePoint, false);
			for each(var mp: MoveablePoint in a_snapPoints) {
				if(ignoredFeature != null && mp.getFeature() == ignoredFeature)
					continue;
				return mp.getPoint();
			}
			return ptClicked;
		}

		// IEditableItem implementation
		public function onRegisteredAsEditableItem(eim: IEditableItemManager): void
		{
			m_editableItemManager = eim;
			for each(var mp: MoveablePoint in ml_movablePoints)
				m_editableItemManager.addEditableItem(mp);
		}
	
		public function onUnregisteredAsEditableItem(eim: IEditableItemManager): void
		{
			for each(var mp: MoveablePoint in ml_movablePoints)
				eim.removeEditableItem(mp);
		}
	
		public function get editPriority(): int
		{ return 50; }

		// IHighlightableItem implementation
		public function canReleaseHighlight(): Boolean
		{ return true; }

		public function set highlighted(b: Boolean): void
		{
			if(mb_highlighted != b) {
				mb_highlighted = b;
				updateGlow();
			}
		}
	
		public function get highlighted(): Boolean
		{ return mb_highlighted; }

		protected function updateGlow(): void
		{
			if(mb_selected != m_editableSprite.visible) {
				m_editableSprite.visible = mb_selected;
			}
			if(!mb_highlighted && !mb_selected) {
				filters = null; // [ new GlowFilter(0xff0000, 1, 8, 8, 4) ];
				return;
			}

			var i_innerGlowColor: uint = 0;
			var i_outterGlowColor: uint = 0;
			if(mb_highlighted)
				i_innerGlowColor = 0xffffff;
			if(mb_selected)
				i_outterGlowColor = 0xffff00;
			filters = [ new GlowFilter(i_innerGlowColor, 1, 6, 6, 2), new GlowFilter(i_outterGlowColor, 1, 8, 8, 4) ];
		}

		public function set selected(b: Boolean): void
		{
			if(mb_selected != b) {
				mb_selected = b;
				updateGlow();
			}
		}
	
		public function get selected(): Boolean
		{ return mb_selected; }

		public function set modified(b: Boolean): void
		{ mb_modified = b; }
	
		public function get modified(): Boolean
		{ return mb_modified; }

		public function get master(): InteractiveLayerWFSEditable
		{ return m_master; }
	}
}
