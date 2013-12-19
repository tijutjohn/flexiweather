package com.iblsoft.flexiweather.ogc.multiview.data
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;

	public class MultiViewViewData implements Serializable
	{
		private var _dataProvider: Array;
		
		public function MultiViewViewData()
		{
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
			storage.serializeNonpersistentArray('data-provider', dataProvider, ViewData);
			
		}
	}
}

import com.iblsoft.flexiweather.utils.Serializable;
import com.iblsoft.flexiweather.utils.Storage;

class ViewData implements Serializable
{
	
	public var data: int;
	public var label: String;

	public function serialize(storage: Storage): void
	{
		data = storage.serializeInt('data', data);
		label = storage.serializeString('label', label);
	}
}