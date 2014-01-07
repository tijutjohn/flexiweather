package com.iblsoft.flexiweather.ogc.multiview.data
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;

	public class MultiViewViewData implements Serializable
	{
		private var _dataProvider: Array;
		
		public function MultiViewViewData()
		{
			_dataProvider = new Array();
		}
		
		public function get dataProvider():Array
		{
			return _dataProvider;
		}

		public function set dataProvider(value:Array):void
		{
			_dataProvider = value;
		}

		public function serialize(storage:Storage):void
		{
			var arr: Array = [];
			if (storage.isStoring())
			{
				if (dataProvider && dataProvider.length > 0)
				{
					for each (var item: Object  in _dataProvider)
					{
						if (item is MultiViewDataProviderItem)
							arr.push(item);
						else {
							var newItem: MultiViewDataProviderItem = new MultiViewDataProviderItem();
							newItem.enabled = item.enabled;
							newItem.label = item.label;
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
					
					storage.serializeNonpersistentArray('data-provider', arr, MultiViewDataProviderItem);
				}
			} else {
				try {
					storage.serializeNonpersistentArray('data-provider', arr, MultiViewDataProviderItem);
				} catch (e: Error) {
					trace("MultiViewViewData: cannot restore data provider");
				}
				_dataProvider = arr;
			}
			
		}
	}
}