package com.iblsoft.flexiweather.utils
{
	import mx.collections.ArrayCollection;

	public class ArrayUtils
	{
		/** Duplicates ArrayCollection instance, but keeps original item references. */
		public static function dupArrayCollection(a: ArrayCollection): ArrayCollection
		{
			if (a == null)
				return null;
			var b: ArrayCollection = new ArrayCollection();
			for each (var o: Object in a)
			{
				b.addItem(o);
			}
			return b;
		}

		/** Duplicates Array instance, but keeps original item references. */
		public static function dupArray(a: Array): Array
		{
			if (a == null)
				return null;
			var b: Array = [];
			for (var o: Object in a)
			{
				b[o] = a[o];
			}
			return b;
		}

		public static function filterRemoveEmptyStrings(o: Object, dummy1: Object = null, dummy2: Object = null): Boolean
		{
			if (o == null)
				return false; // treat null object as emptry string
			if (!o is String)
				return true; // keep non-Strings in the array
			return (o as String).length > 0;
		}

		public static function intersectedArrays(
				a1: Array, a2: Array, comparator: Function = null): Array
		{
			if (comparator == null)
				comparator = Operators.equalsStrictly;
			if (a1 == null || a2 == null)
				return [];
			var a: Array = [];
			for each (var o: Object in a1)
			{
				if (isInside(a2, o, comparator))
					a.push(o);
			}
			return a;
		}

		public static function unionArrays(
				a_dest: Array, a_with: Array, comparator: Function = null): void
		{
			if (comparator == null)
				comparator = Operators.equalsStrictly;
			for each (var o: Object in a_with)
			{
				if (!isInside(a_dest, o, comparator))
					a_dest.push(o);
			}
		}

		public static function isInside(
				arr: Array, obj: Object, comparator: Function = null): Boolean
		{
			if (comparator == null)
				comparator = Operators.equalsStrictly;
			for each (var o: Object in arr)
			{
				if (comparator(obj, o))
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

		public static function getFilteredArrayFromArrayCollection(a_source: ArrayCollection): Array
		{
			var a: Array = [];
			for each (var item: * in a_source)
			{
				a.push(item);
			}
			return a;
		}

		public static function swapItemsInArrayCollectionSource(ac: ArrayCollection, item: Object, newPosition: int): void
		{
			var id: int = ac.getItemIndex(item);
			if (id >= 0)
			{
				//only do swap if item is already in collection
				if (id != newPosition)
				{
					//swap will be done, because position are not same
					var swapObject: Object = ac.source[newPosition];
					ac.source[newPosition] = item;
					ac.source[id] = swapObject;
				}
			}
		}
	}
}
