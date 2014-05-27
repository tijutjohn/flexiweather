package com.iblsoft.flexiweather.widgets.controls
{
	import mx.collections.IList;
	import mx.events.CollectionEvent;
	
	import spark.components.DropDownList;
	
	public class InteractiveDropDownList extends DropDownList
	{
		override public function set dataProvider(value:IList):void
		{ 
			
			if (super.dataProvider)
				super.dataProvider.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onDataProviderChange);
			
			super.dataProvider = value;

			onDataProviderChange();
			
			if (super.dataProvider)
				super.dataProvider.addEventListener(CollectionEvent.COLLECTION_CHANGE, onDataProviderChange);
		}
			
		public function InteractiveDropDownList()
		{
			super();
		}
		
		private function onDataProviderChange(event: CollectionEvent = null): void
		{
			
			if (dataProvider && dataProvider.length > 0)
			{
				var maxChars: int = 0;
				var newTypicalItem: Object;
				for each (var item: Object in dataProvider)
				{
					var displayText: String;
					displayText = itemToLabel(item);
					if (displayText.length > maxChars)
					{
						maxChars = displayText.length;
						newTypicalItem = item;
					}
				}
				typicalItem = newTypicalItem;
			}
			
			invalidateSize();
			invalidateDisplayList();
		}
	}
}