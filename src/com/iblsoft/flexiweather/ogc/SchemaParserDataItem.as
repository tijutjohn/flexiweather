package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	
	import flash.events.EventDispatcher;
	
	public class SchemaParserDataItem extends EventDispatcher
	{
		public static const TYPE_STRING: String 	= 'string';
		public static const TYPE_LOCATION: String 	= 'location';
		public static const TYPE_DATE: String 		= 'dateTime';
		public static const TYPE_DOUBLE: String 	= 'double';
		public static const TYPE_DECIMAL: String 	= 'decimal';
		public static const TYPE_INTEGER: String 	= 'integer';
		public static const TYPE_BOOLEAN: String 	= 'boolean';
		public static const TYPE_COMPLEX_TYPE: String = 'complexType';
		
		public var name:String;
		
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
			{
				retName = parentItem.fullName + "/" +retName;
			}
			
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
		
		public var type:String;
		public var nullable:Boolean;
		
		public var parentItem: SchemaParserDataItem;
		public var childrenParameters:Array;
		
		public var attributes:Array;
		
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
		
		/**
		 * 
		 */
		public function SchemaParserDataItem()
		{
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
		public function addAttribute(attribute: SchemaParserDataItemAttribute):void
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
		public function getScalarItems(): Array
		{
			if (type != TYPE_COMPLEX_TYPE)
				return [this];
			else {
				var items: Array = [];
				if (childrenParameters && childrenParameters.length > 0)
				{
					for each (var dataItem: SchemaParserDataItem in childrenParameters)
					{
						var childrenScalarItems: Array = dataItem.getScalarItems();
						ArrayUtils.unionArrays(items, childrenScalarItems);
					}
					return items;
				}
			}
			
			return null;	
		}
		
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
					item.childrenParameters.push(child.clone());	
				}
			}
			
			return item;
		}
	}
}