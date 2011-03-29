package com.iblsoft.flexiweather.plugins
{
	import mx.controls.Image;
	
	public class PluginAbility
	{
		public static const ACTION: String = "action";
		public static const DOCKLET: String = "docklet";
		public static const CHAT: String = "chat";
		public static const PERSISTENT_CONFIGURATION: String = "persistenConfiguration";
		public static const PANE_CLIENT: String = "paneClient";
		public static const INTERACTIVE_WIDGET_CLIENT: String = "interactiveWidgetClient";
		public static const LAYER_SELECTION_LISTENER: String = "layerSelectionListener";
		public static const LAYER_CHANGE_LISTENER: String = "layerChangeListener";
		public static const LAYER_OPTIONS_PROVIDER: String = "layerOptionsProvider";
		public static const LAYER_BEHAVIOUR: String = "layerBehaviour";
		
		public static const MENU_ITEM: String = "menuItem";
		public static const SUBMENU_ITEM: String = "submenuItem";
		
		private var ms_abilityType: String;
		private var m_classOrInstance: Object;
		private var ms_id: String;
		private var ms_plugin_id: String;
		private var m_metadata: Object = new Object;
		
		function PluginAbility(s_abilityType: String, s_id: String, s_plugin_id: String, classOrInstance: Object)
		{
			ms_abilityType = s_abilityType;
			ms_id = s_id;
			ms_plugin_id = s_plugin_id;
			m_classOrInstance = classOrInstance;
		}
		
		public static function action(classOrInstance: Object,
				s_id: String, s_plugin_id: String, s_name: String, b_exclusive: Boolean, icon: Class): PluginAbility
		{
			return new PluginAbility(PluginAbility.ACTION, s_id, s_plugin_id, classOrInstance)
					.withMetadata("name", s_name)
					.withMetadata("exclusive", b_exclusive)
					.withMetadata("icon", icon); 
		}

		public static function docklet(classOrInstance: Object,
				s_id: String, s_name: String, s_plugin_id: String = null): PluginAbility
		{
			return new PluginAbility(PluginAbility.DOCKLET, s_id, s_plugin_id, classOrInstance) 
					.withMetadata("name", s_name);
		}
		
		public static function chat(classOrInstance: Object,
				s_id: String, s_name: String,s_plugin_id: String = null): PluginAbility
		{
			return new PluginAbility(PluginAbility.CHAT, s_id, s_plugin_id, classOrInstance) 
					.withMetadata("name", s_name);
		}
		
		public static function persistentConfiguration(classOrInstance: Object,
				s_id: String, s_name: String, s_plugin_id: String = null): PluginAbility
		{
			return new PluginAbility(PluginAbility.PERSISTENT_CONFIGURATION, s_id, s_plugin_id, classOrInstance) 
					.withMetadata("name", s_name);
		}

		public static function paneClient(classOrInstance: Object,
				s_id: String = null, s_plugin_id: String = null): PluginAbility
		{
			return new PluginAbility(PluginAbility.PANE_CLIENT, s_id, s_plugin_id, classOrInstance); 
		}
		
		public static function interactiveWidgetClient(classOrInstance: Object,
				s_id: String = null, s_plugin_id: String = null): PluginAbility
		{
			return new PluginAbility(PluginAbility.INTERACTIVE_WIDGET_CLIENT, s_id, s_plugin_id, classOrInstance); 
		}
		
		public static function layerOptionsProvider(classOrInstance: Object,
				s_id: String, s_plugin_id: String = null): PluginAbility
		{
			return new PluginAbility(PluginAbility.LAYER_OPTIONS_PROVIDER, s_id, s_plugin_id, classOrInstance); 
		}

		public static function layerBehaviour(classOrInstance: Object,
				s_id: String, s_name: String, s_plugin_id: String = null): PluginAbility
		{
			return new PluginAbility(PluginAbility.LAYER_BEHAVIOUR, s_id, s_plugin_id, classOrInstance) 
					.withMetadata("name", s_name);
		}
		
		public static function menuItem(classOrInstance: Object,
				s_id: String, s_name: String, i_priority: int, s_plugin_id: String = null): PluginAbility
		{
			var ability: PluginAbility = new PluginAbility(PluginAbility.MENU_ITEM, s_id, s_plugin_id, classOrInstance)
			ability.withMetadata("name", s_name);
			ability.withMetadata("priority", i_priority);
			
			return ability;
		}
		
		public static function submenuItem(classOrInstance: Object,
				s_id: String, s_mainMenu_id, s_name: String, i_priority: int, s_plugin_id: String = null): PluginAbility
		{
			var ability: PluginAbility = new PluginAbility(PluginAbility.SUBMENU_ITEM, s_id, s_plugin_id, classOrInstance)
			ability.withMetadata("name", s_name);
			ability.withMetadata("mainMenuID", s_mainMenu_id);
			ability.withMetadata("priority", i_priority);
			
			return ability;
		}

		public static function custom(s_abilityType: String, classOrInstance: Object, s_id: String, s_plugin_id: String = null): PluginAbility
		{
			return new PluginAbility(s_abilityType, s_id, s_plugin_id, classOrInstance); 
		}

		public function withMetadata(s_key: String, value: Object): PluginAbility
		{
			m_metadata[s_key] = value;
			return this;
		}
		
		public function getImplementationInstance(plugin: IPlugin): IAbility
		{
			if(m_classOrInstance is Class) {
				var instance: IAbility = IAbility(new m_classOrInstance());
				instance.bindToPlugin(plugin);
				return instance;
			}
			else
				return IAbility(m_classOrInstance);
		}
		
		public function getMetadata(s_key: String, defaultValue: Object = null): Object
		{
			if(s_key in m_metadata)
				return m_metadata[s_key];
			else
				return defaultValue;				
		}

		// getters and setters
		public function get id(): String
		{ return ms_id; }
		public function get pluginId(): String
		{ return ms_plugin_id; }

		public function get abilityType(): String
		{ return ms_abilityType; }
	}
}