package com.iblsoft.flexiweather.ogc.editable.data.jetstream
{
	import com.iblsoft.flexiweather.ogc.editable.IEditableItemManager;
	import com.iblsoft.flexiweather.ogc.editable.IHighlightableItem;
	import com.iblsoft.flexiweather.ogc.editable.IMouseEditableItem;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	import com.iblsoft.flexiweather.ogc.editable.data.MoveablePoint;
	import com.iblsoft.flexiweather.ogc.editable.features.curves.WFSFeatureEditableJetStream;
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.getTimer;
	
	public class MoveableWindPoint extends MoveablePoint
		implements IMouseEditableItem, IHighlightableItem
	{
	
//		private var _debugTF: TextField;
		
		/**
		 * 
		 */
		public function MoveableWindPoint(feature: WFSFeatureEditable, i_pointIndex:uint, i_reflection: uint, i_reflectionDelta: int)
		{
			super(feature, i_pointIndex, i_reflection, i_reflectionDelta);
			
			m_pt = WFSFeatureEditableJetStream(feature).getWindPoint(i_pointIndex, i_reflection);
	
//			_debugTF = new TextField();
//			addChild(_debugTF);
			
			update();
		}
		
		private function updateDebugTextfield(txt: String = ''): void
		{
			return;
			
//			if (m_pt && _debugTF)
//			{
//				var space: int = mb_highlighted ? 30 : 24;
//				_debugTF.x = - (space / 2);
//				_debugTF.y = - (space / 2);
//				
//				_debugTF.text = txt + space + "/" + mi_pointIndex + "/" + getTimer();
//				_debugTF.border = true;
//				_debugTF.autoSize = TextFieldAutoSize.LEFT;
//				var format: TextFormat = _debugTF.getTextFormat();
//				format.color = 0xffffff;
//				format.size = 14;
//				_debugTF.setTextFormat(format);
//			}
		}
		
		override protected function draw(): void
		{
			var space: int = mb_highlighted ? 12 : 8;
			
			graphics.clear();
			
			graphics.lineStyle(1, 0x000000);
			graphics.beginFill(mb_selected ? 0x993399 : 0x66CC00, 0.8);
			graphics.drawRect(- (space / 2), - (space / 2), space, space);
			graphics.endFill();
			
			updateDebugTextfield();
		}
		
		
	
		// IMouseEditableItem implementation
		override public function onMouseMove(pt: Point, event: MouseEvent): Boolean
		{
			if(!mb_dragging)
				return false;
			
			m_pt = pt;
			update();
			
			
			if (m_feature is WFSFeatureEditableJetStream){
				WFSFeatureEditableJetStream(m_feature).setWindPoint(mi_pointIndex, m_pt, mi_reflectionDelta);
			}
			
			return true;
		}
		
		override public function onMouseDoubleClick(pt: Point, event: MouseEvent): Boolean
		{
			return false;
		}
		
		/**
		 * 
		 */
		override public function onMouseDown(pt: Point, event: MouseEvent): Boolean
		{
			if ((m_feature is WFSFeatureEditableJetStream) && !selected){
				WFSFeatureEditableJetStream(m_feature).selectedWindPointIndex = mi_pointIndex;
			}
			
			m_editableItemManager.setMouseMoveCapture(this);
			m_editableItemManager.setMouseClickCapture(this);
			mb_dragging = true;
			
			return true;
		}
		
		override public function onMouseUp(pt: Point, event: MouseEvent): Boolean
		{
			if(!mb_dragging)
				return false;
			m_editableItemManager.releaseMouseMoveCapture(this);
			m_editableItemManager.releaseMouseClickCapture(this);
				mb_dragging = false;
				
			return true;
		}
		
	}
}