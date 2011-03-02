package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	
	import mx.collections.ArrayCollection;

	public class LayerArrayCollection extends ArrayCollection
	{
		public var layer: InteractiveLayer;
		
		private var _selectedItem: Object;
		public function get selectedItem(): Object
		{
			return _selectedItem;
		}
		public function set selectedItem(value: Object): void
		{
			_selectedItem = value;
		}
		public function LayerArrayCollection(source:Array=null)
		{
			super(source);
		}
		
	}
}