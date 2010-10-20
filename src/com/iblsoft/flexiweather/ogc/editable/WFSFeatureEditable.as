package com.iblsoft.flexiweather.ogc.editable
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWFS;
	import com.iblsoft.flexiweather.ogc.WFSFeatureBase;
	
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
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
		protected var mi_editMode: int = WFSFeatureEditableMode.ADD_POINTS_WITH_MOVE_POINTS;
		
		protected var mb_useMonochrome: Boolean = false;
		protected var mi_monochromeColor: uint = 0x333333;
		
		protected var ma_points: Array;
		
		protected var m_editableItemManager: IEditableItemManager;

		public function WFSFeatureEditable(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
			m_editableSprite.visible = false;
		}
		
		override public function setMaster(master: InteractiveLayerWFS): void
		{
			super.setMaster(master);
			var masterEditable: InteractiveLayerWFSEditable = master as InteractiveLayerWFSEditable;
			if(masterEditable != null)
				masterEditable.editingComponentsContainer.addChild(m_editableSprite);
		}
		
		override public function update(): void
		{
			super.update();
			var eim: IEditableItemManager = master as IEditableItemManager; 

			var mp: MoveablePoint;
			var i: uint;
			for(i = 0; i < m_points.length; ++i) {
				if(i >= ml_movablePoints.length) {
					mp = new MoveablePoint(this, i);
					ml_movablePoints.push(mp);
					m_editableSprite.addChild(mp);
					if(eim != null)
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
				if(eim != null)
					eim.removeEditableItem(mp);
				m_editableSprite.removeChild(mp);
			}
			while(m_points.length < ml_movablePoints.length) {
				ml_movablePoints.pop();
			}
			m_editableSprite.visible = mb_selected;
		}

		override public function cleanup(): void
		{
			super.cleanup();

			var masterEditable: InteractiveLayerWFSEditable = master as InteractiveLayerWFSEditable;
			if(masterEditable != null)
				masterEditable.editingComponentsContainer.removeChild(m_editableSprite);

			for each(var mp: MoveablePoint in ml_movablePoints)
				m_editableSprite.removeChild(mp);
			ml_movablePoints = [];
		}
		
		public function renderFallbackGraphics(i_preferredColor: uint = 0x5A90B1): void {
			graphics.clear();
			graphics.lineStyle(1, i_preferredColor);
			if(m_points.length == 1) {
				graphics.beginFill(i_preferredColor);
				graphics.drawRoundRect(m_points[0].x - 4, m_points[0].y - 4, 9, 9, 6, 6);
				graphics.endFill();
			}
			else {
				for(var i: uint = 0; i < m_points.length; ++i) {
					if(i == 0)
						graphics.moveTo(m_points[i].x, m_points[i].y);
					else
						graphics.lineTo(m_points[i].x, m_points[i].y);
				}
			} 
		}
		
		public function toInsertGML(xmlInsert: XML): void
		{}

		public function toUpdateGML(xmlUpdate: XML): void
		{}

		public function fromGML(gml: XML): void
		{}
		
		public function isInternal(): Boolean
		{ return false; }

		public function clone(): WFSFeatureEditable
		{
			var o: Object = this;
			var c: Class = o.constructor;
			var f: WFSFeatureEditable = new c(
					this.ms_namespace, this.ms_typeName, null);
			var xml: XML = <Feature/>; 
			this.toInsertGML(xml);
			f.fromGML(xml);
			return f;
		}

		// helper methods for GML serialisation

		public function addInsertGMLProperty(xmlInsert: XML,
				s_namespace: String, s_property: String, value: Object): void
		{
			if(s_namespace == null)
				s_namespace = ms_namespace;
			var p: XML = <{s_property} xmlns={s_namespace}/>;
			p.appendChild(value);
			xmlInsert.appendChild(p);
		}

		public function addUpdateGMLProperty(xmlUpdate: XML,
				s_namespace: String, s_property: String, value: Object): void
		{
			if(s_namespace == null)
				s_namespace = ms_namespace;
			var p: XML = <wfs:Property xmlns:wfs="http://www.opengis.net/wfs"/>;
			p.appendChild(<wfs:Name xmlns:wfs="http://www.opengis.net/wfs" xmlns:ns={s_namespace}>ns:{s_property}</wfs:Name>);
			var v: XML = <wfs:Value xmlns:wfs="http://www.opengis.net/wfs"/>;
			v.appendChild(value);
			p.appendChild(v);
			xmlUpdate.appendChild(p);
		}

		// point/location manipulation helpers

		public function setPoint(i_pointIndex: uint, pt: Point): void
		{
			m_points[i_pointIndex] = pt;
			m_coordinates[i_pointIndex] = m_master.container.pointToCoord(pt.x, pt.y);
			update();
			modified = true;
		}
		
		public function insertPointBefore(i_pointIndex: uint, pt: Point): void
		{
			m_points.addItemAt(pt, i_pointIndex);
			m_coordinates.addItemAt(m_master.container.pointToCoord(pt.x, pt.y), i_pointIndex);
			update();
			modified = true;
		}
		
		public function removePoint(i_pointIndex: uint): void
		{
			m_points.removeItemAt(i_pointIndex);
			m_coordinates.removeItemAt(i_pointIndex);
			update();
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
		
		public function onKeyDown(evt: KeyboardEvent): Boolean
		{ return false; }
		
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

		public function set editMode(v: int): void
		{
			mi_editMode = v;
		}
			
		public function get editMode(): int
		{ return mi_editMode; }
		
		public function set useMonochrome(val: Boolean): void
		{
			var b_needUpdate: Boolean = false;
			if(mb_useMonochrome != val)
				b_needUpdate = true;
			
			mb_useMonochrome = val;
			
			if(b_needUpdate)
				update();
		}
		
		public function get useMonochrome(): Boolean
		{ return mb_useMonochrome; }
		
		public function set monochromeColor(i_color: uint): void
		{
			var b_needUpdate: Boolean = false;
			if (mb_useMonochrome && (mi_monochromeColor != i_color))
				b_needUpdate = true;
			
			mi_monochromeColor = i_color;
			
			if (b_needUpdate)
				update();
		}
		
		public function get monochromeColor(): uint
		{ return mi_monochromeColor; }
	}
}
