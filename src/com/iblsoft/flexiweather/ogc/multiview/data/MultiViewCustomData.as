package com.iblsoft.flexiweather.ogc.multiview.data
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	
	import mx.collections.ArrayCollection;

	public class MultiViewCustomData implements Serializable
	{
		public var dataProvider: ArrayCollection;
		public var selectedIndex: int;
		public var timeDifference: int;
		public var synchronizeFrame: Boolean;
		
		public function MultiViewCustomData(selectedIndex: int = -1, timeDifference: int = -1)
		{
			this.selectedIndex = selectedIndex;
			this.timeDifference = timeDifference;
		}
		
		public function serialize(storage:Storage):void
		{
			selectedIndex = storage.serializeInt("selected-index", selectedIndex);
			timeDifference = storage.serializeInt("time-difference", timeDifference);
			synchronizeFrame = storage.serializeBool("synchronize-frame", synchronizeFrame);
			
		}
		
		
	}
}