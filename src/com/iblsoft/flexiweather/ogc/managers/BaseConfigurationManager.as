package com.iblsoft.flexiweather.ogc.managers
{
	import flash.events.EventDispatcher;
	
	import mx.utils.ObjectUtil;

	public class BaseConfigurationManager extends EventDispatcher
	{
		protected var groups: Array = [];
		protected var submenuPos: int = 0;

		private var _latestMenuItemsList: XMLList;
		
		public function BaseConfigurationManager()
		{
		}


		public function get latestMenuItemsList():XMLList
		{
			return _latestMenuItemsList;
		}

		public function set latestMenuItemsList(value:XMLList):void
		{
			_latestMenuItemsList = value;
//			trace(this + " latestMenuItemsList: " + _latestMenuItemsList.toXMLString);
		}

		protected function sortArray(item1: Object, item2: Object, array: Array = null): int
		{
			//if item has not defined labels do not compare it
			if (!item1.label || !item2.label)
				return 1;
			var label1: String = fixLabel(item1.label).toLowerCase();
			var label2: String = fixLabel(item2.label).toLowerCase();
			var isFolder1: Boolean = isFolder(label1);
			var isFolder2: Boolean = isFolder(label1);
			if (isFolder1 && !isFolder2)
				return 1;
			else
			{
				if (!isFolder1 && isFolder2)
					return -1;
				else
				{
					if ((isFolder1 && isFolder2) || (!isFolder1 && !isFolder2))
						return ObjectUtil.compare(label1, label2);
				}
			}
			return 0;
		}

		private function isFolder(path: String): Boolean
		{
			return path.indexOf('/') >= 0;
		}

		protected function fixLabel(lbl: String): String
		{
			if (!lbl)
				return null;
			var test: String = 'global/';
			if (lbl.indexOf(test) == 0)
				return lbl.substr(test.length);
			test = 'groups/';
			if (lbl.indexOf(test) == 0)
				return lbl.substr(test.length);
			test = 'users/';
			if (lbl.indexOf(test) == 0)
				return 'user/' + lbl.substr(test.length);
			return lbl;
		}

		/**
		 * Creates folders and subfolders for custom areas
		 * @param groupName - full group name... it can consists subfolders. Use / for subolders. E.g Continents/States
		 * @param areasXMLList - root menu item
		 * @return
		 *
		 */
		protected function createGroupSubfoldersAndGetParent(groupName: String, itemXMLList: XML): XML
		{
			var groupParentXML: XML;
			var currGroupParentXML: XML = itemXMLList;
			var groupObject: Object;
			var parentGroupObject: Object;
			var groupsArr: Array;
			//check if there is more levels (split by "/")
			groupsArr = groupName.split('/');
			var level: int = 0;
			var position: int;
			var currJoinedGroupName: String = ''
			for each (var currGroupName: String in groupsArr)
			{
				if (level == 0)
					currJoinedGroupName = currGroupName;
				else
					currJoinedGroupName += '/' + currGroupName
				if (!groups[currJoinedGroupName])
				{
					groupParentXML = <menuitem label={currGroupName}/>
							;
					groupObject = new Object();
					groupObject.parent = groupParentXML;
					groupObject.submenuPos = 0;
					groups[currJoinedGroupName] = groupObject;
					if (level == 0)
						position = submenuPos;
					else
						position = parentGroupObject.submenuPos;
					var len: int = currGroupParentXML.elements().length();
					if (len == 0)
						currGroupParentXML.appendChild(groupParentXML);
					else
					{
						if (position > 0)
							currGroupParentXML.insertChildAfter(currGroupParentXML.elements()[position - 1], groupParentXML);
						else
							currGroupParentXML.insertChildBefore(currGroupParentXML.elements()[position], groupParentXML);
					}
					if (level == 0)
						submenuPos++;
					else
						parentGroupObject.submenuPos++;
				}
				else
				{
					groupObject = groups[currJoinedGroupName];
					groupParentXML = groupObject.parent as XML;
				}
				parentGroupObject = groupObject;
				currGroupParentXML = groupParentXML;
				level++;
			}
			return groupParentXML;
		}
		
		
	}
}
