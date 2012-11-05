package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import mx.collections.ArrayCollection;

	public class SchemaParser extends EventDispatcher
	{
		protected var m_schemaXML: XML;
		protected var m_Elements: ArrayCollection;

		/**
		 *
		 */
		public function SchemaParser()
		{
			super();
		}

		/**
		 *
		 */
		public function getElementByName(elementName: String): SchemaParserDataItem
		{
			for each (var eElement: SchemaParserDataItem in m_Elements)
			{
				if (eElement.name == elementName)
					return (eElement);
			}
			return (null);
		}

		/**
		*
		*/
		public function parseSchema(schemaXML: XML): void
		{
			m_schemaXML = schemaXML;
			m_Elements = new ArrayCollection();
			// USING XML OBJECT AND XML LISTS
			// ALL DEFINITION ARE IN xsd NAMESPACE
			//var defXML: XML = new XML(tmpData);
			var xsdNamespace: Namespace = m_schemaXML.namespace('xsd');
			// GET ALL elements FROM ROOT SCHEMA
			var elementsDef: XMLList = m_schemaXML.xsdNamespace::element;
			for each (var elementDef: XML in elementsDef)
			{
				m_Elements.addItem(parseElement(elementDef, m_schemaXML.xsdNamespace::*));
			}
		/*var tmp: Array = new Array();
		for (var i: uint = 0; i < m_Elements.length; i++){
			ArrayUtils.unionArrays(tmp, SchemaParserDataItem(m_Elements[i]).getScalarItems());
		}

		for each (var tItem: SchemaParserDataItem in tmp){
			trace(tItem.fullName);
		}*/
		}

		/**
		*
		*/
		public function parseElement(elementNode: XML, rootList: XMLList): SchemaParserDataItem
		{
			var ret: SchemaParserDataItem = new SchemaParserDataItem();
			if (elementNode.hasSimpleContent())
			{ // ELEMENT HAS NO CHILD NODES -> CAN BE BASIC TYPE
				// SETUP ELEMENT NAME
				ret.name = String(elementNode.@name);
				// CHECK IF ELEMENT HAS TYPE DEFINITION
				if (elementNode.hasOwnProperty('@type'))
				{
					if (isSimpleType(elementNode.@type))
					{ // ELEMENT IS SIMPLE TYPE
						ret.type = String(elementNode.@type);
						if (elementNode.hasOwnProperty('@minOccurs'))
							ret.minOccurs = int(elementNode.@minOccurs);
						if (elementNode.hasOwnProperty('@maxOccurs'))
							ret.minOccurs = int(elementNode.@maxOccurs);
					}
					else
					{ // ELEMENT HAS PROBABLY SEPARATE TYPE DEFINITION
						// SEPARATE SOME NAMESPACE DEFINITIONS BEFORE TYPE NAME
						var sType: String = String(elementNode.@type).substr(String(elementNode.@type).lastIndexOf(':') + 1); // THIS CAN BE DONE USING REG EXP
						// TRY TO FIND TYPE DEFINITION
						var defs: XMLList = rootList.(attribute('name') == sType);
						if (defs.length())
						{
							// TAKE complexType DEFINITION
							// localName() IS NAME WITHOUT ANY NAMESPACE DEFINITION
							for each (var defItem: XML in defs)
							{
								if (defItem.localName() == 'complexType')
								{
									ret.type = SchemaParserDataItem.TYPE_COMPLEX_TYPE;
									parseComplexType(defItem, ret);
								}
							}
							/*if (String(XML(defs[0]).localName()) == 'complexType'){
								ret.type = SchemaParserDataItem.TYPE_COMPLEX_TYPE;

								parseComplexType(defs[0], ret);
							}*/
						}
						else
						{
							// DID NOT FIND ANY TYPE DEFINITION FOR ELEMENT
							// TRY IF THERE IS SOME def PARAMETER
						}
					}
				}
				else
				{
					ret.type = SchemaParserDataItem.TYPE_COMPLEX_TYPE;
					// TRY TO FIND ref PARAMETER
					if (elementNode.hasOwnProperty('@ref'))
					{
						// THIS IS REFERENCED TYPE -> NOT SUPPORTED YET
						ret.isReferenced = true;
					}
				}
			}
			else
			{
				// SETUP ELEMENT NAME
				ret.name = String(elementNode.@name);
				var childs: XMLList = elementNode.children();
				for each (var child: XML in childs)
				{
					if (child.localName() == "complexType")
						parseComplexType(child, ret);
				}
			}
			return (ret);
		}

		/**
		 *
		 */
		private function parseComplexType(typeNode: XML, itemInstance: SchemaParserDataItem): void
		{
			// POSSIBLE CHILD TAGS
			// 	complexContent
			// 	sequence
			//  simpleContent
			var complexTypeXMLDef: XMLList = typeNode.children();
			//var complexTypeDef: String = String(complexTypeXMLDef.localName());
			for each (var cItem: XML in complexTypeXMLDef)
			{
				switch (String(cItem.localName()))
				{
					case 'complexContent':
					{
						parseComplexContent(cItem, itemInstance);
						break;
					}
					case 'sequence':
					{
						parseSequence(cItem, itemInstance);
						break;
					}
					case 'simpleContent':
					{
						parseSimpleContent(cItem, itemInstance);
						break;
					}
				}
			}
		}

		/**
		 *
		 */
		private function parseComplexContent(complexContentNode: XML, itemInstance: SchemaParserDataItem): void
		{
			var firstChildDef: XML;
			firstChildDef = complexContentNode.children()[0];
			switch (String(firstChildDef.localName()))
			{
				case 'extension':
				{
					// TODO RESOLVE TYPE !!!
					parseExtension(firstChildDef, itemInstance);
					break;
				}
			}
		}

		/**
		 *
		 */
		private function parseSequence(sequenceNode: XML, itemInstance: SchemaParserDataItem): void
		{
			// IF ELEMENT TYPE HAS A SEQUENCE, THIS IS COMPLEX_TYPE
			itemInstance.type = SchemaParserDataItem.TYPE_COMPLEX_TYPE;
			for each (var child: XML in sequenceNode.children())
			{
				if (String(child.localName()) == 'element')
					itemInstance.addChild(parseElement(child, sequenceNode.children()));
				else
				{
				}
			}
		}

		/**
		 *
		 */
		private function parseSimpleContent(simpleContentNode: XML, itemInstance: SchemaParserDataItem): void
		{
			for each (var child: XML in simpleContentNode.children())
			{
				if (String(child.localName()) == 'extension')
					parseExtension(child, itemInstance);
				else
				{
				}
			}
		}

		/**
		 *
		 */
		private function parseExtension(extensionNode: XML, itemInstance: SchemaParserDataItem): void
		{
			// RESOLVE EXTENSION TYPE (base PARAMETER)
			if (isSimpleType(String(extensionNode.@base)))
				itemInstance.type = String(extensionNode.@base);
			else
				itemInstance.type = SchemaParserDataItem.TYPE_COMPLEX_TYPE;
			for each (var child: XML in extensionNode.children())
			{
				if (String(child.localName()) == 'sequence')
					parseSequence(child, itemInstance);
				else if (String(child.localName()) == 'attribute')
					parseAttribute(child, itemInstance);
			}
		}

		/**
		 *
		 */
		private function parseAttribute(attributeNode: XML, itemInstance: SchemaParserDataItem): void
		{
			//itemInstance.
			var nAttribute: SchemaParserDataItemAttribute = new SchemaParserDataItemAttribute();
			nAttribute.type = String(attributeNode.@type);
			nAttribute.name = String(attributeNode.@name);
			if (attributeNode.hasOwnProperty('@use'))
				nAttribute.use_val = String(attributeNode.attribute('use'));
			if (attributeNode.hasOwnProperty('@default'))
				nAttribute.default_val = String(attributeNode.attribute('default'));
			if (attributeNode.hasOwnProperty('@fixed'))
				nAttribute.fixed = String(attributeNode.attribute('fixed'));
			itemInstance.addAttribute(nAttribute);
		}

		/**
		 *
		 */
		public function isSimpleType(typeName: String): Boolean
		{
			switch (typeName)
			{
				case 'string':
				case 'dateTime':
				case 'double':
				case 'decimal':
				case 'integer':
				case 'boolean':
				case 'date':
				case 'time':
				{
					return (true);
					break;
				}
				default:
				{
					return (false);
				}
			}
		}
	}
}
