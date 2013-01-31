package com.iblsoft.flexiweather.utils
{

	public class XMLStorage extends Storage
	{
		internal var m_xml: XML;
		internal var m_current: XML;

		public function XMLStorage(xml: XML = null)
		{
			super(xml != null ? LOADING : STORING);
			if (xml != null)
			{
				m_xml = xml;
				m_current = m_xml;
			}
			else
			{
				m_xml = <X-IBLSTORAGE version="1.1"/>
						;
				m_current = m_xml;
			}
		}

		public static function getXMLNode(xml: XML, nodeName: String): XML
		{
			var children: XMLList = xml.children();
			for each (var node: XML in children)
			{
				if (node.localName() == nodeName)
				{
					return node;
				}
			}
			return null;
		}
		
		public static function addHeaderToXML(xml: XML): XML
		{
			if (xml)
			{
				var updatedXML: XML = <X-IBLSTORAGE version="1.1"/>;
				updatedXML.appendChild(xml);
				
				return updatedXML;
			}
			return null;
		}
		override public function hasKey(s_key: String, i_index: uint /* = NONINDEXED*/): Boolean
		{
			if (isCurrentRoot())
			{
				if (i_index == NONINDEXED)
					return m_current.elements(s_key).length() > 0;
				else
					return i_index < m_current.elements(s_key).length();
			}
			else
				return (i_index == NONINDEXED && m_current.attribute(s_key).length() > 0) || i_index < m_current.elements(s_key).length();
		}

		override protected function __serializeString(s_key: String, i_index: uint /* = NONINDEXED*/, s: String, s_default: String = null): String
		{
			if (isLoading())
			{
				var s: String = getStringValue(s_key, i_index);
				if (s == null)
					return s_default;
				return s;
			}
			else
			{
				setStringValue(s_key, i_index, s);
				return s;
			}
		}

		override protected function __serializeInt(s_key: String, i_index: uint /* = NONINDEXED*/, i: int, i_default: int = 0): int
		{
			if (isLoading())
			{
				var s: String = getStringValue(s_key, i_index);
				if (s == null)
					return i_default;
				return int(s);
			}
			else
			{
				setStringValue(s_key, i_index, String(i));
				return i;
			}
		}

		override protected function __serializeUInt(s_key: String, i_index: uint /* = NONINDEXED*/, i: uint, i_default: uint = 0): uint
		{
			if (isLoading())
			{
				var s: String = getStringValue(s_key, i_index);
				if (s == null)
					return i_default;
				return uint(s);
			}
			else
			{
				setStringValue(s_key, i_index, String(i));
				return i;
			}
		}

		override protected function __serializeBool(s_key: String, i_index: uint /* = NONINDEXED*/, b: Boolean, b_default: Boolean = false): Boolean
		{
			if (isLoading())
			{
				var s: String = getStringValue(s_key, i_index);
				if (s == null)
					return b_default;
				return s != "false";
			}
			else
			{
				setStringValue(s_key, i_index, b ? "true" : "false");
				return b;
			}
		}

		override protected function __serializeNumber(s_key: String, i_index: uint /* = NONINDEXED*/, f: Number, f_default: Number = NaN): Number
		{
			if (isLoading())
			{
				var s: String = getStringValue(s_key, i_index);
				if (s == null)
					return f_default;
				return Number(s);
			}
			else
			{
				setStringValue(s_key, i_index, String(f));
				return f;
			}
		}

		override public function commit(): void
		{
		}

		override protected function downLevel(s_key: String, i_index: uint /*= NONINDEXED*/): Object
		{
			var currentBackup: XML = m_current;
			var ch: XMLList;
			if (mb_mode == STORING)
			{
				ch = m_current.elements(s_key);
				if (i_index < ch.length())
					m_current = ch[i_index]; // storing into existing sub-element
				else
				{
					// create a new sub-element 
					m_current = <{s_key}/>
							;
					currentBackup.appendChild(m_current);
				}
			}
			else
			{
				ch = m_current.elements(s_key);
				if (i_index == NONINDEXED)
					i_index = 0;
				if (i_index >= ch.length())
					return null; // node index probably out of range 
				m_current = ch[i_index];
			}
			return currentBackup;
		}

		override protected function upLevel(restorePoint: Object): void
		{
			m_current = XML(restorePoint);
		}

		private function setStringValue(s_key: String, i_index: uint /*= NONINDEXED*/, s_value: String): void
		{
			if (i_index == NONINDEXED)
			{
				if (!isCurrentRoot())
				{
					s_key = fixAttributeKey(s_key, i_index);
					if (s_value != null)
						m_current[s_key] = s_value;
					else
						delete m_current[s_key];
					return;
				}
				i_index = 0;
			}
			if (s_value == null)
				s_value = "";
			var ch: XMLList = m_current.elements(s_key);
			if (i_index < ch.length())
			{
				ch[i_index] = <{s_key}>{s_value}</{s_key}>
						;
			}
			else
			{
				m_current.appendChild(<{s_key}>{s_value}</{s_key}>
						);
			}
		}

		private function getStringValue(s_key: String, i_index: uint /*= NONINDEXED*/): String
		{
			if (i_index == NONINDEXED)
			{
				if (!isCurrentRoot())
				{
					s_key = fixAttributeKey(s_key, i_index);
					return s_key in m_current ? String(m_current[s_key]) : null;
				}
				i_index = 0;
			}
			var ch: XMLList = m_current.elements(s_key);
			if (ch[i_index])
				return String(ch[i_index]);
			else
				return null;
		}

		private function fixAttributeKey(s_key: String, i_index: uint): String
		{
			if (!(m_current == m_xml))
				s_key = '@' + s_key;
			return s_key;
		}

		private function isCurrentRoot(): Boolean
		{
			return m_current == m_xml;
		}

		// getter & setters
		public function get xml(): XML
		{
			return m_xml;
		}
	}
}
