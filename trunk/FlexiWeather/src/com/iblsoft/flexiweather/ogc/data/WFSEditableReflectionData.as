package com.iblsoft.flexiweather.ogc.data
{
	import com.iblsoft.flexiweather.ogc.editable.MoveablePoint;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	public class WFSEditableReflectionData extends ReflectionData
	{
		protected var _moveablePoints: Array;
		protected var _annotation: AnnotationBox;

		public function get moveablePoints(): Array
		{
			return _moveablePoints;
		}

		public function get annotation(): AnnotationBox
		{
			return _annotation;
		}

		public function WFSEditableReflectionData(iw: InteractiveWidget)
		{
			super(iw);
			_moveablePoints = [];
		}

		override public function remove(): void
		{
			super.remove();
			_moveablePoints = null;
			_annotation = null;
		}

		override public function removeItemAt(pointer: int): void
		{
			super.removeItemAt(pointer);
			
			var mp: MoveablePoint;
			
			var removedPoints: Array = _moveablePoints.splice(pointer, 1);
			if (removedPoints && removedPoints.length > 0)
			{
				mp = removedPoints[0] as MoveablePoint;
				if (mp.parent)
				{
					mp.parent.removeChild(mp);
				}
			} else {
				trace("WFSEditableReflectionData: cannot find point for removing");
			}
//			_annotations.splice(pointer, 1);
			//update pointIndex of moveable points after remove point
			var total: int = _moveablePoints.length;
			for (var i: int = pointer; i < total; i++)
			{
				mp = _moveablePoints[i] as MoveablePoint;
				mp.pointIndex--;
			}
		}

		public function addMoveablePoint(mp: MoveablePoint, pointer: int): void
		{
			_moveablePoints[pointer] = mp;
		}

		public function addAnnotation(annotation: AnnotationBox): void
		{
			_annotation = annotation;
//			_annotations[pointer] = annotation;	
		}
	}
}
