package com.iblsoft.flexiweather.ogc.multiview.data
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;

	import mx.collections.ArrayCollection;

	public class MultiViewCustomData implements Serializable
	{
		private var _dataProvider: ArrayCollection;
		public var selectedIndex: int;
		public var timeDifference: int;
		private var _synchronizeFrame: Boolean = true;
		private var _synchronizeArea: Boolean = true;

		public function MultiViewCustomData(selectedIndex: int = -1, timeDifference: int = -1)
		{
			_dataProvider = new ArrayCollection();
			this.selectedIndex = selectedIndex;
			this.timeDifference = timeDifference;
		}



		public function get synchronizeFrame():Boolean
		{
			return _synchronizeFrame;
		}

		public function set synchronizeFrame(value:Boolean):void
		{
			_synchronizeFrame = value;
		}

		public function get synchronizeArea():Boolean
		{
			return _synchronizeArea;
		}

		public function set synchronizeArea(value:Boolean):void
		{
			_synchronizeArea = value;
		}

		public function get dataProvider():ArrayCollection
		{
			return _dataProvider;
		}

		public function set dataProvider(value:ArrayCollection):void
		{
			_dataProvider = value;
		}

		public function serialize(storage:Storage):void
		{
			selectedIndex = storage.serializeInt("selected-index", selectedIndex);
			timeDifference = storage.serializeInt("time-difference", timeDifference);
			synchronizeFrame = storage.serializeBool("synchronize-frame", synchronizeFrame);
			synchronizeArea = storage.serializeBool("synchronize-area", synchronizeArea);

			var arr: Array = [];
			if (storage.isStoring())
			{
				if (dataProvider && dataProvider.length > 0)
				{
					for each (var item: Object  in _dataProvider)
					{
						if (item)
						{
							if (item is MultiViewDataProviderItem)
								arr.push(item);
							else {
								var newItem: MultiViewDataProviderItem = new MultiViewDataProviderItem();
								if (item.hasOwnProperty('label'))
									newItem.label = item.label;
								if (item.hasOwnProperty('enabled'))
									newItem.enabled = item.enabled;
								if (item.hasOwnProperty('level'))
									newItem.level = item.level;
								if (item.hasOwnProperty('run'))
									newItem.run = item.run;
								if (item.hasOwnProperty('name'))
									newItem.name = item.name;
								if (item.hasOwnProperty('fullPath'))
									newItem.fullPath = item.fullPath;
								arr.push(newItem);
							}
						}
					}

					storage.serializeNonpersistentArray('data-provider', arr, MultiViewDataProviderItem);
				}
			} else {
				try {
					storage.serializeNonpersistentArray('data-provider', arr, MultiViewDataProviderItem);

				} catch (e: Error) {
					trace("MultiViewCustomData: cannot restore data provider");
				}
				_dataProvider = new ArrayCollection(arr);
			}

		}


	}
}