package com.iblsoft.flexiweather.components
{
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import spark.components.DropDownList;

	public class IndexRetainingDropDownList extends DropDownList
	{
		override public function set dataProvider(value: IList): void
		{
//			var originalSelection: Object = this.selectedItem;
			super.dataProvider = value;
//			var newIdx: int = getOriginalSelectionIndex(originalSelection);
//			this.selectedIndex = newIdx;
		}

		override public function set selectedIndex(value: int): void
		{
			super.selectedIndex = value;
		}

		public function IndexRetainingDropDownList()
		{
			super();
		}

		protected function getOriginalSelectionIndex(originalSelection: Object): int
		{
			var ac: ArrayCollection = dataProvider as ArrayCollection;
			if (ac)
				return ac.getItemIndex(originalSelection);
			return -1;
		}
	}
}
