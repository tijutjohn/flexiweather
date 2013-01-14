package com.iblsoft.flexiweather.ogc.managers
{
	import com.iblsoft.flexiweather.ogc.configuration.AnimationConfiguration;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;

	public class AnimationConfigurationManager extends BaseConfigurationManager implements Serializable
	{
		public static const ANIMATIONS_CHANGED: String = 'animationsChanged';
		internal static var sm_instance: AnimationConfigurationManager;
		internal var ma_animations: ArrayCollection = new ArrayCollection();

		// getters & setters
		public function get animations(): ArrayCollection
		{
			return ma_animations;
		}

		public function AnimationConfigurationManager()
		{
			if (sm_instance != null)
				throw new Error("AnimationConfigurationManager can only be accessed through AnimationConfigurationManager.getInstance()");
		}

		public static function getInstance(): AnimationConfigurationManager
		{
			if (sm_instance == null)
				sm_instance = new AnimationConfigurationManager();
			return sm_instance;
		}

		public function serialize(storage: Storage): void
		{
			storage.serializePersistentArrayCollection("animation", ma_animations, AnimationConfiguration);
		}

		public function getLayerByLabel(lbl: String): AnimationConfiguration
		{
			if (ma_animations && ma_animations.length > 0)
			{
				for each (var map: AnimationConfiguration in ma_animations)
				{
					if (map.label == lbl)
						return map;
				}
			}
			return null;
		}

		public function addAnimation(animation: AnimationConfiguration): void
		{
			ma_animations.addItem(animation);
			notify();
		}

		private function notify(): void
		{
			var event: Event = new Event(ANIMATIONS_CHANGED);
			dispatchEvent(event);
		}

		public function getMapsXMLList(oldXMLList: XML = null): XMLList
		{
			if (ma_animations && ma_animations.length > 0)
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
				for each (var animation: AnimationConfiguration in ma_animations)
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
					var animationData: String = "animations." + animation.animationConfiguration.toXMLString(); //+area.projection.crs+","+area.projection.bbox.xMin+","+area.projection.bbox.yMin+","+area.projection.bbox.xMax+","+area.projection.bbox.yMax;
					var mapXML: XML = <menuitem label={lbl} data={animationData} type='animation'/>
					if (groupName && groupName.length > 0)
					{
						groupParentXML = createGroupSubfoldersAndGetParent(groupName, animationsXMLList);
						groupParentXML.appendChild(mapXML);
					}
					else
						animationsXMLList.appendChild(mapXML);
				}
//				var areaCustom: XML = <menuitem label='Custom...' data='custom.area' type='action'/>;
//				mapsXMLList.appendChild(areaCustom);
				return animationsXMLList.children();
			}
			return null;
		}
	}
}
