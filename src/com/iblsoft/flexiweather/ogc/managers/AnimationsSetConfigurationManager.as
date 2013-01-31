package com.iblsoft.flexiweather.ogc.managers
{
	import com.iblsoft.flexiweather.ogc.configuration.AnimationSetConfiguration;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;

	public class AnimationsSetConfigurationManager extends BaseConfigurationManager implements Serializable
	{
		public static const ANIMATIONS_SETS_CHANGED: String = 'animationsChanged';
		internal static var sm_instance: AnimationsSetConfigurationManager;
		private var ma_animationsSets: ArrayCollection = new ArrayCollection();

		// getters & setters
		public function get animationsSets(): ArrayCollection
		{
			return ma_animationsSets;
		}

		public function AnimationsSetConfigurationManager()
		{
			if (sm_instance != null)
				throw new Error("AnimationConfigurationManager can only be accessed through AnimationConfigurationManager.getInstance()");
		}

		public static function getInstance(): AnimationsSetConfigurationManager
		{
			if (sm_instance == null)
				sm_instance = new AnimationsSetConfigurationManager();
			return sm_instance;
		}

		public function serialize(storage: Storage): void
		{
			storage.serializePersistentArrayCollection("animationSet", ma_animationsSets, AnimationSetConfiguration);
		}

		public function getLayerByLabel(lbl: String): AnimationSetConfiguration
		{
			if (ma_animationsSets && ma_animationsSets.length > 0)
			{
				for each (var map: AnimationSetConfiguration in ma_animationsSets)
				{
					if (map.label == lbl)
						return map;
				}
			}
			return null;
		}

		public function addAnimationsSet(animationsSet: AnimationSetConfiguration): void
		{
			ma_animationsSets.addItem(animationsSet);
			notify();
		}

		private function notify(): void
		{
			var event: Event = new Event(ANIMATIONS_SETS_CHANGED);
			dispatchEvent(event);
		}

		public function getAnimationsSetsXMLList(oldXMLList: XML = null): XMLList
		{
			if (ma_animationsSets && ma_animationsSets.length > 0)
			{
				groups = [];
				submenuPos = 0;
				var animationsXMLList: XML;
				if (oldXMLList)
				{
					while (oldXMLList.children().length() > 0)
					{
						delete oldXMLList.children()[0];
					}
					animationsXMLList = oldXMLList;
				}
				else
				{
					animationsXMLList = <menuitem label='Animations' data='animations' type='folder'/>;
				}
				var groupParentXML: XML;
				for each (var animation: AnimationSetConfiguration in ma_animationsSets)
				{
					var lbl: String = animation.label;
					lbl = fixLabel(lbl);
					var groupName: String = '';
					if (lbl && lbl.indexOf('/') > 0)
					{
						var lastPos: int = lbl.lastIndexOf('/');
						//there is group name
						groupName = lbl.substring(0, lastPos);
						lbl = lbl.substring(lastPos + 1, lbl.length);
					}
					var animationData: String = "animations." + animation.animationsSetConfiguration.toXMLString(); //+area.projection.crs+","+area.projection.bbox.xMin+","+area.projection.bbox.yMin+","+area.projection.bbox.xMax+","+area.projection.bbox.yMax;
					var mapXML: XML = <menuitem label={lbl} data={animationData} type='animation'/>
					if (groupName && groupName.length > 0)
					{
						groupParentXML = createGroupSubfoldersAndGetParent(groupName, animationsXMLList);
						groupParentXML.appendChild(mapXML);
					}
					else
						animationsXMLList.appendChild(mapXML);
				}
				latestMenuItemsList = animationsXMLList.children(); 
				return latestMenuItemsList;
			}
			latestMenuItemsList = null;
			return null;
		}
	}
}
