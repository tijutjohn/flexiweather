package com.iblsoft.flexiweather.utils
{
	import mx.collections.ArrayCollection;
	
	public class TreeUtils
	{
		public function TreeUtils()
		{
		}
		
		
		/********************************************************************
		 * 
		 * Functions for getting Item
		 * 
		 *******************************************************************/
		 
		public static function getItemByPropertyName(item: Object, propertyName: String, model: Object): Object
		{
			if (model is ArrayCollection)
			{
				var arr: ArrayCollection = model as ArrayCollection;
				if (arr.length > 0)
				{
					for each (var obj: Object in arr)
					{
						if (obj[propertyName] == item[propertyName])
						{
							//item is found
							return obj;
						} else {
							if (obj.hasOwnProperty("children"))
							{
								return getItemByPropertyName(item, propertyName, obj.children);
							}
						}
					}
				}
			} else {
				if (model is Object)
				{
					if (model[propertyName] == item[propertyName])
						return  model;
				}
			}
			
			return null;
		}
		
		/********************************************************************
		 * 
		 * Functions for getting parent
		 * 
		 *******************************************************************/
		public static function getParent(item: Object, model: Object, parent: Object = null): Object
		{
			if (model is ArrayCollection)
			{
				var arr: ArrayCollection = model as ArrayCollection;
				if (arr.length > 0)
				{
					for each (var obj: Object in arr)
					{
						trace("TreeUtils.getParent ARR, obj: " + obj.label);
						if (obj == item)
						{
							trace("TreeUtils.getParent ARR, obj: " + obj.label + " PARENT FOUND: " + parent);
							//item is found
							return parent;
						} else {
							if (obj.hasOwnProperty("children"))
							{
								trace("TreeUtils.getParent ARR, obj: " + obj.label + " has children");
								var parentItem: Object = getParent(item, obj.children, obj);
								if (parentItem)
									return parentItem;
							}
						}
					}
				}
			} else {
				if (model is Object)
				{
					trace("TreeUtils.getParent Model is object");
				}
			}
			
			return null;
		}
		
		
		public static function getParentByPropertyName(item: Object, propertyName: String, model: Object, parent: Object = null): Object
		{
			if (model is ArrayCollection)
			{
				var arr: ArrayCollection = model as ArrayCollection;
				if (arr.length > 0)
				{
					for each (var obj: Object in arr)
					{
						if (obj[propertyName] == item[propertyName])
						{
							//item is found
							return parent;
						} else {
							if (obj.hasOwnProperty("children"))
							{
								return getParentByPropertyName(item, propertyName, obj.children, obj);
							}
						}
					}
				}
			} else {
				if (model is Object)
				{
					trace("object");
				}
			}
			
			return parent;
		}

	}
}