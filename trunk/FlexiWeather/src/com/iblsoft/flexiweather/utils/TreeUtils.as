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
							return obj.data;
						}
						else
						{
							if (obj.hasOwnProperty("children"))
							{
								var retObject: Object = getItemByPropertyName(item, propertyName, obj.children);
								if (retObject)
									return retObject;
							}
						}
					}
				}
			}
			else
			{
				if (model is Object)
				{
					if (model[propertyName] == item[propertyName])
						return model.data;
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
						if (obj == item)
						{
							//item is found
							return parent;
						}
						else
						{
							if (obj.hasOwnProperty("children"))
							{
								var parentItem: Object = getParent(item, obj.children, obj);
								if (parentItem)
									return parentItem;
							}
						}
					}
				}
			}
			else
			{
				if (model is Object)
					trace("TreeUtils.getParent Model is object");
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
						}
						else
						{
							if (obj.hasOwnProperty("children"))
								return getParentByPropertyName(item, propertyName, obj.children, obj);
						}
					}
				}
			}
			else
			{
				if (model is Object)
					trace("object");
			}
			return parent;
		}

		public static function getAllNodesForOpen(model: Object, nodesArray: ArrayCollection): void
		{
			var obj: Object;
			if (model is ArrayCollection)
			{
				var arr: ArrayCollection = model as ArrayCollection;
				if (arr.length > 0)
				{
					for each (obj in arr)
					{
						getAllNodesForOpen(obj, nodesArray);
						/*
						if (obj.hasOwnProperty("children"))
						{
							nodesArray.addItem(obj);

							getAllNodesForOpen(obj.children, nodesArray);
						}*/
					}
				}
			}
			else
			{
				if (model is Object)
				{
					if ((model as Object).hasOwnProperty("children"))
					{
						nodesArray.addItem(model);
						for each (obj in(model as Object).children)
						{
							getAllNodesForOpen(obj, nodesArray);
						}
					}
				}
			}
		}
	/**
	 * Return path to item in dataProvider.
	 * @param item
	 * @param dataProvider
	 * @return
	 *
	 */
	/*
	public static function getPath( item: Object, dataObject: Object, pathLimiter: String = '/'): String
	{
		var pathObject: Object = {currentPath: '', limiter: pathLimiter};
		if (getItemPathByProperty(item, dataObject, pathObject, ''))
			return pathObject.currentPath;

		return null;
	}

	public static function getPathByPropertyName( item: Object, dataObject: Object, propertyName: String, pathLimiter: String = '/'): String
	{
		var pathObject: Object = {currentPath: '', limiter: pathLimiter};
		if (getItemPathByProperty(item, dataObject, pathObject, propertyName))
			return pathObject.currentPath;

		return null;
	}


	private static function getItemPathByProperty(item: Object, dataObject: Object, pathObject: Object, propertyName: String = ''): Boolean
	{
		var pathFound: Boolean;
		var dataItem: Object;
		var isByProperty: Boolean = propertyName != '';
		var pathLimiter: String = pathObject.limiter;

		if (dataObject is ArrayCollection)
		{
			var dataProvider: ArrayCollection = dataObject as ArrayCollection;
			for each (dataItem in dataProvider)
			{
				pathFound = getItemPathByProperty(item, dataItem, pathObject, propertyName);
				if (pathFound)
					return true
			}
		} else {
			if (dataObject is Object)
			{
				if (isByProperty)
				{
					pathObject.currentPath += pathLimiter + dataObject[propertyName];
					if (item[propertyName] == dataObject[propertyName])
					{
						return true;
					}
				} else {
					pathObject.currentPath += pathLimiter + dataObject.name;
					if (item == dataObject)
					{
						return true;
					}
				}

				if (dataObject.hasOwnProperty('children'))
				{
					var children: ArrayCollection = dataObject.children;
					if (children.length > 0)
					{
						for each (dataItem in children)
						{
							pathFound = getItemPathByProperty(item, dataItem, pathObject, propertyName);
							if (pathFound)
								return true
						}
					}
				}
			}
		}

		return false;
	}
	*/
	}
}
