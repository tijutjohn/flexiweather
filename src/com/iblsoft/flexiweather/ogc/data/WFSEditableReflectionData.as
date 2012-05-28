package com.iblsoft.flexiweather.ogc.data
{
	import com.iblsoft.flexiweather.ogc.editable.MoveablePoint;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	public class WFSEditableReflectionData extends ReflectionData
	{
		protected var _moveablePoints: Array;
		protected var _annotations: Array;
		
		public function get moveablePoints(): Array
		{
			return _moveablePoints;
		}
		public function get annotations(): Array
		{
			return _annotations;
		}
		
		public function WFSEditableReflectionData(iw:InteractiveWidget)
		{
			super(iw);
			
			_annotations = [];
			_moveablePoints = [];
		}
		
		override public function remove(): void
		{
			super.remove();
			
			_moveablePoints = null;
			_annotations = null;
		}
		
		override public function removeItemAt(pointer: int): void
		{
			super.removeItemAt(pointer);
			
			_moveablePoints.splice(pointer, 1);
			_annotations.splice(pointer, 1);
		}
		
		public function addMoveablePoint(mp: MoveablePoint, pointer: int): void
		{
			_moveablePoints[pointer] = mp;	
		}
		
		public function addAnnotation(annotation: AnnotationBox, pointer: int): void
		{
			_annotations[pointer] = annotation;	
		}
	}
}