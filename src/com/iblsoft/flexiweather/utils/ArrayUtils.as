package com.iblsoft.flexiweather.utils
{
	import mx.collections.ArrayCollection;
	
	public class ArrayUtils
	{
		/** Duplicates ArrayCollection instance, but keeps original item references. */
		public static function dupArrayCollection(a: ArrayCollection): ArrayCollection
		{
			if(a == null)
				return null;
			var b: ArrayCollection = new ArrayCollection();
			for each(var o: Object in a) {
				b.addItem(o);
			}
			return b;
		}

		/** Duplicates Array instance, but keeps original item references. */
		public static function dupArray(a: Array): Array
		{
			if(a == null)
				return null;
			var b: Array = [];
			for(var o: Object in a) {
				b[o] = a[o];
			}
			return b;
		}
		
		public static function filterRemoveEmptyStrings(o: Object, dummy1: Object = null, dummy2: Object = null): Boolean
		{
			if(o == null)
				return false; // treat null object as emptry string
			if(!o is String)
				return true; // keep non-Strings in the array
			return (o as String).length > 0;
		}
		
		
		public static function intersectedArrays(a1: Array, a2: Array): Array
		{
			if(a1 == null || a2 == null)
				return [];
			var a: Array = [];
			for each(var o: Object in a1) {
//				var id: int = a2.indexOf(o, 0);
//				if(id >= 0)	
//					a.push(o);
				if(isObjectInside(a2, o))
					a.push(o);
			}
			return a;
		}

		public static function unionArrays(a_dest: Array, a_with: Array): void
		{
			for each(var o: Object in a_with) {
//				if(a_dest.indexOf(o) < 0)
				if(!isObjectInside(a_dest, o))
					a_dest.push(o); 
			}
		}
		public static function isObjectInside(arr: Array, obj: Object): Boolean
		{
			for each(var o: Object in arr)
			{
				if (obj is String && o is String)
				{
					if (obj == o)
						return true;
				} else {
					if (obj is Object && o is Object)
					{
						if (obj.label == o.label)
							return true;
					}
				}
			}
			return false;
		}
		public static function isValueInside(a_source: Array, value: Object): Boolean
		{
			for each(var o: Object in a_source) {
				if (value == o)
					return true; 
			}
			return false;
		}
		public static function getItemIndexByPropertyName(a_source: ArrayCollection, propertyName: String, value: Object): int
		{
			for (var i: int = 0; i < a_source.length; i++)
			{
				var item: Object = a_source[i];
				if (item[propertyName] == value)
					return i;
			} 
			return -1;
		}
		
		public static function getFilteredArrayFromArrayCollection(ac: ArrayCollection): Array
		{
			var a: Array = [];
			for each (var item: * in ac)
			{
				a.push(item);
			}
			return a;
		}
	}
}