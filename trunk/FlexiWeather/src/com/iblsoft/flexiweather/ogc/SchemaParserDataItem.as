package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import flash.events.EventDispatcher;
	import mx.utils.UIDUtil;

	public class SchemaParserDataItem extends EventDispatcher
	{
		public static const TYPE_STRING: String = 'string';
		public static const TYPE_LOCATION: String = 'location';
		public static const TYPE_DATE: String = 'dateTime';
		public static const TYPE_DOUBLE: String = 'double';
		public static const TYPE_DECIMAL: String = 'decimal';
		public static const TYPE_INTEGER: String = 'integer';
		public static const TYPE_BOOLEAN: String = 'boolean';
		public static const TYPE_COMPLEX_TYPE: String = 'complexType';
		public var name: String;
		/**
		 * after parsing of saved data, we store full name here to remember it for later use.
		 */
		public var tempFullName: String;

		/**
		 *
		 */
		public function get fullName(): String
		{
			var retName: String = name;
			if (parentItem)
				retName = parentItem.fullName + "/" + retName;
			return retName;
		}

		/**
		 *
		 */
		public function get fullNameNoRoot(): String
		{
			var retName: String = fullName;
			// CUT FIRST NAME
			var parts: Array = retName.split('/');
			parts.shift();
			retName = parts.join('/');
			return retName;
		}
		public var type: String;
		public var nullable: Boolean;
		public var parentItem: SchemaParserDataItem;
		public var childrenParameters: Array;
		public var attributes: Array;
		public var isReferenced: Boolean = false;
		public var minOccurs: int;
		public var maxOccurs: int;

		public function get isMandatory(): Boolean
		{
			return minOccurs > 0;
		}

		public function get hasChildren(): Boolean
		{
			return (childrenParameters && childrenParameters.length > 0);
		}
		public var uid: String;

		/**
		 *
		 */
		public function SchemaParserDataItem()
		{
			uid = UIDUtil.createUID();
		}

		/**
		 *
		 */
		public function isChildOf(parent: SchemaParserDataItem): Boolean
		{
			if (parentItem == parent)
				return true;
			if (parentItem)
				return parentItem.isChildOf(parent);
			return false;
		}

		/**
		 *
		 */
		public function addChild(child: SchemaParserDataItem): void
		{
			if (!childrenParameters)
				childrenParameters = new Array();
			child.parentItem = this;
			childrenParameters.push(child);
		}

		/**
		 *
		 */
		public function addAttribute(attribute: SchemaParserDataItemAttribute): void
		{
			if (!attributes)
				attributes = new Array();
			attributes.push(attribute);
		}

		/**
		 * Return all scalar items for this data item. If item is complex type and had children
		 * it will return all children
		 * @return
		 *
		 */
		public function getScalarItems(typeFilter: Array = null): Array
		{
			if (type != TYPE_COMPLEX_TYPE)
			{
				if (typeFilter)
				{
					if (resolveTypeFilter(typeFilter))
						return [this];
					else
						return null;
				}
				else
					return [this];
			}
			else
			{
				var items: Array = [];
				if (childrenParameters && childrenParameters.length > 0)
				{
					for each (var dataItem: SchemaParserDataItem in childrenParameters)
					{
						var childrenScalarItems: Array = dataItem.getScalarItems(typeFilter);
						ArrayUtils.unionArrays(items, childrenScalarItems);
					}
					return items;
				}
			}
			return null;
		}

		/**
		 *
		 */
		protected function resolveTypeFilter(typeFilter: Array): Boolean
		{
			for each (var tFilter: String in typeFilter)
			{
				if (tFilter == type)
					return (true);
			}
			return (false);
		}

		/**
		 *
		 */
		public function getScalarValues(responseXML: *): Array
		{
			var items: Array = [];
			if (type != TYPE_COMPLEX_TYPE)
				return (resolveValueFromXML(responseXML));
			else
			{
				if (childrenParameters && childrenParameters.length > 0)
				{
					for each (var dataItem: SchemaParserDataItem in childrenParameters)
					{
						var responseChilds: XMLList;
						//if (parentItem == null){
						//	responseChilds = new XMLList(responseXML);
						//} else {
						responseChilds = XMLList(responseXML).elements(dataItem.name);
						//var k = responseXML.children();
						//}
						var childrenScalarItems: Array;
						for each (var responseChild: XML in XMLList(responseXML).children())
						{
							if (responseChild.localName() == dataItem.name)
							{
								childrenScalarItems = dataItem.getScalarValues(responseChild);
								ArrayUtils.unionArrays(items, childrenScalarItems);
							}
						}
					}
					return items;
				}
			}
			return null;
		}

		/**
		 *
		 */
		protected function resolveValueFromXML(responseXML: *): Array
		{
			var ret: Array = [];
			if (responseXML is XML)
			{
				var resObj: Object = new Object();
				resObj.name = fullNameNoRoot;
				resObj.value = parseValue(String(XML(responseXML).text()));
				ret = [resObj];
			}
			else if (responseXML is XMLList)
			{
				// TODO - MORE VALUES
			}
			return (ret);
		}

		/**
		 *
		 */
		protected function parseValue(value: String): *
		{
			switch (type)
			{
				case SchemaParserDataItem.TYPE_STRING:
				{
					return (String(value));
				}
				case SchemaParserDataItem.TYPE_DATE:
				{
					return (ISO8601Parser.stringToDate(value));
				}
				case SchemaParserDataItem.TYPE_DECIMAL:
				case SchemaParserDataItem.TYPE_DOUBLE:
				{
					return (Number(value));
				}
				case SchemaParserDataItem.TYPE_INTEGER:
				{
					return (int(value));
				}
				default:
				{
					return (value);
				}
			}
		}

		/**
		 *
		 */
		public function clone(): SchemaParserDataItem
		{
			var item: SchemaParserDataItem = new SchemaParserDataItem();
			item.name = name;
			item.type = type;
			item.nullable = nullable;
			item.minOccurs = minOccurs;
			item.maxOccurs = maxOccurs;
			if (parentItem)
				item.parentItem = parentItem;
			item.childrenParameters = [];
			if (childrenParameters && childrenParameters.length > 0)
			{
				for each (var child: SchemaParserDataItem in childrenParameters)
				{
					item.addChild(child.clone());
						//item.childrenParameters.push(child.clone());	
				}
			}
			return item;
		}
	}
}
