package com.iblsoft.flexiweather.components
{
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import spark.components.DropDownList;
	import spark.components.supportClasses.TextBase;
	import spark.utils.LabelUtil;

	public class ResizableDropDownList extends DropDownList
	{
		override public function set dataProvider(value: IList): void
		{
			if (dataProvider)
				removeDataProviderListeners(dataProvider);
			super.dataProvider = value;
			if (value)
				addDataProviderListeners(value);
		}

		public function ResizableDropDownList()
		{
			super();
		}
		private var _typicalItemFound: Boolean;

		override protected function commitProperties(): void
		{
			super.commitProperties();
			if (!_typicalItemFound)
			{
				findLongestTypicalItem();
				_typicalItemFound = true;
			}
		}

		private function findLongestTypicalItem(): int
		{
			var calculatedWidth: Number = 50; // Set this to minimum width to start with
			var dpAc: ArrayCollection = dataProvider as ArrayCollection;
			if (dpAc && dpAc.length > 0)
			{
				var format: TextFormat = new TextFormat();
				format.font = "Times New Roman";
				format.size = 16;
				var longestItem: Object;
				for each (var item: Object in dpAc)
				{
					var str: String = LabelUtil.itemToLabel(item, labelField, labelFunction);
					var size: Rectangle = measureString(str, format);
					if (size.width > calculatedWidth)
					{
						longestItem = item;
						calculatedWidth = size.width;
					}
				}
				if (longestItem)
					typicalItem = longestItem;
			}
			return calculatedWidth;
		}

		private function measureString(str: String, format: TextFormat): Rectangle
		{
			var textField: TextField = new TextField();
			textField.defaultTextFormat = format;
			textField.text = str;
			return new Rectangle(0, 0, textField.textWidth, textField.textHeight);
		}

		private function addDataProviderListeners(dp: IList): void
		{
			if (dp is ArrayCollection)
			{
				var dpAC: ArrayCollection = dp as ArrayCollection;
				dpAC.addEventListener(CollectionEvent.COLLECTION_CHANGE, onCollectionChange);
			}
		}

		private function removeDataProviderListeners(dp: IList): void
		{
			if (dp is ArrayCollection)
			{
				var dpAC: ArrayCollection = dp as ArrayCollection;
				dpAC.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onCollectionChange);
			}
		}

		private function onCollectionChange(event: CollectionEvent): void
		{
			var type: String = event.kind;
			switch (type)
			{
				case CollectionEventKind.ADD:
				case CollectionEventKind.REMOVE:
				{
					findLongestTypicalItem();
					_typicalItemFound = true;
					break;
				}
			}
		}
	}
}
