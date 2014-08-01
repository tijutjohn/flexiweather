package com.iblsoft.flexiweather.ogc.editable.data.jetstream
{
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;
	import com.iblsoft.flexiweather.ogc.data.WFSEditableReflectionData;
	import com.iblsoft.flexiweather.ogc.editable.features.curves.WFSFeatureEditableJetStreamWindBarb;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Sprite;
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	
	public class WindReflectionData extends WFSEditableReflectionData
	{
		private var _moveableWindPoints: Array;
		private var _editableJetStreamWindbarbs: Array;
		private var _windbarbs: ArrayCollection;
		public var jetstreamCurvePoints: Array;
		
		override public function get annotation():AnnotationBox
		{
			return null;
		}
		
		public function WindReflectionData(iw:InteractiveWidget)
		{
			super(iw);
			
			cleanup();
		}
		
		public function get totalWindPoints(): uint
		{
			if (_moveableWindPoints)
				return _moveableWindPoints.length;
			
			return 0;
		}
		public function get windPoints(): Array
		{
			return _moveableWindPoints;
		}
		public function get editableJetStreamWindbarbs(): Array
		{
			return _editableJetStreamWindbarbs;
		}
		public function get windbarbs(): ArrayCollection
		{
			return _windbarbs;
		}
		
		private function onWindbarbsChange(event: CollectionEvent): void
		{
			switch (event.kind)
			{
				case CollectionEventKind.REMOVE:
					trace("remove windbarb");
					break;
			}
		}
		override public function remove(): void
		{
			super.remove();
			_windbarbs = null;
			_editableJetStreamWindbarbs = null;
			_moveableWindPoints = null;
		}
		override public function cleanup(): void
		{
			super.cleanup();
			_windbarbs = new ArrayCollection();	
			_windbarbs.addEventListener(CollectionEvent.COLLECTION_CHANGE, onWindbarbsChange);
			
			_editableJetStreamWindbarbs = [];	
			_moveableWindPoints = [];	
		}
		
		override public function removeItemAt(pointer: int): void
		{
			super.removeItemAt(pointer);
			
//			if (windbarbs && windbarbs.length > pointer)
//				_windbarbs.removeItemAt(pointer);
//			if (_editableJetStreamWindbarbs && _editableJetStreamWindbarbs.length > pointer)
//				_editableJetStreamWindbarbs.splice(pointer, 1);
//			if (_moveableWindPoints && _moveableWindPoints.length > pointer)
//				_moveableWindPoints.splice(pointer, 1);
		}
		
		override public function addAnnotation(annotation: AnnotationBox): void
		{
			
		}
		
		public function removeWindbarbAt(position: int): void
		{
			if (windbarbs && windbarbs.length > position)
				_windbarbs.removeItemAt(position);
			if (_editableJetStreamWindbarbs && _editableJetStreamWindbarbs.length > position)
				_editableJetStreamWindbarbs.splice(position, 1);
			if (_moveableWindPoints && _moveableWindPoints.length > position)
				_moveableWindPoints.splice(position, 1);
		}
		
		public function updateWindbarbAt(windbarb: WindBarb, position: int): void
		{
			if (_windbarbs.length == position)
			{
				addWindbarbAt(windbarb, position);
			} else {
				_windbarbs.setItemAt(windbarb, position);
			}
		}
		public function addWindbarbAt(windbarb: WindBarb, position: int): void
		{
			_windbarbs.addItemAt(windbarb, position);
		}
		public function addWindbarb(windbarb: WindBarb): void
		{
			_windbarbs.addItem(windbarb);
		}
		
		public function addWindMoveablePoint(mp: MoveableWindPoint, pointer: int, cp: WFSFeatureEditableJetStreamWindBarb): void
		{
			_moveableWindPoints[pointer] = mp;
			_editableJetStreamWindbarbs[pointer] = cp;
		}
	}
}