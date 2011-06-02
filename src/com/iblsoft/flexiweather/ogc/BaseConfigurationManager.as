package com.iblsoft.flexiweather.ogc
{
	import flash.events.EventDispatcher;
	
	public class BaseConfigurationManager extends EventDispatcher
	{
		protected var groups:Array = [];
		protected var submenuPos: int = 0;
		
		public function BaseConfigurationManager()
		{
		}
		
		
		protected function fixLabel(lbl: String): String
		{
			var test: String = 'global/'; 
			if (lbl.indexOf(test) == 0)
				return lbl.substr(test.length);
			test = 'groups/';
			if (lbl.indexOf(test) == 0)
				return lbl.substr(test.length);
			test = 'users/';
			if (lbl.indexOf(test) == 0)
				return 'user/'+lbl.substr(test.length);
			
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
				{
					currJoinedGroupName = currGroupName;
				} else {
					currJoinedGroupName += '/'+currGroupName
				}
				if (!groups[currJoinedGroupName])
				{
					groupParentXML = <menuitem label={currGroupName}/>;
					
					groupObject = new Object();
					groupObject.parent = groupParentXML;
					groupObject.submenuPos = 0;
					
					groups[currJoinedGroupName] = groupObject;
					
					if (level == 0)
					{
						position = submenuPos;
					} else {
						position = parentGroupObject.submenuPos;
					}
					
					var len:int = currGroupParentXML.elements().length();
					if (len == 0 )
						currGroupParentXML.appendChild(groupParentXML);
					else {
						if (position > 0)
							currGroupParentXML.insertChildAfter(currGroupParentXML.elements()[position - 1], groupParentXML);
						else
							currGroupParentXML.insertChildBefore(currGroupParentXML.elements()[position], groupParentXML);
					}
					if (level == 0)
					{
						submenuPos++;
					} else {
						parentGroupObject.submenuPos++;
					}
					
					
				} else {
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