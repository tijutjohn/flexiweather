package com.iblsoft.flexiweather.ogc.editable.data.jetstream
{
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.editable.features.curves.WFSFeatureEditableJetStreamWindBarb;

	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;

	public class JetStreamFeatureDataReflection extends FeatureDataReflection
	{
		private var _moveableWindPoints: Array;
		private var _editableJetStreamWindbarbs: Array;
		private var _windbarbs: ArrayCollection;
		public var jetstreamCurvePoints: Array;

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

		public function JetStreamFeatureDataReflection(i_reflectionData:int)
		{
			super(i_reflectionData);

			cleanup();
		}

		public function cleanup(): void
		{
			_windbarbs = new ArrayCollection();
			_windbarbs.addEventListener(CollectionEvent.COLLECTION_CHANGE, onWindbarbsChange);

			_editableJetStreamWindbarbs = [];
			_moveableWindPoints = [];
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
			if (position >= _windbarbs.length)
			{
//				addWindbarbAt(windbarb, position);
				addWindbarb(windbarb);
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