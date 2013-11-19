package com.iblsoft.flexiweather.ogc.editable
{
	import com.iblsoft.flexiweather.events.WFSCursorManagerEvent;
	import com.iblsoft.flexiweather.events.WFSCursorManagerTypes;
	import com.iblsoft.flexiweather.ogc.events.MoveablePointEvent;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.system.Capabilities;
	import flash.system.TouchscreenType;

	public class MoveablePoint extends Sprite implements IMouseEditableItem, IHighlightableItem
	{
		protected var m_feature: WFSFeatureEditable;
		private var _mi_pointIndex: uint;

		override public function set x(value:Number):void
		{
			super.x = value;
			
//			trace(this + " x = " + value);
		}
		override public function set visible(value:Boolean):void
		{
			super.visible = value;
		}
		protected function get mi_pointIndex(): uint
		{
			return _mi_pointIndex;
		}

		protected function set mi_pointIndex(value: uint): void
		{
			_mi_pointIndex = value;
		}

		public function get pointIndex(): uint
		{
			return _mi_pointIndex;
		}

		public function set pointIndex(value: uint): void
		{
			_mi_pointIndex = value;
		}
		public function get reflection(): uint
		{
			return mi_reflection;
		}
		
		protected var mi_reflection: uint;
		protected var mi_reflectionDelta: int;
		protected var m_pt: Point;
		protected var mb_highlighted: Boolean = false;
		protected var mb_selected: Boolean = false;
		protected var m_editableItemManager: IEditableItemManager;
		protected var mb_dragging: Boolean = false;
		public var m_pointCursor: int = WFSCursorManagerTypes.CURSOR_ADD_POINT;

		public function MoveablePoint(feature: WFSFeatureEditable, i_pointIndex: uint, i_reflection: uint, i_reflectionDelta: int)
		{
			super();
			doubleClickEnabled = true;
			m_feature = feature;
			mi_pointIndex = i_pointIndex;
			mi_reflection = i_reflection;
			mi_reflectionDelta = i_reflectionDelta;
			m_pt = feature.getPoint(i_pointIndex);
			//addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			//addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			draw();
			update();
		}

		public function update(): void
		{
			if (m_pt)
			{
				this.x = m_pt.x;
				this.y = m_pt.y;
			}
		}

		protected function draw(): void
		{
			graphics.clear();
			graphics.lineStyle(mb_highlighted ? 4 : 2, 0x000000);
			graphics.beginFill(mb_selected ? 0x00ff00 : 0xffff00, 0.8);
			var i_resize: uint = 0;
			var dpi: Number = Capabilities.screenDPI;
			if (Capabilities.touchscreenType == TouchscreenType.FINGER && dpi > 72)
				i_resize = 10;
			graphics.drawCircle(0, 0, i_resize + (mb_highlighted ? 7 : 5));
			graphics.endFill();
		}

		public function onRegisteredAsEditableItem(eim: IEditableItemManager): void
		{
			m_editableItemManager = eim;
		}

		public function onUnregisteredAsEditableItem(eim: IEditableItemManager): void
		{
			m_editableItemManager = null;
		}

		public function get editPriority(): int
		{
			return 100;
		}

		// IHighlightableItem implementation
		public function canReleaseHighlight(): Boolean
		{
			return !mb_dragging;
		}

		public function set highlighted(b: Boolean): void
		{
			if (mb_highlighted != b)
			{
				mb_highlighted = b;
				draw();
					//update();
			}
		}

		public function get highlighted(): Boolean
		{
			return mb_highlighted;
		}

		// IMouseEditableItem implementation
		public function onMouseMove(pt: Point, event: MouseEvent): Boolean
		{
			if (!mb_dragging)
				return false;
			m_pt = pt;
			update();
			m_feature.setPoint(mi_pointIndex, m_pt, mi_reflectionDelta);
			var mpe: MoveablePointEvent = new MoveablePointEvent(MoveablePointEvent.MOVEABLE_POINT_MOVE, true);
			mpe.point = this;
			mpe.feature = m_feature;
			mpe.x = pt.x;
			mpe.y = pt.y;
			dispatchEvent(mpe);
			return true;
		}

		public function onMouseClick(pt: Point, event: MouseEvent): Boolean
		{
			return false;
		}

		public function onMouseDoubleClick(pt: Point, event: MouseEvent): Boolean
		{
			m_feature.deselect();
			if (m_feature is IClosableCurve && m_feature.coordinates.length > 2)
			{
				if (mi_pointIndex == 0)
				{
					var closableCurve: IClosableCurve = IClosableCurve(m_feature);
					if (!closableCurve.isCurveClosed())
						closableCurve.closeCurve();
				}
			}
			return true;
		}

		public function onMouseDown(pt: Point, event: MouseEvent): Boolean
		{
//			trace("onMouseDown : " + pt);
			m_editableItemManager.setMouseMoveCapture(this);
			m_editableItemManager.setMouseClickCapture(this);
			m_feature.selectMoveablePoint(mi_pointIndex, mi_reflection);
			mb_dragging = true;
			var mpe: MoveablePointEvent = new MoveablePointEvent(MoveablePointEvent.MOVEABLE_POINT_DOWN, true);
			mpe.point = this;
			mpe.feature = m_feature;
			mpe.x = pt.x;
			mpe.y = pt.y;
			dispatchEvent(mpe);
			return true;
		}

		public function onMouseUp(pt: Point, event: MouseEvent): Boolean
		{
			if (!mb_dragging)
				return false;
			m_editableItemManager.releaseMouseMoveCapture(this);
			m_editableItemManager.releaseMouseClickCapture(this);
			mb_dragging = false;
			
			var featurePointsLength: int = m_feature.getPoints().length;
			if (mi_pointIndex == 0 || mi_pointIndex == (featurePointsLength - 1))
			{
				// if finished moving of first of last point...
				if (m_feature is IClosableCurve && featurePointsLength >= 2)
				{
					// ... of a closable curve with more than 2 points ...
					var closableCurve: IClosableCurve = IClosableCurve(m_feature);
					if (!closableCurve.isCurveClosed())
					{
						// ... which is not closed yet
						var ptFirst: Point = m_feature.getPoint(0);
						var ptLast: Point = m_feature.getPoint(featurePointsLength - 1);
						var f_dist: Number = (ptFirst.subtract(ptLast)).length;
						if (f_dist < 5)
						{
							closableCurve.closeCurve();
							m_feature.removePointAt(featurePointsLength - 1);
						}
					}
				}
			}
			
			var mpe: MoveablePointEvent 
			
//			trace("onMouseUp : " + pt);
			
			mpe = new MoveablePointEvent(MoveablePointEvent.MOVEABLE_POINT_UP, true);
			mpe.point = this;
			mpe.feature = m_feature;
			mpe.x = pt.x;
			mpe.y = pt.y;
			dispatchEvent(mpe);
			
			mpe = new MoveablePointEvent(MoveablePointEvent.MOVEABLE_POINT_CLICK, true);
			mpe.point = this;
			mpe.feature = m_feature;
			mpe.x = pt.x;
			mpe.y = pt.y;
			dispatchEvent(mpe);
			
			return true;
		}

		public function getPoint(): Point
		{
			return m_pt;
		}

		public function setPoint(pt: Point): void
		{
//			if (!pt.equals(m_pt))
//			{
				m_pt = pt;
//				trace(this + " setPoint");
				update();
//			}
		}

		public function getFeature(): WFSFeatureEditable
		{
			return m_feature;
		}

		public function get selected(): Boolean
		{
			return (mb_selected);
		}

		public function set selected(val: Boolean): void
		{
			mb_selected = val;
			draw();
		}

		public function onMouseOver(evt: MouseEvent = null): void
		{
			// IGNORE THIS IF USER IS DRAGGING THIS POINT
			//if (!mb_dragging){
			//	dispatchEvent(new WFSCursorManagerEvent(WFSCursorManagerEvent.CHANGE_CURSOR, WFSCursorManagerTypes.CURSOR_ADD_POINT, true));
			//}
		}

		public function onMouseOut(evt: MouseEvent = null): void
		{
			//if (!mb_dragging){
			//	dispatchEvent(new WFSCursorManagerEvent(WFSCursorManagerEvent.CLEAR_CURSOR));
			//}
		}

		override public function toString(): String
		{
			return "MoveablePoint: " + m_pt + " index: " + pointIndex + " reflection: " + mi_reflection + " delta: " + mi_reflection;
		}
	}
}
